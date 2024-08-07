---@meta _

---@class transposer:ProxyBase
local transposer = {}

---Transfer some fluids between two fluid handlers (pipes or tanks, etc).
---
---**sourceSide** is the side pulled from and **sinkSide** is the side transferred to.
---
---The **side** value is a integral value representing the cardinal directions (east, west, south, north), up, and down. The sides library has these values for convenience. count is the number of millibuckets to transfers.
---
---Returns true and the number of millibuckets transfered on success, or false and an error message on failure.
---@param sourceSide number
---@param sinkSide number
---@param count number
---@return boolean, number
function transposer.transferFluid(sourceSide, sinkSide, count) end

---Store an item stack description in the specified slot of the database with the specified address.
---@param side number
---@param slot number
---@param dbAddress string
---@param dbSlot number
function transposer.store(side, slot, dbAddress, dbSlot) end


---compareStackToDatabase
---@param side number
---@param slot number
---@param dbAddress string
---@param dbSlot number
---@return boolean
function transposer.compareStackToDatabase(side,slot,dbAddress,dbSlot) end

---Get number of items in the specified slot of the inventory on the specified side of the device.
---@param side number
---@param slot number
---@return number
function transposer.getSlotStackSize(side,slot) end

---Get the maximum number of items in the specified slot of the inventory on the specified side of the device.
---@param side number
---@param slot number
---@return number
function transposer.getSlotMaxStackSize(side,slot) end

---getInventoryName
---@param side number
---@return string
function transposer.getInventoryName(side) end

---Get the number of slots in the inventory on the specified side of the device.
---@param side number
---@return number
function transposer.getInventorySize(side) end

---Get a description of the fluid in the the specified tank on the specified side.
---@param side number
---@param tank? number
---@return table
function transposer.getFluidInTank(side,tank) end

---Get the amount of fluid in the specified tank on the specified side.
---@param side number
---@param tank? number
---@return number
function transposer.getTankLevel(side,tank) end


---Transfer some items between two inventories.
---@param sourceSide number
---@param sinkSide number
---@param count? number
---@param sourceSlot? number
---@param sinkSlot? number
---@return number
function transposer.transferItem(sourceSide,sinkSide,count,sourceSlot,sinkSlot) end

---Get whether the items in the two specified slots of the inventory on the specified side of the device are of the same type.
---@param side number
---@param slotA number
---@param slotB number
---@return boolean
function transposer.compareStacks(side, slotA,slotB) end

---Get whether the items in the two specified slots of the inventory on the specified side of the device are equivalent (have shared OreDictionary IDs).
---@param side number
---@param slotA number
---@param slotB number
---@return boolean
function transposer.areStacksEquivalent(side, slotA,slotB) end

---Get the number of tanks available on the specified side.
---@param side number
---@return number
function transposer.getTankCount(side) end

---Get a description of the stack in the inventory on the specified side of the device.
---@param side number
---@param slot number
---@return ItemStack?
function transposer.getStackInSlot(side, slot) end

---Get the capacity of the specified tank on the specified side.
---@param side number
---@param tank number
---@return number
function transposer.getTankCapacity(side,tank) end


---Get a description of all stacks in the inventory on the specified side of the device.\
---The return value is callable. Calling it will return a table describing the stack in the inventory or nothing if the iterator reaches end.
---
---The return value provides the followings callbacks:
---
---``getAll():table``\
---Returns ALL the stack in the this.array. Memory intensive.\
---``count():number``\
---Returns the number of elements in the this.array.\
---``reset()``\
---Reset the iterator index so that the next call will return the first element.
---@param side number
---@return ItemIterator
function transposer.getAllStacks(side) end

---@class ItemIterator
---@overload fun():ItemStack
---@field getAll fun():ItemStack[] @Returns ALL the stack in the this.array. Memory intensive.
---@field count fun():number @Returns the number of elements in the this.array.
---@field reset fun() @Reset the iterator index so that the next call will return the first element.


---@class ItemStack
---@field hasTag boolean
---@field label string
---@field maxDamage number
---@field maxSize number
---@field name string
---@field size number
---@field damage number
---@field id number
