local gps = require('autocrop.gps')
local scanner = require('autocrop.scanner')
local action = require('autocrop.action')
local database = require('autocrop.database')

local config = require('autocrop.config')

local manager = require('autocrop.manager')

local running = true

---@type table<Plot, table>
local empty = {}

---@param crop crop
---@param plot Plot
local function checkChild(plot, crop)
	if not crop.isCrop or  crop.name == 'emptyCrop' then
		return
	end
	if crop.name == 'air' then
		action.placeCropStick(2)
	elseif scanner.isWeed(crop, 'storage') then
		action.deweed()
		action.placeCropStick()
	elseif crop.name == plot.target then
		local stat = crop.gr + crop.ga - crop.re
		if stat >= config.autoSpreadThreshold then
			-- Make sure no parent on the working farm is empty
			if  empty[plot] and crop.gr <= config.workingMaxGrowth and crop.re <= config.workingMaxResistance then
				action.transplant(crop, empty[plot])
				empty[plot] = nil
				action.placeCropStick(2)

				-- No parent is empty, put in storage
			else
				local x, y = manager.reserveStorageSlot(crop)
				print("reserveStorageSlot x, y", x, y)
				if not (x and y) then
					print('no slot available, the storage is full!')
					running = false
					return
				end
				action.transplant(crop, {x = x, y = y})
				action.placeCropStick(2)
			end

			-- Stats are not high enough
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
	elseif crop.name == 'air' or crop.name == 'emptyCrop' then
		empty[plot] = {x = crop.x, y = crop.y}
		return true
	end
end

local function init()
	manager.createAllPlots()
	manager.resetNexPlot()
	manager.setupAllPlot()
end


local function runtime()
	for plot in manager.nextPlot do
		print("plot:", plot.x, plot.y)
		for x, y, t in plot:Iterator() do
			gps.go(x, y)
			local crop = scanner.scan()
			--print("t", t, "crop", crop.name)
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


local function main()
	init()
	while running and runtime() do
		action.restockAll()
	end
	for plot in manager.nextPlot do
		plot:cleanUp()
	end
	gps.goHome()
	print('autoStat: Complete!')
end

main()
