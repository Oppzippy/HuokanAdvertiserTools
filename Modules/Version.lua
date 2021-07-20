local _, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("Version", addon.ModulePrototype, "AceEvent-3.0", "AceComm-3.0")

local VERSION = 6
local COMM_PREFIX = "HAT_Version"

function module:OnInitialize()
	self.versionPrints = 0
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterComm(COMM_PREFIX)
	--@do-not-package@
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	--@end-do-not-package@
end

function module:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if IsInGuild() then
		self:SendCommMessage(COMM_PREFIX, tostring(VERSION), "GUILD")
	end
end

function module:OnCommReceived(_, message, channel, sender)
	--@do-not-package@
	Core:Printf("%s is on version %s", sender, message)
	--@end-do-not-package@
	-- We will move over to sending the version string as well as number in the future once most people
	-- upgrade to a version that supports receiving those messages.
	local versionNumber, versionString = message:gmatch("(%d+) (.*)")()
	versionNumber = tonumber(versionNumber)
	if not versionNumber then return end

	if versionNumber < VERSION then
		self:SendCommMessage(COMM_PREFIX, self:GetVersionCommMessage(), "WHISPER", sender)
	else
		self:NewVersionReceived({
			number = versionNumber,
			string = versionString,
		})
	end
end

function module:NewVersionReceived(version)
	if not self.latestVersion or self.latestVersion.number < version.number then
		self.latestVersion = version
		if self.printVersionTimer then
			self.printVersionTimer:Cancel()
		end
		self.printVersionTimer = C_Timer.NewTimer(1, function()
			self:PrintLatestVersion()
		end)
	end
end

function module:PrintLatestVersion()
	if self.versionPrints < 3 then
		self.versionPrints = self.versionPrints + 1
		if self.latestVersion.string:find("@") ~= 1 then
			Core:Print(L.update_available_with_version:format(self.latestVersion.string, Core:GetVersion()))
		else
			Core:Print(L.update_available)
		end
	end
end

function module:GetVersionCommMessage()
	return tostring(VERSION) .. " " .. Core:GetVersion()
end

function module:SlashCmd(args)
	Core:Printf(L.version:format(Core:GetVersion(), VERSION))
end

--@do-not-package@
function module:UPDATE_MOUSEOVER_UNIT()
	if not self.mouseoverVersionBlacklist then
		self.mouseoverVersionBlacklist = {}
	end
	local mouseoverGuild = GetGuildInfo("mouseover")
	if mouseoverGuild and mouseoverGuild:lower():find("huokan") then
		local mouseoverName, mouseoverRealm = UnitName("mouseover")
		if mouseoverName and mouseoverRealm then
			mouseoverName = mouseoverName .. "-" .. mouseoverRealm
		end
		if not mouseoverName or self.mouseoverVersionBlacklist[mouseoverName] then
			return
		end
		self.mouseoverVersionBlacklist[mouseoverName] = mouseoverName

		self:SendCommMessage(COMM_PREFIX, self:GetVersionCommMessage(), "WHISPER", mouseoverName)
		self:SendCommMessage(COMM_PREFIX, "0 v0", "WHISPER", mouseoverName)
		self:SendCommMessage(COMM_PREFIX, "0", "WHISPER", mouseoverName)
		Core:Printf("Sent version to %s", mouseoverName)
	end
end
--@end-do-not-package@
