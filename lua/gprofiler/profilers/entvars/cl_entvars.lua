GProfiler.EntVars = GProfiler.EntVars or {}

function GProfiler.EntVars.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Entity Variables", "gprofiler/entvars.png", 6, GProfiler.EntVars.DoTab, function()

end)
