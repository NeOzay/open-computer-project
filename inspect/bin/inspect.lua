local inspect = require("inspect")
local shell = require("shell")
local io = require("io")

local args, ops = shell.parse(...)

print(table.concat(args, ","))

local t = load("return ".. args[1])()
local depth = tonumber(ops.d or ops.depth) or math.huge
local s = inspect(t, {depth = depth})

local f, reason = io.open("inspected", "w")
if f then
  f:write(s)
  f:close()
  shell.execute("less inspected")
else
  print(reason)
end


