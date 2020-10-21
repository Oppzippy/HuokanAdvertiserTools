local _, addon = ...

local Core = addon.Core

local module = Core:NewModule("GuildDeposit", addon.ModulePrototype, "AceEvent-3.0")

function module:OnInitialize()
	self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY")
end

function module:GUILDBANK_UPDATE_WITHDRAWMONEY()

end
