---@class opdata.svd 
---@field _repos table<string, {repo:string}>
---@field [string] table<string, string>}


---@alias oppm.cfg {path:string, repos:table<string, table<string, oppm.package>>}

---@class oppm.package
---@field files table<string, string>
---@field dependencies  table<string, string>
---@field name string
---@field description string
---@field authors string
---@field note string
---@field hidden? boolean
---@field repo string

---@class oppt.handler
---@field data oppm.package