GProfiler.Timers = GProfiler.Timers or {}
GProfiler.Timers.Realm = GProfiler.Timers.Realm or "Client"
GProfiler.Timers.ProfileActive = GProfiler.Timers.ProfileActive or false
GProfiler.Timers.StartTime = GProfiler.Timers.StartTime or 0
GProfiler.Timers.EndTime = GProfiler.Timers.EndTime or 0

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

function GProfiler.Timers.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local RealmSelector = GProfiler.Menu.CreateRealmSelector(Header, "Timers", Header:GetWide() - TabPadding - 110, Header:GetTall() / 2 - 30 / 2, function(s, _, value)
		GProfiler.Timers.Realm = value
		GProfiler.Menu.OpenTab("Timers", GProfiler.Timers.DoTab)
	end)
	RealmSelector:SetPos(Header:GetWide() - RealmSelector:GetWide() - TabPadding, Header:GetTall() / 2 - RealmSelector:GetTall() / 2)

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.Timers.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
	StartButton:SetTextColor(MenuColors.White)
	StartButton:SetFont("GProfiler.Menu.StartButton")
	StartButton:SizeToContents()
	StartButton:SetTall(RealmSelector:GetTall())
	StartButton:SetPos(Header:GetWide() - StartButton:GetWide() - RealmSelector:GetWide() - TabPadding * 2, Header:GetTall() / 2 - StartButton:GetTall() / 2)
	StartButton.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
		draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

		if s:IsHovered() then
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
		end
	end

	local TimersTimeRunning = vgui.Create("DLabel", Header)
	TimersTimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	TimersTimeRunning:SetText(GProfiler.TimeRunning(GProfiler.Timers.StartTime, GProfiler.Timers.EndTime, GProfiler.Timers.ProfileActive) .. "s")
	TimersTimeRunning:SizeToContents()
	TimersTimeRunning:SetPos(Header:GetWide() - TimersTimeRunning:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - TimersTimeRunning:GetTall() / 2)
	TimersTimeRunning:SetTextColor(MenuColors.White)
	function TimersTimeRunning:Think()
		if GProfiler.Timers.ProfileActive then
			self:SetText(GProfiler.TimeRunning(GProfiler.Timers.StartTime, 0, GProfiler.Timers.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	StartButton.DoClick = function()
		if GProfiler.Timers.ProfileActive then
			GProfiler.Timers.EndTime = SysTime()
			if GProfiler.Timers.Realm == "Server" then
				GProfiler.Timers.Override = GProfiler.TimeRunning(GProfiler.Timers.StartTime, SysTime(), GProfiler.Timers.ProfileActive) .. "s"
				net.Start("GProfiler_Timers_ToggleServerProfile")
				net.WriteBool(false)
				net.SendToServer()
			else
				GProfiler.Timers:Stop()
				GProfiler.Timers.ProfileActive = false
				GProfiler.Menu.OpenTab("Timers", GProfiler.Timers.DoTab)
			end

			if timer.Exists("GProfiler.Timers.Time") then
				timer.Remove("GProfiler.Timers.Time")
			end
		else
			GProfiler.Timers.StartTime = SysTime()
			GProfiler.Timers.EndTime = 0
			GProfiler.Timers.Override = nil
			if GProfiler.Timers.Realm == "Server" then
				net.Start("GProfiler_Timers_ToggleServerProfile")
				net.WriteBool(true)
				net.SendToServer()
			else
				GProfiler.Timers:StartProfiler()
				GProfiler.Timers.ProfileActive = true
				StartButton:SetText(GProfiler.Language.GetPhrase("profiler_stop"))
			end
		end
	end

	local SectionHeader = vgui.Create("DPanel", Content)
	SectionHeader:SetSize(Content:GetWide(), 40)
	SectionHeader:SetPos(0, Header:GetTall())
	SectionHeader.Paint = nil

	local leftFraction = .7
	local rightFraction = .3

	local LeftHeader, LeftHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("profiler_results"), 0, 0, SectionHeader:GetWide() * leftFraction - 5, SectionHeader:GetTall())
	local RightHeader, RightHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("timer_function"), LeftHeader:GetWide() + 10, 0, SectionHeader:GetWide() * rightFraction - 5, LeftHeader:GetTall())

	local LeftContent = vgui.Create("DPanel", Content)
	LeftContent:SetSize(LeftHeader:GetWide(), Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	LeftContent:SetPos(0, SectionHeader:GetTall() + Header:GetTall())
	LeftContent.Paint = nil

	local RightContent = vgui.Create("DPanel", Content)
	RightContent:SetSize(RightHeader:GetWide(), Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	RightContent:SetPos(LeftContent:GetWide() + 10, SectionHeader:GetTall() + Header:GetTall())
	RightContent.Paint = nil

	local FunctionDetailsBackground = vgui.Create("DPanel", RightContent)
	FunctionDetailsBackground:SetSize(RightContent:GetWide() - TabPadding * 2, RightContent:GetTall() - TabPadding * 2)
	FunctionDetailsBackground:SetPos(TabPadding, TabPadding)
	FunctionDetailsBackground.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, MenuColors.CodeBackground) end

	local FunctionDetails = vgui.Create("DTextEntry", FunctionDetailsBackground)
	FunctionDetails:Dock(FILL)
	FunctionDetails:SetMultiline(true)
	FunctionDetails:SetKeyboardInputEnabled(false)
	FunctionDetails:SetVerticalScrollbarEnabled(true)
	FunctionDetails:SetDrawBackground(false)
	FunctionDetails:SetTextColor(MenuColors.White)
	FunctionDetails:SetFont("GProfiler.Menu.FunctionDetails")
	FunctionDetails:SetText(GProfiler.Language.GetPhrase("timer_select"))

	local ProfilerResults = vgui.Create("DListView", LeftContent)
	ProfilerResults:SetSize(LeftContent:GetWide() - TabPadding * 2, LeftContent:GetTall() - TabPadding * 2)
	ProfilerResults:SetPos(TabPadding, TabPadding)
	ProfilerResults:SetMultiSelect(false)
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("timer"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("file"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("delay"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("times_run"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("total_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("longest_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("average_time"))

	local ProfileData = table.Merge(GProfiler.Timers.Simple, GProfiler.Timers.Create)
	for k, v in pairs(ProfileData or {}) do
		local line = ProfilerResults:AddLine(v.Type == "Simple" and "Simple Timer" or tostring(k), v.Source or "Unknown", math.Round(v.Delay, 4), v.Count, v.TotalTime, v.LongestTime, v.AverageTime)
		line.OnMousePressed = function(s, l)
			if l == 108 then
				local menu = DermaMenu()
				menu:AddOption(GProfiler.CopyLang("receiver"), function() SetClipboardText(k) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("times_received"), function() SetClipboardText(v.Count) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("largest_size"), function() SetClipboardText(v.LongestTime) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("total_size"), function() SetClipboardText(v.TotalTime) end):SetIcon("icon16/page_copy.png")
				menu:Open()
			end

			for k, v in pairs(ProfilerResults.Lines) do
				v:SetSelected(false)
			end
			line:SetSelected(true)

			GProfiler.RequestFunctionSource(v.Source, v.Lines[1], v.Lines[2], function(source)
				if not IsValid(FunctionDetails) then return end
				FunctionDetails:SetText(table.concat(source, "\n"))
			end)
		end
	end

	local Wide = ProfilerResults:GetWide()
	ProfilerResults.Columns[1]:SetWide(Wide * 0.2)
	ProfilerResults.Columns[2]:SetWide(Wide * 0.2)
	ProfilerResults.Columns[3]:SetWide(Wide * 0.075)
	ProfilerResults.Columns[4]:SetWide(Wide * 0.075)
	ProfilerResults.Columns[5]:SetWide(Wide * 0.17)
	ProfilerResults.Columns[6]:SetWide(Wide * 0.17)
	ProfilerResults.Columns[7]:SetWide(Wide * 0.17)
	ProfilerResults:SortByColumn(5, true)

	local function UpdateLists()
		GProfiler.StyleDListView(ProfilerResults)
	end
	UpdateLists()
end
GProfiler.Menu.RegisterTab("Timers", "icon16/time.png", 5, GProfiler.Timers.DoTab, function()
		if GProfiler.Timers.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.Timers.StartTime, 0, GProfiler.Timers.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.Timers.Override then
		return GProfiler.Timers.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_Timers_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	GProfiler.Timers.ProfileActive = status

	if ply == LocalPlayer() and not GProfiler.Timers.ProfileActive then
		GProfiler.Menu.OpenTab("Timers", GProfiler.Timers.DoTab)
	end
end)

net.Receive("GProfiler_Timers_SendData", function(len)
	local firstChunk = net.ReadBool()
	if firstChunk then
		GProfiler.Timers.Simple = {}
		GProfiler.Timers.Create = {}
	end
	local lastChunk = net.ReadBool()
	for i = 1, net.ReadUInt(32) do
		local type = net.ReadString()
		local name = net.ReadString()
		GProfiler.Timers[type][name] = {
			Count = net.ReadUInt(15),
			Delay = net.ReadFloat(),
			TotalTime = net.ReadFloat(),
			LongestTime = net.ReadFloat(),
			AverageTime = net.ReadFloat(),
			Source = net.ReadString(),
			Lines = {net.ReadUInt(14), net.ReadUInt(14)},
			Type = type
		}
	end
	if lastChunk then
		GProfiler.Menu.OpenTab("Timers", GProfiler.Timers.DoTab)
	end
end)