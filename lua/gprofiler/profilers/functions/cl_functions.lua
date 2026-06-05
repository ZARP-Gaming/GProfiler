GProfiler.Functions = GProfiler.Functions or {}
local Functions = GProfiler.Functions
Functions.Realm = Functions.Realm or "Client"
Functions.ActiveFocus = Functions.ActiveFocus or {}
Functions.SourceFilter = Functions.SourceFilter or ""
Functions.CGServerCache = Functions.CGServerCache or {}

local FunctionsStore = GProfiler.Profilers.GetStore("Functions")

local function GetFocus()
	local realm = Functions.Realm == "Both" and "Client" or Functions.Realm
	Functions.ActiveFocus[realm] = Functions.ActiveFocus[realm] or {}
	return Functions.ActiveFocus[realm]
end

local function ValidateFocus(foc)
	return string.StartWith(foc or "", "function: 0x") or string.StartWith(foc or "", "0x")
end

local function SendFocus()
	if Functions.Realm == "Server" or Functions.Realm == "Both" then
		local focus = GetFocus()
		net.Start("GProfiler_Functions_SetFocus")
		if not table.IsEmpty(focus) then
			net.WriteBool(true)
			net.WriteUInt(#focus, 5)
			for _, v in ipairs(focus) do
				net.WriteString(v)
			end
		else
			net.WriteBool(false)
		end
		net.SendToServer()
	end
end

local function StyleInput(input)
	input.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(18, 46, 74, 255))
		s:DrawTextEntryText(color_white, Color(100, 150, 200), color_white)
	end
end

function GProfiler.Functions.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Functions", "gprofiler/functions.png")
	local initialActive = Functions.Realm == "Both" and (FunctionsStore:IsActive("Client") or FunctionsStore:IsActive("Server")) or FunctionsStore:IsActive(Functions.Realm)
	local StartStop = Header:SetupStartStop(initialActive)
	local RealmSelector = Header:SetupRealmSelector(Functions.Realm, true)
	local Timer = Header:SetupTimer(function()
		local realm = Functions.Realm == "Both" and "Client" or Functions.Realm
		return FunctionsStore:GetTimerData(realm)
	end)

	local ReceivingLabel = vgui.Create("DLabel", Header)
	ReceivingLabel:SetFont("GProfiler.Inter24")
	ReceivingLabel:SetTextColor(Color(225, 66, 66))
	ReceivingLabel:SetText("Receiving data...")
	ReceivingLabel:SizeToContents()
	ReceivingLabel:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() / 2 - ReceivingLabel:GetTall() / 2)
	ReceivingLabel:SetVisible(false)
	function ReceivingLabel:Think()
		self:SetVisible(Functions.ReceivingData == true)
	end

	local FocusBar = vgui.Create("DPanel", Outer)
	FocusBar:SetSize(Outer:GetWide(), GProfiler.GetScaledSize(40))
	FocusBar:SetPos(0, Header:GetTall())
	FocusBar.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(22, 50, 80, 200))
	end

	local focusLbl = vgui.Create("DLabel", FocusBar)
	focusLbl:SetFont("GProfiler.Inter24")
	focusLbl:SetTextColor(color_white)
	focusLbl:SetText("Focus:")
	focusLbl:SizeToContents()
	focusLbl:SetPos(GProfiler.GetScaledSize(10), FocusBar:GetTall() / 2 - focusLbl:GetTall() / 2)

	local indicatorSize = GProfiler.GetScaledSize(8)
	local validIndicator = vgui.Create("DPanel", FocusBar)
	validIndicator:SetSize(indicatorSize, GProfiler.GetScaledSize(20))
	validIndicator:SetPos(focusLbl:GetX() + focusLbl:GetWide() + GProfiler.GetScaledSize(6), FocusBar:GetTall() / 2 - GProfiler.GetScaledSize(20) / 2)

	local isValidInput = false
	validIndicator.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, isValidInput and Color(0, 200, 80) or Color(200, 60, 60))
	end

	local focusInput = vgui.Create("DTextEntry", FocusBar)
	focusInput:SetSize(GProfiler.GetScaledSize(180), GProfiler.GetScaledSize(26))
	focusInput:SetPos(validIndicator:GetX() + validIndicator:GetWide() + GProfiler.GetScaledSize(6), FocusBar:GetTall() / 2 - GProfiler.GetScaledSize(26) / 2)
	focusInput:SetFont("GProfiler.Inter24")
	focusInput:SetPlaceholderText("function: 0x... or 0x...")
	StyleInput(focusInput)
	focusInput.OnTextChanged = function()
		isValidInput = ValidateFocus(focusInput:GetText())
	end

	local FocusList = vgui.Create("DIconLayout", FocusBar)
	FocusList:SetSpaceX(GProfiler.GetScaledSize(5))
	FocusList:SetPos(focusInput:GetX() + focusInput:GetWide() + GProfiler.GetScaledSize(10), FocusBar:GetTall() / 2 - GProfiler.GetScaledSize(26) / 2)
	FocusList:SetSize(FocusBar:GetWide() - focusInput:GetX() - focusInput:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(26))
	FocusList.Paint = nil

	local function RebuildFocusChips()
		FocusList:Clear()
		for _, focusVal in ipairs(GetFocus()) do
			local chip = FocusList:Add("DPanel")
			chip:SetTall(GProfiler.GetScaledSize(26))
			chip.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(31, 79, 128, 255))
			end

			local hexDisplay = string.match(focusVal, "0x%x+") or focusVal
			local chiplbl = vgui.Create("DLabel", chip)
			chiplbl:SetFont("GProfiler.Inter24")
			chiplbl:SetText(hexDisplay)
			chiplbl:SetTextColor(color_white)
			chiplbl:SizeToContents()
			chiplbl:SetPos(GProfiler.GetScaledSize(6), chip:GetTall() / 2 - chiplbl:GetTall() / 2)

			local removeBtn = vgui.Create("DButton", chip)
			removeBtn:SetSize(GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(20))
			removeBtn:SetPos(chiplbl:GetX() + chiplbl:GetWide() + GProfiler.GetScaledSize(4), chip:GetTall() / 2 - GProfiler.GetScaledSize(20) / 2)
			removeBtn:SetText("")
			removeBtn.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(80, 30, 30, s:IsHovered() and 200 or 150))
				draw.SimpleText("x", "GProfiler.Inter24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			removeBtn.DoClick = function()
				table.RemoveByValue(GetFocus(), focusVal)
				RebuildFocusChips()
			end

			chip:SetWide(chiplbl:GetX() + chiplbl:GetWide() + removeBtn:GetWide() + GProfiler.GetScaledSize(10))
		end
		FocusList:InvalidateLayout()
	end
	RebuildFocusChips()

	focusInput.OnEnter = function()
		local txt = focusInput:GetText()
		if not ValidateFocus(txt) then return end
		if not string.StartWith(txt, "function: ") then txt = "function: " .. txt end
		if not table.HasValue(GetFocus(), txt) then
			table.insert(GetFocus(), txt)
			RebuildFocusChips()
		end
		focusInput:SetText("")
		isValidInput = false
		validIndicator:InvalidateLayout()
	end

	local contentY = Header:GetTall() + FocusBar:GetTall() + GProfiler.GetScaledSize(12)
	Base:SetPos(GProfiler.GetScaledSize(10), contentY)
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - contentY - GProfiler.GetScaledSize(12))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		FocusBar:SetSize(Outer:GetWide(), FocusBar:GetTall())
		FocusList:SetSize(FocusBar:GetWide() - focusInput:GetX() - focusInput:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(26))
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - contentY - GProfiler.GetScaledSize(12))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		if Running and (Functions.Realm == "Client" or Functions.Realm == "Both") then
			local focus = GetFocus()
			GProfiler.Functions.Focus = {}
			for _, v in ipairs(focus) do
				GProfiler.Functions.Focus[v] = true
			end
			if table.IsEmpty(focus) then
				GProfiler.Functions.Focus = false
			end
		end

		GProfiler.Profilers.Toggle("Functions", Functions.Realm, Running)

		if Running then
			SendFocus()
		end

		if Functions.RefreshUI then
			Functions.RefreshUI()
		end
	end

	function RealmSelector:OnStateChanged(state)
		Functions.Realm = state
		if state == "Both" then
			StartStop.State = FunctionsStore:IsActive("Client") or FunctionsStore:IsActive("Server")
		else
			StartStop.State = FunctionsStore:IsActive(state)
		end
		StartStop:SetText(StartStop.State and "Stop" or "Start")
		RebuildFocusChips()
		if Functions.RefreshUI then
			Functions.RefreshUI()
		end
	end

	local Split, RightPanel = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "func_lr", 0.65)
	local ResultsPanel, BottlenecksPanel = GProfiler.Utils.HSplitPanel(Split, GProfiler.GetScaledSize(10), "func_l_tb", 0.65)
	local Source, CallGraph = GProfiler.Utils.HSplitPanel(RightPanel, GProfiler.GetScaledSize(10), "func_r_bt", 0.6)

	local SourceHeader = vgui.Create("DLabel", Source)
	SourceHeader:SetFont("GProfiler.Inter24")
	SourceHeader:SetTextColor(color_white)
	SourceHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	SourceHeader:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	SourceHeader:SetText("Select a function to view source.")

	Source.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)
	end

	local RichText = vgui.Create("RichText", Source)
	RichText:SetText("")
	RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20) - GProfiler.GetScaledSize(30) - GProfiler.GetScaledSize(42))
	RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(30))
	RichText:SetVerticalScrollbarEnabled(true)
	function RichText:PerformLayout()
		self:SetFontInternal("GProfiler.Code")
	end

	local SelectedProfile = nil

	local FocusBtn = vgui.Create("DButton", Source)
	FocusBtn:SetSize((Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, GProfiler.GetScaledSize(32))
	FocusBtn:SetPos(GProfiler.GetScaledSize(10), Source:GetTall() - GProfiler.GetScaledSize(40))
	FocusBtn:SetText("")
	FocusBtn.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(31, 79, 128, s:IsHovered() and 220 or 160))
		draw.SimpleText("Focus Toggle", "GProfiler.Inter24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	FocusBtn.DoClick = function()
		if not SelectedProfile then return end
		local focus = GetFocus()
		if table.HasValue(focus, SelectedProfile.focus) then
			table.RemoveByValue(focus, SelectedProfile.focus)
		else
			table.insert(focus, SelectedProfile.focus)
		end
		RebuildFocusChips()
	end

	local PrintBtn = vgui.Create("DButton", Source)
	PrintBtn:SetSize((Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, GProfiler.GetScaledSize(32))
	PrintBtn:SetPos(GProfiler.GetScaledSize(20) + (Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, Source:GetTall() - GProfiler.GetScaledSize(40))
	PrintBtn:SetText("")
	local printBtnText = "Print Details"
	PrintBtn.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(31, 79, 128, s:IsHovered() and 220 or 160))
		draw.SimpleText(printBtnText, "GProfiler.Inter24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	PrintBtn.DoClick = function()
		if not SelectedProfile then return end
		local v = SelectedProfile
		MsgC(GProfiler.SyntaxColors.keyword, "Function: ", color_white, tostring(v.name), "\n")
		MsgC(GProfiler.SyntaxColors.keyword, "Source: ",   color_white, tostring(v.source), "\n")
		MsgC(GProfiler.SyntaxColors.keyword, "Lines: ",    color_white, tostring(v.lines), "\n")
		MsgC(GProfiler.SyntaxColors.keyword, "Calls: ",    color_white, tostring(v.calls), "\n")
		MsgC(GProfiler.SyntaxColors.keyword, "Total: ",    color_white, string.format("%.4f ms", (v.time or 0) * 1000), "\n")
		MsgC(GProfiler.SyntaxColors.keyword, "Average: ",  color_white, string.format("%.4f ms", (v.average or 0) * 1000), "\n")
		printBtnText = "Printed!"
		timer.Simple(2, function() printBtnText = "Print Details" end)
	end

	Source.OnHandleMoved = function()
		SourceHeader:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
		RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20) - GProfiler.GetScaledSize(30) - GProfiler.GetScaledSize(42))
		RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(30))
		FocusBtn:SetSize((Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, GProfiler.GetScaledSize(32))
		FocusBtn:SetPos(GProfiler.GetScaledSize(10), Source:GetTall() - GProfiler.GetScaledSize(40))
		PrintBtn:SetSize((Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, GProfiler.GetScaledSize(32))
		PrintBtn:SetPos(GProfiler.GetScaledSize(20) + (Source:GetWide() - GProfiler.GetScaledSize(30)) / 2, Source:GetTall() - GProfiler.GetScaledSize(40))
		RichText:InvalidateLayout()
	end

	local cgHeaderH = GProfiler.GetScaledSize(34)

	local CGHeader = vgui.Create("DLabel", CallGraph)
	CGHeader:SetFont("GProfiler.Inter24")
	CGHeader:SetTextColor(color_white)
	CGHeader:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(5))
	CGHeader:SetSize(CallGraph:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
	CGHeader:SetText("Call Graph")

	CallGraph.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_TL + GProfiler.RNDX.NO_TR)
	end

	local currentCGTree = nil

	local copyBtnW = GProfiler.GetScaledSize(90)
	local copyBtnH = GProfiler.GetScaledSize(24)
	local CGCopyBtn = vgui.Create("DButton", CallGraph)
	CGCopyBtn:SetSize(copyBtnW, copyBtnH)
	CGCopyBtn:SetPos(CallGraph:GetWide() - copyBtnW - GProfiler.GetScaledSize(8), GProfiler.GetScaledSize(5))
	CGCopyBtn:SetText("")
	local copyBtnText = "Copy"
	CGCopyBtn.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(31, 79, 128, s:IsHovered() and 220 or 160))
		draw.SimpleText(copyBtnText, "GProfiler.Inter24", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	CGCopyBtn.DoClick = function()
		if not currentCGTree then
			copyBtnText = "No data"
			timer.Simple(2, function() copyBtnText = "Copy" end)
			return
		end

		local lines = {}
		local function serialize(nodeList)
			for _, node in ipairs(nodeList) do
				local indent = string.rep("  ", node.Depth or 0)
				local src = node.source and node.source ~= "" and string.format(" | %s (%s)", node.source, node.lines or "") or ""
				lines[#lines + 1] = string.format("%s- %s | %s | %s%s",
					indent, node.name or "?", node.timeStr or "", node.pctStr or "", src)
				if node.Children and #node.Children > 0 then
					serialize(node.Children)
				end
			end
		end
		serialize(currentCGTree)

		SetClipboardText(table.concat(lines, "\n"))
		copyBtnText = "Copied!"
		timer.Simple(2, function() copyBtnText = "Copy" end)
	end

	local CGScroll = vgui.Create("DScrollPanel", CallGraph)
	CGScroll:SetPos(0, cgHeaderH)
	CGScroll:SetSize(CallGraph:GetWide(), CallGraph:GetTall() - cgHeaderH)

	local function SetDefaultCGState(msg)
		if not IsValid(CGScroll) then return end
		currentCGTree = nil
		CGScroll:Clear()
		local pnl = vgui.Create("DPanel", CGScroll)
		pnl:Dock(FILL)
		pnl.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, GProfiler.SyntaxColors.background)
			draw.SimpleText(msg or "Select a function to view call graph.", "GProfiler.Inter24", GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(14), GProfiler.SyntaxColors.comment, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		pnl:SetTall(CGScroll:GetTall())
		CGScroll.OnSizeChanged = function(scroll, w, h)
			if IsValid(pnl) then pnl:SetTall(h) end
		end
	end
	SetDefaultCGState()

	local function RenderCallGraph(tree)
		if not IsValid(CGScroll) then return end
		if not tree or not tree.children or #tree.children == 0 then
			SetDefaultCGState("No call graph data available.")
			return
		end

		CGScroll:Clear()

		local Canvas = vgui.Create("DPanel", CGScroll)
		Canvas:Dock(TOP)
		Canvas:SetTall(0)

		local lineHeight = GProfiler.GetScaledSize(22)
		local indentSize = GProfiler.GetScaledSize(16)
		local iconSize = GProfiler.GetScaledSize(10)

		local function convert(nodeList, parentTime, depth)
			local nodes = {}
			for _, v in ipairs(nodeList) do
				local pct = parentTime > 0 and math.min((v.time or 0) / parentTime, 1) or 0
				local node = {
					name = v.name or "Unknown",
					timeStr = string.format("%.3fms", (v.time or 0) * 1000),
					pctStr = string.format("%.1f%%", pct * 100),
					pctNum = pct,
					time = v.time or 0,
					source = v.source or "",
					lines = v.lines or "",
					Depth = depth,
					Expanded = false,
					Children = {}
				}
				if v.children and #v.children > 0 and depth < 32 then
					node.Children = convert(v.children, v.time or 0, depth + 1)
				end
				node.Expanded = #node.Children > 0
				nodes[#nodes + 1] = node
			end
			return nodes
		end

		local children = convert(tree.children, tree.time or 0, 1)

		local RootNodes = {
			{
				name = tree.name or "Unknown",
				timeStr = string.format("%.3fms", (tree.time or 0) * 1000),
				pctStr = "100%",
				pctNum = 1.0,
				time = tree.time or 0,
				source = tree.source or "",
				lines = tree.lines or "",
				Depth = 0,
				Expanded = true,
				Children = children
			}
		}

		currentCGTree = RootNodes

		Canvas.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, GProfiler.SyntaxColors.background)

			local mouseX, mouseY = s:LocalCursorPos()
			local clicked = s.MousePressed

			if clicked then
				local function checkClick(nodeList, currentY)
					for _, node in ipairs(nodeList) do
						local rowY = currentY
						currentY = currentY + lineHeight
						if #node.Children > 0 then
							local ex = GProfiler.GetScaledSize(6) + node.Depth * indentSize
							if mouseX >= ex - 4 and mouseX <= ex + iconSize + 4 and mouseY >= rowY and mouseY <= rowY + lineHeight then
								node.Expanded = not node.Expanded
								s:InvalidateLayout()
								return currentY, true
							end
						end
						if node.Expanded and #node.Children > 0 then
							local newY, handled = checkClick(node.Children, currentY)
							currentY = newY
							if handled then return currentY, true end
						end
					end
					return currentY, false
				end
				checkClick(RootNodes, 0)
				s.MousePressed = false
			end

			local function DrawNodes(nodeList, currentY)
				for _, node in ipairs(nodeList) do
					local rowY = currentY

					surface.SetDrawColor(Color(31, 79, 128, 70))
					surface.DrawRect(0, rowY, w * math.Clamp(node.pctNum, 0, 1), lineHeight)
					surface.SetDrawColor(GProfiler.SyntaxColors.lineSep)
					surface.DrawRect(0, rowY + lineHeight - 1, w, 1)

					local ex = GProfiler.GetScaledSize(6) + node.Depth * indentSize
					if #node.Children > 0 then
						surface.SetDrawColor(GProfiler.SyntaxColors.lineNumber)
						draw.NoTexture()
						local ey = rowY + (lineHeight - iconSize) / 2
						if node.Expanded then
							surface.DrawPoly({
								{ x = ex,                y = ey + iconSize / 4 },
								{ x = ex + iconSize / 2, y = ey + iconSize / 4 },
								{ x = ex + iconSize / 4, y = ey + iconSize * 3 / 4 }
							})
						else
							surface.DrawPoly({
								{ x = ex,                y = ey + iconSize / 4 },
								{ x = ex + iconSize / 2, y = ey + iconSize / 2 },
								{ x = ex,                y = ey + iconSize * 3 / 4 }
							})
						end
					end

					surface.SetFont("GProfiler.Code")
					local textY = rowY + (lineHeight - select(2, surface.GetTextSize("A"))) / 2 - 1
					local nameX = ex + iconSize + GProfiler.GetScaledSize(4)
					local pctW = surface.GetTextSize(node.pctStr)
					local timeW = surface.GetTextSize(node.timeStr)
					local rightX = w - GProfiler.GetScaledSize(8)

					surface.SetTextColor(GProfiler.SyntaxColors.string)
					surface.SetTextPos(rightX - pctW, textY)
					surface.DrawText(node.pctStr)
					rightX = rightX - pctW - GProfiler.GetScaledSize(10)

					surface.SetTextColor(GProfiler.SyntaxColors.number)
					surface.SetTextPos(rightX - timeW, textY)
					surface.DrawText(node.timeStr)

					surface.SetTextColor(GProfiler.SyntaxColors.funcCall)
					surface.SetTextPos(nameX, textY)
					surface.DrawText(node.name)

					currentY = currentY + lineHeight
					if node.Expanded and #node.Children > 0 then
						currentY = DrawNodes(node.Children, currentY)
					end
				end
				return currentY
			end

			DrawNodes(RootNodes, 0)
		end

		Canvas.PerformLayout = function(s)
			local function CalcHeight(nodeList)
				local h = 0
				for _, node in ipairs(nodeList) do
					h = h + lineHeight
					if node.Expanded and #node.Children > 0 then h = h + CalcHeight(node.Children) end
				end
				return h
			end
			s:SetTall(math.max(CalcHeight(RootNodes) + GProfiler.GetScaledSize(10), CGScroll:GetTall()))
		end

		Canvas.OnMousePressed = function(s, code)
			if code == MOUSE_LEFT then s.MousePressed = true end
		end

		Canvas:InvalidateLayout()
	end

	local function PopulateCallGraph(cgKey)
		if not IsValid(CGScroll) then return end
		if not cgKey then SetDefaultCGState() return end

		local displayRealm = Functions.Realm == "Both" and "Client" or Functions.Realm

		if displayRealm == "Server" then
			local cached = Functions.CGServerCache[cgKey]
			if cached ~= nil then
				RenderCallGraph(cached or nil)
			else
				SetDefaultCGState("Loading call graph...")
				net.Start("GProfiler_Functions_RequestCallGraph")
				net.WriteString(cgKey)
				net.SendToServer()
				Functions._pendingCGKey = cgKey
			end
			return
		end

		local cgData = FunctionsStore:GetData(displayRealm .. "_callgraph") or {}
		RenderCallGraph(cgData[cgKey])
	end

	Functions.RefreshCallGraph = PopulateCallGraph

	CallGraph.OnHandleMoved = function()
		CGHeader:SetSize(CallGraph:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(24))
		CGScroll:SetSize(CallGraph:GetWide(), CallGraph:GetTall() - cgHeaderH)
		CGCopyBtn:SetPos(CallGraph:GetWide() - copyBtnW - GProfiler.GetScaledSize(8), GProfiler.GetScaledSize(5))
	end

	local ListHeader = GProfiler.Utils.SetupHeader(ResultsPanel, "Profiler Results", nil, true)
	local ResultsList = GProfiler.Utils.CreateList(ResultsPanel, ListHeader, {
		"Function", "Source", "Calls", "Total Time (ms)", "Avg Time (ms)"
	})

	local filterLbl = vgui.Create("DLabel", ListHeader)
	filterLbl:SetFont("GProfiler.Inter24")
	filterLbl:SetTextColor(color_white)
	filterLbl:SetText("Filter source:")
	filterLbl:SizeToContents()

	local filterInput = vgui.Create("DTextEntry", ListHeader)
	filterInput:SetSize(GProfiler.GetScaledSize(150), GProfiler.GetScaledSize(28))
	filterInput:SetFont("GProfiler.Inter24")
	StyleInput(filterInput)

	filterLbl:SetPos(ListHeader:GetWide() - filterInput:GetWide() - filterLbl:GetWide() - GProfiler.GetScaledSize(15), ListHeader:GetTall() / 2 - filterLbl:GetTall() / 2)
	filterInput:SetPos(ListHeader:GetWide() - filterInput:GetWide() - GProfiler.GetScaledSize(10), ListHeader:GetTall() / 2 - filterInput:GetTall() / 2)

	local BottleneckHeader = GProfiler.Utils.SetupHeader(BottlenecksPanel, "Top 50 Bottlenecks", nil, true)
	local BottleneckList = GProfiler.Utils.CreateList(BottlenecksPanel, BottleneckHeader, {
		"#", "Function", "Source", "Single Run (ms)"
	})

	local function PopulateBottlenecks()
		if not IsValid(BottleneckList) then return end

		local displayRealm = Functions.Realm == "Both" and "Client" or Functions.Realm
		local bottlenecks = FunctionsStore:GetData(displayRealm .. "_bottlenecks") or {}

		BottleneckList:Clear()

		for i, v in ipairs(bottlenecks) do
			local row = BottleneckList:AddLine(
				i,
				v.name or "Unknown",
				string.format("%s (%s)", v.source, v.lines),
				math.Round((v.runtime or 0) * 1000, 4)
			)
			row.BottleneckData = v
			row:SetSortValue(4, v.runtime or 0)
		end
	end

	function BottleneckList:OnRowSelected(rowIndex, row)
		local data = row.BottleneckData
		if not data then return end
		SelectedProfile = { name = data.name, source = data.source, lines = data.lines, focus = data.focus }
		PopulateCallGraph(data.cgKey or data.focus)

		RichText:SetText("Loading source...")
		SourceHeader:SetText("")

		local file = data.source
		if file and file ~= "" then
			file = string.match(file, "@?(.+)") or file
			local lines = string.Split(data.lines or "0 - 0", " - ")
			local lineStart = tonumber(lines[1]) or 0
			local lineEnd = tonumber(lines[2]) or 0

			SourceHeader:SetText(string.format("%s (%d - %d)", file, lineStart, lineEnd))
			GProfiler.RequestFunctionSource(file, lineStart, lineEnd, function(src)
				if not IsValid(RichText) then return end
				if src then
					GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), lineStart)
				else
					RichText:SetText("Failed to load source.")
				end
			end)
		else
			RichText:SetText("No source available.")
		end
	end

	BottlenecksPanel.OnHandleMoved = function()
		BottleneckList:SetSize(BottlenecksPanel:GetWide(), BottlenecksPanel:GetTall() - BottleneckHeader:GetTall())
		BottleneckList:SetPos(0, BottleneckHeader:GetTall())
		BottleneckHeader:SetWide(BottlenecksPanel:GetWide())
	end

	local function PopulateResults()
		if not IsValid(ResultsList) then return end

		local displayRealm = Functions.Realm == "Both" and "Client" or Functions.Realm
		local realmData = FunctionsStore:GetData(displayRealm) or {}

		ResultsList:Clear()

		local filterText = Functions.SourceFilter:lower()

		for _, v in pairs(realmData) do
			if filterText ~= "" then
				local src = (v.source or ""):lower()
				if not string.find(src, filterText, 1, true) then continue end
			end

			local row = ResultsList:AddLine(
				v.name or "Unknown",
				string.format("%s (%s)", v.source, v.lines),
				v.calls,
				math.Round((v.time or 0) * 1000, 4),
				math.Round((v.average or 0) * 1000, 4)
			)
			row.FunctionData = v
			row:SetSortValue(4, v.time or 0)
			row:SetSortValue(5, v.average or 0)
		end

		ResultsList:SortByColumn(4, true)
		PopulateBottlenecks()
	end

	filterInput.OnTextChanged = function()
		Functions.SourceFilter = filterInput:GetText()
		PopulateResults()
	end

	timer.Simple(0, function()
		if IsValid(filterInput) and Functions.SourceFilter ~= "" then
			filterInput:SetText(Functions.SourceFilter)
		end
	end)

	Functions.RefreshUI = function()
		Functions.CGServerCache = {}
		PopulateResults()
		SetDefaultCGState()
	end
	PopulateResults()

	function ResultsList:OnRowSelected(rowIndex, row)
		local data = row.FunctionData
		if not data then return end
		SelectedProfile = data
		PopulateCallGraph(data.cgKey or data.focus)

		RichText:SetText("Loading source...")
		SourceHeader:SetText("")

		local file = data.source
		if file and file ~= "" then
			file = string.match(file, "@?(.+)") or file
			local lines = string.Split(data.lines or "0 - 0", " - ")
			local lineStart = tonumber(lines[1]) or 0
			local lineEnd = tonumber(lines[2]) or 0

			SourceHeader:SetText(string.format("%s (%d - %d)", file, lineStart, lineEnd))
			GProfiler.RequestFunctionSource(file, lineStart, lineEnd, function(src)
				if not IsValid(RichText) then return end
				if src then
					GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), lineStart)
				else
					RichText:SetText("Failed to load source.")
				end
			end)
		else
			RichText:SetText("No source available.")
		end
	end

	ResultsList.OnRowRightClick = function(lst, rowIndex, row)
		local data = row and row.FunctionData
		if not data then return end

		local focus = GetFocus()
		local isFocused = table.HasValue(focus, data.focus)
		local menu = DermaMenu()
		menu:AddOption(isFocused and "Remove Focus" or "Add Focus", function()
			if isFocused then
				table.RemoveByValue(focus, data.focus)
			else
				table.insert(focus, data.focus)
			end
			RebuildFocusChips()
		end):SetIcon("icon16/zoom.png")
		menu:AddSpacer()
		menu:AddOption("Copy Function Name", function() SetClipboardText(data.name or "") end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Source",        function() SetClipboardText(data.source or "") end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Calls",         function() SetClipboardText(tostring(data.calls or 0)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Total Time",    function() SetClipboardText(tostring(data.time or 0)) end):SetIcon("icon16/page_copy.png")
		menu:AddOption("Copy Avg Time",      function() SetClipboardText(tostring(data.average or 0)) end):SetIcon("icon16/page_copy.png")
		menu:Open()
	end

	ResultsPanel.OnHandleMoved = function()
		ResultsList:SetSize(ResultsPanel:GetWide(), ResultsPanel:GetTall() - ListHeader:GetTall())
		ResultsList:SetPos(0, ListHeader:GetTall())
		ListHeader:SetWide(ResultsPanel:GetWide())
		filterLbl:SetPos(ListHeader:GetWide() - filterInput:GetWide() - filterLbl:GetWide() - GProfiler.GetScaledSize(15), ListHeader:GetTall() / 2 - filterLbl:GetTall() / 2)
		filterInput:SetPos(ListHeader:GetWide() - filterInput:GetWide() - GProfiler.GetScaledSize(10), filterInput:GetY())
	end
end

GProfiler.Menu.RegisterTab("Functions", "gprofiler/functions.png", 3, GProfiler.Functions.DoTab, function()
	local realm = Functions.Realm == "Both" and "Client" or Functions.Realm
	local timer = FunctionsStore:GetTimerData(realm)
	if timer.StartTime == 0 then return end
	return GProfiler.TimeRunning(timer.StartTime, timer.EndTime, timer.ProfileActive), timer.ProfileActive
end)

local function MakeCgKey(name, source, lines)
	local stableName = name or ""
	if string.StartWith(stableName, "0x") then stableName = "" end
	local stripped = string.match(stableName, "^(.+)%s+%[.-%]$")
	if stripped then stableName = stripped end
	local splitLines = string.Split(lines or "0 - 0", " - ")
	return (source or "") .. "\1" .. (splitLines[1] or "0") .. "\1" .. (splitLines[2] or "0") .. "\1" .. stableName
end

net.Receive("GProfiler_Functions_SendData", function()
	local first = net.ReadBool()
	if first then Functions._pendingData = {} end

	local last = net.ReadBool()
	local count = net.ReadUInt(32)
	local pending = Functions._pendingData or {}

	for i = 1, count do
		local name = net.ReadString()
		local source = net.ReadString()
		local lines = net.ReadString()
		local calls = net.ReadUInt(22)
		local time = net.ReadFloat()
		local average = net.ReadFloat()
		local focus = net.ReadString()
		local cgKey = MakeCgKey(name, source, lines)

		if not pending[cgKey] then
			pending[cgKey] = {
				name = name, source = source, lines = lines,
				calls = 0, time = 0, average = 0,
				focus = focus, cgKey = cgKey
			}
		end
		local d = pending[cgKey]
		d.calls = d.calls + calls
		d.time = d.time + time
		d.average = d.average + average
	end

	Functions._pendingData = pending

	if last then
		FunctionsStore:SetData("Server", pending)
		Functions._pendingData = nil
		Functions.ReceivingData = false
		if Functions.RefreshUI then Functions.RefreshUI() end
	end
end)

net.Receive("GProfiler_Functions_SendBottlenecks", function()
	local count = net.ReadUInt(6)
	local list = {}
	for i = 1, count do
		local name = net.ReadString()
		local source = net.ReadString()
		local lines = net.ReadString()
		table.insert(list, {
			name = name,
			source = source,
			lines = lines,
			runtime = net.ReadFloat(),
			cgKey = MakeCgKey(name, source, lines)
		})
	end
	FunctionsStore:SetData("Server_bottlenecks", list)
	if Functions.RefreshUI then Functions.RefreshUI() end
end)

local function netReadTree()
	local node = {
		name = net.ReadString(),
		source = net.ReadString(),
		lines = net.ReadString(),
		time = net.ReadFloat(),
		children = {}
	}
	local count = net.ReadUInt(16)
	for i = 1, count do
		node.children[#node.children + 1] = netReadTree()
	end
	return node
end

net.Receive("GProfiler_Functions_CallGraphResponse", function()
	local cgKey = net.ReadString()
	local hasTree = net.ReadBool()
	local tree = hasTree and netReadTree() or nil

	Functions.CGServerCache[cgKey] = tree or false

	if Functions._pendingCGKey == cgKey and Functions.RefreshCallGraph then
		Functions.RefreshCallGraph(cgKey)
		Functions._pendingCGKey = nil
	end
end)
