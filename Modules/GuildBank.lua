local _, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("GuildBank", addon.ModulePrototype, "AceEvent-3.0", "AceConsole-3.0")

local GOLD_CAP = 99999999999

module.options = {
	name = L.guild_bank,
	type = "group",
	args = {
		open = module:CreateOpenButtonOptionTable(1),
		autoShow = {
			name = L.auto_show,
			type = "toggle",
			order = 2,
		},
		autoHide = {
			name = L.auto_hide,
			type = "toggle",
			order = 3,
		},
		lockedSize = {
			name = L.locked_size,
			desc = L.locked_size_desc,
			type = "toggle",
			order = 4,
			set = function(_, lockedSize)
				local db = module:GetProfileDB()
				db.lockedSize = lockedSize
				if module.logFrame then
					module.logFrame:EnableResize(not lockedSize)
				end
			end,
		},
	},
}

function module:OnInitialize()
	self.frames = {}

	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANK_UPDATE_MONEY")
	self:RegisterEvent("PLAYER_MONEY")

	hooksecurefunc("DepositGuildBankMoney", function(copper)
		copper = math.floor(copper)
		if GetMoney() < copper then
			Core:Printf("Deposit would cause negative player money. If this is an unexpected error, please open a ticket. Player money: %.0f, deposit: %.0f", GetMoney(), copper)
			return
		end
		if GetGuildBankMoney() + copper > GOLD_CAP then
			Core:Printf("Deposit would cause guild bank to gold cap. If this is an unexpected error, please open a ticket. Guild bank money: %.0f, deposit: %.0f", GetGuildBankMoney(), copper)
			return
		end
		self.prevMoney = GetMoney()
		self.deposit = {
			time = GetTime(),
			copper = copper,
			events = {},
		}
	end)
end

function module:GUILDBANKFRAME_OPENED()
	local db = self:GetProfileDB()
	if self:IsInCommunityGuild() and db.autoShow then
		self:Show()
	end
end

function module:GUILDBANKFRAME_CLOSED()
	local db = self:GetProfileDB()
	if self:IsInCommunityGuild() and db.autoHide then
		self:Hide()
	end
end

-- GUILDBANK_UPDATE_MONEY and PLAYER_MONEY may be called in any order,
-- so handle both orders properly. Verify on both ends that everything checks out.
function module:GUILDBANK_UPDATE_MONEY(event)
	if self.deposit then
		if not self.deposit.verified then
			self.deposit.verified = true
			self.deposit.events[#self.deposit.events+1] = event
		else
			self:ProcessDeposit()
		end
	end
end

function module:PLAYER_MONEY(event)
	if self.deposit then
		if not self.deposit.verified then
			if self.prevMoney - self.deposit.copper == GetMoney() then
				self.deposit.verified = true
				self.deposit.events[#self.deposit.events+1] = event
			end
		else
			self:ProcessDeposit()
		end
	end
end

do
	function module:ProcessDeposit()
		if not self:IsInCommunityGuild() then
			Core:Print(L.warning_not_in_community_guild)
			return
		end
		if not self.deposit.verified then
			Core:Print(L.failed_to_verify_deposit)
			return
		end
		if GetTime()-self.deposit.time > 5 then
			Core:Print(L.deposit_timed_out)
			return
		end
		if self.prevMoney-self.deposit.copper ~= GetMoney() then
			Core:Print(L.failed_to_verify_gold_change)
			return
		end
		local deposit = self.deposit
		self.deposit = nil

		local character = self:UnitNameAndRealm("player")
		local guild = self:GuildNameAndRealm("player")
		local globalDB = self:GetGlobalDB()
		globalDB.deposits[#globalDB.deposits+1] = {
			timestamp = GetServerTime(),
			copper = deposit.copper,
			character = character,
			guild = guild,
		}
		self:RenderDeposits()
	end
end

function module:Show()
	if self:IsVisible() then
		self:Hide()
	end
	self.logFrame = addon:CreateLogWithNotes()
	self.logFrame:RegisterCallback("OnClose", function()
		self:Hide()
	end)
	local db = self:GetProfileDB()
	self.logFrame:SetStatusTable(db.uiStatus)
	self.logFrame:EnableResize(not db.lockedSize)

	self.logFrame:SetTitle(L.huokan_bank_deposits_for_user:format(addon.discordTag or "Unknown", Core:GetVersion()))
	self:RenderDeposits()
end


function module:Hide()
	if self:IsVisible() then
		self.logFrame:Release()
		self.logFrame = nil
	end
end

function module:IsVisible()
	return self.logFrame ~= nil
end

function module:RenderDeposits()
	if not self:IsVisible() then return end
	local globalDB = self:GetGlobalDB()
	local numDeposits = #globalDB.deposits

	self.logFrame:PauseLayout()
	self.logFrame:ReleaseChildren()
	for i = numDeposits, 1, -1 do
		local deposit = globalDB.deposits[i]
		local logItem = addon:CreateLogItem(
			deposit.timestamp,
			L.guild_bank_deposit:format(
				GetCoinTextureString(deposit.copper),
				deposit.guild,
				deposit.character
			),
			deposit.note
		)
		logItem:RegisterCallback("OnNoteChanged", function(_, _, note)
			deposit.note = note
		end)
		self.logFrame:AddItem(logItem)
	end
	self.logFrame:ResumeLayout()
	self.logFrame:DoLayout()
end

function module:SlashCmd(args)
	if #args == 0 then
		if self:IsVisible() then
			self:Hide()
		else
			self:Show()
		end
	elseif args[1] == "resetui" then
		self:Hide()
		local db = self:GetProfileDB()
		db.uiStatus = {
			width = addon.dbDefaults.profile.GuildBank.uiStatus.width,
			height = addon.dbDefaults.profile.GuildBank.uiStatus.height,
		}
		self:Show()
	elseif args[1] == "printdeposit" then
		DevTools_Dump(self.deposit)
	end
end
