local internet = require('internet')
local shell = require('shell')
local filesystem = require('filesystem')
local args = { ... }
local branch
local repo

if args[1] == "remove" then
	repo = args[2]
	if args[3] then
		branch = args[3]
	else
		branch = "master"
	end
else
	repo = args[1]
	if args[2] then
		branch = args[2]
	else
		branch = 'master'
	end
end

print("Welcome, to the package installer")
if not args[1] then
	print(
[[
Usage:
   pastebin run kydcWA2y <user>/<repo> [<branch>]
   pastebin run kydcWA2y remove <user>/<repo> [<branch>]
]]
)
return
end

-- REPO
local url = string.format('https://raw.githubusercontent.com/%s/%s', repo, branch)

shell.execute(string.format('wget -fq %s/%s %s', url, ".package.lua", "_package.lua"))
if not filesystem.exists(shell.resolve("_package.lua")) then
	error()
end
local package = loadfile("_package")()

if args[1] == 'remove' then
	-- Remove
	io.write("do you want to remove "..repo.." package?[Y/n]:")
	if string.lower(io.read()) == "n" then
		print("abort uninstallation")
		return
	end
	for index, file in ipairs(package) do
		if filesystem.exists(file) then
			print("deletion of: "..file)
			filesystem.remove(file)
		end
	end
else
	-- INSTALL
	for index, file in ipairs(package) do
		local dir = filesystem.path(file)
		local overwrite = true
		if filesystem.exists(file) then
			io.write("do you want to overwrite "..file.." [y/N]:")
			overwrite = string.lower(io.read()) == "y"
		end
		if overwrite then
			if not filesystem.exists(dir) then
				filesystem.makeDirectory(dir)
			end

			shell.execute(string.format('wget -f %s/%s /%s', url, file, file))
		end
	end
end

filesystem.remove("_package")