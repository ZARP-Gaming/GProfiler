GProfiler.Database = GProfiler.Database or {}
GProfiler.Database.Providers = GProfiler.Database.Providers or {}

local ProviderLoader = {}

function ProviderLoader.LoadProviders()
	local loadedCount = 0

	local files, _ = file.Find("gprofiler/profilers/database/providers/*.lua", "LUA")
	for _, fileName in ipairs(files or {}) do
		local success, err = pcall(function()
			include("gprofiler/profilers/database/providers/" .. fileName)
			loadedCount = loadedCount + 1
		end)

		if not success then
			GProfiler.Log("Failed to load database provider " .. fileName .. ": " .. tostring(err), 4)
		end
	end

	return loadedCount
end

function ProviderLoader.GetRegisteredProviders()
	local providers = {}
	for name, provider in pairs(GProfiler.Database.Providers) do
		if name != "Register" then
			providers[name] = provider
		end
	end
	return providers
end

function ProviderLoader.GetAvailableProviders()
	local available = {}
	for name, provider in pairs(ProviderLoader.GetRegisteredProviders()) do
		if provider:IsAvailable() then
			available[name] = provider
		end
	end
	return available
end

function ProviderLoader.Initialize()
	local loadedCount = ProviderLoader.LoadProviders()
	local availableProviders = ProviderLoader.GetAvailableProviders()
	local availableCount = table.Count(availableProviders)

	GProfiler.Log("Database providers initialized: " .. loadedCount .. " loaded, " .. availableCount .. " available", 2)

	return availableProviders
end

return ProviderLoader