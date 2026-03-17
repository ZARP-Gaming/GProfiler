GProfiler = GProfiler or { Config = {}, Access = {}, Utils = {} }

local logLevels = {
	[1] = {"DEBUG", Color(0, 255, 0)},
	[2] = {"INFO", Color(0, 0, 255)},
	[3] = {"WARNING", Color(255, 255, 0)},
	[4] = {"ERROR", Color(255, 0, 0)},
	[5] = {"LOAD", Color(255, 0, 255)}
}

local color_white = Color(255, 255, 255)

function GProfiler.Log(str, lvl)
	local LvlData = logLevels[lvl or 1] or logLevels[1]
	if not GProfiler.Config[string.format("LOG_%s", LvlData[1])] then return end

	MsgC(LvlData[2], string.format("[GProfiler][%s] ", LvlData[1]), color_white, str, "\n")
end

local incFuncs = {
	sv = SERVER and include or function() end,
	cl = SERVER and AddCSLuaFile or include,
	sh = function(f) include(f) AddCSLuaFile(f) end
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
