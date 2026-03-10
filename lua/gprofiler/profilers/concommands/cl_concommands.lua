GProfiler.ConCommands = GProfiler.ConCommands or {}

function GProfiler.ConCommands.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Commands", "gprofiler/commands.png", 4, GProfiler.ConCommands.DoTab, function()

end)
