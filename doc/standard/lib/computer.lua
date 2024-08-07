---@meta computer

---@class computerlib
local computer = {}

--- Returns the component address of this computer.
---@return string
function computer.address() end

--- Returns the component address of the computer's temporary file system (if any), used for mounting it on startup.
---@return string
function computer.tmpAddress() end

--- Returns the amount of memory currently unused, in bytes.
--- If this gets close to zero your computer will probably soon crash with an out of memory error.
--- Note that for OpenOS, it is highly recommended to at least have 1x tier 1.5 RAM stick or more.
--- The os will boot on a single tier 1 ram stick, but quickly and easily run out of memory.
---@return number
function computer.freeMemory() end

--- Returns the total amount of memory installed in this computer, in bytes.
---@return number
function computer.totalMemory() end

--- Returns the amount of energy currently available in the network the computer is in.
--- For a robot this is the robot's own energy / fuel level.
---@return number
function computer.energy() end

--- Returns the maximum amount of energy that can be stored in the network the computer is in.
--- For a robot this is the size of the robot's internal buffer (what you see in the robot's GUI).
---@return number
function computer.maxEnergy() end

--- Returns the time in real world seconds this computer has been running.
--- Measured based on the world time that passed since it was started - meaning this will not increase while the game is paused, for example.
---@return number
function computer.uptime() end

--- Shuts down the computer.
--- Optionally reboots the computer, if reboot is true.
--- i.e. shuts down, then starts it again automatically.
--- This function never returns.
---@param reboot boolean? @Optional. If true, the computer will be rebooted after shutdown.
function computer.shutdown(reboot) end

--- Get the address of the filesystem component from which to try to boot first.
--- @return string
function computer.getBootAddress() end

--- Set the address of the filesystem component from which to try to boot first.
--- Call with nil / no arguments to clear.
--- @param address string?
function computer.setBootAddress(address) end

--- Returns the current runlevel the computer is in.
--- Current Runlevels in OpenOS are:
--- S: Single-User mode, no components or filesystems initialized yet
--- 1: Single-User mode, filesystems and components initialized - OpenOS finished booting
--- @return string|number
function computer.runlevel() end

--- A list of all users registered on this computer, as a tuple.
--- To iterate the result as a list, use `table.pack`, first.
--- Please see the user rights documentation.
--- @return string, ...
function computer.users() end

--- Registers a new user with this computer.
--- Returns true if the user was successfully added.
--- Returns nil and an error message otherwise.
--- The user must be currently in the game.
--- The user will gain full access rights on the computer.
--- In the shell, useradd USER is a command line option to invoke this method.
--- @param name string
--- @return boolean|nil, string
function computer.addUser(name) end

--- Unregisters a user from this computer.
--- Returns true if the user was removed, false if they weren't registered in the first place.
--- The user will lose all access to this computer.
--- When the last user is removed from the user list, the computer becomes accessible to all players.
--- userdel USER is a command line option to invoke this method.
--- @param name string
--- @return boolean
function computer.removeUser(name) end

--- Pushes a new signal into the queue.
--- Signals are processed in a FIFO order.
--- The signal has to at least have a name.
--- Arguments to pass along with it are optional.
--- Note that the types supported as signal parameters are limited to the basic types nil, boolean, number, string, and tables.
--- Yes tables are supported (keep reading).
--- Threads and functions are not supported.
--- Note that only tables of the supported types are supported.
--- That is, tables must compose types supported, such as other strings and numbers, or even sub tables.
--- But not of functions or threads.
--- @param name string
function computer.pushSignal(name, ...) end

--- Tries to pull a signal from the queue, waiting up to the specified amount of time before failing and returning nil.
--- If no timeout is specified waits forever.
--- The first returned result is the signal name, following results correspond to what was pushed in pushSignal, for example.
--- These vary based on the event type.
--- Generally it is more convenient to use event.pull from the event library.
--- The return value is the very same, but the event library provides some more options.
--- @param timeout number @Optional. The time to wait for a signal before returning nil. If not provided, waits indefinitely.
--- @return string name, ...
function computer.pullSignal(timeout) end

--- Causes the computer to produce a beep sound.
--- If frequency is a number, its value must be between 20 and 2000.
---
--- This method is overloaded taking a single string parameter as a pattern of dots . and dashes - for short and long beeps respectively.
--- @param frequency? string|number @Optional. The frequency of the beep sound.
--- @param duration? number @Optional. The duration of the beep sound.
function computer.beep(frequency, duration) end

--- Returns a table of information about installed devices in the computer.
--- @return table
function computer.getDeviceInfo() end

return computer
