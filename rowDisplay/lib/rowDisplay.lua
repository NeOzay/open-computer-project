local component = require("component")
local term      = require("term")

local gpu = component.gpu

---@class RowManager.Cell
---@field text string
---@field formatedText? string
---@field lpadding integer
---@field rpadding integer
---@field align "left"|"center"|"right"
---@field width integer
---@field x integer
---@field y integer
---@field separator string
local Cell = {}
Cell.__index = Cell

---@param x integer
---@param y integer
---@param width integer
---@param lpadding? integer
---@param rpadding? integer
---@param align? "left"|"center"|"right"
---@param separator? string
---@return RowManager.Cell
local function newCell(x, y, width, lpadding, rpadding, align, separator)
	local cell = setmetatable({}, Cell)
	cell.text = ""
	cell.x = x
	cell.y = y
	cell.width = width
	cell.lpadding = lpadding or 0
	cell.rpadding = rpadding or 0
	cell.align = align or "left"
	cell.separator = separator or "|"
	return cell
end

---@param cell RowManager.Cell
local function formatText(cell)
	if cell.formatedText then return	end
	local space = cell.width - cell.lpadding - cell.rpadding - #cell.separator
	local text = cell.text
	if #text > space then
		text = string.sub(text, 1, space)
	elseif cell.align == "right" then
		text = string.rep(" ", space - #text) .. text
	elseif cell.align == "center" then
		local lspace = math.floor((space - #text) / 2)
		text = string.rep(" ", lspace) .. text .. string.rep(" ", space - #text - lspace)
	else
		text = text .. string.rep(" ", space - #text)
	end
	cell.formatedText = text
end

---@param text any
function Cell:setText(text)
	self.text = tostring(text)
	self.formatedText = nil
	return self
end

---@param lpadding integer
---@param rpadding integer
function Cell:setPadding(lpadding, rpadding)
	self.lpadding = lpadding
	self.rpadding = rpadding
	self.formatedText = nil
	return self
end

---@param align "left"|"center"|"right"
function Cell:setAlign(align)
	self.align = align
	self.formatedText = nil
	return self
end

---@param separator string
function Cell:setSeparator(separator)
	self.separator = separator
	return self
end

---@param separator? boolean
function Cell:draw( separator)
	formatText(self)
	gpu.set(self.x + self.lpadding, self.y, self.formatedText..(separator and self.separator or ""))
end

---@class RowManager.Row
---@field rowNb number
---@field cells RowManager.Cell[]
local Row = {}
Row.__index = Row

---@param x integer
---@param width integer
---@param lpadding? integer
---@param rpadding? integer
---@param align? "left"|"center"|"right"
---@param separator? string
---@return RowManager.Cell
---@overload fun(self:RowManager.Row, width: integer):RowManager.Cell
function Row:addCell(x, width, lpadding, rpadding, align, separator)
	local Cells = self.cells
	if not width then
		width = x
		if #self.cells == 0 then
			x = 1
		else
			x = Cells[#Cells].x + Cells[#Cells].width
		end
	end
	local cell = newCell(x, self.rowNb, width, lpadding, rpadding, align, separator)
	table.insert(self.cells, cell)
	return cell
end

---@param cellNb integer
---@param text string
function Row:setCellText(cellNb, text)
	self.cells[cellNb].text = text
	self.cells[cellNb].formatedText = nil
	return self
end

---@param cellNb integer
---@param lpadding integer
---@param rpadding integer
function Row:setPadding(cellNb, lpadding, rpadding)
	self.cells[cellNb].lpadding = lpadding
	self.cells[cellNb].rpadding = rpadding
	self.cells[cellNb].formatedText = nil
	return self
end

---@param cellNb integer
---@param align "left"|"center"|"right"
function Row:setAlign(cellNb, align)
	self.cells[cellNb].align = align
	self.cells[cellNb].formatedText = nil
	return self
end

local width, height = gpu.getResolution()

---@param cellNb? integer
function Row:draw(cellNb)
	local last = #self.cells
	if cellNb then
			self.cells[cellNb]:draw(cellNb ~= last)
		return
	end
	gpu.fill(1, self.rowNb, width, 1, " ")
	for i, cell in ipairs(self.cells) do
		cell:draw(i ~= last)
	end
end

---@class RowManager
local RowManager = {}
RowManager.__index = RowManager
local rows = {} ---@type RowManager.Row[]

---@param row RowManager.Row
local function movebottomRow(row)
	row.rowNb = row.rowNb + 1
	for _, cell in ipairs(row.cells) do
		cell.y = row.rowNb
	end
end

---@param rowNunber? integer
---@return RowManager.Row
function RowManager:newRow(rowNunber)
	rowNunber = rowNunber or 1
	local row = setmetatable({}, Row)
	row.cells = {}
	row.rowNb = rowNunber

	local otherRow = rows[rowNunber]
	rows[rowNunber] = row
	while otherRow do
		movebottomRow(otherRow)
		otherRow:draw()
		local bottomRow = rows[otherRow.rowNb]
		rows[otherRow.rowNb] = otherRow
		otherRow = bottomRow
	end
	row:draw()
	return row
end

---@param rowNb? integer
function RowManager:clearRows(rowNb)
	if rowNb then
		rows[rowNb] = nil
		return
	end
	rows = {}
end

function RowManager.drawAllRow()
	term.clear()
	for _, row in pairs(rows) do
		row:draw()
	end
end

return RowManager
