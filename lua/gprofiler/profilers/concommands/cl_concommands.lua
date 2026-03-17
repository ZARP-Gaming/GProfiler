GProfiler.ConCommands = GProfiler.ConCommands or {}

local CommandsStore = GProfiler.Profilers.GetStore("Commands")

function GProfiler.ConCommands.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Commands", "gprofiler/commands.png", 4, GProfiler.ConCommands.DoTab, function()
	if not CommandsStore then return end
	local timer = CommandsStore:GetTimerData(GProfiler.ConCommands.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)
