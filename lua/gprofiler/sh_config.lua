GProfiler.Version = "2.0.0"

-- Available languages: english
GProfiler.Config.Language = "english"

-- Enable/Disable Log Types
GProfiler.Config.LOG_DEBUG = true
GProfiler.Config.LOG_INFO = true
GProfiler.Config.LOG_WARNING = true
GProfiler.Config.LOG_ERROR = true
GProfiler.Config.LOG_LOAD = false

-- Access
GProfiler.Config.AllowedSteamIDs = { -- SteamIDs that can access GProfiler
	["76561198XXXXXXXXX"] = true
}

GProfiler.Config.AllowSuperAdmin = false -- Allow players with superadmin (Player:IsSuperAdmin()) to access GProfiler regardless of other checks.

-- todo, requires a lot of changes probably
-- GProfiler.Config.AlwaysAllowClient = false -- Allow clients to use GProfiler (limited to client realm/cannot view sources, etc)

--[[
	If express is available, we use it over gmod's net library
	This can handle larger data sizes, and we shouldn't need to worry about overflowing the buffer
	Learn more at https://github.com/CFC-Servers/gm_express

	If you are using express and are having issues, set this to false to rule out express as the issue
]]
GProfiler.Config.UseExpressNetworking = true
-- Minimum profiler results required to use express networking
-- Express is not worth using for small amounts, as it will be slower for small data
GProfiler.Config.ExpressMinimumResults = 25

if SERVER then return end

GProfiler.MenuColors = {
	-- Misc
	White = Color(255, 255, 255),
	Blue = Color(91, 118, 255),
	Black100 = Color(0, 0, 0, 100),

	-- Scrollbars
	ScrollBar = Color(38, 57, 78),
	ScrollBarGrip = Color(68, 87, 108),
	ScrollBarGripOutline = Color(88, 107, 138),
}

GProfiler.Config.MenuCommands = {
	Chat = '!gprofiler', -- False to disable
	Console = 'gprofiler', -- False to disable
	Closekey = KEY_F4 -- False to disable
}
