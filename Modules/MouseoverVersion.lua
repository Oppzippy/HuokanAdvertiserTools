local _, addon = ...

local Core = addon.Core
local module = Core:NewModule("MouseoverVersion", addon.ModulePrototype, "AceEvent-3.0", "AceComm-3.0")

local COMM_PREFIX = "HAT_Version"

function module:OnInitialize()
	self.mouseoverBlacklist = {}
	if addon.devMode then
		self:RegisterComm(COMM_PREFIX)
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
end

function module:OnCommReceived(_, message, channel, sender)
	Core:Printf("%s is on version %s", sender, message)
end

function module:UPDATE_MOUSEOVER_UNIT()
	local mouseoverGuild = GetGuildInfo("mouseover")
	if mouseoverGuild and mouseoverGuild:lower():find("huokan") then
		local mouseoverName, mouseoverRealm = UnitName("mouseover")
		local guid = UnitGUID("mouseover")
		if mouseoverName and mouseoverRealm then
			mouseoverName = mouseoverName .. "-" .. mouseoverRealm
		end
		if not mouseoverName or self.mouseoverBlacklist[guid] then
			return
		end
		self.mouseoverBlacklist[guid] = true

		self:SendCommMessage(COMM_PREFIX, "0 v0", "WHISPER", mouseoverName)
		self:SendCommMessage(COMM_PREFIX, "0", "WHISPER", mouseoverName)
		Core:Printf("Sent version check to %s", mouseoverName)
	end
end
