local Color=require("color")
local thread=require("thread")
local event=require("event")
local component=require("component")

local TO=require("textObject")
local drawtO=TO.drawtO
local TextObject=TO.TextObject

local os=require("os")

---@type button[]
buttonlist={}

thread.create(function()
    while true do
        ---@type string,string,number,number,number,string
        local eventname, screenAddress, mx, my, mouseButton, playerName=event.pull("touch")
        for i, button in ipairs(buttonlist) do
            if button:isClicked(mx, my) then
                button:click()
                button:draw()
                tablet.beep(120, .1)
                break
            end
        end
    end
end)

---@return button
local function Button()
    ---@class button
    ---@field x number
    ---@field y number
    ---@field ox number
    ---@field oy number
    ---@field status boolean
    ---@field fn function
    ---@field mode string
    ---@field textureON color[]
    ---@field textureOFF color[]
    local b={}
    b.x=1
    b.y=1
    b.ox=0
    b.oy=0
    b.status=false
    b.mode="toggle"
    b.textureON={ Color("green"), Color("gray") }
    b.textureOFF={ Color("gray"), Color("red") }

    function b:draw()
        if self.status then
            for i, v in ipairs(self.textureON) do
                drawtO(TextObject(" ", v, v), self.x + self.ox + i - 1, self.y + self.oy)
            end
        else
            for i, v in ipairs(self.textureOFF) do
                drawtO(TextObject(" ", v, v), self.x + self.ox + i - 1, self.y + self.oy)
            end
        end
    end

    ---@param colors color[]
    function b:setTextureON(colors)
        self.textureON=colors
    end

    ---@param colors color[]
    function b:setTextureOFF(colors)
        self.textureOFF=colors
    end

    ---@param ox number
    ---@param oy number
    function b:setOffset(ox, oy)
        self.ox=ox
        self.oy=oy
    end

    ---@param x number
    ---@param y number
    function b:setPos(x, y)
        self.x=x
        self.y=y
    end

    ---@param fn function
    function b:setFunction(fn)
        self.fn=fn
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
        local width=b:getWidth()
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
        self.status=not self.status
        if self.fn then
            self.fn()
        end
    end

    table.insert(buttonlist, b)
    return b
end

return Button