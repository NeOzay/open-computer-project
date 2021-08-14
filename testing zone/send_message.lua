local component = require("component")
local os = require("os")
local term = require("term")
local event = require("event")
local shell = require("shell")

local gpu= component.gpu
local modem = component.modem

local args, ops = shell.parse(...)

modem.
modem.open(123)
-- Send some message.
modem.broadcast(123, ops.t or false)
-- Wait for a message from another network card.
