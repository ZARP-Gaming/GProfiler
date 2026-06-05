GProfiler.NetVars = GProfiler.NetVars or {}
local NetVars = GProfiler.NetVars
NetVars.ProfileData = NetVars.ProfileData or {}
NetVars.ProfileActive = NetVars.ProfileActive or false

util.AddNetworkString("GProfiler_NetVars_SendData")

local NetVarTypes = {"Angle", "Bool", "Entity", "Float", "Int", "String", "Vector"}
local EntityMeta = FindMetaTable("Entity")
local PlayerMeta = FindMetaTable("Player")

hook.Add("Initialize", "GProfiler_NetVars", function()
	for _, type in ipairs(NetVarTypes) do
		for _, prefix in ipairs({"", "2"}) do
			local funcName = string.format("SetNW%s%s", prefix, type)
			local funcNameDetour = string.format("GProfiler_NetVars_%s%s", prefix, type)

			if not EntityMeta[funcNameDetour] then
				EntityMeta[funcNameDetour] = EntityMeta[funcName]
				EntityMeta[funcName] = function(ent, name, value)
					NetVars.CollectData(ent, name, value, type, prefix == "2")
					return ent[funcNameDetour](ent, name, value)
				end
			end

			if not PlayerMeta[funcNameDetour] then
				PlayerMeta[funcNameDetour] = PlayerMeta[funcName]
				PlayerMeta[funcName] = function(ply, name, value)
					NetVars.CollectData(ply, name, value, type, prefix == "2")
					return ply[funcNameDetour](ply, name, value)
				end
			end
		end
	end
end)

function NetVars.CollectData(ent, name, value, type, nw2)
	if not NetVars.ProfileActive then return end

	local ent = tostring(ent)
	local type = string.format("(NW%s) %s", nw2 and "2" or "", type)

	NetVars.ProfileData[ent] = NetVars.ProfileData[ent] or {}
	NetVars.ProfileData[ent][name] = NetVars.ProfileData[ent][name] or {}
	NetVars.ProfileData[ent][name][type] = NetVars.ProfileData[ent][name][type] or { TimesUpdated = 0 }
	NetVars.ProfileData[ent][name][type].TimesUpdated = NetVars.ProfileData[ent][name][type].TimesUpdated + 1
	NetVars.ProfileData[ent][name][type].CurValue = value
end

local function SendData(ply)
	net.Start("GProfiler_NetVars_SendData")
	net.WriteUInt(table.Count(NetVars.ProfileData), 32)
	for ent, data in pairs(NetVars.ProfileData) do
		net.WriteString(ent)
		net.WriteUInt(table.Count(data), 32)
		for name, types in pairs(data) do
			net.WriteString(name)
			net.WriteUInt(table.Count(types), 32)
			for type, info in pairs(types) do
				net.WriteString(type)
				net.WriteUInt(info.TimesUpdated, 32)
				net.WriteString(tostring(info.CurValue or ""))
			end
		end
	end
	net.Send(ply)
end

GProfiler.Profilers.Register("Network Variables", {
	Realms = { "Server" },
	OnStart = function(realm, ply)
		GProfiler.Log("Server network variables profiler started!", 2)
		NetVars.ProfileData = {}
		NetVars.ProfileActive = true
	end,
	OnStop = function(realm, ply)
		GProfiler.Log("Server network variables profile stopped, sending data!", 2)
		NetVars.ProfileActive = false
		if ply then SendData(ply) end
	end,
	WriteData = function(realm, ply)
		SendData(ply)
	end
})
