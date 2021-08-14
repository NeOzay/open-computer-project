local Color = require("color")
--local Button = require("button")


local TO = require("textObject")
local TextObject = TO.TextObject
local drawtO = TO.drawtO

---staticText
---@param tO textObject
---@param x number
---@param y number
local function staticText(tO, x, y)
    ---@class  staticText
    ---@field tO textObject
    ---@field x number
    ---@field y number
    local sT = {}
    sT.tO = tO
    sT.x = x
    sT.y = y
    return sT
end

---@param tO textObject
---@param x number
---@param y number
local function fieldText(tO, x, y)
    ---@class fieldText : staticText
    local fT = {}

    return fT
end

local function Panel()
    ---@class panel
    ---@field x number
    ---@field y number
    ---@field hight number
    ---@field width number
    ---@field title staticText
    ---@field statics staticText[]
    ---@field field
    ---@field button button[]
    ---@field defautBackgroundColor color
    ---@field defautForegroundColor color
    local p = {}
    p.statics = {}
    p.button = {}
    p.x = 1
    p.y = 1
    p.hight = 1
    p.width = 1
    p.defautForegroundColor = Color("white")
    p.defautBackgroundColor = Color("black")
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
        local textWidth = #field.tO.text / 2
        local width = self.width / 2
        field.x = width - textWidth
    end

    ---addStatic
    ---@param tO textObject
    ---@param x number
    ---@param y number
    function p:addStatic(tO, x, y)
        local sT = staticText(tO, x, y)
        table.insert(self.statics, sT)
    end

    ---addButton
    ---@param button button
    ---@param x number
    ---@param y number
    function p:addButton(button, x, y)
        if x and y then
            button:setPos(x, y)
        end
        button:setOffset(self.x, self.y)
        table.insert(self.button, button)
    end

    ---@param text string
    ---@param foregroundColor color
    ---@param backgroundColor color
    ---@overload fun(text:string, foregroundColor:color):textObject
    ---@overload fun(text:string):textObject
    function p:TextObject(text, foregroundColor, backgroundColor)
        foregroundColor = foregroundColor or self.defautForegroundColor
        backgroundColor = backgroundColor or self.defautBackgroundColor
        return TextObject(text,foregroundColor,backgroundColor)
    end

    ---@param tO textObject
    ---@param x number
    ---@param y number
    function p:drawtO(tO, x, y)
        ---@type color
        local bg, fg
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
        gpu.fill(self.x, self.y, self.width, self.hight, " ")

        gpu.setBackground(backgroundColor.color, backgroundColor.isPaletteIndex)
        gpu.fill(self.x + 1, self.y + 1, self.width - 2, self.hight - 2, " ")

    end

    function p:drawStatics()
        for _, sT in ipairs(self.statics) do
            p:drawtO(sT.tO, sT.x + self.x, sT.y + self.y)
        end
    end

    function p:drawButtons()
        for _, button in pairs(self.button) do
            if button.status then
                for i, tO in ipairs(button.textureON) do
                    drawtO(tO, self.x + button.x + i - 1, self.y + button.y)
                end
            else
                for i, tO in ipairs(button.textureOFF) do
                    drawtO(tO, self.x + button.x + i - 1, self.y + button.y)
                end
            end
        end
    end

    function p:hide()
        gpu.setBackground(0x000000)
        gpu.fill(self.x, self.y, self.width, self.hight, " ")
    end

    function p:drawAll()
        self:drawTitle()
        self:drawStatics()
        self:drawButtons()
    end

    return p
end

return Panel