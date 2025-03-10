---@generic K
---@param values K[]
---@param choices string[]
---@param prompt string
---@param row boolean?
---@return K?
local function selector(values, choices, prompt, row)
	table.insert(values, 'Cancel')
	if values ~= choices then
		table.insert(choices, "Cancel")
	end
	if not row then
		for index, c in ipairs(choices) do
			io.write(index .. ". " .. c .. "\n")
		end
	else
		local s = ""
		for index, c in ipairs(choices) do
			s = s .. index .. ". " .. c .. "\t"
			if index % 3 == 0 then
				s = s .. "\n"
			end
		end
		io.write(s .. "\n")
	end
	local choice
	while not choice do
		io.write(prompt)
		local input = io.read()
		if not input then
			return nil
		end
		choice = values[tonumber(input)]
	end
	if choice == "Cancel" then
		return nil
	end
	return choice
end

return selector
