local component     = require("component")
local sides         = require("sides")
local serialization = require("serialization")
local filesystem    = require("filesystem")
local shell         = require("shell")

local stock_keeper  = require("stock-keeper")
local selector      = require("selector")

local args, options = shell.parse(...)

---@class Stock_Keeper.data
---@field transposers table<string, Stock_Keeper.data.transposer>
local data          = {
	transposers = {}
}

local cacheFile     = shell.resolve("/etc/stockdata.svd")

local function loadConf()
	local file = io.open(cacheFile, "r")
	if not file then
		return
	end
	local content = file:read("*a")
	local err
	data, err = serialization.unserialize(content)
	file:close()
	if not data then
		error("Failed to load configuration: " .. err)
	end
end

local function saveConf()
	local file = io.open(cacheFile, "w")
	if not file then
		error("Failed to open file for writing configuration")
	end
	file:write(serialization.serialize(data))
	file:close()
end

---@param name string
---@param transposer string
---@param interface string
---@param InputSide number?
local function addTransposer(name, transposer, interface, InputSide)
	local pt = component.proxy(transposer)
	local pi = component.proxy(interface)
	if not pt then
		error("Invalid transposer address: " .. transposer)
	elseif pt.type ~= "transposer" then
		error("Invalid transposer type: " .. pt.type)
	end
	if not pi then
		error("Invalid interface address: " .. interface)
	elseif pi.type ~= "me_interface" then
		error("Invalid interface type: " .. pi.type)
	end
	if not data.transposers[transposer] then
		---@class Stock_Keeper.data.transposer
		---@field recipes {output:Stock_Keeper.itemStack, inputs:Stock_Keeper.itemStack[], outputSide:number, inputSide:number}[]
		---@field defaultInputSide number?
		local t = { transposer = transposer, interface = interface, recipes = {}, name = name, defaultInputSide = InputSide }
		data.transposers[transposer] = t
	else
		data.transposers[transposer].name = name
		data.transposers[transposer].interface = interface
	end
end

---@param filename string
---@return {output:Stock_Keeper.itemStack, inputs:Stock_Keeper.itemStack[], outputSide:number, inputSide:number}[]
local function loadBook(filename)
	local recipesBook = {}
	if filesystem.exists(filename) then
		local file = io.open(filename, "r")
		if not file then
			error("Failed to open file for reading recipes book")
		end
		local content = file:read("*a") ---@type string
		local err
		recipesBook, err = serialization.unserialize(content)
		file:close()
		if not recipesBook then
			error("Failed to load recipes book: " .. err)
		end
	else
		io.write("Recipes book not found, creating new one\n")
	end
	return recipesBook
end

---@param book table
---@param filename string
local function saveBook(book, filename)
	local file = io.open(filename, "w")
	if not file then
		error("Failed to open file for writing recipes book")
	end
	file:write(serialization.serialize(book, math.huge))
	file:close()
end

---@param stack ItemStack
---@return Stock_Keeper.itemStack
local function item(stack)
	return { label = stack.label, name = stack.name, damage = stack.damage, size = stack.size }
end

---@param book table
local function optimizeRecipes(book)
	for name, recipe in ipairs(book) do
		local max = recipe.output.size
		for _, input in ipairs(recipe.inputs) do
			max = math.max(max, input.size)
		end
		max = 64 // max
		recipe.output.size = recipe.output.size * max
		for _, input in ipairs(recipe.inputs) do
			input.size = input.size * max
		end
	end
end

----------------

loadConf()

local bookslocate = "/home/recipes-books/"

---@param values? (Stock_Keeper.data.transposer|string)[]
---@param choices? string[]
---@return Stock_Keeper.data.transposer|string|nil
local function selectTransposer(values, choices)
	if not next(data.transposers) then
		io.write("No transposers found\n")
		return
	end
	values = values or {}
	choices = choices or {}
	for _, trans in pairs(data.transposers) do
		table.insert(values, trans)
		table.insert(choices, trans.name)
	end
	return selector(values, choices, "select transposer: ")
end

if args[1] == "add" and not args[2] then
	local values = { "recipes", "transposer" }
	local choices = { "Add recipes", "Add transposer" }
	local choice = selector(values, choices, "select what to add: ")
	if not choice then
		return
	end
	args[2] = choice
end

if args[1] == "add" and args[2] == "transposer" then
	io.write("Enter transposer address: ")
	local t = io.stdin:read()
	if not t then
		return
	end
	io.write("Enter interface address: ")
	local i = io.stdin:read()
	if not i then
		return
	end
	io.write("Enter transposer name: ")
	local n = io.stdin:read()
	if not n then
		return
	end
	if n == "" then
		n = t
	end
	io.write("Enter transposer default output side (optional): ")
	local os = io.stdin:read()
	if os == false then
		return
	end
	addTransposer(n, t, i, os)
	saveConf()
end

---@param path string?
---@param collector string[]?
local function listRecipesBooks(path, collector)
	path = path or bookslocate
	collector = collector or {}
	for file in filesystem.list(path) do
		if file:find("/$") then
			listRecipesBooks(path .. file .. "/", collector)
		else
			table.insert(collector, path .. file)
		end
	end
	return collector
end

if args[1] == "add" and args[2] == "recipes" then
	local trans = selectTransposer()
	if not trans then
		return
	end
	if not args[3] then
		local bookslist = listRecipesBooks()
		if #bookslist < 1 then
			io.write("No recipes books found, create one first\n")
			return
		end
		local choice = selector(bookslist, bookslist, "select recipes book: ")
		if not choice then
			return
		end
		local recipesBook = loadBook(choice)
		local sidesStr = ""
		for i = 0, 5 do
			sidesStr = sidesStr .. i .. ". " .. sides[i] .. "   "
		end

		local lastinputSide
		local lastoutputSide
		io.write("Enter Sides for all recipes\n")
		io.write(sidesStr .. "\n")
		for index, recipes in ipairs(recipesBook) do
			while not recipes.outputSide do
				io.write("Enter output side for recipe " .. recipes.output.label .. ": ")
				local side = tonumber(io.stdin:read())
				if side and side > 0 and side < 6 then
					recipes.outputSide = side
				else
					io.write(sidesStr .. "\n")
				end
			end

			while not recipes.inputSide do
				io.write("Enter input side for recipe " .. recipes.output.label .. ": ")
				local side = tonumber(io.stdin:read())
				if side and side > 0 and side < 6 then
					recipes.inputSide = side
				else
					io.write(sidesStr .. "\n")
				end
			end
		end
		for name, recipe in ipairs(recipesBook) do
			io.write("Adding recipe " .. recipe.output.name .. "\n")
			table.insert(trans.recipes, recipe)
		end
	end
	saveConf()
end

if args[1] == "clear" and not args[2] then
	local values = { "recipes", "transposer", "book" }
	local choices = { "Clear recipes", "Clear transposer", "Clear book" }
	local choice = selector(values, choices, "select what to clear: ")
	if not choice then
		return
	end
	args[2] = choice
end

if args[1] == "clear" and args[2] == "transposer" then
	local choice = selectTransposer({ "all" }, { "clear all transposers" })
	if not choice then
		return
	end
	if choice == "all" then
		data.transposers = {}
	elseif type(choice) == "table" then
		data.transposers[choice.transposer] = nil
	end
	saveConf()
end

if args[1] == "clear" and args[2] == "recipes" then
	local trans = selectTransposer()
	if not trans or type(trans) == "string" then
		return
	end
	if #trans.recipes == 0 then
		io.write("No recipes to remove\n")
		return
	end
	local values = { "all" } ---@type (number|string)[]
	local choices = { "Clear all recipes" }
	for ri, recipe in ipairs(trans.recipes) do
		local ingrList = {}
		for _, ingr in ipairs(recipe.inputs) do
			table.insert(ingrList, ingr.size .. " " .. ingr.label)
		end
		table.insert(values, ri)
		table.insert(choices, recipe.output.size .. " " .. recipe.output.label .. " <- " .. table.concat(ingrList, ","))
	end
	local choice = selector(values, choices, "select recipe to clear: ")

	if choice == "all" then
		io.write("Clearing all recipes")
		trans.recipes = {}
	elseif type(choice) == "number" then
		io.write("Clearing recipe " .. trans.recipes[choice].output.label)
		table.remove(trans.recipes, choice)
	end
	saveConf()
end

if args[1] == "clear" and args[2] == "book" then
	local bookslist = listRecipesBooks()
	if #bookslist < 1 then
		io.write("No recipes books found\n")
		return
	end
	local bookFile = selector(bookslist, bookslist, "select recipes book: ")
	if not bookFile then
		return
	end
	local values = { "all" } ---@type (number|string)[]
	local choices = { "Clear all recipes" }
	local book = loadBook(bookFile)
	for ri, recipe in ipairs(book) do
		local ingrList = {}
		for _, ingr in ipairs(recipe.inputs) do
			table.insert(ingrList, ingr.size .. " " .. ingr.label)
		end
		table.insert(values, ri)
		table.insert(choices, recipe.output.size .. " " .. recipe.output.label .. " <- " .. table.concat(ingrList, ","))
	end
	local choice = selector(values, choices, "select recipe to clear: ")

	if choice == "all" then
		io.write("Clearing all recipes")
		book = {}
	elseif type(choice) == "number" then
		io.write("Clearing recipe " .. book[choice].output.label)
		table.remove(book, choice)
	end
	saveBook(book, bookFile)
end

if args[1] == "book" then
	if not filesystem.exists(bookslocate) then
		filesystem.makeDirectory(bookslocate)
	end
	local filename = args[2]
	if not filename then
		io.write("Enter filename: ")
		filename = io.stdin:read()
	end
	if filename == "" or not filename then
		filename = bookslocate .. "book.svd"
	else
		filename = filename:match("%.svd$") and filename or filename .. ".svd"
		filename = bookslocate .. filename
	end
	local recipesBook = loadBook(filename)
	local address = selectTransposer()
	if not address or type(address) == "string" then
		return
	end
	local transposer = component.proxy(address.transposer, "transposer")
	if not transposer then
		error("Failed to get transposer")
	end
	local values = {} ---@type number[]
	local choices = {}
	for i = 0, 5 do
		local invname = transposer.getInventoryName(i)
		if invname and invname ~= "tile.appliedenergistics2.BlockInterface" then
			local stack = transposer.getSlotStackSize(i, 1)
			if stack and stack > 0 then
				table.insert(values, i)
				table.insert(choices, invname .. " (" .. sides[i] .. ")")
			end
		end
	end
	if not next(values) then
		error("No inventories found")
	end
	local chestSide = selector(values, choices, "select chest side: ")
	if not chestSide then
		return
	end

	local currentRecipe = nil
	for i = 1, transposer.getInventorySize(chestSide) or 0 do
		local stack = transposer.getStackInSlot(chestSide, i)
		if not stack then
			if currentRecipe then
				table.insert(recipesBook, currentRecipe)
				currentRecipe = nil
			end
			goto continue
		end
		if not currentRecipe then
			currentRecipe = { output = item(stack), inputs = {} }
		else
			table.insert(currentRecipe.inputs, item(stack))
		end
		::continue::
	end
	optimizeRecipes(recipesBook)
	saveBook(recipesBook, filename)
end

if args[1] == "info" and not args[2] then
	local values = { "book", "transposer" }
	local choices = { "List recipes in book", "List recipes in transposer" }
	local choice = selector(values, choices, "select what to clear: ")
	if not choice then
		return
	end
	args[2] = choice
end

if args[1] == "info" and args[2] == "transposer" then
	local transposer = selectTransposer()
	if not transposer then
		return
	end
	io.write("Transposer: " .. transposer.name .. "\n")
	for _, recipe in ipairs(transposer.recipes) do
		local ingrList = {}
		for _, ingr in ipairs(recipe.inputs) do
			table.insert(ingrList, ingr.size .. " " .. ingr.label)
		end
		io.write(recipe.output.size .. " " .. recipe.output.label .. " <- " .. table.concat(ingrList, ",") .. "\n")
	end
end

if args[1] == "info" and args[2] == "book" then
	local bookslist = listRecipesBooks()
	if #bookslist < 1 then
		io.write("No recipes books found\n")
		return
	end
	local choice = selector(bookslist, bookslist, "select recipes book: ")
	if not choice then
		return
	end
	local recipesBook = loadBook(choice)
	for _, recipe in ipairs(recipesBook) do
		local ingrList = {}
		for _, ingr in ipairs(recipe.inputs) do
			table.insert(ingrList, ingr.size .. " " .. ingr.label)
		end
		io.write(recipe.output.size .. " " .. recipe.output.label .. " <- " .. table.concat(ingrList, ",") .. "\n")
	end
end

if args[1] == "run" then
	for add, trans in pairs(data.transposers) do
		local inv = stock_keeper.addStock(add, trans.interface)
		for _, recipes in ipairs(trans.recipes) do
			inv:addRecipe(recipes.output, 500):addIngredients(recipes.inputs):setSides(recipes.outputSide, recipes
			.inputSide)
		end
	end
	stock_keeper.run()
end