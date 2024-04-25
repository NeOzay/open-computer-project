---@meta _

---@class inventory_controller:ProxyBase
local inventory_controller = {}
--- Returns the size of the inventory at the specified side.
--- side - must be a valid side.
--- Returns: the size of the inventory, or nil followed by a description why this function failed (usually no inventory).
---@param side number The side of the inventory.
---@return number|nil,string @The size of the inventory or nil followed by a description of the failure.
function inventory_controller.getInventorySize(side) end

--- Returns a table describing the item in the specified slot or nil.\
--- Deprecated for getting info about robot's own inventory, see getStackInInternalSlot.\
--- side - must be a valid side.\
--- slot - the slot to analyze. This does not check the inventory size and will consider slots outside the inventory bounds to be empty.\
---
--- Returns: nil if the slot was empty (or outside the inventory's bounds), a table otherwise with the following information about the item in that slot:\
--- **damage**:number - the current damage value of the item.\
--- **maxDamage**:number - the maximum damage this item can have before it breaks.\
--- **size**:number - the current stack size of the item.\
--- **maxSize**:number - the maximum stack size of this item.\
--- **id**:number - the Minecraft id of the item. Note that this field is only included if insertIdsInConverters=true in the configs, and can vary between servers!\
--- **name**:string - the untranslated item name, which is an internal Minecraft value like oc:item.FloppyDisk\
--- **label**:string - the translated item name\
--- **hasTag**:boolean - whether or not the item has an NBT tag associated with it.\
---@param side number The side of the inventory.
---@param slot number The slot to analyze.
---@return ItemStack|nil @A table describing the item in the slot, or nil if the slot is empty.
function inventory_controller.getStackInSlot(side, slot) end

--- Gets Itemstack description of item in specified or selected slot (if no input provided) of robot inventory.
---@param slot number? Optional. The slot to get the item from. If not provided, the currently selected slot is used.
---@return ItemStack|nil @A table describing the item in the slot, or nil if the slot is empty.
function inventory_controller.getStackInInternalSlot(slot) end

--- Puts up to count items from the currently selected slot into the specified slot of the inventory at the specified side.
--- side - a valid side.
--- slot - the slot to drop the item into.
--- count - how many items to transfer.
--- Returns: true if at least one item was moved, false and a secondary result that describes the error otherwise.
--- Note that the robot cannot drop items into its own inventory, attempting to do so will cause this to throw an error.
---@param side number The side of the inventory.
---@param slot number The slot to drop the item into.
---@param count number? Optional. How many items to transfer.
---@return boolean,string @true if at least one item was moved, false and a secondary result that describes the error otherwise.
function inventory_controller.dropIntoSlot(side, slot, count) end

--- Takes up to count items from the specified slot of the inventory at the specified side and puts them into the currently selected slot.
--- side - a valid side.
--- slot - the slot to take the item from.
--- count - how many items to transfer.
--- Returns: true if at least one item was moved, false otherwise.
--- If the currently selected slot is occupied, then the items will be stacked with similar items in the robot's inventory or moved to the next free slot if available.
---@param side number The side of the inventory.
---@param slot number The slot to take the item from.
---@param count number? Optional. How many items to transfer.
---@return boolean @true if at least one item was moved, false otherwise.
function inventory_controller.suckFromSlot(side, slot, count) end

--- Swaps the content of the robot's tool slot with the content of the currently selected inventory slot.
--- Returns: true if the items were swapped, false otherwise. This operation usually succeeds.
--- Note that you can put any kind of item into the robot's tool slot, not only tools, even items that the robot cannot use at all.
---@return boolean @true if the items were swapped, false otherwise.
function inventory_controller.equip() end

--- Stores the Itemstack description of the item from the specified slot in an inventory on the specified side, into a specified database slot with the specified address.
---@param side number The side of the inventory.
---@param slot number The slot to store the item from.
---@param dbAddress string The address of the database.
---@param dbSlot number The slot of the database to store the item in.
---@return boolean @true if the item was stored successfully, false otherwise.
function inventory_controller.store(side, slot, dbAddress, dbSlot) end

--- Stores Itemstack description of item in specified robot inventory slot into specified database slot with the specified database address.
---@param slot number The slot of the robot inventory to store the item from.
---@param dbAddress string The address of the database.
---@param dBslot number The slot of the database to store the item in.
---@return boolean @true if the item was stored successfully, false otherwise.
function inventory_controller.storeInternal(slot, dbAddress, dBslot) end

--- Compare Itemstack description in specified slot with one in specified slot of a database with specified address.
--- Returns true if items match.
---@param slot number The slot to compare.
---@param dBaddress string The address of the database.
---@param dBslot number The slot of the database to compare.
---@return boolean @true if items match, false otherwise.
function inventory_controller.compareToDatabase(slot, dBaddress, dBslot) end

--- Checks to see if Itemstack descriptions in specified slotA and slotB of inventory on specified side match.
--- Returns true if identical.
---@param side number The side of the inventory.
---@param slotA number The first slot to compare.
---@param slotB number The second slot to compare.
---@return boolean @true if items match, false otherwise.
function inventory_controller.compareStacks(side, slotA, slotB) end

--- Gets maximum number of items in specified slot in inventory on the specified side.
---@param side number The side of the inventory.
---@param slot number The slot to check.
---@return number @The maximum number of items in the slot.
function inventory_controller.getSlotMaxStackSize(side, slot) end

--- Gets number of items in specified slot in inventory on the specified side.
---@param side number The side of the inventory.
---@param slot number The slot to check.
---@return number @The number of items in the slot.
function inventory_controller.getSlotStackSize(side, slot) end
