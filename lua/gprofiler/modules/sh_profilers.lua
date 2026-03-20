GProfiler.Profilers = GProfiler.Profilers or {}
GProfiler.Profilers.Registered = GProfiler.Profilers.Registered or {}

local Profilers = GProfiler.Profilers
local SysTime = SysTime

if SERVER then
	util.AddNetworkString("GProfiler.Profiler.Status")
	util.AddNetworkString("GProfiler.Profiler.Toggle")
	util.AddNetworkString("GProfiler.Profiler.RequestData")
	util.AddNetworkString("GProfiler.Profiler.SyncState")
end

local function CreateStore(name, opts)
	local Store = {}

	Store.Name = name
	Store.Realms = opts.Realms or { "Client", "Server" }
	Store.ServerOnly = opts.ServerOnly or false

	Store.Active = {}
	Store.StartTime = {}
	Store.EndTime = {}
	Store.Data = {}
	Store.Version = {}
	Store.StartedBy = {}

	for _, realm in ipairs(Store.Realms) do
		Store.Active[realm] = false
		Store.StartTime[realm] = 0
		Store.EndTime[realm] = 0
		Store.Data[realm] = {}
		Store.Version[realm] = 0
	end

	function Store:IsActive(realm)
		return self.Active[realm] or false
	end

	function Store:GetData(realm)
		return self.Data[realm]
	end

	function Store:SetData(realm, data)
		self.Data[realm] = data
		self.Version[realm] = (self.Version[realm] or 0) + 1
	end

	function Store:Start(realm, ply)
		if self.Active[realm] then return false end
		self.Active[realm] = true
		self.StartTime[realm] = SysTime()
		self.EndTime[realm] = 0
		self.Data[realm] = {}
		self.StartedBy[realm] = ply
		return true
	end

	function Store:Stop(realm, ply)
		if not self.Active[realm] then return false end
		self.Active[realm] = false
		self.EndTime[realm] = SysTime()
		return true
	end

	function Store:GetTimerData(realm)
		if not realm then realm = "Client" end
		return {
			StartTime = self.StartTime[realm] or 0,
			EndTime = self.EndTime[realm] or 0,
			ProfileActive = self.Active[realm] or false
		}
	end

	return Store
end

function Profilers.Register(name, opts)
	opts = opts or {}
	local profiler = {
		Name = name,
		Store = CreateStore(name, opts),
		Realms = opts.Realms or { "Client", "Server" },
		ServerOnly = opts.ServerOnly or false,
		OnStart = opts.OnStart,
		OnStop = opts.OnStop,
		WriteData = opts.WriteData,
		ReadData = opts.ReadData,
		OnDataReceived = opts.OnDataReceived,
	}

	Profilers.Registered[name] = profiler
	return profiler.Store
end

function Profilers.Get(name)
	return Profilers.Registered[name]
end

function Profilers.GetStore(name)
	local p = Profilers.Registered[name]
	return p and p.Store
end

function Profilers.GetAll()
	return Profilers.Registered
end

if SERVER then
	local function BroadcastStatus(name, realm, active, ply)
		local store = Profilers.Get(name).Store
		net.Start("GProfiler.Profiler.Status")
		net.WriteString(name)
		net.WriteString(realm)
		net.WriteBool(active)
		net.WriteEntity(ply)
		net.WriteFloat(active and (SysTime() - store.StartTime[realm]) or 0)
		net.Broadcast()
	end

	net.Receive("GProfiler.Profiler.Toggle", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local name = net.ReadString()
		local realm = net.ReadString()
		local start = net.ReadBool()

		local profiler = Profilers.Get(name)
		if not profiler then return end
		if realm ~= "Server" then return end

		if start then
			if not profiler.Store:Start(realm, ply) then return end
			if profiler.OnStart then profiler.OnStart(realm, ply) end
			BroadcastStatus(name, realm, true, ply)
		else
			if profiler.OnStop then profiler.OnStop(realm, ply) end
			if not profiler.Store:Stop(realm, ply) then return end
			BroadcastStatus(name, realm, false, ply)
		end
	end)

	net.Receive("GProfiler.Profiler.RequestData", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local name = net.ReadString()
		local profiler = Profilers.Get(name)
		if not profiler then return end

		if profiler.WriteData then
			profiler.WriteData("Server", ply)
		end
	end)

	net.Receive("GProfiler.Profiler.SyncState", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local count = 0
		local active = {}
		for name, profiler in pairs(Profilers.Registered) do
			if profiler.Store:IsActive("Server") then
				count = count + 1
				active[name] = profiler
			end
		end

		net.Start("GProfiler.Profiler.SyncState")
		net.WriteUInt(count, 8)
		for name, profiler in pairs(active) do
			net.WriteString(name)
			net.WriteFloat(SysTime() - profiler.Store.StartTime["Server"])
			net.WriteEntity(profiler.Store.StartedBy["Server"] or Entity(0))
		end
		net.Send(ply)
	end)

	hook.Add("PlayerInitialSpawn", "GProfiler.SyncState", function(ply)
		timer.Simple(1, function()
			if not IsValid(ply) then return end
			if not GProfiler.Access.HasAccess(ply) then return end

			local count = 0
			local active = {}
			for name, profiler in pairs(Profilers.Registered) do
				if profiler.Store:IsActive("Server") then
					count = count + 1
					active[name] = profiler
				end
			end

			if count == 0 then return end

			net.Start("GProfiler.Profiler.SyncState")
			net.WriteUInt(count, 8)
			for name, profiler in pairs(active) do
				net.WriteString(name)
				net.WriteFloat(SysTime() - profiler.Store.StartTime["Server"])
				net.WriteEntity(profiler.Store.StartedBy["Server"] or Entity(0))
			end
			net.Send(ply)
		end)
	end)

	return
end

net.Receive("GProfiler.Profiler.Status", function()
	local name = net.ReadString()
	local realm = net.ReadString()
	local active = net.ReadBool()
	local ply = net.ReadEntity()
	local startTime = net.ReadFloat()

	local profiler = Profilers.Get(name)
	if not profiler then return end

	if active then
		profiler.Store.Active[realm] = true
		profiler.Store.StartTime[realm] = SysTime() - startTime
		profiler.Store.EndTime[realm] = 0
		profiler.Store.StartedBy[realm] = ply
	else
		profiler.Store.Active[realm] = false
		profiler.Store.EndTime[realm] = SysTime()
	end

	hook.Run("GProfiler.Profiler.StatusChanged", name, realm, active, ply)
end)

net.Receive("GProfiler.Profiler.SyncState", function()
	local count = net.ReadUInt(8)
	for i = 1, count do
		local name = net.ReadString()
		local elapsed = net.ReadFloat()
		local ply = net.ReadEntity()

		local profiler = Profilers.Get(name)
		if not profiler then continue end

		profiler.Store.Active["Server"] = true
		profiler.Store.StartTime["Server"] = SysTime() - elapsed
		profiler.Store.EndTime["Server"] = 0
		profiler.Store.StartedBy["Server"] = ply

		hook.Run("GProfiler.Profiler.StatusChanged", name, "Server", true, ply)
	end
end)

function Profilers.Toggle(name, realm, start)
	local profiler = Profilers.Get(name)
	if not profiler then return end

	if realm == "Both" then
		Profilers.Toggle(name, "Client", start)
		Profilers.Toggle(name, "Server", start)
		return
	end

	if realm == "Client" then
		if start then
			if not profiler.Store:Start(realm) then return end
			if profiler.OnStart then profiler.OnStart(realm) end
		else
			if profiler.OnStop then profiler.OnStop(realm) end
			profiler.Store:Stop(realm)
		end
		hook.Run("GProfiler.Profiler.StatusChanged", name, realm, start)
	else
		net.Start("GProfiler.Profiler.Toggle")
		net.WriteString(name)
		net.WriteString(realm)
		net.WriteBool(start)
		net.SendToServer()
	end
end

function Profilers.RequestData(name, callback)
	local profiler = Profilers.Get(name)
	if not profiler then return end

	if callback then
		profiler._DataCallback = callback
	end

	net.Start("GProfiler.Profiler.RequestData")
	net.WriteString(name)
	net.SendToServer()
end
