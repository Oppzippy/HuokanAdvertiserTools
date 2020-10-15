local _, addon = ...

local Core = addon.Core
local L = addon.L

local module = Core:NewModule("Payment", addon.ModulePrototype, "AceConsole-3.0", "AceEvent-3.0")

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

module.paymentData = {}

function module:OnInitialize()
	self.suggestRecipient = addon.SuggestedInputWidget.Create(SendMailNameEditBox)
	self.suggestSubject = addon.SuggestedInputWidget.Create(SendMailSubjectEditBox)
	self.suggestRecipient:SetText("test")
	self.suggestSubject:SetText(string.format("%s Huokan Community Sale Gold", self:GetDiscordTag()))

	self.suggestRecipient.RegisterCallback(self, "VALIDITY_CHANGE")
	self.suggestSubject.RegisterCallback(self, "VALIDITY_CHANGE")
	self:VALIDITY_CHANGE()
end

function module:VALIDITY_CHANGE()
	if self.suggestRecipient:IsValid() and self.suggestSubject:IsValid() then
		SendMailMailButton:Show()
	else
		SendMailMailButton:Hide()
	end
end

function module:OnValidRecipient()
	self.isRecipientValid = true
end

function module:OnValidSubject()
	self.isSubjectValid = true
end

function module:OnInvalidRecipient()
	self.isRecipientValid = false
end

function module:OnInvalidSubject()
	self.isSubjectValid = false
end

function module:GetDiscordTag()
	return self.paymentData.discordTag or module:GetDB().discordTag
end
