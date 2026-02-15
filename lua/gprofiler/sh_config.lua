GProfiler.Version = "1.9.1"

-- Available languages: english, french, german, dutch, russian, italian, turkish
-- Some languages may only have partial support.
GProfiler.Config.Language = "english"

-- Enable/Disable Log Types
GProfiler.Config.LOG_DEBUG = true
GProfiler.Config.LOG_INFO = true
GProfiler.Config.LOG_WARNING = true
GProfiler.Config.LOG_ERROR = true
GProfiler.Config.LOG_LOAD = false

GProfiler.Config.AllowedSteamIDs = { -- SteamIDs that can access GProfiler
	["76561198XXXXXXXXX"] = true
}

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

if CLIENT then
	GProfiler.MenuColors = {
		White = Color(255, 255, 255),
		Blue = Color(91, 118, 255),

		-- Menu
		Background = Color(8, 27, 48, 220),
		OpaqueBlack = Color(0, 0, 0, 200),
		OpaqueBlack2 = Color(0, 0, 0, 150),
		TopBarSeparator = Color(91, 118, 255, 10),
		HeaderSeparator = Color(91, 118, 255, 50),
		RealmSelectorBackground = Color(38, 57, 78),
		RealmSelectorOutline = Color(88, 107, 138),
		ActiveProfile = Color(10, 155, 10),
		InactiveProfile = Color(200, 50, 50),

		-- Lists
		DListBackground = Color(18, 37, 58),
		DListColumnBackground = Color(68, 87, 108),
		DListColumnOutline = Color(88, 107, 138),
		DListRowBackground = Color(48, 67, 88),
		DListRowHover = Color(68, 87, 108),
		DListRowTextColor = Color(235, 235, 235),
		DListRowSelected = Color(91, 118, 255, 50),

		-- Scrollbars
		ScrollBar = Color(38, 57, 78),
		ScrollBarGrip = Color(68, 87, 108),
		ScrollBarGripOutline = Color(88, 107, 138),

		-- Buttons
		ButtonOutline = Color(88, 107, 138),
		ButtonBackground = Color(38, 57, 78),
		ButtonHover = Color(58, 77, 98),

		CodeBackground = Color(45, 45, 45)
	}

	GProfiler.Config.MenuCommands = {
		Chat = '!gprofiler', -- False to disable
		Console = 'gprofiler', -- False to disable
		Closekey = KEY_F4 -- False to disable
	}
end
