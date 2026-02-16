GProfiler.Database = GProfiler.Database or {}
GProfiler.Database.ProfileActive = GProfiler.Database.ProfileActive or false
GProfiler.Database.StartTime = GProfiler.Database.StartTime or 0
GProfiler.Database.EndTime = GProfiler.Database.EndTime or 0
GProfiler.Database.ProfileActive = GProfiler.Database.ProfileActive or false

local TabPadding = 10
local MenuColors = GProfiler.MenuColors

local function QueryTimeScore(query, queryTime)
  if queryTime > 0.5 then
    return Color(238, 95, 91, 255)
  elseif queryTime > 0.1 then
    return Color(250, 167, 50, 255)
  end
  return Color(94, 185, 94, 255)
end


local function CreateTimelinePanel(parent, w, h, data, currentQuery)
  local minWidth = 10
  local TimelinePanel = vgui.Create("DPanel", parent)
  TimelinePanel:SetSize(w, h)
  TimelinePanel.Paint = function(s, w, h)
    draw.RoundedBox(4, 0, 0, w, h, MenuColors.OpaqueBlack2)

		if s.ShowData then -- hack: reduces freezes, don't question what works
			s:ShowData()
		end
  end

  function TimelinePanel:ShowData()
		TimelinePanel.ShowData = nil

		local totalTime = 0
		for _, entry in ipairs(data) do
			totalTime = totalTime + entry.Time
		end

		local startX = 0
		local SpaceBetweenEntries = 1
		local allocatedWidth = 0
		local widths = {}

		for _, entry in ipairs(data) do
			local entryWidth = (w * entry.Time / totalTime)
			if entryWidth < minWidth then entryWidth = minWidth end
			table.insert(widths, entryWidth)
			allocatedWidth = allocatedWidth + entryWidth
		end

		local scale = w / allocatedWidth

		for k, entry in ipairs(data) do
			local entryWidth = widths[k] * scale - SpaceBetweenEntries
			if entryWidth < 1 then entryWidth = 1 end
			local entryColor = QueryTimeScore(entry.Query, entry.Time)
			if entry.Query != currentQuery then entryColor.a = 25 end

			local entryPanel = vgui.Create("DPanel", TimelinePanel)
			if k == #data then entryPanel:SetSize(w - startX, h)
			else entryPanel:SetSize(entryWidth, h) end
			entryPanel:SetPos(startX, 0)
			local HoverColor = table.Copy(entryColor)
			entryPanel.Lerp = 0
			entryPanel.Paint = function(s, w, h)
				draw.RoundedBox(2, 0, 1, w - 2, h - 2, entryColor)

				if s:IsHovered() then
					s.Lerp = Lerp(FrameTime() * 10, s.Lerp, 1)
				else
					s.Lerp = Lerp(FrameTime() * 10, s.Lerp, 0)
				end

				if s.Lerp > 0 then
					HoverColor.a = (230 * s.Lerp)
					draw.RoundedBox(2, 0, 1, w - 2, h - 2, HoverColor)
				end
			end
			entryPanel:SetCursor("hand")
			entryPanel.OnMousePressed = function()
				print("Clicked on entry:", entry.QueryId)
				GProfiler.Database.SelectedQuery = entry.QueryId
			end

			startX = startX + entryPanel:GetWide() + SpaceBetweenEntries
		end
	end

  return TimelinePanel
end


function GProfiler.Database.DoTab(Content)
	local Header = vgui.Create("EditablePanel", Content)
	Header:SetSize(Content:GetWide(), 40)
	Header:SetMouseInputEnabled(true)
	Header:SetPos(0, 10)
	Header.Paint = nil

	local StartButton = vgui.Create("DButton", Header)
	StartButton:SetText(GProfiler.Database.ProfileActive and GProfiler.Language.GetPhrase("profiler_stop") or GProfiler.Language.GetPhrase("profiler_start"))
	StartButton:SetTextColor(MenuColors.White)
	StartButton:SetFont("GProfiler.Menu.StartButton")
	StartButton:SizeToContents()
	StartButton:SetTall(Header:GetTall() - 6)
	StartButton:SetPos(Header:GetWide() - StartButton:GetWide() - TabPadding * 2, Header:GetTall() / 2 - StartButton:GetTall() / 2)
	StartButton.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
		draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

		if s:IsHovered() then
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
		end
	end

	StartButton.DoClick = function()
		if GProfiler.Database.ProfileActive then
			GProfiler.Database.EndTime = SysTime()
			GProfiler.Database.Override = GProfiler.TimeRunning(GProfiler.Database.StartTime, SysTime(), GProfiler.Database.ProfileActive) .. "s"

			net.Start("GProfiler_Database_ToggleServerProfile")
			net.WriteBool(false)
			net.SendToServer()
		else
			GProfiler.Database.StartTime = SysTime()
			GProfiler.Database.EndTime = 0
			GProfiler.Database.Override = nil
			net.Start("GProfiler_Database_ToggleServerProfile")
			net.WriteBool(true)
			net.SendToServer()
		end
	end

	local TimeRunning = vgui.Create("DLabel", Header)
	TimeRunning:SetFont("GProfiler.Menu.SectionHeader")
	TimeRunning:SetText(GProfiler.TimeRunning(GProfiler.Database.StartTime, GProfiler.Database.EndTime, GProfiler.Database.ProfileActive) .. "s")
	TimeRunning:SizeToContents()
	TimeRunning:SetPos(Header:GetWide() - TimeRunning:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - TimeRunning:GetTall() / 2)
	TimeRunning:SetTextColor(MenuColors.White)
	function TimeRunning:Think()
		if GProfiler.Database.ProfileActive then
			self:SetText(GProfiler.TimeRunning(GProfiler.Database.StartTime, 0, GProfiler.Database.ProfileActive) .. "s")
			self:SizeToContents()
			self:SetPos(Header:GetWide() - self:GetWide() - StartButton:GetWide() - TabPadding * 3, Header:GetTall() / 2 - self:GetTall() / 2)
		end
	end

	local ReceivingData = vgui.Create("DLabel", Header)
	ReceivingData:SetFont("GProfiler.Menu.SectionHeader")
	ReceivingData:SetText("Receiving data...    ")
	ReceivingData:SizeToContents()
	ReceivingData:SetPos(Header:GetWide() - ReceivingData:GetWide() - StartButton:GetWide() - TimeRunning:GetWide() - TabPadding * 3, Header:GetTall() / 2 - ReceivingData:GetTall() / 2)
	ReceivingData:SetTextColor(Color(225, 66, 66))
	function ReceivingData:Think()
		if GProfiler.Database.ReceivingData then
			self:SetVisible(true)
		else
			self:SetVisible(false)
		end
	end

	local ContentArea = vgui.Create("DPanel", Content)
	ContentArea:SetSize(Content:GetWide() - 10, Content:GetTall() - Header:GetTall() - 20)
	ContentArea:SetPos(5, Header:GetTall() + 15)
	ContentArea.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListBackground)
	end

	local List = vgui.Create("DPanelList", ContentArea)
	List:SetSize(ContentArea:GetWide(), ContentArea:GetTall())
	List:SetPos(0, 0)
	List:SetSpacing(5)
	List:EnableHorizontal(false)
	List:EnableVerticalScrollbar(true)

	local ScrollBar = List.VBar
	ScrollBar:SetWide(10)
	ScrollBar:SetHideButtons(true)
	ScrollBar.Paint = function(s, w, h) draw.RoundedBox(4, 2, 0, w - 2, h, MenuColors.ScrollBar) end
	ScrollBar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(4, 2, 0, w - 2, h, MenuColors.ScrollBarGrip) end

	if not GProfiler.Database.ProfileData or table.Count(GProfiler.Database.ProfileData) == 0 then
		local NoData = vgui.Create("DLabel", ContentArea)
		NoData:SetText(GProfiler.Language.GetPhrase("profiler_no_data"))
		NoData:SetFont("GProfiler.Menu.SectionHeader")
		NoData:SizeToContents()
		NoData:SetPos(ContentArea:GetWide() / 2 - NoData:GetWide() / 2, ContentArea:GetTall() / 2 - NoData:GetTall() / 2)
		NoData:SetTextColor(MenuColors.White)
		return
	end

	local Data = GProfiler.Database.ProfileData
	local Explains = GProfiler.Database.Explains or {}

	local TimelineData = {}
	for k, queryData in pairs(Data) do
		local query = queryData.Query
		local time = queryData.AverageTime or 0
		local color = QueryTimeScore(query, time)
		table.insert(TimelineData, {Query = query, Time = time, Color = color, QueryId = k})
	end

	local function CreateRow(List, id, queryData)
		local Row = vgui.Create("DPanel", List)
		Row:SetSize(List:GetWide() --[[/ 2]] - 10, 30)
		Row.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListRowBackground)
		end
		Row.Think = function(s)
			if GProfiler.Database.SelectedQuery == s.QueryId then
				GProfiler.Database.SelectedQuery = nil
				List:ScrollToChild(s)
			end
		end
		Row.QueryId = id

		surface.SetFont("GProfiler.Menu.RowText")
		local Label = vgui.Create("DLabel", Row)
		Label:SetText(string.format("%d. Query Time:", id))
		Label:SetFont("GProfiler.Menu.RowText")
		Label:SizeToContents()
		Label:SetPos(10, 10)

		local time = string.format("%.2fms", queryData.AverageTime * 1000)
		local badgeW, badgeH = surface.GetTextSize(time)
		local TimeBadge = vgui.Create("DPanel", Row)
		TimeBadge:SetSize(badgeW + 10, badgeH + 4)
		TimeBadge:SetPos(10 + Label:GetWide() + 5, 10)
		local ScoreCol = QueryTimeScore(queryData.Query, queryData.AverageTime)
		TimeBadge.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, ScoreCol)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)
			draw.SimpleText(time, "GProfiler.Menu.RowText", w / 2, h / 2, MenuColors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local TimesRun = vgui.Create("DLabel", Row)
		TimesRun:SetText(string.format("x%d", queryData.Count))
		TimesRun:SetFont("GProfiler.Menu.RowText")
		TimesRun:SizeToContents()
		TimesRun:SetSize(TimesRun:GetWide() + 10, TimesRun:GetTall() + 4)
		TimesRun:SetPos(Row:GetWide() - TimesRun:GetWide() - 10, 10)
		TimesRun:SetTextColor(color_white)
		TimesRun:SetContentAlignment(5)
		TimesRun.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.OpaqueBlack2)
		end

		local TypeBadge = vgui.Create("DLabel", Row)
		TypeBadge:SetText(queryData.Type or "Unknown")
		TypeBadge:SetFont("GProfiler.Menu.RowText")
		TypeBadge:SizeToContents()
		TypeBadge:SetSize(TypeBadge:GetWide() + 10, TypeBadge:GetTall() + 4)
		TypeBadge:SetPos(Row:GetWide() - TimesRun:GetWide() - TypeBadge:GetWide() - 20, 10)
		TypeBadge:SetTextColor(MenuColors.White)
		TypeBadge:SetContentAlignment(5)
		TypeBadge.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.OpaqueBlack2)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack)
		end

		local CopyQuery = vgui.Create("DButton", Row)
		CopyQuery:SetText(GProfiler.Language.GetPhrase("profiler_copy_query"))
		CopyQuery:SetFont("GProfiler.Menu.RowText")
		CopyQuery:SizeToContents()
		CopyQuery:SetSize(CopyQuery:GetWide() + 10, TimesRun:GetTall())
		CopyQuery:SetPos(Row:GetWide() - TimesRun:GetWide() - TypeBadge:GetWide() - CopyQuery:GetWide() - 30, 10)
		CopyQuery:SetTextColor(MenuColors.White)
		CopyQuery.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.OpaqueBlack2)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)
			if s:IsHovered() then
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
			end
		end
		CopyQuery.DoClick = function()
			SetClipboardText(queryData.Query)
		end

		Row:SetTall(TimeBadge:GetTall() + 20)

		local QueryParser = GProfiler.Database.QueryParser.New()
		local template = QueryParser:ParseTemplate(queryData.Query)
		local templateString = ""
		for _, v in ipairs(template) do
			if v[1] == "\n" then
				templateString = templateString .. "\n"
			else
				templateString = templateString .. "" .. v[1]
			end
		end

		local function GetRealTextHeight(text, font, maxW)
			surface.SetFont(font)
			local lines = string.Explode("\n", text)
			local totalHeight = 0
			for _, line in ipairs(lines) do
				local lineWidth, lineHeight = surface.GetTextSize(line)
				if lineWidth > maxW then
					local words = string.Explode(" ", line)
					local currentLine = ""
					for _, word in ipairs(words) do
						if surface.GetTextSize(currentLine .. " " .. word) <= maxW then
							currentLine = currentLine .. " " .. word
						else
							totalHeight = totalHeight + lineHeight
							currentLine = word
							if surface.GetTextSize(currentLine) > maxW*2 then
								totalHeight = totalHeight + lineHeight
							end
						end
					end
					totalHeight = totalHeight + lineHeight
				else
					totalHeight = totalHeight + lineHeight
				end
			end

			return totalHeight
		end

		local queryH = GetRealTextHeight(templateString, "GProfiler.Menu.RowText", Row:GetWide() - 50)
		local TextArea = vgui.Create("DTextEntry", Row)
		TextArea:SetPos(10, 15 + TimeBadge:GetTall())
		TextArea:SetText(queryData.Query)
		TextArea:SetFont("GProfiler.Menu.RowText")
		TextArea:SetMultiline(true)
		TextArea:SetEditable(false)
		TextArea:SetSize(Row:GetWide() - 20, queryH + 10)
		TextArea:SetMouseInputEnabled(false)
		TextArea:SizeToContentsY()
		TextArea:SetPaintBackground(false)
		TextArea:SetTextColor(Color(255, 255, 255, 255))
		TextArea.Paint = function(s, w, h)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack)
			draw.SimpleText(s:GetText(), "GProfiler.Menu.RowText", 5, 5, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end

		local TextAreaCover = vgui.Create("DPanel", Row)
		TextAreaCover:SetPos(10, 15 + TimeBadge:GetTall())
		TextAreaCover:SetSize(TextArea:GetWide(), TextArea:GetTall())
		TextAreaCover.Paint = nil

		local fHeight = draw.GetFontHeight("GProfiler.Menu.RowText")
		local function CreateTemplate()
			if TextAreaCover.TemplateCreated then return end
			TextAreaCover.TemplateCreated = true
			TextArea.Paint = function(s, w, h)
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack)
			end

			local xoff, yoff = 5, 5
			local maxw = TextArea:GetWide() - 20
			for _, v in ipairs(template) do
				if v[1] == "\n" and v[2] == 12 then
					xoff = 5
					yoff = yoff + fHeight
					continue
				end

				local cat = GProfiler.Database.TokenCategories[v[2]] or { name = "Unknown", description = "Unknown category" }
				local label = vgui.Create("DLabel", TextAreaCover)
				label:SetText(v[2] ~= 12 and ("" .. v[1] .. "") or " ")
				label:SetFont("GProfiler.Menu.RowText")
				label:SizeToContents()
				label:SetPos(xoff, yoff)
				if v[2] == 1 and not GProfiler.Database.MySQLKeywords[v[1]] then v[1] = v[1]:upper() end
				label:SetToolTip((v[2] == 1 and (v[1] .. " - " .. (GProfiler.Database.MySQLKeywords[v[1]])) or "Token") .. (cat and ("\n" .. (cat.name or "?") .. ": " .. (cat.description or "?")) or ""))
				label:SetMouseInputEnabled(true)
				label:SetTextColor(color_white)
				label.hoverlerp = 0
				label.Paint = function(self, w, h)
					if self:IsHovered() then
						self.hoverlerp = Lerp(FrameTime() * 10, self.hoverlerp, 1)
					else
						self.hoverlerp = Lerp(FrameTime() * 10, self.hoverlerp, 0)
					end

					if self.hoverlerp > 0 then
						draw.RoundedBox(4, 0, 0, w, h, Color(255, 255, 255, 10 * self.hoverlerp))
					end
				end

				local lw = label:GetWide()
				xoff = xoff + lw
				if xoff + lw > maxw then
					xoff = 5
					yoff = yoff + fHeight
				end
			end
		end
		TextAreaCover.OnCursorEntered = function() CreateTemplate() end
		if string.find(queryData.Query, "\n") then CreateTemplate() end
		if queryH > draw.GetFontHeight("GProfiler.Menu.RowText") then CreateTemplate() end

		Row:SetTall(Row:GetTall() + TextArea:GetTall() + 10)

		local TimelinePanel = CreateTimelinePanel(Row, Row:GetWide() - 20, 15, TimelineData, queryData.Query)
		TimelinePanel:SetPos(10, 15 + TimeBadge:GetTall() + TextArea:GetTall() + 5)

		Row:SetTall(Row:GetTall() + TimelinePanel:GetTall() + 5)

		local Collapses = {}

		local function CreateCollapse(Name, Id, RighText)
			local Collapse = vgui.Create("DCollapsibleCategory", Row)
			Collapse:SetSize(Row:GetWide() - 20, fHeight * 2)
			Collapse:SetPos(10, 25 + TimeBadge:GetTall() + TextArea:GetTall() + TimelinePanel:GetTall() + (Id - 1) * (fHeight * 2 + 5))
			Collapse:SetLabel(GProfiler.Language.GetPhrase(Name))
			Collapse:SetExpanded(false)
			Collapse:SetAnimTime(0)
			Collapse.Paint = function(s, w, h)
				draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListColumnBackground)
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)

				if s:IsHovered() then
					draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)
				end

				if RighText then
					draw.SimpleText(RighText, "GProfiler.Menu.RowText", w - 10, (fHeight * 2) / 2, Color(255, 255, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				end
			end
			Collapse.Header:SetFont("GProfiler.Menu.RowText")
			Collapse.Header:SetTall(fHeight * 2)

			Row:SetTall(Row:GetTall() + Collapse.Header:GetTall() + 2)
			local BaseHeight = Row:GetTall()
			local CollapsePanel = vgui.Create("DPanel", Collapse)
			CollapsePanel:SetSize(Collapse:GetWide(), Collapse:GetTall())
			CollapsePanel.Paint = function(s, w, h)
				draw.RoundedBoxEx(4, 2, 2, w - 4, h - 4, MenuColors.OpaqueBlack, false, false, true, true)
			end
			CollapsePanel:SetTall(0)
			Collapse:SetContents(CollapsePanel)
			Collapse.OnToggle = function(self, expanded)
				if expanded then
					Row:SetTall(Row:GetTall() + CollapsePanel:GetTall())
					if Id == 1 then
						Collapses[2]:SetPos(10, Collapses[2]:GetY() + CollapsePanel:GetTall())
						Collapses[3]:SetPos(10, Collapses[3]:GetY() + CollapsePanel:GetTall())
					elseif Id == 2 then
						Collapses[3]:SetPos(10, Collapses[3]:GetY() + CollapsePanel:GetTall())
					end
				else
					Row:SetTall(Row:GetTall() - CollapsePanel:GetTall())
					if Id == 1 then
						Collapses[2]:SetPos(10, Collapses[2]:GetY() - CollapsePanel:GetTall())
						Collapses[3]:SetPos(10, Collapses[3]:GetY() - CollapsePanel:GetTall())
					elseif Id == 2 then
						Collapses[3]:SetPos(10, Collapses[3]:GetY() - CollapsePanel:GetTall())
					end
				end

				if CollapsePanel.OnToggle then
					CollapsePanel:OnToggle(expanded)
				end
			end

			table.insert(Collapses, Collapse)

			return Collapse, CollapsePanel
		end

		local ExplainCollapse, ExplainPanel = CreateCollapse("Explain", 1)
		local InternalCollapse, InternalPanel = CreateCollapse("Profile", 2)
		local SourceCollapse, SourcePanel = CreateCollapse("Source", 3, string.format("%s (%s - %s)", queryData.Source.File, queryData.Source.Line1, queryData.Source.Line2))

		if not Explains[id] or (Explains[id])["noExplain"] then
			local NoExplain = vgui.Create("DLabel", ExplainPanel)
			NoExplain:SetText(GProfiler.Language.GetPhrase("profiler_no_explain"))
			NoExplain:SetFont("GProfiler.Menu.RowText")
			NoExplain:SizeToContents()
			NoExplain:SetSize(NoExplain:GetWide() + 10, NoExplain:GetTall() + 20)
			NoExplain:SetContentAlignment(5)
			NoExplain:SetTextColor(Color(255, 255, 255, 200))
		else
			local Columns = {"Select Type", "Table", "Type", "Possible Keys", "Key", "Key Len", "Ref", "Rows", "Extra"}
			local HeaderPanel = vgui.Create("DPanel", ExplainPanel)
			HeaderPanel:SetSize(ExplainPanel:GetWide(), fHeight * 2)
			HeaderPanel.Paint = function(s, w, h)
				draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListColumnBackground)
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)
			end

			for i, col in ipairs(Columns) do
				local HeaderLabel = vgui.Create("DLabel", HeaderPanel)
				HeaderLabel:SetText(col)
				HeaderLabel:SetFont("GProfiler.Menu.RowText")
				HeaderLabel:SizeToContents()
				HeaderLabel:SetPos((i - 1) * (HeaderPanel:GetWide() / #Columns) + 5, fHeight / 2 - HeaderLabel:GetTall() / 2 + 8)
				HeaderLabel:SetTextColor(MenuColors.White)
				HeaderLabel:SetContentAlignment(5)
			end

			for i, explain in ipairs(Explains[id] or {}) do
				local ExplainRow = vgui.Create("DPanel", ExplainPanel)
				ExplainRow:SetSize(ExplainPanel:GetWide(), fHeight * 2)
				ExplainRow:SetPos(0, (i) * (fHeight  * 2))
				ExplainRow.Paint = function(s, w, h)
					draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListColumnBackground)
					draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack)
				end

				for j, col in ipairs(Columns) do
					local Value = explain[col:lower():gsub(" ", "_")] or "N/A"
					local ValueLabel = vgui.Create("DLabel", ExplainRow)
					ValueLabel:SetToolTip(Value)
					if j < #Columns then
						local maxW = (ExplainRow:GetWide() / #Columns) - 10
						if surface.GetTextSize(Value) > maxW then
							Value = string.sub(Value, 1, math.floor(maxW / surface.GetTextSize("a") * 0.8)) .. "..."
						end
					elseif j == #Columns then
						local maxW = (ExplainRow:GetWide() / #Columns) - 10
						if surface.GetTextSize(Value) > maxW then
							Value = string.sub(Value, 1, math.floor(maxW / surface.GetTextSize("a"))) .. "..."
						end
					end
					ValueLabel:SetText(Value)
					ValueLabel:SetFont("GProfiler.Menu.RowText")
					ValueLabel:SizeToContents()
					ValueLabel:SetPos((j - 1) * (ExplainRow:GetWide() / #Columns) + 5, fHeight / 2 - ValueLabel:GetTall() / 2 + 8)
					ValueLabel:SetTextColor(MenuColors.White)
					ValueLabel:SetContentAlignment(5)
					ValueLabel:SetMouseInputEnabled(true)
				end

				ExplainPanel:Add(ExplainRow)
			end
		end

		local Columns = {"Status", "Duration", "Percentage"}
		local InternalHeaderPanel = vgui.Create("DPanel", InternalPanel)
		InternalHeaderPanel:SetSize(InternalPanel:GetWide(), fHeight * 2)
		InternalHeaderPanel.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListColumnBackground)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)
		end

		local colWidth = (InternalHeaderPanel:GetWide() - 10) / #Columns
		for i, col in ipairs(Columns) do
			local HeaderLabel = vgui.Create("DLabel", InternalHeaderPanel)
			HeaderLabel:SetText(col)
			HeaderLabel:SetFont("GProfiler.Menu.RowText")
			HeaderLabel:SizeToContents()
			HeaderLabel:SetPos((i - 1) * colWidth + 5, fHeight / 2 - HeaderLabel:GetTall() / 2 + 8)
			HeaderLabel:SetTextColor(MenuColors.White)
			HeaderLabel:SetContentAlignment(5)
		end

		local internalData = queryData.InternalData
		if internalData then
			for i, data in ipairs(internalData) do
				local InternalRow = vgui.Create("DPanel", InternalPanel)
				InternalRow:SetSize(InternalPanel:GetWide(), fHeight * 2)
				InternalRow:SetPos(0, (i) * (fHeight * 2))
				InternalRow.Paint = function(s, w, h)
					draw.RoundedBox(4, 0, 0, w, h, MenuColors.DListColumnBackground)
					draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack)

					if s:IsHovered() then
						draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.OpaqueBlack2)
					end

					if s.PaintColor then
						draw.RoundedBox(100, w - h - 8, h / 4, h / 2, h / 2, s.PaintColor)
					end
				end

				for j, col in ipairs(Columns) do
					local Value = data[col]
					if col == "Percentage" then
						local totalTime = queryData.AverageTime or 0
						Value = totalTime > 0 and (data.Duration or 0) / totalTime or 0
					end
					local ValueLabel = vgui.Create("DLabel", InternalRow)
					ValueLabel:SetToolTip(Value)
					if j < #Columns then
						local maxW = (InternalRow:GetWide() / #Columns) - 10
						if surface.GetTextSize(Value) > maxW then
							Value = string.sub(Value, 1, math.floor(maxW / surface.GetTextSize("a") * 0.8)) .. "..."
						end
					end
					ValueLabel:SetText(j == 1 and (Value or "N/A") or j == 2 and string.format("%.3fms", (Value or 0) * 1000) or (string.format("%.2f%%", (Value or 0) * 100)))
					ValueLabel:SetFont("GProfiler.Menu.RowText")
					ValueLabel:SizeToContents()
					ValueLabel:SetPos((j - 1) * (InternalRow:GetWide() / #Columns) + 5, fHeight / 2 - ValueLabel:GetTall() / 2 + 8)
					ValueLabel:SetTextColor(MenuColors.White)
					ValueLabel:SetContentAlignment(5)
					ValueLabel:SetMouseInputEnabled(true)

					if j == 2 then
						local duration = (data.Duration or 0) * 1000
						local durationColor = duration > 1000 and Color(255, 0, 0) or (duration > 500 and Color(255, 165, 0) or Color(0, 255, 0))
						InternalRow.PaintColor = durationColor
					end
				end
				InternalPanel:Add(InternalRow)
			end
		else
			local NoProfile = vgui.Create("DLabel", InternalPanel)
			NoProfile:SetText(GProfiler.Language.GetPhrase("profiler_no_profile"))
			NoProfile:SetFont("GProfiler.Menu.RowText")
			NoProfile:SizeToContents()
			NoProfile:SetSize(NoProfile:GetWide() + 10, NoProfile:GetTall() + 20)
			NoProfile:SetContentAlignment(5)
			NoProfile:SetTextColor(Color(255, 255, 255, 200))
			InternalPanel:Add(NoProfile)
			InternalHeaderPanel:SetVisible(false)
		end

		local SourceText = vgui.Create("DTextEntry", SourcePanel)
		SourceText:SetMultiline(true)
		SourceText:SetKeyboardInputEnabled(false)
		SourceText:SetVerticalScrollbarEnabled(true)
		SourceText:SetDrawBackground(false)
		SourceText:SetTextColor(MenuColors.White)
		SourceText:SetFont("GProfiler.Menu.FunctionDetails")
		SourceText:SetText(GProfiler.Language.GetPhrase("requesting_source"))
		SourceText:SizeToContentsY()
		SourceText:SetSize(SourcePanel:GetWide() - 20, SourceText:GetTall() + 6)
		SourceText:SetPos(5, 6)
		SourcePanel:Add(SourceText)

		local RequestedSource = false
		function SourcePanel:OnToggle(expanded)
			if RequestedSource then return end
			RequestedSource = true

			GProfiler.RequestFunctionSource(queryData.Source.File, queryData.Source.Line1, queryData.Source.Line2, function(source)
				if not IsValid(SourceText) then return end
				SourceText:SetText(table.concat(source, "\n"))
				local lines = string.Explode("\n", SourceText:GetText())
				local lineHeight = draw.GetFontHeight("GProfiler.Menu.FunctionDetails")
				SourceText:SetTall(math.min(#lines * lineHeight + 10, 400))
				SourceText:SetSize(SourcePanel:GetWide() - 20, SourceText:GetTall() + 6)
				SourceCollapse:Toggle()
				SourceCollapse:Toggle()
			end)
		end

		return Row
	end

	for id, queryData in ipairs(Data) do
		local Row = CreateRow(List, id, queryData)
		List:AddItem(Row)
	end
end

GProfiler.Menu.RegisterTab("Database", "icon16/database_connect.png", 8, GProfiler.Database.DoTab, function()
	if GProfiler.Database.ProfileActive then
		return GProfiler.TimeRunning(GProfiler.Database.StartTime, 0, GProfiler.Database.ProfileActive) .. "s", MenuColors.ActiveProfile
	elseif GProfiler.Database.Override then
		return GProfiler.Database.Override, MenuColors.InactiveProfile
	end
end)

net.Receive("GProfiler_Database_ServerProfileStatus", function()
	local status = net.ReadBool()
	local ply = net.ReadEntity()
	GProfiler.Database.ProfileActive = status

	if ply == LocalPlayer() then
		GProfiler.Menu.OpenTab("Database", GProfiler.Database.DoTab)
	end
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
		GProfiler.Database.ReceivingData = true
		GProfiler.Database.ProfileData = {}
		GProfiler.Database.Explains = {}
	end

	local count = net.ReadUInt(14)
	for i = 1, count do
		local id = net.ReadUInt(14)
		local typeId = net.ReadUInt(3)
		GProfiler.Database.ProfileData[id] = {
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

		local hasInt = net.ReadBool()
		if hasInt then
			local data = {}
			local internalCount = net.ReadUInt(7)
			for j = 1, internalCount do
				data[j] = {
					Duration = net.ReadFloat(),
					Status = net.ReadString()
				}
			end
			GProfiler.Database.ProfileData[id].InternalData = data
		else
			GProfiler.Database.ProfileData[id].InternalData = false
		end
	end

	count = net.ReadUInt(14)
	for i = 1, count do
		local id = net.ReadUInt(14)
		if net.ReadBool() then
			GProfiler.Database.Explains[id] = {noExplain = true}
		else
			local explainCount = net.ReadUInt(6)
			GProfiler.Database.Explains[id] = {}
			for j = 1, explainCount do
				GProfiler.Database.Explains[id][j] = {
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
		GProfiler.Database.ReceivingData = false
		GProfiler.Menu.OpenTab("Database", GProfiler.Database.DoTab)
	end
end)
