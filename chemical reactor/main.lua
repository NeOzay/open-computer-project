local component = require("component")
local sides =  require("sides")
local tankmanager = component.transposer
local chemSize = sides.north
local tankssides = {sides.bottom, sides.top }

local function getLiquidInChem()
	local fluidsList = tankmanager.getFluidInTank(chemSize)
	for i = 1, 3 do
		if fluidsList[i].name then
			return fluidsList[i].name
		end
	end
end

while true do
	local current = getLiquidInChem()
	if not current then
		for index, side in ipairs(tankssides) do
			if tankmanager.getTankLevel(side) > 2000 then
				tankmanager.transferFluid(side, chemSize, 2000)
				break
			end
		end
	end
	os.sleep(5)
end