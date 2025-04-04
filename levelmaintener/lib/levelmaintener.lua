local component = require("component")
local event = require("event")

local AE = component.me_interface

local idleCPUs = {} ---@type table<AECpuMetadata, boolean>
local busyCPUs = {} ---@type table<AECpuMetadata, boolean>

local config = {
    maxCraftingBatches = 1000,
    -- Control how many CPUs to use. 0 is unlimited, negative to keep some CPU free, between 0 and 1 to reserve a share,
    -- and greater than 1 to allocate a fixed number.
    allowedCpus = -2
}

local availableCpus = 0
local jobs = {} ---@type autoMaintener.tracker[]
local querys = {} ---@type [autoMaintener.tracker, integer][]

---@class autoMaintener.tracker
---@field recipe AECraftable
---@field status? AECraftingJob
---@field waitingForJob boolean
---@field name string
---@field damage integer
---@field label string
---@field threshold integer
---@field lower integer

local trackers = {} ---@type table<string, autoMaintener.tracker?>

local function updateAvailableCpus()
    local cpus = availableCpus
    availableCpus = 0
    local all = AE.getCpus()
    if config.allowedCpus == 0 then
        availableCpus = #all
    elseif config.allowedCpus > 1 then
        availableCpus = math.min(#all, config.allowedCpus)
    elseif config.allowedCpus < -1 then
        availableCpus = math.max(0, #all + config.allowedCpus)
    else
        availableCpus = math.floor(#all * config.allowedCpus)
    end
    if availableCpus ~= cpus then
        idleCPUs = {}
        busyCPUs = {}
        for i = 1, #all do
            local cpu = all[i]
            if cpu.cpu.isBusy() then
                busyCPUs[cpu] = true
            else
                idleCPUs[cpu] = true
            end
        end
    end
end

local function refillIdleCPUs()
    for cpu in pairs(busyCPUs) do
        if not cpu.cpu.isBusy() then
            busyCPUs[cpu] = nil
            idleCPUs[cpu] = true
        end
    end
end

local function getCPU()
    if not next(idleCPUs) then
        refillIdleCPUs()
    end
    for key in pairs(idleCPUs) do
        idleCPUs[key] = nil
        busyCPUs[key] = true
        if not key.cpu.isBusy() then
            return key
        end
    end
    return nil
end

---@param item ItemStack|{name:string, damage:integer, label:string}
---@param threshold integer
---@param lower? integer
---@return autoMaintener.tracker?, string?
local function newTracker(item, threshold, lower)
    local name = item.name
    local damage = item.damage
    local recipe = AE.getCraftables({ name = name, damage = damage })[1]
    if not recipe then
        print("Recipe not found for " .. item.label)
        return nil, "Recipe not found"
    end
    trackers[name .. tostring(damage)] = {
        recipe = recipe,
        name = name,
        damage = damage,
        label = item.label,
        threshold = threshold,
        lower = lower or math.floor(threshold / 3),
        waitingForJob = false,
    }
    return trackers[name .. tostring(damage)], nil
end

---@param tracker autoMaintener.tracker
local function isDone(tracker)
    if not tracker.status then
        return true
    end
    if tracker.status.isDone() or tracker.status.isCanceled() then
        tracker.status = nil
        return true
    end
    return false
end

local function releaseJobs()
    local release = false
    for i = 1, #jobs do
        local tracker = jobs[i]
        if isDone(tracker) then
            table.remove(jobs, i)
            print("Finished crafting: " .. tracker.label)
            release = true
        end
    end
    return release
end

local function doQuery()
    local query = querys[#querys]
    if not query then
        return
    end

    if #jobs == availableCpus then
        if not releaseJobs() then
            return
        end
    end

    local tracker, amount = query[1], query[2]
    local result = tracker.recipe.request(amount, false)
    if result.hasFailed() then
        print("Failed to start crafting " .. tracker.label .. " x" .. amount)
    else
        tracker.status = result
        table.insert(jobs, tracker)
        print("Started crafting " .. tracker.label .. " x" .. amount)
        querys[#querys] = nil
        tracker.waitingForJob = false
        doQuery()
    end
end

local function main()
    updateAvailableCpus()
    print("Available CPUs: " .. availableCpus)
    event.timer(10, function(...)
        releaseJobs()   
        doQuery()
    end, math.huge)
    local name = ""
    while true do
        for item in AE.allItems() do
            name = item.name .. item.damage
            local tracker = trackers[name]
            if tracker and not tracker.waitingForJob and isDone(tracker) and item.size < tracker.lower then
                local amount = math.min(tracker.threshold - item.size, config.maxCraftingBatches)
                querys[#querys + 1] = {tracker, amount}
                tracker.waitingForJob = true
                doQuery()
            end
            os.sleep()
        end
        os.sleep(5)
        print('Jobs : ' .. #jobs .. ' Querys: ' .. #querys)
    end
end



return {
    config = config,
    start = main,
    addTracker = newTracker,
}