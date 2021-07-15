local _, addon = ...

local Core, L = addon.Core, addon.L
local module = Core:NewModule("NotInCommunityGuild", addon.ModulePrototype, "AceEvent-3.0", "AceConsole-3.0")

function module:OnInitialize()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function module:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if not self:IsInCommunityGuild() then
		Core:Print(L.warning_not_in_community_guild)
	end
end
