local _, addon = ...

local ModulePrototype = {}
addon.ModulePrototype = ModulePrototype

function ModulePrototype:GetDB()
	return addon.Core:GetDB(self:GetName())
end
