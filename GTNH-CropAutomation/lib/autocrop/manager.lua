local gps = require('autocrop.gps')
local Plot = require('autocrop.plot')
local config = require("autocrop.config")

local db = require('autocrop.database')

local workingFarmSize = config.workingFarmSize

local plotshape = config.plotshape

local plotWidth = #plotshape[1]
local plotHeight = #plotshape

local function checkPlotShape()
	local length = #plotshape[1]
	for index, line in ipairs(plotshape) do
		if #line ~= length then
			io.stderr:write("invalid plot length, all lines must be the same length")
			os.exit()
		end
	end
end

---@class plotManager
---@field plots Plot[]
local manager = {}
manager.plots = {}

function manager.setupAllPlot()
	gps.goHome()
	for plot in manager.nextPlot do
		print("plot:", plot.x, plot.y)
		plot:setup()
		plot:updateLowerCrop()
	end
end

function manager.cleanUpAllPlot()

end

function manager.createAllPlots()
	checkPlotShape()
	manager.plots = {}

	local floorFarmWidth = workingFarmSize - workingFarmSize % plotWidth
	local floorFarmHeight = workingFarmSize - workingFarmSize % plotHeight

	local index = 0
	local yflip = false
	local xflip = false
	for x = 0, floorFarmWidth - 1, plotWidth do
		for y = 1, floorFarmHeight, plotHeight do
			y = yflip and (floorFarmHeight - y - 1) or y
			index = index + 1
			print(index, x .. "-" .. y .. " " .. tostring(yflip))
			table.insert(manager.plots, Plot.new(-x, y, -plotWidth, plotHeight, xflip, yflip))
			xflip = not xflip
		end
		--reverse all
		xflip = not xflip
		yflip = not yflip
	end
end

local last
--get the next plot
---@return Plot?
function manager.nextPlot()
	local v
	last, v = next(manager.plots, last)
	return v
end

--reset the next plot iterator
function manager.resetNexPlot()
	last = nil
end

local firstStorage = Plot.new(2, 9, 6, -16)
local secondStorage = Plot.new(-8, -1, 10, -6)

---@type table<number, fun():x:number, y:number, cropType:string?>
local storageAvaliable = { firstStorage:Iterator(), secondStorage:Iterator() }

local function getFreeStorageSlot()
	local iterator = storageAvaliable[1]
	if not iterator then
		return
	end
	local x, y = iterator()
	if x and y then
		return x, y
	end
	table.remove(storageAvaliable, 1)
	return getFreeStorageSlot()
end

local containing = {}

function manager.existInStorage(crop)
	return containing[crop.name]
end

--get a storage slot for a crop
---@param crop crop
---@return number? x
---@return number? y
function manager.reserveStorageSlot(crop)
	local x, y = getFreeStorageSlot()
	if x and y then
		containing[crop.name] = true
		db.copy(crop, x, y)
		return x, y
	end
end

function manager.readyForNextRound()
	
end

return manager
