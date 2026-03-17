GProfiler.Database = GProfiler.Database or {}

local MySQLKeywords = {
  ["ACCESSIBLE"] = "Ensures table alterations are compatible with storage engines.",
  ["ACCOUNT"] = "Used in security statements to manage user accounts (e.g., LOCK/UNLOCK).",
  ["ACTION"] = "Specifies the action for triggers or constraints.",
  ["ACTIVE"] = "Indicates an active operation or state (e.g., in partitioning).",
  ["ADD"] = "Adds columns, indexes, or constraints to a table.",
  ["ADMIN"] = "Used in role or privilege management.",
  ["AFTER"] = "Specifies the position of a new column or trigger timing.",
  ["AGAINST"] = "Used in FULLTEXT search queries with MATCH.",
  ["AGGREGATE"] = "Defines an aggregate function in stored programs.",
  ["ALGORITHM"] = "Specifies the algorithm for table operations (e.g., CREATE, ALTER).",
  ["ALL"] = "Compares a value to all values in a set or selects all columns.",
  ["ALTER"] = "Modifies an existing database object (e.g., table, view).",
  ["ALWAYS"] = "Used in generated columns to enforce storage.",
  ["ANALYSE"] = "Analyzes table statistics for optimization (synonym for ANALYZE).",
  ["ANALYZE"] = "Analyzes and stores key distribution for tables.",
  ["AND"] = "Combines conditions where both must be true.",
  ["ANY"] = "Compares a value to any value in a set.",
  ["AS"] = "Assigns an alias to a column or table.",
  ["ASC"] = "Sorts results in ascending order.",
  ["ASCII"] = "Specifies ASCII character set for a column or expression.",
  ["ASENSITIVE"] = "Indicates a non-sensitive cursor in stored procedures.",
  ["AT"] = "Used in timestamp or versioning clauses.",
  ["AUTOEXTEND_SIZE"] = "Sets the auto-extend size for InnoDB tablespaces.",
  ["AUTO_INCREMENT"] = "Automatically generates unique values for a column.",
  ["AVG"] = "Calculates the average of a set of values.",
  ["AVG_ROW_LENGTH"] = "Specifies the average row length for table storage.",
  ["BACKUP"] = "Used in backup-related statements.",
  ["BEFORE"] = "Specifies trigger execution before an event.",
  ["BEGIN"] = "Starts a transaction or stored program block.",
  ["BETWEEN"] = "Selects values within a range.",
  ["BIGINT"] = "Defines a large integer column type.",
  ["BINARY"] = "Specifies a binary string or collation.",
  ["BINLOG"] = "Refers to the binary log for replication.",
  ["BIT"] = "Defines a bit-value column type.",
  ["BLOB"] = "Defines a binary large object column type.",
  ["BLOCK"] = "Used in partitioning or locking operations.",
  ["BOOL"] = "Synonym for BOOLEAN.",
  ["BOOLEAN"] = "Defines a boolean column type (TRUE/FALSE).",
  ["BOTH"] = "Used in string operations to apply to both sides.",
  ["BTREE"] = "Specifies a B-tree index type.",
  ["BY"] = "Used in ORDER BY, GROUP BY, or partitioning clauses.",
  ["BYTE"] = "Synonym for BINARY in some contexts.",
  ["CACHE"] = "Controls caching behavior for queries or indexes.",
  ["CALL"] = "Invokes a stored procedure.",
  ["CASCADE"] = "Propagates changes to related tables in constraints.",
  ["CASCADED"] = "Used in constraint or trigger propagation.",
  ["CASE"] = "Conditional logic to transform values.",
  ["CATALOG_NAME"] = "Refers to the catalog name in information schema.",
  ["CHAIN"] = "Used in transaction control for chaining.",
  ["CHANGE"] = "Modifies a column in ALTER TABLE.",
  ["CHAR"] = "Defines a fixed-length character column type.",
  ["CHARACTER"] = "Synonym for CHAR in column definitions.",
  ["CHARSET"] = "Specifies the character set for a column or table.",
  ["CHECK"] = "Enforces a condition on column values.",
  ["CHECKSUM"] = "Enables table checksums for integrity.",
  ["CIPHER"] = "Specifies encryption for secure connections.",
  ["CLASS_ORIGIN"] = "Refers to the origin of a constraint in information schema.",
  ["CLIENT"] = "Used in client connection options.",
  ["CLOB"] = "Defines a character large object (not standard in MySQL).",
  ["CLOSE"] = "Closes a cursor in stored procedures.",
  ["COALESCE"] = "Returns the first non-NULL value from a list.",
  ["CODE"] = "Used in error handling for stored programs.",
  ["COLLATE"] = "Specifies the collation for string comparisons.",
  ["COLLATION"] = "Refers to the collation in information schema or queries.",
  ["COLUMN"] = "Refers to a table column in DDL statements.",
  ["COLUMN_NAME"] = "Refers to a column name in information schema.",
  ["COLUMNS"] = "Refers to multiple columns in information schema.",
  ["COMMENT"] = "Adds a comment to a table, column, or other object.",
  ["COMMIT"] = "Saves changes in a transaction.",
  ["COMPACT"] = "Specifies a compact row format for InnoDB.",
  ["COMPLETION"] = "Used in transaction control for completion options.",
  ["COMPRESSED"] = "Enables compression for InnoDB tables.",
  ["COMPRESSION"] = "Specifies compression options for tables.",
  ["CONCURRENT"] = "Allows concurrent operations in certain contexts.",
  ["CONDITION"] = "Used in stored procedures for condition handling.",
  ["CONNECTION"] = "Refers to a database connection or its properties.",
  ["CONSISTENT"] = "Used in transactions for consistent snapshots.",
  ["CONSTRAINT"] = "Defines a constraint (e.g., FOREIGN KEY, UNIQUE).",
  ["CONTAINS"] = "Used in spatial or FULLTEXT queries.",
  ["CONTEXT"] = "Refers to context in error messages or diagnostics.",
  ["CONTINUE"] = "Continues execution in a stored program loop.",
  ["CONVERT"] = "Converts data between character sets or types.",
  ["COUNT"] = "Counts rows or non-NULL values in a set.",
  ["CREATE"] = "Creates a new database object (e.g., table, database).",
  ["CROSS"] = "Specifies a cross join between tables.",
  ["CUBE"] = "Used in GROUP BY for multidimensional grouping.",
  ["CURRENT"] = "Refers to the current value in versioning or cursors.",
  ["CURRENT_DATE"] = "Returns the current date.",
  ["CURRENT_TIME"] = "Returns the current time.",
  ["CURRENT_TIMESTAMP"] = "Returns the current date and time.",
  ["CURRENT_USER"] = "Returns the current user name.",
  ["CURSOR"] = "Declares a cursor for iterating over query results.",
  ["DATA"] = "Used in table or partitioning operations.",
  ["DATABASE"] = "Refers to a database in DDL or DML statements.",
  ["DATABASES"] = "Refers to multiple databases (e.g., SHOW DATABASES).",
  ["DATE"] = "Defines a date column type.",
  ["DATETIME"] = "Defines a date and time column type.",
  ["DAY"] = "Extracts the day from a date expression.",
  ["DAY_HOUR"] = "Used in intervals (e.g., DATE_SUB).",
  ["DAY_MICROSECOND"] = "Used in intervals for precise time operations.",
  ["DAY_MINUTE"] = "Used in intervals for time operations.",
  ["DAY_SECOND"] = "Used in intervals for time operations.",
  ["DEALLOCATE"] = "Frees a prepared statement.",
  ["DEC"] = "Synonym for DECIMAL.",
  ["DECIMAL"] = "Defines a fixed-point number column type.",
  ["DECLARE"] = "Declares variables, cursors, or conditions in stored programs.",
  ["DEFAULT"] = "Sets a default value for a column.",
  ["DEFERRED"] = "Used in constraints for deferred checking.",
  ["DELAYED"] = "Delays INSERT operations for performance.",
  ["DELAY_KEY_WRITE"] = "Delays key updates for MyISAM tables.",
  ["DELETE"] = "Removes rows from a table.",
  ["DESC"] = "Sorts results in descending order or describes table structure.",
  ["DESCRIBE"] = "Displays table structure (synonym for SHOW COLUMNS).",
  ["DETERMINISTIC"] = "Indicates a stored function always returns the same result.",
  ["DIAGNOSTICS"] = "Provides diagnostic information in stored programs.",
  ["DIRECTORY"] = "Specifies a directory for table storage.",
  ["DISABLE"] = "Disables a feature (e.g., keys, triggers).",
  ["DISCARD"] = "Discards a tablespace or partition.",
  ["DISTINCT"] = "Removes duplicate rows from the result set.",
  ["DISTINCTROW"] = "Synonym for DISTINCT.",
  ["DIV"] = "Performs integer division.",
  ["DO"] = "Executes an expression without returning results.",
  ["DOUBLE"] = "Defines a double-precision floating-point column type.",
  ["DROP"] = "Deletes a database object (e.g., table, index).",
  ["DUAL"] = "A dummy table used in SELECT statements without FROM.",
  ["DUMPFILE"] = "Specifies a file for dumping table data.",
  ["DUPLICATE"] = "Used in INSERT ... ON DUPLICATE KEY UPDATE.",
  ["DYNAMIC"] = "Specifies a dynamic row format for InnoDB.",
  ["EACH"] = "Used in triggers to iterate over rows.",
  ["ELSE"] = "Part of CASE or IF, specifies the default result.",
  ["ELSEIF"] = "Used in stored program IF statements.",
  ["EMPTY"] = "Used in JSON or spatial operations to denote empty values.",
  ["ENABLE"] = "Enables a feature (e.g., keys, triggers).",
  ["ENCLOSED"] = "Specifies enclosing characters for data in LOAD DATA.",
  ["ENCRYPTION"] = "Enables encryption for tables or tablespaces.",
  ["END"] = "Closes a CASE, IF, or LOOP statement.",
  ["ENDS"] = "Used in event scheduling for end times.",
  ["ENGINE"] = "Specifies the storage engine for a table.",
  ["ENGINES"] = "Refers to storage engines in SHOW ENGINES.",
  ["ENUM"] = "Defines a column with a set of allowed string values.",
  ["ERROR"] = "Used in error handling or diagnostics.",
  ["ERRORS"] = "Refers to errors in LOAD DATA or diagnostics.",
  ["ESCAPE"] = "Specifies an escape character for LIKE or LOAD DATA.",
  ["ESCAPED"] = "Indicates escaped data in LOAD DATA.",
  ["EVENT"] = "Defines or manages a scheduled event.",
  ["EVENTS"] = "Refers to events in SHOW EVENTS.",
  ["EVERY"] = "Used in event scheduling for recurrence.",
  ["EXCHANGE"] = "Exchanges partitions or subpartitions.",
  ["EXCLUDE"] = "Used in locking or resource group management.",
  ["EXECUTE"] = "Executes a prepared statement.",
  ["EXISTS"] = "Tests for the existence of rows in a subquery.",
  ["EXIT"] = "Exits a stored program loop.",
  ["EXPANSION"] = "Used in FULLTEXT search for query expansion.",
  ["EXPIRE"] = "Sets account or password expiration.",
  ["EXPLAIN"] = "Describes how a query will be executed.",
  ["EXPORT"] = "Exports table data (e.g., to a file).",
  ["EXTENDED"] = "Provides extended output for EXPLAIN or CHECK TABLE.",
  ["EXTENT_SIZE"] = "Sets extent size for InnoDB tablespaces.",
  ["FALSE"] = "Boolean literal for false.",
  ["FAST"] = "Specifies a fast operation (e.g., in ALTER TABLE).",
  ["FAULTS"] = "Used in diagnostics or error handling.",
  ["FETCH"] = "Retrieves the next row from a cursor.",
  ["FIELD"] = "Used in string functions to find field positions.",
  ["FIELDS"] = "Refers to columns in LOAD DATA or SHOW COLUMNS.",
  ["FILE"] = "Specifies a file for operations like LOAD DATA.",
  ["FIRST"] = "Refers to the first value or row in a set.",
  ["FIXED"] = "Specifies a fixed row format for InnoDB.",
  ["FLOAT"] = "Defines a floating-point number column type.",
  ["FLUSH"] = "Clears or reloads caches, logs, or tables.",
  ["FOR"] = "Used in loops, cursors, or LOCK TABLES.",
  ["FORCE"] = "Forces an operation (e.g., index usage, table creation).",
  ["FOREIGN"] = "Defines a foreign key constraint.",
  ["FORMAT"] = "Specifies output format for EXPLAIN or data export.",
  ["FOUND_ROWS"] = "Returns the number of rows found by the last query.",
  ["FROM"] = "Specifies the table(s) to retrieve data from.",
  ["FULL"] = "Used in FULL JOIN or FULLTEXT indexes.",
  ["FULLTEXT"] = "Defines a full-text index for text searching.",
  ["FUNCTION"] = "Defines or calls a stored or user-defined function.",
  ["GENERAL"] = "Used in log or replication settings.",
  ["GENERATED"] = "Indicates a generated column (virtual or stored).",
  ["GEOMETRY"] = "Defines a spatial geometry column type.",
  ["GET"] = "Retrieves a value (e.g., in diagnostics).",
  ["GLOBAL"] = "Specifies a global variable or scope.",
  ["GRANT"] = "Assigns privileges to users or roles.",
  ["GRANTS"] = "Shows privileges (e.g., SHOW GRANTS).",
  ["GROUP"] = "Groups rows with the same values into summary rows.",
  ["GROUP_CONCAT"] = "Concatenates grouped values into a string.",
  ["HANDLER"] = "Provides direct access to table storage engine.",
  ["HASH"] = "Specifies a hash index or partitioning type.",
  ["HAVING"] = "Filters grouped rows based on a condition.",
  ["HIGH_PRIORITY"] = "Increases the priority of a query or operation.",
  ["HISTOGRAM"] = "Used in ANALYZE TABLE for column statistics.",
  ["HOST"] = "Specifies the host for user accounts or connections.",
  ["HOUR"] = "Extracts the hour from a time expression.",
  ["HOUR_MICROSECOND"] = "Used in intervals for precise time operations.",
  ["HOUR_MINUTE"] = "Used in intervals for time operations.",
  ["HOUR_SECOND"] = "Used in intervals for time operations.",
  ["IF"] = "Conditional statement in queries or stored programs.",
  ["IGNORE"] = "Ignores errors or duplicates in DML operations.",
  ["IGNORED"] = "Marks indexes or constraints to be ignored.",
  ["IMMEDIATE"] = "Performs an operation immediately (e.g., constraints).",
  ["IMPORT"] = "Imports data (e.g., tablespace or dump).",
  ["IN"] = "Checks if a value is within a set of values.",
  ["INDEX"] = "Creates an index to improve query performance.",
  ["INDEXES"] = "Refers to multiple indexes (e.g., SHOW INDEXES).",
  ["INFILE"] = "Specifies an input file for LOAD DATA.",
  ["INITIAL_SIZE"] = "Sets the initial size for InnoDB tablespaces.",
  ["INNER"] = "Specifies an inner join between tables.",
  ["INOUT"] = "Parameter mode for stored procedures (input/output).",
  ["INSENSITIVE"] = "Indicates a case-insensitive cursor or operation.",
  ["INSERT"] = "Adds new rows to a table.",
  ["INSTALL"] = "Installs a plugin or component.",
  ["INSTANCE"] = "Refers to a server instance in replication or clustering.",
  ["INT"] = "Defines an integer column type.",
  ["INTEGER"] = "Synonym for INT.",
  ["INTERVAL"] = "Used in date/time arithmetic (e.g., DATE_ADD).",
  ["INTO"] = "Specifies the destination for query results or INSERT data.",
  ["INVISIBLE"] = "Makes a column or index invisible to queries.",
  ["INVOKER"] = "Specifies the security context for stored programs.",
  ["IO"] = "Refers to input/output operations or threads.",
  ["IS"] = "Tests for equality with NULL or other values.",
  ["ISOLATION"] = "Sets the transaction isolation level.",
  ["ISSUER"] = "Specifies the issuer for SSL certificates.",
  ["ITERATE"] = "Restarts a loop in a stored program.",
  ["JOIN"] = "Combines rows from multiple tables based on a condition.",
  ["JSON"] = "Defines a JSON column type or used in JSON functions.",
  ["KEY"] = "Defines or refers to an index or primary key.",
  ["KEYS"] = "Refers to multiple keys (e.g., SHOW KEYS).",
  ["KEY_BLOCK_SIZE"] = "Sets the block size for index storage.",
  ["KILL"] = "Terminates a connection or query.",
  ["LANGUAGE"] = "Specifies the language for stored functions or errors.",
  ["LAST"] = "Refers to the last value or row in a set.",
  ["LEADING"] = "Used in string operations to apply to the start.",
  ["LEAVE"] = "Exits a stored program block or loop.",
  ["LEFT"] = "Specifies a left join or string function operation.",
  ["LESS"] = "Used in partitioning (e.g., LESS THAN).",
  ["LEVEL"] = "Specifies the transaction isolation level or hierarchy.",
  ["LIKE"] = "Matches a pattern in a string.",
  ["LIMIT"] = "Restricts the number of rows returned.",
  ["LINEAR"] = "Specifies a linear hash for partitioning.",
  ["LINES"] = "Specifies line handling in LOAD DATA.",
  ["LIST"] = "Used in partitioning to define value lists.",
  ["LOAD"] = "Loads data or indexes (e.g., LOAD DATA, LOAD INDEX).",
  ["LOCAL"] = "Specifies a local variable or scope.",
  ["LOCALTIME"] = "Synonym for NOW(), returns current time.",
  ["LOCALTIMESTAMP"] = "Synonym for NOW(), returns current timestamp.",
  ["LOCK"] = "Locks tables or rows to prevent concurrent access.",
  ["LOCKS"] = "Refers to locks in SHOW STATUS or diagnostics.",
  ["LOGFILE"] = "Refers to log files in replication or server settings.",
  ["LOGS"] = "Refers to logs in SHOW LOGS or diagnostics.",
  ["LONG"] = "Used in column definitions or LONGTEXT.",
  ["LONGBLOB"] = "Defines a large binary object column type.",
  ["LONGTEXT"] = "Defines a large text column type.",
  ["LOOP"] = "Defines a loop in stored programs.",
  ["LOW_PRIORITY"] = "Decreases the priority of a query or operation.",
  ["MASTER"] = "Refers to the master server in replication.",
  ["MATCH"] = "Used in FULLTEXT searches or foreign key constraints.",
  ["MAX"] = "Returns the maximum value in a set.",
  ["MAXVALUE"] = "Specifies the maximum value in partitioning.",
  ["MEDIUMBLOB"] = "Defines a medium-sized binary object column type.",
  ["MEDIUMINT"] = "Defines a medium-sized integer column type.",
  ["MEDIUMTEXT"] = "Defines a medium-sized text column type.",
  ["MEMBER"] = "Used in role or group management.",
  ["MEMORY"] = "Specifies the MEMORY storage engine.",
  ["MERGE"] = "Used in storage engines or view algorithms.",
  ["MESSAGE_TEXT"] = "Refers to error message text in diagnostics.",
  ["MICROSECOND"] = "Extracts microseconds from a time expression.",
  ["MIDDLEINT"] = "Synonym for MEDIUMINT.",
  ["MIN"] = "Returns the minimum value in a set.",
  ["MINUTE"] = "Extracts the minute from a time expression.",
  ["MINUTE_MICROSECOND"] = "Used in intervals for precise time operations.",
  ["MINUTE_SECOND"] = "Used in intervals for time operations.",
  ["MOD"] = "Performs modulo operation.",
  ["MODE"] = "Sets the SQL mode or operation mode.",
  ["MODIFIES"] = "Indicates a stored function modifies data.",
  ["MODIFY"] = "Changes a column definition in ALTER TABLE.",
  ["MONTH"] = "Extracts the month from a date expression.",
  ["NAMES"] = "Sets the character set for names in the session.",
  ["NATIONAL"] = "Specifies a national character set (e.g., NCHAR).",
  ["NATURAL"] = "Specifies a natural join based on common columns.",
  ["NCHAR"] = "Defines a national character column type.",
  ["NDB"] = "Refers to the NDB Cluster storage engine.",
  ["NDBCLUSTER"] = "Synonym for NDB.",
  ["NEVER"] = "Used in generated columns or event scheduling.",
  ["NEW"] = "Refers to new values in triggers.",
  ["NEXT"] = "Refers to the next value or row in a sequence.",
  ["NO"] = "Disables a feature or option.",
  ["NODEGROUP"] = "Specifies a node group in NDB Cluster.",
  ["NONE"] = "Indicates no action or no value.",
  ["NOT"] = "Negates a condition.",
  ["NO_WAIT"] = "Prevents waiting for locks in transactions.",
  ["NO_WRITE_TO_BINLOG"] = "Prevents writing to the binary log.",
  ["NULL"] = "Represents a missing or unknown value.",
  ["NUMERIC"] = "Synonym for DECIMAL.",
  ["NVARCHAR"] = "Defines a national variable-length character column.",
  ["OFFSET"] = "Skips a specified number of rows before returning results.",
  ["OLD"] = "Refers to old values in triggers.",
  ["ON"] = "Specifies the condition for a JOIN or trigger.",
  ["ONE"] = "Used in replication or single-value contexts.",
  ["ONLY"] = "Restricts operations (e.g., in FULLTEXT or privileges).",
  ["OPEN"] = "Opens a cursor or resource.",
  ["OPTIMIZE"] = "Optimizes table storage or performance.",
  ["OPTIMIZER_COSTS"] = "Refers to optimizer cost settings.",
  ["OPTION"] = "Specifies optional settings in statements.",
  ["OPTIONALLY"] = "Indicates an optional feature in LOAD DATA.",
  ["OPTIONS"] = "Refers to options in SHOW or table definitions.",
  ["OR"] = "Combines conditions where at least one must be true.",
  ["ORDER"] = "Sorts the result set by specified columns.",
  ["OUT"] = "Parameter mode for stored procedures (output).",
  ["OUTER"] = "Specifies an outer join (e.g., LEFT OUTER JOIN).",
  ["OUTFILE"] = "Specifies an output file for query results.",
  ["OVER"] = "Used in window functions to define the window.",
  ["OWNER"] = "Specifies the owner of an object or resource.",
  ["PACK_KEYS"] = "Controls key compression in MyISAM tables.",
  ["PAGE"] = "Used in partitioning or storage operations.",
  ["PARSER"] = "Specifies a parser for FULLTEXT indexes.",
  ["PARTIAL"] = "Indicates a partial operation (e.g., index or backup).",
  ["PARTITION"] = "Defines or manages table partitions.",
  ["PARTITIONING"] = "Refers to partitioning in table definitions.",
  ["PARTITIONS"] = "Specifies the number of partitions.",
  ["PASSWORD"] = "Sets or manages user passwords.",
  ["PERSISTENT"] = "Indicates persistent storage for generated columns.",
  ["PHASE"] = "Used in replication or transaction phases.",
  ["PLUGIN"] = "Manages server plugins (e.g., INSTALL PLUGIN).",
  ["PLUGINS"] = "Refers to multiple plugins (e.g., SHOW PLUGINS).",
  ["POINT"] = "Defines a spatial point data type.",
  ["PRECEDING"] = "Used in window functions for frame boundaries.",
  ["PRECISION"] = "Specifies precision for numeric types.",
  ["PREPARE"] = "Prepares a statement for execution.",
  ["PRESERVE"] = "Preserves data or settings in operations.",
  ["PRIMARY"] = "Defines a primary key constraint.",
  ["PRIVILEGES"] = "Refers to user privileges (e.g., SHOW PRIVILEGES).",
  ["PROCEDURE"] = "Defines or calls a stored procedure.",
  ["PROCESS"] = "Used in process management or diagnostics.",
  ["PROCESSLIST"] = "Shows running processes (e.g., SHOW PROCESSLIST).",
  ["PROFILE"] = "Used in profiling queries or performance.",
  ["PROFILES"] = "Refers to multiple profiles in SHOW PROFILES.",
  ["PROXY"] = "Grants proxy privileges to a user.",
  ["PURGE"] = "Clears logs or binary logs.",
  ["QUARTER"] = "Extracts the quarter from a date expression.",
  ["QUERY"] = "Refers to a query in optimization or diagnostics.",
  ["QUICK"] = "Speeds up certain operations (e.g., DELETE, REPAIR).",
  ["RANGE"] = "Used in partitioning or window function frames.",
  ["READ"] = "Sets read-only mode or lock type.",
  ["READS"] = "Indicates a stored function reads data.",
  ["READ_ONLY"] = "Enforces read-only mode for transactions or tables.",
  ["READ_WRITE"] = "Allows read and write operations.",
  ["REAL"] = "Synonym for DOUBLE in column definitions.",
  ["REBUILD"] = "Rebuilds indexes or partitions.",
  ["RECOVER"] = "Recovers data or connections.",
  ["REDO_LOG"] = "Refers to the redo log in InnoDB.",
  ["REDUNDANT"] = "Specifies a redundant row format for InnoDB.",
  ["REFERENCES"] = "Defines a foreign key reference.",
  ["REGEXP"] = "Matches a regular expression in a string.",
  ["RELAY"] = "Used in replication for relay logs.",
  ["RELAYLOG"] = "Refers to the relay log in replication.",
  ["RELAY_LOG_FILE"] = "Specifies the relay log file in replication.",
  ["RELAY_LOG_POS"] = "Specifies the relay log position in replication.",
  ["RELEASE"] = "Releases a lock or savepoint.",
  ["RELOAD"] = "Reloads privileges or caches.",
  ["REMOVE"] = "Removes a feature or object (e.g., partitioning).",
  ["RENAME"] = "Renames a table, column, or other object.",
  ["REORGANIZE"] = "Reorganizes partitions or tables.",
  ["REPAIR"] = "Repairs a corrupted table.",
  ["REPEAT"] = "Defines a repeating loop in stored programs.",
  ["REPEATABLE"] = "Sets repeatable read isolation level.",
  ["REPLACE"] = "Replaces rows in a table or string function operation.",
  ["REPLICA"] = "Refers to a replica server in replication.",
  ["REPLICAS"] = "Refers to multiple replicas in replication.",
  ["REPLICATE_DO_DB"] = "Specifies databases to replicate.",
  ["REPLICATE_IGNORE_DB"] = "Specifies databases to ignore in replication.",
  ["REPLICATION"] = "Refers to replication settings or status.",
  ["REQUIRE"] = "Specifies SSL or authentication requirements.",
  ["RESET"] = "Resets server settings, logs, or replication.",
  ["RESIGNAL"] = "Raises a signal in stored programs.",
  ["RESTART"] = "Restarts the server or a process.",
  ["RESTRICT"] = "Prevents cascading actions in constraints.",
  ["RESUME"] = "Resumes a suspended event or process.",
  ["RETURN"] = "Returns a value from a stored function or procedure.",
  ["RETURNING"] = "Specifies returned values in some DML statements.",
  ["RETURNS"] = "Defines the return type of a stored function.",
  ["REUSE"] = "Reuses connections or resources.",
  ["REVOKE"] = "Removes privileges from users or roles.",
  ["RIGHT"] = "Specifies a right join or string function operation.",
  ["ROLE"] = "Manages roles for privilege assignment.",
  ["ROLLBACK"] = "Undoes changes in a transaction.",
  ["ROLLUP"] = "Adds summary rows in GROUP BY queries.",
  ["ROTATE"] = "Rotates logs or keys in replication or encryption.",
  ["ROW"] = "Refers to a single row in queries or functions.",
  ["ROWS"] = "Specifies multiple rows in queries or window functions.",
  ["ROW_COUNT"] = "Returns the number of rows affected by a statement.",
  ["ROW_FORMAT"] = "Specifies the row storage format for tables.",
  ["SAVEPOINT"] = "Sets a savepoint in a transaction.",
  ["SCHEDULE"] = "Schedules events or tasks.",
  ["SCHEMA"] = "Synonym for DATABASE.",
  ["SCHEMAS"] = "Refers to multiple databases (e.g., SHOW SCHEMAS).",
  ["SECOND"] = "Extracts the second from a time expression.",
  ["SECOND_MICROSECOND"] = "Used in intervals for precise time operations.",
  ["SECURITY"] = "Specifies the security context for stored programs.",
  ["SELECT"] = "Retrieves data from one or more tables.",
  ["SENSITIVE"] = "Indicates a case-sensitive cursor or operation.",
  ["SEPARATOR"] = "Specifies a separator in GROUP_CONCAT or LOAD DATA.",
  ["SERIAL"] = "Synonym for BIGINT AUTO_INCREMENT.",
  ["SERIALIZABLE"] = "Sets serializable transaction isolation level.",
  ["SERVER"] = "Refers to the database server in replication or settings.",
  ["SESSION"] = "Specifies session scope for variables or settings.",
  ["SET"] = "Assigns values in UPDATE or session variables.",
  ["SHARE"] = "Used in table locking or resource sharing.",
  ["SHOW"] = "Displays database metadata or status.",
  ["SHUTDOWN"] = "Shuts down the database server.",
  ["SIGNAL"] = "Raises an error or signal in stored programs.",
  ["SIGNED"] = "Specifies a signed integer type.",
  ["SIMPLE"] = "Indicates a simple operation or algorithm.",
  ["SKIP"] = "Skips rows or operations (e.g., in locking).",
  ["SLAVE"] = "Refers to a slave server in replication (deprecated).",
  ["SLOW"] = "Used in log or query settings for slow queries.",
  ["SMALLINT"] = "Defines a small integer column type.",
  ["SNAPSHOT"] = "Used in consistent snapshots for transactions.",
  ["SOME"] = "Synonym for ANY in comparisons.",
  ["SONAME"] = "Specifies the shared object name for plugins.",
  ["SOUNDS"] = "Used in SOUNDS LIKE for phonetic matching.",
  ["SOURCE"] = "Refers to the source server in replication.",
  ["SPATIAL"] = "Defines a spatial index or data type.",
  ["SPECIFIC"] = "Specifies a specific function or procedure.",
  ["SQL"] = "Indicates SQL code in stored programs.",
  ["SQLEXCEPTION"] = "Handles SQL exceptions in stored programs.",
  ["SQLSTATE"] = "Refers to SQL state codes in diagnostics.",
  ["SQLWARNING"] = "Handles SQL warnings in stored programs.",
  ["SQL_BIG_RESULT"] = "Hints that a query returns a large result set.",
  ["SQL_BUFFER_RESULT"] = "Buffers the result set for performance.",
  ["SQL_CACHE"] = "Caches query results (deprecated).",
  ["SQL_CALC_FOUND_ROWS"] = "Calculates the total rows for a limited query.",
  ["SQL_NO_CACHE"] = "Prevents caching of query results.",
  ["SQL_SMALL_RESULT"] = "Hints that a query returns a small result set.",
  ["SSL"] = "Enables SSL for secure connections.",
  ["STACKED"] = "Used in diagnostics for stacked error handling.",
  ["START"] = "Starts a transaction, event, or server.",
  ["STARTING"] = "Specifies the starting point for LOAD DATA.",
  ["STARTS"] = "Used in event scheduling for start times.",
  ["STATS_AUTO_RECALC"] = "Controls automatic statistics recalculation.",
  ["STATS_PERSISTENT"] = "Enables persistent statistics for tables.",
  ["STATS_SAMPLE_PAGES"] = "Sets the number of pages sampled for statistics.",
  ["STATUS"] = "Shows server or session status.",
  ["STOP"] = "Stops a server, event, or replication.",
  ["STORAGE"] = "Specifies the storage type (e.g., DISK, MEMORY).",
  ["STORED"] = "Indicates a stored generated column.",
  ["STRAIGHT_JOIN"] = "Forces a join order in queries.",
  ["STRING"] = "Refers to a string data type or value.",
  ["SUBJECT"] = "Specifies the subject for SSL certificates.",
  ["SUBPARTITION"] = "Defines a subpartition in a table.",
  ["SUBPARTITIONS"] = "Specifies the number of subpartitions.",
  ["SUM"] = "Calculates the sum of a set of values.",
  ["SUPER"] = "Grants superuser privileges.",
  ["SUSPEND"] = "Suspends an event or process.",
  ["SWAPS"] = "Used in partitioning or storage operations.",
  ["SWITCHES"] = "Used in diagnostics or configuration.",
  ["TABLE"] = "Refers to a table in DDL or DML statements.",
  ["TABLES"] = "Refers to multiple tables (e.g., SHOW TABLES).",
  ["TABLESPACE"] = "Defines or manages a tablespace for storage.",
  ["TEMPORARY"] = "Creates a temporary table or object.",
  ["TEMPTABLE"] = "Specifies the TEMPTABLE algorithm for views.",
  ["TERMINATED"] = "Specifies termination characters in LOAD DATA.",
  ["TEXT"] = "Defines a text column type.",
  ["THAN"] = "Used in comparisons or partitioning (e.g., LESS THAN).",
  ["THEN"] = "Part of CASE or IF, specifies the result for a condition.",
  ["TIME"] = "Defines a time column type.",
  ["TIMESTAMP"] = "Defines a timestamp column type.",
  ["TIMESTAMPADD"] = "Adds an interval to a timestamp.",
  ["TIMESTAMPDIFF"] = "Calculates the difference between timestamps.",
  ["TINYBLOB"] = "Defines a small binary object column type.",
  ["TINYINT"] = "Defines a tiny integer column type.",
  ["TINYTEXT"] = "Defines a small text column type.",
  ["TO"] = "Used in RENAME, GRANT, or data conversion.",
  ["TRAILING"] = "Used in string operations to apply to the end.",
  ["TRANSACTION"] = "Manages a database transaction.",
  ["TRIGGER"] = "Defines or manages a database trigger.",
  ["TRIGGERS"] = "Refers to multiple triggers (e.g., SHOW TRIGGERS).",
  ["TRUE"] = "Boolean literal for true.",
  ["TRUNCATE"] = "Removes all rows from a table without dropping its structure.",
  ["UNBOUNDED"] = "Used in window functions for frame boundaries.",
  ["UNDEFINED"] = "Indicates an undefined value or state.",
  ["UNDO"] = "Used in transaction rollback or undo logs.",
  ["UNION"] = "Combines the result sets of two or more SELECT statements.",
  ["UNIQUE"] = "Ensures all values in a column or set are unique.",
  ["UNKNOWN"] = "Indicates an unknown value or state.",
  ["UNLOCK"] = "Releases table or row locks.",
  ["UNSIGNED"] = "Specifies an unsigned numeric type.",
  ["UPDATE"] = "Modifies existing rows in a table.",
  ["UPGRADE"] = "Upgrades table or server versions.",
  ["USAGE"] = "Grants usage privileges without specific permissions.",
  ["USE"] = "Selects a database for use.",
  ["USING"] = "Alternative to ON for specifying join columns.",
  ["UTC_DATE"] = "Returns the current UTC date.",
  ["UTC_TIME"] = "Returns the current UTC time.",
  ["UTC_TIMESTAMP"] = "Returns the current UTC timestamp.",
  ["VALUE"] = "Specifies a single value in INSERT or partitioning.",
  ["VALUES"] = "Specifies multiple values in INSERT or partitioning.",
  ["VARBINARY"] = "Defines a variable-length binary string column.",
  ["VARCHAR"] = "Defines a variable-length character column.",
  ["VARIABLE"] = "Refers to a session or system variable.",
  ["VARIABLES"] = "Refers to multiple variables (e.g., SHOW VARIABLES).",
  ["VARYING"] = "Synonym for VARCHAR in some contexts.",
  ["VIEW"] = "Defines or manages a database view.",
  ["VIRTUAL"] = "Indicates a virtual generated column.",
  ["VISIBLE"] = "Makes a column or index visible to queries.",
  ["WAIT"] = "Waits for a lock or resource.",
  ["WARNINGS"] = "Shows warnings from the last statement.",
  ["WEEK"] = "Extracts the week from a date expression.",
  ["WHEN"] = "Part of CASE or IF, specifies a condition.",
  ["WHERE"] = "Filters rows based on a condition.",
  ["WHILE"] = "Defines a while loop in stored programs.",
  ["WITH"] = "Used in CTEs, subqueries, or replication settings.",
  ["WORK"] = "Used in transaction control (e.g., COMMIT WORK).",
  ["WRITE"] = "Sets write mode for locks or transactions.",
  ["XOR"] = "Logical XOR operation.",
  ["YEAR"] = "Extracts the year from a date expression.",
  ["ZEROFILL"] = "Pads numeric values with zeros."
}

local MySQLFunctions = {
  ["COUNT"] = true,
  ["SUM"] = true,
  ["AVG"] = true,
  ["MAX"] = true,
  ["MIN"] = true,
  ["GROUP_CONCAT"] = true,
  ["COALESCE"] = true,
  ["CONCAT"] = true,
  ["NOW"] = true,
  ["CURRENT_TIMESTAMP"] = true,
  ["DATE_ADD"] = true,
  ["DATE_SUB"] = true,
  ["BIT_AND"] = true,
  ["BIT_OR"] = true,
  ["BIT_XOR"] = true,
  ["STD"] = true,
  ["STDDEV"] = true,
  ["STDDEV_POP"] = true,
  ["STDDEV_SAMP"] = true,
  ["VAR_POP"] = true,
  ["VAR_SAMP"] = true,
  ["VARIANCE"] = true,
  ["ASCII"] = true,
  ["BIN"] = true,
  ["BIT_LENGTH"] = true,
  ["CHAR"] = true,
  ["CHAR_LENGTH"] = true,
  ["CHARACTER_LENGTH"] = true,
  ["CONCAT_WS"] = true,
  ["ELT"] = true,
  ["EXPORT_SET"] = true,
  ["FIELD"] = true,
  ["FIND_IN_SET"] = true,
  ["FORMAT"] = true,
  ["FROM_BASE64"] = true,
  ["HEX"] = true,
  ["INSTR"] = true,
  ["LCASE"] = true,
  ["LEFT"] = true,
  ["LENGTH"] = true,
  ["LIKE"] = true,
  ["LOAD_FILE"] = true,
  ["LOCATE"] = true,
  ["LOWER"] = true,
  ["LPAD"] = true,
  ["LTRIM"] = true,
  ["MAKE_SET"] = true,
  ["MID"] = true,
  ["OCT"] = true,
  ["OCTET_LENGTH"] = true,
  ["ORD"] = true,
  ["POSITION"] = true,
  ["QUOTE"] = true,
  ["REGEXP_INSTR"] = true,
  ["REGEXP_LIKE"] = true,
  ["REGEXP_REPLACE"] = true,
  ["REGEXP_SUBSTR"] = true,
  ["REPEAT"] = true,
  ["REVERSE"] = true,
  ["RIGHT"] = true,
  ["RPAD"] = true,
  ["RTRIM"] = true,
  ["SOUNDEX"] = true,
  ["SPACE"] = true,
  ["STRCMP"] = true,
  ["SUBSTR"] = true,
  ["SUBSTRING"] = true,
  ["SUBSTRING_INDEX"] = true,
  ["TO_BASE64"] = true,
  ["TRIM"] = true,
  ["UCASE"] = true,
  ["UNHEX"] = true,
  ["UPPER"] = true,
  ["WEIGHT_STRING"] = true,
  ["ABS"] = true,
  ["ACOS"] = true,
  ["ASIN"] = true,
  ["ATAN"] = true,
  ["ATAN2"] = true,
  ["CEIL"] = true,
  ["CEILING"] = true,
  ["CONV"] = true,
  ["COS"] = true,
  ["COT"] = true,
  ["CRC32"] = true,
  ["DEGREES"] = true,
  ["DIV"] = true,
  ["EXP"] = true,
  ["FLOOR"] = true,
  ["LN"] = true,
  ["LOG"] = true,
  ["LOG10"] = true,
  ["LOG2"] = true,
  ["MOD"] = true,
  ["PI"] = true,
  ["POW"] = true,
  ["POWER"] = true,
  ["RADIANS"] = true,
  ["RAND"] = true,
  ["ROUND"] = true,
  ["SIGN"] = true,
  ["SIN"] = true,
  ["SQRT"] = true,
  ["TAN"] = true,
  ["TRUNCATE"] = true,
  ["ADDDATE"] = true,
  ["ADDTIME"] = true,
  ["CURDATE"] = true,
  ["CURRENT_DATE"] = true,
  ["CURRENT_TIME"] = true,
  ["CURTIME"] = true,
  ["DATE"] = true,
  ["DATE_FORMAT"] = true,
  ["DATEDIFF"] = true,
  ["DAY"] = true,
  ["DAYNAME"] = true,
  ["DAYOFMONTH"] = true,
  ["DAYOFWEEK"] = true,
  ["DAYOFYEAR"] = true,
  ["EXTRACT"] = true,
  ["FROM_DAYS"] = true,
  ["FROM_UNIXTIME"] = true,
  ["GET_FORMAT"] = true,
  ["HOUR"] = true,
  ["LAST_DAY"] = true,
  ["LOCALTIME"] = true,
  ["LOCALTIMESTAMP"] = true,
  ["MAKEDATE"] = true,
  ["MAKETIME"] = true,
  ["MICROSECOND"] = true,
  ["MINUTE"] = true,
  ["MONTH"] = true,
  ["MONTHNAME"] = true,
  ["PERIOD_ADD"] = true,
  ["PERIOD_DIFF"] = true,
  ["QUARTER"] = true,
  ["SEC_TO_TIME"] = true,
  ["SECOND"] = true,
  ["STR_TO_DATE"] = true,
  ["SUBDATE"] = true,
  ["SUBTIME"] = true,
  ["SYSDATE"] = true,
  ["TIME"] = true,
  ["TIME_FORMAT"] = true,
  ["TIME_TO_SEC"] = true,
  ["TIMEDIFF"] = true,
  ["TIMESTAMP"] = true,
  ["TIMESTAMPADD"] = true,
  ["TIMESTAMPDIFF"] = true,
  ["TO_DAYS"] = true,
  ["TO_SECONDS"] = true,
  ["UNIX_TIMESTAMP"] = true,
  ["UTC_DATE"] = true,
  ["UTC_TIME"] = true,
  ["UTC_TIMESTAMP"] = true,
  ["WEEK"] = true,
  ["WEEKDAY"] = true,
  ["WEEKOFYEAR"] = true,
  ["YEAR"] = true,
  ["YEARWEEK"] = true,
  ["CASE"] = true,
  ["IF"] = true,
  ["IFNULL"] = true,
  ["NULLIF"] = true,
  ["JSON_ARRAY"] = true,
  ["JSON_ARRAY_APPEND"] = true,
  ["JSON_ARRAY_INSERT"] = true,
  ["JSON_CONTAINS"] = true,
  ["JSON_CONTAINS_PATH"] = true,
  ["JSON_DEPTH"] = true,
  ["JSON_EXTRACT"] = true,
  ["JSON_INSERT"] = true,
  ["JSON_KEYS"] = true,
  ["JSON_LENGTH"] = true,
  ["JSON_MERGE"] = true,
  ["JSON_MERGE_PATCH"] = true,
  ["JSON_MERGE_PRESERVE"] = true,
  ["JSON_OBJECT"] = true,
  ["JSON_PRETTY"] = true,
  ["JSON_QUOTE"] = true,
  ["JSON_REMOVE"] = true,
  ["JSON_REPLACE"] = true,
  ["JSON_SEARCH"] = true,
  ["JSON_SET"] = true,
  ["JSON_TABLE"] = true,
  ["JSON_TYPE"] = true,
  ["JSON_UNQUOTE"] = true,
  ["JSON_VALID"] = true,
  ["JSON_VALUE"] = true,
  ["MEMBER OF"] = true,
  ["ST_AREA"] = true,
  ["ST_ASBINARY"] = true,
  ["ST_ASGEOJSON"] = true,
  ["ST_ASTEXT"] = true,
  ["ST_BUFFER"] = true,
  ["ST_CENTROID"] = true,
  ["ST_CONTAINS"] = true,
  ["ST_CONVEXHULL"] = true,
  ["ST_CROSSES"] = true,
  ["ST_DIFFERENCE"] = true,
  ["ST_DIMENSION"] = true,
  ["ST_DISJOINT"] = true,
  ["ST_DISTANCE"] = true,
  ["ST_ENVELOPE"] = true,
  ["ST_EQUALS"] = true,
  ["ST_GEOMCOLLFROMTEXT"] = true,
  ["ST_GEOMCOLLFROMWKB"] = true,
  ["ST_GEOMFROMGEOJSON"] = true,
  ["ST_GEOMFROMTEXT"] = true,
  ["ST_GEOMFROMWKB"] = true,
  ["ST_INTERSECTION"] = true,
  ["ST_INTERSECTS"] = true,
  ["ST_ISCLOSED"] = true,
  ["ST_ISEMPTY"] = true,
  ["ST_ISSIMPLE"] = true,
  ["ST_LENGTH"] = true,
  ["ST_NUMGEOMETRIES"] = true,
  ["ST_NUMINTERIORRING"] = true,
  ["ST_NUMPOINTS"] = true,
  ["ST_OVERLAPS"] = true,
  ["ST_POINTFROMTEXT"] = true,
  ["ST_POINTFROMWKB"] = true,
  ["ST_SIMPLIFY"] = true,
  ["ST_SRID"] = true,
  ["ST_STARTPOINT"] = true,
  ["ST_SYMDIFFERENCE"] = true,
  ["ST_TOUCHES"] = true,
  ["ST_UNION"] = true,
  ["ST_VALIDATE"] = true,
  ["ST_WITHIN"] = true,
  ["ST_X"] = true,
  ["ST_Y"] = true,
  ["MBRCONTAINS"] = true,
  ["MBRCOVEREDBY"] = true,
  ["MBRCOVERS"] = true,
  ["MBRDISJOINT"] = true,
  ["MBREQUAL"] = true,
  ["MBRINTERSECTS"] = true,
  ["MBROVERLAPS"] = true,
  ["MBRTOUCHES"] = true,
  ["MBRWITHIN"] = true,
  ["AES_DECRYPT"] = true,
  ["AES_ENCRYPT"] = true,
  ["COMPRESS"] = true,
  ["MD5"] = true,
  ["RANDOM_BYTES"] = true,
  ["SHA"] = true,
  ["SHA1"] = true,
  ["SHA2"] = true,
  ["UNCOMPRESS"] = true,
  ["UNCOMPRESSED_LENGTH"] = true,
  ["BENCHMARK"] = true,
  ["CHARSET"] = true,
  ["COLLATION"] = true,
  ["CONNECTION_ID"] = true,
  ["CURRENT_ROLE"] = true,
  ["CURRENT_USER"] = true,
  ["DATABASE"] = true,
  ["FOUND_ROWS"] = true,
  ["LAST_INSERT_ID"] = true,
  ["ROLES_GRAPHML"] = true,
  ["ROW_COUNT"] = true,
  ["SCHEMA"] = true,
  ["SESSION_USER"] = true,
  ["SYSTEM_USER"] = true,
  ["USER"] = true,
  ["VERSION"] = true,
  ["ANY_VALUE"] = true,
  ["BIN_TO_UUID"] = true,
  ["CAST"] = true,
  ["CONVERT"] = true,
  ["DEFAULT"] = true,
  ["GET_LOCK"] = true,
  ["GROUPING"] = true,
  ["INET_ATON"] = true,
  ["INET_NTOA"] = true,
  ["INET6_ATON"] = true,
  ["INET6_NTOA"] = true,
  ["IS_FREE_LOCK"] = true,
  ["IS_IPV4"] = true,
  ["IS_IPV4_COMPAT"] = true,
  ["IS_IPV4_MAPPED"] = true,
  ["IS_IPV6"] = true,
  ["IS_USED_LOCK"] = true,
  ["IS_UUID"] = true,
  ["MASTER_POS_WAIT"] = true,
  ["NAME_CONST"] = true,
  ["RELEASE_ALL_LOCKS"] = true,
  ["RELEASE_LOCK"] = true,
  ["SLEEP"] = true,
  ["UUID"] = true,
  ["UUID_SHORT"] = true,
  ["UUID_TO_BIN"] = true,
  ["VALUES"] = true
}

local TokenType = { KEYWORD = "KEYWORD", IDENTIFIER = "IDENTIFIER", STRING = "STRING", NUMBER = "NUMBER", OPERATOR = "OPERATOR", PUNCTUATION = "PUNCTUATION", WHITESPACE = "WHITESPACE", VARIABLE = "VARIABLE", PLACEHOLDER = "PLACEHOLDER" }

local TokenCategories = {
  [1] = { name = "Query Parameter", description = "MySQL keyword that defines query structure (e.g., SELECT, WHERE)." },
  [2] = { name = "Column", description = "Column name or alias used in the query (e.g., age, name)." },
  [3] = { name = "Table", description = "Table name or alias used in the query (e.g., users)." },
  [4] = { name = "String Literal", description = "String value in quotes (e.g., 'John')." },
  [5] = { name = "Numeric Literal", description = "Numeric value (e.g., 18)." },
  [6] = { name = "Operator", description = "Operator used in conditions or expressions (e.g., =, >)." },
  [7] = { name = "Punctuation", description = "Punctuation mark (e.g., comma, semicolon)." },
  [8] = { name = "Function", description = "Built-in MySQL function (e.g., COUNT, SUM)." },
  [9] = { name = "Alias", description = "Alias defined with AS or implied (e.g., dept in SELECT department AS dept)." },
  [10] = { name = "User Variable", description = "MySQL user variable (e.g., @rownum)." },
  [11] = { name = "Placeholder", description = "Query parameter placeholder (e.g., %i, %s)." },
  [12] = { name = "Whitespace", description = "Whitespace character (e.g., space, tab, newline)." }
}

local QueryParser = {}
QueryParser.__index = QueryParser

function QueryParser.New()
  local self = setmetatable({}, QueryParser)
  self.tokens = {}
  self.currentTokenIndex = 1
  self.originalQuery = ""
  return self
end

function QueryParser:Tokenize(query)
  self.tokens = {}
  self.originalQuery = query
  local upperQuery = query:upper()
  local i = 1
  local len = #query
  local maxTokens = 1000

  while i <= len do
    if #self.tokens >= maxTokens then
      print("GProfiler Error: Token limit reached (" .. maxTokens .. "). Possible infinite loop.")
      break
    end

    local char = upperQuery:sub(i, i)
    local matched = false
    local startPos = i

    if char:match("%s") then
      local ws = query:sub(i, i)
      i = i + 1
      table.insert(self.tokens, {
        type = TokenType.WHITESPACE,
        value = ws,
        upperValue = char
      })
      matched = true
    end

    if not matched and (char == "'" or char == '"') then
      local str = char
      local innerStr = ""
      local quote = char
      i = i + 1
      while i <= len and upperQuery:sub(i, i) ~= quote do
        str = str .. query:sub(i, i)
        innerStr = innerStr .. query:sub(i, i)
        i = i + 1
      end
      if i <= len then
        str = str .. quote
        i = i + 1
      end
      table.insert(self.tokens, {
        type = TokenType.STRING,
        value = str,
        upperValue = innerStr:upper()
      })
      matched = true
    end

    if not matched and char == "`" then
      local ident = "`"
      local innerIdent = ""
      i = i + 1
      while i <= len and upperQuery:sub(i, i) ~= "`" do
        ident = ident .. query:sub(i, i)
        innerIdent = innerIdent .. query:sub(i, i)
        i = i + 1
      end
      if i <= len then
        ident = ident .. "`"
        i = i + 1
      end
      table.insert(self.tokens, {
        type = TokenType.IDENTIFIER,
        value = ident,
        upperValue = innerIdent:upper()
      })
      matched = true
    end

    if not matched and char:match("%d") then
      local num = ""
      while i <= len and (upperQuery:sub(i, i):match("%d") or upperQuery:sub(i, i) == ".") do
        num = num .. query:sub(i, i)
        i = i + 1
      end
      table.insert(self.tokens, {
        type = TokenType.NUMBER,
        value = num,
        upperValue = num
      })
      matched = true
    end

    if not matched and char == "@" then
      local var = "@"
      i = i + 1
      while i <= len and upperQuery:sub(i, i):match("[A-Z0-9_#]") do
        var = var .. query:sub(i, i)
        i = i + 1
      end
      table.insert(self.tokens, {
        type = TokenType.VARIABLE,
        value = var,
        upperValue = var:upper()
      })
      matched = true
    end

    if not matched and char == "%" and i < len and upperQuery:sub(i + 1, i + 1):match("[IS]") then
      local placeholder = query:sub(i, i + 1)
      i = i + 2
      table.insert(self.tokens, {
        type = TokenType.PLACEHOLDER,
        value = placeholder,
        upperValue = placeholder:upper()
      })
      matched = true
    end

    if not matched and (char:match("[=<>!+-/*(),;.]") or (char == ":" and i < len and upperQuery:sub(i + 1, i + 1) == "=")) then
      local op = char
      local increment = 1
      if i < len then
        local nextChar = upperQuery:sub(i + 1, i + 1)
        if char == "<" and nextChar == ">" then
          op = "<>"
          increment = 2
        elseif char == "!" and nextChar == "=" then
          op = "!="
          increment = 2
        elseif char == ":" and nextChar == "=" then
          op = ":="
          increment = 2
        end
      end
      local origOp = query:sub(startPos, startPos + increment - 1)
      i = i + increment
      local tokenType = (op == "," or op == ";" or op == ".") and TokenType.PUNCTUATION or TokenType.OPERATOR
      table.insert(self.tokens, {
        type = tokenType,
        value = origOp,
        upperValue = op
      })
      matched = true
    end

    if not matched and char:match("[A-Z0-9_#]") then
      local word = ""
      while i <= len and upperQuery:sub(i, i):match("[A-Z0-9_#]") do
        word = word .. query:sub(i, i)
        i = i + 1
      end
      local upperWord = word:upper()
      local tokenType = (MySQLKeywords[upperWord] or MySQLFunctions[upperWord]) and TokenType.KEYWORD or TokenType.IDENTIFIER
      table.insert(self.tokens, {
        type = tokenType,
        value = word,
        upperValue = upperWord
      })
      matched = true
    end

    if not matched then
      table.insert(self.tokens, {
        type = TokenType.IDENTIFIER,
        value = query:sub(i, i),
        upperValue = char
      })
      i = i + 1
    end
  end
end

function QueryParser:GetNextToken()
  local token = self.tokens[self.currentTokenIndex]
  self.currentTokenIndex = self.currentTokenIndex + 1
  return token
end

function QueryParser:Parse(query)
  self:Tokenize(query)
  self.currentTokenIndex = 1
  local structure = {}
  local currentSection = nil
  local subqueryLevel = 0
  local maxSections = 200

  while self.currentTokenIndex <= #self.tokens do
    if table.Count(structure) >= maxSections then
      print("GProfiler Error: Section limit reached (" .. maxSections .. ").")
      break
    end

    local token = self:GetNextToken()
    if not token then break end

		local tuv = token.upperValue
    if token.type == TokenType.KEYWORD then
      if tuv == "SELECT" or tuv == "INSERT" or tuv == "UPDATE" or tuv == "DELETE" or tuv == "CREATE" or tuv == "ALTER" or tuv == "DROP" then
        currentSection = "LEVEL" .. subqueryLevel .. "_" .. tuv
        structure[currentSection] = {tokens = {}, explanation = MySQLKeywords[tuv] or "Unknown keyword"}
      elseif currentSection and (tuv == "FROM" or tuv == "WHERE" or tuv == "JOIN" or tuv == "GROUP" or tuv == "HAVING" or tuv == "ORDER" or tuv == "LIMIT") then
        currentSection = "LEVEL" .. subqueryLevel .. "_" .. tuv
        structure[currentSection] = {tokens = {}, explanation = MySQLKeywords[tuv] or "Unknown keyword"}
      end
      if currentSection then table.insert(structure[currentSection].tokens, token) end
    elseif token.type == TokenType.OPERATOR and tuv == "(" then
      subqueryLevel = subqueryLevel + 1
      if currentSection then table.insert(structure[currentSection].tokens, token) end
    elseif token.type == TokenType.OPERATOR and tuv == ")" then
      subqueryLevel = math.max(subqueryLevel - 1, 0)
      if currentSection then table.insert(structure[currentSection].tokens, token) end
    elseif currentSection and token.type ~= TokenType.WHITESPACE then
      table.insert(structure[currentSection].tokens, token)
    end
  end
  return structure
end

function QueryParser:ParseTemplate(query)
  self:Tokenize(query)
  local template = {}
  local currentSection = nil
  local expectAlias = false
  local subqueryLevel = 0
  local maxTokens = 2000

  for i, token in ipairs(self.tokens) do
    if #template >= maxTokens then
      print("GProfiler Error: Template token limit reached (" .. maxTokens .. ").")
      break
    end

    if token.type == TokenType.WHITESPACE then
      if token.value == "\n" then table.insert(template, {token.value, 12}) continue end
    end

    local category
		local tuv = token.upperValue
    if token.type == TokenType.KEYWORD then
      if MySQLFunctions[tuv] then
        category = 8 -- Function
      else
        category = 1 -- Query Parameter
      end
      -- Track sections
      if tuv == "SELECT" or tuv == "INSERT" or tuv == "UPDATE" or tuv == "DELETE" or tuv == "CREATE" or tuv == "ALTER" or tuv == "DROP" then
        currentSection = tuv
      elseif tuv == "FROM" or tuv == "WHERE" or tuv == "JOIN" or tuv == "GROUP" or tuv == "HAVING" or tuv == "ORDER" or tuv == "LIMIT" then
        currentSection = tuv
      end
      if tuv == "AS" then
        expectAlias = true
      end
    elseif token.type == TokenType.IDENTIFIER then
      if expectAlias then
        category = 9 -- Alias
        expectAlias = false
      elseif currentSection == "FROM" or currentSection == "JOIN" then
        category = 3 -- Table
      elseif currentSection == "SELECT" or currentSection == "WHERE" or currentSection == "UPDATE" or currentSection == "INSERT" or currentSection == "CREATE" then
        category = 2 -- Column
      else
        category = 2 -- Default to column
      end
    elseif token.type == TokenType.VARIABLE then
      category = 10 -- User Variable
    elseif token.type == TokenType.PLACEHOLDER then
      category = 11 -- Placeholder
    elseif token.type == TokenType.STRING then
      category = 4 -- String Literal
    elseif token.type == TokenType.NUMBER then
      category = 5 -- Numeric Literal
    elseif token.type == TokenType.OPERATOR then
      category = 6 -- Operator
      if tuv == "(" then
        subqueryLevel = subqueryLevel + 1
      elseif tuv == ")" then
        subqueryLevel = math.max(subqueryLevel - 1, 0)
      end
    elseif token.type == TokenType.PUNCTUATION then
      category = 7 -- Punctuation
    elseif token.type == TokenType.WHITESPACE then
      category = 12
    else
      category = 0 -- Unknown
    end

    table.insert(template, {token.value, category})
  end

  return template
end

GProfiler.Database.QueryParser = QueryParser
GProfiler.Database.TokenCategories = TokenCategories
GProfiler.Database.MySQLKeywords = MySQLKeywords
GProfiler.Database.MySQLFunctions = MySQLFunctions
