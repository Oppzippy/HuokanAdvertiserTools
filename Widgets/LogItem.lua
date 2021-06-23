local _, addon = ...

local CallbackHandler = LibStub("CallbackHandler-1.0")
local LogItemPrototype = {}

function addon:CreateLogItem(timestamp, text, note)
	local item = setmetatable({}, {
		__index = LogItemPrototype,
	})
	item.timestamp = timestamp
	item.text = text
	item.note = note
	item.callbacks = CallbackHandler:New(item)
	return item
end

function LogItemPrototype:SetNote(note)
	self.note = note
	self.callbacks:Fire("OnNoteChanged", self, note)
end
