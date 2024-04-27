local gps = require('autocrop.gps')

local reverseStorage = {}
---@type table<string, crop>
local farm = {}

-- ======================== WORKING FARM ========================

---@param x number
---@param y number
local function posToString(x, y)
    return string.format('%d-%d', x, y)
end

---@param x number
---@param y number
local function newEntry(x, y)
    local crop =  {x = x, y = y}
    farm[posToString(x, y)] = crop
    return crop
end


---@param x number
---@param y number
local function getCrop(x, y)
    return farm[posToString(x, y)] or newEntry(x, y)
end

---@param crop crop
---@param x number
---@param y number
---@return crop
local function copy(crop, x, y)
    local entry = getCrop(x, y)
    entry.name = crop.name
    entry.gr = crop.gr
    entry.ga = crop.ga
    entry.re = crop.re
    entry.tier = crop.tier
    entry.hasSeed = crop.hasSeed
    entry.isCrop = crop.isCrop
    return entry
end

local function getCropBelow()
    local x, y = gps.getPos()
    return getCrop(x, y)
end

-- ======================== STORAGE FARM ========================

return {
    copy = copy,
    getCropBelow = getCropBelow,
    getCrop = getCrop,
}