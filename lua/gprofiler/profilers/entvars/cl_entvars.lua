GProfiler.EntVars = GProfiler.EntVars or {}

local EntVars = GProfiler.EntVars
EntVars.ProfileData = EntVars.ProfileData or {}

GProfiler.Profilers.Register("Entity Variables", {
	Realms = {"Client"},
	OnStart = function(realm, ply)
		EntVars.ProfileActive = true
		EntVars.ProfileData = {}
	end,
	OnStop = function(realm, ply)
		EntVars.ProfileActive = false
		local EntVarsStore = GProfiler.Profilers.GetStore("Entity Variables")
		if EntVarsStore then
			EntVarsStore:SetData(realm, EntVars.ProfileData)
		end
		if EntVars.RefreshUI then EntVars.RefreshUI() end
	end
})
local EntVarsStore = GProfiler.Profilers.GetStore("Entity Variables")

function GProfiler.EntVars.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Entity Variables", "gprofiler/entvars.png")
	local StartStop = Header:SetupStartStop(EntVarsStore:IsActive("Client"))
	local Timer = Header:SetupTimer(function()
		return EntVarsStore:GetTimerData("Client")
	end)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("Entity Variables", "Client", Running)
		if EntVars.RefreshUI then EntVars.RefreshUI() end
	end

	local Header = GProfiler.Utils.SetupHeader(Base, "Profiler Results", nil, true)
	local ResultsList = GProfiler.Utils.CreateList(Base, Header, {"Entity", "Variable", "Times Changed", "Current Value"})
	ResultsList:SetTall(Base:GetTall() - Header:GetTall())
	ResultsList.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(38, 63, 89, 255))
	end

	local function PopulateResults()
		if not IsValid(ResultsList) then return end

		local realmData = EntVarsStore:GetData("Client") or {}

		ResultsList:Clear()

		for k, v in pairs(realmData) do
			for var, count in pairs(v) do
				if var == "GProfiler_SavedEnt" or var == "GProfiler_CurrentValues" then continue end
				local currentVal = v.GProfiler_CurrentValues and v.GProfiler_CurrentValues[var] or "N/A"
				ResultsList:AddLine(v.GProfiler_SavedEnt or "N/A", var, count, currentVal)
			end
		end
	end
	EntVars.RefreshUI = PopulateResults
	PopulateResults()
end

GProfiler.Menu.RegisterTab("Entity Variables", "gprofiler/entvars.png", 6, GProfiler.EntVars.DoTab, function()
	local timer = EntVarsStore:GetTimerData("Client")
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

function GProfiler.EntVars.CollectData(ent, var, _, val)
	if not GProfiler.EntVars.ProfileActive then return end

	if not GProfiler.EntVars.ProfileData[ent] then
		GProfiler.EntVars.ProfileData[ent] = {
			GProfiler_SavedEnt = tostring(ent),
			GProfiler_CurrentValues = {}
		}
	end

	GProfiler.EntVars.ProfileData[ent][var] = (GProfiler.EntVars.ProfileData[ent][var] or 0) + 1
	GProfiler.EntVars.ProfileData[ent].GProfiler_CurrentValues[var] = tostring(val)
end

local function CaptureEnt(ent, attempts)
	if not IsValid(ent) then return end
	if not ent.GetNetworkVars then
		if attempts and attempts > 5 then return end
		timer.Simple(.5, function() CaptureEnt(ent, (attempts or 0) + 1) end)
		return
	end

	for k, v in pairs(ent:GetNetworkVars() or {}) do
		local GProfilerIdent = string.format("GProfiler.%s", k)
		if ent[GProfilerIdent] then continue end
		ent[GProfilerIdent] = true
		ent:NetworkVarNotify(k, GProfiler.EntVars.CollectData)
	end
end

hook.Add("OnEntityCreated", "GProfiler.EntVars.CaptureEnt", function(ent) timer.Simple(0, function() CaptureEnt(ent) end) end)
hook.Add("InitPostEntity", "GProfiler.EntVars.CaptureEnts", function()
	for k, v in ipairs(ents.GetAll()) do CaptureEnt(v) end
end)