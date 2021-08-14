local colors = require("colors")


---@class Colors
---@field white color
---@field orange color
---@field magenta color
---@field lightblue color
---@field yellow color
---@field lime color
---@field pink color
---@field gray color
---@field silver color
---@field cyan color
---@field purple color
---@field blue color
---@field brown color
---@field green color
---@field red color
---@field black color
---@overload fun(cl:number):color
---@overload fun(cl:string):color
---@overload fun(cl:number,isPaletteIndex:boolean):color
local Colors = {}

---@param cl number
---@param isPaletteIndex boolean
---@overload fun(cl:number):color
---@overload fun(cl:string):color
function Colors.__index(cl, isPaletteIndex)
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

setmetatable(Colors,Colors)

Colors.white = Colors(0xFFFFFF)
Colors.orange = Colors(0xFFCC33)
Colors.magenta = Colors(0xCC66CC)
Colors.lightblue = Colors(0x6699FF)
Colors.yellow = Colors(0xFFFF33)
Colors.lime = Colors(0x33CC33)
Colors.pink = Colors(0xFF6699)
Colors.gray = Colors(0x333333)
Colors.silver = Colors(0xCCCCCC)
Colors.cyan = Colors(0x336699)
Colors.purple = Colors(0x9933CC)
Colors.blue = Colors(0x333399)
Colors.brown = Colors(0x663300)
Colors.green = Colors(0x336600)
Colors.red = Colors(0xFF3333)
Colors.black = Colors(0x0)

return Colors


