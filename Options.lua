local _, addon = ...

addon.options = {
	type = "group",
	set = function(info, val)
		local module = info[1]
		local db = addon.Core:GetDB(module)
		db[info[#info]] = val
	end,
	get = function(info)
		local module = info[1]
		local db = addon.Core:GetDB(module)
		return db[info[#info]]
	end,
	args = {},
}

addon.dbDefaults = {
	profile = {
		Payment = {
			autoShow = true,
		}
	}
}
