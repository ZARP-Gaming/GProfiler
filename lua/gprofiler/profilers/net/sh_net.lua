GProfiler.Net = GProfiler.Net or {}
GProfiler.Net.IsDetoured = GProfiler.Net.IsDetoured or false
GProfiler.Net.ProfileData = GProfiler.Net.ProfileData or {}
GProfiler.Net.ProfileData.Inc = GProfiler.Net.ProfileData.Inc or {}
GProfiler.Net.ProfileData.Out = GProfiler.Net.ProfileData.Out or {}
GProfiler.Net.Breakdowns = GProfiler.Net.Breakdowns or {}

local netReadHeader = net.ReadHeader
local util = util
local max = math.max

local netWriteFunctions = {
	"WriteAngle", "WriteBit", "WriteBool", "WriteColor", "WriteData",
	"WriteDouble", "WriteEntity", "WriteFloat", "WriteInt", "WriteMatrix",
	"WriteNormal", "WriteString", "WriteTable", "WriteType", "WriteUInt",
	"WriteUInt64", "WriteVector"
}

GProfiler.Net.OriginalWrites = GProfiler.Net.OriginalWrites or {}

local netSendFunctions = { "Send" }
if SERVER then
	table.insert(netSendFunctions, "Broadcast")
	table.insert(netSendFunctions, "SendOmit")
	table.insert(netSendFunctions, "SendPVS")
	table.insert(netSendFunctions, "SendPAS")
else
	table.insert(netSendFunctions, "SendToServer")
end

local function DetourOutgoing()
	GProfiler.Net.OriginalWrites = {}

	local function AddEntry(funcName, size, ...)
		if not GProfiler.Net.CurrentMsg then return end

		local entry = {
			Func = funcName,
			Children = {},
			Size = size or 0
		}

		local stack = GProfiler.Net.CurrentMsg.Stack
		local parent = stack[#stack]
		if parent then
			table.insert(parent.Children, entry)
		end
		return entry
	end

	GProfiler.Net.OriginalWrites["Start"] = net.Start
	function net.Start(name, ...)
		local nameLower = name:lower()

		GProfiler.Net.CurrentMsg = {
			Name = nameLower,
			Stack = {},
			Root = { Children = {} },
			StartTime = SysTime()
		}
		GProfiler.Net.CurrentMsg.Stack[1] = GProfiler.Net.CurrentMsg.Root

		AddEntry("Start", 0)

		return GProfiler.Net.OriginalWrites["Start"](name, ...)
	end

	local function FinishMsg()
		if not GProfiler.Net.CurrentMsg then return end
		local name = GProfiler.Net.CurrentMsg.Name

		if not GProfiler.Net.ProfileData.Out[name] then
			GProfiler.Net.ProfileData.Out[name] = {0, 0, 0, nil, nil, nil, 0, 0, 0}
		end

		local d = GProfiler.Net.ProfileData.Out[name]
		local bytes, bits = net.BytesWritten()
		local size = bits or (bytes * 8)

		local dt = SysTime() - (GProfiler.Net.CurrentMsg.StartTime or SysTime())

		d[1] = d[1] + 1
		d[2] = max(d[2], size)
		d[3] = d[3] + size

		d[7] = d[7] + dt
		d[8] = max(d[8], dt)
		d[9] = d[7] / d[1]

		if not d[4] then
			local src = debug.getinfo(3, "S")
			if src then
				d[4] = src.short_src
				d[5] = src.linedefined
				d[6] = src.lastlinedefined
			end
		end

		GProfiler.Net.Breakdowns[name] = {
			Nodes = GProfiler.Net.CurrentMsg.Root.Children,
			Size = size
		}

		GProfiler.Net.CurrentMsg = nil
	end

	for _, funcName in ipairs(netSendFunctions) do
		if not net[funcName] then continue end
		GProfiler.Net.OriginalWrites[funcName] = net[funcName]

		net[funcName] = function(...)
			if GProfiler.Net.CurrentMsg then
				AddEntry(funcName, 0)
			end

			FinishMsg()
			return GProfiler.Net.OriginalWrites[funcName](...)
		end
	end

	for _, funcName in ipairs(netWriteFunctions) do
		if not net[funcName] then continue end

		GProfiler.Net.OriginalWrites[funcName] = net[funcName]
		net[funcName] = function(...)
			if not GProfiler.Net.CurrentMsg then
				return GProfiler.Net.OriginalWrites[funcName](...)
			end

			local entry = AddEntry(funcName, nil, ...)

			table.insert(GProfiler.Net.CurrentMsg.Stack, entry)

			local startB, startBits = net.BytesWritten()
			local ret = {GProfiler.Net.OriginalWrites[funcName](...)}
			local endB, endBits = net.BytesWritten()

			startBits = startBits or (startB * 8)
			endBits = endBits or (endB * 8)
			entry.Size = endBits - startBits

			table.remove(GProfiler.Net.CurrentMsg.Stack)

			return unpack(ret)
		end
	end
end

local function RestoreOutgoing()
	if not GProfiler.Net.OriginalWrites["Start"] then return end

	net.Start = GProfiler.Net.OriginalWrites["Start"]

	for _, funcName in ipairs(netSendFunctions) do
		if GProfiler.Net.OriginalWrites[funcName] then
			net[funcName] = GProfiler.Net.OriginalWrites[funcName]
		end
	end

	for _, funcName in ipairs(netWriteFunctions) do
		if GProfiler.Net.OriginalWrites[funcName] then
			net[funcName] = GProfiler.Net.OriginalWrites[funcName]
		end
	end

	GProfiler.Net.OriginalWrites = {}
	GProfiler.Net.CurrentMsg = nil
end

function GProfiler.Net:StartProfiler(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or GProfiler.Net.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " net profiler started!", 2)
	GProfiler.Net.ProfileData = { Inc = {}, Out = {} }
	GProfiler.Net.Breakdowns = {}

	GProfiler.Net.IsDetoured = true
	GProfiler.Net.ProfileStarted = SysTime()

	GProfiler.Net.OriginalIncoming = GProfiler.Net.OriginalIncoming or net.Incoming

	function net.Incoming(len, client)
		local i = netReadHeader()

		local strName = util.NetworkIDToString(i)
		if not strName then return end
		local nameLower = strName:lower()

		if not GProfiler.Net.ProfileData.Inc[nameLower] then
			GProfiler.Net.ProfileData.Inc[nameLower] = {0, 0, 0, nil, nil, nil, 0, 0, 0}
		end

		len = len - 16

		local d = GProfiler.Net.ProfileData.Inc[nameLower]
		d[1] = d[1] + 1
		d[2] = max(d[2], len)
		d[3] = d[3] + len

		local func = net.Receivers[nameLower]
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

	DetourOutgoing()
end

function GProfiler.Net:RestoreNet(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or not GProfiler.Net.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " net profile stopped, sending data!", 2)
	GProfiler.Net.IsDetoured = false
	GProfiler.Net.ProfileStarted = nil

	net.Incoming = GProfiler.Net.OriginalIncoming
	RestoreOutgoing()

	if GProfiler.Net.RefreshUI then
		GProfiler.Net.RefreshUI()
	end

	if CLIENT then return end

	local function SendData(dataMap, isIncoming)
		local count = table.Count(dataMap)
		if GProfiler.ExpressAvailable() and count > GProfiler.Config.ExpressMinimumResults-1 and count > 0 then
			local Data = {}
			for k, v in pairs(dataMap) do
				Data[tostring(k)] = {
					Count = v[1], MaxSize = v[2], TotalSize = v[3],
					Source = v[4], LineStart = v[5], LineEnd = v[6],
					TotalTime = v[7], LongestTime = v[8], AverageTime = v[9]
				}
			end

			express.Send("GProfiler_Net_SendData", { IsIncoming = isIncoming, Data = Data }, ply)
		else
			net.Start("GProfiler_Net_SendData")
			net.WriteBool(isIncoming)
			net.WriteUInt(count, 32)
			for name, data in pairs(dataMap) do
				net.WriteString(name)
				net.WriteUInt(data[1], 32)
				net.WriteUInt(data[2], 32)
				net.WriteDouble(data[3])
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

	SendData(GProfiler.Net.ProfileData.Inc, true)
	SendData(GProfiler.Net.ProfileData.Out, false)
end

if SERVER then
	util.AddNetworkString("GProfiler_Net_ToggleServerProfile")
	util.AddNetworkString("GProfiler_Net_ServerProfileStatus")
	util.AddNetworkString("GProfiler_Net_SendData")
	util.AddNetworkString("GProfiler_Net_RequestBreakdown")
	util.AddNetworkString("GProfiler_Net_SendBreakdown")
	util.AddNetworkString("GProfiler_Net_ReceiverTbl")
	util.AddNetworkString("GProfiler_NetTest")

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
			net.WriteString(Source.short_src or "")
			net.WriteUInt(Source.linedefined or 0, 16)
			net.WriteUInt(Source.lastlinedefined or 0, 16)
		end
		net.Send(ply)
	end)

	net.Receive("GProfiler_Net_RequestBreakdown", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local name = net.ReadString()
		local breakdownData = GProfiler.Net.Breakdowns[name]

		net.Start("GProfiler_Net_SendBreakdown")
		net.WriteString(name) -- TODO: assign an network id for these!
		if breakdownData then
			net.WriteBool(true)
			net.WriteUInt(breakdownData.Size, 32)

			local function WriteNode(node)
				net.WriteString(node.Func) -- ^
				net.WriteUInt(node.Size, 32)
				net.WriteUInt(#node.Children, 16)
				for _, child in ipairs(node.Children) do
					WriteNode(child)
				end
			end

			local nodes = breakdownData.Nodes
			net.WriteUInt(#nodes, 16)
			for _, node in ipairs(nodes) do
				WriteNode(node)
			end
		else
			net.WriteBool(false)
		end
		net.Send(ply)
	end)
end
