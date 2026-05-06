GProfiler.Database = GProfiler.Database or {}
GProfiler.Database.Providers = GProfiler.Database.Providers or {}

local BaseProvider = {}
BaseProvider.__index = BaseProvider
BaseProvider.Name = "Base Provider"
BaseProvider.ModuleName = ""
BaseProvider.QueryFunction = ""
BaseProvider.HasProfiling = false

function BaseProvider:New()
	local provider = setmetatable({}, self)
	provider.Objects = {}
	provider.IsDetoured = false
	provider.OriginalFunctions = {}
	return provider
end

function BaseProvider:IsAvailable()
	if not self.ModuleName or self.ModuleName == "" then return true end
	return util.IsBinaryModuleInstalled(self.ModuleName)
end

function BaseProvider:Initialize()
	if not self:IsAvailable() then
		return false
	end

	if self.ModuleName and self.ModuleName ~= "" then
		require(self.ModuleName)
	end

	self:SetupConnectionHook()
	return true
end

function BaseProvider:SetupConnectionHook()
	error("SetupConnectionHook must be implemented by provider: " .. self.Name)
end

function BaseProvider:AddDatabaseObject(object, meta)
	local objectData = {
		object = object,
		meta = meta,
		type = self.Name,
		qfunc = self.QueryFunction,
		oldQueryFunc = nil,
		oldQueryFuncs = {},
		hasProfiling = false
	}

	table.insert(self.Objects, objectData)
	GProfiler.Log("New database object found (" .. self.Name .. "): " .. tostring(object), 1)

	if self.IsDetoured then
		if self:ValidateObject(objectData) then
			self:DetourQueryFunction(objectData)
			self:EnableSQLProfiling(objectData)
			GProfiler.Log("Detoured new object created during an active profiling session (" .. self.Name .. "): " .. tostring(object), 1)
		end
	end
end

function BaseProvider:StartProfiling()
	if self.IsDetoured then return end

	self.IsDetoured = true

	for k, v in pairs(self.Objects) do
		if not self:ValidateObject(v) then
			self.Objects[k] = nil
			continue
		end

		self:DetourQueryFunction(v)
		self:EnableSQLProfiling(v)
	end
end

function BaseProvider:StopProfiling()
	if not self.IsDetoured then return end

	self.IsDetoured = false

	for k, v in pairs(self.Objects) do
		if v.oldQueryFunc or (v.oldQueryFuncs and next(v.oldQueryFuncs)) then
			self:RestoreQueryFunction(v)
			self:DisableSQLProfiling(v)
		end
	end
end

function BaseProvider:ValidateObject(objectData)
	if self.QueryMethods then
		local target = objectData.meta or objectData.object
		for _, methodName in ipairs(self.QueryMethods) do
			if target[methodName] then
				return true
			end
		end
		GProfiler.Log("Database object " .. tostring(objectData.object) .. " does not have any query methods!", 1)
		return false
	else
		local hasFunc = (objectData.meta and objectData.meta[objectData.qfunc]) or objectData.object[objectData.qfunc]
		if not hasFunc then
			GProfiler.Log("Database object " .. tostring(objectData.object) .. " does not have a query function! (" .. tostring(objectData.qfunc) .. ")", 1)
			return false
		end
		return true
	end
end

function BaseProvider:DetourQueryFunction(objectData)
	error("DetourQueryFunction must be implemented by provider: " .. self.Name)
end

function BaseProvider:RestoreQueryFunction(objectData)
	local target = objectData.meta or objectData.object

	if objectData.oldQueryFuncs and next(objectData.oldQueryFuncs) then
		for methodName, oldFunc in pairs(objectData.oldQueryFuncs) do
			target[methodName] = oldFunc
		end
		for k in pairs(objectData.oldQueryFuncs) do
			objectData.oldQueryFuncs[k] = nil
		end
	elseif objectData.oldQueryFunc then
		target[objectData.qfunc] = objectData.oldQueryFunc
		objectData.oldQueryFunc = nil
	end
end

function BaseProvider:EnableSQLProfiling(objectData) end
function BaseProvider:DisableSQLProfiling(objectData) end

function BaseProvider:GetProfilingData(callback)
	local profilingData = {}
	local waitingFor = 0

	for _, objectData in pairs(self.Objects) do
		if objectData.hasProfiling then
			waitingFor = waitingFor + 1
			self:GetObjectProfilingData(objectData, function(data)
				waitingFor = waitingFor - 1
				if data then
					for query, profile in pairs(data) do
						profilingData[query] = profile
					end
				end

				if waitingFor == 0 then
					callback(profilingData)
				end
			end)
		end
	end

	if waitingFor == 0 then
		callback(profilingData)
	end
end

function BaseProvider:GetObjectProfilingData(objectData, callback)
	callback(nil)
end

function BaseProvider:CreateExplainQuery(queryText, objectData, queryId)
	local trimmed = queryText:Trim():lower()
	if not (trimmed:StartWith("select") or trimmed:StartWith("update") or trimmed:StartWith("delete")) then
		GProfiler.Database.Explains[queryId] = { noExplain = true }
		return
	end

	if GProfiler.Database.Explains[queryId] then return end

	local explainQuery = "EXPLAIN " .. queryText
	GProfiler.Database.Explains[queryId] = {}

	self:ExecuteExplainQuery(explainQuery, objectData, queryId)
end

function BaseProvider:ExecuteExplainQuery(explainQuery, objectData, queryId)
	GProfiler.Database.Explains[queryId] = { noExplain = true }
end

function BaseProvider:GetQueryId(queryIdent)
	local queryKey = self.Name .. "_" .. queryIdent

	if not GProfiler.Database.SeenQuery[queryIdent] then
		GProfiler.Database.SeenQuery[queryIdent] = true
		GProfiler.Database.QueryIdCounter = (GProfiler.Database.QueryIdCounter or 0) + 1
		GProfiler.Database.QueryMapping[queryIdent] = GProfiler.Database.QueryIdCounter
		return GProfiler.Database.QueryIdCounter
	else
		return GProfiler.Database.QueryMapping[queryIdent]
	end
end

function BaseProvider:ProcessQueryResult(queryText, startTime, queryId, source)
	local time = SysTime() - startTime

	if not source then
		source = {
			short_src = "Unknown",
			linedefined = 0,
			lastlinedefined = 0
		}
	end

	if not GProfiler.Database.SeenQuery[queryText] then
		GProfiler.Database.SeenQuery[queryText] = true
	end

	if not GProfiler.Database.ProfileData[queryId] then
		GProfiler.Database.ProfileData[queryId] = {
			Count = 0, Time = 0, AverageTime = 0, LongestTime = 0,
			Query = queryText, Type = self.Name, Source = { source.short_src, source.linedefined or 0, source.lastlinedefined or 0}
		}
	end

	local data = GProfiler.Database.ProfileData[queryId]
	data.Count = data.Count + 1
	data.Time = data.Time + time
	data.AverageTime = data.Time / data.Count
	data.LongestTime = math.max(data.LongestTime, time)

	return data
end

function BaseProvider:CleanupAfterProfiling()
	for k, v in pairs(self.Objects) do
		if v.oldQueryFunc or (v.oldQueryFuncs and next(v.oldQueryFuncs)) then
			v.oldQueryFunc = nil
			v.oldQueryFuncs = {}
		end
	end
end

function GProfiler.Database.Providers.Register(providerClass)
	if GProfiler.Database.Providers[providerClass.Name] then
		return true
	end

	local provider = providerClass:New()
	if provider:Initialize() then
		GProfiler.Database.Providers[provider.Name] = provider
		return true
	end
	return false
end

return BaseProvider