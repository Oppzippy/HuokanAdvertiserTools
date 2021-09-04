local _, addon = ...

local ModulePrototype = {}
addon.ModulePrototype = ModulePrototype

local L = addon.L

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

function ModulePrototype:CreateOpenButtonOptionTable(order)
	return {
		name = L.open,
		desc = "/hat " .. self:GetName():lower(),
		type = "execute",
		width = "full",
		order = order,
		func = function()
			if self.IsVisible and self:IsVisible() then
				self:Hide()
			else
				self:Show()
			end
		end,
	}
end

function ModulePrototype:IsInCommunityGuild()
	local guildNameAndRealm = self:GuildNameAndRealm("player")
	if guildNameAndRealm then
		return addon.communityGuilds[guildNameAndRealm:lower()] or addon.devMode
	end
end

function ModulePrototype:UnitNameAndRealm(unit)
	local name, realm = UnitName(unit)
	if realm == nil then
		realm = GetNormalizedRealmName()
	end
	if name and realm then
		return name .. "-" .. realm
	end
	return ""
end

function ModulePrototype:PlayerNameAndRealmNotNormalized()
	local name = UnitName("player")
	local realm = GetRealmName()
	if name and realm then
		return name .. "-" .. realm
	end
	return ""
end

function ModulePrototype:GuildNameAndRealm(unit)
	local guildName, _, _, realm = GetGuildInfo("player")
	if not guildName then
		return
	end
	if not realm then
		realm = GetNormalizedRealmName()
	end
	return guildName .. "-" .. realm
end
