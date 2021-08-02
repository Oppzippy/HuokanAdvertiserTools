local _, addon = ...

local ModulePrototype = {}
addon.ModulePrototype = ModulePrototype

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
	local guildName, _, _, realm = GetGuildInfo("player")
	if not guildName then
		return
	end
	if not realm then
		realm = GetRealmName()
	end
	return addon.communityGuilds[string.format("%s - %s", guildName:lower(), realm:lower())] or addon.devMode
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
