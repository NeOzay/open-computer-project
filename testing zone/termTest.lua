local term = require("term")
local os = require("os")
local component = require("component")

local gpu = component.gpu
local screenw, screenl = gpu.getResolution()

local _

---@return number,number
local function getOffset()
    local _, _, _, _, ox, oy = term.getViewport()
    return ox, oy
end

---@param barsize number
---@return fun(percent:number):string @between 0 and 1
local function newProgressbar(barsize)
    local left = "["
    local right = ("]%3d%%"):format(0)
    local gap = barsize or 50 - #left - #right
    local at
    local tampon = 1
    ---@type string[]
    local bar = { left, ">", right }
    for i = 1, gap do
        table.insert(bar, #bar, " ")
    end
    ---@type
    return coroutine.wrap(function(percent)
        while true do

            right = ("]%3d%%"):format(tostring(percent * 100))
            table.remove(bar)
            table.insert(bar, right)

            at = math.floor(percent * (gap) + 0.5)
            for i = tampon, gap + 2 do
                if i < at + 2 then
                    table.insert(bar, 2, "=")
                    table.remove(bar, #bar - 1)
                else
                    tampon = i
                    break
                end
            end
            percent = coroutine.yield(table.concat(bar))
        end
    end)
end

---@param initLine number
---@param drawFn fun(currentLine:number,text:string|number)
local function newDisplay(initLine, drawFn)
    ---@type number
    local currentLine
    if initLine == 1 then
        currentLine = initLine
        initLine = initLine + 1
        term.setCursor(1, initLine)
    else
        currentLine = initLine - 1
        term.setCursor(1, initLine)
    end

    local state = false
    return ---@param text string|number
    function(text)
        text = tostring(text)
        local _, yo = getOffset()
        if yo == 50 then
            if state then
                currentLine = math.max(currentLine - 1, 1)
            else
                state = true
            end
        end
        drawFn(currentLine, text)
    end
end

term.clear()
local bar = newProgressbar(150)
local display = newDisplay(30,
        function(line, text)
            gpu.fill(1, line, screenl, 1, " ")
            gpu.set(1, line, text)
        end)

local t
for i = 1, 100 do
    local ox, oy = getOffset()
    print(ox .. " " .. oy .. " line " .. i)
    display(bar(i/100))
    os.sleep(0.2)
end
