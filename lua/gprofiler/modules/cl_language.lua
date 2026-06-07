-- TODO: v2 currently uses none of this

GProfiler.Language = GProfiler.Language or {}
GProfiler.Language.Langs = GProfiler.Language.Langs or {}

function GProfiler.Language:AddLanguage(lang, cb)
	GProfiler.Language.Langs[lang] = {}

	local LangGroup = {}

	function LangGroup:AddPhrase(key, phrase)
		self[key] = phrase
	end

	cb(LangGroup)

	GProfiler.Language.Langs[lang] = LangGroup
end

function GProfiler.Language.GetPhrase(key)
	local Lang = GProfiler.Language.Langs[GProfiler.Config.Language]
	if not Lang then Lang = GProfiler.Language.Langs["english"] end

	return Lang[key] or (GProfiler.Config.Language ~= "english" and GProfiler.Language.Langs["english"][key] or key) or key
end

GProfiler.Language:AddLanguage("english", function(Lang)
	-- Tab Names
	Lang:AddPhrase("tab_overview", "Overview")
	Lang:AddPhrase("tab_hooks", "Hooks")
	Lang:AddPhrase("tab_networking", "Network")
	Lang:AddPhrase("tab_functions", "Functions")
	Lang:AddPhrase("tab_commands", "Commands")
	Lang:AddPhrase("tab_timers", "Timers")
	Lang:AddPhrase("tab_entity_variables", "Entity Variables")
	Lang:AddPhrase("tab_network_variables", "Network Variables")
	Lang:AddPhrase("tab_database", "Database")
	Lang:AddPhrase("tab_jit_profiler", "JIT Profiler")
end)
