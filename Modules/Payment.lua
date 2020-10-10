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
end

function module:GetDiscordTag()
	return self.paymentData.discordTag or module:GetDB().discordTag
end
