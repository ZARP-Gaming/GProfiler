GProfiler.Functions = GProfiler.Functions or {}
local FunctionsProfiler = GProfiler.Functions
FunctionsProfiler.Realm = FunctionsProfiler.Realm or "Client"
FunctionsProfiler.ProfileActive = FunctionsProfiler.ProfileActive or false
FunctionsProfiler.StartTime = FunctionsProfiler.StartTime or 0
FunctionsProfiler.EndTime = FunctionsProfiler.EndTime or 0
FunctionsProfiler.ActiveFocus = FunctionsProfiler.ActiveFocus or {}
FunctionsProfiler.SourceFilter = FunctionsProfiler.SourceFilter or ""

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

local function ValidateFocus(foc)
	return string.StartWith(foc or "", "function: 0x") or string.StartWith(foc or "", "0x")
end

local FocusColors = {
	Valid = Color(0, 255, 0),
	Invalid = Color(255, 0, 0)
}

local function bytesToReadable(bytes)
	if bytes < 1024 then
		return string.format("%d B", bytes)
	elseif bytes < 1048576 then
		return string.format("%.2f KB", bytes / 1024)
	else
		return string.format("%.2f MB", bytes / 1048576)
	end
end

function FunctionsProfiler.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local RealmSelector = GProfiler.Menu.CreateRealmSelector(Header, "Functions", Header:GetWide() - 110 - TabPadding, Header:GetTall() / 2 - 30 / 2, function(s, _, value)
		FunctionsProfiler.Realm = value
		GProfiler.Menu.OpenTab("Functions", FunctionsProfiler.DoTab)
	end)
	RealmSelector:SetPos(Header:GetWide() - RealmSelector:GetWide() - TabPadding, Header:GetTall() / 2 - RealmSelector:GetTall() / 2)

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(FunctionsProfiler.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
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

	local FunctionTimeRunning = vgui.Create("DLabel", Header)
	FunctionTimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	FunctionTimeRunning:SetText(GProfiler.TimeRunning(FunctionsProfiler.StartTime, FunctionsProfiler.EndTime, FunctionsProfiler.ProfileActive) .. "s")
	FunctionTimeRunning:SizeToContents()
	FunctionTimeRunning:SetPos(Header:GetWide() - FunctionTimeRunning:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - FunctionTimeRunning:GetTall() / 2)
	FunctionTimeRunning:SetTextColor(MenuColors.White)
	function FunctionTimeRunning:Think()
		if FunctionsProfiler.ProfileActive then
			self:SetText(FunctionsProfiler.Override or GProfiler.TimeRunning(FunctionsProfiler.StartTime, 0, FunctionsProfiler.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	local ReceivingData = vgui.Create("DLabel", Header)
	ReceivingData:SetFont("GProfiler.Menu.SectionHeader")
	ReceivingData:SetText("Receiving data...    ")
	ReceivingData:SizeToContents()
	ReceivingData:SetPos(Header:GetWide() - ReceivingData:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - FunctionTimeRunning:GetWide() - TabPadding * 3, Header:GetTall() / 2 - ReceivingData:GetTall() / 2)
	ReceivingData:SetTextColor(Color(225, 66, 66))
	function ReceivingData:Think()
		if FunctionsProfiler.ReceivingData then
			self:SetVisible(true)
		else
			self:SetVisible(false)
		end
	end

	StartButton.DoClick = function()
		if FunctionsProfiler.ProfileActive then
			FunctionsProfiler.EndTime = SysTime()
			FunctionsProfiler.Override = GProfiler.TimeRunning(FunctionsProfiler.StartTime, SysTime(), FunctionsProfiler.ProfileActive) .. "s"
			if FunctionsProfiler.Realm == "Server" then
				net.Start("GProfiler_Functions_ToggleServerProfile")
				net.WriteBool(false)
				net.SendToServer()
				FunctionsProfiler.ReceivingData = true
			else
				GProfiler.Functions:RestoreFunctions()
				FunctionsProfiler.ProfileActive = false
				GProfiler.Menu.OpenTab("Functions", FunctionsProfiler.DoTab)
			end
		else
			FunctionsProfiler.Override = nil
			FunctionsProfiler.StartTime = SysTime()
			FunctionsProfiler.EndTime = 0
			if FunctionsProfiler.Realm == "Server" then
				net.Start("GProfiler_Functions_ToggleServerProfile")
				net.WriteBool(true)
				if not table.IsEmpty(FunctionsProfiler.ActiveFocus) then
					net.WriteBool(true)
					net.WriteUInt(#FunctionsProfiler.ActiveFocus, 5)
					for k, v in ipairs(FunctionsProfiler.ActiveFocus) do
						net.WriteString(v)
					end
				else
					net.WriteBool(false)
				end
				net.SendToServer()
			else
				FunctionsProfiler.Focus = {}
				for k, v in pairs(FunctionsProfiler.ActiveFocus or {}) do
					FunctionsProfiler.Focus[v] = true
				end

				if table.IsEmpty(FunctionsProfiler.ActiveFocus) then
					FunctionsProfiler.Focus = false
				end

				GProfiler.Functions:StartProfiler()
				FunctionsProfiler.ProfileActive = true
				StartButton:SetText(GProfiler.Language.GetPhrase("profiler_stop"))
			end
		end
	end

	local SectionHeader = vgui.Create("DPanel", Content)
	SectionHeader:SetSize(Content:GetWide(), 40)
	SectionHeader:SetPos(0, Header:GetTall())
	SectionHeader.Paint = nil

	local leftFraction = .75
	local rightFraction = .25

	local LeftHeader, LeftHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("profiler_results"), 0, 0, SectionHeader:GetWide() * leftFraction - 5, SectionHeader:GetTall())
	local RightHeader, RightHeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("function_details"), LeftHeader:GetWide() + 10, 0, SectionHeader:GetWide() * rightFraction - 5, LeftHeader:GetTall())

	local FilterFileLabel, FilterFile = GProfiler.Menu.CreateLabeledInput(LeftHeader, GProfiler.Language.GetPhrase("filter_source") .. ":", 0, 0, 150, Header:GetTall() - TabPadding * 1.5)
	FilterFileLabel:SetX(LeftHeader:GetWide() - FilterFileLabel:GetWide() - FilterFile:GetWide() - 15)
	FilterFile:SetX(LeftHeader:GetWide() - FilterFile:GetWide() - TabPadding)

	local FunctionsFocusLabel, AddFocus = GProfiler.Menu.CreateLabeledInput(Header, GProfiler.Language.GetPhrase("focus") .. ":", TabPadding, Header:GetTall() / 2 - (Header:GetTall() - TabPadding * 1.5) / 2, 150, Header:GetTall() - TabPadding * 1.5, 10)

	local FocusList = vgui.Create("DIconLayout", Header)
	FocusList:SetSpaceX(5)
	FocusList:SetSize(Header:GetWide() - AddFocus:GetWide() - FunctionsFocusLabel:GetWide() - StartButton:GetWide() - RealmSelector:GetWide() - TabPadding * 5, Header:GetTall() - TabPadding)
	FocusList:SetPos(AddFocus:GetWide() + FunctionsFocusLabel:GetWide() + FunctionsFocusLabel:GetPos() + 10, Header:GetTall() / 2 - FocusList:GetTall() / 2)
	FocusList.Paint = nil

	local function AddFocusToList(value)
		local Pnl = FocusList:Add("DPanel")
		Pnl:SetSize(20, FocusList:GetTall())
		Pnl.Paint = function(s, w, h)
			draw.RoundedBox(4, 2, 2, w - 4, h - 4, MenuColors.RealmSelectorBackground)
		end

		local lbl = vgui.Create("DLabel", Pnl)
		lbl:SetFont("GProfiler.Menu.RealmSelector")
		lbl:SetText(string.Split(value, "function: ")[2])
		lbl:SizeToContents()
		lbl:SetPos(5, FocusList:GetTall() / 2 - lbl:GetTall() / 2)
		lbl:SetTextColor(MenuColors.White)

		local remove = vgui.Create("DButton", Pnl)
		remove:SetSize(20, 20)
		remove:SetPos(lbl:GetWide() + 10, FocusList:GetTall() / 2 - remove:GetTall() / 2)
		remove:SetText("X")
		remove:SetTextColor(MenuColors.White)
		remove:SetFont("GProfiler.Menu.RealmSelector")
		remove.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

			if s:IsHovered() then
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
			end
		end
		remove.DoClick = function()
			table.RemoveByValue(FunctionsProfiler.ActiveFocus, value)
		end

		Pnl:SizeToChildren(true, false)
		Pnl:SetWide(Pnl:GetWide() + 5)
	end

	for k, v in ipairs(FunctionsProfiler.ActiveFocus) do
		AddFocusToList(v)
	end

	AddFocus.OnEnter = function()
		if ValidateFocus(AddFocus:GetText()) and not table.HasValue(FunctionsProfiler.ActiveFocus, AddFocus:GetText()) then
			if !string.StartWith(AddFocus:GetText(), "function: ") then AddFocus:SetText("function: " .. AddFocus:GetText()) end
			table.insert(FunctionsProfiler.ActiveFocus, AddFocus:GetText())
			AddFocus:SetText("")
		end
	end

	local IsValidInput = false
	local OldPaint = AddFocus.Paint
	function AddFocus:Paint(w, h)
		OldPaint(self, w, h)
		draw.RoundedBox(4, 1, 1, 10, h - 2, IsValidInput and FocusColors.Valid or FocusColors.Invalid)
	end

	function AddFocus:OnTextChanged()
		IsValidInput = ValidateFocus(self:GetText())
	end

	local prevAmount = 0
	FocusList.Think = function() -- fixme: wtf was I thinking here?
		if prevAmount != #FunctionsProfiler.ActiveFocus then
			prevAmount = #FunctionsProfiler.ActiveFocus
			FocusList:Clear()
			FocusList:SetSize(Header:GetWide() - AddFocus:GetWide() - FunctionsFocusLabel:GetWide() - StartButton:GetWide() - RealmSelector:GetWide() - TabPadding * 5, Header:GetTall() - TabPadding)
			FocusList:SetPos(AddFocus:GetWide() + FunctionsFocusLabel:GetWide() + FunctionsFocusLabel:GetPos() + 10, Header:GetTall() / 2 - FocusList:GetTall() / 2)
			for k, v in ipairs(FunctionsProfiler.ActiveFocus) do
				AddFocusToList(v)
			end
		end
	end

	local LeftContent = vgui.Create("DPanel", Content)
	LeftContent:SetSize(Content:GetWide() * leftFraction - 5, Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	LeftContent:SetPos(0, SectionHeader:GetTall() + Header:GetTall())
	LeftContent.Paint = nil

	local RightContent = vgui.Create("DPanel", Content)
	RightContent:SetSize(Content:GetWide() * rightFraction - 5, Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	RightContent:SetPos(LeftContent:GetWide() + 10, SectionHeader:GetTall() + Header:GetTall())
	RightContent.Paint = nil

	local FunctionDetailsBackground = vgui.Create("DPanel", RightContent)
	FunctionDetailsBackground:SetSize(RightContent:GetWide() - TabPadding * 2, RightContent:GetTall() - TabPadding * 2 - 50)
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
	FunctionDetails:SetText(GProfiler.Language.GetPhrase("function_select"))

	local FunctionDetailsSeparator = vgui.Create("DPanel", RightContent)
	FunctionDetailsSeparator:SetSize(RightContent:GetWide() - TabPadding * 2, 1)
	FunctionDetailsSeparator:SetPos(TabPadding, FunctionDetailsBackground:GetTall() + TabPadding * 2)
	FunctionDetailsSeparator.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, MenuColors.HeaderSeparator) end

	local BottomSection = vgui.Create("DPanel", RightContent)
	BottomSection:SetSize(RightContent:GetWide() - TabPadding * 2, RightContent:GetTall() - FunctionDetailsBackground:GetTall() - FunctionDetailsSeparator:GetTall() - TabPadding * 3)
	BottomSection:SetPos(TabPadding, FunctionDetailsBackground:GetTall() + FunctionDetailsSeparator:GetTall() + TabPadding * 3)
	BottomSection.Paint = nil

	local SelectedProfile = nil
	local Buttons = {
		[GProfiler.Language.GetPhrase("focus")] = function()
			if not SelectedProfile then return end
			if table.HasValue(FunctionsProfiler.ActiveFocus, SelectedProfile.focus) then
				table.RemoveByValue(FunctionsProfiler.ActiveFocus, SelectedProfile.focus)
			else
				table.insert(FunctionsProfiler.ActiveFocus, SelectedProfile.focus)
			end
		end,
		[GProfiler.Language.GetPhrase("print_details")] = function(b)
			if not SelectedProfile then return end

			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("function"), ": ", MenuColors.White, SelectedProfile.name, "\n")
			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("source"), ": ", MenuColors.White, SelectedProfile.source, "\n")
			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("lines"), ": ", MenuColors.White, SelectedProfile.lines, "\n")
			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("times_called"), ": ", MenuColors.White, SelectedProfile.calls, "\n")
			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("total_time"), ": ", MenuColors.White, SelectedProfile.time, "\n")
			MsgC(MenuColors.Blue, GProfiler.Language.GetPhrase("average_time"), ": ", MenuColors.White, SelectedProfile.average, "\n")

			b:SetText(GProfiler.Language.GetPhrase("printed"))
			timer.Simple(2, function()
				if not IsValid(b) then return end
				b:SetText(GProfiler.Language.GetPhrase("print_details"))
			end)
		end
	}

	local ButtonWidth = BottomSection:GetWide() / table.Count(Buttons)
	local ButtonHeight = BottomSection:GetTall() - TabPadding

	local i = 0
	for k, v in pairs(Buttons) do
		local Button = vgui.Create("DButton", BottomSection)
		Button:SetSize(ButtonWidth - 5, ButtonHeight)
		Button:SetPos(i * ButtonWidth + (i * 5), 0)
		Button:SetText(k)
		Button:SetTextColor(MenuColors.White)
		Button:SetFont("GProfiler.Menu.RealmSelector")
		Button.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

			if self:IsHovered() then
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
			end
		end
		Button.DoClick = v
		i = i + 1
	end

	local FunctionProfiler = vgui.Create("DListView", LeftContent)
	FunctionProfiler:SetSize(LeftContent:GetWide() - TabPadding * 2, LeftContent:GetTall() - TabPadding * 2)
	FunctionProfiler:SetPos(TabPadding, TabPadding)
	FunctionProfiler:SetMultiSelect(false)
	FunctionProfiler:AddColumn(GProfiler.Language.GetPhrase("function"))
	FunctionProfiler:AddColumn(GProfiler.Language.GetPhrase("source"))
	FunctionProfiler:AddColumn(GProfiler.Language.GetPhrase("times_called"))
	FunctionProfiler:AddColumn(string.format("%s (ms)", GProfiler.Language.GetPhrase("total_time")))
	FunctionProfiler:AddColumn(string.format("%s (ms)", GProfiler.Language.GetPhrase("average_time")))
	-- FunctionProfiler:AddColumn("Garbage"):SetWide(5) -- Not confident on its accuracy yet

	for k, v in pairs(FunctionsProfiler.ProfileData) do
		if FunctionsProfiler.ProfileActive and FunctionsProfiler.Realm == "Client" then break end
		local line = FunctionProfiler:AddLine(v.name or "Unknown", string.format("%s (%s)", v.source, v.lines), v.calls, v.time, v.average, bytesToReadable(v.garbage or 0))
		line:SetSortValue(6, v.garbage or 0)
		line.OnMousePressed = function(s, l)
			if l == 108 then
				local menu = DermaMenu()
				menu:AddOption(GProfiler.Language.GetPhrase("focus"), function()
					if table.HasValue(FunctionsProfiler.ActiveFocus, v.focus) then
						table.RemoveByValue(FunctionsProfiler.ActiveFocus, v.focus)
					else
						table.insert(FunctionsProfiler.ActiveFocus, v.focus)
					end
				end):SetIcon("icon16/zoom.png")
				menu:AddOption(GProfiler.CopyLang("name"), function() SetClipboardText(v.name) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("source"), function() SetClipboardText(v.source) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("times_called"), function() SetClipboardText(v.calls) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("total_time"), function() SetClipboardText(v.time) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("average_time"), function() SetClipboardText(v.average) end):SetIcon("icon16/page_copy.png")
				menu:Open()
				return
			end

			SelectedProfile = v
			for k, v in ipairs(FunctionProfiler.Lines) do
				v:SetSelected(false)
			end
			line:SetSelected(true)

			local lines = string.Split(v.lines, " - ")
			GProfiler.RequestFunctionSource(v.source, lines[1], lines[2], function(source)
				if not IsValid(FunctionDetails) then return end
				FunctionDetails:SetText(table.concat(source, "\n"))
			end)
		end
	end

	FilterFile.OnTextChanged = function()
		local filterText = FilterFile:GetText():lower()
		FunctionsProfiler.SourceFilter = FilterFile:GetText()
		for k, v in ipairs(FunctionProfiler.Lines) do
			local source = v:GetColumnText(2):lower()
			if string.find(source, filterText, 1, true) then
				v:SetVisible(true)
			else
				v:SetVisible(false)
			end
		end
		FunctionProfiler:DataLayout()
		FunctionProfiler:InvalidateLayout()
	end

	FunctionProfiler:SortByColumn(5, true)
	GProfiler.StyleDListView(FunctionProfiler)

	timer.Simple(0, function()
		if FunctionsProfiler.SourceFilter != "" then
			FilterFile:SetText(FunctionsProfiler.SourceFilter)
			FilterFile:OnTextChanged()
		end
	end)
end

GProfiler.Menu.RegisterTab("Functions", "icon16/bug.png", 3, FunctionsProfiler.DoTab, function()
	if FunctionsProfiler.ProfileActive then
		return GProfiler.TimeRunning(FunctionsProfiler.StartTime, 0, FunctionsProfiler.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif FunctionsProfiler.Override then
		return FunctionsProfiler.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_Functions_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	FunctionsProfiler.ProfileActive = status

	if ply == LocalPlayer() then
		GProfiler.Menu.OpenTab("Functions", FunctionsProfiler.DoTab)
	end
end)

net.Receive("GProfiler_Functions_SendData", function(len, ply)
	local first = net.ReadBool()

	if first then
		FunctionsProfiler.ProfileData = {}
	end

	local last = net.ReadBool()
	local count = net.ReadUInt(32)
	for i = 1, count do
		local name = net.ReadString()
		local source = net.ReadString()
		local lines = net.ReadString()
		local calls = net.ReadUInt(22)
		local time = net.ReadFloat()
		local average = net.ReadFloat()
		local focus = net.ReadString()
		local garbage = net.ReadFloat()

		if not FunctionsProfiler.ProfileData[name] then
			FunctionsProfiler.ProfileData[name] = {
				name = name,
				source = source,
				lines = lines,
				calls = 0,
				time = 0,
				average = 0,
				focus = focus,
				garbage = 0
			}
		end

		local Dat = FunctionsProfiler.ProfileData[name]
		Dat.calls = Dat.calls + calls
		Dat.time = Dat.time + time
		Dat.average = Dat.average + average
		Dat.garbage = Dat.garbage + garbage
	end

	if last then
		GProfiler.Menu.OpenTab("Functions", FunctionsProfiler.DoTab)
		FunctionsProfiler.ReceivingData = false
	end
end)

hook.Add("ExpressLoaded", "GProfiler_Functions", function()
	express.Receive("GProfiler_Functions_SendData", function(data)
		FunctionsProfiler.ReceivingData = false
		FunctionsProfiler.ProfileData = data
		GProfiler.Menu.OpenTab("Functions", FunctionsProfiler.DoTab)
	end)
end)
