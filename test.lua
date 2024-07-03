local component = require("component")
local computer = require("computer")

---@return filesystem[]
local function getAvailableFilesystem()
	local filesystems = {}
	local tmpfs = computer.tmpAddress()
	for address, type in component.list("filesystem") do
		if address ~= tmpfs then
			local proxy = component.proxy(address) ---@cast proxy filesystem
			if proxy.list("/")[1] == nil or proxy.exists("programs.cfg") then
				filesystems[#filesystems + 1] = proxy
			end
		end
	end
	return filesystems
end

local function addPackageToDisk(pack, address)
	local fs = component.proxy(address)
	if type(fs.type) ~= "filesystem" then return	end
	---@cast fs filesystem
	local files = fs.list("/")
	if not files then
		io.stderr:write("Failed to list files on disk\n")
		return
	end
	if not fs.exists("/ocpt") then
		fs.makeDirectory("/ocpt")
	end
	local file = fs.open("/ocpt/" .. pack.info.name, "w")
	if not file then
		io.stderr:write("Failed to open file for writing\n")
		return
	end
	fs.write(file, pack:serialize())
	fs.close(file)
	
end
getAvailableFilesystem()
addPackageToDisk(ocpt.getPackage("ocpt"), "f0b1")