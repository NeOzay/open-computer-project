local internet = require('internet')
local shell = require('shell')
local filesystem = require('filesystem')
local args = { ... }



local package = args[1]

print("Welcome, to the package installer")
if not args[1] then
	print(
		[[
Usage:
   pastebin run kydcWA2y <package>
]]
	)
	return
end

local repo = "NeOzay/open-computer-project"
local branch = "master"
local url = string.format('https://raw.githubusercontent.com/%s/%s', repo, branch)

local function install(name)
	shell.execute(string.format('wget -fq %s/%s/%s %s', url, name, ".package.lua", "_package.lua"))
	if not filesystem.exists(shell.resolve("_package.lua")) then
		error()
	end
	local filesList = loadfile("_package.lua")()


	-- INSTALL
	for index, file in ipairs(filesList) do
		local dir = file
		if not string.find(dir, "usr") then
			dir = filesystem.concat("usr", dir)
		end
		local overwrite = true
		if not filesystem.exists(filesystem.path(dir)) then
			filesystem.makeDirectory(filesystem.path(dir))
		elseif filesystem.exists(dir) then
			io.write(dir)
			io.write("do you want to overwrite the following element?[y/N]:")
			overwrite = string.lower(io.read()) == "y"
		end
		if overwrite then
			shell.execute(string.format('wget -f %s/%s/%s /%s', url, name, file, dir))
		end
	end
	filesystem.remove("_package")
	for index, dep in ipairs(filesList.dependencies or {}) do
		install(dep)
	end
end

install(package)
