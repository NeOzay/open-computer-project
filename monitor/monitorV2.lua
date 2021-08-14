local component = require("component")
local os = require("os")

local colors = require("colors")

require("textDraw")

local term = require("term")
local thread = require("thread")
local event = require("event")
local serialization = require("serialization")
local conf = require("monitor conf")

local Button = require("button")

local gpu = component.gpu
local tunnel = component.tunnel

term.clear()



---@param tO textObject
---@param x number
---@param y number
local function staticText(tO, x, y)
	---@class staticText
    ---@field tO textObject
    ---@field x number
    ---@field y number
	local sT = {}
	sT.tO = tO
	sT.x = x
	sT.y = y

	return sT
end

local function panel()
	---@class panel
    ---@field x number
    ---@field y number
    ---@field hight number
    ---@field width number
    ---@field title staticText
    ---@field statics staticText[]
    ---@field defautBackgroundColor color
  	---@field defautForegroundColor color
	local p = {}
	p.statics = {}
	p.x = 1
	p.y = 1
	p.hight = 1
	p.width = 1
	p.defautForegroundColor = color("white")
	p.defautBackgroundColor = color("black")
	---@param x number
    ---@param y number
	function p:setPos(x, y)
		self.x = x
		self.y = y
	end

	---@param pcolor color
	function p:setDefautBackgroundColor(pcolor)
		self.defautBackgroundColor = pcolor
	end

	---@param pcolor color
	function p:setDefautForegroundColor(pcolor)
		self.defautForegroundColor = pcolor
	end

	---@param width number
    ---@param hight number
	function p:setSize(width, hight)
		self.hight = hight
		self.width = width
	end

	---@param tO textObject
    ---@param x number
    ---@param y number
	function p:setTitle(tO, x, y)
		self.title = staticText(tO, x, y)
	end

	---@param field staticText
	function p:centerText(field)
		local textWidth = #field.tO.text/2
		local width = self.width/2
		field.x = width-textWidth
	end

	---addStatic
  	---@param tO textObject
  	---@param x number
  	---@param y number
	function p:addStatic(tO, x, y)
		local sT = staticText(tO, x, y)
		table.insert(self.statics, sT)
	end

	---@param tO textObject
  	---@param x number
  	---@param y number
	function p:drawtO(tO, x, y)
		local bg
		local fg
		if tO.foregroundColor then
			fg = tO.foregroundColor
		else
			fg = self.defautForegroundColor
		end

		if tO.backgroundColor then
			bg = tO.backgroundColor
		else
			bg = self.defautBackgroundColor
		end
		--print(bg.color)
		gpu.setBackground(bg.color, bg.isPaletteIndex)
		gpu.setForeground(fg.color, fg.isPaletteIndex)
		gpu.set(x, y, tO.text)
	end

	function p:drawTitle()
		p:drawtO(self.title.tO, self.title.x + self.x, self.title.y + self.y)
	end

	---@param frameColor color
  	---@param backgroundColor color
  	---@overload fun(frameColor:color)
  	---@overload fun()
	function p:drawFrame(frameColor, backgroundColor)
		if not backgroundColor then
			backgroundColor = self.defautBackgroundColor
		end
		if not frameColor then
			frameColor = self.defautForegroundColor
		end
		gpu.setBackground(frameColor.color, frameColor.isPaletteIndex)
		gpu.fill(self.x, self.y, self.width, self.hight , " ")

		gpu.setBackground(backgroundColor.color, backgroundColor.isPaletteIndex)
		gpu.fill(self.x + 1, self.y + 1, self.width - 2, self.hight - 2, " ")

	end

	function p:drawStatics()
		for i, sT in ipairs(self.statics) do
			p:drawtO(sT.tO, sT.x + self.x, sT.y + self.y)
		end
	end

	function p:drawAll()
		self:drawTitle()
		self:drawStatics()
	end

	return p
end

local function p1()
	local p = panel()

	local text1 = textObject("Fission Reactor", color("red"), color("white"))
	local text2 = textObject("Statue", color("white"))
	local text3 = textObject("Always Run")

	p:setTitle(text1, 4, 0)

	p:addStatic(text2, 2, 2)
	p:addStatic(text3, 2, 3)

	p:setSize(23, 6)
	p:setPos(25,10)
	p:setDefautBackgroundColor(color("cyan"))
	p:drawFrame()
	p:drawTitle()

	p:drawStatics()
	return p
end

local function p2()
	local p = panel()

	local title = textObject("Fission Reactor", color("red"), color("yellow"))
	local static1 = textObject("Statue", color("white"))
	local static2 = textObject("Always Run")

	p:setTitle(title, 1, 0)
	p:centerText(p.title)
	p:addStatic(static1, 2, 2)
	p:addStatic(static2, 2, 3)

	p:setSize(23, 6)
	p:setPos(1, 7)
	p:setDefautBackgroundColor(color("cyan"))
	p:drawFrame(color("blue"))
	p:drawTitle()

	p:drawStatics()
	return p
end

--p1()
p2()

os.sleep(10)
