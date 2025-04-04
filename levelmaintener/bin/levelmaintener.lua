local component               = require("component")
local shell                   = require("shell")
local serialization           = require("serialization")

local selector                = require("selector")
package.loaded.levelmaintener = nil
local levelmaintener          = require("levelmaintener")

local args, options           = shell.parse(...)
local cacheFile               = shell.resolve("/etc/levelmaintener.svd")

local database                = component.database
if not database then
    error("Database is required for this program")
end

---@type {items: table<string, integer>}
local data = { items = {} }
local function loadConf()
    local file = io.open(cacheFile, "r")
    if not file then
        return
    end
    local content = file:read("*a")
    local _data, err = serialization.unserialize(content)
    file:close()
    if not _data then
        error("Failed to load configuration: " .. err)
    end
    data = _data
end

local function saveConf()
    local file = io.open(cacheFile, "w")
    if not file then
        error("Failed to open file for writing configuration")
    end
    file:write(serialization.serialize(data, math.huge))
    file:close()
end

loadConf()
local values = { "run", "transposer", "database", "manual", "list" }
local choices = { "start program", "add items (transposer)", "add items (database)", "add items (manual)",
    "list registred items" }
local select
if args[1] then
    for i = 1, #values do
        if values[i] == args[1] then
            select = values[i]
            break
        end
    end
end
select = select or selector(values, choices, "Select a method:")


local edited = false
---@param stack ItemStack
local function makeEntry(stack)
    local threshold
    while not threshold do
        io.write(" '", stack.label, '\', choice threshold (default 1000, 0 for remove): ')
        threshold = io.read()
        if threshold == false then
            break
        elseif threshold == "" then
            threshold = 1000
        else
            threshold = tonumber(threshold)
        end
    end
    if not threshold then
        return
    end
    if threshold > 0 then
        data.items[stack.name .. "||" .. stack.damage .. "||" .. stack.label] = threshold
    else
        data.items[stack.name .. "||" .. stack.damage .. "||" .. stack.label] = nil
    end
    edited = true
end

if select == "transposer" then
    local transposer = component.transposer
    if not transposer then
        error("Transposer not found")
    end
    local chestSide
    for i = 0, 5 do
        local invname = transposer.getInventoryName(i)
        if invname and invname ~= "tile.appliedenergistics2.BlockInterface" then
            chestSide = i
            break
        end
    end

    if not chestSide then
        error("No valid chest found")
    end
    local items = transposer.getAllStacks(chestSide).getAll()
    for i = 1, #items do
        local stack = items[i]
        if stack and stack.name then
            makeEntry(stack)
        end
    end
end

if select == "database" then
    io.write("Database found, start to read all slots...\n")
    local success = true
    index = 1
    local stack
    while success do
        success, stack = pcall(database.get, index)
        if stack and type(stack) ~= "string" then
            makeEntry(stack)
        end
        index = index + 1
    end
end

if select == "manual" then
    if not database then
        error("Database not found")
    end
    while true do
        io.write("enter internal name of item (default gregtech:gt.metaitem.01):")
        local name = io.read()
        if name == "" then
            name = "gregtech:gt.metaitem.01"
        end
        if not name then
            break
        end
        io.write("enter damage of item (default 0):")
        local damage = io.read() ---@type string|false|number
        if not damage then
            break
        end
        if damage == "" then
            damage = 0
        else
            damage = tonumber(damage) or damage
        end
        if type(damage) ~= "number" then
            io.stderr:write("Invalid damage value: " .. damage)
            break
        end
        ---@cast damage number
        local success, err = database.set(1, name, math.floor(damage))
        if not success then
            error("Failed to set item in database: " .. err)
        end
        local stack = database.get(1)
        if stack then
            makeEntry(stack)
        else
            io.stderr:write("Failed to get item for name: " .. name .. ", damage: " .. damage .. "\n")
        end
    end
end

if select == "list" then
    for k, v in pairs(data.items) do
        local name, damage, label = k:match("([^|]+)||([^|]+)||([^|]+)")
        if label then
            print(" '" .. label .. "' Threshold: " .. v)
        else
            print(" '" .. k .. "' Threshold: " .. v)
        end
    end
end

if select == "run" then
    for k, v in pairs(data.items) do
        local name, damage, label = k:match("([^|]+)||([^|]+)||([^|]+)")
        if name and damage and label then
            local damage = tonumber(damage)
            if not damage then
                error("Invalid damage value: " .. damage)
            end
            local item = { name = name, damage = math.floor(damage), label = label }

            levelmaintener.addTracker(item, v)
        end
    end
    levelmaintener.start()
end

if edited then
    saveConf()
end