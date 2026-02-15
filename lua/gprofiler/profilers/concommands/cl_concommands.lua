GProfiler.ConCommands = GProfiler.ConCommands or {}
GProfiler.ConCommands.ProfileActive = GProfiler.ConCommands.ProfileActive or false
GProfiler.ConCommands.StartTime = GProfiler.ConCommands.StartTime or 0
GProfiler.ConCommands.EndTime = GProfiler.ConCommands.EndTime or 0
GProfiler.ConCommands.ProfileActive = GProfiler.ConCommands.ProfileActive or false
GProfiler.ConCommands.Realm = GProfiler.ConCommands.Realm or "Client"

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

local function GetCommandList(realm, callback)
	if realm == "Client" then
		local commands = concommand.GetTable()
		local commandList = {}

		for k, v in pairs(commands) do
			local source, lineStart, lineEnd = GProfiler.ConCommands.GetFunction(k, commands)
			commandList[k] = {Source = source, Lines = {lineStart, lineEnd}}
		end

		callback(commandList)
	elseif realm == "Server" then
		net.Start("GProfiler_ConCommands_CommandList")
		net.SendToServer()

		net.Receive("GProfiler_ConCommands_CommandList", function()
			local commandList = {}
			for i = 1, net.ReadUInt(32) do
				local command = net.ReadString()
				local source = net.ReadString()
				local lineStart = net.ReadUInt(16)
				local lineEnd = net.ReadUInt(16)
				commandList[command] = {Source = source, Lines = {lineStart, lineEnd}}
			end

			callback(commandList)
		end)
	end
end

function GProfiler.ConCommands.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local RealmSelector = GProfiler.Menu.CreateRealmSelector(Header, "ConCommands", Header:GetWide() - 110 - TabPadding, Header:GetTall() / 2 - 30 / 2, function(s, _, value)
		GProfiler.ConCommands.Realm = value
		GProfiler.Menu.OpenTab("Commands", GProfiler.ConCommands.DoTab)
	end)
	RealmSelector:SetPos(Header:GetWide() - RealmSelector:GetWide() - TabPadding, Header:GetTall() / 2 - RealmSelector:GetTall() / 2)

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.ConCommands.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
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

	StartButton.DoClick = function()
		if GProfiler.ConCommands.ProfileActive then
			GProfiler.ConCommands.EndTime = SysTime()
			GProfiler.ConCommands.Override = GProfiler.TimeRunning(GProfiler.ConCommands.StartTime, SysTime(), GProfiler.ConCommands.ProfileActive) .. "s"
			if GProfiler.ConCommands.Realm == "Server" then
				net.Start("GProfiler_ConCommands_ToggleServerProfile")
				net.WriteBool(false)
				net.SendToServer()
			else
				GProfiler.ConCommands:RestoreCommands()
				GProfiler.ConCommands.ProfileActive = false
				GProfiler.Menu.OpenTab("Commands", GProfiler.ConCommands.DoTab)
			end
		else
			GProfiler.ConCommands.StartTime = SysTime()
			GProfiler.ConCommands.EndTime = 0
			GProfiler.ConCommands.Override = nil
			if GProfiler.ConCommands.Realm == "Server" then
				net.Start("GProfiler_ConCommands_ToggleServerProfile")
				net.WriteBool(true)
				net.SendToServer()
			else
				GProfiler.ConCommands:StartProfiler()
				GProfiler.ConCommands.ProfileActive = true
				StartButton:SetText(GProfiler.Language.GetPhrase("profiler_stop"))
			end
		end
	end

	local TimeRunning = vgui.Create("DLabel", Header)
	TimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	TimeRunning:SetText(GProfiler.TimeRunning(GProfiler.ConCommands.StartTime, GProfiler.ConCommands.EndTime, GProfiler.ConCommands.ProfileActive) .. "s")
	TimeRunning:SizeToContents()
	TimeRunning:SetPos(Header:GetWide() - TimeRunning:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - TimeRunning:GetTall() / 2)
	TimeRunning:SetTextColor(MenuColors.White)
	function TimeRunning:Think()
		if GProfiler.ConCommands.ProfileActive then
			self:SetText(GProfiler.TimeRunning(GProfiler.ConCommands.StartTime, 0, GProfiler.ConCommands.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - StartButton:GetWide() - RealmSelector:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	local SectionHeader = vgui.Create("DPanel", Content)
	SectionHeader:SetSize(Content:GetWide(), 40)
	SectionHeader:SetPos(0, Header:GetTall())
	SectionHeader.Paint = nil

	local leftFraction = .7
	local rightFraction = .3

	local LeftHeader, LeftHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("profiler_results"), 0, 0, SectionHeader:GetWide() * leftFraction - 5, SectionHeader:GetTall())
	local RightHeader, RightHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("command_function"), LeftHeader:GetWide() + 10, 0, SectionHeader:GetWide() * rightFraction - 5, LeftHeader:GetTall())

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
	FunctionDetails:SetText(GProfiler.Language.GetPhrase("command_select"))

	local ProfilerResults = vgui.Create("DListView", LeftContent)
	ProfilerResults:SetSize(LeftContent:GetWide() - TabPadding * 2, (LeftContent:GetTall() - TabPadding * 2) / 2)
	ProfilerResults:SetPos(TabPadding, TabPadding)
	ProfilerResults:SetMultiSelect(false)
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("command"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("file"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("times_run"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("total_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("average_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("longest_time"))

	local Wide = ProfilerResults:GetWide()
	ProfilerResults.Columns[1]:SetWidth(Wide * .20)
	ProfilerResults.Columns[2]:SetWidth(Wide * .24)
	ProfilerResults.Columns[3]:SetWidth(Wide * .14)
	ProfilerResults.Columns[4]:SetWidth(Wide * .16)
	ProfilerResults.Columns[5]:SetWidth(Wide * .16)
	ProfilerResults.Columns[6]:SetWidth(Wide * .16)

	for k, v in pairs(GProfiler.ConCommands.ProfileData or {}) do
		local Line = ProfilerResults:AddLine(k, v.Source, v.Count, v.Time, v.AverageTime, v.LongestTime)
		Line.OnMousePressed = function(s, l)
			if l == 108 then
				local menu = DermaMenu()
				menu:AddOption(GProfiler.CopyLang("command"), function() SetClipboardText(k) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("file"), function() SetClipboardText(v.Function) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("times_run"), function() SetClipboardText(v.Count) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("total_time"), function() SetClipboardText(v.Time) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("average_time"), function() SetClipboardText(v.AverageTime) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("longest_time"), function() SetClipboardText(v.LongestTime) end):SetIcon("icon16/page_copy.png")
				menu:Open()
			end

			for k, v in pairs(ProfilerResults.Lines) do v:SetSelected(false) end
			Line:SetSelected(true)

			FunctionDetails:SetText(GProfiler.Language.GetPhrase("requesting_source"))
			GProfiler.RequestFunctionSource(v.Source, tonumber(v.Lines[1]), tonumber(v.Lines[2]), function(source)
				if not IsValid(FunctionDetails) then return end
				FunctionDetails:SetText(table.concat(source, "\n"))
			end)
		end
	end

	local CommandList = vgui.Create("DListView", LeftContent)
	CommandList:SetSize(LeftContent:GetWide() - TabPadding * 2, (LeftContent:GetTall() - TabPadding * 2) / 2 - 10)
	CommandList:SetPos(TabPadding, TabPadding + ProfilerResults:GetTall() + TabPadding)
	CommandList:SetMultiSelect(false)
	CommandList:AddColumn(GProfiler.Language.GetPhrase("command"))
	CommandList:AddColumn(GProfiler.Language.GetPhrase("file"))

	GetCommandList(GProfiler.ConCommands.Realm, function(list)
		if not IsValid(CommandList) then return end
		CommandList:Clear()

		for k, v in pairs(list) do
			local Line = CommandList:AddLine(k, v.Source)
			Line.OnMousePressed = function(s, l)
				if l == 108 then
					local menu = DermaMenu()
					menu:AddOption(GProfiler.CopyLang("command"), function() SetClipboardText(k) end):SetIcon("icon16/page_copy.png")
					menu:AddOption(GProfiler.CopyLang("file"), function() SetClipboardText(v.Source) end):SetIcon("icon16/page_copy.png")
					menu:Open()
				end

				for k, v in pairs(CommandList.Lines) do v:SetSelected(false) end
				Line:SetSelected(true)

				FunctionDetails:SetText(GProfiler.Language.GetPhrase("requesting_source"))
				GProfiler.RequestFunctionSource(v.Source, tonumber(v.Lines[1]), tonumber(v.Lines[2]), function(source)
					if not IsValid(FunctionDetails) then return end
					FunctionDetails:SetText(table.concat(source, "\n"))
				end)
			end
		end

		GProfiler.StyleDListView(CommandList)
	end)

	GProfiler.StyleDListView(ProfilerResults)
	GProfiler.StyleDListView(CommandList)
end

GProfiler.Menu.RegisterTab("Commands", "icon16/application_xp_terminal.png", 4, GProfiler.ConCommands.DoTab, function()
	if GProfiler.ConCommands.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.ConCommands.StartTime, 0, GProfiler.ConCommands.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.ConCommands.Override then
		return GProfiler.ConCommands.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_ConCommands_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	GProfiler.ConCommands.ProfileActive = status

	if ply == LocalPlayer() then
		GProfiler.Menu.OpenTab("Commands", GProfiler.ConCommands.DoTab)
	end
end)

net.Receive("GProfiler_ConCommands_SendData", function()
	local data = {}
	for i = 1, net.ReadUInt(32) do
		local cmd = net.ReadString()
		data[cmd] = {
			Count = net.ReadUInt(32),
			Time = net.ReadFloat(),
			AverageTime = net.ReadFloat(),
			LongestTime = net.ReadFloat(),
			Source = net.ReadString(),
			Lines = {net.ReadUInt(16), net.ReadUInt(16)}
		}
	end

	GProfiler.ConCommands.ProfileData = data
	GProfiler.Menu.OpenTab("Commands", GProfiler.ConCommands.DoTab)
end)