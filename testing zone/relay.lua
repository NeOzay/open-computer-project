local component = require("component")
local os = require("os")
local term = require("term")
local event = require("event")

term.clear()

local gpu= component.gpu
local modem= component.modem

modem.open(123)
print(modem.isOpen(123))

while true do
	local _, _, from, port, _, message = event.pull("modem_message")
	print("receive message from "..from)
	if from == "f5047a6a-88f8-41a0-83b8-6c1e35ceaef0" then
		modem.broadcast(123, message)
		print("broadcast message")
	end
end
