GProfiler.JIT = GProfiler.JIT or {}
local JIT = GProfiler.JIT
JIT.Realm = JIT.Realm or "Client"
JIT.View = JIT.View or "Self"

local JITStore = GProfiler.Profilers.GetStore("JIT Profiler")

local VMSTATE_INFO = {
	{ key = "N", label = "Native", color = Color(80, 200, 120), desc = "Running JIT-compiled machine code (fast path)" },
	{ key = "I", label = "Interpreted", color = Color(80, 150, 255), desc = "Running bytecode in the interpreter (not compiled)" },
	{ key = "C", label = "C / Engine", color = Color(230, 200, 60), desc = "Inside C functions and engine calls" },
	{ key = "G", label = "Garbage Collector", color = Color(235, 75, 75), desc = "Collecting garbage - high means allocation pressure" },
	{ key = "J", label = "JIT Compiler", color = Color(200, 110, 230), desc = "Compiling traces - high means trace churn" }
}

local VMSTATE_BY_KEY = {}
for _, info in ipairs(VMSTATE_INFO) do VMSTATE_BY_KEY[info.key] = info end

local function ParseFrames(stack)
	local out = {}
	for _, f in ipairs(string.Explode(";", stack or "")) do
		if f ~= "" then out[#out + 1] = f end
	end
	return out
end

local function FrameParts(frame)
	local name, loc = string.match(frame, "^(.-) @ (.+)$")
	if not name then return nil, frame end
	return name, loc
end

local function LocSource(loc)
	if not loc then return nil end
	local file, line = string.match(loc, "^(.+):(%d+)$")
	return file, tonumber(line)
end

local function SplitSample(key)
	local t1 = string.find(key, "\t", 1, true)
	if not t1 then return "?", nil, key end
	local t2 = string.find(key, "\t", t1 + 1, true)
	if not t2 then return string.sub(key, 1, t1 - 1), nil, string.sub(key, t1 + 1) end
	return string.sub(key, 1, t1 - 1), string.sub(key, t1 + 1, t2 - 1), string.sub(key, t2 + 1)
end

local function Dominant(vm)
	local best, bestc = "?", -1
	for k, c in pairs(vm) do
		if c > bestc then best, bestc = k, c end
	end
	return best
end

local function BuildSelf(map)
	local res = {}
	for key, count in pairs(map) do
		local vm, _, stack = SplitSample(key)
		local leaf = ParseFrames(stack)[1]
		if leaf then
			local r = res[leaf]
			if not r then r = { count = 0, vm = {} } res[leaf] = r end
			r.count = r.count + count
			r.vm[vm] = (r.vm[vm] or 0) + count
		end
	end
	return res
end

local function BuildInclusive(map)
	local res = {}
	for key, count in pairs(map) do
		local vm, _, stack = SplitSample(key)
		local seen = {}
		for _, f in ipairs(ParseFrames(stack)) do
			if not seen[f] then
				seen[f] = true
				local r = res[f]
				if not r then r = { count = 0, vm = {} } res[f] = r end
				r.count = r.count + count
				r.vm[vm] = (r.vm[vm] or 0) + count
			end
		end
	end
	return res
end

local function BuildTree(map)
	local root = { name = "(root)", samples = 0, children = {} }
	for key, count in pairs(map) do
		local _, _, stack = SplitSample(key)
		local frames = ParseFrames(stack)
		local node = root
		root.samples = root.samples + count
		for i = #frames, 1, -1 do
			local f = frames[i]
			local child = node.children[f]
			if not child then
				child = { name = f, samples = 0, children = {} }
				node.children[f] = child
			end
			node = child
			node.samples = node.samples + count
		end
	end
	return root
end

local function BuildByState(map)
	local groups, totals = {}, {}
	for key, count in pairs(map) do
		local vm, _, stack = SplitSample(key)
		local leaf = ParseFrames(stack)[1]
		if leaf then
			groups[vm] = groups[vm] or {}
			groups[vm][leaf] = (groups[vm][leaf] or 0) + count
			totals[vm] = (totals[vm] or 0) + count
		end
	end
	return groups, totals
end

local function DisplayRealm()
	return JIT.Realm == "Both" and "Client" or JIT.Realm
end

local function GetStoreData()
	return JITStore:GetData(DisplayRealm()) or {}
end

local function GetSamplesMap(data)
	if not data.samples then return {} end
	if data.samplesMap then return data.samplesMap end
	if data.samples[1] ~= nil then
		local map = {}
		for _, entry in ipairs(data.samples) do
			map[entry[1]] = (map[entry[1]] or 0) + entry[2]
		end
		data.samplesMap = map
		return map
	end
	return data.samples
end

local function StyleInput(input)
	input.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(18, 46, 74, 255))
		s:DrawTextEntryText(color_white, Color(100, 150, 200), color_white)
	end
end

function GProfiler.JIT.DoTab(Base, Outer)
	local clientOK = JIT.Available == true
	local serverOK = JIT.ServerAvailable == true

	local disabled = {}
	if not clientOK then disabled.Client = true end
	if not serverOK then disabled.Server = true end
	if not (clientOK and serverOK) then disabled.Both = true end

	if disabled[JIT.Realm] then
		JIT.Realm = clientOK and "Client" or (serverOK and "Server" or "Client")
	end

	local function IsActiveRealm()
		if JIT.Realm == "Both" then return JITStore:IsActive("Client") or JITStore:IsActive("Server") end
		return JITStore:IsActive(JIT.Realm)
	end

	local function SendMode()
		if JIT.Realm == "Server" or JIT.Realm == "Both" then
			net.Start("GProfiler_JIT_SetMode")
			net.WriteUInt(math.Clamp(JIT.Interval or 1, 1, 1000), 16)
			net.WriteBool(JIT.Granularity == "f")
			net.SendToServer()
		end
	end

	local Header = GProfiler.Utils.SetupHeader(Outer, "JIT Profiler", "gprofiler/functions.png")
	local StartStop = Header:SetupStartStop(IsActiveRealm())
	local RealmSelector = Header:SetupRealmSelector(JIT.Realm, true, disabled)
	local ModeSelector = Header:SetupModeSelector(function() return JIT.Granularity end, function(v)
		JIT.Granularity = v
		SendMode()
	end, {
		{ value = "l", label = "Line", desc = "Sample the exact source line (most precise)" },
		{ value = "f", label = "Function", desc = "Sample per function (coarser, less overhead)" }
	})
	local Timer = Header:SetupTimer(function()
		return JITStore:GetTimerData(DisplayRealm())
	end)

	local Bar = vgui.Create("DPanel", Outer)
	Bar:SetSize(Outer:GetWide(), GProfiler.GetScaledSize(40))
	Bar:SetPos(0, Header:GetTall())
	Bar.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(22, 50, 80, 200))
	end

	local viewButtons = {}
	local function RefreshResults() end

	local function MakeViewButton(label, x)
		local btn = vgui.Create("DButton", Bar)
		btn:SetSize(GProfiler.GetScaledSize(90), GProfiler.GetScaledSize(26))
		btn:SetPos(x, Bar:GetTall() / 2 - GProfiler.GetScaledSize(26) / 2)
		btn:SetText("")
		btn.Paint = function(s, w, h)
			local active = JIT.View == label
			GProfiler.RNDX.Draw(4, 0, 0, w, h, active and Color(31, 79, 128, 255) or Color(18, 46, 74, 255))
			draw.SimpleText(label, "GProfiler.Inter24", w / 2, h / 2, active and color_white or Color(160, 185, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			JIT.View = label
			RefreshResults()
		end
		viewButtons[#viewButtons + 1] = btn
		return btn
	end

	local vx = GProfiler.GetScaledSize(10)
	MakeViewButton("Self", vx)
	MakeViewButton("Inclusive", vx + GProfiler.GetScaledSize(96))
	MakeViewButton("Call Tree", vx + GProfiler.GetScaledSize(192))
	MakeViewButton("By State", vx + GProfiler.GetScaledSize(288))

	local intLbl = vgui.Create("DLabel", Bar)
	intLbl:SetFont("GProfiler.Inter24")
	intLbl:SetTextColor(color_white)
	intLbl:SetText("Sample every")
	intLbl:SizeToContents()
	intLbl:SetPos(vx + GProfiler.GetScaledSize(400), Bar:GetTall() / 2 - intLbl:GetTall() / 2)

	local intInput = vgui.Create("DTextEntry", Bar)
	intInput:SetSize(GProfiler.GetScaledSize(50), GProfiler.GetScaledSize(26))
	intInput:SetPos(intLbl:GetX() + intLbl:GetWide() + GProfiler.GetScaledSize(6), Bar:GetTall() / 2 - GProfiler.GetScaledSize(26) / 2)
	intInput:SetFont("GProfiler.Inter24")
	intInput:SetText(tostring(JIT.Interval or 1))
	intInput:SetNumeric(true)
	StyleInput(intInput)

	local msLbl = vgui.Create("DLabel", Bar)
	msLbl:SetFont("GProfiler.Inter24")
	msLbl:SetTextColor(color_white)
	msLbl:SetText("ms")
	msLbl:SizeToContents()
	msLbl:SetPos(intInput:GetX() + intInput:GetWide() + GProfiler.GetScaledSize(6), Bar:GetTall() / 2 - msLbl:GetTall() / 2)

	local hintLbl = vgui.Create("DLabel", Bar)
	hintLbl:SetFont("GProfiler.Graph.Small")
	hintLbl:SetTextColor(Color(150, 175, 205))
	hintLbl:SetText("lower = more detail, higher = less overhead")
	hintLbl:SizeToContents()
	hintLbl:SetPos(msLbl:GetX() + msLbl:GetWide() + GProfiler.GetScaledSize(10), Bar:GetTall() / 2 - hintLbl:GetTall() / 2)

	intInput.OnEnter = function()
		JIT.Interval = math.Clamp(tonumber(intInput:GetText()) or 1, 1, 1000)
		intInput:SetText(tostring(JIT.Interval))
		SendMode()
	end

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
		if Running then SendMode() end
		GProfiler.Profilers.Toggle("JIT Profiler", JIT.Realm, Running)
		RefreshResults()
	end

	function RealmSelector:OnStateChanged(state)
		JIT.Realm = state
		StartStop.State = IsActiveRealm()
		StartStop:SetText(StartStop.State and "Stop" or "Start")
		RefreshResults()
	end

	local Split, SourcePanel = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "jit_lr", 0.62)
	local ResultsPanel, StatePanel = GProfiler.Utils.HSplitPanel(Split, GProfiler.GetScaledSize(10), "jit_l_tb", 0.72)

	local headH = GProfiler.GetScaledSize(30)
	local btnH = GProfiler.GetScaledSize(26)

	local SourceHeader = vgui.Create("DLabel", SourcePanel)
	SourceHeader:SetFont("GProfiler.Inter24")
	SourceHeader:SetTextColor(color_white)
	SourceHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	SourceHeader:SetSize(SourcePanel:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	SourceHeader:SetText("Select a row to view source.")

	SourcePanel.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
	end

	local UpBtn = vgui.Create("DButton", SourcePanel)
	UpBtn:SetText("")
	UpBtn:SetVisible(false)
	UpBtn.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, s:IsHovered() and 18 or 8))
		draw.SimpleText("Show more", "GProfiler.Inter24", w / 2, h / 2, Color(170, 195, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local DownBtn = vgui.Create("DButton", SourcePanel)
	DownBtn:SetText("")
	DownBtn:SetVisible(false)
	DownBtn.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, s:IsHovered() and 18 or 8))
		draw.SimpleText("Show more", "GProfiler.Inter24", w / 2, h / 2, Color(170, 195, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local RichText = vgui.Create("RichText", SourcePanel)
	RichText:SetText("")
	RichText:SetVerticalScrollbarEnabled(true)
	function RichText:PerformLayout()
		self:SetFontInternal("GProfiler.Code")
	end

	local cur
	local activeLoc

	local function LayoutSource()
		local w, h = SourcePanel:GetSize()
		SourceHeader:SetSize(w - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
		local top = headH + (UpBtn:IsVisible() and btnH or 0)
		local bottom = DownBtn:IsVisible() and btnH or 0
		UpBtn:SetPos(0, headH)
		UpBtn:SetSize(w, btnH)
		DownBtn:SetPos(0, h - btnH)
		DownBtn:SetSize(w, btnH)
		RichText:SetPos(GProfiler.GetScaledSize(10), top)
		RichText:SetSize(w - GProfiler.GetScaledSize(20), h - top - bottom - GProfiler.GetScaledSize(8))
	end

	local function LoadWindow()
		if not cur then return end
		SourceHeader:SetText(string.format("%s (%d)", cur.file, cur.line))
		RichText:SetText("Loading source...")
		local reqCount = cur.to - cur.from + 1
		GProfiler.RequestFunctionSource(cur.file, cur.from, cur.to, function(src)
			if not IsValid(RichText) then return end
			if not src or #src == 0 then
				RichText:SetText("Failed to load source.")
				return
			end
			cur.to = cur.from + #src - 1
			UpBtn:SetVisible(cur.from > 1)
			DownBtn:SetVisible(#src >= reqCount)
			LayoutSource()
			GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), cur.from, cur.line)
		end)
	end

	UpBtn.DoClick = function()
		if not cur then return end
		cur.from = math.max(cur.from - 15, 1)
		LoadWindow()
	end

	DownBtn.DoClick = function()
		if not cur then return end
		cur.to = cur.to + 15
		LoadWindow()
	end

	SourcePanel.OnHandleMoved = function()
		LayoutSource()
	end

	LayoutSource()

	local function ShowSource(loc)
		activeLoc = loc
		local file, line = LocSource(loc)
		if not file or not line then
			cur = nil
			activeLoc = nil
			UpBtn:SetVisible(false)
			DownBtn:SetVisible(false)
			SourceHeader:SetText("No source for this frame.")
			RichText:SetText("")
			LayoutSource()
			return
		end
		file = string.match(file, "@?(.+)") or file
		cur = { file = file, line = line, from = math.max(line - 5, 1), to = line + 5 }
		LoadWindow()
	end

	StatePanel.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, Color(38, 63, 89, 255), GProfiler.RNDX.NO_TL + GProfiler.RNDX.NO_TR)

		local data = GetStoreData()
		local total = data.total or 0
		local vms = data.vmstates or {}
		local pad = GProfiler.GetScaledSize(12)

		draw.SimpleText("VM State", "GProfiler.Inter28", pad, GProfiler.GetScaledSize(8), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(string.format("%d samples  -  %s mode  -  %dms", total, (data.granularity == "f" and "function" or "line"), data.interval or 1), "GProfiler.Inter24", w - pad, GProfiler.GetScaledSize(12), Color(150, 175, 205), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		local barY = GProfiler.GetScaledSize(38)
		local barH = GProfiler.GetScaledSize(14)
		local barW = w - pad * 2
		if total > 0 then
			local cx = pad
			for _, info in ipairs(VMSTATE_INFO) do
				local segW = ((vms[info.key] or 0) / total) * barW
				if segW > 0 then
					surface.SetDrawColor(info.color)
					surface.DrawRect(cx, barY, segW, barH)
					cx = cx + segW
				end
			end
		end

		local rowY = barY + barH + GProfiler.GetScaledSize(10)
		local rowH = GProfiler.GetScaledSize(22)
		local sw = GProfiler.GetScaledSize(11)
		for _, info in ipairs(VMSTATE_INFO) do
			local count = vms[info.key] or 0
			local c = total > 0 and (count / total) or 0

			surface.SetDrawColor(info.color)
			surface.DrawRect(pad, rowY + rowH / 2 - sw / 2, sw, sw)

			local labelX = pad + sw + GProfiler.GetScaledSize(8)
			surface.SetFont("GProfiler.Inter24")
			local labelW = surface.GetTextSize(info.label)
			draw.SimpleText(info.label, "GProfiler.Inter24", labelX, rowY + rowH / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(info.desc, "GProfiler.Graph.Small", labelX + labelW + GProfiler.GetScaledSize(10), rowY + rowH / 2, Color(150, 175, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("%.1f%%  (%d)", c * 100, count), "GProfiler.Inter24", w - pad, rowY + rowH / 2, info.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			rowY = rowY + rowH
		end
	end

	local Container = vgui.Create("DPanel", ResultsPanel)
	Container.Paint = nil

	ResultsPanel.OnHandleMoved = function()
		Container:SetSize(ResultsPanel:GetWide(), ResultsPanel:GetTall())
		Container:SetPos(0, 0)
		if RefreshResults then RefreshResults() end
	end

	local function BuildList(aggregate, pctLabel)
		Container:Clear()
		local ListHeader = GProfiler.Utils.SetupHeader(Container, "Results", nil, true)
		local List = GProfiler.Utils.CreateList(Container, ListHeader, { "Location", "State", "Samples", pctLabel })

		local data = GetStoreData()
		local total = data.total or 0
		local agg = aggregate(GetSamplesMap(data))

		local rows = {}
		for frame, r in pairs(agg) do rows[#rows + 1] = { frame = frame, count = r.count, dom = Dominant(r.vm) } end
		table.sort(rows, function(a, b) return a.count > b.count end)

		for _, r in ipairs(rows) do
			local name, loc = FrameParts(r.frame)
			local pct = total > 0 and (r.count / total * 100) or 0
			local info = VMSTATE_BY_KEY[r.dom]
			local row = List:AddLine(name and (name .. "  " .. loc) or loc, info and info.label or r.dom, r.count, string.format("%.1f%%", pct))
			row.Loc = loc
			row:SetSortValue(3, r.count)
			row:SetSortValue(4, pct)
		end
		List:SortByColumn(3, true)

		function List:OnRowSelected(idx, row)
			ShowSource(row.Loc)
		end

		Container.OnHandleMoved = function()
			ListHeader:SetWide(Container:GetWide())
			List:SetSize(Container:GetWide(), Container:GetTall() - ListHeader:GetTall())
			List:SetPos(0, ListHeader:GetTall())
		end
	end

	local function RenderNodeTree(roots, title)
		Container:Clear()
		local TreeHeader = GProfiler.Utils.SetupHeader(Container, title, nil, true)
		local Scroll = vgui.Create("DScrollPanel", Container)
		Scroll:SetPos(0, TreeHeader:GetTall())
		Scroll:SetSize(Container:GetWide(), Container:GetTall() - TreeHeader:GetTall())

		local lineHeight = GProfiler.GetScaledSize(22)
		local indentSize = GProfiler.GetScaledSize(16)
		local iconSize = GProfiler.GetScaledSize(10)

		local Canvas = vgui.Create("DPanel", Scroll)
		Canvas:Dock(TOP)
		Canvas:SetTall(0)

		Canvas.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, GProfiler.SyntaxColors.background)
			local mouseX, mouseY = s:LocalCursorPos()
			local clicked = s.MousePressed

			local function draw_nodes(list, y)
				for _, node in ipairs(list) do
					local rowY = y
					surface.SetDrawColor(31, 79, 128, 70)
					surface.DrawRect(0, rowY, w * math.Clamp(node.pct, 0, 1), lineHeight)
					if node.loc and node.loc == activeLoc then
						surface.SetDrawColor(255, 214, 90, 30)
						surface.DrawRect(0, rowY, w, lineHeight)
					end
					surface.SetDrawColor(GProfiler.SyntaxColors.lineSep)
					surface.DrawRect(0, rowY + lineHeight - 1, w, 1)

					local ex = GProfiler.GetScaledSize(6) + node.depth * indentSize
					if #node.Children > 0 then
						surface.SetDrawColor(GProfiler.SyntaxColors.lineNumber)
						draw.NoTexture()
						local ey = rowY + (lineHeight - iconSize) / 2
						if node.Expanded then
							surface.DrawPoly({ { x = ex, y = ey + iconSize / 4 }, { x = ex + iconSize / 2, y = ey + iconSize / 4 }, { x = ex + iconSize / 4, y = ey + iconSize * 3 / 4 } })
						else
							surface.DrawPoly({ { x = ex, y = ey + iconSize / 4 }, { x = ex + iconSize / 2, y = ey + iconSize / 2 }, { x = ex, y = ey + iconSize * 3 / 4 } })
						end
					end

					if clicked and mouseY >= rowY and mouseY < rowY + lineHeight then
						if #node.Children > 0 and mouseX >= ex - 4 and mouseX <= ex + iconSize + 4 then
							node.Expanded = not node.Expanded
							s:InvalidateLayout()
						else
							ShowSource(node.loc)
						end
					end

					surface.SetFont("GProfiler.Code")
					local textY = rowY + (lineHeight - select(2, surface.GetTextSize("A"))) / 2 - 1
					local nameX = ex + iconSize + GProfiler.GetScaledSize(4)
					local pctStr = string.format("%.1f%%", node.pct * 100)
					local cntStr = tostring(node.samples)
					local rightX = w - GProfiler.GetScaledSize(8)

					surface.SetTextColor(GProfiler.SyntaxColors.number)
					local cw = surface.GetTextSize(cntStr)
					surface.SetTextPos(rightX - cw, textY)
					surface.DrawText(cntStr)
					rightX = rightX - cw - GProfiler.GetScaledSize(10)

					surface.SetTextColor(GProfiler.SyntaxColors.string)
					local pw = surface.GetTextSize(pctStr)
					surface.SetTextPos(rightX - pw, textY)
					surface.DrawText(pctStr)

					if node.name then
						surface.SetTextColor(GProfiler.SyntaxColors.funcCall)
						surface.SetTextPos(nameX, textY)
						surface.DrawText(node.name)
						surface.SetTextColor(GProfiler.SyntaxColors.lineNumber)
						surface.SetTextPos(nameX + surface.GetTextSize(node.name) + GProfiler.GetScaledSize(8), textY)
						surface.DrawText(node.loc or "")
					else
						surface.SetTextColor(node.color or GProfiler.SyntaxColors.funcCall)
						surface.SetTextPos(nameX, textY)
						surface.DrawText(node.label)
					end

					y = y + lineHeight
					if node.Expanded and #node.Children > 0 then
						y = draw_nodes(node.Children, y)
					end
				end
				return y
			end

			draw_nodes(roots, 0)
			s.MousePressed = false
		end

		Canvas.PerformLayout = function(s)
			local function calc(list)
				local total = 0
				for _, node in ipairs(list) do
					total = total + lineHeight
					if node.Expanded and #node.Children > 0 then total = total + calc(node.Children) end
				end
				return total
			end
			s:SetTall(math.max(calc(roots) + GProfiler.GetScaledSize(10), Scroll:GetTall()))
		end

		Canvas.OnMousePressed = function(s, code)
			if code == MOUSE_LEFT then s.MousePressed = true end
		end
		Canvas:InvalidateLayout()

		Container.OnHandleMoved = function()
			TreeHeader:SetWide(Container:GetWide())
			Scroll:SetSize(Container:GetWide(), Container:GetTall() - TreeHeader:GetTall())
		end
	end

	local function BuildTreeView()
		local data = GetStoreData()
		local tree = BuildTree(GetSamplesMap(data))

		local function Convert(node, depth, parentSamples)
			local nodes = {}
			for _, child in pairs(node.children) do
				local pct = parentSamples > 0 and child.samples / parentSamples or 0
				local nm, loc = FrameParts(child.name)
				nodes[#nodes + 1] = {
					label = nm and (nm .. "  " .. loc) or child.name,
					name = nm,
					loc = loc or child.name,
					samples = child.samples,
					pct = pct,
					depth = depth,
					Expanded = false,
					Children = Convert(child, depth + 1, child.samples)
				}
			end
			table.sort(nodes, function(a, b) return a.samples > b.samples end)
			return nodes
		end

		local roots = Convert(tree, 0, tree.samples)
		for _, n in ipairs(roots) do n.Expanded = #n.Children > 0 end
		RenderNodeTree(roots, "Call Tree")
	end

	local function BuildByStateView()
		local data = GetStoreData()
		local grandTotal = data.total or 0
		local groups, totals = BuildByState(GetSamplesMap(data))

		local roots = {}
		for _, info in ipairs(VMSTATE_INFO) do
			local g = groups[info.key]
			if g then
				local stateTotal = totals[info.key] or 0
				local children = {}
				for leaf, count in pairs(g) do
					local nm, loc = FrameParts(leaf)
					children[#children + 1] = {
						label = nm and (nm .. "  " .. loc) or leaf,
						name = nm,
						loc = loc or leaf,
						samples = count,
						pct = stateTotal > 0 and count / stateTotal or 0,
						depth = 1,
						Expanded = false,
						Children = {}
					}
				end
				table.sort(children, function(a, b) return a.samples > b.samples end)
				roots[#roots + 1] = {
					label = string.format("%s  -  %d samples (%.1f%%)", info.label, stateTotal, grandTotal > 0 and stateTotal / grandTotal * 100 or 0),
					loc = nil,
					samples = stateTotal,
					pct = grandTotal > 0 and stateTotal / grandTotal or 0,
					depth = 0,
					Expanded = true,
					Children = children,
					color = info.color
				}
			end
		end

		RenderNodeTree(roots, "By VM State")
	end

	RefreshResults = function()
		if not IsValid(Container) then return end
		Container:SetSize(ResultsPanel:GetWide(), ResultsPanel:GetTall())
		Container:SetPos(0, 0)
		if not (clientOK or serverOK) then
			Container:Clear()
			local msg = vgui.Create("DPanel", Container)
			msg:Dock(FILL)
			msg.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(38, 63, 89, 255))
				draw.SimpleText("gprofiler binary module not installed (x86-64 only).", "GProfiler.Inter28", w / 2, h / 2, Color(200, 120, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			return
		end
		if JIT.View == "Self" then
			BuildList(BuildSelf, "Self %")
		elseif JIT.View == "Inclusive" then
			BuildList(BuildInclusive, "Total %")
		elseif JIT.View == "By State" then
			BuildByStateView()
		else
			BuildTreeView()
		end
	end

	JIT.RefreshUI = RefreshResults
	timer.Simple(0, RefreshResults)
end

GProfiler.Menu.RegisterTab("JIT Profiler", "gprofiler/functions.png", 9, GProfiler.JIT.DoTab, function()
	local timer = JITStore:GetTimerData(JIT.Realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

local function RequestServerAvailability()
	net.Start("GProfiler_JIT_Availability")
	net.SendToServer()
end

net.Receive("GProfiler_JIT_Availability", function()
	JIT.ServerAvailable = net.ReadBool()
	if JIT.RefreshUI then JIT.RefreshUI() end
end)

hook.Add("GProfiler.Loaded", "GProfiler.JIT.RequestAvailability", function()
	timer.Simple(1, RequestServerAvailability)
end)

net.Receive("GProfiler_JIT_SendData", function()
	local first = net.ReadBool()
	local last = net.ReadBool()

	local pending = JIT._pending or { samples = {}, total = 0, vmstates = {} }
	if first then
		pending = { samples = {}, total = 0, vmstates = {} }
		pending.total = net.ReadUInt(32)
		pending.granularity = net.ReadString()
		pending.interval = net.ReadUInt(16)
		pending.vmstates = {
			I = 0, N = 0, C = 0, G = 0, J = 0
		}
		pending.vmstates.I = net.ReadUInt(32)
		pending.vmstates.N = net.ReadUInt(32)
		pending.vmstates.C = net.ReadUInt(32)
		pending.vmstates.G = net.ReadUInt(32)
		pending.vmstates.J = net.ReadUInt(32)
	end

	local count = net.ReadUInt(24)
	for i = 1, count do
		local stack = net.ReadString()
		local c = net.ReadUInt(24)
		pending.samples[stack] = (pending.samples[stack] or 0) + c
	end

	JIT._pending = pending

	if last then
		pending._isMap = true
		JITStore:SetData("Server", pending)
		JIT._pending = nil
		if JIT.RefreshUI then JIT.RefreshUI() end
	end
end)

if express then
	express.Receive("GProfiler_JIT_SendData", function(data)
		JITStore:SetData("Server", {
			samples = data.samples,
			total = data.total,
			vmstates = data.vmstates,
			granularity = data.granularity,
			interval = data.interval
		})
		if JIT.RefreshUI then JIT.RefreshUI() end
	end)
end
