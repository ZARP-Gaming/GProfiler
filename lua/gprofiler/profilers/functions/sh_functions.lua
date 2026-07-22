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

local chunkSizeLimit = 90000

local callStack = {}
local IgnoreCache = {}
local functionNames = {}
local mostExpensiveCalls = {}
local mostExpensiveDict = {}
local cgStack = {}
local cgBest = {}

local namewhatPriority = { global = 5, field = 4, method = 3, ["local"] = 2, upvalue = 1 }

local function resetBottlenecks()
	for i = 1, 50 do mostExpensiveCalls[i] = { runtime = 0 } end
	mostExpensiveDict = {}
end
resetBottlenecks()

local function buildDisplayName(func, nameInfo)
	if nameInfo and nameInfo.name then
		local nw = nameInfo.namewhat
		if nw and nw ~= "" then
			return string.format("%s [%s]", nameInfo.name, nw)
		end
		return nameInfo.name
	end
	return Replace(tostring(func), "function: ", "")
end

local function updateBottleneck(func, runTime, name, source, lines)
	if runTime <= mostExpensiveCalls[50].runtime then return end

	if mostExpensiveDict[func] then
		local i = mostExpensiveDict[func]
		if runTime < mostExpensiveCalls[i].runtime then return end

		mostExpensiveCalls[i].runtime = runTime
		mostExpensiveCalls[i].name = name
		mostExpensiveCalls[i].source = source
		mostExpensiveCalls[i].lines = lines

		while i > 1 and runTime > mostExpensiveCalls[i - 1].runtime do
			mostExpensiveDict[mostExpensiveCalls[i - 1].func] = i
			mostExpensiveCalls[i - 1], mostExpensiveCalls[i] = mostExpensiveCalls[i], mostExpensiveCalls[i - 1]
			i = i - 1
		end

		mostExpensiveDict[func] = i
		return
	end

	local i = 50
	while i >= 1 and runTime > mostExpensiveCalls[i].runtime do
		if mostExpensiveCalls[i].func then
			mostExpensiveDict[mostExpensiveCalls[i].func] = i + 1
		end
		i = i - 1
	end

	mostExpensiveDict[func] = i + 1
	table.insert(mostExpensiveCalls, i + 1, { func = func, runtime = runTime, name = name, source = source, lines = lines })

	if mostExpensiveCalls[51] then
		if mostExpensiveCalls[51].func then
			mostExpensiveDict[mostExpensiveCalls[51].func] = nil
		end
		mostExpensiveCalls[51] = nil
	end
end

local function MakeStableKey(name, source, lines)
	local stableName = name or ""
	if string.StartWith(stableName, "0x") then stableName = "" end
	local stripped = string.match(stableName, "^(.+)%s+%[.-%]$")
	if stripped then stableName = stripped end
	local splitLines = string.Split(lines or "0 - 0", " - ")
	return (source or "") .. "\1" .. (splitLines[1] or "0") .. "\1" .. (splitLines[2] or "0") .. "\1" .. stableName
end

local function CombineDuplicates()
	local combined = {}
	for k, v in pairs(FunctionsProfiler.ProfileData) do
		local key = MakeStableKey(v.name, v.source, v.lines)
		if not combined[key] then
			combined[key] = {
				name = v.name, source = v.source,
				lines = v.lines, calls = v.calls,
				time = v.time, average = 0,
				focus = v.focus, cgKey = key
			}
		else
			local Combined = combined[key]
			Combined.calls = Combined.calls + v.calls
			Combined.time = Combined.time + v.time
		end
	end

	for _, v in pairs(combined) do
		v.average = v.calls > 0 and (v.time / v.calls) or 0
	end

	FunctionsProfiler.ProfileData = combined
end

local function timingFinalize(frame)
	if frame.finalized then return end
	frame.finalized = true

	local funcTable = frame.funcTable
	if not funcTable then return end

	local runTime = SysTime() - frame.start
	funcTable.time = funcTable.time + runTime
	funcTable.average = funcTable.calls > 0 and (funcTable.time / funcTable.calls) or 0

	updateBottleneck(frame.func, runTime, funcTable.name, funcTable.source, funcTable.lines)
end

local function handleFunction(event, parent)
	local func = event.func

	if IgnoreCache[func] or Find(event.short_src, "/lua/gprofiler/", 1, true) then IgnoreCache[func] = true return end

	local existing = functionNames[func]
	local newPriority = namewhatPriority[event.namewhat] or 0
	local existingPriority = existing and (namewhatPriority[existing.namewhat] or 0) or -1
	if not existing or newPriority > existingPriority then
		functionNames[func] = { name = event.name, namewhat = event.namewhat }
	end

	if parent then
		while #callStack > 0 and callStack[#callStack].func ~= parent do
			local f = callStack[#callStack]
			callStack[#callStack] = nil
			timingFinalize(f)
		end
	else
		while #callStack > 0 do
			local f = callStack[#callStack]
			callStack[#callStack] = nil
			timingFinalize(f)
		end
	end

	local funcTable
	if not (FunctionsProfiler.Focus and not FunctionsProfiler.Focus[tostring(func)]) then
		funcTable = FunctionsProfiler.ProfileData[func]
		if not funcTable then
			funcTable = {
				name = buildDisplayName(func, functionNames[func]),
				source = event.short_src,
				lines = event.linedefined .. " - " .. event.lastlinedefined,
				calls = 0, time = 0, average = 0,
				focus = Replace(tostring(func), "function: ", "")
			}
			FunctionsProfiler.ProfileData[func] = funcTable
		else
			local fname = functionNames[func]
			if fname and (namewhatPriority[fname.namewhat] or 0) > 0 then
				funcTable.name = buildDisplayName(func, fname)
			end
		end

		funcTable.calls = funcTable.calls + 1
		funcTable.average = funcTable.calls > 0 and (funcTable.time / funcTable.calls) or 0
	end

	callStack[#callStack + 1] = { func = func, start = SysTime(), funcTable = funcTable }
end

local function handleReturn(func)
	local top = callStack[#callStack]
	if top and top.func == func then
		callStack[#callStack] = nil
		timingFinalize(top)
	end
end

local function cgFinalize(frame)
	if frame.finalized then return end
	frame.finalized = true
	frame.time = SysTime() - frame.start
	if cgBest[frame.func] == nil then
		cgBest[frame.func] = frame
	end
end

local function makeFrame(func, info)
	return {
		func = func,
		start = SysTime(),
		children = {},
		source = info.short_src or "",
		lines = (info.linedefined or 0) .. " - " .. (info.lastlinedefined or 0)
	}
end

local function cgOnCall(func, parent, info)
	if IgnoreCache[func] then return end

	if parent then
		while #cgStack > 0 and cgStack[#cgStack].func ~= parent do
			local f = cgStack[#cgStack]
			cgStack[#cgStack] = nil
			cgFinalize(f)
		end
	else
		while #cgStack > 0 do
			local f = cgStack[#cgStack]
			cgStack[#cgStack] = nil
			cgFinalize(f)
		end
	end

	local frame = makeFrame(func, info)
	local pframe = cgStack[#cgStack]
	if pframe then pframe.children[#pframe.children + 1] = frame end
	cgStack[#cgStack + 1] = frame
end

local function cgOnReturn(func)
	if IgnoreCache[func] then return end
	local top = cgStack[#cgStack]
	if top and top.func == func then
		cgStack[#cgStack] = nil
		cgFinalize(top)
	end
end

local function onEvent(event)
	local info = GetInfo(2, "fSn")
	if not info then return end

	if event == "call" then
		local parent
		for level = 3, 24 do
			local pi = GetInfo(level, "fS")
			if not pi then break end
			if pi.what ~= "C" and pi.func and not IgnoreCache[pi.func] then
				parent = pi.func
				break
			end
		end

		handleFunction(info, parent)
		cgOnCall(info.func, parent, info)
	else
		cgOnReturn(info.func)
		handleReturn(info.func)
	end
end

local function StartDetour()
	if FunctionsProfiler.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " function profiler started!", 2)
	FunctionsProfiler.ProfileData = {}
	FunctionsProfiler.IsDetoured = true

	callStack = {}
	IgnoreCache = {}
	functionNames = {}
	cgStack = {}
	cgBest = {}
	resetBottlenecks()
	debug.sethook(onEvent, "cr")
end

local CG_MAX_DEPTH = 32

local function serializeFrame(frame, depth)
	local node = {
		name = buildDisplayName(frame.func, functionNames[frame.func]),
		source = frame.source or "",
		lines = frame.lines or "0 - 0",
		time = frame.time or 0,
		children = {}
	}

	if depth < CG_MAX_DEPTH and frame.children[1] then
		local order, byFunc = {}, {}
		for _, c in ipairs(frame.children) do
			local g = byFunc[c.func]
			if not g then
				g = { rep = c, kids = {} }
				byFunc[c.func] = g
				order[#order + 1] = c.func
			end
			for _, gk in ipairs(c.children) do
				g.kids[#g.kids + 1] = gk
			end
		end

		for _, f in ipairs(order) do
			local g = byFunc[f]
			local merged = {
				func = g.rep.func,
				source = g.rep.source,
				lines = g.rep.lines,
				time = g.rep.time or 0,
				children = g.kids
			}
			node.children[#node.children + 1] = serializeFrame(merged, depth + 1)
		end
	end

	return node
end

local function StopDetour()
	if not FunctionsProfiler.IsDetoured then return end

	debug.sethook()
	while #callStack > 0 do
		local f = callStack[#callStack]
		callStack[#callStack] = nil
		timingFinalize(f)
	end
	FunctionsProfiler.IsDetoured = false

	GProfiler.Log((SERVER and "Server" or "Client") .. " function profile stopped!", 2)

	while #cgStack > 0 do
		local f = cgStack[#cgStack]
		cgStack[#cgStack] = nil
		cgFinalize(f)
	end

	local cgData = {}
	for func, frame in pairs(cgBest) do
		local key = MakeStableKey(buildDisplayName(func, functionNames[func]), frame.source, frame.lines)
		if not cgData[key] then
			cgData[key] = serializeFrame(frame, 0)
		end
	end

	FunctionsProfiler.CallGraphData = cgData
	CombineDuplicates()
end

local function buildBottleneckList()
	local list = {}
	for i = 1, 50 do
		local entry = mostExpensiveCalls[i]
		if not entry.func then break end
		table.insert(list, {
			name = entry.name or "Unknown",
			source = entry.source or "",
			lines = entry.lines or "0 - 0",
			runtime = entry.runtime,
			focus = Replace(tostring(entry.func), "function: ", ""),
			cgKey = MakeStableKey(entry.name, entry.source, entry.lines)
		})
	end
	return list
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
				focus = v.focus
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
			end
			net.Send(ply)

			i = i + 1
			timer.Simple(.2, sendChunk)
		end
		sendChunk()
	end
end

local function SendBottlenecks(ply)
	local list = buildBottleneckList()
	net.Start("GProfiler_Functions_SendBottlenecks")
	net.WriteUInt(#list, 6)
	for _, v in ipairs(list) do
		net.WriteString(v.name)
		net.WriteString(v.source)
		net.WriteString(v.lines)
		net.WriteFloat(v.runtime)
	end
	net.Send(ply)
end

GProfiler.Profilers.Register("Functions", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		StartDetour()
	end,
	OnStop = function(realm, ply)
		StopDetour()
		if CLIENT then
			local FuncStore = GProfiler.Profilers.GetStore("Functions")
			if FuncStore then
				FuncStore:SetData(realm, FunctionsProfiler.ProfileData)
				FuncStore:SetData(realm .. "_bottlenecks", buildBottleneckList())
				FuncStore:SetData(realm .. "_callgraph", FunctionsProfiler.CallGraphData or {})
			end
		end
		if SERVER and ply then
			SendData(ply)
			SendBottlenecks(ply)
		end
	end,
	WriteData = function(realm, ply)
		SendData(ply)
		SendBottlenecks(ply)
	end
})

if SERVER then
	util.AddNetworkString("GProfiler_Functions_SendData")
	util.AddNetworkString("GProfiler_Functions_SendBottlenecks")
	util.AddNetworkString("GProfiler_Functions_SetFocus")
	util.AddNetworkString("GProfiler_Functions_RequestCallGraph")
	util.AddNetworkString("GProfiler_Functions_CallGraphResponse")

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

	local function netWriteTree(node)
		net.WriteString(node.name or "Unknown")
		net.WriteString(node.source or "")
		net.WriteString(node.lines or "0 - 0")
		net.WriteFloat(node.time or 0)
		net.WriteUInt(#node.children, 16)
		for _, c in ipairs(node.children) do netWriteTree(c) end
	end

	net.Receive("GProfiler_Functions_RequestCallGraph", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local cgKey = net.ReadString()
		local tree = (FunctionsProfiler.CallGraphData or {})[cgKey]

		net.Start("GProfiler_Functions_CallGraphResponse")
		net.WriteString(cgKey)
		net.WriteBool(tree ~= nil)
		if tree then netWriteTree(tree) end
		net.Send(ply)
	end)
end
