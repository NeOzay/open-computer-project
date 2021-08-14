local colors = require("colors")
local component =  require("component")
local gpu = component.gpu

local mdl = {}

---@param cl number
---@param isPaletteIndex boolean
---@overload fun(cl:number):color
---@overload fun(cl:string):color
function mdl.color(cl, isPaletteIndex)
	---@class color
    ---@field color number
    ---@field isPaletteIndex boolean
	local o = {}
	if type(cl) == "string" then
		o.color = colors[cl]
		o.isPaletteIndex = true
	else
		o.color = cl
		o.isPaletteIndex = isPaletteIndex or false
	end
	return o
end

---@param text string
---@param foregroundColor color
---@param backgroundColor color
---@overload fun(text:string,foregroundColor:color):textObject
---@overload fun(text:string):textObject
function mdl.textObject(text, foregroundColor, backgroundColor)
	---@class textObject
    ---@field text string
    ---@field foregroundColor color
    ---@field backgroundColor color
	local tO = {}
	tO.text = text
	tO.foregroundColor = foregroundColor
	tO.backgroundColor = backgroundColor
	return tO
end

function mdl.drawtO(tO, x, y)
	local bg
	local fg
	gpu.setBackground(bg.color, bg.isPaletteIndex)
	gpu.setForeground(fg.color, fg.isPaletteIndex)
	gpu.set(x, y, tO.text)
end

return mdl