local _, addon = ...

local LibCopyPaste = LibStub("LibCopyPaste-1.0")

local Core = addon.Core
local L = addon.L

local module = Core:NewModule("GoldTrade", addon.ModulePrototype, "AceConsole-3.0", "AceEvent-3.0")
module.encryptionKey = {1735411286, 1370423342, 719978063, 3842767669}

module.options = {
	name = L.gold_trade,
	type = "group",
	args = {
		noOptions = {
			type = "description",
			name = L.no_options,
		},
	},
}

function module:OnInitialize()
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("TRADE_SHOW")
	self:RegisterEvent("TRADE_ACCEPT_UPDATE", "TRADE_SHOW")
	self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
	self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED", "UpdateAcceptTradeButton")

	self.tradePurposeEditBox = self:CreateTradePurposeEditBox()
end

function module:TRADE_SHOW()
	self.lastKnownTradeTarget = self:GetNameAndRealm("NPC")
end

function module:PLAYER_TRADE_MONEY()
	self:RegisterEvent("PLAYER_MONEY")
	self.trade = {
		prevMoney = GetMoney(),
		time = GetTime(),
		targetName = self.lastKnownTradeTarget,
	}
end

function module:PLAYER_MONEY()
	self:UnregisterEvent("PLAYER_MONEY")
	local trade = self.trade
	self.trade = nil
	if GetTime() - trade.time < 15 then -- Ignore previous trade if something went wrong such as being gold capped
		local diff = GetMoney() - trade.prevMoney
		if diff ~= 0 then
			local purpose = self.tradePurposeEditBox:GetText()
			self:LogTrade(self.targetName, diff, purpose)
			self.tradePurposeEditBox:SetText("")
		end
	end
end

function module:LogTrade(targetName, money, purpose)
	local tradeInfo = {
		gold = money / COPPER_PER_GOLD,
		buyer = targetName,
		sellerCharacter = self:GetNameAndRealm("player"),
		buyerCharacter = targetName,
		time = date("!%Y-%m-%dT%TZ"), -- ISO 8601
		purpose = purpose,
	}
	local message = addon.json.encode(tradeInfo)
	local encrypted = addon.TEA.encrypt(message, self.encryptionKey)
	local encoded = addon.base64.encode(encrypted)
	LibCopyPaste:Copy(L.addon_name, encoded)
end

function module:GetNameAndRealm(unit)
	local name, realm = UnitName(unit)
	if not realm or realm == "" then
		realm = GetNormalizedRealmName()
	end
	local fullName = string.format("%s-%s", name, realm)
	return fullName
end

function module:TRADE_PLAYER_ITEM_CHANGED()
	self:UpdateAcceptTradeButton()
	C_Timer.After(0, function()
		for i = 1, 7 do
			local button = _G[string.format("TradePlayerItem%dItemButton", i)]
			button:Click("RightButton")
		end
	end)
end

function module:CreateTradePurposeEditBox()
	local frame = CreateFrame("Frame", nil, TradeFrame)
	frame:SetPoint("TOPLEFT", TradeFrame, "BOTTOMLEFT")
	frame:SetPoint("TOPRIGHT", TradeFrame, "BOTTOMRIGHT")
	frame:SetBackdrop({
		bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
		tile = true,
	})
	frame:SetSize(TradeFrame:GetWidth(), 100)
	frame:Show()
	frame:EnableMouse(true)
	frame:EnableKeyboard(true)

	local title = frame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
	title:SetPoint("TOP", frame, "TOP")
	title:SetText(L.enter_trade_description)
	title:Show()

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOP", frame, "TOP", 0, -20)
	scrollFrame:SetPoint("LEFT", frame, "LEFT")
	scrollFrame:SetPoint("RIGHT", frame, "RIGHT")
	scrollFrame:SetPoint("BOTTOM", frame, "BOTTOM")
	scrollFrame:Show()

	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetSize(TradeFrame:GetWidth(), 100)
	editBox:SetFont(ChatFontNormal:GetFont())
	editBox:SetAutoFocus(false)
	editBox:SetMultiLine(true)
	editBox:Show()
	editBox:SetScript("OnEscapePressed", function()
		editBox:ClearFocus()
	end)
	frame:SetScript("OnMouseDown", function()
		editBox:SetFocus()
	end)

	editBox:SetScript("OnTextChanged", function()
		self:UpdateAcceptTradeButton()
	end)

	scrollFrame:SetScrollChild(editBox)

	return editBox
end

function module:UpdateAcceptTradeButton()
	if self.tradePurposeEditBox:GetText() == "" or self:AreItemsInTrade() then
		TradeFrameTradeButton:Hide()
	else
		TradeFrameTradeButton:Show()
	end
end

function module:AreItemsInTrade()
	for i = 1, 7 do
		if GetTradePlayerItemInfo(i) or GetTradeTargetItemInfo(i) then
			return true
		end
	end
	return false
end
