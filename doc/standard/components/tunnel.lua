---@meta _

---@class tunnel:ProxyBase
local tunnel = {}


---Sends the specified data to the card this one is linked to.
function tunnel.send(...) end


---Gets the maximum packet size (config setting).
---@return number
function tunnel.maxPacketSize() end

---Gets the tunnel address of the link card. This is also available in linkChannel using an inventory controller and getting the stack from an inventory slot.
---@return string
function tunnel.getChannel() end

---Gets the current wake-up message. When the network card detects the wake message (a string in the first argument of a network packet), on any port and the machine is off, the machine is started. This is the same functionality also provided by robots, cases, servers, drones, and tablets.
---@return string
function tunnel.getWakeMessage() end


---@param message string
---@return string
---@overload fun(message: string, fuzzy: boolean):string
function tunnel.setWakeMessage(message) end

return tunnel

