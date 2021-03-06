local rob = require("robot")
local os = require("os")
local component =  require("component")
local computer = require("computer")

local sides = require("sides")

local inventoryControleur = component.inventory_controller
local generator = component.generator
local chunk = component.chunkloader

chunk.setActive(true)

local height = 4
local width = 4

local invSize = rob.inventorySize()
local maxEnergy = computer.maxEnergy()

local function startCheck()
	local ender = inventoryControleur.getStackInInternalSlot(1)
	local coal = inventoryControleur.getStackInInternalSlot(2)
	if not ender or ender.name ~= "enderstorage:ender_storage" or not coal or coal.name ~= "minecraft:coal" then
		error("no enderchest in slot 1 or coal in slot 2")
	end
end

local function forward()
	rob.swing()
	if not rob.forward() then
		os.sleep(2)
		forward()
	end
end

local function move(pos)
	for i = 1, pos do
		forward()
	end
end

local function empty()
	rob.select(1)
	local ok = rob.placeUp()
	if ok then
		for i = 3, invSize do
			rob.select(i)
			rob.dropUp()
		end
		rob.select(2)
		rob.swingUp()
	end
end

---@param _side boolean @false right, true left
local function half_turn(_side)
	if _side then
		rob.swing()
		rob.turnLeft()
		move(3)
		rob.swing()
		rob.turnLeft()
	else
		rob.swing()
		rob.turnRight()
		move(3)
		rob.swing()
		rob.turnRight()
	end
end

local function energy()
	rob.select(2)
	local currentEnergy = computer.energy()/maxEnergy
	local count = generator.count()
	if currentEnergy < 0.8 then
		if  count < 10 then
			generator.insert(10-count)
		end
	end
end


local sideflip = false
local function main()
	startCheck()
	while true do
		for i = 1, width - 1 do
			move(height)
			half_turn(sideflip)
			sideflip = not sideflip
		end
		move(height)
		empty()
		for i = 1, 2 do
			rob.swingDown()
			rob.down()
		end
		rob.swingDown()
		if not rob.down() then
			os.exit()
		end
		rob.turnAround()
		energy()
	end
end

main()