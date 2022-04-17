local serialization ={}


---Generates a string from an object that can be parsed again using serialization.unserialize. The generated output is Lua code. Supports basic types (nil, boolean, number, string) and tables without cycles (will error out when cycles are detected, unless in pretty print mode). Properly handles NaN values and infinity.
---
---The pretty mode can be used to generate output for display to the user, this output will in most circumstances not be readable with serialization.unserialize.
---
---The value of pretty defines the number of entries that will be printed.
---
---If pretty is set to true it will by default print 10 entries.
---
---This function can be useful for sending messages via a network card.
---@param value any @except functions
---@return string
---@overload fun(value: any , pretty:number):string
function serialization.serialize(value) end

---Restores an object previously saved with serialization.serialize.
---Contents
---@param value string
---@return any
function serialization.unserialize(value) end

return serialization