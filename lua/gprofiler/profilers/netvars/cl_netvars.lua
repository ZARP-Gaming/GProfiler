GProfiler.NetVars = GProfiler.NetVars or {}
local NetVars = GProfiler.NetVars

GProfiler.Profilers.Register("Network Variables", {
	Realms = { "Server" }
})
local NetVarsStore = GProfiler.Profilers.GetStore("Network Variables")

function GProfiler.NetVars.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Network Variables", "gprofiler/netvars.png")
	local StartStop = Header:SetupStartStop(NetVarsStore:IsActive("Server"))
	local Timer = Header:SetupTimer(function()
		return NetVarsStore:GetTimerData("Server")
	end)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("Network Variables", "Server", Running)
		if NetVars.RefreshUI then NetVars.RefreshUI() end
	end

	local ListHeader = GProfiler.Utils.SetupHeader(Base, "Profiler Results", nil, true)
	local ResultsList = GProfiler.Utils.CreateList(Base, ListHeader, {"Entity", "Variable", "Type", "Times Updated", "Current Value"})

	local function PopulateResults()
		if not IsValid(ResultsList) then return end

		local data = NetVarsStore:GetData("Server") or {}

		ResultsList:Clear()

		for ent, vars in pairs(data) do
			for var, types in pairs(vars) do
				for type, info in pairs(types) do
					local row = ResultsList:AddLine(ent, var, type, info.TimesUpdated, tostring(info.CurValue))
					row.NVData = { ent = ent, var = var, type = type, TimesUpdated = info.TimesUpdated, CurValue = info.CurValue }
					row:SetSortValue(4, info.TimesUpdated or 0)
				end
			end
		end

		ResultsList:SortByColumn(4, true)
	end
	NetVars.RefreshUI = PopulateResults
	PopulateResults()

	ResultsList.OnRowRightClick = function(lst, rowIndex, row)
		local data = row and row.NVData
		if not data then return end

		local menu = DermaMenu()
		menu:AddOption("Copy Entity", function() SetClipboardText(tostring(data.ent)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Variable", function() SetClipboardText(tostring(data.var)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Type", function() SetClipboardText(tostring(data.type)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Times Updated", function() SetClipboardText(tostring(data.TimesUpdated)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Current Value", function() SetClipboardText(tostring(data.CurValue)) end):SetIcon("icon16/page_copy.png")
		menu:Open()
	end

	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
		ListHeader:SetWide(Base:GetWide())
		ResultsList:SetSize(Base:GetWide(), Base:GetTall() - ListHeader:GetTall())
		ResultsList:SetPos(0, ListHeader:GetTall())
	end
end

GProfiler.Menu.RegisterTab("Network Variables", "gprofiler/netvars.png", 7, GProfiler.NetVars.DoTab, function()
	local timer = NetVarsStore:GetTimerData("Server")
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

net.Receive("GProfiler_NetVars_SendData", function()
	local data = {}
	local numEnts = net.ReadUInt(32)
	for i = 1, numEnts do
		local ent = net.ReadString()
		data[ent] = {}
		local numVars = net.ReadUInt(32)
		for j = 1, numVars do
			local name = net.ReadString()
			data[ent][name] = {}
			local numTypes = net.ReadUInt(32)
			for k = 1, numTypes do
				local type = net.ReadString()
				data[ent][name][type] = {
					TimesUpdated = net.ReadUInt(32),
					CurValue = net.ReadString()
				}
			end
		end
	end

	NetVarsStore:SetData("Server", data)
	if NetVars.RefreshUI then NetVars.RefreshUI() end
end)
