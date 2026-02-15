GProfiler.Net = GProfiler.Net or {}
GProfiler.Net.IsDetoured = GProfiler.Net.IsDetoured or false
GProfiler.Net.ProfileData = GProfiler.Net.ProfileData or {}

local netReadHeader = net.ReadHeader
local util = util
local max = math.max

function GProfiler.Net:StartProfiler(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or GProfiler.Net.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " net profiler started!", 2)
	GProfiler.Net.ProfileData = {}
	GProfiler.Net.IsDetoured = true
	GProfiler.Net.ProfileStarted = SysTime()

	GProfiler.Net.OriginalIncoming = GProfiler.Net.OriginalIncoming or net.Incoming

	function net.Incoming(len, client)
		local i = netReadHeader()

		local strName = util.NetworkIDToString(i)
		if not strName then return end

		if not GProfiler.Net.ProfileData[strName] then
			GProfiler.Net.ProfileData[strName] = {0, 0, 0, nil, nil, nil, 0, 0, 0}
		end

		len = len - 16

		local d = GProfiler.Net.ProfileData[strName]
		d[1] = d[1] + 1
		d[2] = max(d[2], len)
		d[3] = d[3] + len

		local func = net.Receivers[strName:lower()]
		if not func then return end

		if not d[4] then
			local Source = debug.getinfo(func, "S")
			if Source then
				d[4] = Source.short_src
				d[5] = Source.linedefined
				d[6] = Source.lastlinedefined
			end
		end

		local start = SysTime()
		func(len, client)
		local endT = SysTime()
		d[7] = d[7] + (endT - start)
		d[8] = max(d[8], endT - start)
		d[9] = d[7] / d[1]
	end
end

function GProfiler.Net:RestoreNet(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or not GProfiler.Net.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " net profile stopped, sending data!", 2)
	GProfiler.Net.IsDetoured = false
	GProfiler.Net.ProfileStarted = nil

	net.Incoming = GProfiler.Net.OriginalIncoming

	if CLIENT then return end

	local Count = table.Count(GProfiler.Net.ProfileData)
	if GProfiler.ExpressAvailable() and Count > GProfiler.Config.ExpressMinimumResults-1 and Count > 0 then
		local Data = {}
		for k, v in pairs(GProfiler.Net.ProfileData) do
			Data[tostring(k)] = {
				Count = v[1], MaxSize = v[2], TotalSize = v[3],
				Source = v[4], LineStart = v[5], LineEnd = v[6],
				TotalTime = v[7], LongestTime = v[8], AverageTime = v[9]
			}
		end

		express.Send("GProfiler_Net_SendData", Data, ply)
	else
		net.Start("GProfiler_Net_SendData")
		net.WriteUInt(Count, 32)
		for name, data in pairs(GProfiler.Net.ProfileData) do
			net.WriteString(name)
			net.WriteUInt(data[1], 32)
			net.WriteUInt(data[2], 32)
			net.WriteUInt(data[3], 32)
			net.WriteString(data[4] or "")
			net.WriteUInt(data[5] or 0, 16)
			net.WriteUInt(data[6] or 0, 16)
			net.WriteFloat(data[7])
			net.WriteFloat(data[8])
			net.WriteFloat(data[9])
		end
		net.Send(ply)
	end
end

if SERVER then
	util.AddNetworkString("GProfiler_Net_ToggleServerProfile")
	util.AddNetworkString("GProfiler_Net_ServerProfileStatus")
	util.AddNetworkString("GProfiler_Net_SendData")
	util.AddNetworkString("GProfiler_Net_ReceiverTbl")

	net.Receive("GProfiler_Net_ToggleServerProfile", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		if net.ReadBool() then
			GProfiler.Net:StartProfiler(ply)
			net.Start("GProfiler_Net_ServerProfileStatus")
			net.WriteBool(true)
			net.WriteEntity(ply)
			net.Broadcast()
		else
			GProfiler.Net:RestoreNet(ply)
			net.Start("GProfiler_Net_ServerProfileStatus")
			net.WriteBool(false)
			net.WriteEntity(ply)
			net.Broadcast()
		end
	end)

	net.Receive("GProfiler_Net_ReceiverTbl", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		net.Start("GProfiler_Net_ReceiverTbl")
		net.WriteUInt(table.Count(net.Receivers), 32)
		for name, func in pairs(net.Receivers) do
			local Source = debug.getinfo(func, "S") or {}
			net.WriteString(name)
			net.WriteString(string.format("%s (%s)", tostring(func), GProfiler.GetFunctionLocation(func)))
			net.WriteString(Source.short_src or "")
			net.WriteUInt(Source.linedefined or 0, 16)
			net.WriteUInt(Source.lastlinedefined or 0, 16)
		end
		net.Send(ply)
	end)
end
