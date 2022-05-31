local component = require("component")
local sides =  require("sides")
local transposer = component.transposer

local recipes = require("recipes")

local assemblerSide = sides.north
local drawerSide = sides.top

local itemsIterator = transposer.getAllStacks(drawerSide)

---@return Item[]
local function selectRecipe()
	local i = 0
	local text = ""
	---@type Item[][]
	local list = {}
	for name, recipe in pairs(recipes) do
		i = i + 1
		text = text.."["..i.."]"..name..","
		table.insert(list, recipe)
	end
	print(text)
	---@type number
	local selection
	while type(selection) ~= "number" do
		selection = tonumber(io.read())
	end
	return list[selection]
end

---@type table<string, number>
local itemSlot = {}
---@param recipe Item[]
local function findItems(recipe)
	itemsIterator.reset()

	---@type {[string]:boolean}
	local toFound = {}
	for _, item in ipairs(recipe) do
		toFound[item.name] = true
	end
	local i = 0
	for storedItem in itemsIterator do
		i = i + 1
		local storedItemLabel = storedItem.label
		if toFound[storedItemLabel] then
			toFound[storedItemLabel] = nil
			itemSlot[storedItemLabel] = i
		end
	end

	local missing = {}
	local hasmissing = false
	for name, bool in pairs(toFound) do
		if bool then
			hasmissing = true
			table.insert(missing, name)
		end
	end
	if hasmissing then
		local allMissing = table.concat(missing, ", ")
		print(allMissing.." not found")
	end
end

---@param fromSlot number
---@param pushin number
---@param amount number
local function transferToAssembler(fromSlot, pushin, amount)
	transposer.transferItem(drawerSide, assemblerSide, amount, fromSlot, pushin)
end

local selectedRecipe = selectRecipe()
findItems(selectedRecipe)

for key, value in pairs(transposer.getStackInSlot(drawerSide, itemSlot[selectedRecipe[1].name])) do
	print(key, value)
end

--
