local component = require("component")
local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local term = require("term")
local computer = require("computer")

local ocpt = require("ocpt")

local gpu = component.gpu

local args, options = shell.parse(...)

local function printUsage()
	print("OpenPrograms Package Manager, use this to browse through and download OpenPrograms programs easily")
	print("Usage:")
	print("'ocpt list [-i]' to get a list of all the available program packages")
	print("'ocpt list [-i] <filter>' to get a list of available packages containing the specified substring")
	print(" -i: Only list already installed packages")
	print("'ocpt info <package>' to get further information about a program package")
	print("'ocpt install [-f] <package> [path]' to download a package to a directory on your system (or /usr by default)")
	print("'ocpt update <package>' to update an already installed package")
	print("'ocpt update all' to update every already installed package")
	print("'ocpt uninstall <package>' to remove a package from your system")
	print("'ocpt floppy [-r] <package> [filesystem]' to copy a package to a floppy disk")
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
	print("Repository: " .. pack.repoName)
	
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

---@return string[]
local function getAvailableFilesystem()
	local function isvalidFilesystem(address)
		local proxy = component.proxy(address) ---@cast proxy filesystem
		return proxy.list("/")[1] == nil or proxy.exists("/programs.cfg")
	end
	
   local filesystems = {} ---@type string[]
   local tmpfs = computer.tmpAddress()
   for address, type in component.list("filesystem") do
      if address ~= tmpfs then
         if isvalidFilesystem(address) then
            filesystems[#filesystems + 1] = address
         end
      end
   end
   return filesystems
end

if args[1] == "floppy" then
	if not args[2] then
		io.stderr:write("No package specified\n")
		return
	end
	if not args[3] then
		local fsList = getAvailableFilesystem()
		if not fsList[1] then
			io.stderr:write("No valid filesystem found\n")
			return
		end
		for index, disk in ipairs(fsList) do
			print(index .. ": " .. disk)
		end
		io.write("Select a filesystem: ")
		local input
		while not input do
			input = fsList[tonumber(io.read())]
		end
		args[3] = input
	end
	if options.r then
		local success, err = ocpt.removeToDisk(args[2], args[3])
		if success then
			io.write("Package removed successfully\n")
		else
			io.stderr:write("Failed to remove package: " .. err .. "\n")
		end
		return
	end
	print("searching package: " .. args[2].."...")
	local pack = ocpt.getPackage(args[2])
	if not pack then
		io.stderr:write("Package does not exist\n")
		return
	end
	print("Copying package '" .. pack.info.name .. "' to disk")
	local success, err = pack:addToDisk(args[3])
	if success then
		io.write("Package copied successfully\n")
	else
		io.stderr:write("Failed to copy package: " .. err .. "\n")
	end
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
