GProfiler.AutoProfile = GProfiler.AutoProfile or {}
GProfiler.AutoProfile.States = GProfiler.AutoProfile.States or { Client = {}, Server = {} }

local AutoProfile = GProfiler.AutoProfile

net.Receive("GProfiler.AutoProfile.SendState", function()
	local count = net.ReadUInt(8)
	for i = 1, count do
		AutoProfile.States.Server[net.ReadString()] = net.ReadUInt(2)
	end
end)

sql.Query("CREATE TABLE IF NOT EXISTS gprofiler_autoprofile_cl (profiler TEXT PRIMARY KEY, state INTEGER)")

function AutoProfile.GetServerState(name) return AutoProfile.States.Server[name] or 0 end
function AutoProfile.GetClientState(name) return AutoProfile.States.Client[name] or 0 end

function AutoProfile.SetServerState(name, state)
	AutoProfile.States.Server[name] = state
	net.Start("GProfiler.AutoProfile.Configure")
	net.WriteString(name)
	net.WriteUInt(state, 2)
	net.SendToServer()
end

function AutoProfile.SetClientState(name, state)
	AutoProfile.States.Client[name] = state
	if state == 0 then
		sql.Query("DELETE FROM gprofiler_autoprofile_cl WHERE profiler = " .. sql.SQLStr(name))
	else
		sql.Query("REPLACE INTO gprofiler_autoprofile_cl (profiler, state) VALUES (" .. sql.SQLStr(name) .. ", " .. state .. ")")
	end
end

local function AutoStartClient(name)
	if GProfiler.Profilers.GetStore(name) and GProfiler.Profilers.GetStore(name):IsActive("Client") then return end
	GProfiler.Profilers.Toggle(name, "Client", true)
end

local function WhenReady(id, fn)
	if IsValid(LocalPlayer()) then fn() return end
	hook.Add("Think", id, function()
		if not IsValid(LocalPlayer()) then return end
		hook.Remove("Think", id)
		fn()
	end)
end

hook.Add("GProfiler.Loaded", "GProfiler.AutoProfile.Client", function()
	local data = sql.Query("SELECT * FROM gprofiler_autoprofile_cl")
	for _, row in ipairs(data or {}) do
		local name = row.profiler
		local state = tonumber(row.state) or 0
		if state == 0 then continue end

		local profiler = GProfiler.Profilers.Get(name)
		if not profiler or not table.HasValue(profiler.Realms, "Client") then continue end

		local id = "GProfiler.AutoProfile.CL." .. name
		if state == 1 then
			WhenReady(id, function()
				GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler (client)!", 2)
				AutoStartClient(name)
			end)
		elseif state == 2 then
			hook.Add("InitPostEntity", id, function()
				hook.Remove("InitPostEntity", id)
				WhenReady(id, function()
					GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler (client, gamemode loaded)!", 2)
					AutoStartClient(name)
				end)
			end)
		elseif state == 3 then
			WhenReady(id, function()
				GProfiler.Log("[Auto Profiler] Starting " .. name .. " profiler (client, spawned)!", 2)
				AutoStartClient(name)
			end)
		end
	end

	sql.Query("DELETE FROM gprofiler_autoprofile_cl")
end)
