GProfiler.Database = GProfiler.Database or {}

local DatabaseStore = GProfiler.Profilers.GetStore("Database")

function GProfiler.Database.DoTab(Content)

end

GProfiler.Menu.RegisterTab("Database", "gprofiler/database.png", 8, GProfiler.Database.DoTab, function()

end)
