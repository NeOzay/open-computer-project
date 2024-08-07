local bit32 = require("mineOS.Bit32")
local unicode = require("unicode")

---@class MineOS.filesystemLib:filesystemLib
local filesystem = setmetatable({}, {__index = require("filesystem")})

local BUFFER_SIZE = 1024

function filesystem.extension(path, lower)
	return path:match("[^%/]+(%.[^%/]+)%/?$")
end




local function readString(self, count)
	-- If current buffer content is a "part" of "count of data" we need to read
	if count > #self.buffer then
		local data, chunk = self.buffer, nil

		while #data < count do
			chunk = self.proxy.read(self.stream, BUFFER_SIZE)

			if chunk then
				data = data .. chunk
			else
				self.position = self:seek("end", 0)

				-- EOF at start
				if data == "" then
					return nil
				-- EOF after read
				else
					return data
				end
			end
		end

		self.buffer = data:sub(count + 1, -1)
		chunk = data:sub(1, count)
		self.position = self.position + #chunk

		return chunk
	else
		local data = self.buffer:sub(1, count)
		self.buffer = self.buffer:sub(count + 1, -1)
		self.position = self.position + count

		return data
	end
end

local function readLine(self)
	local data = ""
	while true do
		if #self.buffer > 0 then
			local starting, ending = self.buffer:find("\n")
			if starting then
				local chunk = self.buffer:sub(1, starting - 1)
				self.buffer = self.buffer:sub(ending + 1, -1)
				self.position = self.position + #chunk

				return data .. chunk
			else
				data = data .. self.buffer
			end
		end

		local chunk = self.proxy.read(self.stream, BUFFER_SIZE)
		if chunk then
			self.buffer = chunk
			self.position = self.position + #chunk
		-- EOF
		else
			local data = self.buffer
			self.position = self:seek("end", 0)

			return #data > 0 and data or nil
		end
	end
end

local function lines(self)
	return function()
		local line = readLine(self)
		if line then
			return line
		else
			self:close()
		end
	end
end

local function readAll(self)
	local data, chunk = "", nil
	while true do
		chunk = self.proxy.read(self.stream, 4096)
		if chunk then
			data = data .. chunk
		-- EOF
		else
			self.position = self:seek("end", 0)
			return data
		end
	end
end

local function readBytes(self, count, littleEndian)
	if count == 1 then
		local data = readString(self, 1)
		if data then
			return string.byte(data)
		end

		return nil
	else
		local bytes, result = {string.byte(readString(self, count) or "\x00", 1, 8)}, 0

		if littleEndian then
			for i = #bytes, 1, -1 do
				result = bit32.bor(bit32.lshift(result, 8), bytes[i])
			end
		else
			for i = 1, #bytes do
				result = bit32.bor(bit32.lshift(result, 8), bytes[i])
			end
		end

		return result
	end
end

local function readUnicodeChar(self)
	local byteArray = {string.byte(readString(self, 1))}

	local nullBitPosition = 0
	for i = 1, 7 do
		if bit32.band(bit32.rshift(byteArray[1], 8 - i), 0x1) == 0x0 then
			nullBitPosition = i
			break
		end
	end

	for i = 1, nullBitPosition - 2 do
		table.insert(byteArray, string.byte(readString(self, 1)))
	end

	return string.char(table.unpack(byteArray))
end

local function read(self, format, ...)
	local formatType = type(format)
	if formatType == "number" then	
		return readString(self, format)
	elseif formatType == "string" then
		format = format:gsub("^%*", "")

		if format == "a" then
			return readAll(self)
		elseif format == "l" then
			return readLine(self)
		elseif format == "b" then
			return readBytes(self, 1)
		elseif format == "bs" then
			return readBytes(self, ...)
		elseif format == "u" then
			return readUnicodeChar(self)
		else
			error("bad argument #2 ('a' (whole file), 'l' (line), 'u' (unicode char), 'b' (byte as number) or 'bs' (sequence of n bytes as number) expected, got " .. format .. ")")
		end
	else
		error("bad argument #1 (number or string expected, got " .. formatType ..")")
	end
end

local function seek(self, pizda, cyka)
	if pizda == "set" then
		local result, reason = self.proxy.seek(self.stream, "set", cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	elseif pizda == "cur" then
		local result, reason = self.proxy.seek(self.stream, "set", self.position + cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	elseif pizda == "end" then
		local result, reason = self.proxy.seek(self.stream, "end", cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	else
		error("bad argument #2 ('set', 'cur' or 'end' expected, got " .. tostring(pizda) .. ")")
	end
end

local function write(self, ...)
	local data = {...}
	for i = 1, #data do
		data[i] = tostring(data[i])
	end
	data = table.concat(data)

	-- Data is small enough to fit buffer
	if #data < (BUFFER_SIZE - #self.buffer) then
		self.buffer = self.buffer .. data

		return true
	else
		-- Write current buffer content
		local success, reason = self.proxy.write(self.stream, self.buffer)
		if success then
			-- If data will not fit buffer, use iterative writing with data partitioning 
			if #data > BUFFER_SIZE then
				for i = 1, #data, BUFFER_SIZE do
					success, reason = self.proxy.write(self.stream, data:sub(i, i + BUFFER_SIZE - 1))
					
					if not success then
						break
					end
				end

				self.buffer = ""

				return success, reason
			-- Data will perfectly fit in empty buffer
			else
				self.buffer = data

				return true
			end
		else
			return false, reason
		end
	end
end

local function writeBytes(self, ...)
	return write(self, string.char(...))
end

local function close(self)
	if self.write and #self.buffer > 0 then
		self.proxy.write(self.stream, self.buffer)
	end

	return self.proxy.close(self.stream)
end

function filesystem.open(path, mode)
	local proxy, proxyPath = filesystem.get(path)
	proxyPath = unicode.sub(path, proxyPath:len() + 1, -1)
	local result, reason = proxy.open(proxyPath, mode)
	if result then
		local handle = {
			proxy = proxy,
			stream = result,
			position = 0,
			buffer = "",
			close = close,
			seek = seek,
		}

		if mode == "r" or mode == "rb" then
			handle.readString = readString
			handle.readUnicodeChar = readUnicodeChar
			handle.readBytes = readBytes
			handle.readLine = readLine
			handle.lines = lines
			handle.readAll = readAll
			handle.read = read

			return handle
		elseif mode == "w" or mode == "wb" or mode == "a" or mode == "ab" then
			handle.write = write
			handle.writeBytes = writeBytes

			return handle
		else
			error("bad argument #2 ('r', 'rb', 'w', 'wb' or 'a' expected, got )" .. tostring(mode) .. ")")
		end
	else
		return nil, reason
	end
end

function filesystem.read(path)
	local handle, reason = filesystem.open(path, "rb")
	if handle then
		local data = readAll(handle)
		handle:close()

		return data
	end

	return false, reason
end

local function writeOrAppend(append, path, ...)
	filesystem.makeDirectory(filesystem.path(path))
	
	local handle, reason = filesystem.open(path, append and "ab" or "wb")
	if handle then
		local result, reason = write(handle, ...)
		handle:close()

		return result, reason
	end

	return false, reason
end

function filesystem.write(path, ...)
	return writeOrAppend(false, path,...)
end

function filesystem.writeTable(path, ...)
	return filesystem.write(path, require("mineOS.Text").serialize(...))
end

function filesystem.readTable(path)
	local result, reason = filesystem.read(path)
	if result then
		return require("mineOS.Text").deserialize(result)
	end

	return result, reason
end

return filesystem