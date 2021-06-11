local _, addon = ...
local AceGUI = LibStub("AceGUI-3.0")

local Core, L = addon.Core, addon.L
local module = Core:NewModule("GuildBank", addon.ModulePrototype, "AceEvent-3.0", "AceConsole-3.0")

local GOLD_CAP = 99999999999

module.options = {
	name = L.guild_bank,
	type = "group",
	args = {
		autoShow = {
			name = L.auto_show,
			type = "toggle",
			order = 1,
		},
		autoHide = {
			name = L.auto_hide,
			type = "toggle",
			order = 2,
		},
		lockedSize = {
			name = L.locked_size,
			desc = L.locked_size_desc,
			type = "toggle",
			order = 3,
			set = function(_, lockedSize)
				local db = module:GetProfileDB()
				db.lockedSize = lockedSize
				if module.frames.window then
					module.frames.window:EnableResize(not lockedSize)
				end
			end,
		},
	},
}

function module:OnInitialize()
	self.frames = {}

	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY")
	self:RegisterEvent("PLAYER_MONEY")

	hooksecurefunc("DepositGuildBankMoney", function(copper)
		if GetMoney() >= copper and GetGuildBankMoney() + copper <= GOLD_CAP then
			self.prevMoney = GetMoney()
			self.deposit = {
				time = GetTime(),
				copper = copper,
			}
		end
	end)
end

function module:IsInCommunityGuild()
	local guildName = GetGuildInfo("player")
	return guildName and guildName:find("Huokan") ~= nil
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

-- GUILDBANK_UPDATE_WITHDRAWMONEY and PLAYER_MONEY may be called in any order,
-- so handle both orders properly. Verify on both ends that everything checks out.
function module:GUILDBANK_UPDATE_WITHDRAWMONEY()
	if self.deposit then
		if not self.deposit.verified then
			self.deposit.verified = true
		else
			self:ProcessDeposit()
		end
	end
end

function module:PLAYER_MONEY()
	if not self.deposit then return end

	if not self.deposit.verified then
		if self.prevMoney - self.deposit.copper == GetMoney() then
			self.deposit.verified = true
		end
	else
		self:ProcessDeposit()
	end
end

do
	local function getCharacterNameAndRealm()
		local name = UnitName("player")
		local realm = GetRealmName()
		return name .. "-" .. realm
	end

	local function getGuildNameAndRealm()
		local guildName, _, _, guildRealm = GetGuildInfo("player")
		if not guildRealm then
			guildRealm = GetRealmName()
		end
		return guildName .. "-" .. guildRealm
	end

	function module:ProcessDeposit()
		if not self:IsInCommunityGuild() then return end
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

		local character = getCharacterNameAndRealm()
		local guild = getGuildNameAndRealm()
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
	if self.frames.window then
		self:Hide()
	end

	local window = AceGUI:Create("Window")
	self.frames.window = window
	window:SetCallback("OnClose", function()
		self:Hide()
	end)
	local db = self:GetProfileDB()

	self:ForceWindowToScreenBounds()

	-- It accepts the reference so the db will be updated directly on status changes
	window:SetStatusTable(db.uiStatus)
	window:EnableResize(not db.lockedSize)

	window:SetLayout("flow")
	window:SetTitle(L.huokan_bank_deposits_for_user:format(addon.discordTag or "Unknown"))

	self.frames.scrollContainer, self.frames.scrollFrame = self:CreateScrollFrame()
	self:RenderDeposits()

	window:AddChild(self.frames.scrollContainer)
end

function module:ForceWindowToScreenBounds()
	local db = self:GetProfileDB()
	local maxWidth = UIParent:GetWidth()
	local maxHeight = UIParent:GetHeight()

	-- wider than screen
	if db.uiStatus.width > maxWidth then
		db.uiStatus.width = maxWidth
	end
	-- taller than screen
	if db.uiStatus.height > maxHeight then
		db.uiStatus.height = maxHeight
	end
	if db.uiStatus.left and db.uiStatus.top then
		-- left of screen
		if db.uiStatus.left < 0 then
			db.uiStatus.left = 0
		end
		-- right of screen
		if db.uiStatus.left > maxWidth - db.uiStatus.width  then
			db.uiStatus.left = maxWidth - db.uiStatus.width
		end
		-- bottom of screen
		if db.uiStatus.top < db.uiStatus.height then
			db.uiStatus.top = db.uiStatus.height
		end
		-- top of screen
		if db.uiStatus.top > maxHeight then
			db.uiStatus.top = maxHeight
		end
	end
end

function module:Hide()
	if self.frames.window then
		local db = self:GetProfileDB()
		-- AceGUI's Window doesn't set the status' width and height properties on resize,
		-- only on move. If the user moves the window before closing it, everything works fine,
		-- but if the user resizes the window and then closes it, the size data would be lost.
		db.uiStatus.width = self.frames.window.frame:GetWidth()
		db.uiStatus.height = self.frames.window.frame:GetHeight()

		self.frames.window:Release()
		self.frames = {}
	end
end

function module:IsVisible()
	return self.frames.window ~= nil
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
	end
end

function module:CreateScrollFrame()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	return scrollContainer, scrollFrame
end

function module:RenderDeposits()
	if not self.frames.window then return end

	local globalDB = self:GetGlobalDB()
	-- Don't re-run layout every time a widget is added during the loop
	self.frames.scrollFrame:PauseLayout()
	self.frames.scrollFrame:ReleaseChildren()
	local numDeposits = #globalDB.deposits
	for i = numDeposits, 1, -1 do
		local deposit = globalDB.deposits[i]
		local frame = self:RenderDeposit(deposit)
		frame:SetFullWidth(true)

		if i == numDeposits then
			frame:AddChild(self:RenderNote(deposit))
		elseif deposit.note and deposit.note ~= "" then
			frame:AddChild(self:RenderUnmodifiableNote(deposit))
		end

		self.frames.scrollFrame:AddChild(frame)
	end
	self.frames.scrollFrame:ResumeLayout()
	self.frames.scrollFrame:DoLayout()
end

function module:RenderDeposit(deposit)
	local container = AceGUI:Create("InlineGroup")
	-- TODO convert to eastern time
	container:SetTitle(date("!%Y-%m-%d %I:%M%p UTC", deposit.timestamp))
	container:SetLayout("Flow")

	local label = AceGUI:Create("Label")
	label:SetFullWidth(true)
	label:SetText(L.guild_bank_deposit:format(
		GetCoinTextureString(deposit.copper),
		deposit.guild,
		deposit.character
	))
	container:AddChild(label)

	return container
end

function module:RenderNote(deposit)
	local note = AceGUI:Create("EditBox")
	note:SetLabel(L.note)
	note:SetText(deposit.note or "")
	note:SetCallback("OnEnterPressed", function(_, _, 	text)
		deposit.note = text
	end)
	note:SetFullWidth(true)
	return note
end

function module:RenderUnmodifiableNote(deposit)
	local note = AceGUI:Create("Label")
	if deposit.note then
		local noteFormat = "|cFFFFD100%s|r: %s"
		note:SetText(noteFormat:format(L.note, deposit.note) or "")
	end
	note:SetFullWidth(true)
	return note
end
