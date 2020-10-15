local _, addon = ...
local SuggestedInputWidget = {}
addon.SuggestedInputWidget = SuggestedInputWidget

function SuggestedInputWidget.Create(targetWidget)
	local self = setmetatable({}, { __index = SuggestedInputWidget })
	self.targetWidget = targetWidget
	self:CreateDisplay(targetWidget)
	return self
end

function SuggestedInputWidget:SetText(text)
	self.text = text
	self:UpdateDisplay()
end

function SuggestedInputWidget:UpdateDisplay()
	local text = self:GetDisplayText()
	self.fontString:SetText(text)
	self.frame:SetWidth(self.fontString:GetStringWidth() + 8)
end

do
	local deleteColor = "|cFFCC0000"
	local badColor = "|cFFFF7766"
	local goodColor = "|r"
	local pendingColor = "|cFFAAAAAA"

	local function getColor(expected, actual)
		if #actual == 1 then
			if #expected == 1 then
				return expected == actual and goodColor or badColor
			end
			return deleteColor
		end
		return #expected == 1 and pendingColor or badColor
	end

	local conversion = {
		[" "] = "_",
	}

	function SuggestedInputWidget:GetDisplayText()
		if not self.text then return "" end
		local displayText = {}
		local expectedText = self.text
		local actualText = self.targetWidget:GetText()
		local prevColor
		for i = 1, math.max(#expectedText, #actualText) do
			local expectedChar = expectedText:sub(i, i)
			local actualChar = actualText:sub(i, i)
			local color = getColor(expectedChar, actualChar)
			if color ~= prevColor then
				displayText[#displayText+1] = color
				prevColor = color
			end
			local displayChar = #expectedChar == 1 and expectedChar or actualChar
			if actualChar ~= expectedChar and #actualChar == 1 and conversion[expectedChar] then
				displayChar = conversion[expectedChar]
			end
			displayText[#displayText+1] = displayChar
		end
		return table.concat(displayText)
	end
end

function SuggestedInputWidget:CreateDisplay(target)
	local frame = CreateFrame("Frame", nil, target, "BackdropTemplate")
	self.frame = frame
	frame:SetFrameStrata("HIGH")
	frame:SetPoint("TOPLEFT", target, "BOTTOMLEFT")
	frame:SetSize(target:GetSize())
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 8,
	})
	frame:Hide()

	local fs = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	self.fontString = fs
	fs:SetPoint("LEFT", frame, "LEFT", 5, 0)

	target:HookScript("OnTextChanged", function()
		self:UpdateDisplay()
	end)

	target:HookScript("OnEditFocusGained", function()
		frame:Show()
	end)

	target:HookScript("OnEditFocusLost", function()
		frame:Hide()
	end)
end
