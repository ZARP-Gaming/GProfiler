GProfiler = GProfiler or { Config = {}, Access = {}, Utils = {} }

local logLevels = {
	[1] = {"DEBUG", Color(80, 200, 120)},
	[2] = {"INFO", Color(80, 150, 255)},
	[3] = {"WARNING", Color(230, 200, 60)},
	[4] = {"ERROR", Color(235, 75, 75)},
	[5] = {"LOAD", Color(200, 110, 230)}
}

local color_white = Color(255, 255, 255)
local lastLogTime = {}

local function f(ms)
	if ms >= 86400000 then return math.Round(ms / 86400000) .. "d" end
	if ms >= 3600000 then return math.Round(ms / 3600000) .. "h" end
	if ms >= 60000 then return math.Round(ms / 60000) .. "m" end
	if ms >= 1000 then return math.Round(ms / 1000) .. "s" end
	return math.Round(ms) .. "ms"
end

function GProfiler.Log(str, lvl)
	local LvlData = logLevels[lvl or 1] or logLevels[1]
	if not GProfiler.Config[string.format("LOG_%s", LvlData[1])] then return end

	local namespace = "gprofiler:" .. string.lower(LvlData[1])
	local now = SysTime() * 1000
	local diff = lastLogTime[namespace] and (now - lastLogTime[namespace]) or 0
	lastLogTime[namespace] = now

	MsgC(LvlData[2], "  " .. namespace .. " ", color_white, str, LvlData[2], " +" .. f(diff), color_white, "\n")
end

local incFuncs = {
	sv = SERVER and include or function() end,
	cl = SERVER and AddCSLuaFile or include,
	sh = function(f) include(f) AddCSLuaFile(f) end,
	nl = function() end
}

local function incFile(f)
	(incFuncs[string.GetFileFromFilename(f):sub(1,2)] or incFuncs.sh)(f)
	GProfiler.Log(string.format("Loaded file %s", f), 5)
end

local function incFolder(folder, subFileOnly, fileOnly)
	GProfiler.Log(string.format("Loading folder %s", folder), 5)

	local files, folders = file.Find(folder.."/*", "LUA")
	for _, f in SortedPairs(files, CLIENT) do incFile(string.format("%s/%s", folder, f)) end

	if fileOnly then return end
	for _, f in ipairs(folders) do incFolder(folder.."/"..f, nil, subFileOnly) end
end

incFile("gprofiler/sv_init.lua")
incFile("gprofiler/sh_config.lua")
incFile("gprofiler/cl_menu.lua")
incFolder("gprofiler/modules")
incFolder("gprofiler/profilers", true)

hook.Run("GProfiler.Loaded")
GProfiler.Ready = true
