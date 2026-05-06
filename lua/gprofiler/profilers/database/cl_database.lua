GProfiler.Database = GProfiler.Database or {}
local Database = GProfiler.Database

GProfiler.Profilers.Register("Database", {})

local DatabaseStore = GProfiler.Profilers.GetStore("Database")

local function QueryTimeColor(time)
	if time > 0.5 then return Color(238, 95, 91) end
	if time > 0.1 then return Color(250, 167, 50) end
	return Color(94, 185, 94)
end

local function CreateTimelinePanel(parent, w, h, data, currentQuery)
	local minWidth = 10
	local TimelinePanel = vgui.Create("DPanel", parent)
	TimelinePanel:SetSize(w, h)
	TimelinePanel.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, GProfiler.SyntaxColors.background)
		if s.ShowData then s:ShowData() end
	end

	function TimelinePanel:ShowData()
		TimelinePanel.ShowData = nil

		local totalTime = 0
		for _, entry in ipairs(data) do
			totalTime = totalTime + entry.Time
		end

		local startX = 0
		local gap = 1
		local widths = {}
		local allocatedWidth = 0

		for _, entry in ipairs(data) do
			local entryWidth = w * entry.Time / totalTime
			if entryWidth < minWidth then entryWidth = minWidth end
			table.insert(widths, entryWidth)
			allocatedWidth = allocatedWidth + entryWidth
		end

		local scale = w / allocatedWidth

		for k, entry in ipairs(data) do
			local entryWidth = widths[k] * scale - gap
			if entryWidth < 1 then entryWidth = 1 end
			local entryColor = QueryTimeColor(entry.Time)
			if entry.Query != currentQuery then entryColor.a = 25 end

			local HoverColor = table.Copy(entryColor)
			local entryPanel = vgui.Create("DPanel", TimelinePanel)
			entryPanel:SetSize(k == #data and w - startX or entryWidth, h)
			entryPanel:SetPos(startX, 0)
			entryPanel.Lerp = 0
			entryPanel.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(2, 0, 1, w - 2, h - 2, entryColor)
				if s.Lerp > 0 then
					HoverColor.a = 230 * s.Lerp
					GProfiler.RNDX.Draw(2, 0, 1, w - 2, h - 2, HoverColor)
				end
			end
			entryPanel.Think = function(s)
				s.Lerp = Lerp(FrameTime() * 10, s.Lerp, s:IsHovered() and 1 or 0)
			end
			entryPanel:SetCursor("hand")
			entryPanel.OnMousePressed = function()
				Database.SelectedQuery = entry.QueryId
			end

			startX = startX + entryPanel:GetWide() + gap
		end
	end

	return TimelinePanel
end

function GProfiler.Database.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Database", "gprofiler/database.png")
	local initialActive = DatabaseStore:IsActive("Server")
	local StartStop = Header:SetupStartStop(initialActive)
	local Timer = Header:SetupTimer(function()
		return DatabaseStore:GetTimerData("Server")
	end)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		if QueryList then QueryList:SetSize(Base:GetWide(), Base:GetTall()) end
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("Database", "Server", Running)
	end

	local QueryList = vgui.Create("DPanelList", Base)
	QueryList:SetSize(Base:GetWide(), Base:GetTall())
	QueryList:SetSpacing(GProfiler.GetScaledSize(10))
	QueryList:EnableVerticalScrollbar()

	local ScrollBar = QueryList.VBar
	ScrollBar:SetWide(GProfiler.GetScaledSize(12))
	ScrollBar:SetHideButtons(true)
	ScrollBar.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 10))
	end
	ScrollBar.btnGrip.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 20))
	end

	local rowH = GProfiler.GetScaledSize(30)
	local pad = GProfiler.GetScaledSize(10)

	local function CreateRow(id, queryData, explains)
		local Row = vgui.Create("DPanel", QueryList)
		Row:SetSize(QueryList:GetWide() - pad, rowH)
		Row.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(6, 0, 0, w, h, Color(24, 58, 94, 197))
			-- GProfiler.RNDX.Draw(6, 3, 3, w - 6, h - 6, Color(26, 55, 85, 150))
		end
		Row.Think = function(s)
			if Database.SelectedQuery == s.QueryId then
				Database.SelectedQuery = nil
				QueryList:ScrollToChild(s)
			end
		end
		Row.QueryId = id

		local ScoreCol = QueryTimeColor(queryData.AverageTime)
		local timeStr = string.format("%.2fms", queryData.AverageTime * 1000)

		local IdLabel = vgui.Create("DLabel", Row)
		IdLabel:SetText(string.format("%d.", id))
		IdLabel:SetFont("GProfiler.Inter24")
		IdLabel:SetTextColor(Color(255, 255, 255, 200))
		IdLabel:SizeToContents()
		IdLabel:SetPos(pad, pad + rowH / 2 - IdLabel:GetTall() / 2)

		surface.SetFont("GProfiler.Inter24")
		local bw, bh = surface.GetTextSize(timeStr)
		local TimeBadge = vgui.Create("DPanel", Row)
		TimeBadge:SetSize(bw + pad, bh + GProfiler.GetScaledSize(4))
		TimeBadge:SetPos(IdLabel:GetX() + IdLabel:GetWide() + GProfiler.GetScaledSize(5), pad + rowH / 2 - (bh + GProfiler.GetScaledSize(4)) / 2)
		TimeBadge.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(ScoreCol.r, ScoreCol.g, ScoreCol.b, 40))
			GProfiler.RNDX.Draw(4, 1, 1, w - 2, h - 2, Color(ScoreCol.r, ScoreCol.g, ScoreCol.b, 20))
			draw.SimpleText(timeStr, "GProfiler.Inter24", w / 2, h / 2, ScoreCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local TypeBadge = vgui.Create("DLabel", Row)
		TypeBadge:SetText(queryData.Type or "Unknown")
		TypeBadge:SetFont("GProfiler.Inter24")
		TypeBadge:SetTextColor(Color(210, 210, 210))
		TypeBadge:SizeToContents()
		TypeBadge:SetSize(TypeBadge:GetWide() + pad, TypeBadge:GetTall() + GProfiler.GetScaledSize(4))
		TypeBadge:SetContentAlignment(5)

		local CountBadge = vgui.Create("DLabel", Row)
		CountBadge:SetText(string.format("x%d", queryData.Count))
		CountBadge:SetFont("GProfiler.Inter24")
		CountBadge:SetTextColor(GProfiler.SyntaxColors.text)
		CountBadge:SizeToContents()
		CountBadge:SetSize(CountBadge:GetWide() + pad, CountBadge:GetTall() + GProfiler.GetScaledSize(4))
		CountBadge:SetContentAlignment(5)

		local CopyBtn = vgui.Create("DButton", Row)
		CopyBtn:SetText("Copy Query")
		CopyBtn:SetFont("GProfiler.Inter24")
		CopyBtn:SizeToContentsX()
		CopyBtn:SetTextColor(Color(0, 0, 0, 0))
		CopyBtn:SetSize(CopyBtn:GetWide() + GProfiler.GetScaledSize(10), CountBadge:GetTall())
		CopyBtn.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10))
			if s:IsHovered() then GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10)) end
			draw.SimpleText("Copy Query", "GProfiler.Inter24", w / 2, h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		CopyBtn.DoClick = function()
			SetClipboardText(queryData.Query)
		end

		CountBadge:SetPos(Row:GetWide() - CountBadge:GetWide() - pad, pad + rowH / 2 - CountBadge:GetTall() / 2)
		TypeBadge:SetPos(CountBadge:GetX() - TypeBadge:GetWide() - GProfiler.GetScaledSize(5), pad + rowH / 2 - TypeBadge:GetTall() / 2)
		CopyBtn:SetPos(TypeBadge:GetX() - CopyBtn:GetWide() - GProfiler.GetScaledSize(5), pad + rowH / 2 - CopyBtn:GetTall() / 2)

		Row:SetTall(rowH + pad * 2)

		local QueryParser = GProfiler.Database.QueryParser.New()
		local template = QueryParser:ParseTemplate(queryData.Query)

		surface.SetFont("GProfiler.Inter24")
		local _, lineH = surface.GetTextSize("A")
		local maxW = Row:GetWide() - pad * 2 - GProfiler.GetScaledSize(10)
		local xoff, yoff = 0, 0
		local queryH = lineH

		for _, v in ipairs(template) do
			if v[1] == "\n" then
				xoff = 0
				queryH = queryH + lineH
			else
				local tw = surface.GetTextSize(v[1])
				if xoff + tw > maxW then
					xoff = 0
					queryH = queryH + lineH
				end
				xoff = xoff + tw
			end
		end

		local TextBg = vgui.Create("DPanel", Row)
		TextBg:SetPos(pad, Row:GetTall())
		TextBg:SetSize(Row:GetWide() - pad * 2, queryH + pad)
		TextBg.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(18, 28, 39, 255))
		end

		xoff, yoff = GProfiler.GetScaledSize(5), GProfiler.GetScaledSize(5)
		for _, v in ipairs(template) do
			if v[1] == "\n" then
				xoff = GProfiler.GetScaledSize(5)
				yoff = yoff + lineH
				continue
			end

			local lbl = vgui.Create("DLabel", TextBg)
			local displayText = v[1]
			if v[2] == 1 and Database.MySQLKeywords and not Database.MySQLKeywords[displayText] then
				displayText = displayText:upper()
			end
			lbl:SetText(displayText)
			lbl:SetFont("GProfiler.Inter24")
			lbl:SetTextColor(GProfiler.SyntaxColors.text)
			lbl:SizeToContents()
			lbl:SetPos(xoff, yoff)

			local cat = Database.TokenCategories and Database.TokenCategories[v[2]]
			if cat then
				lbl:SetToolTip(cat.name .. ": " .. cat.description)
				lbl:SetMouseInputEnabled(true)
				lbl.hoverlerp = 0
				lbl.Paint = function(self, w, h)
					self.hoverlerp = Lerp(FrameTime() * 10, self.hoverlerp, self:IsHovered() and 1 or 0)
					if self.hoverlerp > 0 then
						GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 50 * self.hoverlerp))
					end
				end
			end

			xoff = xoff + lbl:GetWide()
			if xoff > maxW then
				xoff = GProfiler.GetScaledSize(5)
				yoff = yoff + lineH
			end
		end

		Row:SetTall(Row:GetTall() + TextBg:GetTall() + GProfiler.GetScaledSize(5))

		local TimelineData = {}
		for k2, qd in pairs(Database.ProfileData or {}) do
			table.insert(TimelineData, {Query = qd.Query, Time = qd.AverageTime or 0, QueryId = k2})
		end

		local Timeline = CreateTimelinePanel(Row, Row:GetWide() - pad * 2, GProfiler.GetScaledSize(15), TimelineData, queryData.Query)
		Timeline:SetPos(pad, Row:GetTall())
		Row:SetTall(Row:GetTall() + Timeline:GetTall() + GProfiler.GetScaledSize(5))

		local Collapses = {}
		local function CreateCollapse(name, id, rightText)
			local collapseH = GProfiler.GetScaledSize(40)
			local Collapse = vgui.Create("DCollapsibleCategory", Row)
			Collapse:SetSize(Row:GetWide() - pad * 2, collapseH)
			Collapse:SetPos(pad, Row:GetTall())
			Collapse:SetLabel(name)
			Collapse:SetExpanded(false)
			Collapse:SetAnimTime(0)
			Collapse.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(39, 75, 113))
				if rightText then
					draw.SimpleText(rightText, "GProfiler.Inter24", w - pad, collapseH / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
			end
			Collapse.Header:SetFont("GProfiler.Inter24")
			Collapse.Header:SetTall(collapseH)

			Row:SetTall(Row:GetTall() + collapseH + GProfiler.GetScaledSize(2))

			local ContentPanel = vgui.Create("DPanel", Collapse)
			ContentPanel:SetSize(Collapse:GetWide(), 0)
			ContentPanel.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(15, 22, 30, 255), GProfiler.RNDX.NO_TL + GProfiler.RNDX.NO_TR)
			end
			Collapse:SetContents(ContentPanel)

			Collapse.OnToggle = function(self, expanded)
				local delta = ContentPanel:GetTall()
				Row:SetTall(Row:GetTall() + (expanded and delta or -delta))
				if id == 1 then
					Collapses[2]:SetPos(Collapses[2]:GetX(), Collapses[2]:GetY() + (expanded and delta or -delta))
					Collapses[3]:SetPos(Collapses[3]:GetX(), Collapses[3]:GetY() + (expanded and delta or -delta))
				elseif id == 2 then
					Collapses[3]:SetPos(Collapses[3]:GetX(), Collapses[3]:GetY() + (expanded and delta or -delta))
				end
				if ContentPanel.OnToggle then ContentPanel:OnToggle(expanded) end
			end

			table.insert(Collapses, Collapse)
			return Collapse, ContentPanel
		end

		local sourceRightText = string.format("%s (%d - %d)", queryData.Source.File, queryData.Source.Line1, queryData.Source.Line2)
		local ExplainCollapse, ExplainPanel = CreateCollapse("Explain", 1)
		local InternalCollapse, InternalPanel = CreateCollapse("Profile", 2)
		local SourceCollapse, SourcePanel = CreateCollapse("Source", 3, sourceRightText)

		if not explains[id] or explains[id].noExplain then
			local lbl = vgui.Create("DLabel", ExplainPanel)
			lbl:SetText("No explain data available.")
			lbl:SetFont("GProfiler.Inter24")
			lbl:SetTextColor(GProfiler.SyntaxColors.comment)
			lbl:SizeToContents()
			ExplainPanel:SetTall(lbl:GetTall())
		else
			local Columns = {"Select Type", "Table", "Type", "Possible Keys", "Key", "Key Len", "Ref", "Rows", "Extra"}
			local innerW = ExplainPanel:GetWide()
			local colW = innerW / #Columns

			local HeaderRow = vgui.Create("DPanel", ExplainPanel)
			HeaderRow:SetSize(innerW, rowH)
			HeaderRow.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10))
			end
			for i, col in ipairs(Columns) do
				local lbl = vgui.Create("DLabel", HeaderRow)
				lbl:SetText(col)
				lbl:SetFont("GProfiler.Inter24")
				lbl:SetTextColor(GProfiler.SyntaxColors.text)
				lbl:SizeToContents()
				lbl:SetPos((i - 1) * colW + GProfiler.GetScaledSize(5), rowH / 2 - lbl:GetTall() / 2)
			end

			local totalH = rowH
			for i, explain in ipairs(explains[id]) do
				local ExplainRow = vgui.Create("DPanel", ExplainPanel)
				ExplainRow:SetSize(innerW, rowH)
				ExplainRow:SetPos(0, totalH)
				ExplainRow.Paint = function(s, w, h)
					GProfiler.RNDX.Draw(0, 0, 0, w, h, i % 2 == 0 and Color(255, 255, 255, 5) or Color(255, 255, 255, 2))
				end
				for j, col in ipairs(Columns) do
					local val = explain[col:lower():gsub(" ", "_")]
					local valStr = tostring(val ~= nil and val or "N/A")
					local lbl = vgui.Create("DLabel", ExplainRow)
					lbl:SetText(valStr)
					lbl:SetFont("GProfiler.Inter24")
					lbl:SetTextColor(GProfiler.SyntaxColors.text)
					lbl:SizeToContents()
					lbl:SetPos((j - 1) * colW + GProfiler.GetScaledSize(5), rowH / 2 - lbl:GetTall() / 2)
					lbl:SetMouseInputEnabled(true)
					lbl:SetToolTip(valStr)
				end
				totalH = totalH + rowH
			end
			ExplainPanel:SetTall(totalH)
		end

		local ProfColumns = {"Status", "Duration", "Percentage"}
		local profInnerW = InternalPanel:GetWide()
		local profColW = profInnerW / #ProfColumns

		local ProfHeader = vgui.Create("DPanel", InternalPanel)
		ProfHeader:SetSize(profInnerW, rowH)
		ProfHeader.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10))
		end
		for i, col in ipairs(ProfColumns) do
			local lbl = vgui.Create("DLabel", ProfHeader)
			lbl:SetText(col)
			lbl:SetFont("GProfiler.Inter24")
			lbl:SetTextColor(GProfiler.SyntaxColors.text)
			lbl:SizeToContents()
			lbl:SetPos((i - 1) * profColW + GProfiler.GetScaledSize(5), rowH / 2 - lbl:GetTall() / 2)
		end

		local internalData = queryData.InternalData
		if internalData then
			local totalH = rowH
			for i, entry in ipairs(internalData) do
				local duration = (entry.Duration or 0) * 1000
				local pct = queryData.AverageTime > 0 and (entry.Duration or 0) / queryData.AverageTime * 100 or 0
				local statusColor = duration > 1000 and Color(255, 0, 0) or (duration > 500 and Color(255, 165, 0) or Color(0, 255, 0))
				local values = {entry.Status or "N/A", string.format("%.3fms", duration), string.format("%.2f%%", pct)}

				local ProfRow = vgui.Create("DPanel", InternalPanel)
				ProfRow:SetSize(profInnerW, rowH)
				ProfRow:SetPos(0, totalH)
				ProfRow.Paint = function(s, w, h)
					GProfiler.RNDX.Draw(0, 0, 0, w, h, i % 2 == 0 and Color(255, 255, 255, 5) or Color(255, 255, 255, 2))
					GProfiler.RNDX.Draw(100, w - rowH - GProfiler.GetScaledSize(8), rowH / 4, rowH / 2, rowH / 2, statusColor)
				end
				for j, val in ipairs(values) do
					local lbl = vgui.Create("DLabel", ProfRow)
					lbl:SetText(val)
					lbl:SetFont("GProfiler.Inter24")
					lbl:SetTextColor(GProfiler.SyntaxColors.text)
					lbl:SizeToContents()
					lbl:SetPos((j - 1) * profColW + GProfiler.GetScaledSize(5), rowH / 2 - lbl:GetTall() / 2)
				end
				totalH = totalH + rowH
			end
			InternalPanel:SetTall(totalH)
		else
			ProfHeader:SetVisible(false)
			local lbl = vgui.Create("DLabel", InternalPanel)
			lbl:SetText("No profile data available.")
			lbl:SetFont("GProfiler.Inter24")
			lbl:SetTextColor(GProfiler.SyntaxColors.comment)
			lbl:SizeToContents()
			InternalPanel:SetTall(lbl:GetTall())
		end

		local RichText = vgui.Create("RichText", SourcePanel)
		RichText:SetText("Expand to load source.")
		RichText:SetSize(SourcePanel:GetWide(), GProfiler.GetScaledSize(200))
		RichText:SetVerticalScrollbarEnabled(true)
		function RichText:PerformLayout()
			self:SetFontInternal("GProfiler.Code")
		end
		SourcePanel:SetTall(RichText:GetTall())

		local requestedSource = false
		function SourcePanel:OnToggle(expanded)
			if not expanded or requestedSource then return end
			requestedSource = true
			GProfiler.RequestFunctionSource(queryData.Source.File, queryData.Source.Line1, queryData.Source.Line2, function(src)
				if not IsValid(RichText) then return end
				if src then
					GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), queryData.Source.Line1)
				else
					RichText:SetText("Failed to load source.")
				end
			end)
		end

		Row:SetTall(Row:GetTall() + pad)

		return Row
	end

	local function PopulateQueries()
		QueryList:Clear()
		local data = Database.ProfileData
		local explains = Database.Explains or {}
		if not data or table.Count(data) == 0 then return end
		for id, queryData in ipairs(data) do
			local Row = CreateRow(id, queryData, explains)
			QueryList:AddItem(Row)
		end
	end
	Database.RefreshUI = PopulateQueries
	PopulateQueries()
end

GProfiler.Menu.RegisterTab("Database", "gprofiler/database.png", 8, GProfiler.Database.DoTab, function()
	local timer = DatabaseStore:GetTimerData("Server")
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

local TypeLookup = {
	[1] = "mysqloo",
	[2] = "tmysql4",
	[3] = "goobie_mysql",
	[4] = "sqlite"
}

net.Receive("GProfiler_Database_SendData", function()
	local isFirstChunk = net.ReadBool()
	local isLastChunk = net.ReadBool()

	if isFirstChunk then
		Database.ProfileData = {}
		Database.Explains = {}
	end

	local count = net.ReadUInt(14)
	for i = 1, count do
		local id = net.ReadUInt(14)
		local typeId = net.ReadUInt(3)
		Database.ProfileData[id] = {
			Type = TypeLookup[typeId] or "unknown",
			Count = net.ReadUInt(14),
			Time = net.ReadFloat(),
			AverageTime = net.ReadFloat(),
			LongestTime = net.ReadFloat(),
			Query = net.ReadString(),
			Source = {
				File = net.ReadString(),
				Line1 = net.ReadUInt(16),
				Line2 = net.ReadUInt(16)
			}
		}

		if net.ReadBool() then
			local internalData = {}
			local internalCount = net.ReadUInt(7)
			for j = 1, internalCount do
				internalData[j] = {
					Duration = net.ReadFloat(),
					Status = net.ReadString()
				}
			end
			Database.ProfileData[id].InternalData = internalData
		else
			Database.ProfileData[id].InternalData = false
		end
	end

	count = net.ReadUInt(14)
	for i = 1, count do
		local id = net.ReadUInt(14)
		if net.ReadBool() then
			Database.Explains[id] = {noExplain = true}
		else
			local explainCount = net.ReadUInt(6)
			Database.Explains[id] = {}
			for j = 1, explainCount do
				Database.Explains[id][j] = {
					select_type = net.ReadString(),
					table = net.ReadString(),
					type = net.ReadString(),
					possible_keys = net.ReadString(),
					key = net.ReadString(),
					key_len = net.ReadString(),
					ref = net.ReadString(),
					rows = net.ReadUInt(32),
					extra = net.ReadString()
				}
			end
		end
	end

	if isLastChunk then
		DatabaseStore:SetData("Server", Database.ProfileData)
		if Database.RefreshUI then Database.RefreshUI() end
	end
end)
