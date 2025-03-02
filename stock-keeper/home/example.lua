local sides = require("sides")

local stock_keeper = require("stock-keeper")

local inv1 = stock_keeper.addTransposer("e8128c98-105b-4779-a2be-5876d4b0a75b", "fbf061ba-8ee0-477c-8eb1-7ff1aa70138a")

--local inv2 = stock_keeper.addTransposer("77c0043d-a3a4-419d-a302-71a3346479d4", "5504ded9-9cbe-478a-8ec2-d01eda5d4c0c")

local stack = stock_keeper.createItemStack

local metaitem01 = "gregtech:gt.metaitem.01"

local stainlessSteel = stack(metaitem01, 11306, 64)
local stainlessSteelDust = stack(metaitem01, 2306, 64)

local irondust = stack(metaitem01, 2032, 64)
local steel = stack(metaitem01, 11305, 64)


inv1:addRecipe(stainlessSteel, 500)
	:addIngredient(stainlessSteelDust):setSides(sides.south, sides.east)

inv1:addRecipe(steel, 500)
	:addIngredient(irondust):setSides(sides.south, sides.east)

stock_keeper.run()