local _, addon = ...

local AceGUI = LibStub("AceGUI-3.0")

local Core, L = addon.Core, addon.L
local module = Core:NewModule("GoldTracker", addon.ModulePrototype, "AceEvent-3.0")

module.options = {
	name = L.gold_tracker,
	type = "group",
	args = {
		open = module:CreateOpenButtonOptionTable(1),
		includeGuildBanksIfGuildLeader = {
			name = L.include_guild_banks_if_guild_leader,
			type = "toggle",
			order = 2,
		},
	},
}

StaticPopupDialogs["HUOKANADVERTISERTOOLS_GOLDTRACKER_CONFIRMDELETE"] = {
	text = L.confirm_delete_character_from_gold_tracker,
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		module:ConfirmDeleteCharacter()
	end,
	OnCancel = function()
		module:CancelDeleteCharacter()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function module:OnInitialize()
	self.frames = {}

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_MONEY", "UpdateMoney")
	self:RegisterEvent("GUILDBANKFRAME_OPENED", "UpdateGuildBankMoney")
	self:RegisterEvent("GUILDBANK_UPDATE_MONEY", "UpdateGuildBankMoney")
	self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateGuild")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
end

function module:PLAYER_ENTERING_WORLD()
	self:UpdateMoney()
	self:UpdateFaction()
end

function module:UpdateFaction()
	local faction = UnitFactionGroup("player")
	self:SetCharacterValue("faction", faction)
end

function module:UpdateMoney()
	self:SetCharacterValue("money", GetMoney())
	if self:IsVisible() then
		self:Show()
	end
end

function module:UpdateGuildBankMoney()
	self:SetGuildValue("money", GetGuildBankMoney())
	if self:IsVisible() and self:GetProfileDB().includeGuildBanksIfGuildLeader then
		self:Show()
	end
end

function module:UpdateGuild()
	local guild = self:GuildNameAndRealm("player")
	self:SetCharacterValue("guild", guild)
	if guild then
		self.guildLeaderUpdateQueued = true
	end
end

function module:GUILD_ROSTER_UPDATE()
	if self.guildLeaderUpdateQueued then
		self.guildLeaderUpdateQueued = nil
		for i = 1, GetNumGuildMembers() do
			local name, _, rankIndex = GetGuildRosterInfo(i)
			if rankIndex == 0 then
				self:SetGuildValue("guildLeader", name)
				return
			end
		end
	end
end

function module:SetCharacterValue(key, value)
	local globalDB = self:GetGlobalDB()
	local playerName = self:UnitNameAndRealm("player")
	local entry = globalDB.characters[playerName]
	if entry then
		entry[key] = value
	else
		globalDB.characters[playerName] = {
			[key] = value,
		}
	end
end

function module:SetGuildValue(key, value)
	local globalDB = self:GetGlobalDB()
	local guildName = self:GuildNameAndRealm("player")
	local entry = globalDB.guilds[guildName]
	if entry then
		entry[key] = value
	else
		globalDB.guilds[guildName] = {
			[key] = value,
		}
	end
end

local function splitRealm(character)
	return strsplit("-", character, 2)
end

function module:Show()
	if self:IsVisible() then
		self:Hide()
	end
	local db = self:GetProfileDB()
	local window = AceGUI:Create("Window")
	window:SetStatusTable(db.uiStatus)
	window:SetCallback("OnClose", function()
		self:Hide()
	end)
	window:SetTitle(L.gold_tracker)
	window:SetLayout("Fill")
	self.frames.window = window
	local scrollFrame = self:CreateScrollFrame()
	local totalLabel = self:CreateTotalLabel()
	local moneyListing = self:CreateMoneyListingsByRealm()
	scrollFrame:AddChild(totalLabel)
	scrollFrame:AddChild(moneyListing)
	window:AddChild(scrollFrame)
end

function module:CreateScrollFrame()
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetFullWidth(true)
	scrollFrame:SetFullHeight(true)
	scrollFrame:SetLayout("Flow")
	return scrollFrame
end

function module:CreateTotalLabel()
	local globalDB = self:GetGlobalDB()
	local totalLabel = AceGUI:Create("Label")
	totalLabel:SetFullWidth(true)
	local total = 0
	for character, _ in next, globalDB.characters do
		total = total + self:GetCharacterMoney(character)
	end
	totalLabel:SetText(L.total_amount:format(GetCoinTextureString(total)))
	return totalLabel
end

function module:CreateMoneyListingsByRealm()
	local container = AceGUI:Create("SimpleGroup")
	container:SetFullWidth(true)
	container:SetLayout("Flow")
	local keys = self:SortedCharacterKeys()
	local prevRealm, realmGroup
	for _, key in ipairs(keys) do
		local _, realm = splitRealm(key)
		if realm ~= prevRealm then
			prevRealm = realm
			if realmGroup then
				container:AddChild(realmGroup)
			end
			realmGroup = self:CreateRealmGroup(realm)
		end
		local moneyLabel = self:CreateMoneyListing(key)
		local deleteButton = self:CreateDeleteButton(key)
		moneyLabel:SetRelativeWidth(0.85)
		deleteButton:SetRelativeWidth(0.14)
		realmGroup:AddChild(moneyLabel)
		realmGroup:AddChild(deleteButton)
	end
	if realmGroup then
		container:AddChild(realmGroup)
	end
	return container
end

function module:CreateRealmGroup(realm)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("Flow")
	group:SetTitle(realm)
	group:SetFullWidth(true)
	return group
end

function module:CreateMoneyListing(character)
	local moneyLabel = AceGUI:Create("Label")
	local money = self:GetCharacterMoney(character)
	moneyLabel:SetText(character .. ": " .. GetCoinTextureString(money))
	return moneyLabel
end

function module:GetCharacterMoney(character)
	local globalDB = self:GetGlobalDB()
	local profileDB = self:GetProfileDB()
	local characterInfo = globalDB.characters[character]
	local money = characterInfo.money
	if profileDB.includeGuildBanksIfGuildLeader and characterInfo.guild then
		local guild = globalDB.guilds[characterInfo.guild]
		if guild and guild.guildLeader == character and guild.money then
			money = money + guild.money
		end
	end
	return money
end

function module:CreateDeleteButton(character)
	local button = AceGUI:Create("Button")
	button:SetText("X")
	button:SetCallback("OnClick", function()
		self.deleteCharacter = character
		StaticPopup_Show("HUOKANADVERTISERTOOLS_GOLDTRACKER_CONFIRMDELETE", character)
	end)
	return button
end

function module:ConfirmDeleteCharacter()
	local globalDB = self:GetGlobalDB()
	globalDB.characters[self.deleteCharacter] = nil
	self:Show()
end

function module:CancelDeleteCharacter()
	self.deleteCharacter = nil
end

function module:IsVisible()
	return self.frames.window ~= nil
end

function module:Hide()
	if self.frames.window then
		local profileDB = self:GetProfileDB()
		local statusTable = profileDB.uiStatus
		-- AceGUI's Window doesn't set the status' width and height properties on resize,
		-- only on move. If the user moves the window before closing it, everything works fine,
		-- but if the user resizes the window and then closes it, the size data would be lost.
		if statusTable then
			statusTable.width = self.frames.window.frame:GetWidth()
			statusTable.height = self.frames.window.frame:GetHeight()
		end
		self.frames.window:Release()
		self.frames = {}
	end
end

function module:SortedCharacterKeys()
	local globalDB = self:GetGlobalDB()
	local characters = {}
	for character, _ in next, globalDB.characters do
		characters[#characters+1] = character
	end
	table.sort(characters, function(a, b)
		local nameA, realmA = splitRealm(a)
		local nameB, realmB = splitRealm(b)
		if realmA == realmB then
			return nameA < nameB
		end
		return realmA < realmB
	end)
	return characters
end
