---@meta _

---@class geolyzer:ProxyBase
local geolyzer = {}

--- Analyzes the density of an area at the specified relative coordinates.
--- Returns a list of hardness values for the blocks in the specified range.
--- The coordinates are relative to the location of the geolyzer.
---@param x number The relative x-coordinate.
---@param z number The relative z-coordinate.
---@param y? number Optional. The relative y-coordinate.
---@param w? number Optional. The width of the analyzed area.
---@param d? number Optional. The depth of the analyzed area.
---@param h? number Optional. The height of the analyzed area.
---@param ignoreReplaceable? boolean|table Optional. Whether to ignore replaceable blocks or additional options.
--- If set to true, replaceable blocks will be ignored.
--- If set to a table of options, additional settings can be provided.
---@return table @A table of hardness values for the analyzed area.
function geolyzer.scan(x, z, y, w, d, h, ignoreReplaceable) end

--- Get some information on a directly adjacent block.
--- Returns a table containing information about the block.
--- By default, the returned table includes the string ID of the block, metadata, hardness, and more.
--- Note that a single call to this consumes the same amount of energy as a call to scan.
--- This method can be disabled with the misc.allowItemStackInspection setting in the config.
---@param side number The side of the geolyzer to analyze.
---@param options? table Optional. Additional options for analysis.
---@return table @Information about the block on the specified side.
function geolyzer.analyze(side, options) end

--- Stores an item stack representation of the block on the specified side of the geolyzer to the specified slot of a database component.
--- Do not expect this to work well for every block, especially for mod's blocks that are differentiated by NBT data (such as robots).
---@param side number The side of the geolyzer to store.
---@param dbAddress string The address of the database component.
---@param dbSlot number The slot of the database component to store the item stack representation.
---@return boolean @Whether the storing operation was successful.
function geolyzer.store(side, dbAddress, dbSlot) end

--- Detects the block on the given side relative to the robot and returns whether or not the robot can move into the block.
--- Returns a general description of the block.
---@param side number The side to detect.
---@return boolean,string @Whether the robot can move into the block, and a description of the block.
function geolyzer.detect(side) end

--- Returns whether there is a clear line of sight to the sky directly above.
--- Transparent blocks, e.g., glass don't affect the line of sight.
---@return boolean @Whether there is a clear line of sight to the sky.
function geolyzer.canSeeSky() end

--- Returns whether the sun is currently visible directly above.
--- The result is affected by possible blocks blocking the line of sight directly above.
---@return boolean @Whether the sun is currently visible.
function geolyzer.isSunVisible() end
