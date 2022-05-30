local component = require("component")
local sides =  require("sides")
local transposer = component.transposer

local recipes = require("recipes")

local assemblerSide = sides.north
local drawerSide = sides.top

local itemsIterator = transposer.getAllStacks(drawerSide)

local function selectRecipe()
	local list = {}
	for name, recipe in pairs(recipes) do
		table.insert(list, name)
	end
	local text = ""
	for index, value in ipairs(list) do
		text = text.."["..index.."]"..value..","
	end
	print(text)
	return list[tonumber(io.read())]
end

local itemSlot = {}
local function findItem(recipe)
	itemsIterator.reset()

	
end

selectRecipe()

transposer.getStackInSlot(side, slot)