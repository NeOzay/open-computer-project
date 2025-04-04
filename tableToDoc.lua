local fs = require("filesystem")
local component = require("component")

local craft = component.me_interface.getCraftables()[1].request()
local atable = craft
local name = "cpu"

local function save(text, path)
  local file, error = fs.open(path, "w")
  file:write(text)
  file:close()
end

local texts = "---@class " .. name.."\n"
local allMethods = {}
for k, v in pairs(atable) do
  local str = type(v)	
  if str == "table" or str == "function" then
	 str = tostring(v)
  end
  table.insert(allMethods, "---@field " .. k .. " " .. str)
  print(name .. "." .. k, str)
end
texts = texts .. table.concat(allMethods, "\n")
save(texts, "/home/" .. name .. ".lua")
