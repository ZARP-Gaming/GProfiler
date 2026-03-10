GProfiler.Net = GProfiler.Net or {}
local Net = GProfiler.Net

-- Net.StartTime = Net.StartTime or 0
-- Net.EndTime = Net.EndTime or 0
-- Net.Realm = Net.Realm or "Client"
Net.StartTime = 0
Net.EndTime = 0
Net.Realm = "Client"

function GProfiler.Net.DoTab(Base, Outer)
	local Header = GProfiler.Utils.SetupHeader(Outer, "Networking", "gprofiler/network.png")
	local StartStop = Header:SetupStartStop(Net.ProfileActive)
	local RealmSelector = Header:SetupRealmSelector(Net.Realm == "Client")
	local Timer = Header:SetupTimer(Net)

	Base:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(12))
	Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
	Base.OnHandleMoved = function()
		Header:SetWide(Outer:GetWide())
		Base:SetSize(Outer:GetWide() - GProfiler.GetScaledSize(20), Outer:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(22))
		Header.OnHandleMoved()
	end

	function StartStop:OnStateChanged(Running)
		Net.ProfileActive = Running

		if not Net.ProfileActive then
			Net.EndTime = SysTime()

			if Net.Realm == "Client" then
				GProfiler.Net:RestoreNet()
			else
				net.Start("GProfiler_Net_ToggleServerProfile")
				net.WriteBool(false)
				net.SendToServer()
			end
		else
			Net.StartTime = SysTime()
			Net.EndTime = 0

			if Net.Realm == "Client" then
				GProfiler.Net:StartProfiler()
			else
				net.Start("GProfiler_Net_ToggleServerProfile")
				net.WriteBool(true)
				net.SendToServer()
				GProfiler.Net.ProfileData = {}
			end
		end
	end

	function RealmSelector:OnStateChanged(state) Net.Realm = state end

	local left, right = GProfiler.Utils.VSplitPanel(Base, GProfiler.GetScaledSize(10), "net_lr", 0.65)
	local Results, Receivers = GProfiler.Utils.HSplitPanel(left, GProfiler.GetScaledSize(10), "net_l_bt", 0.65)
	local ResultsSent, ResultsReceived = GProfiler.Utils.HSplitPanel(Results, GProfiler.GetScaledSize(10), "net_results_split", 0.5)
	local Source, Breakdown = GProfiler.Utils.HSplitPanel(right, GProfiler.GetScaledSize(10), "net_r_bt", 0.75)
	local ClientReceivers, ServerReceivers = GProfiler.Utils.VSplitPanel(Receivers, GProfiler.GetScaledSize(10), "net_lb_lr", 0.5)

	Source.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)
	end

	local RichText = vgui.Create("RichText", Source)
	RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20))
	RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(10))
	RichText:SetVerticalScrollbarEnabled(true)
	function RichText:PerformLayout()
		self:SetFontInternal("GProfiler.Code")
	end

	Source.OnHandleMoved = function()
		RichText:SetSize(Source:GetWide() - GProfiler.GetScaledSize(20), Source:GetTall() - GProfiler.GetScaledSize(20))
		RichText:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(10))
		RichText:InvalidateLayout()
	end

	local BreakdownPanel = vgui.Create("DScrollPanel", Breakdown)
	BreakdownPanel:Dock(FILL)

	local function FormatBits(bits)
		if not bits or bits == 0 then return "0 Bytes" end
		if bits < 8 then
			return bits .. (bits == 1 and " Bit" or " Bits")
		end
		return string.NiceSize(bits / 8)
	end

	local SentHeader = GProfiler.Utils.SetupHeader(ResultsSent, "Messages Sent", nil, true)
	local ReceivedHeader = GProfiler.Utils.SetupHeader(ResultsReceived, "Messages Received", nil, true)

	local function CreateList(Parent, Columns)
		local ResultsList = vgui.Create("GP.ListView", Parent)
		ResultsList:SetSize(Parent:GetWide(), Parent:GetTall() - SentHeader:GetTall())
		ResultsList:SetPos(0, SentHeader:GetTall())
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
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10))
		end
		sbar.btnGrip.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 20))
		end

		for k, v in ipairs(ResultsList.Columns) do
			v.Header:SetFont("GProfiler.Inter28")
			v.Header:SetTextColor(color_white)
			local isLast = v == ResultsList.Columns[#ResultsList.Columns]
			v.Header.Paint = function(s, w, h)
				GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(64, 105, 146), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
				if not isLast then
					surface.SetDrawColor(Color(255, 255, 255, 20))
					surface.DrawRect(w - 1, 0, 1, h)
				end

				if s:IsHovered() then
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 20), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
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
				GProfiler.RNDX.Draw(0, 0, 0, w, h, isEven and Color(255, 255, 255, 10) or Color(255, 255, 255, 2))

				if s:IsHovered() then
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 20))
				end

				if s:IsLineSelected() then
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 30))
				end
			end
			for _, col in pairs(line.Columns) do
				col:SetFont("GProfiler.Inter24")
				col:SetTextColor(Color(255, 255, 255, 200))
			end
			return line
		end

		local sbar = ResultsList.VBar
		sbar:SetWide(GProfiler.GetScaledSize(12))
		sbar:SetHideButtons(true)
		sbar.Paint = function(s, w, h) GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10)) end
		sbar.btnGrip.Paint = function(s, w, h) GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 20)) end

		return ResultsList
	end

	local ResultsList = CreateList(ResultsSent, {"Name", "Count", "Size", "Total", "Avg Time"})
	local ReceivedList = CreateList(ResultsReceived, {"Name", "Count", "Size", "Total", "Avg Time"})

	Results.OnHandleMoved = function()
		ResultsList:SetSize(Results:GetWide(), Results:GetTall() - SentHeader:GetTall())
		ResultsList:SetPos(0, SentHeader:GetTall())
		ReceivedList:SetSize(Results:GetWide(), Results:GetTall() - ReceivedHeader:GetTall())
		ReceivedList:SetPos(0, ReceivedHeader:GetTall())
		SentHeader:SetSize(Results:GetWide(), SentHeader:GetTall())
		ReceivedHeader:SetSize(Results:GetWide(), ReceivedHeader:GetTall())
	end

	local function PopulateBreakdown(name, nodes, totalSize)
		if not IsValid(BreakdownPanel) then return end

		BreakdownPanel:Clear()

		local Canvas = vgui.Create("DPanel", BreakdownPanel)
		Canvas:Dock(TOP)
		Canvas:SetTall(0)
		Canvas.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, GProfiler.SyntaxColors.background)
		end

		local function GetParts(funcName, arg, size)
			local parts = {}
			table.insert(parts, {"net", GProfiler.SyntaxColors.library})
			table.insert(parts, {".", GProfiler.SyntaxColors.punctuation})
			table.insert(parts, {funcName, GProfiler.SyntaxColors.funcCall})
			table.insert(parts, {"(", GProfiler.SyntaxColors.punctuation})
			if arg then
				table.insert(parts, {arg, GProfiler.SyntaxColors.string})
			end
			table.insert(parts, {")", GProfiler.SyntaxColors.punctuation})
			if size and size > 0 then
				table.insert(parts, {" -- Size: " .. FormatBits(size), GProfiler.SyntaxColors.comment})
			end
			return parts
		end

		local Lines = {}

		table.insert(Lines, {
			Parts = GetParts("Start", '"' .. name .. '"', totalSize),
			Depth = 0,
			Expanded = true,
			Children = nodes
		})

		local function AddChildren(children, depth)
			for _, child in ipairs(children) do
				local line = {
					Parts = GetParts(child.Func, nil, child.Size),
					Depth = depth,
					Expanded = true,
					Children = child.Children,
					IsNode = true,
					ParentNode = children
				}
				table.insert(Lines, line)
				if child.Children and #child.Children > 0 then
					AddChildren(child.Children, depth + 1)
				end
			end
		end

		local RootNodes = {}

		local startNode = {
			Parts = GetParts("Start", '"' .. name .. '"', totalSize),
			Children = {},
			Depth = 0,
			Expanded = true
		}
		table.insert(RootNodes, startNode)

		local hiddenFuncs = {
			["Start"] = true,
			["Send"] = true,
			["Broadcast"] = true,
			["SendOmit"] = true,
			["SendPVS"] = true,
			["SendPAS"] = true
		}

		local function BuildTree(parentList, dataChildren, depth)
			for _, child in ipairs(dataChildren) do
				if hiddenFuncs[child.Func] then continue end

				local node = {
					Parts = GetParts(child.Func, nil, child.Size),
					Children = {},
					Depth = depth,
					Expanded = true
				}
				table.insert(parentList, node)
				if child.Children and #child.Children > 0 then
					BuildTree(node.Children, child.Children, depth + 1)
				end
			end
		end

		BuildTree(startNode.Children, nodes, 1)

		local sendNode = {
			Parts = GetParts("Send"),
			Children = {},
			Depth = 0,
			Expanded = true
		}
		table.insert(RootNodes, sendNode)

		local lineHeight = GProfiler.GetScaledSize(22)
		local indentSize = GProfiler.GetScaledSize(20)
		local iconSize = GProfiler.GetScaledSize(16)

		Canvas.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(8, 0, 0, w, h, GProfiler.SyntaxColors.background, GProfiler.RNDX.NO_BR + GProfiler.RNDX.NO_BL)

			draw.RoundedBox(0, 0, 0, GProfiler.GetScaledSize(30), h, GProfiler.SyntaxColors.background)
			surface.SetDrawColor(GProfiler.SyntaxColors.lineSep)
			surface.DrawRect(GProfiler.GetScaledSize(30), 0, 1, h)

			local y = 0
			local mouseX, mouseY = s:LocalCursorPos()
			local clicked = s.MousePressed
			local targetNode = nil

			if clicked then
				local function checkClick(nodeList, currentY)
					for _, node in ipairs(nodeList) do
						local rowY= currentY
						currentY = currentY + lineHeight

						local x = GProfiler.GetScaledSize(40) + (node.Depth * indentSize)
						local expanderX = x - indentSize

						if #node.Children > 0 then
							if mouseX >= expanderX and mouseX <= expanderX + iconSize and mouseY >= rowY and mouseY <= rowY + lineHeight then
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

			local lineNum = 1
			local function DrawNodes(nodeList, currentY)
				for _, node in ipairs(nodeList) do
					local rowY = currentY

					draw.SimpleText(lineNum, "GProfiler.Code", GProfiler.GetScaledSize(25), rowY + lineHeight/2, GProfiler.SyntaxColors.lineNumber, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					lineNum = lineNum + 1

					local x = GProfiler.GetScaledSize(40) + (node.Depth * indentSize)

					if #node.Children > 0 and node.Depth > 0 then
						local expanderX = x - indentSize
						local expanderY = rowY + (lineHeight - iconSize)/2

						surface.SetDrawColor(GProfiler.SyntaxColors.lineNumber)
						draw.NoTexture()

						if node.Expanded then
							surface.DrawPoly({
								{ x = expanderX, y = expanderY + iconSize/4 },
								{ x = expanderX + iconSize/2, y = expanderY + iconSize/4 },
								{ x = expanderX + iconSize/4, y = expanderY + iconSize/2 + iconSize/4 }
							})
						else
							surface.DrawPoly({
								{ x = expanderX, y = expanderY + iconSize/4 },
								{ x = expanderX + iconSize/2, y = expanderY + iconSize/2 },
								{ x = expanderX, y = expanderY + iconSize/2 + iconSize/4 }
							})
						end
					end

					surface.SetFont("GProfiler.Code")
					local textX = x
					for _, part in ipairs(node.Parts) do
						surface.SetTextColor(part[2])
						surface.SetTextPos(textX, rowY + (lineHeight - surface.GetTextSize("A"))/2 - 4)
						surface.DrawText(part[1])
						textX = textX + surface.GetTextSize(part[1])
					end

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
			local h = 0
			local function CalcHeight(nodeList)
				for _, node in ipairs(nodeList) do
					h = h + lineHeight
					if node.Expanded and #node.Children > 0 then
						CalcHeight(node.Children)
					end
				end
			end
			CalcHeight(RootNodes)
			s:SetTall(h + GProfiler.GetScaledSize(10))
		end

		Canvas.OnMousePressed = function(s, code)
			if code == MOUSE_LEFT then
				s.MousePressed = true
			end
		end

		Canvas:InvalidateLayout()
	end

	GProfiler.Net.UpdateBreakdownUI = function(name)
		local data = GProfiler.Net.Breakdowns[name]
		if data then
			PopulateBreakdown(name, data.Nodes, data.Size)
		end
	end

	function ResultsList:OnRowSelected(rowIndex, row)
		local name = row:GetColumnText(1)
		local data = GProfiler.Net.ProfileData.Out and GProfiler.Net.ProfileData.Out[name]

		if data then
			BreakdownPanel:Clear()

			local file = data.Source or data[4]
			local lineDefined = data.LineDefined or data[5] or 0
			local lastLineDefined = data.LastLineDefined or data[6] or 0

			if file and file ~= "" then
				file = string.match(file, "@?(.+)")
				if not file then file = data.Source or data[4] end

				GProfiler.RequestFunctionSource(file, lineDefined, lastLineDefined, function(src)
					if src then
						GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), lineDefined)
					else
						RichText:SetText("Failed to load source")
					end
				end)
			else
				RichText:SetText("Failed to load source (2)")
			end

			if Net.Realm == "Client" then
				local breakdownData = GProfiler.Net.Breakdowns and GProfiler.Net.Breakdowns[name]
				if breakdownData then
					PopulateBreakdown(name, breakdownData.Children or {}, data.Size or data[7] or 0)
				end
			else
				net.Start("GProfiler_Net_RequestBreakdown")
				net.WriteString(name)
				net.SendToServer()
			end
		end
	end

	function ReceivedList:OnRowSelected(rowIndex, row)
		local name = row:GetColumnText(1)
		local data = GProfiler.Net.ProfileData.Inc and GProfiler.Net.ProfileData.Inc[name]

		if data then
			BreakdownPanel:Clear()

			local file = data.Source or data[4]
			local lineDefined = data.LineDefined or data[5] or 0
			local lastLineDefined = data.LastLineDefined or data[6] or 0

			if file and file ~= "" then
				file = string.match(file, "@?(.+)")
				if not file then file = data.Source or data[4] end

				GProfiler.RequestFunctionSource(file, lineDefined, lastLineDefined, function(src)
					if src then
						GProfiler.SyntaxHighlight(RichText, table.concat(src, ""), lineDefined)
					else
						RichText:SetText("Failed to load source")
					end
				end)
			else
				RichText:SetText("Failed to load source (2)")
			end
		end
	end

	local function PopulateResults()
		if not IsValid(ResultsList) or not IsValid(ReceivedList) then return end

		ResultsList:Clear()
		if GProfiler.Net.ProfileData.Out then
			for name, data in pairs(GProfiler.Net.ProfileData.Out) do
				local count = data.Count or data[1] or 0
				local maxSize = data.MaxSize or data[2] or 0
				local totalSize = data.TotalSize or data[3] or 0
				local avgTime = data.AverageTime or data[9] or 0

				ResultsList:AddLine(name, count, FormatBits(maxSize), FormatBits(totalSize), math.Round(avgTime * 1000, 3) .. "ms")
			end
		end

		ReceivedList:Clear()
		if GProfiler.Net.ProfileData.Inc then
			for name, data in pairs(GProfiler.Net.ProfileData.Inc) do
				local count = data.Count or data[1] or 0
				local maxSize = data.MaxSize or data[2] or 0
				local totalSize = data.TotalSize or data[3] or 0
				local avgTime = data.AverageTime or data[9] or 0

				ReceivedList:AddLine(name, count, FormatBits(maxSize), FormatBits(totalSize), math.Round(avgTime * 1000, 3) .. "ms")
			end
		end
	end
	GProfiler.Net.RefreshUI = PopulateResults
	PopulateResults()

	Base.OnRemove = function()
		GProfiler.Net.RefreshUI = nil
		GProfiler.Net.UpdateBreakdownUI = nil
	end

	local function CreateReceiverList(Parent, Receivers, Title)
		Parent:Clear()

		local HeaderPanel = vgui.Create("DPanel", Parent)
		HeaderPanel:SetSize(Parent:GetWide(), GProfiler.GetScaledSize(50))
		HeaderPanel.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(8, 0, 0, w, h, Color(34, 77, 122), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
			draw.SimpleText(Title, "GProfiler.Inter28", GProfiler.GetScaledSize(10), h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local RefreshButton = vgui.Create("DButton", HeaderPanel)
		RefreshButton:SetSize(GProfiler.GetScaledSize(80), GProfiler.GetScaledSize(30))
		RefreshButton:SetPos(HeaderPanel:GetWide() - RefreshButton:GetWide() - GProfiler.GetScaledSize(10), (HeaderPanel:GetTall() - RefreshButton:GetTall()) / 2)
		RefreshButton:SetText("Refresh")
		RefreshButton:SetFont("GProfiler.Inter24")
		RefreshButton:SetTextColor(Color(0,0,0,0))
		RefreshButton.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 20))
			if s:IsHovered() then
				GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 20))
			end
			draw.SimpleText("Refresh", "GProfiler.Inter24", w / 2, h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		RefreshButton.DoClick = function()
			net.Start("GProfiler_Net_ReceiverTbl")
			net.SendToServer()
		end

		local List = vgui.Create("DPanelList", Parent)
		List:SetSize(Parent:GetWide(), Parent:GetTall() - HeaderPanel:GetTall())
		List:SetPos(0, HeaderPanel:GetTall())
		List:EnableVerticalScrollbar()

		local ScrollBar = List.VBar
		ScrollBar:SetWide(GProfiler.GetScaledSize(12))
		ScrollBar:SetHideButtons(true)
		ScrollBar.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 10))
		end
		ScrollBar.btnGrip.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 20))
		end

		for k, Receiver in ipairs(Receivers) do
			local i = k
			local Item = vgui.Create("DButton", List)
			Item:SetSize(List:GetWide(), GProfiler.GetScaledSize(30))
			Item:SetText(Receiver.Name)
			Item:SetFont("GProfiler.Inter24")
			Item:SizeToContentsY()
			Item:SetTall(Item:GetTall() + GProfiler.GetScaledSize(10))
			Item:SetContentAlignment(1)
			Item:SetTextColor(Color(0,0,0,0))
			Item.Paint = function(s, w, h)
				if i % 2 == 0 then
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 10))
				else
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 2))
				end

				if s:IsHovered() then
					GProfiler.RNDX.Draw(0, 0, 0, w, h, Color(255, 255, 255, 20))
				end

				draw.SimpleText(Receiver.Name, "GProfiler.Inter24", GProfiler.GetScaledSize(10), h / 2, GProfiler.SyntaxColors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			List:AddItem(Item)
		end

		Parent.OnHandleMoved = function()
			HeaderPanel:SetSize(Parent:GetWide(), HeaderPanel:GetTall())
			RefreshButton:SetPos(HeaderPanel:GetWide() - RefreshButton:GetWide() - GProfiler.GetScaledSize(10), (HeaderPanel:GetTall() - RefreshButton:GetTall()) / 2)
			List:SetSize(Parent:GetWide(), Parent:GetTall() - HeaderPanel:GetTall())
			List:SetPos(0, HeaderPanel:GetTall())
			for k, v in pairs(List:GetItems()) do
				v:SetSize(List:GetWide(), v:GetTall())
			end
		end
	end

	local CLReceivers = {}
	local SVReceivers = {}

	for name, func in pairs(net.Receivers) do
		local Source = debug.getinfo(func, "S") or {}
		local ReceiverInfo = {
			["Name"] = name,
			["Source"] = Source.short_src or "",
			["LineDefined"] = Source.linedefined or 0,
			["LastLineDefined"] = Source.lastlinedefined or 0
		}
		table.insert(CLReceivers, ReceiverInfo)
	end

	local clr = CreateReceiverList(ClientReceivers, CLReceivers, string.format("Client Receivers (%d)", #CLReceivers))

	net.Receive("GProfiler_Net_ReceiverTbl", function(len, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		SVReceivers = {}
		local Count = net.ReadUInt(32)
		for i = 1, Count do
			local name = net.ReadString()
			local source = net.ReadString()
			local lineDefined = net.ReadUInt(16)
			local lastLineDefined = net.ReadUInt(16)

			local ReceiverInfo = {
				["Name"] = name,
				["Source"] = source,
				["LineDefined"] = lineDefined,
				["LastLineDefined"] = lastLineDefined
			}
			table.insert(SVReceivers, ReceiverInfo)
		end

		local svr = CreateReceiverList(ServerReceivers, SVReceivers, string.format("Server Receivers (%d)", #SVReceivers))
	end)

	net.Start("GProfiler_Net_ReceiverTbl")
	net.SendToServer()
end
GProfiler.Menu.RegisterTab("Networking", "gprofiler/network.png", 2, GProfiler.Net.DoTab, function()
	if Net.StartTime == 0 then return end
	return GProfiler.TimeRunning(Net.StartTime, Net.EndTime, Net.ProfileActive), Net.ProfileActive
end)

net.Receive("GProfiler_Net_SendData", function()
	local isIncoming = net.ReadBool()
	local count = net.ReadUInt(32)

	if not GProfiler.Net.ProfileData.Inc then GProfiler.Net.ProfileData.Inc = {} end
	if not GProfiler.Net.ProfileData.Out then GProfiler.Net.ProfileData.Out = {} end

	local target = isIncoming and GProfiler.Net.ProfileData.Inc or GProfiler.Net.ProfileData.Out
	table.Empty(target)

	for i=1, count do
		local name = net.ReadString()
		local data = {}
		data.Count = net.ReadUInt(32)
		data.MaxSize = net.ReadUInt(32)
		data.TotalSize = net.ReadDouble()
		data.Source = net.ReadString()
		data.LineDefined = net.ReadUInt(16)
		data.LastLineDefined = net.ReadUInt(16)
		data.TotalTime = net.ReadFloat()
		data.LongestTime = net.ReadFloat()
		data.AverageTime = net.ReadFloat()
		target[name] = data
	end

	if GProfiler.Net.RefreshUI then
		GProfiler.Net.RefreshUI()
	end
end)

net.Receive("GProfiler_Net_SendBreakdown", function()
	local name = net.ReadString()
	local found = net.ReadBool()
	if not found then return end

	local totalSize = net.ReadUInt(32)

	local function ReadNode()
		local node = {}
		node.Func = net.ReadString()
		node.Size = net.ReadUInt(32)
		local childCount = net.ReadUInt(16)
		node.Children = {}
		for i=1, childCount do
			node.Children[i] = ReadNode()
		end
		return node
	end

	local rootChildren = {}
	local count = net.ReadUInt(16)
	for i=1, count do
		table.insert(rootChildren, ReadNode())
	end

	GProfiler.Net.Breakdowns = GProfiler.Net.Breakdowns or {}
	GProfiler.Net.Breakdowns[name] = {
		Nodes = rootChildren,
		Size = totalSize
	}

	if GProfiler.Net.UpdateBreakdownUI then
		GProfiler.Net.UpdateBreakdownUI(name)
	end
end)