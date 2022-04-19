
---@class disk_drive
---@field address string
local disk_drive = {}
disk_drive.slot = -1
disk_drive.type = "disk_drive"

---Eject the currently present medium from the drive.
---@return boolean
---@overload fun(velocity:number):boolean
function disk_drive.eject() end

---Checks whether some medium is currently in the drive.
---@return boolean
function disk_drive.isEmpty() end

---Return the internal floppy disk address
---@return string
function disk_drive.media() end

return disk_drive


