local gps = require('autocrop.gps')
local scanner = require('autocrop.scanner')
local action = require('autocrop.action')
local database = require('autocrop.database')

local config = require('autocrop.config')

local manager = require('autocrop.manager')

local running = true

---@param crop crop
---@param plot Plot
local function checkChild(plot, crop)
	if not crop.isCrop or  crop.name == 'emptyCrop' then
		return
	end

	if crop.name == 'air' then
		action.placeCropStick(2)
	elseif scanner.isWeed(crop, 'working') then
		action.deweed()
		action.placeCropStick()
	elseif crop.name == plot.target then
		local stat = crop.gr + crop.ga - crop.re

		if stat > plot.lowestStat then

			action.transplant(crop, plot.lowerCrop)

			action.placeCropStick(2)
			scanner.scan()

			plot:updateLowerCrop()
		else
			action.deweed()
			action.placeCropStick()
		end
	elseif config.keepMutations and (not manager.existInStorage(crop)) then
		local x, y = manager.reserveStorageSlot(crop)
		if not (x and y) then
			 print('no slot available, the storage is full!')
			running = false
			return
		end
		action.transplant(crop, {x = x, y = y})
		action.placeCropStick(2)
	else
		action.deweed()
		action.placeCropStick()
	end
end


---@param crop crop
---@param plot Plot
local function checkParent(plot, crop)
	if crop.isCrop and crop.name ~= 'air' and crop.name ~= 'emptyCrop' then
		if scanner.isWeed(crop, 'working') then
			action.deweed()
			scanner.scan()
			plot:updateLowerCrop()
		end
	end
end

local function init()
	manager.createAllPlots()
	manager.setupAllPlot()
end


local cleanUp = {}
local function runtime()
	for plot in manager.plotsIterator() do
		print("plot:", plot.x, plot.y)
		for x, y, t in plot:Iterator() do
			if cleanUp[plot] then
				break
			end
			if plot.lowestStat >= config.autoStatThreshold then
				plot:cleanUp()
				cleanUp[plot] = true
				break
			end
			gps.go(x, y)
			local crop = scanner.scan()
			print("t", t, "crop", crop.name)
			if t == "2" then
				checkChild(plot, crop)
			else
				checkParent(plot, crop)
			end
			if action.needCharge() then
				action.charge()
			end
		end
	end
	return true
end

local index = 0
local function main()
	init()
	while running and runtime() do
		index = index + 1
		print("runtime ".. index.." end")
		action.restockAll()
		running = false
		for plot in manager.plotsIterator() do
			if plot.lowestStat < config.autoStatThreshold then
				running = true
				break
			end
		end
	end
	print('autoStat: Minimum Stat Threshold Reached!')
	for plot in manager.plotsIterator() do
		if not cleanUp[plot] then
			plot:cleanUp()
		end
	end
	gps.goHome()
	print('autoStat: Complete!')
end

main()
