util.AddNetworkString("GProfiler.AutoProfile.Configure")
util.AddNetworkString("GProfiler.AutoProfile.SendState")

local Profilers = GProfiler.Profilers

local function AutoStart(name, ply)
	local profiler = Profilers.Get(name)
	if not profiler then return end
	if not profiler.Store:Start("Server", ply) then return end
	if profiler.OnStart then profiler.OnStart("Server", ply) end
	net.Start("GProfiler.Profiler.Status")
	net.WriteString(name)
	net.WriteString("Server")
	net.WriteBool(true)
	net.WriteEntity(ply)
	net.WriteFloat(0)
	net.Broadcast()
end

hook.Add("GProfiler.Loaded", "GProfiler.AutoProfile", function()
	sql.Query("CREATE TABLE IF NOT EXISTS gprofiler_autoprofile (profiler TEXT PRIMARY KEY, state INTEGER)")

	local data = sql.Query("SELECT * FROM gprofiler_autoprofile")
	for _, row in ipairs(data or {}) do
		local state = tonumber(row.state) or 0
		if state == 0 then continue end

		local name = row.profiler
		if state == 1 then
			GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler!", 2)
			AutoStart(name, Entity(0))
		elseif state == 2 then
			hook.Add("PostGamemodeLoaded", "GProfiler.AutoProfile." .. name, function()
				hook.Remove("PostGamemodeLoaded", "GProfiler.AutoProfile." .. name)
				GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler (gamemode loaded)!", 2)
				AutoStart(name, Entity(0))
			end)
		elseif state == 3 then
			hook.Add("PlayerInitialSpawn", "GProfiler.AutoProfile." .. name, function(ply)
				hook.Remove("PlayerInitialSpawn", "GProfiler.AutoProfile." .. name)
				GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler (player joined)!", 2)
				AutoStart(name, ply)
			end)
		end
	end

	sql.Query("DELETE FROM gprofiler_autoprofile")
end)

net.Receive("GProfiler.AutoProfile.Configure", function(len, ply)
	if not GProfiler.Access.HasAccess(ply) then return end

	local name = net.ReadString()
	local state = net.ReadUInt(2)

	if not Profilers.Get(name) then return end

	if state == 0 then
		sql.Query("DELETE FROM gprofiler_autoprofile WHERE profiler = " .. sql.SQLStr(name))
	else
		sql.Query("REPLACE INTO gprofiler_autoprofile (profiler, state) VALUES (" .. sql.SQLStr(name) .. ", " .. state .. ")")
	end
end)

hook.Add("PlayerInitialSpawn", "GProfiler.AutoProfile.SendState", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) or not GProfiler.Access.HasAccess(ply) then return end

		local data = sql.Query("SELECT * FROM gprofiler_autoprofile")
		if table.IsEmpty(data or {}) then return end

		net.Start("GProfiler.AutoProfile.SendState")
		net.WriteUInt(#data, 8)
		for _, row in ipairs(data) do
			net.WriteString(row.profiler)
			net.WriteUInt(tonumber(row.state) or 0, 2)
		end
		net.Send(ply)
	end)
end)
