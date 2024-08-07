local component = require("component")
local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local term = require("term")

local ocpt = require("ocpt")

local gpu = component.gpu

local args, options = shell.parse(...)

local function printUsage()
	print("OpenPrograms Package Manager, use this to browse through and download OpenPrograms programs easily")
	print("Usage:")
	print("'oppm list [-i]' to get a list of all the available program packages")
	print("'oppm list [-i] <filter>' to get a list of available packages containing the specified substring")
	print(" -i: Only list already installed packages")
	print("'oppm info <package>' to get further information about a program package")
	print("'oppm install [-f] <package> [path]' to download a package to a directory on your system (or /usr by default)")
	print("'oppm update <package>' to update an already installed package")
	print("'oppm update all' to update every already installed package")
	print("'oppm uninstall <package>' to remove a package from your system")
	print(
		"'oppm register <repository>' to register a package repository locally\n  Must be a valid GitHub repo containing programs.cfg")
	print("'oppm unregister <repository>' to remove a package repository from your local registry")
	print(" -f: Force creation of directories and overwriting of existing files.")
end

---@param packs string[]
local function printPackages(packs)
	if packs == nil or not packs[1] then
		print("No package matching specified filter found.")
		return
	end
	term.clear()
	local xRes, yRes = gpu.getResolution()
	print("--OpenPrograms Package list--")
	local xCur, yCur = term.getCursor()
	for _, j in ipairs(packs) do
		term.write(j .. "\n")
		yCur = yCur + 1
		if yCur > yRes - 1 then
			term.write("[Press any key to continue]")
			local event = event.pull("key_down")
			if event then
				term.clear()
				print("--OpenPrograms Package list--")
				xCur, yCur = term.getCursor()
			end
		end
	end
end

---@param pack oppt.package.handler
local function provideInfo(pack)
	local info = pack.info
	local done = false
	print("--Information about package '" .. info.name .. "'--")
	if info.name then
		print("Name: " .. info.name)
		done = true
	end
	if info.description then
		print("Description: " .. info.description)
		done = true
	end
	if info.authors then
		print("Authors: " .. info.authors)
		done = true
	end
	if info.note then
		print("Note: " .. info.note)
		done = true
	end
	if pack.files then
		local c = 0
		for i in pairs(pack.files) do
			c = c + 1
		end
		if c > 0 then
			print("Number of files: " .. tostring(c))
			done = true
		end
	end
	if not done then
		print("No information provided.")
	end
end


if args[1] == "list" then
	local packs = ocpt.list(options.i, args[2])
	printPackages(packs)
	return
end

if args[1] == "info" then
	if not args[2] then
		io.stderr:write("No package specified\n")
		return
	end
	local pack = ocpt.getPackage(args[2])
	if not pack then
		io.stderr:write("Package does not exist\n")
		return
	end
	provideInfo(pack)
	return
end

if args[1] == "install" then
	if not args[2] then
		io.stderr:write("No package specified\n")
		return
	end
	print("searching package: " .. args[2].."...")
	local pack = ocpt.getPackage(args[2])
	if not pack then
		io.stderr:write("Package does not exist\n")
		return
	end
	print("Installing package '" .. pack.info.name .. "'")
	local success, msg = pack:install(args[3], options.f)
	if not success then
		io.stderr:write("Failed to install package: " .. msg .. "\n")
	else
		print("Package installed successfully")
	end
	return
end

if args[1] == "floppy" then
	if not args[2] then
		io.stderr:write("No package specified\n")
		return
	end
	if not args[3] then
		io.stderr:write("No disk address specified\n")
	end
	local pack = ocpt.getPackage(args[2])
	if not pack then
		io.stderr:write("Package does not exist\n")
		return
	end
	print(pack:addToDisk(args[3]))
	return
end

if args[1] == "update" then
	if not args[2] then
		io.stderr:write("No package specified\n")
	end
	if args[2] == "all" then
		local success, msg = ocpt.updateAll()
		if not success then
			io.stderr:write("Failed to update all packages: " .. msg .. "\n")
			return
		end
		return
	end
	print("Updating package '" .. args[2] .. "'")
	local success, msg = ocpt.update(args[2])
	if not success then
		io.stderr:write("Failed to update package: " .. msg .. "\n")
	else
		print("Package updated successfully")
	end
	return
end

if args[1] == "uninstall" then
	if not args[2] then
		io.stderr:write("No package specified\n")
	end
	local success, msg = ocpt.uninstall(args[2])
	if not success then
		io.stderr:write("Failed to uninstall package: " .. msg .. "\n")
	else
		print("Package uninstalled successfully")
	end
	return
end

if args[1] == "register" then
	if not args[2] then
		io.stderr:write("No repository specified\n")
		return
	end
	local success, msg = ocpt.registerRepo(args[2])
	if not success then
		io.stderr:write("Failed to register repository: " .. msg .. "\n")
	else
		print("Repository registered successfully")
	end
	return
end

if args[1] == "unregister" then
	if not args[2] then
		io.stderr:write("No repository specified\n")
		return
	end
	local success, msg = ocpt.unregisterRepo(args[2])
	if not success then
		io.stderr:write("Failed to unregister repository: " .. msg .. "\n")
	else
		print("Repository unregistered successfully")
	end
	return
end
printUsage()
