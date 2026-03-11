-- util.AddNetworkString("GProfiler.SendState")

-- local Profilers = {
-- 	"ConCommands", --[["EntVars",]] "Functions",
-- 	"Hooks", "Net", "NetVars", "Timers", "Database"
-- }

-- hook.Add("PlayerInitialSpawn", "GProfiler.SendState", function(ply)
-- 	local Active = {}
-- 	for _, profiler in ipairs(Profilers) do
-- 		if GProfiler[profiler].ProfileStarted then
-- 			Active[profiler] = GProfiler[profiler].ProfileStarted
-- 		end
-- 	end

-- 	if table.IsEmpty(Active) then return end

-- 	net.Start("GProfiler.SendState")
-- 	net.WriteUInt(table.Count(Active), 4)
-- 	for profiler, time in pairs(Active) do
-- 		net.WriteString(profiler)
-- 		net.WriteFloat(SysTime() - time)
-- 	end
-- 	net.Send(ply)
-- end)

local lan = GetConVar("sv_lan")
if lan:GetBool() then SetGlobalBool("gprofiler_lan", true) end