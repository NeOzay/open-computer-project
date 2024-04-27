local config    = require("autocrop.config")
local action    = require("autocrop.action")
local robot     = require("robot")

local gps       = require('autocrop.gps')
local scanner   = require('autocrop.scanner')
local database  = require('autocrop.database')

local plotshape = config.plotshape

local abs       = math.abs

---@class Plot
---@field crops table<crop, boolean>
---@field last number
---@field x number
---@field y number
---@field w number
---@field h number
---@field target string
---@field lowerCrop crop
---@field lowestStat number
---@field flipWidth boolean
---@field flipHeight boolean
---@field Iterator fun(self:Plot):fun():x:number, y:number, cropType:string?
local Plot      = {}

Plot.__index    = Plot

local function getsigne(n)
	return n > 0 and 1 or n < 0 and -1 or 0
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param flipWidth? boolean
---@param flipHeight? boolean
---@return Plot
function Plot.new(x, y, w, h, flipWidth, flipHeight)
	flipWidth, flipHeight = flipWidth or false, flipHeight or false
	local plot = setmetatable({ x = x, y = y, w = w, h = h, crops = {}, flipWidth = flipWidth, flipHeight = flipHeight }, Plot)
	return plot
end

function Plot:Iterator()
	local reverseWidth, reverseHeight = self.flipWidth or false, self.flipHeight or false
	local ws = getsigne(self.w)
	local hs = getsigne(self.h)
	return coroutine.wrap(function()
		for y2 = 0, abs(self.h) - 1 do
			y2 = reverseHeight and (abs(self.h) - y2 - 1) or y2
			for x2 = 0, abs(self.w) - 1 do
				--print("debug: x, y", x,x2, y, y2)
				x2 = reverseWidth and (abs(self.w) - x2 - 1) or x2
				--print("debug: x, y", self.x, x2 * ws, self.y, y2 * hs)
				coroutine.yield(self.x + (x2 * ws), self.y + (y2 * hs), self:getCropType(x2 + 1, y2 + 1))
				--table.insert(slots, posUtil.posToWorkingSlot(x + x2, y + y2))
			end
			reverseWidth = not reverseWidth
		end
		reverseWidth = not reverseWidth
		coroutine.yield()
	end)
end

---@param x number
---@param y number
---@param absolute boolean?
---@return string?
function Plot:getCropType(x, y, absolute)
	if absolute then
		x = abs(x - self.x) + 1
		y = abs(y - self.y) + 1
	end
	if x > abs(self.w) or x < 1 or y > abs(self.h) or y < 1 then
		return
	end
	local ry = abs(self.h) - (y - 1)
	local rx = abs(self.w) - (x - 1)
	local shape = plotshape[ry]
	return string.sub(shape or "", rx, rx)
end

function Plot:setup()
	for x, y in self:Iterator() do
		gps.go(x, y)
		local crop = scanner.scan()
		local crop_type = self:getCropType(x, y, true)

		crop.type = crop_type
		if crop_type == "t" and crop.hasSeed then
			self.target = crop.name
		else
			if crop.name == "air" and crop_type == "2" then
				action.placeCropStick(2)
			end
		end
		self.crops[crop] = true
	end
end

function Plot:cleanUp()
	for x, y in self:Iterator() do
		gps.go(x, y)
		local crop = scanner.scan()
		if crop.type == "2" or crop.name == "emptyCrop" or scanner.isWeed(crop, "working") then
			robot.swingDown()
			-- Pickup
			if config.KeepDrops then
				robot.suckDown()
			end
			scanner.scan()
		end
	end
end

function Plot:updateLowerCrop()
	local lower
	local lowestStat = 99
	for x, y, cropType in self:Iterator() do
		local crop = database.getCrop(x, y)
		if crop.isCrop and cropType == "t" then
			if crop.name == 'air' or crop.name == 'emptyCrop' then
				lower = crop
				lowestStat = 0
				break
			elseif crop.name ~= self.target then
				local stat = crop.gr + crop.ga - crop.re - 2
				if stat < lowestStat then
					lowestStat = stat
					lower = crop
				end
			else
				local stat = crop.gr + crop.ga - crop.re
				if stat < lowestStat then
					lowestStat = stat
					lower = crop
				end
			end
		end
	end
	self.lowerCrop = lower
	self.lowestStat = lowestStat
end

return Plot
