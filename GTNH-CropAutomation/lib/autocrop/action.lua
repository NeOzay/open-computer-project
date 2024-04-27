local component = require('component')
local robot = require('robot')
local sides = require('sides')
local computer = require('computer')
local os = require('os')

local gps = require('autocrop.gps')
local config = require('autocrop.config')
local signal = require('autocrop.signal')
local scanner = require('autocrop.scanner')
local posUtil = require('autocrop.posUtil')
local database = require('autocrop.database')
local inventory_controller = component.inventory_controller


local function needCharge()
    return computer.energy() / computer.maxEnergy() < config.needChargeLevel
end


local function fullyCharged()
    return computer.energy() / computer.maxEnergy() > 0.99
end


local function fullInventory()
    for i=1, robot.inventorySize() do
        if robot.count(i) == 0 then
            return false
        end
    end
    return true
end


local function charge()
    gps.go(config.chargerPos)
    gps.turnTo(1)
    repeat
        os.sleep(0.5)
    until fullyCharged()
end


local function restockStick(comeBack)
    local selectedSlot = robot.select()
    if comeBack then
        gps.save()
    end
    gps.go(config.stickContainerPos)
    robot.select(config.stickSlot)
    for i=1, inventory_controller.getInventorySize(sides.down) do
        inventory_controller.suckFromSlot(sides.down, i, 64-robot.count())
        if robot.count() == 64 then
            break
        end
    end
    if comeBack then
        gps.restore()
    end
    robot.select(selectedSlot)
end


local function dumpInventory()
    local selectedSlot = robot.select()

    gps.go(config.storagePos)
    for i=1, (config.storageStopSlot) do
        if robot.count(i) > 0 then
            robot.select(i)
            for e=1, inventory_controller.getInventorySize(sides.down) do
                if inventory_controller.getStackInSlot(sides.down, e) == nil then
                    inventory_controller.dropIntoSlot(sides.down, e)
                    break
                end
            end
        end
    end

    robot.select(selectedSlot)
end


local function restockAll()
    dumpInventory()
    restockStick()
    charge()
end


local function placeCropStick(count)
    count = count or 1
    local selectedSlot = robot.select()
    if robot.count(config.stickSlot) < count + 1 then
        restockStick(true)
    end
    robot.select(config.stickSlot)
    inventory_controller.equip()
    for _=1, count do
        robot.useDown(sides.up)
    end
    inventory_controller.equip()
    robot.select(selectedSlot)
end


local function deweed()
    local selectedSlot = robot.select()
    if config.keepDrops and fullInventory() then
        dumpInventory()
    end
    robot.select(config.spadeSlot)
    inventory_controller.equip()
    robot.useDown()
    if config.keepDrops then
        robot.suckDown()
    end
    scanner.scan()
    inventory_controller.equip()
    robot.select(selectedSlot)
end

---@param crop crop
---@param target crop
---@return boolean success
---@overload fun(crop:crop, target:{x:number, y:number})
local function transplant(crop, target)
    local selectedSlot = robot.select()
    gps.save()
    robot.select(config.binderSlot)
    inventory_controller.equip()

    -- TRANSFER TO RELAY LOCATION
    gps.go(config.dislocatorPos)
    robot.useDown(sides.down)
    gps.go(crop.x, crop.y)
    robot.useDown(sides.down, true)
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- TRANSFER CROP TO DESTINATION
    robot.useDown(sides.down, true)
    gps.go(target.x, target.y)

    local locate = scanner.scan()
    if locate.name == 'air' then
        placeCropStick()
    elseif locate.isCrop == false then
        print('transplant failed at x:', locate.x, 'y:', locate.y)
        gps.restore()
        robot.select(selectedSlot)
        return false
    end

    robot.useDown(sides.down, true)
    gps.go(config.dislocatorPos)
    signal.pulseDown()

    -- DESTROY ORIGINAL CROP
    inventory_controller.equip()
    gps.go(config.relayFarmlandPos)
    robot.swingDown()
    if config.KeepDrops then
        robot.suckDown()
    end

    database.copy(crop, target.x, target.y)
    gps.restore()
    robot.select(selectedSlot)
    return true
end



return {
    needCharge = needCharge,
    charge = charge,
    restockStick = restockStick,
    dumpInventory = dumpInventory,
    restockAll = restockAll,
    placeCropStick = placeCropStick,
    deweed = deweed,
    transplant = transplant,
}