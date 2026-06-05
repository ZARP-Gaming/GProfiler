GProfiler.Timers = GProfiler.Timers or {}
local Timers = GProfiler.Timers

Timers.Realm = Timers.Realm or "Client"

local TimersStore = GProfiler.Profilers.GetStore("Timers")

function GProfiler.Timers.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Timers", "gprofiler/timers.png")
	local initialActive = Timers.Realm == "Both" and (TimersStore:IsActive("Client") or TimersStore:IsActive("Server")) or TimersStore:IsActive(Timers.Realm)
	local StartStop = Header:SetupStartStop(initialActive)
	local RealmSelector = Header:SetupRealmSelector(Timers.Realm, true)
	local Timer = Header:SetupTimer(function()
		local realm = Timers.Realm == "Both" and "Client" or Timers.Realm
		return TimersStore:GetTimerData(realm)
	end)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("Timers", Timers.Realm, Running)

		if Timers.RefreshUI then
			Timers.RefreshUI()
		end
	end

	function RealmSelector:OnStateChanged(state)
		Timers.Realm = state
		if state == "Both" then
			StartStop.State = TimersStore:IsActive("Client") or TimersStore:IsActive("Server")
		else
			StartStop.State = TimersStore:IsActive(state)
		end
		StartStop:SetText(StartStop.State and "Stop" or "Start")
		if Timers.RefreshUI then
			Timers.RefreshUI()
		end
	end

	local left, Source = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "timers_lr", 0.65)
	local Results, ActivePanel = GProfiler.Utils.HSplitPanel(left, GProfiler.GetScaledSize(10), "timers_l_bt", 0.65)
	local ClientTimers, ServerTimers = GProfiler.Utils.VSplitPanel(ActivePanel, GProfiler.GetScaledSize(10), "timers_lb_lr", 0.5)

	local SourceHeader = vgui.Create("DLabel", Source)
	SourceHeader:SetFont("GProfiler.Inter24")
	SourceHeader:SetTextColor(GProfiler.SyntaxColors.comment)
	SourceHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	SourceHeader:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	SourceHeader:SetText("Select a timer to view source.")

	Source.Paint = function(s, w, h)
		GProfiler.RNDX.DrawScaled(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)
	end

	local RichText = vgui.Create("RichText", Source)
	RichText:SetText("")
	RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20) - GProfiler.GetScaledSize(30))
	RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(30))
	RichText:SetVerticalScrollbarEnabled(true)
	function RichText:PerformLayout()
		self:SetFontInternal("GProfiler.Code")
	end

	Source.OnHandleMoved = function()
		SourceHeader:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
		RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20) - GProfiler.GetScaledSize(30))
		RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(30))
		RichText:InvalidateLayout()
	end

	local Header = GProfiler.Utils.SetupHeader(Results, "Profiler Results", nil, true)
	local ResultsList = GProfiler.Utils.CreateList(Results, Header, {"Name", "Type", "Count", "Delay", "Total Time", "Avg Time", "Longest Time"})

	local function PopulateResults()
		if not IsValid(ResultsList) then return end

		local displayRealm = Timers.Realm == "Both" and "Client" or Timers.Realm
		local realmData = TimersStore:GetData(displayRealm) or {}

		ResultsList:Clear()

		local merged = table.Merge(realmData.Simple or {}, realmData.Create or {})
		for k, v in pairs(merged) do
			local line = ResultsList:AddLine(tostring(k), v.Type, v.Count, v.Delay, v.TotalTime, v.AverageTime, v.LongestTime)
			line.TimerData = v
		end
	end
	GProfiler.Timers.RefreshUI = PopulateResults
	PopulateResults()

	function ResultsList:OnRowSelected(rowIndex, row)
		local data = row.TimerData
		if data then
			RichText:SetText("Loading source...")
			SourceHeader:SetText("")

			local file = data.Source
			local lineDefined = data.Lines and data.Lines[1] or 0
			local lastLineDefined = data.Lines and data.Lines[2] or 0

			if file and file ~= "" then
				file = string.match(file, "@?(.+)")
				if not file then file = data.Source end

				SourceHeader:SetText(string.format("%s (%d - %d)", file, lineDefined, lastLineDefined))

				GProfiler.RequestFunctionSource(file, lineDefined, lastLineDefined, function(src)
					if src then
						GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), lineDefined)
					else
						RichText:SetText("Failed to load source")
					end
				end)
			else
				RichText:SetText("Failed to load source (2)")
			end
		end
	end

	local function CreateTimerList(Parent, ActiveList, Title)
		Parent:Clear()

		local HeaderPanel = vgui.Create("DPanel", Parent)
		HeaderPanel:SetSize(Parent:GetWide(), GProfiler.GetScaledSize(50))
		HeaderPanel.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(8, 0, 0, w, h, Color(34, 77, 122), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
			draw.SimpleText(Title, "GProfiler.Inter28", GProfiler.GetScaledSize(10), h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local RefreshButton = vgui.Create("DButton", HeaderPanel)
		RefreshButton:SetSize(GProfiler.GetScaledSize(80), GProfiler.GetScaledSize(30))
		RefreshButton:SetPos(HeaderPanel:GetWide() - RefreshButton:GetWide() - GProfiler.GetScaledSize(10), (HeaderPanel:GetTall() - RefreshButton:GetTall()) / 2)
		RefreshButton:SetText("Refresh")
		RefreshButton:SetFont("GProfiler.Inter24")
		RefreshButton:SetTextColor(Color(0,0,0,0))
		RefreshButton.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 20))
			if s:IsHovered() then
				GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 20))
			end
			draw.SimpleText("Refresh", "GProfiler.Inter24", w / 2, h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		RefreshButton.DoClick = function()
			net.Start("GProfiler_Timers_ActiveList")
			net.SendToServer()
		end

		local List = vgui.Create("DPanelList", Parent)
		List:SetSize(Parent:GetWide(), Parent:GetTall() - HeaderPanel:GetTall())
		List:SetPos(0, HeaderPanel:GetTall())
		List:EnableVerticalScrollbar()

		local ScrollBar = List.VBar
		ScrollBar:SetWide(GProfiler.GetScaledSize(12))
		ScrollBar:SetHideButtons(true)
		ScrollBar.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 10))
		end
		ScrollBar.btnGrip.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 20))
		end

		for k, v in ipairs(ActiveList) do
			local i = k
			local Item = vgui.Create("DButton", List)
			Item:SetSize(List:GetWide(), GProfiler.GetScaledSize(30))
			Item:SetText(v.Name)
			Item:SetFont("GProfiler.Inter24")
			Item:SizeToContentsY()
			Item:SetTall(Item:GetTall() + GProfiler.GetScaledSize(10))
			Item:SetContentAlignment(1)
			Item:SetTextColor(Color(0,0,0,0))
			Item.Paint = function(s, w, h)
				if i % 2 == 0 then
					GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 10))
				else
					GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 2))
				end

				if s:IsHovered() then
					GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 20))
				end

				draw.SimpleText(v.Name, "GProfiler.Inter24", GProfiler.GetScaledSize(10), h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			List:AddItem(Item)
		end

		Parent.OnHandleMoved = function()
			HeaderPanel:SetSize(Parent:GetWide(), HeaderPanel:GetTall())
			RefreshButton:SetPos(HeaderPanel:GetWide() - RefreshButton:GetWide() - GProfiler.GetScaledSize(10), (HeaderPanel:GetTall() - RefreshButton:GetTall()) / 2)
			List:SetSize(Parent:GetWide(), Parent:GetTall() - HeaderPanel:GetTall())
			List:SetPos(0, HeaderPanel:GetTall())
			for k, v in pairs(List:GetItems()) do
				v:SetSize(List:GetWide(), v:GetTall())
			end
		end
	end

	local CLTimers = {}
	local SVTimers = {}

	for _, v in ipairs(GProfiler.Timers.ActiveTimers.Create) do
		table.insert(CLTimers, { Name = v.Name })
	end

	CreateTimerList(ClientTimers, CLTimers, string.format("Client Timers (%d)", #CLTimers))

	net.Receive("GProfiler_Timers_ActiveList", function()
		SVTimers = {}
		for i = 1, net.ReadUInt(16) do
			table.insert(SVTimers, { Name = net.ReadString() })
		end

		CreateTimerList(ServerTimers, SVTimers, string.format("Server Timers (%d)", #SVTimers))
	end)

	net.Start("GProfiler_Timers_ActiveList")
	net.SendToServer()

	Results.OnHandleMoved = function()
		ResultsList:SetSize(Results:GetWide(), Results:GetTall() - Header:GetTall())
		ResultsList:SetPos(0, Header:GetTall())
		Header:SetWide(Results:GetWide())
	end
end

GProfiler.Menu.RegisterTab("Timers", "gprofiler/timers.png", 5, GProfiler.Timers.DoTab, function()
	local timer = TimersStore:GetTimerData(Timers.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

net.Receive("GProfiler_Timers_SendData", function()
	local isFirst = net.ReadBool()
	local isLast = net.ReadBool()
	local count = net.ReadUInt(32)

	local serverData = isFirst and { Simple = {}, Create = {} } or (TimersStore:GetData("Server") or { Simple = {}, Create = {} })

	for i = 1, count do
		local timerType = net.ReadString()
		local name = net.ReadString()
		serverData[timerType][name] = {
			Type = timerType,
			Count = net.ReadUInt(15),
			Delay = net.ReadFloat(),
			TotalTime = net.ReadFloat(),
			LongestTime = net.ReadFloat(),
			AverageTime = net.ReadFloat(),
			Source = net.ReadString(),
			Lines = {net.ReadUInt(14), net.ReadUInt(14)}
		}
	end

	TimersStore:SetData("Server", serverData)

	if isLast and Timers.RefreshUI then
		Timers.RefreshUI()
	end
end)
