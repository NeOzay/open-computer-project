local os = require("os")
local filesystem = require("filesystem")
local component = require("component")
local shell = require("shell")
local term = require("term")

local floppy = filesystem.proxy("my Lib")

gpu = component.gpu

term.clear()

local mountName = floppy.getLabel() or "floppy"

filesystem.mount(floppy, "/" .. mountName)
shell.setWorkingDirectory("/" .. mountName .. "/home/lib")

---@type fun():panel
local Panel = require("panel")


local Color = require("color")


local Button = require("button")


local TO = require("textObject")

local TextObject = TO.TextObject

local drawtO = TO.drawtO

---@type package[]
local lib = {}
for i, file in ipairs(floppy.list("/home/lib")) do
    ---@shape package
    ---@field name string
    ---@field install boolean
    local x = { name = file, install = false }
    table.insert(lib, x)
end

---@type package[]
local bin = {}
for i, file in ipairs(floppy.list("/bin")) do
    table.insert(bin, { name = file, install = false })
end

local dependency = {
    textObject = { "color" },
    button = { "color", "textObject" },
    panel = { "color", "textObject", "button" }
}

gpu.setResolution(106,34)

local p = Panel()

p:setPos(1, 1)
p:setSize(106, 34)
p:setDefautBackgroundColor(Color.cyan)
p:setDefautForegroundColor(Color.silver)


local title = TextObject("package manager installer",Color.red,Color.silver)

for k,package in ipairs(lib) do
    p:addStatic(TextObject(package.name,Color.black),5,k+5)

    local b = Button()
    b:setTextureON(TextObject())

    p:addButton(b,2,k+5)
end

p:setTitle(title,1,1)
p:centerText(p.title)

p:drawFrame()
p:drawTitle()
p:drawStatics()
p:drawButtons()
local function install(package) end

