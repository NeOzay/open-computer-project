local shell = require("shell")

---@class Logger
---@field fileHandle file*
local Logger = {}
Logger.__index = Logger

---@param path? string
---@return Logger
function Logger.newInstance(path)
	if not path then
		path = shell.getWorkingDirectory().."/log.txt"
	end
	local logger = setmetatable({},Logger)
	logger.fileHandle = io.open(path, "w")
	return logger
end

---@param any any
---@param toprint boolean
function Logger:trace(any, toprint)
	any = tostring(any)
	if toprint then
		print(any)
	end
	self.fileHandle:write(any.."\n")
	self.fileHandle:flush()
end

function Logger:close()
	self.fileHandle:close()
end

return