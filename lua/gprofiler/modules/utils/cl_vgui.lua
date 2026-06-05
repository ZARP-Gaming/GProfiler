local PANEL = {}

function PANEL:SortByColumn(ColumnID, Desc)
	table.sort(self.Sorted, function(a, b)
		if Desc then a, b = b, a end
		local aval = a:GetSortValue( ColumnID ) || a:GetColumnText( ColumnID )
		local bval = b:GetSortValue( ColumnID ) || b:GetColumnText( ColumnID )
		if isnumber(aval) and isnumber(bval) then return aval < bval end
		return tostring(aval) < tostring(bval)
	end)

	self:SetDirty(true)
	self:InvalidateLayout()

	self.SortedBy = ColumnID
	self.SortedDescending = Desc
end

derma.DefineControl("GP.ListView", "", PANEL, "DListView")

function GProfiler.Utils.CreateList(Parent, Header, Columns)
	local ResultsList = vgui.Create("GP.ListView", Parent)
	ResultsList:SetSize(Parent:GetWide(), Parent:GetTall() - Header:GetTall())
	ResultsList:SetPos(0, Header:GetTall())
	ResultsList:SetMultiSelect(false)
	for _, col in ipairs(Columns) do
		ResultsList:AddColumn(col)
	end
	ResultsList:SetHeaderHeight(GProfiler.GetScaledSize(30))
	ResultsList:SetDataHeight(GProfiler.GetScaledSize(draw.GetFontHeight("GProfiler.Inter24") + GProfiler.GetScaledSize(10)))
	ResultsList.Paint = nil

	local sbar = ResultsList.VBar
	sbar:SetWide(GProfiler.GetScaledSize(12))
	sbar:SetHideButtons(true)
	sbar.Paint = function(s, w, h)
		GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 10))
	end
	sbar.btnGrip.Paint = function(s, w, h)
		GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 20))
	end

	for k, v in ipairs(ResultsList.Columns) do
		v.Header:SetFont("GProfiler.Inter28")
		v.Header:SetTextColor(color_white)
		local isLast = v == ResultsList.Columns[#ResultsList.Columns]
		v.Header.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(64, 105, 146), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
			if not isLast then
				surface.SetDrawColor(Color(255, 255, 255, 20))
				surface.DrawRect(w - 1, 0, 1, h)
			end

			if s:IsHovered() then
				GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 20), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
			end

			if ResultsList.SortedBy == k then
				draw.SimpleText(ResultsList.SortedDescending and "▼" or "▲", "GProfiler.Inter24", w - GProfiler.GetScaledSize(20), h / 2, Color(255, 255, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	local oldAddLine = ResultsList.AddLine
	ResultsList.AddLine = function(self, ...)
		local line = oldAddLine(self, ...)
		line.Paint = function(s, w, h)
			local isEven = false
			for i, v in ipairs(self.Sorted) do
				if v == line then
					isEven = i % 2 == 0
					break
				end
			end
			GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, isEven and Color(255, 255, 255, 10) or Color(255, 255, 255, 2))

			if s:IsHovered() then
				GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 20))
			end

			if s:IsLineSelected() then
				GProfiler.RNDX.DrawScaled(0, 0, 0, w, h, Color(255, 255, 255, 30))
			end
		end
		for _, col in pairs(line.Columns) do
			col:SetFont("GProfiler.Inter24")
			col:SetTextColor(Color(255, 255, 255, 200))
		end
		local oldSetSize = line.SetSize
		line.SetSize = function(s, w, h)
			oldSetSize(s, w, draw.GetFontHeight("GProfiler.Inter24") + GProfiler.GetScaledSize(12))
		end
		return line
	end

	local sbar = ResultsList.VBar
	sbar:SetWide(GProfiler.GetScaledSize(12))
	sbar:SetHideButtons(true)
	sbar.Paint = function(s, w, h) GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 10)) end
	sbar.btnGrip.Paint = function(s, w, h) GProfiler.RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 255, 255, 20)) end

	return ResultsList
end