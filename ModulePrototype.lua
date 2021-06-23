local _, addon = ...

local ModulePrototype = {}
addon.ModulePrototype = ModulePrototype

local devMode = false

function ModulePrototype:GetProfileDB()
	return self:GetSpecificDB("profile")
end

function ModulePrototype:GetGlobalDB()
	return self:GetSpecificDB("global")
end

function ModulePrototype:GetSpecificDB(dbType)
	return addon.Core:GetDB(self:GetName(), dbType)
end

function ModulePrototype:SlashCmd(args)
	if self.IsVisible then
		if self:IsVisible() and self.Show then
			self:Hide()
		elseif not self:IsVisible() and self.Hide then
			self:Show()
		end
	end
end

function ModulePrototype:IsInCommunityGuild()
	local guildName = GetGuildInfo("player")
	return (guildName and guildName:find("Huokan") ~= nil) or devMode
end

function ModulePrototype:UnitNameAndRealm(unit)
	local name, realm = UnitName(unit)
	if realm == nil then
		realm = GetRealmName()
	end
	if name and realm then
		return name .. "-" .. realm
	end
	return ""
end

--@do-not-package@
devMode = true
--@end-do-not-package@
