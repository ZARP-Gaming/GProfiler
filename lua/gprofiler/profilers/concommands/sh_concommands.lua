GProfiler.ConCommands = GProfiler.ConCommands or {}
GProfiler.ConCommands.ProfileData = GProfiler.ConCommands.ProfileData or {}
GProfiler.ConCommands.IsDetoured = GProfiler.ConCommands.IsDetoured or false

local SysTime = SysTime
local math = math

function GProfiler.ConCommands.GetFunction(cmd, tbl)
	local commands = tbl or concommand.GetTable()
	local command = commands[cmd]

	if not command then return "Unknown", 0, 0 end

	local dbgInfo = debug.getinfo(command)
	return dbgInfo.short_src, dbgInfo.linedefined, dbgInfo.lastlinedefined
end

local function StartDetour()
	if GProfiler.ConCommands.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " commands profiler started!", 2)
	GProfiler.ConCommands.OldRun = GProfiler.ConCommands.OldRun or concommand.Run
	GProfiler.ConCommands.ProfileData = {}
	GProfiler.ConCommands.IsDetoured = true

	concommand.Run = function(ply, cmd, ...)
		local start = SysTime()
		local ret = GProfiler.ConCommands.OldRun(ply, cmd, ...)
		local time = SysTime() - start

		if not GProfiler.ConCommands.ProfileData[cmd] then
			local source, lineStart, lineEnd = GProfiler.ConCommands.GetFunction(cmd)
			GProfiler.ConCommands.ProfileData[cmd] = {
				Count = 0,
				Time = 0,
				AverageTime = 0,
				LongestTime = 0,
				Source = source,
				Lines = {lineStart, lineEnd}
			}
		end

		local Data = GProfiler.ConCommands.ProfileData[cmd]
		Data.Count = Data.Count + 1
		Data.Time = Data.Time + time
		Data.AverageTime = Data.Time / Data.Count
		Data.LongestTime = math.max(Data.LongestTime, time)

		return ret
	end
end

local function StopDetour()
	if not GProfiler.ConCommands.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " commands profile stopped!", 2)
	GProfiler.ConCommands.IsDetoured = false
	concommand.Run = GProfiler.ConCommands.OldRun
end

local function SendData(ply)
	net.Start("GProfiler_ConCommands_SendData")
		net.WriteUInt(table.Count(GProfiler.ConCommands.ProfileData), 32)
		for k, v in pairs(GProfiler.ConCommands.ProfileData) do
			net.WriteString(k)
			net.WriteUInt(v.Count, 32)
			net.WriteFloat(v.Time)
			net.WriteFloat(v.AverageTime)
			net.WriteFloat(v.LongestTime)
			net.WriteString(v.Source)
			net.WriteUInt(v.Lines[1], 16)
			net.WriteUInt(v.Lines[2], 16)
		end
	net.Send(ply)
end

GProfiler.Profilers.Register("Commands", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		StartDetour()
	end,
	OnStop = function(realm, ply)
		StopDetour()
		if CLIENT then
			local CmdStore = GProfiler.Profilers.GetStore("Commands")
			if CmdStore then
				CmdStore:SetData(realm, GProfiler.ConCommands.ProfileData)
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
	util.AddNetworkString("GProfiler_ConCommands_CommandList")
	util.AddNetworkString("GProfiler_ConCommands_SendData")

	net.Receive("GProfiler_ConCommands_CommandList", function(_, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local commandList = {}
		for k, v in pairs(concommand.GetTable()) do
			local source, lineStart, lineEnd = GProfiler.ConCommands.GetFunction(k, concommand.GetTable())
			commandList[k] = {Source = source, Lines = {lineStart, lineEnd}}
		end

		net.Start("GProfiler_ConCommands_CommandList")
			net.WriteUInt(table.Count(commandList), 32)
			for k, v in pairs(commandList) do
				net.WriteString(k)
				net.WriteString(v.Source)
				net.WriteUInt(v.Lines[1], 16)
				net.WriteUInt(v.Lines[2], 16)
			end
		net.Send(ply)
	end)
end