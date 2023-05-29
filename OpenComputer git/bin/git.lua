package.loaded.github=nil
local shell = require("shell")
local term = require("term")
local filesystem = require("filesystem")
local component = require("component")

local github = require("github")

local gpu = component.gpu
local screenw, screenl = gpu.getResolution()

local args, opts = shell.parse(...)


if opts.b and opts.t then
	io.stderr:write("branch and tag could not define at the same time")
end

---@return number,number
local function getOffset()
	local _, _, _, _, ox, oy = term.getViewport()
	return ox, oy
end

---@param barsize number 
---@return fun(percent:number):string @between 0 and 1
local function newProgressbar(barsize)
	local left = "["
	local right = ("]%3d%%"):format(0)
	local gap = barsize or 50 - #left - #right
	local at
	local tampon = 1
	---@type string[]
	local bar = {left, ">", right}
	for i = 1, gap do
		table.insert(bar, #bar, " ")
	end
	return coroutine.wrap(function(percent)
		while true do

			right = ("]%3d%%"):format(tostring(percent * 100))
			table.remove(bar)
			table.insert(bar, right)

			at = math.floor(percent * (gap) + 0.5)
			for i = tampon, gap + 2 do
				if i < at + 2 then
					table.insert(bar, 2, "=")
					table.remove(bar, #bar - 1)
				else
					tampon = i
					break
				end
			end
			percent = coroutine.yield(table.concat(bar))
		end
	end)
end

---@param initLine number
---@param drawFn fun(currentLine:number,text:string|number,...)
local function newDisplay(initLine, drawFn)
	---@type number
	local currentLine
	if initLine == 1 then
		currentLine = initLine
		initLine = initLine + 1
		term.setCursor(1, initLine)
	else
		currentLine = initLine - 1
		term.setCursor(1, initLine)
	end

	local isBottom = false
	return ---@param text string|number
	function(text, ...)
		text = tostring(text)
		local _, yo = getOffset()
		if yo == 50 then
			if isBottom then
				currentLine = math.max(currentLine - 1, 1)
			else
				isBottom = true
			end
		end
		drawFn(currentLine, text, ...)
	end
end

local function sizeStr(bytes)
	local unit = 1024
	if bytes < unit then
		return ("%s byte(s)"):format(bytes)
	else
		local multi = 10 ^ (1)
		local KiB = math.floor((bytes / unit) * multi + 0.5) / multi
		return ("%s KiB"):format(KiB)
	end
end

local function hasEnoughSpace(locate, repoSize)
	-- The value reported by github underestimates the one reported by CC. This tries
	-- to guess when this matters.

	local disk, _, _ = filesystem.get(locate)

	local maxSpace = disk.spaceTotal()

	local freeSpace = maxSpace - disk.spaceUsed()

	local sizeError = 0.2

	local function warnAndContinue()
		io.stderr:write("Repository may be too large to download, attempt anyway? [Y/n]: ")
		local validAnswers = {[''] = 'yes', y = 'yes', yes = 'yes', n = 'no', no = 'no'}
		local input = io.read()
		while not validAnswers[input:lower()] do
			io.write("Please type [y]es or [n]o: ")
			input = io.read()
		end
		return validAnswers[input:lower()] == 'yes'
	end
	local errStr = "Repository is %s, but only %s are free on this computer. Aborting!"
	errStr = errStr:format(sizeStr(repoSize), sizeStr(freeSpace))
	if repoSize > freeSpace then
		error(errStr)
	elseif repoSize * (1 + sizeError) > freeSpace then
		if not warnAndContinue() then
			error(errStr)
		end
	else
		return true
	end
end

---@param s string
---@return string, string
local function getRepoName(s)
	s = s or ""
	local user, repo = s:match('^(.-)/(.+)$')
	if not user or not repo then
		io.stderr:write("error: give form like git clone <user>/<repo>")
		os.exit()
	end
	return user, repo
end

if args[1] == "clone" then
	local user, repoName = getRepoName(args[2])
	local dest = shell.resolve(args[3] or repoName)
	local auth
	if opts.a then
		auth = github.Auth.get(opts.a)
	end
	print("fetch repo")
	local repo = github.repo(user, repoName, {auth = auth, branch = opts.b, tag = opts.t, latestRelease = opts.r})


	local repoSize = repo:getRepoSize()
	local size = 0
	print("check available space")
	hasEnoughSpace(dest, repoSize)

	local progressbar = newProgressbar(screenw - #"Downloading:" - 7)
	--print(screenw - #"Downloading:" - 7)
	local _, oy = getOffset()

	local display = newDisplay(oy, function(line, text)
		gpu.fill(1, line, screenl, 1, " ")
		gpu.set(1, line, text)
	end)
	print("start Downloading")
	repo:cloneTo(dest, function(item)
		if getmetatable(item) == github.Blob then ---@cast item Blob
			--print(item:fullPath())
			size = size + item.size
			--display("Downloading:" .. progressbar(size / repoSize))
		end
	end)
	return
end

if args[1] == "subclone" then
	local user, repoName = getRepoName(args[2])
	local subdir = opts.s
	if not opts.s then
		io.write("give the path of the subfolder to clone: ")
		subdir = io.read()
	end
	local dest = shell.resolve(args[3] or filesystem.name(subdir))
	local auth
	if opts.a then
		auth = github.Auth.get(opts.a)
		if not auth then
			io.stderr:write("no auth found for "..opts.a)
		return	
		end
	end
	print("fetch repo")
	local repo = github.repo(user, repoName, {auth = auth, branch = opts.b, tag = opts.t, latestRelease = opts.r, subdir = subdir})
	print("start Downloading")
	local repoSize = repo:getRepoSize()
	local size = 0
	print("check available space")
	hasEnoughSpace(dest, repoSize)
	repo:cloneTreeTo(dest, subdir)
	return
end

if args[1] == "auth" then
	local user, token = args[2], args[3]
	if not user then
		return error("No user specified.")
	end

	if args.d then
		github.Auth.delete(user)
		print(('Deleted github token for user %s'):format(user))
	else
		if not token then
			return error("No token specified.")
		end
		local auth = github.Auth.new('oauth', user, token)
		if auth:checkToken() then
			auth:save()
			print(('Saved github token for user %s'):format(auth.user))
		else
			return error("Invalid token!")
		end
	end

	return
end

