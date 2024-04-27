local shell = require("shell")
local filesystem = require("filesystem")

require("autocrop.config").load()

local args, opts = shell.parse(...)

if not args[1] then
   io.write([[
These Open Computers (OC) program will automatically tier-up, stat-up, and spread (duplicate) IC2 crops for you
Usage:
   stat
      Stat will automatically stat-up your target crop until the Gr + Ga - Re is at least 52 (configurable) for ALL crops on the working farm

   spread
      Spread will automatically spread (duplicate) your target crop until the storage farm is full.

   edit
      Edit the configuration file

   run <program>
      Run the user custom program

   ]
]]
   )
end

if args[1] == "stat" then
   dofile("/etc/autocrop/program/stat.lua")
end

if args[1] == "spread" then
   dofile("/etc/autocrop/program/spread.lua")
end

if args[1] == "run" then
   local path = shell.resolve(args[2])
   if not filesystem.exists(path) and filesystem.exists("/etc/autocrop/program/"..args[2]) then
      path = "/etc/autocrop/program/"..args[2]
   end
   if filesystem.isDirectory(path) then
      io.stderr:write(args[2].." is a directory\n")
      return
   end
   if filesystem.exists(path) then
      dofile(path)
   else
      io.stderr:write("unble to find the program "..args[2].."\n")
   end

end

if args[1] == "edit" then
   shell.execute('edit /etc/autocrop/conf.lua')
   return
end