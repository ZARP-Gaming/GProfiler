GProfiler.EntVars = GProfiler.EntVars or {}

GProfiler.Profilers.Register("Entity Variables", {})
local EntVarsStore = GProfiler.Profilers.GetStore("Entity Variables")

function GProfiler.EntVars.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Entity Variables", "gprofiler/entvars.png", 6, GProfiler.EntVars.DoTab, function()

end)
