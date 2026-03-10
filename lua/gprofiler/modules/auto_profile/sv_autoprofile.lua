-- util.AddNetworkString("GProfiler.AutoProfile.Configure")
-- util.AddNetworkString("GProfiler.AutoProfile.SendState")

-- local Profilers = {
-- 	["Hooks"] = "Hooks",
-- 	["Networking"] = "Net",
-- 	["Functions"] = "Functions",
-- 	["Commands"] = "ConCommands",
-- 	["Timers"] = "Timers",
-- 	-- ["Entity Variables"] = "EntVars",
-- 	["Network Variables"] = "NetVars",
-- 	["Database"] = "Database"
-- }

-- local ValidStates = {
-- 	0, -- Disabled
-- 	1, -- ASAP
-- 	2, -- When the gamemode has fully loaded
-- 	3 -- When the first player connects
-- }

-- hook.Add("GProfiler.Loaded", "GProfiler.AutoProfilers", function()
-- 	sql.Query("CREATE TABLE IF NOT EXISTS gprofiler_autoprofile (profiler TEXT, state INTEGER, PRIMARY KEY(profiler))")

-- 	local Data = sql.Query("SELECT * FROM gprofiler_autoprofile")
-- 	if not table.IsEmpty(Data or {}) then
-- 		for _, row in ipairs(Data) do
-- 			row.state = tonumber(row.state) or 0
-- 			if row.state == 0 then continue end

-- 			local Profiler = GProfiler[Profilers[row.profiler]]
-- 			if not Profiler then continue end

-- 			if row.state == 1 then
-- 				GProfiler.Log("[Auto Profiler] Starting " .. row.profiler .. " profiler!", 2)
-- 				Profiler:StartProfiler(Entity(0))
-- 			elseif row.state == 2 then
-- 				GProfiler.Log("[Auto Profiler] Delaying " .. row.profiler .. " profiler until the gamemode has fully loaded!", 2)
-- 				hook.Add("PostGamemodeLoaded", "GProfiler.AutoProfile." .. row.profiler, function()
-- 					hook.Remove("PostGamemodeLoaded", "GProfiler.AutoProfile." .. row.profiler)
-- 					GProfiler.Log("[Auto Profiler] Starting " .. row.profiler .. " profiler (gamemode loaded)!", 2)
-- 					Profiler:StartProfiler(Entity(0))
-- 				end)
-- 			elseif row.state == 3 then
-- 				GProfiler.Log("[Auto Profiler] Delaying " .. row.profiler .. " profiler until the first player connects!", 2)
-- 				hook.Add("PlayerConnect", "GProfiler.AutoProfile." .. row.profiler, function(ply)
-- 					hook.Remove("PlayerConnect", "GProfiler.AutoProfile." .. row.profiler)
-- 					GProfiler.Log("[Auto Profiler] Starting " .. row.profiler .. " profiler (player connected)!", 2)
-- 					Profiler:StartProfiler(ply)
-- 				end)
-- 			end
-- 		end
-- 	end

-- 	sql.Query("DELETE FROM gprofiler_autoprofile")
-- end)

-- net.Receive("GProfiler.AutoProfile.Configure", function(_, ply)
-- 	if not GProfiler.Access.HasAccess(ply) then return end

-- 	local Profiler = net.ReadString()
-- 	local State = net.ReadUInt(2)

-- 	if not Profilers[Profiler] or not table.HasValue(ValidStates, State) then return end

-- 	if State == 0 then
-- 		sql.Query("DELETE FROM gprofiler_autoprofile WHERE profiler = " .. sql.SQLStr(Profiler))
-- 	else
-- 		sql.Query("REPLACE INTO gprofiler_autoprofile (profiler, state) VALUES (" .. sql.SQLStr(Profiler) .. ", " .. State .. ")")
-- 	end
-- end)


-- hook.Add("PlayerInitialSpawn", "GProfiler.AutoProfiler.SendState", function(ply)
-- 	local Data = sql.Query("SELECT * FROM gprofiler_autoprofile")
-- 	if table.IsEmpty(Data or {}) then return end

-- 	net.Start("GProfiler.AutoProfile.SendState")
-- 	net.WriteUInt(table.Count(Data), 4)
-- 	for _, row in ipairs(Data) do
-- 		net.WriteString(row.profiler)
-- 		net.WriteUInt(row.state, 2)
-- 	end
-- 	net.Send(ply)
-- end)