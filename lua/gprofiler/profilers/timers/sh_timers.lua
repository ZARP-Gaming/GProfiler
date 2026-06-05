GProfiler.Timers = GProfiler.Timers or {}
GProfiler.Timers.ActiveTimers = GProfiler.Timers.ActiveTimers or { Simple = {}, Create = {} }
GProfiler.Timers.OldSimpleTimer = GProfiler.Timers.OldSimpleTimer or timer.Simple
GProfiler.Timers.OldCreateTimer = GProfiler.Timers.OldCreateTimer or timer.Create

local Timers = GProfiler.Timers
local ActiveTimers = Timers.ActiveTimers

GProfiler.Profilers.Register("Timers", {})

local chunkSizeLimit = 65535

function Timers:StartProfiler(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) then return end

	if Timers.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " timer profiler started!", 2)
	Timers.IsDetoured = true

	Timers.Simple = {}
	Timers.Create = {}
end

function Timers:Stop(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) then return end

	if not Timers.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " timer profile stopped, sending data!", 2)
	Timers.IsDetoured = false
end

local function SendData(ply)
	if SERVER then
		local ProfileData = table.Merge(Timers.Simple, Timers.Create)
		local chunkCount = 1
		local currentChunkSize = 0
		local chunks = {}
		for k, v in pairs(ProfileData) do
			local chunkSize = 146 + string.len(v.Type) + string.len(tostring(k)) + string.len(v.Source)
			if currentChunkSize + chunkSize > chunkSizeLimit then
				chunkCount = chunkCount + 1
				currentChunkSize = 0
			end

			if not chunks[chunkCount] then chunks[chunkCount] = {} end
			currentChunkSize = currentChunkSize + chunkSize
			table.insert(chunks[chunkCount], {k, v})
		end

		for k, v in ipairs(chunks) do
			net.Start("GProfiler_Timers_SendData")
				net.WriteBool(k == 1)
				net.WriteBool(k == table.Count(chunks))
				net.WriteUInt(table.Count(v), 32)
				for _, data in ipairs(v) do
					local dat = data[2]
					net.WriteString(dat.Type)
					net.WriteString(tostring(data[1]))
					net.WriteUInt(dat.Count, 15)
					net.WriteFloat(dat.Delay)
					net.WriteFloat(dat.TotalTime)
					net.WriteFloat(dat.LongestTime)
					net.WriteFloat(dat.AverageTime)
					net.WriteString(dat.Source)
					net.WriteUInt(dat.Lines[1], 14)
					net.WriteUInt(dat.Lines[2], 14)
				end
			net.Send(ply)
		end

		if table.Count(chunks) == 0 then
			net.Start("GProfiler_Timers_SendData")
				net.WriteBool(true)
				net.WriteBool(true)
				net.WriteUInt(0, 32)
			net.Send(ply)
		end
	end
end

function Timers.CollectTimerData(type, name, delay, func, funcTime)
	if not Timers.IsDetoured then return end

	if not Timers[type][name] then
		local dbgInfo = debug.getinfo(func, "S")
		Timers[type][name] = {
			Count = 0,
			TotalTime = 0,
			LongestTime = 0,
			AverageTime = 0,
			Func = func,
			Delay = delay,
			Source = dbgInfo.short_src,
			Lines = {dbgInfo.linedefined, dbgInfo.lastlinedefined},
			Type = type
		}
	end

	local tbl = Timers[type][name]
	tbl.Count = tbl.Count + 1
	tbl.TotalTime = tbl.TotalTime + funcTime
	tbl.AverageTime = tbl.TotalTime / tbl.Count
	tbl.LongestTime = math.max(tbl.LongestTime, funcTime)
end

local function assertType(value, check, num, expect)
	assert(check(value), string.format("bad argument #%d (%s expected, got %s (%s))", num, expect, type(value), tostring(value)))
	return true
end

timer.Simple = function(delay, func, ...)
	delay = tonumber(delay or 0)
	if not assertType(delay, isnumber, 1, "number") or not assertType(func, isfunction, 2, "function") then return end

	local Index = delay != 0 and table.insert(ActiveTimers.Simple, {NextRun = SysTime() + delay, Source = debug.getinfo(2)})

	local dbgInfo = debug.getinfo(func, "S")
	local sourceKey = string.format("%s:%d", dbgInfo.short_src, dbgInfo.linedefined)

	local args = {...}
	Timers.OldSimpleTimer(delay, function()
		local start = SysTime()
		func(unpack(args))
		Timers.CollectTimerData("Simple", sourceKey, delay, func, SysTime() - start)
		if Index then table.remove(ActiveTimers.Simple, Index) end
	end)
end

timer.Create = function(name, delay, reps, func)
	if not (
		assertType(name, isstring, 1, "string") and
		assertType(delay, isnumber, 2, "number") and
		assertType(reps, isnumber, 3, "number") and
		assertType(func, isfunction, 4, "function")
	) then return end

	name = tostring(name)

	for k, v in ipairs(ActiveTimers.Create) do
		if v.Name == name then
			table.remove(ActiveTimers.Create, k)
			break
		end
	end
	table.insert(ActiveTimers.Create, { Name = name, Reps = reps, Source = debug.getinfo(2) })

	Timers.OldCreateTimer(name, delay, reps, function()
		local start = SysTime()
		func()
		local endtime = SysTime() - start
		Timers.CollectTimerData("Create", name, delay, func, endtime)
		if timer.RepsLeft(name) == 0 then
			for i, data in ipairs(ActiveTimers.Create) do
				if data.Name == name then
					table.remove(ActiveTimers.Create, i)
					break
				end
			end
		end
	end)
end

timer.Create("GProfiler_ClearTimerList", 2, 0, function() -- because apparently table.remove does NOT want to work sometimes?? fixme
	for i = #ActiveTimers.Create, 1, -1 do
		local data = ActiveTimers.Create[i]
		if not timer.Exists(data.Name) then
			table.remove(ActiveTimers.Create, i)
		end
	end

	for i = #ActiveTimers.Simple, 1, -1 do
		local data = ActiveTimers.Simple[i]
		if SysTime() >= data.NextRun then
			table.remove(ActiveTimers.Simple, i)
		end
	end
end)

GProfiler.Profilers.Register("Timers", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		Timers:StartProfiler(ply)
	end,
	OnStop = function(realm, ply)
		Timers:Stop(ply)
		if CLIENT then
			local Store = GProfiler.Profilers.GetStore("Timers")
			if Store then
				Store:SetData(realm, {
					Simple = Timers.Simple,
					Create = Timers.Create
				})
			end
		end
		if SERVER and ply then
			SendData(ply)
		end
	end,
	WriteData = function(realm, ply)
		SendData(ply)
	end
})


if SERVER then
	util.AddNetworkString("GProfiler_Timers_ToggleServerProfile")
	util.AddNetworkString("GProfiler_Timers_ServerProfileStatus")
	util.AddNetworkString("GProfiler_Timers_SendData")
	util.AddNetworkString("GProfiler_Timers_ActiveList")

	net.Receive("GProfiler_Timers_ActiveList", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		net.Start("GProfiler_Timers_ActiveList")
		net.WriteUInt(#ActiveTimers.Create, 16)
		for _, v in ipairs(ActiveTimers.Create) do
			net.WriteString(v.Name)
		end
		net.Send(ply)
	end)

	net.Receive("GProfiler_Timers_ToggleServerProfile", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		if net.ReadBool() then
			Timers:StartProfiler(ply)
			net.Start("GProfiler_Timers_ServerProfileStatus")
			net.WriteBool(true)
			net.WriteEntity(ply)
			net.Broadcast()
		else
			Timers:Stop(ply)
			net.Start("GProfiler_Timers_ServerProfileStatus")
			net.WriteBool(false)
			net.WriteEntity(ply)
			net.Broadcast()
		end
	end)
end

-- local function simplySimple()
-- 	timer.Simple(math.Rand(0.1, 1), function()
-- 		simplySimple()
-- 	end)
-- end
-- simplySimple()

-- timer.Create("GProfiler_TestTimer", math.Rand(0.1, 1), 0, function() end)

-- local function simplySimple2()
-- 	timer.Simple(math.Rand(0.1, 1), function()
-- 		simplySimple2()
-- 	end)
-- end
-- simplySimple2()