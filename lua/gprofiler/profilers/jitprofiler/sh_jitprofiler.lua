GProfiler.JIT = GProfiler.JIT or {}
local JIT = GProfiler.JIT
JIT.Interval = JIT.Interval or 1
JIT.Granularity = JIT.Granularity or "l"

local installed = util.IsBinaryModuleInstalled("gprofiler")
if installed then require("gprofiler") end
JIT.Available = (installed and istable(gprofiler) and gprofiler.Available and gprofiler.Available()) or false
GProfiler.Log("JIT Profiler " .. (JIT.Available and "available!" or string.format("unavailable! (module: %s, avail: %s)", util.IsBinaryModuleInstalled("gprofiler"), gprofiler and gprofiler.Available and tostring(gprofiler.Available()))), 1)

local DUMP_DEPTH = 60
local chunkSizeLimit = 60000
local VMSTATES = { "I", "N", "C", "G", "J" }

local function DumpFormat()
	return JIT.Granularity == "f" and "f @ pl;" or "pl;"
end

local function BuildMode()
	return JIT.Granularity .. "i" .. math.max(math.floor(JIT.Interval), 1)
end

local function StartSampling()
	if not JIT.Available then return end
	gprofiler.Start(BuildMode(), DumpFormat(), DUMP_DEPTH)
end

local function CollectData()
	if not JIT.Available then return { samples = {}, total = 0, vmstates = {}, granularity = JIT.Granularity, interval = JIT.Interval } end
	if gprofiler.IsRunning() then gprofiler.Stop() end
	local samples, total, vmstates = gprofiler.Query()
	return {
		samples = samples or {},
		total = total or 0,
		vmstates = vmstates or {},
		granularity = JIT.Granularity,
		interval = JIT.Interval
	}
end

local function FlattenSamples(samples)
	local arr = {}
	for stack, count in pairs(samples) do
		arr[#arr + 1] = { stack, count }
	end
	return arr
end

local function SendData(ply, data)
	data = data or CollectData()
	local arr = FlattenSamples(data.samples)

	if GProfiler.ExpressAvailable() and #arr > (GProfiler.Config.ExpressMinimumResults or 25) - 1 then
		-- todo
	end

	local chunks = {}
	local chunkCount = 1
	local currentSize = 0
	for _, entry in ipairs(arr) do
		local size = string.len(entry[1]) + 6
		if currentSize + size > chunkSizeLimit then
			chunkCount = chunkCount + 1
			currentSize = 0
		end
		chunks[chunkCount] = chunks[chunkCount] or {}
		table.insert(chunks[chunkCount], entry)
		currentSize = currentSize + size
	end

	if table.IsEmpty(chunks) then chunks[1] = {} end

	local i = 1
	local function sendChunk()
		if not chunks[i] then return end
		net.Start("GProfiler_JIT_SendData")
		net.WriteBool(i == 1)
		net.WriteBool(i == #chunks)
		if i == 1 then
			net.WriteUInt(data.total, 32)
			net.WriteString(data.granularity)
			net.WriteUInt(data.interval, 16)
			for _, s in ipairs(VMSTATES) do
				net.WriteUInt(data.vmstates[s] or 0, 32)
			end
		end
		net.WriteUInt(#chunks[i], 24)
		for _, entry in ipairs(chunks[i]) do
			net.WriteString(entry[1])
			net.WriteUInt(entry[2], 24)
		end
		net.Send(ply)

		i = i + 1
		timer.Simple(0.15, sendChunk)
	end
	sendChunk()
end

GProfiler.Profilers.Register("JIT Profiler", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		StartSampling()
	end,
	OnStop = function(realm, ply)
		local data = CollectData()
		JIT.LastData = data
		if CLIENT then
			local store = GProfiler.Profilers.GetStore("JIT Profiler")
			if store then store:SetData(realm, data) end
		end
		if SERVER and ply then SendData(ply, data) end
	end,
	WriteData = function(realm, ply)
		SendData(ply, JIT.LastData)
	end
})

if SERVER then
	util.AddNetworkString("GProfiler_JIT_SendData")
	util.AddNetworkString("GProfiler_JIT_SetMode")
	util.AddNetworkString("GProfiler_JIT_Availability")

	net.Receive("GProfiler_JIT_SetMode", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end
		JIT.Interval = math.Clamp(net.ReadUInt(16), 1, 1000)
		JIT.Granularity = net.ReadBool() and "f" or "l"
	end)

	net.Receive("GProfiler_JIT_Availability", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end
		net.Start("GProfiler_JIT_Availability")
		net.WriteBool(JIT.Available)
		net.Send(ply)
	end)
end
