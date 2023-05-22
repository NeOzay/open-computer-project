local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local inspect = require("inspect")

local args, ops = shell.parse(...)

local component_available = component.list(args[1])

local index = 1
local order = {}
for address, component_type in component_available do
  print(index, component_type, address)
  index = index + 1
  table.insert(order, address)
end

io.write("choise component: ")

local choise = tonumber(io.read())
local address = order[choise]

local all_methods = component.methods(address)
local this_component = component.proxy(address)

local doc = {}

for method, b in pairs(all_methods) do
  doc[method] = tostring(this_component[method])
end

local s = inspect(doc)

local f, reason = io.open(component_available[address].."_methods", "w")
if f then
  f:write(s)
  f:close()
  shell.execute("less "..component_available[address].."_methods")
else
  print(reason)
end

