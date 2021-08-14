local component = require("component")
local os = require("os")
local colors = require("colors")
local term = require("term")
local thread = require("thread")
local event  = require("event")



local reactor = component.nc_fission_reactor
local gpu = component.gpu
local modem = component.modem

term.clear()


local t = thread.create(function()
	modem.open(123)
	while true do
		local _, _, from, port, _, message = event.pull("modem_message")
		reactor.alwaysRun = message
		gpu.set(12,3,tostring(reactor.alwaysRun).." ")
		if reactor.alwaysRun == true then
			--gpu.set(1,1,"thread suspend")
			thread.current():suspend()

		end
	end

end)

local function init()
	reactor.maxEnergyStored = reactor.getMaxEnergyStored()
	reactor.energyStored = reactor.getEnergyStored()
	reactor.alwaysRun = false

	reactor.deactivate()
	reactor.runing = reactor.isProcessing()
	gpu.set(1,2,"Statut IDLE ")
	gpu.set(1,3,"Always Run false")
end

function reactor:pcCalcul()
	self.energyPc = self.energyStored/self.maxEnergyStored
end
local function updateGUI()
	reactor:pcCalcul()
	if reactor.runing and reactor.energyPc > 0.9 then
		reactor.deactivate()
		gpu.set(8,2,"IDLE   ")
		reactor.runing = false
	elseif not reactor.runing and reactor.energyPc < 0.2 then
		reactor.activate()
		gpu.set(8,2,"RUNNING")
		reactor.runing = true
	end
end


init()

while true do
	if reactor.alwaysRun then
		reactor.activate()
		gpu.set(8,2,"RUNNING")
		reactor.runing = true
		local _, _, from, port, _, message = event.pull("modem_message")
		reactor.alwaysRun = message
		gpu.set(12,3,tostring(reactor.alwaysRun).." ")
		if reactor.alwaysRun == false then
			t:resume()
			--gpu.set(1,1,"thread running")
			updateGUI()
		end
	else
		reactor.energyStored = reactor.getEnergyStored()
		updateGUI()
		os.sleep(2)
	end
end
for k, v in pairs() do
	print(k, v)
end