GProfiler.Net = GProfiler.Net or {}
GProfiler.Net.Realm = GProfiler.Net.Realm or "Client"
GProfiler.Net.ProfileActive = GProfiler.Net.ProfileActive or false
GProfiler.Net.StartTime = GProfiler.Net.StartTime or 0
GProfiler.Net.EndTime = GProfiler.Net.EndTime or 0

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

local function FormatBites(bites)
	if bites < 1024 then
		return bites .. "b"
	elseif bites < 1024 * 1024 then
		return math.Round(bites / 1024, 2) .. "kb"
	else
		return math.Round(bites / 1024 / 1024, 2) .. "mb"
	end
end

local function GetReceiverTable(realm, callback)
	if realm == "Server" then
		net.Start("GProfiler_Net_ReceiverTbl")
		net.SendToServer()
		net.Receive("GProfiler_Net_ReceiverTbl", function()
			local receiverCount = net.ReadUInt(32)
			local receiverTbl = {}
			for i = 1, receiverCount do
				receiverTbl[net.ReadString()] = {
					net.ReadString(),
					net.ReadString(),
					net.ReadUInt(16),
					net.ReadUInt(16)
				}
			end
			callback(receiverTbl)
		end)
	else
		local receiverTbl = {}
		for k, v in pairs(net.Receivers) do
			local Source = debug.getinfo(v, "S") or {short_src = "", linedefined = 0, lastlinedefined = 0}
			receiverTbl[k] = {
				string.format("%s (%s)", tostring(v), GProfiler.GetFunctionLocation(v)),
				Source.short_src,
				Source.linedefined,
				Source.lastlinedefined
			}
		end
		callback(receiverTbl)
	end
end

function GProfiler.Net.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local RealmSelector = GProfiler.Menu.CreateRealmSelector(Header, "Net", Header:GetWide() - TabPadding - 110, Header:GetTall() / 2 - 30 / 2, function(s, _, value)
		GProfiler.Net.Realm = value
		GProfiler.Menu.OpenTab("Networking", GProfiler.Net.DoTab)
	end)
	RealmSelector:SetPos(Header:GetWide() - RealmSelector:GetWide() - TabPadding, Header:GetTall() / 2 - RealmSelector:GetTall() / 2)

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.Net.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
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

	local NetTimeRunning = vgui.Create("DLabel", Header)
	NetTimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	NetTimeRunning:SetText(GProfiler.TimeRunning(GProfiler.Net.StartTime, GProfiler.Net.EndTime, GProfiler.Net.ProfileActive) .. "s")
	NetTimeRunning:SizeToContents()
	NetTimeRunning:SetPos(Header:GetWide() - NetTimeRunning:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - NetTimeRunning:GetTall() / 2)
	NetTimeRunning:SetTextColor(MenuColors.White)
	function NetTimeRunning:Think()
		if GProfiler.Net.ProfileActive then
			self:SetText(GProfiler.Net.Override or GProfiler.TimeRunning(GProfiler.Net.StartTime, 0, GProfiler.Net.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	local ReceivingData = vgui.Create("DLabel", Header)
	ReceivingData:SetFont("GProfiler.Menu.SectionHeader")
	ReceivingData:SetText("Receiving data...    ")
	ReceivingData:SizeToContents()
	ReceivingData:SetPos(Header:GetWide() - ReceivingData:GetWide() - RealmSelector:GetWide() - StartButton:GetWide() - NetTimeRunning:GetWide() - TabPadding * 3, Header:GetTall() / 2 - ReceivingData:GetTall() / 2)
	ReceivingData:SetTextColor(Color(225, 66, 66))
	function ReceivingData:Think()
		if GProfiler.Net.ReceivingData then
			self:SetVisible(true)
		else
			self:SetVisible(false)
		end
	end

	StartButton.DoClick = function()
		if GProfiler.Net.ProfileActive then
			GProfiler.Net.EndTime = SysTime()
			GProfiler.Net.Override = GProfiler.TimeRunning(GProfiler.Net.StartTime, SysTime(), GProfiler.Net.ProfileActive) .. "s"
			if GProfiler.Net.Realm == "Server" then
				net.Start("GProfiler_Net_ToggleServerProfile")
				net.WriteBool(false)
				net.SendToServer()
				GProfiler.Net.ReceivingData = true
			else
				GProfiler.Net.Overridxe = GProfiler.TimeRunning(GProfiler.Net.StartTime, SysTime(), GProfiler.Net.ProfileActive) .. "s"
				GProfiler.Net:RestoreNet()
				GProfiler.Net.ProfileActive = false
				GProfiler.Menu.OpenTab("Networking", GProfiler.Net.DoTab)
			end
		else
			GProfiler.Net.StartTime = SysTime()
			GProfiler.Net.EndTime = 0
			GProfiler.Net.Override = nil
			if GProfiler.Net.Realm == "Server" then
				net.Start("GProfiler_Net_ToggleServerProfile")
				net.WriteBool(true)
				net.SendToServer()
			else
				GProfiler.Net:StartProfiler()
				GProfiler.Net.ProfileActive = true
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

	local LeftHeader = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("profiler_results"), 0, 0, SectionHeader:GetWide() * leftFraction - 5, SectionHeader:GetTall())
	local RightHeader = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("Receiver Function"), LeftHeader:GetWide() + 10, 0, SectionHeader:GetWide() * rightFraction - 5, LeftHeader:GetTall())

	local LeftContent = vgui.Create("DPanel", Content)
	LeftContent:SetSize(LeftHeader:GetWide(), Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	LeftContent:SetPos(0, SectionHeader:GetTall() + Header:GetTall())
	LeftContent.Paint = nil

	local RightContent = vgui.Create("DPanel", Content)
	RightContent:SetSize(RightHeader:GetWide(), Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	RightContent:SetPos(LeftContent:GetWide() + 10, SectionHeader:GetTall() + Header:GetTall())
	RightContent.Paint = nil

	local ProfilerResults = vgui.Create("DListView", LeftContent)
	ProfilerResults:SetSize(LeftContent:GetWide() - TabPadding * 2, (LeftContent:GetTall() - TabPadding * 2) / 2 - 10)
	ProfilerResults:SetPos(TabPadding, TabPadding)
	ProfilerResults:SetMultiSelect(false)
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("receiver"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("times_received"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("largest_size"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("total_size"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("total_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("average_time"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("longest_time"))

	local ReceiversList = vgui.Create("DListView", LeftContent)
	ReceiversList:SetSize(ProfilerResults:GetWide(), ProfilerResults:GetTall())
	ReceiversList:SetPos(TabPadding, ProfilerResults:GetTall() + TabPadding * 2)
	ReceiversList:SetMultiSelect(false)
	ReceiversList:AddColumn(GProfiler.Language.GetPhrase("name")):SetFixedWidth(ReceiversList:GetWide() / 3)
	ReceiversList:AddColumn(GProfiler.Language.GetPhrase("function"))

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
	FunctionDetails:SetText(GProfiler.Language.GetPhrase("receiver_select"))

	local LastSelected = ""
	table.sort(GProfiler.Net.ProfileData or {}, function(a, b) return a.t > b.t end)
	for k, v in pairs(GProfiler.Net.ProfileData or {}) do
		local Line = ProfilerResults:AddLine(k, v[1], string.format("%s (%s)", v[2], FormatBites(v[2])), string.format("%s (%s)", v[3], FormatBites(v[3])), v[7], v[8], v[9])
		Line.OnRightClick = function()
			local menu = DermaMenu()
			menu:AddOption(GProfiler.CopyLang("receiver"), function() SetClipboardText(k) end):SetIcon("icon16/page_copy.png")
			menu:AddOption(GProfiler.CopyLang("times_received"), function() SetClipboardText(v[1]) end):SetIcon("icon16/page_copy.png")
			menu:AddOption(GProfiler.CopyLang("largest_size"), function() SetClipboardText(v[2]) end):SetIcon("icon16/page_copy.png")
			menu:AddOption(GProfiler.CopyLang("total_size"), function() SetClipboardText(v[3]) end):SetIcon("icon16/page_copy.png")
			menu:Open()
		end

		Line.OnSelect = function()
			if not v[4] or LastSelected == v then return end
			LastSelected = v

			FunctionDetails:SetText(GProfiler.Language.GetPhrase("requesting_source"))
			GProfiler.RequestFunctionSource(v[4], tonumber(v[5]), tonumber(v[6]), function(source)
				if not IsValid(FunctionDetails) then return end
				FunctionDetails:SetText(table.concat(source, "\n"))
			end)
		end
	end

	ProfilerResults:SortByColumn(2, true)

	local function UpdateLists()
		GProfiler.StyleDListView(ProfilerResults)
		GProfiler.StyleDListView(ReceiversList)
	end
	UpdateLists()

	GetReceiverTable(GProfiler.Net.Realm, function(receiverTbl)
		if not IsValid(ReceiversList) then return end
		for k, v in pairs(receiverTbl) do
			local Line = ReceiversList:AddLine(k, v[1])
			Line.OnRightClick = function()
				local menu = DermaMenu()
				menu:AddOption(GProfiler.CopyLang("name"), function() SetClipboardText(k) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("function"), function() SetClipboardText(v) end):SetIcon("icon16/page_copy.png")
				menu:Open()
			end

			Line.OnSelect = function()
				if not IsValid(FunctionDetails) then return end
				FunctionDetails:SetText(GProfiler.Language.GetPhrase("requesting_source"))
				GProfiler.RequestFunctionSource(v[2], tonumber(v[3]), tonumber(v[4]), function(source)
					if not IsValid(FunctionDetails) then return end
					FunctionDetails:SetText(table.concat(source, "\n"))
				end)
			end
		end
		UpdateLists()
	end)
end
GProfiler.Menu.RegisterTab("Networking", "icon16/connect.png", 2, GProfiler.Net.DoTab, function()
	if GProfiler.Net.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.Net.StartTime, 0, GProfiler.Net.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.Net.Override then
		return GProfiler.Net.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_Net_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	GProfiler.Net.ProfileActive = status

	if ply == LocalPlayer() and not status then
		GProfiler.Menu.OpenTab("Networking", GProfiler.Net.DoTab)
	end
end)

net.Receive("GProfiler_Net_SendData", function()
	GProfiler.Net.ProfileData = {}
	for i = 1, net.ReadUInt(32) do
		GProfiler.Net.ProfileData[net.ReadString()] = {
			net.ReadUInt(32),
			net.ReadUInt(32),
			net.ReadUInt(32),
			net.ReadString(),
			net.ReadUInt(16),
			net.ReadUInt(16),
			net.ReadFloat(),
			net.ReadFloat(),
			net.ReadFloat()
		}
	end
	GProfiler.Net.ReceivingData = false
	GProfiler.Menu.OpenTab("Networking", GProfiler.Net.DoTab)
end)

hook.Add("ExpressLoaded", "GProfiler.Net", function()
	express.Receive("GProfiler_Net_SendData", function(data)
		GProfiler.Net.ProfileData = {}
		for k, v in pairs(data) do
			GProfiler.Net.ProfileData[k] = {
				v.Count, v.MaxSize, v.TotalSize,
				v.Source, v.LineStart, v.LineEnd,
				v.TotalTime, v.LongestTime, v.AverageTime
			}
		end

		GProfiler.Menu.OpenTab("Networking", GProfiler.Net.DoTab)
		GProfiler.Net.ReceivingData = false
	end)
end)