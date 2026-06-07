// thanks claude

#include <GarrysMod/Lua/Interface.h>
#include <string>
#include <unordered_map>
#include <cstddef>

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

using namespace GarrysMod::Lua;

extern "C" {
	typedef void (*profile_callback)(void *data, void *L, int samples, int vmstate);
	typedef void (*fn_profile_start)(void *L, const char *mode, profile_callback cb, void *data);
	typedef void (*fn_profile_stop)(void *L);
	typedef const char *(*fn_profile_dumpstack)(void *L, const char *fmt, int depth, size_t *len);
}

static fn_profile_start g_start = nullptr;
static fn_profile_stop g_stop = nullptr;
static fn_profile_dumpstack g_dumpstack = nullptr;

static lua_State *g_state = nullptr;

static bool g_running = false;
static unsigned int g_total = 0;
static std::unordered_map<std::string, unsigned int> g_samples;
static std::unordered_map<char, unsigned int> g_vmstates;

static std::string g_dumpfmt = "l;";
static int g_depth = 60;

static void *ResolveSymbol(const char *name) {
	HMODULE mod = GetModuleHandleA("lua_shared.dll");
	if (!mod) return nullptr;
	return reinterpret_cast<void *>(GetProcAddress(mod, name));
}

static void LoadProfilerAPI() {
	g_start = reinterpret_cast<fn_profile_start>(ResolveSymbol("luaJIT_profile_start"));
	g_stop = reinterpret_cast<fn_profile_stop>(ResolveSymbol("luaJIT_profile_stop"));
	g_dumpstack = reinterpret_cast<fn_profile_dumpstack>(ResolveSymbol("luaJIT_profile_dumpstack"));
}

static bool ProfilerAvailable() {
	return g_start && g_stop && g_dumpstack;
}

static void ProfileCallback(void *data, void *L, int samples, int vmstate) {
	g_total += static_cast<unsigned int>(samples);
	g_vmstates[static_cast<char>(vmstate)] += static_cast<unsigned int>(samples);

	if (!g_dumpstack) return;

	size_t len = 0;
	const char *stack = g_dumpstack(L, g_dumpfmt.c_str(), g_depth, &len);
	if (!stack || len == 0) return;

	std::string key;
	key.reserve(len + 2);
	key += static_cast<char>(vmstate);
	key += '\t';
	key.append(stack, len);
	g_samples[key] += static_cast<unsigned int>(samples);
}

LUA_FUNCTION(gprofiler_Available) {
	LUA->PushBool(ProfilerAvailable());
	return 1;
}

LUA_FUNCTION(gprofiler_IsRunning) {
	LUA->PushBool(g_running);
	return 1;
}

LUA_FUNCTION(gprofiler_Reset) {
	g_samples.clear();
	g_vmstates.clear();
	g_total = 0;
	return 0;
}

LUA_FUNCTION(gprofiler_Start) {
	if (!ProfilerAvailable() || g_running) {
		LUA->PushBool(false);
		return 1;
	}

	const char *mode = "li1";
	if (LUA->IsType(1, Type::String)) mode = LUA->GetString(1);
	if (LUA->IsType(2, Type::String)) g_dumpfmt = LUA->GetString(2);
	if (LUA->IsType(3, Type::Number)) g_depth = static_cast<int>(LUA->GetNumber(3));

	g_samples.clear();
	g_vmstates.clear();
	g_total = 0;

	g_start(g_state, mode, ProfileCallback, nullptr);
	g_running = true;

	LUA->PushBool(true);
	return 1;
}

LUA_FUNCTION(gprofiler_Stop) {
	if (!g_running) return 0;
	g_stop(g_state);
	g_running = false;
	return 0;
}

LUA_FUNCTION(gprofiler_Query) {
	LUA->CreateTable();
	for (const auto &pair : g_samples) {
		LUA->PushNumber(static_cast<double>(pair.second));
		LUA->SetField(-2, pair.first.c_str());
	}

	LUA->PushNumber(static_cast<double>(g_total));

	LUA->CreateTable();
	for (const auto &pair : g_vmstates) {
		const char key[2] = { pair.first, '\0' };
		LUA->PushNumber(static_cast<double>(pair.second));
		LUA->SetField(-2, key);
	}

	return 3;
}

LUA_FUNCTION(gprofiler_Snapshot) {
	LUA->PushNumber(static_cast<double>(g_total));

	LUA->CreateTable();
	for (const auto &pair : g_vmstates) {
		const char key[2] = { pair.first, '\0' };
		LUA->PushNumber(static_cast<double>(pair.second));
		LUA->SetField(-2, key);
	}

	return 2;
}

extern "C" GMOD_DLL_EXPORT int gmod13_open(lua_State *L) {
	g_state = L;
	ILuaBase *LUA = L->luabase;
	LUA->SetState(L);

	LoadProfilerAPI();

	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->CreateTable();

	LUA->PushCFunction(gprofiler_Available); LUA->SetField(-2, "Available");
	LUA->PushCFunction(gprofiler_IsRunning); LUA->SetField(-2, "IsRunning");
	LUA->PushCFunction(gprofiler_Reset); LUA->SetField(-2, "Reset");
	LUA->PushCFunction(gprofiler_Start); LUA->SetField(-2, "Start");
	LUA->PushCFunction(gprofiler_Stop); LUA->SetField(-2, "Stop");
	LUA->PushCFunction(gprofiler_Query); LUA->SetField(-2, "Query");
	LUA->PushCFunction(gprofiler_Snapshot); LUA->SetField(-2, "Snapshot");

	LUA->SetField(-2, "gprofiler");
	LUA->Pop();

	return 0;
}

extern "C" GMOD_DLL_EXPORT int gmod13_close(lua_State *L) {
	if (g_running && g_stop) {
		g_stop(g_state);
		g_running = false;
	}
	return 0;
}
