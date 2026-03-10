GProfiler.NetVars = GProfiler.NetVars or {}

function GProfiler.NetVars.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Network Variables", "gprofiler/netvars.png", 7, GProfiler.NetVars.DoTab, function()

end)
