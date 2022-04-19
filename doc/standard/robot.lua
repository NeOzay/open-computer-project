
---@class robot
local robot = {}

---Returns the robot's name.
---
---The name of a Robot is set initially during it's creation and cannot be changed programmatically. However you can change it using an anvil if you want.
---@return string
function robot.name() end

---@alias detectEnum "entity"|"solid"|"replaceable"|"liquid"|"passable"|"air"

---Detects what is directly in front of the robot and returns if the robot could move through it as well as a generic description.
---@return boolean, detectEnum @*true* if the robot if whatever is in front of the robot would prevent him from moving forward (a block or an entity) (Note: Drones return *true* even if the block is *passable*), *false* otherwise. The second parameter describes what is in front in general and is one of either *entity*, *solid*, *replaceable*, *liquid*, *passable* or *air*.
function robot.detect() end

---As *robot.detect()* except that it scans the block directly above the robot.
---@return boolean, detectEnum
function robot.detectUp() end

---As *robot.detect()* except that it scans the block directly below the robot.
---@return boolean, detectEnum
function robot.detectDown() end

---Selects the given inventory slot (if specified) and returns the current inventory slot.
---@param slot? number @the slot to select. If this parameter is omitted, no slot is selected.
---@return number @the currently selected slot. Either the one specified (if successfully selected) or the one that was previously selected.
function robot.select(slot) end

---@return number @the amount of select-able internal robot inventory slots. To get the number of inventory upgrade use: x = robot.inventorySize() / 16.
function robot.inventorySize() end

---Returns the amount of items currently in the specified or selected slot.
---@param slot? number @specifies the slot to count the items in. If omitted the currently selected slot is counted instead.
---@return number @the amount of items in the slot specified or the currently selected slot if no slot was given.
function robot.count(slot) end


---Returns the amount of items that can still be added to the specified slot until it is filled up.
---
---This function helps to determine how many items of a type can be added to a specific slot. While for example cobblestone can pile up to 64 items per slot, empty buckets can only stack up to 16 and other blocks like doors can only take 1 item per slot.
---@param slot? number @specifies the slot to count the items in. If omitted the currently selected slot is counted instead.
---@return number @the amount of items that can still be added to the the slot specified or the currently selected slot until it is considered full.
function robot.space(slot) end


---Moves all or up to count items from the currently selected slot to the specified slot.
---
---If there are items in the target slot then this function attempts to swap the items in those slots. This only succeeds if you move all items away from the current slot or if the current slot was empty anyways.
---
---Note that this will always return true if the specified slot is the same as the currently selected slot, or if both slots are empty, even though no items are effectively moved.
---@param slot number @specifies the slot move the items from the currently selected slot to.
---@param count? number @if specified only up to this many items are moved, otherwise the entire stack is moved.
---@return boolean @*true* if exchanging the content between those slots was successful, *false* otherwise.
function robot.transferTo(slot, count) end

---Compares the item of the currently selected slot to the item of the slot specified and returns whether they are equal or not.
---
---Two items are considered the 'same' if their item type and metadata are the same. Stack size or any additional mod-specific item informations (like for example the content of two floppy disks) are not checked.
---@param slot number @specifies the slot to compare the current slot to.
---@return boolean @true if the item type in the specified slot and the currently selected slot are equal, false otherwise.
function robot.compareTo(slot) end

---Compares the block in front of the robot with the item in the currently selected slot and returns whether they are the same or not.
---
---Blocks are considered the 'same' if their type and metadata are the same. Stack size or any additional informations (like for example the inventory of a container) are not checked.
---
---Note that empty space in front of the robot is considered an 'air block' by the game, which cannot be put into an inventory slot and therefore compared by normal means. An empty slot and an air block are not the same. You can use *robot.detect()* beforehand to determine if there is actually a block in front of the robot.
---
---Also keep in mind that blocks that drop items need to be compared to the actual same block that is in the world. For example stone blocks drop as cobblestone and diamond ores drop diamond items, which are not the same for this function. Use silk-touch items to retrieve the actual block in the world for comparison.
---@return boolean
function robot.compare() end

---As robot.compare just for the block directly above the robot.
---@return boolean
function robot.compareUp() end

---As robot.compare just for the block directly below the robot.
---@return boolean
function robot.compareDown() end

---Tries to move the robot forward.
---
---The result 'impossible move' is kind of a fall-back result and will be returned for example if the robot tries to move into an area of the world that is currently not loaded.
---@return boolean, string @Returns: true if the robot successfully moved, nil otherwise. If movement fails a secondary result will be returned describing why it failed, which will either be 'impossible move', 'not enough energy' or the description of the obstacle as robot.detect would return. The result 'not enough energy' is rarely returned as being low on energy usually causes the robot to shut down beforehand.
function robot.forward() end

---As *robot.forward()* except that the robot tries to move backward.
---@return boolean, string
function robot.back() end

---As *robot.forward()* except that the robot tries to move upwards.
---@return boolean, string
function robot.up() end

---As *robot.forward()* except that the robot tries to move downwards.
---@return boolean, string
function robot.down() end

---Turns the robot 90° to the left.
---
---Note that this can only fail if the robot has not enough energy to perform the turn but has not yet shut down because of it.
function robot.turnLeft() end

---As *robot.turnLeft* except that the robot turns 90° to the right.
function robot.turnRight() end

---This is the same as calling *robot.turnRight* twice.
function robot.turnAround() end


---Makes the robot use the item currently in the tool slot against the block or space immediately in front of the robot in the same way as if a player would make a left-click.
---
---This can be used to mine blocks or fight entities in the same way as if the player did a left-click. Note that tools and weapons do lose durability in the same way as if a player would use them and need to be replaced eventually. Items mined or dropped of mobs will be put into the inventory if possible, otherwise they will be dropped to the ground.
---
---Note that even though the action is performed immediately (like a block being destroyed) this function will wait for a while appropriate to the action performed to simulate the time it would take a player to do the same action. This is most noticeable if you try to mine obsidian blocks: they are destroyed and put into the inventory immediately, but the function will wait for a few seconds.
---
---If this is used to mine blocks, then the tool equipped needs to be sufficient to actually mine the block in front. If for example a wooden pick-axe is used on an obsidian block this will return false. Everything (including an empty slot) can be used to fight mobs, but the damage will be based on the item used. Equally everything can be used to extinguish fire, and items with durability will not lose any if done so.
---@param side? number @ if given the robot will try to 'left-click' only on the surface as specified by side, otherwise the robot will try all possible sides. See the **Sides API** for a list of possible sides.
---@param sneaky? boolean
---@return boolean, string @true if the robot could interact with the block or entity in front of it, false otherwise. If successful the secondary parameter describes what the robot interacted with and will be one of 'entity', 'block' or 'fire'.
function robot.swing(side, sneaky) end

---As *robot.swing* except that the block or entity directly above the robot will be the target.
---@param side? number
---@param sneaky? boolean
---@return boolean, string
function robot.swingUp(side, sneaky) end

---As *robot.swing* except that the block or entity directly below the robot will be the target.
---@param side? number
---@param sneaky? boolean
---@return boolean, string
function robot.swingDown(side, sneaky) end


function robot.drop() end

function robot.dropUp() end

function robot.dropDown() end

return robot