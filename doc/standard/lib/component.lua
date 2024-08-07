---@meta component

---@class componentLib
local component = {}

---Returns the documentation string for the method with the specified name of the component with the specified address, if any. Note that you can also get this string by using tostring on a method in a proxy, for example tostring(component.screen.isOn).
---@param address string
---@param method string
---@return string
function component.doc(address, method) end

---Calls the method with the specified name on the component with the specified address, passing the remaining arguments as arguments to that method. Returns the result of the method call, i.e. the values returned by the method. Depending on the called method's implementation this may throw.
---@param address string
---@param method string
---@param ... any
---@return any ...
function component.invoke(address, method, ...) end

---@class componentLib.list
---@overload fun():string, string

---Returns a table with all components currently attached to the computer, with address as a key and component type as a value. It also provides iterator syntax via __call.
---
---If filter is set this will only return components that contain the filter string (this is not a pattern/regular expression).
---
---For example, component.list("red") will return redstone components.
---
---If true is passed as a second parameter, exact matching is enforced, e.g. red will not match redstone.
---@param filter? string
---@param exact? boolean
---@return componentLib.list|table<string, string>
function component.list(filter, exact) end

---Returns a table with the names of all methods provided by the component with the specified address. The names are the keys in the table, the values indicate whether the method is called directly or not.
---@param address string
---@return table
function component.methods(address) end

---Gets a 'proxy' object for a component that provides all methods the component provides as fields, so they can be called more directly (instead of via invoke). This is what's used to generate 'primaries' of the individual component types, i.e. what you get via component.blah.
---
---For example, you can use it like so: component.proxy(component.list("redstone")()).getInput(sides.north), which gets you a proxy for the first redstone component returned by the component.list iterator, and then calls getInput on it.
---
---Note that proxies will always have at least two fields, type with the component's type name, and address with the component's address.
---@param address string
---@return ProxyBase
function component.proxy(address) end

---Get the component type of the component with the specified address.
---@param address string
---@return string
function component.type(address) end

---Return slot number which the component is installed into. Returns -1 if it doesn't otherwise make sense.
---@param address string
---@return string
function component.slot(address) end

---Undocumented
---@param address string
---@return string
function component.fields(address) end

---Tries to resolve an abbreviated address to a full address. Returns the full address on success, or nil and an error message otherwise. Optionally filters by component type
---@param address string
---@param filter? string
---@return string|nil
---@return string|nil
function component.get(address, filter) end

---Checks if there is a primary component of the specified component type.
---@param componentType string
---@return boolean
function component.isAvailable(componentType) end

---Gets the proxy for the primary component of the specified type. Throws an error if there is no primary component of the specified type.
---@param componentType string
---@return ProxyBase
function component.getPrimary(componentType) end

---Sets a new primary component for the specified component type. The address may be abbreviated, but must be valid if it is not nil. Triggers the component_unavailable and component_available signals if set to nil or a new value, respectively.
---
---Note that the component API has a metatable that allows the following syntax:
---@param address string
---@param componentType string
---@return nil
function component.setPrimary(componentType, address) end

---@class ProxyBase
---@field slot number
---@field address string
---@field type string

---@class componentLib
---@field nc_fission_reactor nc_fission_reactor
---@field gpu gpu
---@field screen screen
---@field tunnel tunnel
---@field modem modem
---@field filesystem filesystem
---@field computer computer
---@field disk_drive disk_drive
---@field transposer transposer
---@field inventory_controller inventory_controller
---@field geolyzer geolyzer

return component
