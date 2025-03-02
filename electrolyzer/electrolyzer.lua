local component = require("component")
local os = require("os")
local sides = require("sides")
local recipes = require("recipes")

local transposer = component.transposer

local drawer = {}

---@return recipeDust
function drawer:getDust()
    local fn = coroutine.wrap(function()
        while true do
            for dustName, index in pairs(self.dustList) do
                local dustNumber = transposer.getSlotStackSize(self.side, index)
                ---@type recipeDust
                local recipe = recipes[dustName]
                print(dustName)
                if recipe then
                    if dustNumber > recipe.amount then
                        coroutine.yield(recipe)
                    end
                end
            end
            os.sleep(60)
        end
    end)

    ---@return recipeDust
    function drawer:getDust() return fn() end
    return fn()
end

---@type table<string,number>
drawer.dustList = {}

---@type GTelectrolyzer[]
local electrolyzerList = {}

---@class GTelectrolyzer
---@field side number
---@field cooldown number
local Electrolyzer = {}
Electrolyzer.__index = Electrolyzer

---@param side number
---@return GTelectrolyzer
function Electrolyzer.new(side)
    return setmetatable({
		side = side,
		cooldown = 0
	}, Electrolyzer)
end

---@param dust recipeDust
function Electrolyzer:insertDust(dust)
    transposer.transferItem(drawer.side, self.side, dust.amount,
                            drawer.dustList[dust.name])
    self.cooldown = dust.duration + 1
    print("insert " .. dust.name .. " in " .. sides[self.side])
end

---@param time number
---@return number new_cooldown
function Electrolyzer:decreaseCooldown(time)
    self.cooldown = math.max(self.cooldown - time, 0)
    return self.cooldown
end
print("init")

for side = 0, #sides - 1 do
    local machine = transposer.getInventoryName(side)
    if machine == "gregtech:machine" then
        table.insert(electrolyzerList, Electrolyzer.new(side))
    elseif machine == "storagedrawers:controller" then
        drawer.side = side
    end
end

for i = 1, transposer.getInventorySize(drawer.side) do
    local stack = transposer.getStackInSlot(drawer.side, i)
    if stack then drawer.dustList[stack.label] = i end
end
print("init end")

local sleep = 0
local newSleep = 100
while true do
    for _, electrolyzer in ipairs(electrolyzerList) do
        local duration = electrolyzer:decreaseCooldown(sleep)
        if duration == 0 then electrolyzer:insertDust(drawer:getDust()) end
        newSleep = math.min(electrolyzer.cooldown, newSleep)
    end
    print("sleep " .. newSleep .. "s")
    os.sleep(newSleep)
    sleep = newSleep
    newSleep = 100
end

