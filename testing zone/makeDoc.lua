local component = require("component")
local fs = require("filesystem")
local alldevice = component.list()
local adress= {}

local i=1

for k,v in pairs(alldevice) do
  print(i.." - "..v)
  i = i+1
  table.insert(adress,k)
end
local device = tonumber(io.read())


function save(text,path)
  local file = fs.open(path,"w")
  file:write(text)
  file:close()
end

local texts= "---@class "..alldevice[adress[device]].."\nlocal "..alldevice[adress[device]].." = {}\n\n"
for k,v in pairs(component[alldevice[adress[device]]]) do
  print(k,v)
  if tostring(v) =="function" then
    texts=texts.."function "..alldevice[adress[device]].."."..k.."() end".."\n\n"
  else
    texts = texts..alldevice[adress[device]].."."..k.." = \""..v.."\"\n\n"
  end

end

save(texts,"/home/"..alldevice[adress[device]]..".lua")
