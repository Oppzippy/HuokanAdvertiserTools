local addonName, addon = ...

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
--@do-not-package@
addon.devMode = true
--@end-do-not-package@

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
	self:RegisterChatCommand("huokanadvertisertools", "SlashCmd")
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
	args = { strsplit(" ", args) }
	if args[1] == "" or args[1] == "?" or args[1] == "help" then
		self:Print(L.help_desc)
	elseif args[1] == "options" then
		InterfaceOptionsFrame_OpenToCategory(L.addon_name)
	else
		local module = self:GetModuleBySlashCmd(args[1])
		if module then
			local moduleArgs = {}
			for i = 2, #args do
				moduleArgs[i-1] = args[i]
			end
			module:SlashCmd(moduleArgs)
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

function Core:GetVersion()
	return GetAddOnMetadata(addonName, "Version")
end
