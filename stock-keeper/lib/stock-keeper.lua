---@diagnostic disable: unused-local
local component = require("component")
local sides     = require("sides")
local term      = require("term")

local rowDisplay = require("rowDisplay")

local database = component.database

term.clear()

local width, height = component.gpu.getResolution()

---@class Stock_Keeper.config
---@field nameCellWidth? integer
---@field stockCellWidth? integer
---@field thresholdCellWidth? integer
---@field inProcessCellWidth? integer
local config = {
	nameCellWidth = (35*width)//50,
	stockCellWidth = (5*width)//50,
	thresholdCellWidth = (5*width)//50,
	inProcessCellWidth = (5*width)//50
}

---@class Stock_Keeper.itemStack
---@field name string
---@field damage integer
---@field size integer

---@param name string
---@param damage? integer
---@param size? integer
---@return Stock_Keeper.itemStack
local function stack(name, damage, size)
	return {name = name, damage = damage or 0, size = size or 1}
end

---@class Stock_Keeper.recipe
---@field output Stock_Keeper.itemStack
---@field outputSide integer
---@field threshold integer
---@field inputs Stock_Keeper.itemStack[]
---@field inputSide integer
---@field inProcess integer
---@field row? RowManager.Row
---@field nameCell? RowManager.Cell
---@field noItemCell? RowManager.Cell
---@field stockCell? RowManager.Cell 
---@field thresholdCell? RowManager.Cell
---@field inProcessCell? RowManager.Cell
---@field currentCell? RowManager.Cell
local Recipe = {}
Recipe.__index = Recipe

---@param item Stock_Keeper.itemStack
---@param threshold integer
---@return Stock_Keeper.recipe
local function newRecipe(item, threshold)
	return setmetatable(
	{
			output = item,
			outputSide = 0,
			inputSide = 0,
			inProcess = 0,
			threshold = threshold,
			inputs = {}
		}, Recipe)
end

---@param item Stock_Keeper.itemStack
---@return Stock_Keeper.recipe
function Recipe:addIngredient(item)
	table.insert(self.inputs, item)
	return self
end

---@param items Stock_Keeper.itemStack[]
---@return Stock_Keeper.recipe
function Recipe:addIngredients(items)
	for _, item in ipairs(items) do
		table.insert(self.inputs, item)
	end
	return self
end

---@param output integer
---@param input integer
function Recipe:setSides(output, input)
	self.outputSide = output
	self.inputSide = input
	return self
end

---@class Stock_Keeper.inventoryHandle
---@field address string
---@field recipes Stock_Keeper.recipe[]
---@field transposer transposer
---@field interface me_interface
---@field interfaceSide integer
---@field row RowManager.Row
local Handle = {}
Handle.__index = Handle

---@param transposerAddress string
---@param interfaceAddress string
---@return Stock_Keeper.inventoryHandle
local function newHandle(transposerAddress, interfaceAddress)
	local transposer = component.proxy(transposerAddress, "transposer")
	if not transposer then
		error("transposer not found")
	end
	local interface = component.proxy(interfaceAddress, "me_interface")
	if not interface then
		error("interface not found")
	end
	local interfaceSide = -1
	for side in ipairs(sides) do
		if transposer.getInventoryName(side) == "tile.appliedenergistics2.BlockInterface" then
			interfaceSide = side
			break
		end
	end
	if interfaceSide == -1 then
		error("not interface found for transposer: "..transposer.address)
	end
	local row = rowDisplay:newRow()
	row:addCell(50):setText("transposer: "..transposer.address)
	row:draw()
	return setmetatable(
		{
			address = transposerAddress,
			recipes = {},
			transposer = transposer,
			interface = interface,
			interfaceSide = interfaceSide,
			row = row
		}, Handle
	)
end

---@param item Stock_Keeper.itemStack
---@param threshold integer
---@return Stock_Keeper.recipe
function Handle:addRecipe(item, threshold)
	local recipe = newRecipe(item, threshold)
	local row =  rowDisplay:newRow(self.row.rowNb + 1)
	database.set(1, item.name, item.damage)
	local label = database.get(1).label
	recipe.currentCell = row:addCell(1):setText(" "):setSeparator("")
	recipe.nameCell = row:addCell(config.nameCellWidth):setText(label)
	recipe.stockCell = row:addCell(config.stockCellWidth):setText(""):setAlign("right")
	recipe.thresholdCell = row:addCell(config.stockCellWidth):setText(recipe.threshold):setAlign("right")
	recipe.inProcessCell = row:addCell(config.inProcessCellWidth):setText(recipe.inProcess):setAlign("right")
	row:draw()
	recipe.row = row
	table.insert(self.recipes, recipe)
	return recipe
end

function Handle:feachInputChest()
	local inputChestMap = {} ---@type table<integer, table<string, integer>>
	for index, recipe in ipairs(self.recipes) do
		if not inputChestMap[recipe.inputSide] then
			local map = {} ---@type table<string, integer>
			for slot=  1, self.transposer.getInventorySize(recipe.inputSide) do
				local item = self.transposer.getStackInSlot(recipe.inputSide, slot)
				if item then
					if map[item.name..item.damage] then
						self.transposer.transferItem(recipe.inputSide, recipe.inputSide, item.size, slot, map[item.name..item.damage])
					else
						map[item.name..item.damage] = slot
					end
				end
			end
			inputChestMap[recipe.inputSide] = map
		end
	end
	return inputChestMap
end

---@class Stock_Keeper
local Stock_Keeper = {}

local handles = {} ---@type Stock_Keeper.inventoryHandle[]

---@param transposerAddress string
---@param interfaceAddress string
function Stock_Keeper.addTransposer(transposerAddress, interfaceAddress)
	local handle = newHandle(transposerAddress, interfaceAddress)
	table.insert(handles, handle)
	return handle
end

---@param name string
---@param damage integer?
---@param size integer?
---@return Stock_Keeper.itemStack
function Stock_Keeper.createItemStack(name, damage, size)
	return stack(name, damage or 0, size or 1)
end

local itemsInNetwork = {} ---@type table<string, ItemStack>
local itemsTofound = {} ---@type table<string, boolean>

local function collectItemsTofound()
	if handles[1].interface.getItemInNetwork then return end
	for _, handle in ipairs(handles) do
		for _, recipe in ipairs(handle.recipes) do
			itemsTofound[recipe.output.name..recipe.output.damage] = true
		end
	end
end

local function collectItemInItemInNetwork()
	local interface = handles[1].interface
	if interface.getItemInNetwork then	return {} end
	local items = {} ---@type table<string, ItemStack>
	local name = ""
	for item in interface.allItems() do
		name = item.name..item.damage
		if itemsTofound[name] then
			items[name] = item
		end
	end
	itemsInNetwork = items
end

---@param interface me_interface
---@param name string
---@param damage integer
---@return ItemStack
local function getItemInNetwork(interface, name, damage)
	if interface.getItemInNetwork then
		return interface.getItemInNetwork(name, damage)
	else
		return itemsInNetwork[name..damage]
	end
end

function Stock_Keeper.run()
	collectItemsTofound()
	while true do
		collectItemInItemInNetwork()
		for _, handle in ipairs(handles) do
			local inputChestMap = handle:feachInputChest()
			local interface = handle.interface
			local transposer = handle.transposer

			for _, recipe in ipairs(handle.recipes) do
				recipe.currentCell:setText("+")
				recipe.currentCell:draw()
				local move = 0
				local output = recipe.output
				local itemInNetwork = getItemInNetwork(interface, output.name, output.damage)
				while recipe.threshold > (itemInNetwork and itemInNetwork.size or 0) + recipe.inProcess do
					local hasItems = true
					local interfaceSetup = false
					for slot, item in ipairs(recipe.inputs) do
						if not interfaceSetup then
							database.set(slot, item.name, item.damage)
							interface.setInterfaceConfiguration(slot, database.address, slot, 64)
							os.sleep(1)
						end
						if transposer.getSlotStackSize(handle.interfaceSide, slot) < item.size  then
							hasItems = false
							recipe.currentCell:setText("-")
							recipe.currentCell:draw()
							break
						end
					end
					interfaceSetup = true
					if hasItems then
						for slot, item in ipairs(recipe.inputs) do
							transposer.transferItem(handle.interfaceSide, recipe.outputSide, item.size, slot)
						end
						recipe.inProcess = recipe.inProcess + recipe.output.size
					else
						break
					end
				end
				os.sleep(1)
				local inputChest = inputChestMap[recipe.inputSide]
				if inputChest and recipe.inProcess > 0 then
					local slot = inputChest[output.name..output.damage]
					if slot then
						move = transposer.transferItem(recipe.inputSide, handle.interfaceSide, recipe.inProcess, slot, 9)
						recipe.inProcess = recipe.inProcess - move
					end
				end
				--print(recipe.output.name, recipe.inProcess)
				recipe.inProcessCell:setText(recipe.inProcess)
				recipe.stockCell:setText((itemInNetwork and itemInNetwork.size or 0) + move)
				if recipe.currentCell.text == "+" then
					recipe.currentCell:setText(" ")
				end
				recipe.row:draw()
				os.sleep(5)
			end
		end
	end
end

function Stock_Keeper.getConfig()
	return config
end

---@param newconf Stock_Keeper.config
function Stock_Keeper.setConfig(newconf)
	config = newconf
end

return Stock_Keeper
