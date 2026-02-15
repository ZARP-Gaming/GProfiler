local BaseProvider = include("base/sv_base_provider.lua")

local GoobieMySQL3Provider = setmetatable({}, { __index = BaseProvider })
GoobieMySQL3Provider.__index = GoobieMySQL3Provider
GoobieMySQL3Provider.Name = "goobie_mysql"
GoobieMySQL3Provider.ModuleName = "goobie_mysql_3"
GoobieMySQL3Provider.QueryMethods = {
	"Run", "RunSync", "Execute", "ExecuteSync",
	"Fetch", "FetchSync", "FetchOne", "FetchOneSync",
	"UpsertQuery", "UpsertQuerySync"
}

function GoobieMySQL3Provider:New()
	local provider = BaseProvider.New(self)
	setmetatable(provider, self)
	return provider
end

function GoobieMySQL3Provider:SetupConnectionHook()
	local oldNewConn = goobie_mysql_3.NewConn
	if goobie_mysql_3.oldNewConn then
		oldNewConn = goobie_mysql_3.oldNewConn
	else
		goobie_mysql_3.oldNewConn = oldNewConn
	end

	goobie_mysql_3.NewConn = function(opts, on_connect)
		local object = oldNewConn(opts, on_connect)
		self:AddDatabaseObject(object, getmetatable(object))
		return object
	end
end

function GoobieMySQL3Provider:DetourQueryFunction(objectData)
	local target = objectData.meta or objectData.object
	objectData.oldQueryFuncs = {}

	local provider = self
	for _, methodName in ipairs(self.QueryMethods) do
		if target[methodName] then
			if not provider.OriginalFunctions[methodName] then
				provider.OriginalFunctions[methodName] = target[methodName]
			end

			local originalFunc = provider.OriginalFunctions[methodName]
			objectData.oldQueryFuncs[methodName] = originalFunc

			target[methodName] = function(obj, ...)
				return provider:WrapQueryMethod(objectData, methodName, obj, ...)
			end
		end
	end
end

function GoobieMySQL3Provider:WrapQueryMethod(objectData, methodName, obj, ...)
	local args = {...}
	local queryText = args[1]

	local oldFunc = objectData.oldQueryFuncs[methodName]
	if not oldFunc then
		ErroNoHalt("No old function found for method: " .. methodName)
		return
	end

	local source = debug.getinfo(2)
	local queryId = self:GetQueryId(queryText .. source.short_src .. tostring(source.linedefined) .. tostring(source.lastlinedefined))
	local startTime

	if string.find(methodName, "Sync") == nil then
		local options = args[2]
		local wrappedOptions = options

		if options and istable(options) and options.callback and isfunction(options.callback) then
			local originalCallback = options.callback
			wrappedOptions = table.Copy(options)
			wrappedOptions.callback = function(err, result)
				self:ProcessQueryResult(queryText, startTime, queryId, source)
				self:CreateExplainQuery(queryText, objectData, queryId)
				originalCallback(err, result)
			end
			args[2] = wrappedOptions
		end

		startTime = SysTime()
		return oldFunc(obj, unpack(args))
	else
		local result = {oldFunc(obj, unpack(args))}
		self:ProcessQueryResult(queryText, startTime, queryId, source)
		self:CreateExplainQuery(queryText, objectData, queryId)
		return unpack(result)
	end
end

function GoobieMySQL3Provider:EnableSQLProfiling(objectData) end
function GoobieMySQL3Provider:DisableSQLProfiling(objectData) end
function GoobieMySQL3Provider:ExecuteExplainQuery(explainQuery, objectData, queryId)
	local target = objectData.object
	if not target then
		GProfiler.Database.Explains[queryId] = { noExplain = true }
		return
	end

	target:Fetch(explainQuery, {
		callback = function(err, result)
			if err then
				GProfiler.Log("Failed to execute EXPLAIN query: " .. tostring(err), 3)
				GProfiler.Database.Explains[queryId] = { noExplain = true }
			else
				GProfiler.Database.Explains[queryId] = result or {}
				GProfiler.Log("EXPLAIN query executed successfully for query " .. queryId, 1)
			end
		end
	})
end
function GoobieMySQL3Provider:GetObjectProfilingData(objectData, callback)
	callback(nil)
end

GProfiler.Database.Providers.Register(GoobieMySQL3Provider)

return GoobieMySQL3Provider