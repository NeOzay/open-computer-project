local robot = require("robot")

---@class autocropConf
local config = {}
setmetatable(config, config)
config.load = function ()
    config.config = loadfile("/etc/autocrop/conf.lua")()
    config.__index = config.config
    if config.spadeSlot <= 0 then
       config.spadeSlot = robot.inventorySize() + config.spadeSlot
    end
    if config.binderSlot <= 0 then
         config.binderSlot = robot.inventorySize() + config.binderSlot
    end
    if config.stickSlot <= 0 then
        config.stickSlot = robot.inventorySize() + config.stickSlot
    end
    if config.storageStopSlot <= 0 then
        config.storageStopSlot = robot.inventorySize() + config.storageStopSlot
    end
end

config.load()

return config