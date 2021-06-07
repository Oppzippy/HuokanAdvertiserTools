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
