local _, addon = ...

addon.luatz = {}
addon.luatz.zoneinfo = {}

_G.HAT_ADDON_NS = addon

local luatz = _G.HAT_ADDON_NS.luatz

local function ts2tt(ts)
	return luatz.timetable.new_from_timestamp(ts)
end

-- Get the current time in UTC
local utcnow = luatz.time()
local now = ts2tt(utcnow)
print(now, "now (UTC)")

-- Get a new time object 6 months from now
local x = now:clone()
x.month = x.month + 6
x:normalise()
print(x, "6 months from now")

-- Find out what time it is in Melbourne at the moment
local melbourne = luatz.get_tz("America/New_York")
local now_in_melbourne = ts2tt(melbourne:localise(utcnow))
print(now_in_melbourne, "NewYork")
