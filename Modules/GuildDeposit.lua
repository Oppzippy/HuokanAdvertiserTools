local _, addon = ...

local L = addon.L

local LibCopyPaste = LibStub("LibCopyPaste-1.0")
local LibDeflate = LibStub("LibDeflate")
local JSON = LibStub("json.lua")
local Base64 = LibStub("base64")

local Core = addon.Core

local module = Core:NewModule("GuildDeposit", addon.ModulePrototype, "AceEvent-3.0")

local HISTORY_SIZE = 20

function module:OnInitialize()
	self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY")
	self:RegisterEvent("GUILDBANKLOG_UPDATE")

	hooksecurefunc("DepositGuildBankMoney", function(copper)
		self.expectedDeposit = {
			time = GetTime(),
			copper = copper,
		}
	end)
end

function module:GUILDBANK_UPDATE_WITHDRAWMONEY()
	QueryGuildBankLog(MAX_GUILDBANK_TABS+1)
	self.isDepositQueued = true
end

function module:GUILDBANKLOG_UPDATE()
	if self.expectedDeposit and GetTime() - self.expectedDeposit.time < 10 then
		local numTransactions = GetNumGuildBankMoneyTransactions()
		if numTransactions > 0 then
			local transactionType, unitName, money = GetGuildBankMoneyTransaction(numTransactions)
			if transactionType == "deposit" then
				if unitName == UnitName("player") and money == self.expectedDeposit.copper then
					self:LogDeposit(numTransactions)
					self.expectedDeposit = nil
				end
			end
		end
	end
end

function module:LogDeposit(transactionIndex)
	local previousDeposits = {}
	local i = transactionIndex - 1
	while i > 0 and #previousDeposits < HISTORY_SIZE do
		previousDeposits[#previousDeposits+1] = self:GetPreviousDeposit(i)
		i = i - 1
	end

	local playerRealm = GetNormalizedRealmName()
	local guildName, _, _, guildRealm = GetGuildInfo("player")

	local depositData = {
		latestDeposit = self:GetLatestDeposit(),
		previousDeposits = previousDeposits,
		bankGuild = {
			name = guildName,
			realm = guildRealm or playerRealm,
		},
	}
	local json = JSON.encode(depositData)
	local compressed = LibDeflate:CompressDeflate(json)
	LibCopyPaste:Copy(L.addon_name, Base64.encode(compressed))
end

function module:GetLatestDeposit()
	local index = GetNumGuildBankMoneyTransactions()
	local deposit = self:GetPreviousDeposit(index)
	if deposit then
		deposit.timestamp = date("!%Y-%m-%dT%TZ", GetServerTime()) -- ISO 8601
		return deposit
	end
end

function module:GetPreviousDeposit(index)
	if index < 1 and index > GetNumGuildBankMoneyTransactions() then return end

	local transactionType, unitNameAndRealm, copper = GetGuildBankMoneyTransaction(index)
	if transactionType == "deposit" then
		local unitName, unitRealm = strsplit("-", unitNameAndRealm, 2)

		local playerRealm = GetNormalizedRealmName()
		return {
			player = {
				name = unitName,
				realm = unitRealm or playerRealm,
			},
			copper = copper,
		}
	end
end
