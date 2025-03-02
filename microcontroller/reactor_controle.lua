-- IC2 Reactor Control Program for OpenComputers Microcontroller
---require a Transposer and a Redstone Card in the Microcontroller

--constants
local CHECK_RODS_COUNTDOWN = 10
local VENTS_NUMBER_CHECK_EVERY_CYCLE = 2
local SLEEP_TIME = 3
local INVENTORY_NAMES = {"tile.appliedenergistics2.BlockInterface", "tile.chest"}

local component = component or require("component") ---@type componentLib
local computer = computer or require("computer") ---@type computerlib
local sides = { down = 0, up = 1, north = 2, south = 3, west = 4, east = 5 }

local ts
if component.list("transposer")() then
	ts = component.proxy(component.list("transposer")()) ---@cast ts transposer
end
if not ts then
	error("No transposer found")
end

local rs
if component.list("redstone")() then
	rs = component.proxy(component.list("redstone")()) ---@cast rs any
end
if not rs then
	error("No redstone card found")
end

local function found(name)
	for _, side in pairs(sides) do
		if ts.getInventoryName(side) == name then
			return side
		end
	end
end

local chest
for _, value in ipairs(INVENTORY_NAMES) do
	chest = found(value)
	if chest then
		break
	end
end
if not chest then
	error("No chest found")
end

local reactor = found("blockReactorChamber") or found("blockGenerator")
if not reactor then
	error("No reactor found")
end
local battery = found("gt.blockmachines")
if not battery then
	error("No battery found")
end
local fuelRods = {}
local vents = {}
local function scanReactor()
	local reactorSize = ts.getInventorySize(reactor)
	for i = 1, reactorSize do
		local stack = ts.getStackInSlot(reactor, i)
		if stack and stack.label:find("Fuel Rod") then
			fuelRods[i] = stack.name
		end
		if stack and stack.label:find("Heat Vent") then
			vents[i] = stack.label
		end
	end
end

local _cache = {}
---@param name string
---@param start? number
---@return number? -- inventory slot
local function foundItemInChest(name, start)
	if _cache[name] then
		local stack = ts.getStackInSlot(chest, _cache[name])
		if stack and stack.name == name and not start then
			return _cache[name]
		else
			_cache[name] = nil
		end
	end
	local size = ts.getInventorySize(chest)
	for i = start or 1, size do
		local stack = ts.getStackInSlot(chest, i)
		if stack and stack.name == name then
			_cache[name] = i
			return i
		end
	end
end

---@param name string
---@param start? number
---@return number? -- inventory slot
local function getAvailableStorageSlot(name, start)
	local slottostore = foundItemInChest(name, start)
	if slottostore then
		local i = ts.getStackInSlot(chest, slottostore)
		if i and i.size == i.maxSize then
			return getAvailableStorageSlot(name, slottostore + 1)
		end
		return slottostore
	end
end

local function checkFuelRods()
	for index, name in pairs(fuelRods) do
		local stack = ts.getStackInSlot(reactor, index)
		if not stack or stack.name ~= name then
			local rodtoload = foundItemInChest(name)
			local slotforstore
			if stack then
				slotforstore = getAvailableStorageSlot(stack.name)
			end
			if rodtoload then
				if slotforstore then
					ts.transferItem(reactor, chest, 1, index, slotforstore)
				else
					ts.transferItem(reactor, chest, 1, index)
				end
				ts.transferItem(chest, reactor, 1, rodtoload, index)
			end
		end
	end
end

local lastVentsCheck
---@param numberOfVentsToCheck number?
local function checkVents(numberOfVentsToCheck)
	for _ = 1, numberOfVentsToCheck or 1 do
		local index = next(vents, lastVentsCheck) or next(vents)
		if not index then error("no vent in reactor") end
		local stack = ts.getStackInSlot(reactor, index)
		if stack then
			if stack.damage / stack.maxDamage > 0.3 then
				rs.setOutput({ [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 })
				error(vents[index] .. " overheating at slot: " .. index)
			end
		else
			error(vents[index] .. " missing at slot: " .. index)
		end
		lastVentsCheck = index
	end
end

local charging = false
local function getBatteryStatus()
	local inv = ts.getAllStacks(battery)
	if not inv then return "high" end
	local hasBattery = false
	for stack in inv do
		if stack.charge and stack.maxCharge then
			hasBattery = true
			if stack.charge / stack.maxCharge < 0.2 then return "low" end
			if stack.charge / stack.maxCharge > 0.8 then return "high" end
		end
	end
	if not hasBattery then
		return "high"
	end
end

local function main()
	scanReactor()
	local batteryStatus = nil
	while true do
		checkVents(VENTS_NUMBER_CHECK_EVERY_CYCLE)
		if CHECK_RODS_COUNTDOWN < 0 then
			checkFuelRods()
			CHECK_RODS_COUNTDOWN = 1
		end
		batteryStatus = getBatteryStatus()
		if batteryStatus == "low" and not charging then
			rs.setOutput({ [0] = 15, [1] = 15, [2] = 15, [3] = 15, [4] = 15, [5] = 15 })
			charging = true
		elseif batteryStatus == "high" and charging then
			rs.setOutput({ [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 })
			charging = false
		end
		CHECK_RODS_COUNTDOWN = CHECK_RODS_COUNTDOWN - 1
		computer.pullSignal(SLEEP_TIME)
	end
end

main()
