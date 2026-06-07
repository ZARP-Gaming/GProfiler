PROJECT_GENERATOR_VERSION = 3

newoption({
	trigger = "gmcommon",
	description = "Sets the path to the garrysmod_common (x86-64-support-sourcesdk) directory",
	value = "path to garrysmod_common dir"
})

local gmcommon = assert(_OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON"),
	"Provide the garrysmod_common path via --gmcommon=PATH or the GARRYSMOD_COMMON environment variable")
include(gmcommon)

CreateWorkspace({name = "gprofiler"})
	CreateProject({serverside = true})
		IncludeLuaShared()

	CreateProject({serverside = false})
		IncludeLuaShared()
