---@meta robot

---@class robotLib
local robot = {}

--- Returns the robot's name.
--- The name of a Robot is set initially during its creation and cannot be changed programmatically. However, you can change it using an anvil if you want.
---@return string The name of the robot.
function robot.name() end

--- Detects what is directly in front of the robot and returns if the robot could move through it as well as a generic description.
--- Returns: true if whatever is in front of the robot would prevent it from moving forward (a block or an entity) (Note: Drones return true even if the block is passable), false otherwise.
--- The second parameter describes what is in front in general and is one of either entity, solid, replaceable, liquid, passable, or air.
---@return boolean, string Whether the robot could move forward and the description of what is in front.
function robot.detect() end

--- As robot.detect() except that it scans the block directly above the robot.
---@return boolean, string Whether the robot could move upward and the description of what is above.
function robot.detectUp() end

--- As robot.detect() except that it scans the block directly below the robot.
---@return boolean, string Whether the robot could move downward and the description of what is below.
function robot.detectDown() end

--- Selects the given inventory slot (if specified) and returns the current inventory slot.
--- slot - the slot to select. If this parameter is omitted, no slot is selected.
--- Returns the currently selected slot. Either the one specified (if successfully selected) or the one that was previously selected.
---@param slot number? optional. The slot to select.
---@return number The currently selected slot.
function robot.select(slot) end

--- Returns the amount of selectable internal robot inventory slots.
--- To get the number of inventory upgrades, use: x = robot.inventorySize() / 16.
---@return number The amount of selectable internal robot inventory slots.
function robot.inventorySize() end

--- Returns the amount of items currently in the specified or selected slot.
--- slot - specifies the slot to count the items in. If omitted the currently selected slot is counted instead.
---@param slot number? optional. Specifies the slot to count the items in.
---@return number The amount of items in the specified or selected slot.
function robot.count(slot) end

--- Returns the amount of items that can still be added to the specified slot until it is filled up.
--- slot - specifies the slot to count the items in. If omitted the currently selected slot is counted instead.
---@param slot number? optional. Specifies the slot to count the items in.
---@return number The amount of items that can still be added to the specified or selected slot until it is considered full.
function robot.space(slot) end

--- Moves all or up to count items from the currently selected slot to the specified slot.
--- slot - specifies the slot move the items from the currently selected slot to.
--- count - if specified only up to this many items are moved, otherwise the entire stack is moved.
--- Returns true if exchanging the content between those slots was successful, false otherwise.
---@param slot number The slot to move the items to.
---@param count number? optional. The amount of items to move.
---@return boolean Whether the transfer was successful.
function robot.transferTo(slot, count) end

--- Compares the item of the currently selected slot to the item of the slot specified and returns whether they are equal or not.
--- slot - specifies the slot to compare the current slot to.
--- Returns true if the item type in the specified slot and the currently selected slot are equal, false otherwise.
--- Two items are considered the 'same' if their item type and metadata are the same. Stack size or any additional mod-specific item informations (like for example the content of two floppy disks) are not checked.
---@param slot number The slot to compare the currently selected slot to.
---@return boolean Whether the items are equal.
function robot.compareTo(slot) end

--- Compares the block in front of the robot with the item in the currently selected slot and returns whether they are the same or not.
--- Returns true if the block in front and the item in the currently selected slot are the same, false otherwise.
--- Blocks are considered the 'same' if their type and metadata are the same. Stack size or any additional informations (like for example the inventory of a container) are not checked.
---@return boolean Whether the block in front and the item in the currently selected slot are the same.
function robot.compare() end

--- As robot.compare() just for the block directly above the robot.
---@return boolean Whether the block above and the item in the currently selected slot are the same.
function robot.compareUp() end

--- As robot.compare() just for the block directly below the robot.
---@return boolean Whether the block below and the item in the currently selected slot are the same.
function robot.compareDown() end

--- Tries to drop items from the currently selected inventory slot in front of the robot.
--- Note that if you are trying to drop items into an inventory below you, use dropDown for that case.
--- This method, drop, will drop the items to the front.
--- count - specifies how many items to drop. If omitted or if count exceeds the amount of items in the currently selected slot, then all items in the currently selected slot are dropped.
--- Returns true if at least one item was dropped, false otherwise.
--- If the block or entity immediately in front of the robot has an accessible item inventory, the robot will try to put those items into this inventory instead of throwing them into the world.
--- If the block in front has an inventory but the item could not be moved into it for any reason, then this function returns false and does not move any items.
--- This function cannot interact with non-item inventories (like for example fluid tanks) and will not consider them an inventory, so items will be thrown into the world instead.
---@param count number? optional. Specifies how many items to drop.
---@return boolean Whether at least one item was dropped.
function robot.drop(count) end

--- As robot.drop just for the block directly above the robot.
---@return boolean Whether at least one item was dropped upward.
function robot.dropUp() end

--- As robot.drop just for the block directly below the robot.
---@return boolean Whether at least one item was dropped downward.
function robot.dropDown() end

--- Tries to pick up items from directly in front of the robot and puts them into the selected slot or (if occupied) the first possible slot.
--- count - limits the amount of items to pick up by this many. If omitted a maximum of one stack is taken.
--- Returns true if at least one item was picked up, false otherwise.
--- If there are multiple items in front of the robot, this will pick them up based on the distance to the robot.
---@param count number? optional. Limits the amount of items to pick up.
---@return boolean Whether at least one item was picked up.
function robot.suck(count) end

--- As robot.suck except that it tries to pick up items from directly above the robot.
---@param count number? optional. Limits the amount of items to pick up.
---@return boolean Whether at least one item was picked up.
function robot.suckUp(count) end

--- As robot.suck except that it tries to pick up items from directly below the robot.
---@param count number? optional. Limits the amount of items to pick up.
---@return boolean Whether at least one item was picked up.
function robot.suckDown(count) end

--- Tries to place the block in the currently selected inventory slot in front of the robot.
--- side - if specified this determines the surface on which the robot attempts to place the block, for example, to place torches on a specific side.
--- If omitted, the robot will try all possible sides.
--- sneaky - if set to true, the robot will simulate a sneak-placement.
--- Returns true if an item could be placed, false otherwise.
--- If placement failed, the secondary return parameter will describe why the placement failed.
---@param side number? optional. Determines the surface on which the robot attempts to place the block.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether an item could be placed.
---@return string|nil If placement failed, describes why the placement failed.
function robot.place(side, sneaky) end

--- As robot.place except that the robot tries to place the item into the space directly above it.
---@param side number? optional. Determines the surface on which the robot attempts to place the block.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether an item could be placed upward.
---@return string|nil If placement failed, describes why the placement failed.
function robot.placeUp(side, sneaky) end

--- As robot.place except that the robot tries to place the item into the space directly below it.
---@param side number? optional. Determines the surface on which the robot attempts to place the block.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether an item could be placed downward.
---@return string|nil If placement failed, describes why the placement failed.
function robot.placeDown(side, sneaky) end

--- Makes the robot use the item currently in the tool slot against the block or space immediately in front of the robot.
--- side - if given the robot will try to 'left-click' only on the surface as specified by side, otherwise the robot will try all possible sides.
--- Returns true if the robot could interact with the block or entity in front of it, false otherwise.
--- If successful, the secondary parameter describes what the robot interacted with and will be one of 'entity', 'block', or 'fire'.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether the robot could interact with the block or entity.
---@return string|nil If successful, describes what the robot interacted with.
function robot.swing(side, sneaky) end

--- Makes the robot use the item currently in the tool slot against the block or space directly above the robot.
--- side - if given the robot will try to 'left-click' only on the surface as specified by side, otherwise the robot will try all possible sides.
--- Returns true if the robot could interact with the block or entity above it, false otherwise.
--- If successful, the secondary parameter describes what the robot interacted with and will be one of 'entity', 'block', or 'fire'.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether the robot could interact with the block or entity.
---@return string|nil If successful, describes what the robot interacted with.
function robot.swingUp(side, sneaky) end

--- Makes the robot use the item currently in the tool slot against the block or space directly below the robot.
--- side - if given the robot will try to 'left-click' only on the surface as specified by side, otherwise the robot will try all possible sides.
--- Returns true if the robot could interact with the block or entity below it, false otherwise.
--- If successful, the secondary parameter describes what the robot interacted with and will be one of 'entity', 'block', or 'fire'.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-placement.
---@return boolean Whether the robot could interact with the block or entity.
---@return string|nil If successful, describes what the robot interacted with.
function robot.swingDown(side, sneaky) end

--- Attempts to use the item currently equipped in the tool slot in the same way as if the player would make a right-click.
--- side - if given the robot will try to 'right-click' only on the surface as specified by side, otherwise the robot will try all possible sides.
--- sneaky - if set to true the robot will simulate a sneak-right-click.
--- duration - how long the item is used. This is useful when using charging items like a bow.
--- Returns: true if the robot could interact with the block or entity in front of it, false otherwise.
--- If successful, the secondary parameter describes what the robot interacted with and will be one of 'blockactivated', 'itemplaced', 'iteminteracted', or 'itemused'.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-right-click.
---@param duration number? optional. How long the item is used.
---@return boolean Whether the robot could interact with the block or entity.
---@return string|nil If successful, describes what the robot interacted with.
function robot.use(side, sneaky, duration) end

--- As robot.use except that the item is used aiming at the area above the robot.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-right-click.
---@param duration number? optional. How long the item is used.
---@return boolean Whether the robot could interact with the block or entity above it.
---@return string|nil If successful, describes what the robot interacted with.
function robot.useUp(side, sneaky, duration) end

--- As robot.use except that the item is used aiming at the area below the robot.
---@param side number? optional. Determines the surface on which the robot attempts to interact.
---@param sneaky boolean? optional. Whether to simulate a sneak-right-click.
---@param duration number? optional. How long the item is used.
---@return boolean Whether the robot could interact with the block or entity below it.
---@return string|nil If successful, describes what the robot interacted with.
function robot.useDown(side, sneaky, duration) end

--- Tries to move the robot forward.
--- Returns: true if the robot successfully moved, nil otherwise.
--- If movement fails, a secondary result will be returned describing why it failed.
---@return boolean Whether the robot successfully moved.
---@return string|nil Description of why movement failed.
function robot.forward() end

--- As robot.forward() except that the robot tries to move backward.
---@return boolean Whether the robot successfully moved.
---@return string|nil Description of why movement failed.
function robot.back() end

--- As robot.forward() except that the robot tries to move upwards.
---@return boolean Whether the robot successfully moved.
---@return string|nil Description of why movement failed.
function robot.up() end

--- As robot.forward() except that the robot tries to move downwards.
---@return boolean Whether the robot successfully moved.
---@return string|nil Description of why movement failed.
function robot.down() end

--- Turns the robot 90° to the left.
function robot.turnLeft() end

--- Turns the robot 90° to the right.
function robot.turnRight() end

--- Turns the robot 180°.
function robot.turnAround() end

--- Deprecated since OC 1.3. Use component.experience.level() instead (only available if the experience upgrade is installed).
--- Returns the current level of the robot, with the fractional part being the percentual progress towards the next level.
---@return number The current level of the robot.
function robot.level() end

--- The number of tanks installed in the robot.
---@return number The number of tanks installed in the robot.
function robot.tankCount() end

--- Selects the specified tank. This determines which tank most operations operate on.
---@param tank number The tank to select.
function robot.selectTank(tank) end

--- The current fluid level in the specified tank, or, if none is specified, the selected tank.
---@param tank number? optional. The specified tank.
---@return number The current fluid level in the specified tank.
function robot.tankLevel(tank) end

--- The remaining fluid capacity in the specified tank, or, if none is specified, the selected tank.
---@param tank number? optional. The specified tank.
---@return number The remaining fluid capacity in the specified tank.
function robot.tankSpace(tank) end

--- Tests whether the fluid in the selected tank is the same as in the specified tank.
---@param tank number The specified tank.
---@return boolean Whether the fluid in the selected tank is the same as in the specified tank.
function robot.compareFluidTo(tank) end

--- Transfers the specified amount of fluid from the selected tank into the specified tank.
--- If no volume is specified, tries to transfer 1000 mB.
---@param tank number The specified tank.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the transfer was successful.
function robot.transferFluidTo(tank, count) end

--- Tests whether the fluid in the selected tank is the same as in the world or the tank in front of the robot.
---@return boolean Whether the fluid in the selected tank is the same as in the world or the tank in front of the robot.
function robot.compareFluid() end

--- Like robot.compareFluid, but operates on the block above the robot.
---@return boolean Whether the fluid in the selected tank is the same as in the block above the robot.
function robot.compareFluidUp() end

--- Like robot.compareFluid, but operates on the block below the robot.
---@return boolean Whether the fluid in the selected tank is the same as in the block below the robot.
function robot.compareFluidDown() end

--- Extracts the specified amount of fluid from the world or the tank in front of the robot.
--- When no amount is specified, will try to drain 1000 mB.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the extraction was successful.
function robot.drain(count) end

--- Like robot.drain, but operates on the block above the robot.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the extraction was successful.
function robot.drainUp(count) end

--- Like robot.drain, but operates on the block below the robot.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the extraction was successful.
function robot.drainDown(count) end

--- Injects the specified amount of fluid from the selected tank into the world or the tank in front of the robot.
--- When no amount is specified, will try to eject 1000 mB.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the injection was successful.
function robot.fill(count) end

--- Like robot.fill, but operates on the block above the robot.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the injection was successful.
function robot.fillUp(count) end

--- Like robot.fill, but operates on the block below the robot.
---@param count number? optional. The specified amount of fluid.
---@return boolean Whether the injection was successful.
function robot.fillDown(count) end

return robot