-- -- For timers, we must detour instantly, as there is no way to get timers created before the detour was created.
-- -- rubat please timer.GetList

-- GProfiler.Timers = GProfiler.Timers or {}
-- GProfiler.Timers.Simple = GProfiler.Timers.Simple or {}
-- GProfiler.Timers.Create = GProfiler.Timers.Create or {}
-- GProfiler.Timers.IsDetoured = GProfiler.Timers.IsDetoured or false
-- GProfiler.Timers.OldSimpleTimer = GProfiler.Timers.OldSimpleTimer or timer.Simple
-- GProfiler.Timers.OldCreateTimer = GProfiler.Timers.OldCreateTimer or timer.Create
-- GProfiler.ActiveTimers = GProfiler.ActiveTimers or { Simple = {}, Create = {} }

-- local chunkSizeLimit = 65535

-- function GProfiler.Timers:StartProfiler(ply)
-- 	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) then return end

-- 	if GProfiler.Timers.IsDetoured then return end

-- 	GProfiler.Log((SERVER and "Server" or "Client") .. " timer profiler started!", 2)
-- 	GProfiler.Timers.IsDetoured = true
-- 	GProfiler.Timers.ProfileStarted = SysTime()

-- 	GProfiler.Timers.Simple = {}
-- 	GProfiler.Timers.Create = {}
-- end

-- function GProfiler.Timers:Stop(ply)
-- 	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) then return end

-- 	if not GProfiler.Timers.IsDetoured then return end

-- 	GProfiler.Log((SERVER and "Server" or "Client") .. " timer profile stopped, sending data!", 2)
-- 	GProfiler.Timers.IsDetoured = false
-- 	GProfiler.Timers.ProfileStarted = nil

-- 	if SERVER then
-- 		local ProfileData = table.Merge(GProfiler.Timers.Simple, GProfiler.Timers.Create)
-- 		local chunkCount = 1
-- 		local currentChunkSize = 0
-- 		local chunks = {}
-- 		for k, v in pairs(ProfileData) do
-- 			local chunkSize = 146 + string.len(v.Type) + string.len(tostring(k)) + string.len(v.Source)
-- 			if currentChunkSize + chunkSize > chunkSizeLimit then
-- 				chunkCount = chunkCount + 1
-- 				currentChunkSize = 0
-- 			end

-- 			if not chunks[chunkCount] then chunks[chunkCount] = {} end
-- 			currentChunkSize = currentChunkSize + chunkSize
-- 			table.insert(chunks[chunkCount], {k, v})
-- 		end

-- 		for k, v in ipairs(chunks) do
-- 			net.Start("GProfiler_Timers_SendData")
-- 				net.WriteBool(k == 1)
-- 				net.WriteBool(k == table.Count(chunks))
-- 				net.WriteUInt(table.Count(v), 32)
-- 				for _, data in ipairs(v) do
-- 					local dat = data[2]
-- 					net.WriteString(dat.Type)
-- 					net.WriteString(tostring(data[1]))
-- 					net.WriteUInt(dat.Count, 15)
-- 					net.WriteFloat(dat.Delay)
-- 					net.WriteFloat(dat.TotalTime)
-- 					net.WriteFloat(dat.LongestTime)
-- 					net.WriteFloat(dat.AverageTime)
-- 					net.WriteString(dat.Source)
-- 					net.WriteUInt(dat.Lines[1], 14)
-- 					net.WriteUInt(dat.Lines[2], 14)
-- 				end
-- 			net.Send(ply)
-- 		end

-- 		if table.Count(chunks) == 0 then
-- 			net.Start("GProfiler_Timers_SendData")
-- 				net.WriteBool(true)
-- 				net.WriteBool(true)
-- 				net.WriteUInt(0, 32)
-- 			net.Send(ply)
-- 		end
-- 	end
-- end

-- function GProfiler.Timers.CollectTimerData(type, name, delay, func, funcTime)
-- 	if not GProfiler.Timers.IsDetoured then return end

-- 	if not GProfiler.Timers[type][name] then
-- 		local dbgInfo = debug.getinfo(func, "S")
-- 		GProfiler.Timers[type][name] = {
-- 			Count = 0,
-- 			TotalTime = 0,
-- 			LongestTime = 0,
-- 			AverageTime = 0,
-- 			Func = func,
-- 			Delay = delay,
-- 			Source = dbgInfo.short_src,
-- 			Lines = {dbgInfo.linedefined, dbgInfo.lastlinedefined},
-- 			Type = type
-- 		}
-- 	end

-- 	local tbl = GProfiler.Timers[type][name]
-- 	tbl.Count = tbl.Count + 1
-- 	tbl.TotalTime = tbl.TotalTime + funcTime
-- 	tbl.AverageTime = tbl.TotalTime / tbl.Count
-- 	tbl.LongestTime = math.max(tbl.LongestTime, funcTime)
-- end

-- local function assertType(value, check, num, expect)
-- 	assert(check(value), string.format("bad argument #%d (%s expected, got %s)", num, expect, type(value)))
-- 	return true
-- end

-- timer.Simple = function(delay, func, ...)
-- 	if not assertType(delay, isnumber, 1, "number") or not assertType(func, isfunction, 2, "function") then return end

-- 	local Index = delay != 0 and table.insert(GProfiler.ActiveTimers.Simple, {NextRun = SysTime() + delay, Source = debug.getinfo(2)})

-- 	local args = {...}
-- 	GProfiler.Timers.OldSimpleTimer(delay, function()
-- 		local start = SysTime()
-- 		func(unpack(args))
-- 		GProfiler.Timers.CollectTimerData("Simple", func, delay, func, SysTime() - start)
-- 		if Index then table.remove(GProfiler.ActiveTimers.Simple, Index) end
-- 	end)
-- end

-- timer.Create = function(name, delay, reps, func)
-- 	if not (
-- 		assertType(name, isstring, 1, "string") and
-- 		assertType(delay, isnumber, 2, "number") and
-- 		assertType(reps, isnumber, 3, "number") and
-- 		assertType(func, isfunction, 4, "function")
-- 	) then return end

-- 	name = tostring(name)

-- 	for k, v in ipairs(GProfiler.ActiveTimers.Create) do
-- 		if v.Name == name then
-- 			table.remove(GProfiler.ActiveTimers.Create, k)
-- 			break
-- 		end
-- 	end
-- 	table.insert(GProfiler.ActiveTimers.Create, { Name = name, Reps = reps, Source = debug.getinfo(2) })

-- 	GProfiler.Timers.OldCreateTimer(name, delay, reps, function()
-- 		local start = SysTime()
-- 		func()
-- 		local endtime = SysTime() - start
-- 		GProfiler.Timers.CollectTimerData("Create", name, delay, func, endtime)
-- 		if timer.RepsLeft(name) == 0 then
-- 			for i, data in ipairs(GProfiler.ActiveTimers.Create) do
-- 				if data.Name == name then
-- 					table.remove(GProfiler.ActiveTimers.Create, i)
-- 					break
-- 				end
-- 			end
-- 		end
-- 	end)
-- end

-- timer.Create("GProfiler_ClearTimerList", 2, 0, function() -- because apparently table.remove does NOT want to work sometimes?? fixme
-- 	for i = #GProfiler.ActiveTimers.Create, 1, -1 do
-- 		local data = GProfiler.ActiveTimers.Create[i]
-- 		if not timer.Exists(data.Name) then
-- 			table.remove(GProfiler.ActiveTimers.Create, i)
-- 		end
-- 	end

-- 	for i = #GProfiler.ActiveTimers.Simple, 1, -1 do
-- 		local data = GProfiler.ActiveTimers.Simple[i]
-- 		if SysTime() >= data.NextRun then
-- 			table.remove(GProfiler.ActiveTimers.Simple, i)
-- 		end
-- 	end
-- end)

-- if SERVER then
-- 	util.AddNetworkString("GProfiler_Timers_ToggleServerProfile")
-- 	util.AddNetworkString("GProfiler_Timers_ServerProfileStatus")
-- 	util.AddNetworkString("GProfiler_Timers_SendData")

-- 	net.Receive("GProfiler_Timers_ToggleServerProfile", function(len, ply)
-- 		if not GProfiler.Access.HasAccess(ply) then return end

-- 		if net.ReadBool() then
-- 			GProfiler.Timers:StartProfiler(ply)
-- 			net.Start("GProfiler_Timers_ServerProfileStatus")
-- 			net.WriteBool(true)
-- 			net.WriteEntity(ply)
-- 			net.Broadcast()
-- 		else
-- 			GProfiler.Timers:Stop(ply)
-- 			net.Start("GProfiler_Timers_ServerProfileStatus")
-- 			net.WriteBool(false)
-- 			net.WriteEntity(ply)
-- 			net.Broadcast()
-- 		end
-- 	end)
-- end