GProfiler.NetVars = GProfiler.NetVars or {}
GProfiler.NetVars.ProfileActive = GProfiler.NetVars.ProfileActive or false
GProfiler.NetVars.ProfileData = GProfiler.NetVars.ProfileData or {}
GProfiler.NetVars.StartTime = GProfiler.NetVars.StartTime or 0
GProfiler.NetVars.EndTime = GProfiler.NetVars.EndTime or 0

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

function GProfiler.NetVars.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.NetVars.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
	StartButton:SetTextColor(MenuColors.White)
	StartButton:SetFont("GProfiler.Menu.StartButton")
	StartButton:SizeToContents()
	StartButton:SetTall(30)
	StartButton:SetPos(Header:GetWide() - StartButton:GetWide() - TabPadding * 2, Header:GetTall() / 2 - StartButton:GetTall() / 2)
	StartButton.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
		draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

		if s:IsHovered() then
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
		end
	end

	function StartButton:DoClick()
		if GProfiler.NetVars.ProfileActive then
			GProfiler.NetVars.ProfileActive = false
			GProfiler.NetVars.EndTime = SysTime()
			GProfiler.NetVars.Override = GProfiler.TimeRunning(GProfiler.NetVars.StartTime, SysTime(), GProfiler.NetVars.ProfileActive) .. "s"
			net.Start("GProfiler_NetVars_ToggleServerProfile")
			net.WriteBool(false)
			net.SendToServer()
			self:SetText(GProfiler.Language.GetPhrase("profiler_start"))
		else
			GProfiler.NetVars.ProfileActive = true
			GProfiler.NetVars.Override = nil
			GProfiler.NetVars.StartTime = SysTime()
			net.Start("GProfiler_NetVars_ToggleServerProfile")
			net.WriteBool(true)
			net.SendToServer()
			self:SetText(GProfiler.Language.GetPhrase("profiler_stop"))
		end
	end

	local TimeRunning = vgui.Create("DLabel", Header)
	TimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	TimeRunning:SetText(GProfiler.TimeRunning(GProfiler.NetVars.StartTime, GProfiler.NetVars.EndTime, GProfiler.NetVars.ProfileActive) .. "s")
	TimeRunning:SizeToContents()
	TimeRunning:SetPos(Header:GetWide() - TimeRunning:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - TimeRunning:GetTall() / 2)
	TimeRunning:SetTextColor(MenuColors.White)
	function TimeRunning:Think()
		if GProfiler.NetVars.ProfileActive then
			self:SetText(GProfiler.TimeRunning(GProfiler.NetVars.StartTime, 0, GProfiler.NetVars.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	local SectionHeader = vgui.Create("DPanel", Content)
	SectionHeader:SetSize(Content:GetWide(), 40)
	SectionHeader:SetPos(0, Header:GetTall())
	SectionHeader.Paint = nil

	local Header, HeaderText = GProfiler.Menu.CreateHeader(SectionHeader, GProfiler.Language.GetPhrase("profiler_results"), 0, 0, SectionHeader:GetWide() - 5, SectionHeader:GetTall())

	local ProfilerContent = vgui.Create("DPanel", Content)
	ProfilerContent:SetSize(Content:GetWide() - 5, Content:GetTall() - SectionHeader:GetTall() - Header:GetTall())
	ProfilerContent:SetPos(0, SectionHeader:GetTall() + Header:GetTall())
	ProfilerContent.Paint = nil

	local ProfilerResults = vgui.Create("DListView", ProfilerContent)
	ProfilerResults:SetSize(ProfilerContent:GetWide() - TabPadding * 2, ProfilerContent:GetTall() - TabPadding * 2)
	ProfilerResults:SetPos(TabPadding, TabPadding)
	ProfilerResults:SetMultiSelect(false)
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("entity"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("variable"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("type"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("times_updated"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("current_value"))

	for ent, vars in pairs(GProfiler.NetVars.ProfileData) do
		for var, types in pairs(vars) do
			for type, data in pairs(types) do
				local Line = ProfilerResults:AddLine(ent, var, type, data.TimesUpdated, data.CurValue)
				Line.OnMousePressed = function(s, l)
					local menu = DermaMenu()
					menu:AddOption(GProfiler.CopyLang("entity"), function() SetClipboardText(ent) end):SetIcon("icon16/page_copy.png")
					menu:AddOption(GProfiler.CopyLang("variable"), function() SetClipboardText(var) end):SetIcon("icon16/page_copy.png")
					menu:AddOption(GProfiler.CopyLang("type"), function() SetClipboardText(type) end):SetIcon("icon16/page_copy.png")
					menu:AddOption(GProfiler.CopyLang("times_updated"), function() SetClipboardText(data.TimesUpdated) end):SetIcon("icon16/page_copy.png")
					menu:AddOption(GProfiler.CopyLang("current_value"), function() SetClipboardText(data.CurValue) end):SetIcon("icon16/page_copy.png")
					menu:Open()
				end
			end
		end
	end

	ProfilerResults:SortByColumn(3, true)

	GProfiler.StyleDListView(ProfilerResults)
end

GProfiler.Menu.RegisterTab("Network Variables", "icon16/table_edit.png", 7, GProfiler.NetVars.DoTab, function()
	if GProfiler.NetVars.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.NetVars.StartTime, 0, GProfiler.NetVars.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.NetVars.Override then
		return GProfiler.NetVars.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_NetVars_SendData", function(len)
	local data = {}
	local numEnts = net.ReadUInt(32)
	for i = 1, numEnts do
		local ent = net.ReadString()
		data[ent] = {}
		local numVars = net.ReadUInt(32)
		for i = 1, numVars do
			local name = net.ReadString()
			data[ent][name] = {}
			local numTypes = net.ReadUInt(32)
			for i = 1, numTypes do
				local type = net.ReadString()
				data[ent][name][type] = {
					TimesUpdated = net.ReadUInt(32),
					CurValue = net.ReadString()
				}
			end
		end
	end
	GProfiler.NetVars.ProfileData = data
end)

net.Receive("GProfiler_NetVars_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	GProfiler.NetVars.ProfileActive = status

	if ply == LocalPlayer() then
		GProfiler.Menu.OpenTab("Network Variables", GProfiler.NetVars.DoTab)
	end
end)