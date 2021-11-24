local _, addon = ...

local read_tzfile = addon.luatz.tzfile.read_tzfile

local tz_cache = {}

local function clear_tz_cache(name)
	tz_cache[name] = nil
end

local function get_tz(name)
	local tzinfo = tz_cache[name]
	if tzinfo == nil then
		tzinfo = read_tzfile(name)
		tz_cache[name] = tzinfo
	end
	return tzinfo
end

addon.luatz.tzcache = {
	get_tz = get_tz;
	clear_tz_cache = clear_tz_cache;
}
