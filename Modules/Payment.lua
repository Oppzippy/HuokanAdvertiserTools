local _, addon = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

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
			name = L.discord_tag,
			type = "input",
			pattern = "^%a+#%d+$",
			usage = L.discord_tag_usage,
		},
	},
}

module.paymentData = {}

local paymentUi = {
	name = L.payment,
	type = "group",
	set = function(info, val)
		module.paymentData[info[#info]] = val
	end,
	get = function(info)
		local key = info[#info]
		if key == "discordTag" then
			return module:GetDiscordTag()
		end
		return module.paymentData[key]
	end,
	args = {
		sendMail = {
			order = 1,
			name = L.send_gold,
			type = "group",
			inline = true,
			args = {
				discordTag = {
					order = 1,
					name = L.discord_tag,
					width = "double",
					type = "input",
					pattern = "^%a+#%d+$",
					usage = L.discord_tag_usage,
				},
				gold = {
					order = 2,
					name = L.gold,
					type = "input",
					validate = function(_, text)
						local gold = tonumber(text)
						return gold and gold > 0
					end,
					usage = L.gold_input_usage,
				},
				goldDisplay = {
					order = 3,
					type = "description",
					width = "normal",
					name = function()
						local copper = module:GetCopper()
						return copper and GetCoinTextureString(copper) or ""
					end,
				},
				send = {
					order = 3,
					name = L.send,
					width = "double",
					type = "execute",
					func = function() module:SendPayment() end,
					disabled = function()
						return not module:CanSend()
					end,
				},
			},
		},
		verification = {
			order = 2,
			name = L.verification,
			type = "group",
			inline = true,
			args = {
				verificationText = {
					type = "description",
					fontSize = "medium",
					name = "",
				},
			},
		},
	},
}

function module:OnInitialize()
	AceConfig:RegisterOptionsTable("HuokanAdvertiserTools_Payment", paymentUi)
	AceConfigDialog:SetDefaultSize("HuokanAdvertiserTools_Payment", 400, 400)
	self:RegisterEvent("MAIL_SHOW")
end

function module:MAIL_SHOW()
	if self:GetDB().autoShow then
		self:Show()
	end
end

function module:Show()
	if self.frame then return end
	local frame = AceGUI:Create("Frame")
	self.frame = frame
	frame:SetTitle(L.payment)
	frame:EnableResize(false)
	frame:SetCallback("OnClose", function()
		self:Hide()
	end)
	AceConfigDialog:Open("HuokanAdvertiserTools_Payment", frame)
end

function module:Hide()
	if self.frame then
		self.frame:Release()
		self.frame = nil
	end
end

function module:IsVisible()
	return self.frame ~= nil
end

function module:SendPayment()
	local realm = GetRealmName()
	local recipient = addon.huokanMailRecipients[realm]
	if recipient then
		if self:CanSend() then
			local copper = self:GetCopper()
			SetSendMailMoney(copper)
			SendMail(recipient, string.format("HuokanAdvertiserPayment %s", self:GetDiscordTag()))
			self.paymentData.gold = nil
			self.copper = copper
			self.recipient = recipient
			self:RegisterEvent("MAIL_SEND_SUCCESS")
			self:RegisterEvent("MAIL_FAILED")
		else
			self:Print("Unable to send mail")
		end
	else
		self:Printf(L.not_available_on_realm, realm)
	end
end

function module:MAIL_SEND_SUCCESS()
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
	local dateString = date("%Y-%m-%d %I:%M:%S %p")
	local verificationText = string.format(L.verification_text, GetCoinTextureString(self.copper), self.recipient, dateString)
	paymentUi.args.verification.args.verificationText.name = verificationText
	if self.frame then
		AceConfigDialog:Open("HuokanAdvertiserTools_Payment", self.frame)
	end
end

function module:MAIL_FAILED()
	self:UnregisterEvent("MAIL_SEND_SUCCESS")
	self:UnregisterEvent("MAIL_FAILED")
	self:Print(L.mail_failed)
end

function module:CanSend()
	return self:GetDiscordTag() and self:GetCopper() and GetMoney() >= self:GetCopper() + GetSendMailPrice()
end

function module:GetCopper()
	local gold = tonumber(self.paymentData.gold)
	if gold and gold > 0 then
		return gold * COPPER_PER_GOLD
	end
end

function module:GetDiscordTag()
	return self.paymentData.discordTag or module:GetDB().discordTag
end
