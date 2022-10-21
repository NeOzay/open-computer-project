local sides = require("doc.standard.sides")
for i = 0, #sides -1 do
	print(i)
	
end
---@type table<number, Item>
local tt = {

}

---@generic  K, V
---@param t table<K, V>
---@return fun(t2: table<K, V>, k: K):K, V
local function loop(t)
	return function (t2, k)
		local k2, v = next(t2, k)
		if not k2 then
			k2, v = next(t2)
		end
		return k2 , v
	end, t
end

for key, value in loop(tt) do
	print(key)
	print(value)
	for i = 1, 1000000000 do	end
end
