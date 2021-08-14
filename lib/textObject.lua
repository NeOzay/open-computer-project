---@class mdlTextObject
---@overload fun(text:string,foregroundColor:color,backgroundColor:color):textObject
local mdl = {}

setmetatable(mdl, {__call = function (_,text,foregroundColor,backgroundColor)
	return mdl.TextObject(text,foregroundColor,backgroundColor)
end})

---@param text string
---@param foregroundColor color
---@param backgroundColor color
function mdl.TextObject(text, foregroundColor, backgroundColor)
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


---@param tO textObject
---@param x number
---@param y number
function mdl.drawtO(tO, x, y)
	local bg = tO.backgroundColor
	local fg = tO.foregroundColor
	gpu.setBackground(bg.color, bg.isPaletteIndex)
	gpu.setForeground(fg.color, fg.isPaletteIndex)
	gpu.set(x, y, tO.text)
end

return mdl