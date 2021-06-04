local _, addon = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = AceLocale:GetLocale("HuokanAdvertiserTools")
addon.L = L

local Core = AceAddon:NewAddon("HuokanAdvertiserTools", "AceConsole-3.0", "AceEvent-3.0")
addon.Core = Core

function Core:OnInitialize()
	self.isInitialized = true
	self.db = AceDB:New("HuokanAdvertiserToolsDB", addon.dbDefaults, true)
	self:UpdateOptions()
	local profileOptions = AceDBOptions:GetOptionsTable(self.db)
	AceConfig:RegisterOptionsTable("HuokanAdvertiserTools", addon.options)
	AceConfig:RegisterOptionsTable("HuokanAdvertiserToolsProfiles", profileOptions)
	AceConfigDialog:AddToBlizOptions("HuokanAdvertiserTools", L.addon_name)
	AceConfigDialog:AddToBlizOptions("HuokanAdvertiserToolsProfiles", L.profiles, L.addon_name)

	self:RegisterChatCommand("hat", "SlashCmd")
end

function Core:UpdateOptions()
	for name, module in self:IterateModules() do
		addon.options.args[name] = module.options
	end
end

function Core:GetDB(module, dbType)
	return self.db[dbType][module]
end

function Core:SlashCmd(args)
	if args == "" then
		InterfaceOptionsFrame_OpenToCategory(L.addon_name)
	elseif args == "?" or args == "help" then
		self:Print(L.help_desc)
	else
		local module = self:GetModuleBySlashCmd(args)
		if module and module.Show then
			if module.Hide and module.IsVisible and module:IsVisible() then
				module:Hide()
			else
				module:Show()
			end
		end
	end
end

function Core:GetModuleBySlashCmd(cmd)
	cmd = cmd:lower()
	for name, module in self:IterateModules() do
		if name:lower() == cmd then
			return module
		end
	end
end
