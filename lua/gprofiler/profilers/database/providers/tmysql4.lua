local BaseProvider = include("base/sv_base_provider.lua")

local TMySQL4Provider = setmetatable({}, { __index = BaseProvider })
TMySQL4Provider.__index = TMySQL4Provider
TMySQL4Provider.Name = "tmysql4"
TMySQL4Provider.ModuleName = "tmysql4"
TMySQL4Provider.QueryFunction = "Query"

function TMySQL4Provider:New()
	local provider = BaseProvider.New(self)
	setmetatable(provider, self)
	return provider
end

function TMySQL4Provider:SetupConnectionHook()
	local oldConnect = tmysql.Connect
	if tmysql.oldConnect then
		oldConnect = tmysql.oldConnect
	else
		tmysql.oldConnect = oldConnect
	end

	tmysql.Connect = function(...)
		local object, err = oldConnect(...)
		if object then
			self:AddDatabaseObject(object, getmetatable(object))
		end
		return object, err
	end
end

function TMySQL4Provider:DetourQueryFunction(objectData)
	local target = objectData.meta or objectData.object
	objectData.oldQueryFunc = target[self.QueryFunction]

	target[self.QueryFunction] = function(obj, queryText, callback, ...)
		local source = debug.getinfo(3) or debug.getinfo(2)
		local queryId = self:GetQueryId(queryText .. source.short_src .. tostring(source.linedefined) .. tostring(source.lastlinedefined))
		local startTime = SysTime()

		local wrappedCallback = nil
		if callback and isfunction(callback) then
			wrappedCallback = function(...)
				self:ProcessQueryResult(queryText, startTime, queryId, source)
				self:CreateExplainQuery(queryText, objectData, queryId)
				callback(...)
			end
		end

		return objectData.oldQueryFunc(obj, queryText, wrappedCallback, ...)
	end
end

function TMySQL4Provider:EnableSQLProfiling(objectData)
	if not objectData.oldQueryFunc then return end

	objectData.oldQueryFunc(objectData.object, "SHOW VARIABLES LIKE 'have_profiling'", function(result)
		if not result or not istable(result) or #result == 0 then return end
		if result[1].status ~= true or not result[1].data or #result[1].data == 0 then return end
		if result[1].data[1].Value ~= "YES" then return end

		objectData.oldQueryFunc(objectData.object, "SET profiling_history_size = 250, profiling = 1;")
		objectData.hasProfiling = true
	end)
end

function TMySQL4Provider:DisableSQLProfiling(objectData)
	if objectData.hasProfiling and objectData.oldQueryFunc then
		objectData.oldQueryFunc(objectData.object, "SET profiling_history_size = 0, profiling = 0;")
	end
end

function TMySQL4Provider:ExecuteExplainQuery(explainQuery, objectData, queryId)
	if not objectData.oldQueryFunc then
		GProfiler.Database.Explains[queryId] = { noExplain = true }
		return
	end

	objectData.oldQueryFunc(objectData.object, explainQuery, function(result)
		result = result and istable(result) and result[1]
		if not result or not result.status then
			GProfiler.Database.Explains[queryId] = { noExplain = true }
			return
		end
		GProfiler.Database.Explains[queryId] = result.data
	end)
end

function TMySQL4Provider:GetObjectProfilingData(objectData, callback)
	print("TMySQL4Provider:GetObjectProfilingData called", objectData, objectData.hasProfiling, objectData.oldQueryFunc)
	if not objectData.hasProfiling or not objectData.oldQueryFunc then
		print("TMySQL4Provider:GetObjectProfilingData no profiling or no oldQueryFunc")
		callback(nil)
		return
	end

	objectData.oldQueryFunc(objectData.object, "SHOW PROFILES", function(result)
		print("TMySQL4Provider:GetObjectProfilingData SHOW PROFILES result:", result)
		if not result or not istable(result) or #result == 0 then
			callback(nil)
			return
		end
		if result[1].status ~= true or not result[1].data or #result[1].data == 0 then
			callback(nil)
			return
		end

		local profilingData = {}
		local waitingFor = 0
		local profiles = result[1].data

		for _, profile in ipairs(profiles) do
			waitingFor = waitingFor + 1

			objectData.oldQueryFunc(objectData.object, "SHOW PROFILE FOR QUERY " .. profile.Query_ID, function(profileResult)
				waitingFor = waitingFor - 1

				if profileResult and istable(profileResult) and #profileResult > 0 then
					if profileResult[1].status == true and profileResult[1].data and #profileResult[1].data > 0 then
						local flattenQuery = profile.Query:gsub("%s+", " "):Trim():lower()
						if flattenQuery:EndsWith(";") then
							flattenQuery = flattenQuery:sub(1, -2)
						end

						profilingData[flattenQuery] = {
							Query = profile.Query,
							Duration = profile.Duration,
							ProfileData = profileResult[1].data
						}
					end
				end

				if waitingFor == 0 then
					callback(profilingData)
				end
			end)
		end

		if waitingFor == 0 then
			callback(profilingData)
		end
	end)
end

GProfiler.Database.Providers.Register(TMySQL4Provider)

return TMySQL4Provider