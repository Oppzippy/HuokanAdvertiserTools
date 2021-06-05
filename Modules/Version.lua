local addonName, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("Version", addon.ModulePrototype, "AceEvent-3.0", "AceComm-3.0")

local VERSION = 1
local COMM_PREFIX = "HAT_Version"

function module:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterComm(COMM_PREFIX)
end

function module:PLAYER_ENTERING_WORLD()
	self:SendCommMessage(COMM_PREFIX, tostring(VERSION), "GUILD")
end

function module:OnCommReceived(_, message, channel, sender)
	local theirVersion = tonumber(message)
	if not theirVersion then return end

	if theirVersion < VERSION then
		self:SendCommMessage(COMM_PREFIX, tostring(VERSION), "WHISPER", sender)
	elseif theirVersion > VERSION and not self.isUpdateAvailable then
		self.isUpdateAvailable = true
		self:Show()
		Core:Print(L.update_available)
	end
end

function module:Show()
	local versionNumber = GetAddOnMetadata(addonName, "Version")
	Core:Printf(L.version:format(versionNumber, VERSION))
end
