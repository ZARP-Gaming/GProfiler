local BaseProvider = include("base/sv_base_provider.lua")

-- TODO: Client has sqlite, so should probably support that as well

local SQLiteProvider = setmetatable({}, { __index = BaseProvider })
SQLiteProvider.__index = SQLiteProvider
SQLiteProvider.Name = "sqlite"
SQLiteProvider.QueryMethods = {
	"Query", -- table or boolean or nil / sql.Query( string query )
	"QueryRow", -- table / sql.QueryRow( string query, number row = 1 )
	"QueryTyped", -- table or boolean / sql.QueryTyped( string query, ... )
	"QueryValue", -- string / sql.QueryValue( string query )
	"TableExists" --  boolean / sql.TableExists( string tableName )
}

function SQLiteProvider:New()
	local provider = BaseProvider.New(self)
	setmetatable(provider, self)
	return provider
end

function SQLiteProvider:DetourQueryFunction(objectData)
	objectData.oldQueryFuncs = {}

	for _, method in ipairs(self.QueryMethods) do
		if not objectData.object[method] then continue end

		local originalFunc = objectData.object[method]
		objectData.oldQueryFuncs[method] = originalFunc

		objectData.object[method] = function(queryText, ...)
			local source = debug.getinfo(2)
			local queryId = self:GetQueryId(queryText .. source.short_src .. tostring(source.linedefined) .. tostring(source.lastlinedefined))
			local startTime = SysTime()
			local result = originalFunc(queryText, ...)

			self:ProcessQueryResult(queryText, startTime, queryId, source)

			return result
		end
	end
end

function SQLiteProvider:SetupConnectionHook()
	self:AddDatabaseObject(sql, nil)
end

function SQLiteProvider:EnableSQLProfiling(objectData) end
function SQLiteProvider:DisableSQLProfiling(objectData) end
function SQLiteProvider:ExecuteExplainQuery(explainQuery, objectData, queryId) end
function SQLiteProvider:GetObjectProfilingData(objectData, callback) end

GProfiler.Database.Providers.Register(SQLiteProvider)

-- concommand.Add("gprofiler_sqlite_test", function()
-- 	sql.Query("SELECT 1")
-- 	sql.QueryRow("SELECT 1")
-- 	sql.QueryTyped("SELECT 1 WHERE 1= ?", 1)
-- 	sql.QueryValue("SELECT 1")
-- 	sql.TableExists("some_table")
-- end)

return SQLiteProvider