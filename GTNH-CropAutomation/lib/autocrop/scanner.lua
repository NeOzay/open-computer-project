local component = require('component')
local sides = require('sides')

local config = require('autocrop.config')
local db = require('autocrop.database')

local geolyzer = component.geolyzer

---@class crop
---@field isCrop boolean
---@field hasSeed boolean
---@field name string|"air"|"block"|'emptyCrop'
---@field gr number?
---@field ga number?
---@field re number?
---@field tier number?
---@field type "b"|"t"|"2"?
---@field x number
---@field y number

---@return crop
local function scan()
    local rawResult = geolyzer.analyze(sides.down)
    local crop = db.getCropBelow()
    -- AIR
    if rawResult.name == 'minecraft:air' or rawResult.name == 'GalacticraftCore:tile.brightAir' then
        crop.isCrop = true
        crop.hasSeed = false
        crop.name = 'air'
    elseif rawResult.name == 'IC2:blockCrop' then
        crop.isCrop = true
        -- EMPTY CROP STICK
        if rawResult['crop:name'] == nil then
            crop.name = 'emptyCrop'
        else
            -- FILLED CROP STICK
            crop.name = rawResult['crop:name']
            crop.hasSeed = true
        end
    else
        -- RANDOM BLOCK
        crop.isCrop = false
        crop.hasSeed = false
        crop.name = 'block'
    end
    crop.gr = rawResult['crop:growth']
    crop.ga = rawResult['crop:gain']
    crop.re = rawResult['crop:resistance']
    crop.tier = rawResult['crop:tier']
    return crop
end


local function isWeed(crop, farm)
    if farm == 'working' then
        return crop.name == 'weed' or
            crop.name == 'Grass' or
            crop.gr > config.workingMaxGrowth or
            crop.re > config.workingMaxResistance or
            (crop.name == 'venomilia' and crop.gr > 7)
    elseif farm == 'storage' then
        return crop.name == 'weed' or
            crop.name == 'Grass' or
            crop.gr > config.storageMaxGrowth or
            crop.re > config.storageMaxResistance or
            (crop.name == 'venomilia' and crop.gr > 7)
    end
end


return {
    scan = scan,
    isWeed = isWeed
}
