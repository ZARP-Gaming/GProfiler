GProfiler.Hooks = GProfiler.Hooks or {}

local HooksStore = GProfiler.Profilers.GetStore("Hooks")

function GProfiler.Hooks.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Hooks", "gprofiler/hooks.png", 1, GProfiler.Hooks.DoTab, function()
	if not HooksStore then return end
	local timer = HooksStore:GetTimerData(GProfiler.Hooks.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)
