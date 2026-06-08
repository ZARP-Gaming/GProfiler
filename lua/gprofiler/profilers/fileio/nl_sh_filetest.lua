GProfiler.FileIO = GProfiler.FileIO or {}
local FileIO = GProfiler.FileIO
FileIO._TestLeaks = FileIO._TestLeaks or {}

local TEST_DIR = "gprofiler_test"

local function WriteStuff()
	for i = 1, 5 do
		file.Write(TEST_DIR .. "/data_" .. i .. ".txt", string.rep("line " .. i .. " of the file\n", i * 25))
	end
	file.Append(TEST_DIR .. "/data_1.txt", "appended at " .. os.time() .. "\n")
	file.Append(TEST_DIR .. "/data_2.txt", "more appended text\n")
end

local function ReadStuff()
	for i = 1, 5 do
		file.Read(TEST_DIR .. "/data_" .. i .. ".txt", "DATA")
	end
	for i = 1, 15 do
		file.Read(TEST_DIR .. "/data_3.txt", "DATA")
	end
end

local function WriteHandle()
	local f = file.Open(TEST_DIR .. "/binary.dat", "wb", "DATA")
	if not f then return end
	for i = 1, 64 do
		f:WriteByte(i % 256)
		f:WriteShort(i * 7)
		f:WriteUShort(i * 3)
		f:WriteLong(i * 1000)
		f:WriteULong(i * 1500)
		f:WriteFloat(i / 3)
		f:WriteDouble(i / 7)
		f:WriteBool(i % 2 == 0)
		f:WriteUInt64(tostring(i * 100000))
	end
	f:Write("trailing string payload for the binary file")
	f:Flush()
	f:Close()
end

local function ReadHandle()
	local r = file.Open(TEST_DIR .. "/binary.dat", "rb", "DATA")
	if not r then return end
	r:Size()
	for i = 1, 64 do
		r:ReadByte()
		r:ReadShort()
		r:ReadUShort()
		r:ReadLong()
		r:ReadULong()
		r:ReadFloat()
		r:ReadDouble()
		r:ReadBool()
		r:ReadUInt64()
	end
	r:Tell()
	r:Seek(0)
	r:Skip(8)
	r:EndOfFile()
	r:Close()
end

local function LineHandle()
	local lf = file.Open(TEST_DIR .. "/data_2.txt", "r", "DATA")
	if not lf then return end
	while not lf:EndOfFile() do
		local line = lf:ReadLine()
		if line == nil then break end
	end
	lf:Close()
end

local function MetaStuff()
	file.Exists(TEST_DIR .. "/data_1.txt", "DATA")
	file.IsDir(TEST_DIR, "DATA")
	file.Size(TEST_DIR .. "/data_1.txt", "DATA")
	file.Time(TEST_DIR .. "/data_4.txt", "DATA")
	file.Find(TEST_DIR .. "/*", "DATA")
	file.Find(TEST_DIR .. "/*.txt", "DATA")
	file.Delete(TEST_DIR .. "/data_5.txt")
end

local function LeakHandle()
	local leak = file.Open(TEST_DIR .. "/leaked.txt", "w", "DATA")
	if not leak then return end
	leak:Write("this handle is intentionally never closed\n")
	leak:WriteLong(1337)
	leak:Flush()
	FileIO._TestLeaks[#FileIO._TestLeaks + 1] = leak
end

local function RunFileTest()
	file.CreateDir(TEST_DIR)
	WriteStuff()
	ReadStuff()
	WriteHandle()
	ReadHandle()
	LineHandle()
	MetaStuff()
	LeakHandle()
	GProfiler.Log("file test battery complete (" .. (SERVER and "server" or "client") .. ")", 2)
end

if SERVER then
	util.AddNetworkString("GProfiler_FileIO_Test")

	net.Receive("GProfiler_FileIO_Test", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end
		RunFileTest()
	end)
end

concommand.Add("gprofiler_filetest", function(ply, cmd, args)
	if CLIENT then
		net.Start("GProfiler_FileIO_Test")
		net.SendToServer()
	end
	RunFileTest()
end)
