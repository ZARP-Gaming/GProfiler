GProfiler.FileIO = GProfiler.FileIO or {}
local FileIO = GProfiler.FileIO
FileIO.Realm = FileIO.Realm or "Client"
FileIO.View = FileIO.View or "Operations"

local FileIOStore = GProfiler.Profilers.GetStore("File I/O")

local function FormatBytes(n)
	n = n or 0
	if n < 1024 then return math.Round(n) .. " B" end
	local kb = n / 1024
	if kb < 1024 then return math.Round(kb, 2) .. " KB" end
	local mb = kb / 1024
	if mb < 1024 then return math.Round(mb, 2) .. " MB" end
	return math.Round(mb / 1024, 2) .. " GB"
end

local function FormatMs(s)
	return string.format("%.3f", (s or 0) * 1000)
end

local function DisplayRealm()
	return FileIO.Realm == "Both" and "Client" or FileIO.Realm
end

local function GetData()
	return FileIOStore:GetData(DisplayRealm()) or {}
end

function GProfiler.FileIO.DoTab(Base, Outer)
	local function IsActiveRealm()
		if FileIO.Realm == "Both" then return FileIOStore:IsActive("Client") or FileIOStore:IsActive("Server") end
		return FileIOStore:IsActive(FileIO.Realm)
	end

	local Header = GProfiler.Utils.SetupHeader(Outer, "File I/O", "gprofiler/fileio.png")
	local StartStop = Header:SetupStartStop(IsActiveRealm())
	local RealmSelector = Header:SetupRealmSelector(FileIO.Realm, true)
	local Timer = Header:SetupTimer(function()
		return FileIOStore:GetTimerData(DisplayRealm())
	end)

	local Bar = vgui.Create("DPanel", Outer)
	Bar:SetSize(Outer:GetWide(), GProfiler.GetScaledSize(46))
	Bar:SetPos(0, Header:GetTall())
	Bar.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(22, 50, 80, 200))
	end

	local viewCounts = {}
	local viewButtons = {}
	local LayoutButtons
	local function RefreshResults() end

	local function MakeViewButton(label)
		local btn = vgui.Create("DButton", Bar)
		btn.Label = label
		btn:SetTall(GProfiler.GetScaledSize(28))
		btn:SetText("")
		btn.Paint = function(s, w, h)
			local active = FileIO.View == label
			GProfiler.RNDX.Draw(4, 0, 0, w, h, active and Color(31, 79, 128, 255) or Color(18, 46, 74, 255))
			GProfiler.RNDX.DrawOutlined(4, 0, 0, w, h, Color(255, 255, 255, 1), 1)
			draw.SimpleText(string.format("%s (%d)", label, viewCounts[label] or 0), "GProfiler.Inter24", w / 2, h / 2, active and color_white or Color(160, 185, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			FileIO.View = label
			RefreshResults()
		end
		viewButtons[#viewButtons + 1] = btn
		return btn
	end

	local vx = GProfiler.GetScaledSize(10)
	MakeViewButton("Operations")
	MakeViewButton("Files")
	MakeViewButton("Callers")
	MakeViewButton("Handles")

	LayoutButtons = function()
		surface.SetFont("GProfiler.Inter24")
		local btnH = GProfiler.GetScaledSize(28)
		local x = vx
		for _, b in ipairs(viewButtons) do
			local tw = surface.GetTextSize(string.format("%s (%d)", b.Label, viewCounts[b.Label] or 0))
			local bw = tw + GProfiler.GetScaledSize(24)
			b:SetSize(bw, btnH)
			b:SetPos(x, Bar:GetTall() / 2 - btnH / 2)
			x = x + bw + GProfiler.GetScaledSize(8)
		end
	end
	LayoutButtons()

	local contentY = Header:GetTall() + Bar:GetTall() + GProfiler.GetScaledSize(12)
	Base:SetPos(GProfiler.GetScaledSize(10), contentY)
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - contentY - GProfiler.GetScaledSize(12))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Bar:SetSize(Outer:GetWide(), Bar:GetTall())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - contentY - GProfiler.GetScaledSize(12))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		GProfiler.Profilers.Toggle("File I/O", FileIO.Realm, Running)
		RefreshResults()
	end

	function RealmSelector:OnStateChanged(state)
		FileIO.Realm = state
		StartStop.State = IsActiveRealm()
		StartStop:SetText(StartStop.State and "Stop" or "Start")
		if state == "Server" or state == "Both" then
			GProfiler.Profilers.RequestData("File I/O")
		end
		RefreshResults()
	end

	local ResultsPanel, DetailPanel = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "fileio_lr", 0.6)
	local BreakdownWrap, SourceWrap = GProfiler.Utils.HSplitPanel(DetailPanel, GProfiler.GetScaledSize(10), "fileio_detail", 0.45)

	local SourceHeader = vgui.Create("DLabel", SourceWrap)
	SourceHeader:SetFont("GProfiler.Inter24")
	SourceHeader:SetTextColor(GProfiler.SyntaxColors.comment)
	SourceHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	SourceHeader:SetSize(SourceWrap:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	SourceHeader:SetText("Select a row for details.")

	SourceWrap.Paint = function(s, w, h)
		GProfiler.RNDX.DrawScaled(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)
	end

	local RichText = vgui.Create("RichText", SourceWrap)
	RichText:SetText("")
	RichText:SetVerticalScrollbarEnabled(true)
	function RichText:PerformLayout()
		self:SetFontInternal("GProfiler.Code")
	end

	local function LayoutSource()
		SourceHeader:SetSize(SourceWrap:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
		RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(30))
		RichText:SetSize(SourceWrap:GetWide() - GProfiler.GetScaledSize(20), SourceWrap:GetTall() - GProfiler.GetScaledSize(38))
		RichText:InvalidateLayout()
	end
	SourceWrap.OnHandleMoved = LayoutSource
	LayoutSource()

	local function ShowText(title, lines)
		SourceHeader:SetText(title)
		RichText:SetText(table.concat(lines, "\n"))
	end

	local function ShowSource(src, line)
		if not src or src == "" or src == "[C]" then
			SourceHeader:SetText("No source available.")
			RichText:SetText("")
			return
		end
		local file = string.match(src, "@?(.+)") or src
		local from = math.max(line - 5, 1)
		local to = line + 5
		SourceHeader:SetText(string.format("%s (%d)", file, line))
		RichText:SetText("Loading source...")
		GProfiler.RequestFunctionSource(file, from, to, function(s)
			if not IsValid(RichText) then return end
			if not s or #s == 0 then RichText:SetText("Failed to load source.") return end
			GProfiler.SyntaxHighlight(RichText, table.concat(s, ""), from, line)
		end)
	end

	local BreakdownContainer = vgui.Create("DPanel", BreakdownWrap)
	BreakdownContainer.Paint = nil
	local lastBreakdown

	local function ShowBreakdownEmpty(msg)
		lastBreakdown = function() ShowBreakdownEmpty(msg) end
		BreakdownContainer:SetSize(BreakdownWrap:GetWide(), BreakdownWrap:GetTall())
		BreakdownContainer:SetPos(0, 0)
		BreakdownContainer:Clear()
		local p = vgui.Create("DPanel", BreakdownContainer)
		p:Dock(FILL)
		p.Paint = function(s, w, h)
			GProfiler.RNDX.DrawScaled(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)
			draw.SimpleText(msg or "", "GProfiler.Inter24", GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(16), GProfiler.SyntaxColors.comment, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	local function ShowBreakdown(title, columns, fill)
		lastBreakdown = function() ShowBreakdown(title, columns, fill) end
		BreakdownContainer:SetSize(BreakdownWrap:GetWide(), BreakdownWrap:GetTall())
		BreakdownContainer:SetPos(0, 0)
		BreakdownContainer:Clear()
		local ListHeader = GProfiler.Utils.SetupHeader(BreakdownContainer, title, nil, true)
		local List = GProfiler.Utils.CreateList(BreakdownContainer, ListHeader, columns)
		fill(List)
		BreakdownContainer.OnHandleMoved = function()
			ListHeader:SetWide(BreakdownContainer:GetWide())
			List:SetSize(BreakdownContainer:GetWide(), BreakdownContainer:GetTall() - ListHeader:GetTall())
			List:SetPos(0, ListHeader:GetTall())
		end
	end

	BreakdownWrap.OnHandleMoved = function()
		if lastBreakdown then lastBreakdown() end
	end
	ShowBreakdownEmpty("Select a row for a breakdown.")

	local Container = vgui.Create("DPanel", ResultsPanel)
	Container.Paint = nil

	ResultsPanel.OnHandleMoved = function()
		Container:SetSize(ResultsPanel:GetWide(), ResultsPanel:GetTall())
		Container:SetPos(0, 0)
		if RefreshResults then RefreshResults() end
	end

	local function BuildList(columns, fill)
		Container:Clear()
		local ListHeader = GProfiler.Utils.SetupHeader(Container, "Results", nil, true)
		local List = GProfiler.Utils.CreateList(Container, ListHeader, columns)

		fill(List)

		Container.OnHandleMoved = function()
			ListHeader:SetWide(Container:GetWide())
			List:SetSize(Container:GetWide(), Container:GetTall() - ListHeader:GetTall())
			List:SetPos(0, ListHeader:GetTall())
		end

		return List
	end

	local function BuildOperations()
		local data = GetData()
		local List = BuildList({ "Operation", "Count", "Bytes", "Total (ms)", "Avg (ms)", "Longest (ms)" }, function(List)
			for name, o in pairs(data.Ops or {}) do
				local avg = o.Count > 0 and o.Time / o.Count or 0
				local row = List:AddLine(name, o.Count, FormatBytes(o.Bytes), FormatMs(o.Time), FormatMs(avg), FormatMs(o.Max))
				row.OpData = { name = name, o = o }
				row:SetSortValue(2, o.Count)
				row:SetSortValue(3, o.Bytes)
				row:SetSortValue(4, o.Time)
				row:SetSortValue(5, avg)
				row:SetSortValue(6, o.Max)
			end
			List:SortByColumn(4, true)
		end)

		function List:OnRowSelected(idx, row)
			local d = row.OpData
			if not d then return end
			SourceHeader:SetText("Select a parameter to view its source.")
			RichText:SetText("")

			local params = d.o.Params or {}
			if table.Count(params) == 0 then
				ShowBreakdownEmpty("No parameters recorded for this operation.")
			else
				ShowBreakdown("Parameters used", { "Parameter", "Count", "Total (ms)", "Bytes" }, function(BList)
					for sig, p in pairs(params) do
						local r = BList:AddLine(sig, p.Count, FormatMs(p.Time), FormatBytes(p.Bytes))
						r.ParamData = p
						r:SetSortValue(2, p.Count)
						r:SetSortValue(3, p.Time)
						r:SetSortValue(4, p.Bytes)
					end
					BList:SortByColumn(2, true)
					function BList:OnRowSelected(i, brow)
						local p = brow.ParamData
						if p then ShowSource(p.Src, p.Line) end
					end
				end)
			end
		end
	end

	local function BuildFiles()
		local data = GetData()
		local List = BuildList({ "File", "Reads", "Writes", "Read", "Written", "Total (ms)" }, function(List)
			for path, f in pairs(data.Files or {}) do
				local row = List:AddLine(path, f.Reads, f.Writes, FormatBytes(f.ReadBytes), FormatBytes(f.WriteBytes), FormatMs(f.Time))
				row.FileData = { path = path, f = f }
				row:SetSortValue(2, f.Reads)
				row:SetSortValue(3, f.Writes)
				row:SetSortValue(4, f.ReadBytes)
				row:SetSortValue(5, f.WriteBytes)
				row:SetSortValue(6, f.Time)
			end
			List:SortByColumn(6, true)
		end)

		function List:OnRowSelected(idx, row)
			local d = row.FileData
			if not d then return end
			SourceHeader:SetText("Select a location to view its source.")
			RichText:SetText("")

			local callers = d.f.Callers or {}
			if table.Count(callers) == 0 then
				ShowBreakdownEmpty("No call locations recorded for this file.")
			else
				ShowBreakdown("Accessed from", { "Location", "Count", "Total (ms)", "Bytes" }, function(BList)
					for _, c in pairs(callers) do
						local r = BList:AddLine(c.Src .. ":" .. c.Line, c.Count, FormatMs(c.Time), FormatBytes(c.Bytes))
						r.CallerData = c
						r:SetSortValue(2, c.Count)
						r:SetSortValue(3, c.Time)
						r:SetSortValue(4, c.Bytes)
					end
					BList:SortByColumn(3, true)
					function BList:OnRowSelected(i, brow)
						local c = brow.CallerData
						if c then ShowSource(c.Src, c.Line) end
					end
				end)
			end
		end
	end

	local function BuildCallers()
		local data = GetData()
		local List = BuildList({ "Location", "Calls", "Bytes", "Total (ms)" }, function(List)
			for _, c in pairs(data.Callers or {}) do
				local row = List:AddLine(c.Src .. ":" .. c.Line, c.Count, FormatBytes(c.Bytes), FormatMs(c.Time))
				row.CallerData = c
				row:SetSortValue(2, c.Count)
				row:SetSortValue(3, c.Bytes)
				row:SetSortValue(4, c.Time)
			end
			List:SortByColumn(4, true)
		end)

		function List:OnRowSelected(idx, row)
			local c = row.CallerData
			if not c then return end
			ShowSource(c.Src, c.Line)
		end
	end

	local function BuildHandles()
		local data = GetData()
		local List = BuildList({ "File", "Mode", "Duration (ms)", "Read", "Written", "Ops", "Status" }, function(List)
			for _, h in ipairs(data.Handles or {}) do
				local row = List:AddLine(h.Path, h.Mode, FormatMs(h.Duration), FormatBytes(h.ReadBytes), FormatBytes(h.WriteBytes), h.Ops, h.Leaked and "LEAKED" or "Closed")
				row.HandleData = h
				row:SetSortValue(3, h.Duration)
				row:SetSortValue(4, h.ReadBytes)
				row:SetSortValue(5, h.WriteBytes)
				row:SetSortValue(6, h.Ops)
				row:SetSortValue(7, h.Leaked and 1 or 0)
				if h.Leaked then
					row.Columns[7]:SetTextColor(Color(235, 75, 75))
				end
			end
			List:SortByColumn(3, true)
		end)

		function List:OnRowSelected(idx, row)
			local h = row.HandleData
			if not h then return end

			if h.OpenSrc and h.OpenSrc ~= "" then
				ShowSource(h.OpenSrc, h.OpenLine)
			else
				ShowText(h.Path, {
					"Mode: " .. h.Mode,
					"Status: " .. (h.Leaked and "LEAKED (never closed)" or "Closed"),
					"Lifetime: " .. FormatMs(h.Duration) .. " ms"
				})
			end

			local seq = h.Sequence or {}
			if #seq == 0 then
				ShowBreakdownEmpty("No operations recorded on this handle.")
			else
				ShowBreakdown(string.format("Operation sequence (%d ops)", h.Ops - 1), { "#", "Operation", "Time (ms)", "Bytes" }, function(BList)
					for i, s in ipairs(seq) do
						local r = BList:AddLine(i, s.Label, FormatMs(s.Time), s.Bytes > 0 and FormatBytes(s.Bytes) or "")
						r:SetSortValue(1, i)
					end
					if (h.SeqTruncated or 0) > 0 then
						local tr = BList:AddLine("", string.format("... %d more (truncated)", h.SeqTruncated), "", "")
						tr:SetSortValue(1, #seq + 1)
					end
					BList:SortByColumn(1, false)
				end)
			end
		end
	end

	RefreshResults = function()
		if not IsValid(Container) then return end
		Container:SetSize(ResultsPanel:GetWide(), ResultsPanel:GetTall())
		Container:SetPos(0, 0)

		local data = GetData()
		viewCounts.Operations = table.Count(data.Ops or {})
		viewCounts.Files = table.Count(data.Files or {})
		viewCounts.Callers = table.Count(data.Callers or {})
		viewCounts.Handles = #(data.Handles or {})
		if LayoutButtons then LayoutButtons() end

		ShowBreakdownEmpty(FileIO.View == "Callers" and "" or "Select a row for a breakdown.")
		SourceHeader:SetText("Select a row for details.")
		RichText:SetText("")

		if FileIO.View == "Operations" then
			BuildOperations()
		elseif FileIO.View == "Files" then
			BuildFiles()
		elseif FileIO.View == "Callers" then
			BuildCallers()
		else
			BuildHandles()
		end
	end

	FileIO.RefreshUI = RefreshResults
	timer.Simple(0, RefreshResults)

	if FileIO.Realm == "Server" or FileIO.Realm == "Both" then
		GProfiler.Profilers.RequestData("File I/O")
	end
end

GProfiler.Menu.RegisterTab("File I/O", "gprofiler/fileio.png", 9, GProfiler.FileIO.DoTab, function()
	local timer = FileIOStore:GetTimerData(FileIO.Realm == "Both" and "Client" or FileIO.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

local recvBuffer = ""
net.Receive("GProfiler_FileIO_SendData", function()
	local first = net.ReadBool()
	local last = net.ReadBool()
	local len = net.ReadUInt(16)
	local chunk = len > 0 and net.ReadData(len) or ""

	if first then recvBuffer = "" end
	recvBuffer = recvBuffer .. chunk
	if not last then return end

	local json = util.Decompress(recvBuffer)
	recvBuffer = ""
	if not json then return end

	local data = util.JSONToTable(json)
	if not data then return end

	data.Ops = data.Ops or {}
	data.Files = data.Files or {}
	data.Callers = data.Callers or {}
	data.Handles = data.Handles or {}

	FileIOStore:SetData("Server", data)
	if FileIO.RefreshUI then FileIO.RefreshUI() end
end)
