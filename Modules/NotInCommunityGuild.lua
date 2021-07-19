local _, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("NotInCommunityGuild", addon.ModulePrototype, "AceEvent-3.0", "AceConsole-3.0")

function module:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function module:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	-- GetGuildInfo doesn't have data yet but IsInGuild does
	-- Keep retrying until GetGuildInfo returns proper data
	local timer
	timer = C_Timer.NewTicker(1, function()
		if not IsInGuild() then
			Core:Print(L.warning_not_in_community_guild)
			timer:Cancel()
		elseif GetGuildInfo("player") then
			timer:Cancel()
			if not self:IsInCommunityGuild() then
				Core:Print(L.warning_not_in_community_guild)
			end
		end
	end, 30)
end
