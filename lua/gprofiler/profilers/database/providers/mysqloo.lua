local BaseProvider = include("base/sv_base_provider.lua")

local MySQLOOProvider = setmetatable({}, { __index = BaseProvider })
MySQLOOProvider.__index = MySQLOOProvider
MySQLOOProvider.Name = "mysqloo"
MySQLOOProvider.ModuleName = "mysqloo"
MySQLOOProvider.QueryFunction = "query"

function MySQLOOProvider:New()
	local provider = BaseProvider.New(self)
	setmetatable(provider, self)
	return provider
end

function MySQLOOProvider:SetupConnectionHook()
	local oldConnect = mysqloo.connect
	if mysqloo.oldConnect then
		oldConnect = mysqloo.oldConnect
	else
		mysqloo.oldConnect = oldConnect
	end

	mysqloo.connect = function(...)
		local object = oldConnect(...)
		self:AddDatabaseObject(object, nil)
		return object
	end
end

function MySQLOOProvider:DetourQueryFunction(objectData)
	objectData.oldQueryFunc = objectData.object[self.QueryFunction]

	objectData.object[self.QueryFunction] = function(obj, queryText, ...)
		local source = debug.getinfo(3) or debug.getinfo(2)
		local queryId = self:GetQueryId(queryText .. source.short_src .. tostring(source.linedefined) .. tostring(source.lastlinedefined))
		local startTime = SysTime()
		local query = objectData.oldQueryFunc(obj, queryText, ...)

		query.oldStart = query.start
		query.start = function()
			startTime = SysTime()

			local oldError = query.onError
			query.onError = function(Q, E)
				self:ProcessQueryResult(queryText, startTime, queryId, source)
				self:CreateExplainQuery(queryText, objectData, queryId)
				if oldError then oldError(Q, E) end
			end

			local oldSuccess = query.onSuccess
			query.onSuccess = function(Q, D)
				self:ProcessQueryResult(queryText, startTime, queryId, source)
				self:CreateExplainQuery(queryText, objectData, queryId)
				if oldSuccess then oldSuccess(Q, D) end
			end

			query:oldStart()
		end

		return query
	end
end

function MySQLOOProvider:EnableSQLProfiling(objectData)
	if not objectData.oldQueryFunc then return end

	local hasProfilingQuery = objectData.oldQueryFunc(objectData.object, "SHOW VARIABLES LIKE 'have_profiling'")
	hasProfilingQuery.onSuccess = function(Q, D)
		if table.Count(D or {}) == 0 then return end
		if D[1].Value == "YES" then
			objectData.hasProfiling = true
			local enable = objectData.oldQueryFunc(objectData.object, "SET profiling_history_size = 250, profiling = 1;")
			enable:start()
		end
	end
	hasProfilingQuery:start()
end

function MySQLOOProvider:DisableSQLProfiling(objectData)
	if objectData.hasProfiling and objectData.oldQueryFunc then
		local disable = objectData.oldQueryFunc(objectData.object, "SET profiling_history_size = 0, profiling = 0;")
		disable:start()
	end
end

function MySQLOOProvider:ExecuteExplainQuery(explainQuery, objectData, queryId)
	if not objectData.oldQueryFunc then
		GProfiler.Database.Explains[queryId] = { noExplain = true }
		return
	end

	local query = objectData.oldQueryFunc(objectData.object, explainQuery)
	local data = {}

	query.onData = function(Q, D)
		data[#data + 1] = D
	end

	query.onSuccess = function(Q, D)
		GProfiler.Database.Explains[queryId] = data
	end

	query.onError = function(Q, E)
		GProfiler.Database.Explains[queryId] = { noExplain = true }
	end

	query:start()
end

function MySQLOOProvider:GetObjectProfilingData(objectData, callback)
	if not objectData.hasProfiling or not objectData.oldQueryFunc then
		callback(nil)
		return
	end

	local query = objectData.oldQueryFunc(objectData.object, "SHOW PROFILES")
	local data = {}

	query.onData = function(Q, D)
		data[#data + 1] = D
	end

	query.onSuccess = function(Q, D)
		if table.IsEmpty(data) then
			callback(nil)
			return
		end

		local profilingData = {}
		local waitingFor = 0

		for _, profile in pairs(data) do
			local profileQuery = objectData.oldQueryFunc(objectData.object, "SHOW PROFILE FOR QUERY " .. profile.Query_ID)
			local pdata = {}

			profileQuery.onData = function(Q, D)
				pdata[#pdata + 1] = D
			end

			profileQuery.onSuccess = function(Q, D)
				waitingFor = waitingFor - 1
				if not table.IsEmpty(pdata) then
					local flattenQuery = profile.Query:gsub("%s+", " "):Trim():lower()
					if flattenQuery:EndsWith(";") then
						flattenQuery = flattenQuery:sub(1, -2)
					end

					profilingData[flattenQuery] = {
						Query = profile.Query,
						Duration = profile.Duration,
						ProfileData = pdata
					}
				end

				if waitingFor == 0 then
					callback(profilingData)
				end
			end

			profileQuery.onError = function(Q, E)
				waitingFor = waitingFor - 1
				if waitingFor == 0 then
					callback(profilingData)
				end
			end

			waitingFor = waitingFor + 1
			profileQuery:start()
		end
	end

	query.onError = function(Q, E)
		callback(nil)
	end

	query:start()
end

GProfiler.Database.Providers.Register(MySQLOOProvider)

return MySQLOOProvider