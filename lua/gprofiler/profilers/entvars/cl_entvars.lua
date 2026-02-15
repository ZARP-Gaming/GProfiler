GProfiler.EntVars = GProfiler.EntVars or {}
GProfiler.EntVars.ProfileActive = GProfiler.EntVars.ProfileActive or false
GProfiler.EntVars.StartTime = GProfiler.EntVars.StartTime or 0
GProfiler.EntVars.EndTime = GProfiler.EntVars.EndTime or 0

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

function GProfiler.EntVars.DoTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.EntVars.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
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
		if GProfiler.EntVars.ProfileActive then
			GProfiler.EntVars.ProfileActive = false
			GProfiler.EntVars.EndTime = SysTime()
			GProfiler.EntVars.Override = GProfiler.TimeRunning(GProfiler.EntVars.StartTime, SysTime(), GProfiler.EntVars.ProfileActive) .. "s"
			GProfiler.Menu.OpenTab("Entity Variables", GProfiler.EntVars.DoTab)
			self:SetText(GProfiler.Language.GetPhrase("profiler_start"))
		else
			GProfiler.EntVars.ProfileData = {}
			GProfiler.EntVars.Override = nil
			GProfiler.EntVars.ProfileActive = true
			GProfiler.EntVars.StartTime = SysTime()
			self:SetText(GProfiler.Language.GetPhrase("profiler_stop"))
		end
	end

	local TimeRunning = vgui.Create("DLabel", Header)
	TimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	TimeRunning:SetText(GProfiler.TimeRunning(GProfiler.EntVars.StartTime, GProfiler.EntVars.EndTime, GProfiler.EntVars.ProfileActive) .. "s")
	TimeRunning:SizeToContents()
	TimeRunning:SetPos(Header:GetWide() - TimeRunning:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - TimeRunning:GetTall() / 2)
	TimeRunning:SetTextColor(MenuColors.White)
	function TimeRunning:Think()
		if GProfiler.EntVars.ProfileActive then
			self:SetText(GProfiler.TimeRunning(GProfiler.EntVars.StartTime, 0, GProfiler.EntVars.ProfileActive) .. "s")
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
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("times_updated"))
	ProfilerResults:AddColumn(GProfiler.Language.GetPhrase("current_value"))

	for k, v in pairs(GProfiler.EntVars.ProfileData or {}) do
		if not v.GProfiler_SavedEnt then continue end
		for var, val in pairs(v) do
			if var == "GProfiler_SavedEnt" or var == "GProfiler_CurrentValues" then continue end
			local Line = ProfilerResults:AddLine(v.GProfiler_SavedEnt, var, val, v.GProfiler_CurrentValues[var] or "Unknown")
			Line.OnRightClick = function()
				local menu = DermaMenu()
				menu:AddOption(GProfiler.CopyLang("entity"), function() SetClipboardText(v.GProfiler_SavedEnt) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("variable"), function() SetClipboardText(var) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("times_updated"), function() SetClipboardText(val) end):SetIcon("icon16/page_copy.png")
				menu:AddOption(GProfiler.CopyLang("current_value"), function() SetClipboardText(v.GProfiler_CurrentValues[var] or "Unknown") end):SetIcon("icon16/page_copy.png")
				menu:Open()
			end
		end
	end

	ProfilerResults:SortByColumn(3, true)

	GProfiler.StyleDListView(ProfilerResults)
end

GProfiler.Menu.RegisterTab("Entity Variables", "icon16/database_edit.png", 6, GProfiler.EntVars.DoTab, function()
	if GProfiler.EntVars.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.EntVars.StartTime, 0, GProfiler.EntVars.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.EntVars.Override then
		return GProfiler.EntVars.Override, MenuColors.InactiveProfile
	end
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
