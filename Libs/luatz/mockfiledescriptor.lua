local _, addon = ...

local MockFileDescriptorPrototype = {}

local NEW_LINE = "\n"

function addon.luatz.NewMockFileDescriptor(fileBytes)
	local fd = setmetatable(
		{
			fileBytes = fileBytes,
			index = 1,
		},
		{
			__index = MockFileDescriptorPrototype
		}
	)

	return fd
end

function MockFileDescriptorPrototype:read(numBytes)
	if numBytes == "*l" then
		return self:readLine()
	elseif type(numBytes) == "number" then
		return self:readNumber(numBytes)
	end
	assert(false)
end

function MockFileDescriptorPrototype:readLine()
	local chars = {}
	local length = #self.fileBytes
	for i = self.index, length do
		local byte = self.fileBytes[i]
		if byte == NEW_LINE then
			break
		else
			chars[#chars+1] = string.char(byte)
		end
	end
	self.index = self.index + #chars + 1 -- +1 for the newline character that was excluded
	return table.concat(chars, "")
end

function MockFileDescriptorPrototype:readNumber(numBytes)
	local chars = {}
	for i = 1, numBytes do
		local byte = self.fileBytes[self.index + i - 1]
		if byte ~= nil then
			chars[i] = string.char(byte)
		end
	end
	self.index = self.index + numBytes
	return table.concat(chars, "")
end

function MockFileDescriptorPrototype:close()
end
