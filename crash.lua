local shell = require("shell")
local fs = require("filesystem")

local args, opts = shell.parse(...)



if not args[1] or not args[2] then
  print("USAGE: crash <error log path> <path to program> [arguments...]")
  return 1
end

local elog = shell.resolve(args[1])
local path = shell.resolve(args[2])

if not fs.exists(path) and fs.exists("/bin/"..args[2]..".lua") then
  path = "/bin/"..args[2]..".lua"
end

if not fs.exists(path) or fs.isDirectory(path) then
  print("Invalid path.")
  print("USAGE: crash <error log path> <path to program> [arguments...]")
  return 1
end

if not fs.exists(fs.path(elog)) then
  fs.makeDirectory(fs.path(elog))
end

local result = {xpcall(loadfile(path), debug.traceback, table.unpack(args))}

if result[1] then
  return table.unpack(result, 2)
else
  print("Program crashed.")
  local file = io.open(elog, "w")
  file:write(result[2])
  file:close()
  print("Error log saved to: " .. elog)
  return 0
end