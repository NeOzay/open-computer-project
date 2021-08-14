local Color = require("color")
local thread = require("thread")
local event = require("event")
local component = require("component")
print(...)

---@class BUTTON
---@field buttonlist button[]
---@field checkFn function
---@field init function
---@overload fun():button
local Button = {}

local param = {...}
local modname = param[1]
--local sub = require(modname..".sub")
if package.loaded[modname] then return end
package.loaded[modname] = Button

Button.buttonlist = {}

---@param fn function
function Button.changeCheckFn(fn)
    Button.checkFn = fn
end

Button.checkFn = function()
    thread.create(function()
        while true do
            ---@type string,string,number,number,number,string
            local _, _, mx, my, _, _ = event.pull("touch")
            for i, button in ipairs(Button.buttonlist) do
                if button:isClicked(mx, my) then
                    button:click()
                    button:draw()
                    break
                end
            end
        end
    end)
end

function Button.init()
    Button.checkFn()
end

--Button.Switch = require("button.switch")
--lib.prefix = (...):match("(.-)[^%.]+$")
--lib.class = require(lib.prefix .. "lib.class")

return Button