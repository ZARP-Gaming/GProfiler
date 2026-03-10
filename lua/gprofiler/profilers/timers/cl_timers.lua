GProfiler.Timers = GProfiler.Timers or {}

function GProfiler.Timers.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Timers", "gprofiler/timers.png", 5, GProfiler.Timers.DoTab, function()

end)