---@type BUTTON
local Button = require("button")

local Color = require("color")
local TO = require("textObject")
local drawtO = TO.drawtO
local TextObject = TO.TextObject

local function Switch()
    ---@class button
    ---@field x number
    ---@field y number
    ---@field ox number
    ---@field oy number
    ---@field status boolean
    ---@field fn function
    ---@field mode string
    ---@field textureON textObject[]
    ---@field textureOFF textObject[]
    local b = {}
    b.x = 1
    b.y = 1
    b.ox = 0
    b.oy = 0
    b.status = false
    b.mode = "toggle"
    --b.textureON = { TextObject(" ",Color.green,Color.green), TextObject(" ",Color.gray,Color.gray) }
    --b.textureOFF = { TextObject(" ",Color.gray,Color.gray), TextObject(" ",Color.red,Color.red) }

    function b:draw()
        if self.status then
            for i, tO in ipairs(self.textureON) do
                drawtO(tO, self.x + self.ox + i - 1, self.y + self.oy)
            end
        else
            for i, tO in ipairs(self.textureOFF) do
                drawtO(tO, self.x + self.ox + i - 1, self.y + self.oy)
            end
        end
    end

    ---@param tO textObject[]
    function b:setTextureON(tO)
        self.textureON = tO
    end

    ---@param tO textObject[]
    function b:setTextureOFF(tO)
        self.textureOFF = tO
    end

    ---@param ox number
    ---@param oy number
    function b:setOffset(ox, oy)
        self.ox = ox
        self.oy = oy
    end

    ---@param x number
    ---@param y number
    function b:setPos(x, y)
        self.x = x
        self.y = y
    end

    ---@param fn function
    function b:setFunction(fn)
        self.fn = fn
    end

    ---@return number
    function b:getWidth()
        if b.status then
            return #b.textureON
        else
            return #b.textureOFF
        end
    end

    function b:isClicked(x, y)
        local width = b:getWidth()
        if x >= self.x + self.ox and
                x <= self.x + self.ox + width - 1 and
                y == self.y + self.oy
        then
            return true
        else
            return false
        end
    end

    function b:click()
        self.status = not self.status
        if self.fn then
            self.fn()
        end
    end

    table.insert(Button.buttonlist, b)
    return b
end

return Switch()