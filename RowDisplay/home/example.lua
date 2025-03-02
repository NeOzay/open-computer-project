local rowDisplay = require("rowDisplay")
rowDisplay:clearRows()

local row = rowDisplay:newRow(2)
row:addCell(3, 10):setText("Hello")
row:addCell(10):setText("World")

rowDisplay:drawAllRow()