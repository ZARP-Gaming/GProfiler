GProfiler.Hooks = GProfiler.Hooks or {}

function GProfiler.Hooks.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Hooks", "gprofiler/hooks.png", 1, GProfiler.Hooks.DoTab, function()

end)
