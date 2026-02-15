GProfiler.NetVars = GProfiler.NetVars or {}
GProfiler.NetVars.ProfileActive = GProfiler.NetVars.ProfileActive or false
GProfiler.NetVars.ProfileData = GProfiler.NetVars.ProfileData or {}

util.AddNetworkString("GProfiler_NetVars_ToggleServerProfile")
util.AddNetworkString("GProfiler_NetVars_ServerProfileStatus")
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
					GProfiler.NetVars.CollectData(ent, name, value, type, prefix == "2")
					return ent[funcNameDetour](ent, name, value)
				end
			end

			if not PlayerMeta[funcNameDetour] then
				PlayerMeta[funcNameDetour] = PlayerMeta[funcName]
				PlayerMeta[funcName] = function(ply, name, value)
					GProfiler.NetVars.CollectData(ply, name, value, type, prefix == "2")
					return ply[funcNameDetour](ply, name, value)
				end
			end
		end
	end
end)

function GProfiler.NetVars.CollectData(ent, name, value, type, nw2)
	if not GProfiler.NetVars.ProfileActive then return end

	local ent = tostring(ent)
	local type = string.format("(NW%s) %s", nw2 and "2" or "", type)

	GProfiler.NetVars.ProfileData[ent] = GProfiler.NetVars.ProfileData[ent] or {}
	GProfiler.NetVars.ProfileData[ent][name] = GProfiler.NetVars.ProfileData[ent][name] or {}
	GProfiler.NetVars.ProfileData[ent][name][type] = GProfiler.NetVars.ProfileData[ent][name][type] or { TimesUpdated = 0 }
	GProfiler.NetVars.ProfileData[ent][name][type].TimesUpdated = GProfiler.NetVars.ProfileData[ent][name][type].TimesUpdated + 1
	GProfiler.NetVars.ProfileData[ent][name][type].CurValue = value
end

function GProfiler.NetVars:StartProfiler()
	if GProfiler.NetVars.ProfileActive then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " network variables profiler started!", 2)
	GProfiler.NetVars.ProfileData = {}
	GProfiler.NetVars.ProfileActive = true
	GProfiler.NetVars.ProfileStarted = SysTime()
end

function GProfiler.NetVars:RestoreNetVars(ply)
	if not GProfiler.NetVars.ProfileActive then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " network variables profile stopped, sending data!", 2)
	GProfiler.NetVars.ProfileActive = false
	GProfiler.NetVars.ProfileStarted = nil

	net.Start("GProfiler_NetVars_SendData")
	net.WriteUInt(table.Count(GProfiler.NetVars.ProfileData), 32)
	for ent, data in pairs(GProfiler.NetVars.ProfileData) do
		net.WriteString(ent)
		net.WriteUInt(table.Count(data), 32)
		for name, types in pairs(data) do
			net.WriteString(name)
			net.WriteUInt(table.Count(types), 32)
			for type, data in pairs(types) do
				net.WriteString(type)
				net.WriteUInt(data.TimesUpdated, 32)
				net.WriteString(tostring(data.CurValue or ""))
			end
		end
	end
	net.Send(ply)
end

net.Receive("GProfiler_NetVars_ToggleServerProfile", function(len, ply)
	if not GProfiler.Access.HasAccess(ply) then return end

	if net.ReadBool() then
		GProfiler.NetVars:StartProfiler()
		net.Start("GProfiler_NetVars_ServerProfileStatus")
		net.WriteBool(true)
		net.WriteEntity(ply)
		net.Broadcast()
	else
		GProfiler.NetVars:RestoreNetVars(ply)
		net.Start("GProfiler_NetVars_ServerProfileStatus")
		net.WriteBool(false)
		net.WriteEntity(ply)
		net.Broadcast()
	end
end)