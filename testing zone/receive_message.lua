local component = require("component")
local os = require("os")
local term = require("term")
local event = require("event")


local gpu= component.gpu
local modem= component.modem

modem.open(123)
print(modem.isOpen(123))

local _, _, from, port, _, message = event.pull("modem_message")
print("Got a message from " .. from .. " on port " .. port .. ": " .. tostring(message))
