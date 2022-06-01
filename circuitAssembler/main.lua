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

---@param recipe Item[]
local function findItems(recipe)
	itemsIterator.reset()

	---@type table<string, number>
	local itemsSlot = {}
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
			itemsSlot[storedItemLabel] = i
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
		error()
	end
	return itemsSlot
end

---@param fromSlot number
---@param pushin number
---@param amount number
---@return number
local function transferToAssembler(fromSlot, pushin, amount)
	local inAss = transposer.getSlotStackSize(assemblerSide, pushin)
	return transposer.transferItem(drawerSide, assemblerSide, math.min(64 - inAss, amount), fromSlot, pushin)
end

local function selectAmount()
	---@type number
	local amount
	while type(amount) ~= "number" do
		amount = tonumber(io.read())
	end
	return amount
end

---@return Item[]
---@return number
local function request()
	return selectRecipe(), selectAmount()
end

local selectedRecipe, recipeAmount = request()
local itemsSlot = findItems(selectedRecipe)
---@type table<number,number>
local item_to_transfer = {}
for index, item in ipairs(selectedRecipe) do
	item_to_transfer[index] = recipeAmount * item.n
end

---@generic  K, V
---@param t table<K, V>
---@return fun(t2: table<K, V>, k: K):K, V
local function loop(t)
	return function (t2, k)
		local k2, v = next(t2, k)
		if not k2 then
			k2, v = next(t2)
		end
		return k2 , v
	end, t
end

local function main()
	for index, item, itemAmount in loop(selectedRecipe) do
		local itemStoredSlot = itemsSlot[item.name]
		local currentAmount = item_to_transfer[index]
		if currentAmount > 0 then
			local transfered = transferToAssembler(itemStoredSlot, index, currentAmount)
			item_to_transfer[index] = currentAmount - transfered
		end
	end
end

main()

