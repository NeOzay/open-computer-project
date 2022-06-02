--local component = require("component")
--local sides =  require("sides")
--local transposer = component.transposer

local recipes = require("recipes")

--local assemblerSide = sides.north
--local drawerSide = sides.top

--local itemsIterator = transposer.getAllStacks(drawerSide)
local function NitemsIterator()
	local n = 0
	return function ()
		n = n + 1
		if n == 7 then
			return nil
		end
		return {label = recipes["Integrated Processor"][n].name}
	end
end

local itemsIterator = NitemsIterator()
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
	--itemsIterator.reset()

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
	print("amount(number)")
	while type(amount) ~= "number" do
		amount = tonumber(io.read())
		print(type(amount))
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
print("make item_to_transfer")
for index, item in ipairs(selectedRecipe) do
	item_to_transfer[index] = recipeAmount * item.n
end

---@generic K,V
---@param t table<K,V>
---@param index K
---@return K
---@return V
local function getNext(t, index)
		local amount
		index, amount = next(t, index)
		if not index then
			index, amount = next(t)
			print()
		end
		return index, amount
end

---@generic K,V:integer
---@param t table<K,V>
---@param index K
---@param key V?
---@return K
---@return V
local function check0(t, index, key)
		if key and key == 0 then
			t[index] = nil
			index, key = getNext(t, index)
			return check0(t, index, key)
		end
		return index, key
end

---@param recipe Item[]
---@param t2 table<number,number>
local function loop(recipe, t2)
	---@param itemAmount table<number,number>
	---@param oldk number
	return function (itemAmount, oldk)
		local index , amount = getNext(itemAmount, oldk)
		index, amount = check0(itemAmount, index, amount)
		local item = recipe[index]
		return index, item, amount
	end, t2
end


local function main()
	for index, item, itemAmount in loop(selectedRecipe, item_to_transfer) do
		local itemStoredSlot = itemsSlot[item.name]
		--local transfered = transferToAssembler(itemStoredSlot, index, itemAmount)
		local transfered = 1
		print(index, item.name, itemAmount)
		item_to_transfer[index] = itemAmount - transfered
	end
end

main()


