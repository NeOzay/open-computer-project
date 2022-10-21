local component = require("component");
local sides = require("sides");
local item = require("item");
local inspect = require("inspect")
local args = {...};

local bee_types = {
    ['Forestry:beeDroneGE'] = "Drone",
    ['Forestry:beePrincessGE'] = "Princess",
    ['Forestry:beeQueenGE'] = "Queen",
    ['Forestry:beeLarvaeGE'] = "Larvae"
};

local bee_genome = {
    "Species", 
    "Speed",
    "Lifespan",
    "Fertility",
    "Temperature Tolerance",
    "Nocturnal",
    nil,
    "Humidity Tolerance",
    "Tolerant Flyer",
    "Cave Dwelling",
    "Flowering",
    "Territory",
    "Effect",
};

local bee_formatter = {

};

local function pp(s)
    print(inspect.inspect(s))
end

local function print_help()
  print("beealyzer [inv side] [slot]")
end

if #args ~= 2 then
  print_help()
  return
end

local t = component.getPrimary('transposer')
if t == nil then
    error("This program requires a transposer (sorry robot fans)")
end

local stack = t.getStackInSlot(sides[args[1]], tonumber(args[2]));

local bee_type = bee_types[stack.name];
if bee_type == nil then
    print("not a bee")
    return
end

if not stack.hasTag then
    print("this is a bee that somehow lacks any nbt")
    return
end

local tag = item.readTag(stack)
print(stack.label)
print("N\tActive\tInactive")
for i, chrom in ipairs(tag.Genome.Chromosomes) do
print(i..'\t'..chrom['UID0']..'\t'..chrom['UID1'])
end