local _, addon = ...
local AceGUI = LibStub("AceGUI-3.0")

local Core, L = addon.Core, addon.L
local module = Core:NewModule("GuildBank", addon.ModulePrototype, "AceEvent-3.0")

local GOLD_CAP = 99999999999

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

function module:GUILDBANKFRAME_OPENED()
	self:ShowUI()
end

function module:GUILDBANKFRAME_CLOSED()
	self:HideUI()
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

function module:ShowUI()
	if self.frames.frame then
		self:HideUI()
	end

	local frame = AceGUI:Create("Window")
	self.frames.frame = frame
	frame:SetCallback("OnClose", function()
		self:HideUI()
	end)
	frame:SetWidth(400)
	frame:SetHeight(600)
	frame:EnableResize(true)
	frame:SetLayout("flow")
	frame:SetTitle(L.huokan_bank_deposits_for_user:format(addon.discordTag or "Unknown"))

	self.frames.scrollContainer, self.frames.scrollFrame = self:CreateScrollFrame()
	self:RenderDeposits()

	frame:AddChild(self.frames.scrollContainer)
end

function module:HideUI()
	if self.frames.frame then
		self.frames.frame:Release()
		self.frames = {}
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
	if not self.frames.frame then return end

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
