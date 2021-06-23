local _, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("Trade", addon.ModulePrototype, "AceEvent-3.0", "AceConsole-3.0")

module.options = {
	name = L.trade,
	type = "group",
	args = {
		autoShow = {
			name = L.auto_show,
			type = "toggle",
			order = 1,
		},
		lockedSize = {
			name = L.locked_size,
			desc = L.locked_size_desc,
			type = "toggle",
			order = 3,
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
	self:RegisterEvent("TRADE_ACCEPT_UPDATE")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
end

function module:TRADE_ACCEPT_UPDATE()
	if self:IsInCommunityGuild() then
		local ourMoney = GetPlayerTradeMoney()
		local theirMoney = GetTargetTradeMoney()

		local gain = theirMoney - ourMoney
		self.tradeCopper = gain
		self.tradeTarget = self:UnitNameAndRealm("npc")
	end
end

function module:PLAYER_TRADE_MONEY()
	if self:IsInCommunityGuild() then
		if self.tradeCopper ~= nil then
			if self.tradeCopper ~= 0 then
				local globalDB = self:GetGlobalDB()
				globalDB.trades[#globalDB.trades+1] = {
					timestamp = GetServerTime(),
					copper = self.tradeCopper,
					character = self:UnitNameAndRealm("player"),
					target = self.tradeTarget,
				}
				local db = self:GetProfileDB()
				if db.autoShow and not self:IsVisible() then
					self:Show()
				end
				self:Render()
			end
			self.tradeCopper = nil
			self.tradeTarget = nil
		else
			self:Print("Trade copper was nil, tell the developers!")
		end
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

	self.logFrame:SetTitle(L.trades_for_user:format(addon.discordTag or "Unknown"))

	self:Render()
end

function module:Render()
	if not self:IsVisible() then return end
	local globalDB = self:GetGlobalDB()
	local numTrades = #globalDB.trades
	self.logFrame:PauseLayout()
	self.logFrame:ReleaseChildren()
	for i = numTrades, 1, -1 do
		local trade = globalDB.trades[i]

		local text
		if trade.copper < 0 then
			text = L.traded_money_to:format(trade.character, GetCoinTextureString(trade.copper), trade.target)
		else
			text = L.traded_money_to:format(trade.target, GetCoinTextureString(-trade.copper), trade.character)
		end

		local logItem = addon:CreateLogItem(
			trade.timestamp,
			text,
			trade.note
		)
		logItem:RegisterCallback("OnNoteChanged", function(_, _, note)
			trade.note = note
		end)
		self.logFrame:AddItem(logItem)
	end
	self.logFrame:ResumeLayout()
	self.logFrame:DoLayout()
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
