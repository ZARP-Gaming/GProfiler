GProfiler.FileIO = GProfiler.FileIO or {}
local FileIO = GProfiler.FileIO
FileIO.IsDetoured = FileIO.IsDetoured or false
FileIO.OrigLib = FileIO.OrigLib or {}
FileIO.OrigFile = FileIO.OrigFile or {}

local SysTime = SysTime
local debug = debug

local FileMeta = FindMetaTable("File")

local libSpecs = {
	{ "Read", "read" },
	{ "Write", "write" },
	{ "Append", "write" },
	{ "Open", "open" },
	{ "Exists", "meta" },
	{ "IsDir", "meta" },
	{ "Size", "meta" },
	{ "Time", "meta" },
	{ "Delete", "meta" },
	{ "CreateDir", "meta" },
	{ "Find", "find" },
	{ "Rename", "meta" },
	{ "AsyncRead", "meta" }
}

local fileSpecs = {
	{ "Read", "read" },
	{ "ReadLine", "read" },
	{ "ReadBool", "read", 1 },
	{ "ReadByte", "read", 1 },
	{ "ReadShort", "read", 2 },
	{ "ReadUShort", "read", 2 },
	{ "ReadLong", "read", 4 },
	{ "ReadFloat", "read", 4 },
	{ "ReadDouble", "read", 8 },
	{ "ReadUInt64", "read", 8 },
	{ "ReadULong", "read", 4 },
	{ "Write", "write" },
	{ "WriteBool", "write", 1 },
	{ "WriteByte", "write", 1 },
	{ "WriteShort", "write", 2 },
	{ "WriteUShort", "write", 2 },
	{ "WriteLong", "write", 4 },
	{ "WriteFloat", "write", 4 },
	{ "WriteDouble", "write", 8 },
	{ "WriteUInt64", "write", 8 },
	{ "WriteULong", "write", 4 },
	{ "Seek", "meta" },
	{ "Tell", "meta" },
	{ "Size", "meta" },
	{ "Skip", "meta" },
	{ "Flush", "meta" },
	{ "EndOfFile", "meta" },
	{ "Close", "close" }
}

local function NewData()
	return { Ops = {}, Files = {}, Callers = {}, Handles = {} }
end

FileIO.Data = FileIO.Data or NewData()
local HandleMap = setmetatable({}, { __mode = "k" })

local PARAM_LIMIT = 50
local SEQ_LIMIT = 250

local g_depth = 0
local g_src, g_line

local function EnterCall()
	if g_depth == 0 then
		local info = debug.getinfo(3, "Sl")
		if info then
			g_src = info.short_src
			g_line = info.currentline
		else
			g_src = "?"
			g_line = 0
		end
	end
	g_depth = g_depth + 1
end

local function LeaveCall()
	g_depth = g_depth - 1
	if g_depth <= 0 then
		g_depth = 0
		g_src = nil
		g_line = nil
	end
end

local function Record(opName, path, ioKind, dt, bytes, src, line, paramSig)
	local D = FileIO.Data
	bytes = bytes or 0

	local o = D.Ops[opName]
	if not o then
		o = { Count = 0, Time = 0, Max = 0, Bytes = 0, Params = {} }
		D.Ops[opName] = o
	end
	o.Count = o.Count + 1
	o.Time = o.Time + dt
	if dt > o.Max then o.Max = dt end
	o.Bytes = o.Bytes + bytes

	if paramSig then
		local p = o.Params[paramSig]
		if not p then
			if table.Count(o.Params) >= PARAM_LIMIT then
				paramSig = "(other)"
				p = o.Params[paramSig]
			end
			if not p then
				p = { Count = 0, Time = 0, Bytes = 0, Src = src or "", Line = line or 0 }
				o.Params[paramSig] = p
			end
		end
		p.Count = p.Count + 1
		p.Time = p.Time + dt
		p.Bytes = p.Bytes + bytes
	end

	if path then
		local f = D.Files[path]
		if not f then
			f = { Reads = 0, Writes = 0, ReadBytes = 0, WriteBytes = 0, Count = 0, Time = 0, Callers = {} }
			D.Files[path] = f
		end
		f.Count = f.Count + 1
		f.Time = f.Time + dt
		if ioKind == "read" then
			f.Reads = f.Reads + 1
			f.ReadBytes = f.ReadBytes + bytes
		elseif ioKind == "write" then
			f.Writes = f.Writes + 1
			f.WriteBytes = f.WriteBytes + bytes
		end

		if src then
			local ckey = src .. ":" .. line
			local fc = f.Callers[ckey]
			if not fc then
				fc = { Src = src, Line = line, Count = 0, Time = 0, Bytes = 0 }
				f.Callers[ckey] = fc
			end
			fc.Count = fc.Count + 1
			fc.Time = fc.Time + dt
			fc.Bytes = fc.Bytes + bytes
		end
	end

	if src then
		local key = src .. ":" .. line
		local c = D.Callers[key]
		if not c then
			c = { Count = 0, Time = 0, Bytes = 0, Src = src, Line = line }
			D.Callers[key] = c
		end
		c.Count = c.Count + 1
		c.Time = c.Time + dt
		c.Bytes = c.Bytes + bytes
	end
end

local function RegisterHandle(handle, path, mode, src, line)
	local rec = {
		Path = path or "?",
		Mode = tostring(mode or "?"),
		Open = SysTime(),
		Duration = 0,
		ReadBytes = 0,
		WriteBytes = 0,
		Ops = 0,
		Leaked = false,
		OpenSrc = src or "",
		OpenLine = line or 0,
		Sequence = { { Label = "Open (" .. tostring(mode or "?") .. ")", Time = 0, Bytes = 0 } },
		SeqTruncated = 0
	}
	FileIO.Data.Handles[#FileIO.Data.Handles + 1] = rec
	HandleMap[handle] = rec
end

local function WrapLib(name, kind)
	local orig = file[name]
	if not orig then return end
	FileIO.OrigLib[name] = orig

	file[name] = function(a1, a2, ...)
		EnterCall()
		local src, line = g_src, g_line

		local t0 = SysTime()
		local res = { pcall(orig, a1, a2, ...) }
		local dt = SysTime() - t0
		LeaveCall()

		if not res[1] then error(res[2], 2) end
		local r1 = res[2]

		local path = isstring(a1) and a1 or nil
		local bytes = 0
		if kind == "read" then
			bytes = isstring(r1) and #r1 or 0
		elseif kind == "write" then
			bytes = isstring(a2) and #a2 or 0
		end

		local paramSig = path or "?"
		if kind == "open" then
			paramSig = paramSig .. " (" .. tostring(a2) .. ")"
			if r1 then
				RegisterHandle(r1, path or "?", a2, src, line)
			end
		end

		Record("file." .. name, path, kind, dt, bytes, src, line, paramSig)

		return unpack(res, 2, table.maxn(res))
	end
end

local function WrapFile(name, kind, fixed)
	local orig = FileMeta[name]
	if not orig then return end
	FileIO.OrigFile[name] = orig

	FileMeta[name] = function(self, a1, ...)
		EnterCall()
		local src, line = g_src, g_line

		local t0 = SysTime()
		local res = { pcall(orig, self, a1, ...) }
		local dt = SysTime() - t0
		LeaveCall()

		if not res[1] then error(res[2], 2) end
		local r1 = res[2]

		local ioKind = (kind == "read" or kind == "write") and kind or "meta"
		local bytes = 0
		if fixed then
			bytes = fixed
		elseif kind == "read" then
			bytes = isstring(r1) and #r1 or 0
		elseif kind == "write" then
			bytes = isstring(a1) and #a1 or 0
		end

		local rec = HandleMap[self]
		if rec then
			rec.Ops = rec.Ops + 1
			if ioKind == "read" then
				rec.ReadBytes = rec.ReadBytes + bytes
			elseif ioKind == "write" then
				rec.WriteBytes = rec.WriteBytes + bytes
			end

			local label = name
			if (name == "Read" or name == "Seek" or name == "Skip") and isnumber(a1) then
				label = name .. "(" .. a1 .. ")"
			elseif ioKind == "write" then
				label = name .. "(" .. bytes .. " B)"
			end

			if #rec.Sequence < SEQ_LIMIT then
				rec.Sequence[#rec.Sequence + 1] = { Label = label, Time = dt, Bytes = bytes }
			else
				rec.SeqTruncated = rec.SeqTruncated + 1
			end

			if kind == "close" then
				rec.Closed = true
				rec.Duration = SysTime() - rec.Open
				HandleMap[self] = nil
			end
		end

		Record("File:" .. name, rec and rec.Path or nil, ioKind, dt, bytes, src, line)

		return unpack(res, 2, table.maxn(res))
	end
end

local function StartDetour()
	if FileIO.IsDetoured then return end
	GProfiler.Log((SERVER and "Server" or "Client") .. " file I/O profiler started!", 2)

	FileIO.Data = NewData()
	FileIO.OrigLib = {}
	FileIO.OrigFile = {}
	HandleMap = setmetatable({}, { __mode = "k" })
	FileIO.IsDetoured = true

	for _, spec in ipairs(libSpecs) do
		WrapLib(spec[1], spec[2])
	end
	for _, spec in ipairs(fileSpecs) do
		WrapFile(spec[1], spec[2], spec[3])
	end
end

local function StopDetour()
	if not FileIO.IsDetoured then return end
	GProfiler.Log((SERVER and "Server" or "Client") .. " file I/O profiler stopped!", 2)
	FileIO.IsDetoured = false

	for name, orig in pairs(FileIO.OrigLib) do file[name] = orig end
	for name, orig in pairs(FileIO.OrigFile) do FileMeta[name] = orig end
	FileIO.OrigLib = {}
	FileIO.OrigFile = {}

	for _, rec in ipairs(FileIO.Data.Handles) do
		if not rec.Closed then
			rec.Leaked = true
			rec.Duration = SysTime() - rec.Open
		end
	end
end

local CHUNK_SIZE = 60000

local function BuildPayload()
	local D = FileIO.Data
	local handles = {}
	for i, h in ipairs(D.Handles) do
		handles[i] = {
			Path = h.Path,
			Mode = h.Mode,
			Duration = h.Duration,
			ReadBytes = h.ReadBytes,
			WriteBytes = h.WriteBytes,
			Ops = h.Ops,
			Leaked = h.Leaked,
			OpenSrc = h.OpenSrc,
			OpenLine = h.OpenLine,
			Sequence = h.Sequence,
			SeqTruncated = h.SeqTruncated
		}
	end
	return { Ops = D.Ops, Files = D.Files, Callers = D.Callers, Handles = handles }
end

local function SendData(ply)
	local json = util.TableToJSON(BuildPayload()) or "{}"
	local compressed = util.Compress(json) or ""
	local total = #compressed

	local chunks = {}
	local pos = 1
	while pos <= total do
		chunks[#chunks + 1] = string.sub(compressed, pos, pos + CHUNK_SIZE - 1)
		pos = pos + CHUNK_SIZE
	end
	if #chunks == 0 then chunks[1] = "" end

	local i = 1
	local function sendChunk()
		if not IsValid(ply) then return end
		local chunk = chunks[i]
		net.Start("GProfiler_FileIO_SendData")
		net.WriteBool(i == 1)
		net.WriteBool(i == #chunks)
		net.WriteUInt(#chunk, 16)
		net.WriteData(chunk, #chunk)
		net.Send(ply)

		i = i + 1
		if chunks[i] then timer.Simple(0.1, sendChunk) end
	end
	sendChunk()
end

GProfiler.Profilers.Register("File I/O", {
	Realms = { "Client", "Server" },
	OnStart = function(realm, ply)
		StartDetour()
	end,
	OnStop = function(realm, ply)
		StopDetour()
		if CLIENT then
			local store = GProfiler.Profilers.GetStore("File I/O")
			if store then store:SetData(realm, FileIO.Data) end
		end
		if SERVER and ply then SendData(ply) end
	end,
	WriteData = function(realm, ply)
		SendData(ply)
	end
})

if SERVER then
	util.AddNetworkString("GProfiler_FileIO_SendData")
end
