local component = require("component")
local os = require("os")
local colors = require("colors")
local term = require("term")
local thread = require("thread")
local event  = require("event")
local serialization = require("serialization")


local reactor = component.nc_fission_reactor
local gpu = component.gpu
local modem = component.modem

term.clear()

reactor.maxEnergyStored = reactor.getMaxEnergyStored()
reactor.energyStored = reactor.getEnergyStored()
reactor.alwaysRun = false

reactor.deactivate()
reactor.runing = reactor.isProcessing()
gpu.set(8,2,"IDLE  ")

function reactor:pcCalcul()
	self.energyPc = self.energyStored/self.maxEnergyStored
end

local function write(xpos,ypos,text,colorB,colorF)
  gpu.setBackground(colorB)
  gpu.setForeground(colorF)
  gpu.set(xpos,ypos,text)
end


local function updateGUI()
	reactor:pcCalcul()
	if reactor.runing and reactor.energyPc > 0.9 then
		reactor.deactivate()
		gpu.set(8,2,"IDLE  ")
		reactor.runing = false
	elseif not reactor.runing and reactor.energyPc < 0.2 then
		reactor.activate()
		gpu.set(8,2,"RUNING")
		reactor.runing = true
	end
end

local function initGUI()
	gpu.set(1,2,"Statut")
	gpu.set(1,3,"always Run")
	gpu.set(12,3,tostring(reactor.alwaysRun))
	updateGUI()
end



local t = thread.create(
		function(statut)
			modem.open(123)
			statut = statut or false
			while true do
				local _, _, from, port, _, message = event.pull("modem_message")
				reactor.alwaysRun = message
				gpu.set(12,3,tostring(reactor.alwaysRun).." ")
				if reactor.alwaysRun  then
					thread.current():suspend()
				end
			end
end,false
)



initGUI()
while true do
	if reactor.alwaysRun then
		reactor.activate()
		gpu.set(8,2,"RUNING")
		reactor.runing = true
		local _, _, from, port, _, message = event.pull("modem_message")
		reactor.alwaysRun = message
		gpu.set(12,3,tostring(reactor.alwaysRun).." ")
		if not reactor.alwaysRun then
			t:resume()
			reactor.deactivate()
			gpu.set(8,2,"IDLE  ")
			reactor.runing = false
		end
	else
		reactor.energyStored = reactor.getEnergyStored()
		updateGUI()
		os.sleep(2)
	end
end