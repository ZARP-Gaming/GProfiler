GProfiler.Functions = GProfiler.Functions or {}

local FunctionsStore = GProfiler.Profilers.GetStore("Functions")

function GProfiler.Functions.Tab(Content)

end

GProfiler.Menu.RegisterTab("Functions", "gprofiler/functions.png", 3, GProfiler.Functions.Tab, function()
	if not FunctionsStore then return end
	local timer = FunctionsStore:GetTimerData(GProfiler.Functions.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)
