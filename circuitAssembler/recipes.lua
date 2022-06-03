local plastic_board = "Plastic Circuit Board"
local cpu = "CPU"
local resistor = "SMD Resistor"
local capacitor = "SMD Capacitor"
local transistor = "SMD Transistor"
local fine_redAlloy = "Fine Red Alloy Wire"
local fine_copper = "Fine Copper Wire"

---@param name string
---@param n number
local function item(name, n)
	return {name = name, n = n}
end
---@class Item
---@field name string
---@field n number

---@class assSlot
---@field [1] Item
---@field [2] Item
---@field	[3] Item
---@field [4] Item
---@field [5] Item
---@field [6] Item

---@type table<string, Item[]>
local recipes = {}
recipes["Integrated Processor"] = {
	item(plastic_board, 1),
	item(cpu, 1),
	item(resistor, 4),
	item(capacitor, 4),
	item(transistor,4),
	item(fine_redAlloy, 4)
}
recipes["Microprocessor"] = {
	item(plastic_board, 1),
	item(cpu, 1),
	item(resistor, 2),
	item(capacitor, 2),
	item(transistor,2),
	item(fine_copper, 2)
}

return recipes
