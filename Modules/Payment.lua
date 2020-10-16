local _, addon = ...

local Core = addon.Core
local L = addon.L

local module = Core:NewModule("Payment", addon.ModulePrototype, "AceEvent-3.0")

module.options = {
	name = L.payment,
	type = "group",
	args = {
		autoShow = {
			order = 1,
			name = L.auto_show,
			type = "toggle",
		},
		discordTag = {
			order = 2,
			name = L.discord_name,
			type = "input",
			usage = L.discord_name_usage,
		},
	},
}

StaticPopupDialogs["HUOKANADVERTISERTOOLS_INVALIDMAIL"] = {
	text = L.invalid_mail_confirm,
	button1 = YES,
	button2 = NO,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function()
		module.ignoreValidity = true
		module:UpdateValidity()
	end,
}

module.paymentData = {}

function module:OnInitialize()
	self.suggestRecipient = addon.SuggestedInputWidget.Create(SendMailNameEditBox)
	self.suggestRecipient:SetText("test")

	self.suggestSubject = addon.SuggestedInputWidget.Create(SendMailSubjectEditBox)
	self.suggestSubject:SetText(string.format("%s Huokan Community Sale Gold", self:GetDiscordTag()))

	self.suggestRecipient.RegisterCallback(self, "VALIDITY_CHANGE", "UpdateValidity")
	self.suggestSubject.RegisterCallback(self, "VALIDITY_CHANGE", "UpdateValidity")

	self.defaultSendAction = SendMailMailButton:GetScript("OnClick")
	self.ignoreValidity = false
	self:RegisterEvent("MAIL_CLOSED")

	self:UpdateValidity()
end

function module:UpdateValidity()
	if (self.suggestRecipient:IsValid() and self.suggestSubject:IsValid()) or self.ignoreValidity then
		SendMailMailButton:SetScript("OnClick", self.defaultSendAction)
	else
		SendMailMailButton:SetScript("OnClick", function()
			StaticPopup_Show("HUOKANADVERTISERTOOLS_INVALIDMAIL")
		end)
	end
end

function module:MAIL_CLOSED()
	self.ignoreValidity = false
	self:UpdateValidity()
end

function module:GetDiscordTag()
	return self.paymentData.discordTag or self:GetDB().discordTag
end
