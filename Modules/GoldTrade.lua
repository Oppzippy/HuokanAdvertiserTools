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
			self:LogTrade(self.targetName, diff)
		end
	end
end

function module:LogTrade(targetName, money)
	local tradeInfo = {
		gold = money / COPPER_PER_GOLD,
		buyer = targetName,
		sellerCharacter = self:GetNameAndRealm("player"),
		buyerCharacter = targetName,
		time = date("!%Y-%m-%dT%TZ"), -- ISO 8601
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
