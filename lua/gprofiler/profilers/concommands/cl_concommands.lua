GProfiler.ConCommands = GProfiler.ConCommands or {}
local ConCommands = GProfiler.ConCommands

local CommandsStore = GProfiler.Profilers.GetStore("Commands")

function GProfiler.ConCommands.DoTab(Base, Outer)
local Header = GProfiler.Utils.SetupHeader(Outer, "Commands", "gprofiler/commands.png")
	local initialActive = ConCommands.Realm == "Both" and (CommandsStore:IsActive("Client") or CommandsStore:IsActive("Server")) or CommandsStore:IsActive(ConCommands.Realm)
	local StartStop = Header:SetupStartStop(initialActive)
	local RealmSelector = Header:SetupRealmSelector(ConCommands.Realm, true)
	local Timer = Header:SetupTimer(function()
		local realm = ConCommands.Realm == "Both" and "Client" or ConCommands.Realm
		return CommandsStore:GetTimerData(realm)
	end)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("Commands", ConCommands.Realm, Running)

		if ConCommands.RefreshUI then
			ConCommands.RefreshUI()
		end
	end

	function RealmSelector:OnStateChanged(state)
		ConCommands.Realm = state
		if state == "Both" then
			StartStop.State = CommandsStore:IsActive("Client") or CommandsStore:IsActive("Server")
		else
			StartStop.State = CommandsStore:IsActive(state)
		end
		StartStop:SetText(StartStop.State and "Stop" or "Start")
		if ConCommands.RefreshUI then
			ConCommands.RefreshUI()
		end
	end

	local left, Source = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "hook_lr", 0.65)
	local Results, Receivers = GProfiler.Utils.HSplitPanel(left, GProfiler.GetScaledSize(10), "hook_l_bt", 0.65)
	local ClientHooks, ServerHooks = GProfiler.Utils.VSplitPanel(Receivers, GProfiler.GetScaledSize(10), "hook_lb_lr", 0.5)

	local SourceHeader = vgui.Create("DLabel", Source)
	SourceHeader:SetFont("GProfiler.Inter24")
	SourceHeader:SetTextColor(GProfiler.SyntaxColors.comment)
	SourceHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	SourceHeader:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	SourceHeader:SetText("Select a command to view source.")

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
	local ResultsList = GProfiler.Utils.CreateList(Results, Header, {"Command", "Calls", "Total Time", "Average Time", "Longest Time"})

	local function PopulateResults()
		if not IsValid(ResultsList) then return end

		local displayRealm = ConCommands.Realm == "Both" and "Client" or ConCommands.Realm
		local realmData = CommandsStore:GetData(displayRealm) or {}

		ResultsList:Clear()

		for k, v in pairs(realmData) do
			local line = ResultsList:AddLine(k, v.Count, v.Time, v.AverageTime, v.LongestTime)
			line.CmdData = v
		end
	end
	GProfiler.ConCommands.RefreshUI = PopulateResults
	PopulateResults()

	function ResultsList:OnRowSelected(rowIndex, row)
		local data = row.CmdData
		if data then
			RichText:SetText("Loading source...")
			SourceHeader:SetText("")

			local file = data.Source or data[4]
			local lineDefined = data.Lines and data.Lines[1] or data[5] or 0
			local lastLineDefined = data.Lines and data.Lines[2] or data[6] or 0

			if file and file ~= "" then
				file = string.match(file, "@?(.+)")
				if not file then file = data.Source or data[4] end

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

	local function CreateCmdList(Parent, Receivers, Title)
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
			net.Start("GProfiler_ConCommands_CommandList")
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

		for k, Receiver in ipairs(Receivers) do
			local i = k
			local Item = vgui.Create("DButton", List)
			Item:SetSize(List:GetWide(), GProfiler.GetScaledSize(30))
			Item:SetText(Receiver.Name)
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

				draw.SimpleText(Receiver.Name, "GProfiler.Inter24", GProfiler.GetScaledSize(10), h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

	local CLCmds = {}
	local SVCmds = {}

	for name, func in pairs(concommand.GetTable()) do
		table.insert(CLCmds, { Name = name })
	end


	local clr = CreateCmdList(ClientHooks, CLCmds, string.format("Client Commands (%d)", #CLCmds))

	net.Receive("GProfiler_ConCommands_CommandList", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		SVCmds = {}
		for i = 1, net.ReadUInt(32) do
			table.insert(SVCmds, { Name = net.ReadString(), Source = net.ReadString(), Lines = {net.ReadUInt(16), net.ReadUInt(16)} })
		end

		local svr = CreateCmdList(ServerHooks, SVCmds, string.format("Server Commands (%d)", #SVCmds))
	end)

	net.Start("GProfiler_ConCommands_CommandList")
	net.SendToServer()

	Results.OnHandleMoved = function()
		ResultsList:SetSize(Results:GetWide(), Results:GetTall() - Header:GetTall())
		ResultsList:SetPos(0, Header:GetTall())
		Header:SetWide(Results:GetWide())
	end
end

GProfiler.Menu.RegisterTab("Commands", "gprofiler/commands.png", 4, GProfiler.ConCommands.DoTab, function()
	local timer = CommandsStore:GetTimerData(GProfiler.ConCommands.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

net.Receive("GProfiler_ConCommands_SendData", function()
	local count = net.ReadUInt(32)
	local data = {}
	for i = 1, count do
		local name = net.ReadString()
		data[name] = {
			Count = net.ReadUInt(32),
			Time = net.ReadFloat(),
			AverageTime = net.ReadFloat(),
			LongestTime = net.ReadFloat(),
			Source = net.ReadString(),
			Lines = {net.ReadUInt(16), net.ReadUInt(16)}
		}
	end

	CommandsStore:SetData("Server", data)

	if GProfiler.ConCommands.RefreshUI then
		GProfiler.ConCommands.RefreshUI()
	end
end)