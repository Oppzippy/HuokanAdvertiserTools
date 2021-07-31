local _, addon = ...

local L = addon.L

local AceGUI = LibStub("AceGUI-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

local LogWithNotesPrototype = {}

function addon.CreateLogWithNotes()
	local logWithNotes = setmetatable({}, {
		__index = LogWithNotesPrototype,
	})
	logWithNotes.frames = {}
	logWithNotes.items = {}
	logWithNotes.callbacks = CallbackHandler:New(logWithNotes)
	logWithNotes:Show()
	return logWithNotes
end

function LogWithNotesPrototype:AddItem(item)
	self.items[#self.items+1] = item
	if not self.isLayoutPaused then
		self:DoLayout()
	end
end

function LogWithNotesPrototype:ReleaseChildren()
	self.items = {}
	if not self.isLayoutPaused then
		self:DoLayout()
	end
end

function LogWithNotesPrototype:PauseLayout()
	self.isLayoutPaused = true
end

function LogWithNotesPrototype:ResumeLayout()
	self.isLayoutPaused = nil
end

-- It accepts the reference so the db will be updated directly on status changes
function LogWithNotesPrototype:SetStatusTable(statusTable)
	self.statusTable = statusTable
	self:ForceWindowToScreenBounds()
	self.frames.window:SetStatusTable(statusTable)
end

function LogWithNotesPrototype:EnableResize(enableResize)
	self.frames.window:EnableResize(enableResize)
end

function LogWithNotesPrototype:SetTitle(title)
	self.frames.window:SetTitle(title)
end

function LogWithNotesPrototype:Show()
	if not self.frames or self.frames.window then
		return
	end

	local window = AceGUI:Create("Window")
	self.frames.window = window
	window:SetCallback("OnClose", function()
		self:Release()
		self.callbacks:Fire("OnClose")
	end)

	self:ForceWindowToScreenBounds()

	window:SetLayout("flow")

	self.frames.scrollContainer, self.frames.scrollFrame = self:CreateScrollFrame()

	window:AddChild(self.frames.scrollContainer)
end

function LogWithNotesPrototype:ForceWindowToScreenBounds()
	if not self.statusTable then return end

	local maxWidth = UIParent:GetWidth()
	local maxHeight = UIParent:GetHeight()

	-- wider than screen
	if self.statusTable.width > maxWidth then
		self.statusTable.width = maxWidth
	end
	-- taller than screen
	if self.statusTable.height > maxHeight then
		self.statusTable.height = maxHeight
	end
	if self.statusTable.left and self.statusTable.top then
		-- left of screen
		if self.statusTable.left < 0 then
			self.statusTable.left = 0
		end
		-- right of screen
		if self.statusTable.left > maxWidth - self.statusTable.width  then
			self.statusTable.left = maxWidth - self.statusTable.width
		end
		-- bottom of screen
		if self.statusTable.top < self.statusTable.height then
			self.statusTable.top = self.statusTable.height
		end
		-- top of screen
		if self.statusTable.top > maxHeight then
			self.statusTable.top = maxHeight
		end
	end
end

function LogWithNotesPrototype:Release()
	if self.frames and self.frames.window then
		-- AceGUI's Window doesn't set the status' width and height properties on resize,
		-- only on move. If the user moves the window before closing it, everything works fine,
		-- but if the user resizes the window and then closes it, the size data would be lost.
		if self.statusTable then
			self.statusTable.width = self.frames.window.frame:GetWidth()
			self.statusTable.height = self.frames.window.frame:GetHeight()
		end

		self.frames.window:Release()
		self.frames = nil
	end
end

function LogWithNotesPrototype:IsVisible()
	return self.frames.window ~= nil
end

function LogWithNotesPrototype:CreateScrollFrame()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	return scrollContainer, scrollFrame
end

function LogWithNotesPrototype:DoLayout()
	if not self.frames.window then return end

	-- Don't re-run layout every time a widget is added during the loop
	self.frames.scrollFrame:PauseLayout()
	self.frames.scrollFrame:ReleaseChildren()
	for i, item in ipairs(self.items) do
		local frame = self:RenderLogItem(item, {
			unmodifiable = i ~= 1,
		})
		frame:SetFullWidth(true)

		self.frames.scrollFrame:AddChild(frame)
	end
	self.frames.scrollFrame:ResumeLayout()
	self.frames.scrollFrame:DoLayout()
end

function LogWithNotesPrototype:RenderLogItem(item, options)
	if options == nil then
		options = {}
	end
	local container = AceGUI:Create("InlineGroup")
	-- TODO convert to eastern time
	container:SetTitle(date("!%Y-%m-%d %I:%M%p UTC", item.timestamp))
	container:SetLayout("Flow")

	local label = AceGUI:Create("Label")
	label:SetFullWidth(true)
	label:SetText(item.text)
	container:AddChild(label)

	if not options.unmodifiable then
		container:AddChild(self:RenderNote(item))
	elseif item.note and item.note ~= "" then
		container:AddChild(self:RenderUnmodifiableNote(item))
	end

	return container
end

function LogWithNotesPrototype:RenderNote(item)
	local note = AceGUI:Create("EditBox")
	note:SetLabel(L.note)
	note:SetText(item.note or "")
	note:SetCallback("OnEnterPressed", function(_, _, text)
		item:SetNote(text)
	end)
	note:SetFullWidth(true)
	return note
end

function LogWithNotesPrototype:RenderUnmodifiableNote(item)
	local note = AceGUI:Create("Label")
	if item.note then
		local noteFormat = "|cFFFFD100%s|r: %s"
		note:SetText(noteFormat:format(L.note, item.note) or "")
	end
	note:SetFullWidth(true)
	return note
end

