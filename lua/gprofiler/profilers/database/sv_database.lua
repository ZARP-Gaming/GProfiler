GProfiler.Database = GProfiler.Database or {}
GProfiler.Database.ProfileData = GProfiler.Database.ProfileData or {}
GProfiler.Database.IsDetoured = GProfiler.Database.IsDetoured or false
GProfiler.Database.Explains = GProfiler.Database.Explains or {}
GProfiler.Database.SeenQuery = GProfiler.Database.SeenQuery or {}
GProfiler.Database.InternalProfileData = GProfiler.Database.InternalProfileData or {}
GProfiler.Database.QueryIdCounter = GProfiler.Database.QueryIdCounter or 0

local ProviderLoader = include("providers/base/sv_provider_loader.lua")
local availableProviders = ProviderLoader.Initialize()

local IDLookup = {
	["mysqloo"] = 1,
	["tmysql4"] = 2,
	["goobie_mysql"] = 3,
	["sqlite"] = 4
}

-- TODO: Express Networking Support!

function GProfiler.Database:StartProfiler(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or GProfiler.Database.IsDetoured then return end

	GProfiler.Log("Server database profiler started!", 2)

	GProfiler.Database.ProfileData = {}
	GProfiler.Database.Explains = {}
	GProfiler.Database.SeenQuery = {}
	GProfiler.Database.QueryIdCounter = 0
	GProfiler.Database.QueryMapping = {}
	GProfiler.Database.IsDetoured = true
	GProfiler.Database.ProfileStarted = SysTime()

	for name, provider in pairs(availableProviders) do
		provider:StartProfiling()
	end
end

function GProfiler.Database:StopProfiler(ply)
	if not GProfiler.Access.HasAccess(ply or LocalPlayer()) or not GProfiler.Database.IsDetoured then return end

	GProfiler.Log((SERVER and "Server" or "Client") .. " database profiler stopped, sending data!", 2)
	GProfiler.Database.IsDetoured = false
	GProfiler.Database.ProfileStarted = nil

	for name, provider in pairs(availableProviders) do
		provider:StopProfiling()
	end

	if table.Count(GProfiler.Database.ProfileData) == 0 then
		net.Start("GProfiler_Database_SendData")
		net.WriteBool(true)
		net.WriteBool(true)
		net.WriteUInt(0, 32)
		net.WriteUInt(0, 32)
		net.Send(ply)
		return
	end

	local sent = false
	local function SendData()
		if sent then return end
		sent = true

		local function SendChunk(ply, profileData, explains, startIndex, chunkSize)
			if not IsValid(ply) then return end
			net.Start("GProfiler_Database_SendData")
			net.WriteBool(startIndex == 1)
			local endIndex = math.min(startIndex + chunkSize - 1, table.Count(profileData))
			net.WriteBool(endIndex == table.Count(profileData))
			net.WriteUInt(endIndex - startIndex + 1, 14)
			local index = 0
			for k, v in pairs(profileData) do
				index = index + 1
				if index >= startIndex and index <= endIndex then
					local FlattenQuery = v.Query:gsub("%s+", " "):Trim():lower()
					if FlattenQuery:EndsWith(";") then FlattenQuery = FlattenQuery:sub(1, -2) end
					local internalData = GProfiler.Database.InternalProfileData[FlattenQuery]
					if not internalData then
						for k2, v2 in pairs(GProfiler.Database.InternalProfileData) do
							local k2Flat = k2:gsub("%s+", " "):Trim():lower()
							if k2Flat:EndsWith(";") then k2Flat = k2Flat:sub(1, -2) end
							if FlattenQuery:StartsWith(k2Flat) then
								internalData = v2
								break
							end
						end
					end
					net.WriteUInt(k, 14)
					net.WriteUInt(IDLookup[v.Type] or 0, 3)
					net.WriteUInt(v.Count, 14)
					net.WriteFloat(v.Time)
					net.WriteFloat(internalData and internalData.Duration or v.AverageTime)
					net.WriteFloat(v.LongestTime)
					net.WriteString(v.Query or "")
					net.WriteString(v.Source[1] or "Unknown")
					net.WriteUInt(v.Source[2] or 0, 16)
					net.WriteUInt(v.Source[3] or 0, 16)
					if internalData then
						net.WriteBool(true)
						local count = table.Count(internalData.ProfileData)
						net.WriteUInt(count, 7)
						for k2, v2 in ipairs(internalData.ProfileData) do
							net.WriteFloat(v2.Duration or 0)
							net.WriteString(v2.Status or "Unknown")
						end
					else
						net.WriteBool(false)
					end
				end
			end
			if endIndex == table.Count(profileData) then
				net.WriteUInt(table.Count(explains), 14)
				for k, v in pairs(explains) do
					net.WriteUInt(k, 14)
					if v.noExplain then
						net.WriteBool(true)
					else
						net.WriteBool(false)
						net.WriteUInt(table.Count(v), 6)
						for i, explain in ipairs(v) do
							net.WriteString(explain.select_type or "")
							net.WriteString(explain.table or "")
							net.WriteString(explain.type or "")
							net.WriteString(explain.possible_keys or "")
							net.WriteString(explain.key or "")
							net.WriteString(explain.key_len or "")
							net.WriteString(explain.ref or "")
							net.WriteUInt(explain.rows or 0, 32)
							net.WriteString(explain.Extra or "")
						end
					end
				end
			else
				net.WriteUInt(0, 32)
			end
			net.Send(ply)
		end

		local chunkSize = 20
		local totalProfiles = table.Count(GProfiler.Database.ProfileData)
		for startIndex = 1, totalProfiles, chunkSize do
			timer.Simple(0.1, function()
				SendChunk(ply, GProfiler.Database.ProfileData, GProfiler.Database.Explains, startIndex, chunkSize)
			end)
		end
	end

	local providersToWaitFor = 0
	local allProfilingData = {}

	for name, provider in pairs(availableProviders) do
		providersToWaitFor = providersToWaitFor + 1
		provider:GetProfilingData(function(data)
			providersToWaitFor = providersToWaitFor - 1

			if data then
				for query, profile in pairs(data) do
					allProfilingData[query] = profile
				end
			end

			if providersToWaitFor == 0 then
				GProfiler.Database.InternalProfileData = allProfilingData
				SendData()
			end
		end)
	end

	if providersToWaitFor == 0 then
		SendData()
	end
end

function GProfiler.Database:GetAllDatabaseObjects()
	local objects = {}
	for name, provider in pairs(availableProviders) do
		for _, obj in pairs(provider.Objects) do
			table.insert(objects, obj)
		end
	end
	return objects
end

function GProfiler.Database:GetProvider(name)
	return availableProviders[name]
end

function GProfiler.Database:GetAvailableProviders()
	return availableProviders
end

util.AddNetworkString("GProfiler_Database_ToggleServerProfile")
util.AddNetworkString("GProfiler_Database_ServerProfileStatus")
util.AddNetworkString("GProfiler_Database_SendData")

net.Receive("GProfiler_Database_ToggleServerProfile", function(len, ply)
	if not GProfiler.Access.HasAccess(ply) then return end

	if net.ReadBool() then
		GProfiler.Database:StartProfiler(ply)
		net.Start("GProfiler_Database_ServerProfileStatus")
		net.WriteBool(true)
		net.WriteEntity(ply)
		net.Broadcast()
	else
		GProfiler.Database:StopProfiler(ply)
		net.Start("GProfiler_Database_ServerProfileStatus")
		net.WriteBool(false)
		net.WriteEntity(ply)
		net.Broadcast()
	end
end)