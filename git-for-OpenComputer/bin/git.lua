local shell = require("shell")
local filesystem = require("filesystem")

local github = require("github")

local args, opts = shell.parse(...)


if opts.b and opts.t then
	io.stderr:write("branch and tag could not define at the same time")
end

if not args[1] then
	io.write([[
Provides a way to clone a Github Repositories or subpart of this.
Usage:
   clone [--b=<branchname> | --t=<tagname> | -r] [--d=<path>|--d] [--i=<exe>|--i|--I=<exe>] [--a=<username>] <user>/<repo> [<destination>]
      flags
         --b  branch name
         --t  tag name
         -r   last release
         --a  user defined with auth command
         --d  subpart to clone
         --i  replaces the list of ignored files or directories, default: md,png,jpeg,docx,xlsx
         --I  extends the list of ignored files or directories

   auth <user> [<api token> | -d ]
      flags
         -d delete
]]
	)
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
		local validAnswers = { [''] = 'yes', y = 'yes', yes = 'yes', n = 'no', no = 'no' }
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
	local dest = shell.resolve(args[3] or (args.d and filesystem.name(args.d)) or repoName)
	local token
	if opts.a then
		token = github.Auth.get(opts.a)
		if not token then
			io.stderr:write("no auth found for " .. opts.a)
			return
		end
	end

	if opts.d == true then
		io.write("give the path of the subfolder to clone: ")
		opts.d = io.read()
	end

	local excluded_type = { md = true, png = true, jpeg = true, docx = true, xlsx = true }
	if opts.i then
		excluded_type = {}
	end
	if type(opts.i) == "string" or type(opts.I) == "string" then
		for type in string.gmatch(opts.i, '([^,]+)') do
			excluded_type[type] = true
		end
	end


	print("fetch repo")
	local repo = github.repo(user, repoName,
		{ token = token, branch = opts.b, tag = opts.t, latestRelease = opts.r, subdir = opts.d, excluded = excluded_type })

	local repoSize = repo:getRepoSize()
	local size = 0
	print("check available space")
	hasEnoughSpace(dest, repoSize)

	print("start Downloading:")
	local already_download = 0
	repo:cloneTo(dest, function(item, number, root)
		if getmetatable(item) == github.Blob then ---@cast item Blob
			already_download = already_download + 1
			local count = string.format(" [%-2d/%2d]", already_download, root.blobsCount)
			print(count.."  "..item:relatifTo(root))
			size = size + item.size
		end
	end, opts.d)


	return
end

if args[1] == "auth" then
	local user, token = args[2], args[3] ---@type string, string
	local Auth = github.Auth
	if not user then
		return error("No user specified.")
	end

	if args.d then
		if Auth.has(user) then
			Auth.delete(user)
			print(('Deleted github token for user %s'):format(user))
		else
			print('token not found')
		end

		return
	end

	if not token then
		return error("No token specified.")
	end
	local _token = Auth.add(user, token)
	print(('Saved github token for user %s\ntoken verification...'):format(user))

	if not Auth.checkToken(_token) then
		io.stderr:write("Invalid token!")
		return
	else
		print("Check success")
	end

	return
end
