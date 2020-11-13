local _, addon = ...

local L = addon.L

local LibCopyPaste = LibStub("LibCopyPaste-1.0")
local LibDeflate = LibStub("LibDeflate")
local JSON = LibStub("json.lua")
local Base64 = LibStub("base64")

local Core = addon.Core

local module = Core:NewModule("GuildDeposit", addon.ModulePrototype, "AceEvent-3.0")

local HISTORY_SIZE = 3

function module:OnInitialize()
	self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY")
	self:RegisterEvent("GUILDBANKLOG_UPDATE")
end

function module:GUILDBANK_UPDATE_WITHDRAWMONEY()
	QueryGuildBankLog(MAX_GUILDBANK_TABS+1)
	self.isDepositQueued = true
end

function module:GUILDBANKLOG_UPDATE()
	if self.isDepositQueued then
		self.isDepositQueued = false
		local numTransactions = GetNumGuildBankMoneyTransactions()
		if numTransactions > 0 then
			local transactionType, unitName = GetGuildBankMoneyTransaction(numTransactions)
			if transactionType == "deposit" and unitName == UnitName("player") then
				self:LogTransaction(numTransactions)
			end
		end
	end
end

function module:LogTransaction(transationIndex)
	local previousTransactions = {}
	local i = transationIndex - 1
	while i > 0 and #previousTransactions < HISTORY_SIZE do
		previousTransactions[#previousTransactions+1] = self:GetPreviousTransaction(i)
		i = i - 1
	end

	local playerRealm = GetNormalizedRealmName()
	local guildName, _, _, guildRealm = GetGuildInfo("player")

	local transactionData = {
		latestTransaction = self:GetLatestTransaction(),
		previousTransactions = previousTransactions,
		bankGuild = {
			name = guildName,
			realm = guildRealm or playerRealm,
		},
	}
	local json = JSON.encode(transactionData)
	local compressed = LibDeflate:CompressDeflate(json)
	LibCopyPaste:Copy(L.addon_name, Base64.encode(compressed))
end

function module:GetLatestTransaction()
	local index = GetNumGuildBankMoneyTransactions()
	local transaction = self:GetPreviousTransaction(index)
	if transaction then
		transaction.timestamp = date("!%Y-%m-%dT%TZ", GetServerTime()) -- ISO 8601
		return transaction
	end
end

function module:GetPreviousTransaction(index)
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
