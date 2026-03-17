GProfiler.Timers = GProfiler.Timers or {}

local TimersStore = GProfiler.Profilers.GetStore("Timers")

function GProfiler.Timers.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Timers", "gprofiler/timers.png", 5, GProfiler.Timers.DoTab, function()

end)