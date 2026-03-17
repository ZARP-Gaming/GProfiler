GProfiler.Functions = GProfiler.Functions or {}
local FunctionsProfiler = GProfiler.Functions
FunctionsProfiler.IsDetoured = FunctionsProfiler.IsDetoured or false
FunctionsProfiler.ProfileData = FunctionsProfiler.ProfileData or {}
FunctionsProfiler.Focus = FunctionsProfiler.Focus or false

local SysTime = SysTime
local GetInfo = debug.getinfo
local Replace = string.Replace
local Find = string.find
local tostring = tostring
local math = math
local collectgarbage = collectgarbage

local chunkSizeLimit = 90000

local recurse = {}
local startTimes = {}
local startGarbage = {}
local IgnoreCache = {}

local function garbage() -- need to experiment more, which is more accurate? branch differences?
	-- return bit.lshift(gcinfo(), 10) + collectgarbage("\xFF")
	return collectgarbage("count") * 1024
end

local function CombineDuplicates()
	local combined = {}
	for k, v in pairs(FunctionsProfiler.ProfileData) do
		local lines = string.Split(v.lines, " - ")
		local realName = ""
		if string.StartWith(v.name, "0x") and string.find(v.name, "(", 1, true) then
			realName = string.Split(string.Split(v.name, " (")[2], ")")[1]
		end
		local key = v.source .. lines[1] .. lines[2] .. realName
		if not combined[key] then
			combined[key] = {
				name = v.name, source = v.source,
				lines = v.lines, calls = v.calls,
				time = v.time, average = v.average,
				focus = v.focus, garbage = v.garbage
			}
		else
			local Combined = combined[key]
			Combined.calls = Combined.calls + v.calls
			Combined.time = Combined.time + v.time
			Combined.average = Combined.average + v.average
		end
	end

	FunctionsProfiler.ProfileData = combined
end

local function handleFunction(event)
	local time = SysTime()
	local func = event.func

	if IgnoreCache[func] or Find(event.short_src, "/lua/gprofiler/", 1, true) then IgnoreCache[func] = true return end

	if not recurse[func] then recurse[func] = 0 end
	recurse[func] = recurse[func] + 1

	startTimes[func] = time
	startGarbage[func] = garbage()
end

local function handleReturn(event)
	local time = SysTime()
	local func = event.func
	if not startTimes[func] then return end

	local garbage = garbage() - (startGarbage[event.func] or 0)

	if FunctionsProfiler.Focus then
		if not FunctionsProfiler.Focus[tostring(func)] then return end
	end

	local runTime = time - startTimes[func]

	local funcTable = FunctionsProfiler.ProfileData[func]
	if not funcTable then
		local fstr = tostring(func)
		fstr = Replace(fstr, "function: ", "")
		FunctionsProfiler.ProfileData[func] = {
			name = event.name and string.format("%s (%s)", fstr, event.name) or fstr,
			source = event.short_src,
			-- FIXME: It is probably cheaper to send the numbers as uints, I'll experiment sometime
			lines = event.linedefined .. " - " .. event.lastlinedefined,
			calls = 0,
			time = 0,
			average = 0,
			focus = tostring(func),
			garbage = 0
		}
		funcTable = FunctionsProfiler.ProfileData[func]
	end

	funcTable.time = funcTable.time + runTime
	funcTable.calls = funcTable.calls + 1
	funcTable.average = funcTable.time / funcTable.calls
	funcTable.garbage = math.max(funcTable.garbage, garbage)

	recurse[func] = recurse[func] - 1
	if recurse[func] == 0 then recurse[func] = nil end
end

local function onEvent(event)
	local info = GetInfo(3, "fSn")
	if not info then return end

	if event == "call" or event == "tail call" then
		handleFunction(info)
	else
		local func = info.func
		if not recurse[func] or recurse[func] == 0 then return end
		handleReturn(info)
	end
end

local function StartDetour()
	if FunctionsProfiler.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " function profiler started!", 2)
	FunctionsProfiler.ProfileData = {}
	FunctionsProfiler.IsDetoured = true

	recurse = {}
	startTimes = {}

	debug.sethook(onEvent, "cr")
end

local function StopDetour()
	if not FunctionsProfiler.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " function profile stopped!", 2)
	FunctionsProfiler.IsDetoured = false

	debug.sethook()
	CombineDuplicates()
end

local function SendData(ply)
	local Count = table.Count(FunctionsProfiler.ProfileData)
	if GProfiler.ExpressAvailable() and Count > (GProfiler.Config.ExpressMinimumResults or 25) - 1 and Count > 0 then
		local Data = {}
		for k, v in pairs(FunctionsProfiler.ProfileData) do
			Data[tostring(k)] = {
				name = v.name, source = v.source,
				lines = v.lines, calls = v.calls,
				time = v.time, average = v.average,
				focus = v.focus, garbage = v.garbage
			}
		end

		express.Send("GProfiler_Functions_SendData", Data, ply)
	else
		local chunks = {}
		local chunkCount = 1
		local currentChunkSize = 0
		for k, v in pairs(FunctionsProfiler.ProfileData) do
			local curChunkSize = 134 + (v.name and string.len(v.name) or 7) + string.len(v.source) + string.len(v.lines) + string.len(v.focus)
			local chunkSize = currentChunkSize + curChunkSize
			if chunkSize > chunkSizeLimit then
				chunkCount = chunkCount + 1
				currentChunkSize = 0
				chunkSize = 0
			end

			if not chunks[chunkCount] then chunks[chunkCount] = {} end
			table.insert(chunks[chunkCount], v)
			currentChunkSize = chunkSize
		end

		if table.IsEmpty(chunks) then
			net.Start("GProfiler_Functions_SendData", true)
			net.WriteBool(true)
			net.WriteBool(true)
			net.WriteUInt(0, 32)
			net.Send(ply)
			return
		end

		local i = 1
		local function sendChunk()
			if not chunks[i] then return end
			net.Start("GProfiler_Functions_SendData")
			net.WriteBool(i == 1)
			net.WriteBool(i == table.Count(chunks))
			net.WriteUInt(#chunks[i], 32)
			for k, v1 in ipairs(chunks[i]) do
				net.WriteString(v1.name or "Unknown")
				net.WriteString(v1.source)
				net.WriteString(v1.lines)
				net.WriteUInt(v1.calls, 22)
				net.WriteFloat(v1.time)
				net.WriteFloat(v1.average)
				net.WriteString(v1.focus)
				net.WriteFloat(v1.garbage)
			end
			net.Send(ply)

			i = i + 1
			timer.Simple(.2, sendChunk)
		end
		sendChunk()
	end
end

GProfiler.Profilers.Register("Functions", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		StartDetour()
	end,
	OnStop = function(realm, ply)
		StopDetour()
		if SERVER and ply then
			SendData(ply)
		end
	end,
	WriteData = function(realm, ply)
		SendData(ply)
	end
})

if SERVER then
	util.AddNetworkString("GProfiler_Functions_SendData")
	util.AddNetworkString("GProfiler_Functions_SetFocus")

	net.Receive("GProfiler_Functions_SetFocus", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local hasFocus = net.ReadBool()
		if hasFocus then
			local count = net.ReadUInt(5)
			FunctionsProfiler.Focus = {}
			for i = 1, count do
				FunctionsProfiler.Focus[net.ReadString()] = true
			end
		else
			FunctionsProfiler.Focus = false
		end
	end)
end
