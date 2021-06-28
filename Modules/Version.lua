local addonName, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("Version", addon.ModulePrototype, "AceEvent-3.0", "AceComm-3.0")

local VERSION = 17
local COMM_PREFIX = "HAT_Version"

function module:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterComm(COMM_PREFIX)
end

function module:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if IsInGuild() then
		self:SendCommMessage(COMM_PREFIX, tostring(VERSION), "GUILD")
	end
end

function module:OnCommReceived(_, message, channel, sender)
	-- We will move over to sending the version string as well as number in the future once most people
	-- upgrade to a version that supports receiving those messages.
	local versionNumber, versionString = message:gmatch("(%d+) (.*)")()
	versionNumber = tonumber(versionNumber)
	if not versionNumber then
		-- Remove this when we start sending the version string
		versionNumber = tonumber(message)
	end
	if not versionNumber then return end

	if versionNumber < VERSION then
		self:SendCommMessage(COMM_PREFIX, tostring(VERSION), "WHISPER", sender)
	elseif versionNumber > VERSION and not self.isUpdateAvailable then
		self.isUpdateAvailable = true
		if versionString then
			Core:Print(L.update_available_with_version:format(versionString))
		else
			Core:Print(L.update_available)
		end
	end
end

function module:SlashCmd(args)
	local versionNumber = GetAddOnMetadata(addonName, "Version")
	Core:Printf(L.version:format(versionNumber, VERSION))
end
