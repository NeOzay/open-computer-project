local component = require("component")
local fs = require("filesystem")
local alldevice = component.list()
local adress = {}

local i = 1

for k, v in pairs(alldevice) do
  print(i .. " - " .. v)
  i = i + 1
  table.insert(adress, k)
end
local device = tonumber(io.read())

local diviceName = alldevice[adress[device]]

local function save(text, path)
  local file, error = fs.open(path, "w")
  file:write(text)
  file:close()
end

local texts = "---@class " .. diviceName .. "\nlocal " .. diviceName .. " = {}\n\n"
local allMethods = {}
for k, v in pairs(component[diviceName]) do
  print(diviceName .. "." .. k, v)
  table.insert(allMethods, diviceName .. "." .. k .. " " .. tostring(v))
end
texts = texts .. table.concat(allMethods, "\n")
save(texts, "/home/" .. alldevice[adress[device]] .. ".lua")
