GProfiler.Functions = GProfiler.Functions or {}

function GProfiler.Functions.Tab(Content)

end

GProfiler.Menu.RegisterTab("Functions", "gprofiler/functions.png", 3, GProfiler.Functions.Tab, function()
	return "00:00", false
end)
