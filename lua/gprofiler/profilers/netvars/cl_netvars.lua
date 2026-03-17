GProfiler.NetVars = GProfiler.NetVars or {}

GProfiler.Profilers.Register("Network Variables", {})
local NetVarsStore = GProfiler.Profilers.GetStore("Network Variables")

function GProfiler.NetVars.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Network Variables", "gprofiler/netvars.png", 7, GProfiler.NetVars.DoTab, function()

end)
