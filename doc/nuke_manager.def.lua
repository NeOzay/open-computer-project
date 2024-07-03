---@class nuke_manager
---@field  logger? nuke_manager.logger
---@field  settings nuke_manager.settings
---@field  reactor_config nuke_manager.reactor[]
---@field  threads 

---@class nuke_manager.settings
---@field code string

---@class nuke_manager.reactor
---@field code string
---@field type "eu"|"fluid"