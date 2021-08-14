local os = require("os")
local filesystem = require("filesystem")
local component = require("component")
local shell = require("shell")

local disk_drive = component.disk_drive

local floppy = filesystem.proxy(disk_drive.media())

floppy.makeDirectory("/home")
floppy.makeDirectory("/home/lib")
floppy.makeDirectory("/bin")
floppy.setLabel("my Lib")
filesystem.mount(floppy, "/floppy")

local lib = {
    relay = "4Y5A1at8",
    patternFind = "eKPEE2wK",
    textObject = "4xUqyezT",
    color = "uSRLg7D2",
    button = "qHfbQ8xp",
    panel = "ed0bzuGS"
}
local bin = {
    makeDoc = "yiWkaU1p",
    getMethods = "siZENpNx"
}
shell.setWorkingDirectory("/floppy/home/lib")
for name, pastID in pairs(lib) do
    os.execute("pastebin get -f " .. pastID .. " " .. name .. ".lua")
end

shell.setWorkingDirectory("/floppy/bin")
for name, pastID in pairs(bin) do
    os.execute("pastebin get -f " .. pastID .. " " .. name .. ".lua")
end

shell.setWorkingDirectory("/home")