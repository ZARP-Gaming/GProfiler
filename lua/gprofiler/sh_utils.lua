if CLIENT then
	GProfiler.Menu = GProfiler.Menu or {}

	local MenuColors = GProfiler.MenuColors
	local BorderColor = MenuColors.DListColumnOutline
	local TabPadding = 10

	local draw = draw
	local table = table
	local ipairs = ipairs
	local string = string
	local surface = surface

	local function PaintColumn(s, w, h)
		surface.SetDrawColor(BorderColor.r, BorderColor.g, BorderColor.b, BorderColor.a)
		surface.DrawRect(w - 2, 0, 2, h)
	end

	local function PaintLine(s, w, h)
		if s:IsHovered() then
			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowHover)
		else
			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowBackground)
		end

		if s:IsLineSelected() then
			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowSelected)
		end
	end

	local function PaintHeader(s, w, h)
		draw.RoundedBox(1, 0, 0, w, h, MenuColors.DListColumnOutline)
		draw.RoundedBox(1, 1, 1, w - 2, h - 2, MenuColors.DListColumnBackground)

		if s:IsHovered() then
			draw.RoundedBox(1, 0, 0, w, h, MenuColors.DListColumnOutline)
		end
	end

	function GProfiler.StyleDListView(v)
		local Columns = v.Columns
		for k, v1 in ipairs(Columns) do
			v1.Header:SetFont("GProfiler.Menu.ListHeader")
			v1.Header.Paint = PaintHeader
			v1.Header:SetTextColor(MenuColors.White)
		end

		local Lines = v.Lines
		for k, v in ipairs(Lines) do
			local columnCount = table.Count(v.Columns)
			for k, v in ipairs(v.Columns) do
				v:SetTextColor(MenuColors.DListRowTextColor)
				v.Paint = PaintColumn
			end
			v.Paint = PaintLine
		end

		GProfiler.StyleScrollbar(v)

		function v:Paint(w, h)
			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListBackground)
			surface.SetDrawColor(BorderColor.r, BorderColor.g, BorderColor.b, BorderColor.a)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	local function PaintGrip(s, w, h)
		draw.RoundedBox(2, 0, 0, w, h, MenuColors.ScrollBarGripOutline)
		draw.RoundedBox(2, 1, 1, w - 2, h - 2, MenuColors.ScrollBarGrip)

		if s:IsHovered() or s.Depressed then
			draw.RoundedBox(2, 0, 0, w, h, MenuColors.ScrollBarGripOutline)
		end
	end

	local function PaintScrollbar(s, w, h)
		draw.RoundedBox(0, 0, 0, w, h, MenuColors.ScrollBar)
	end

	function GProfiler.StyleScrollbar(v)
		local ScrollBar = v.VBar or (v.GetVBar and v:GetVBar()) or nil
		if not IsValid(ScrollBar) then return end
		ScrollBar.btnUp:SetVisible(false)
		ScrollBar.btnDown:SetVisible(false)
		ScrollBar.Paint = PaintScrollbar
		ScrollBar.btnGrip.Paint = PaintGrip
		ScrollBar.PerformLayout = function()
			local wide = ScrollBar:GetWide()
			local scroll = ScrollBar:GetScroll() / ScrollBar.CanvasSize
			local barSize = math.max(ScrollBar:BarScale() * (ScrollBar:GetTall() - (wide * 2)), 10)
			local track = ScrollBar:GetTall() - (wide * 2) - barSize

			ScrollBar.btnGrip:SetPos(0, (wide + (scroll * (track + 3))) - 16)
			ScrollBar.btnGrip:SetSize(wide, barSize + 30)
		end
	end

	function GProfiler.StyleDropdown(v)
		v.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

			if s:IsHovered() then
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
			end
		end
	end

	local function PaintSeperator(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.HeaderSeparator)
	end

	function GProfiler.Menu.CreateHeader(parent, text, x, y, w, h, noPadding)
		local TabPadding = noPadding and 0 or TabPadding
		local header = vgui.Create("DPanel", parent)
		header:SetSize(w, h)
		header:SetPos(x, y)
		header.Paint = nil

		local headerText = vgui.Create("DLabel", header)
		headerText:SetFont("GProfiler.Menu.SectionHeader")
		headerText:SetText(text)
		headerText:SizeToContents()
		headerText:SetPos(TabPadding, header:GetTall() / 2 - headerText:GetTall() / 2)
		headerText:SetTextColor(MenuColors.White)

		local separator = vgui.Create("DPanel", header)
		separator:SetSize(header:GetWide() - TabPadding * 2, 1)
		separator:SetPos(TabPadding, header:GetTall() - 1)
		separator.Paint = PaintSeperator

		return header, headerText
	end

	local function PaintRealmSelector(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
		draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

		if s:IsHovered() then
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
		end
	end

	function GProfiler.Menu.CreateLabeledInput(parent, labelText, x, y, w, h, textInset)
		textInset = textInset or 0
		local lbl = vgui.Create("DLabel", parent)
		lbl:SetFont("GProfiler.Menu.SectionHeader")
		lbl:SetText(labelText)
		lbl:SizeToContents()
		lbl:SetTextColor(MenuColors.White)
		lbl:SetPos(x, y + 3)

		local input = vgui.Create("DTextEntry", parent)
		input:SetFont("GProfiler.Menu.SectionHeader")
		input:SetText("")
		input:SetSize(w, h)
		input:SetPos(x + lbl:GetWide() + 5, y)
		input:SetTextColor(MenuColors.White)
		function input:Paint(w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.RealmSelectorOutline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.RealmSelectorBackground)
			local x = draw.SimpleText(self:GetText(), "GProfiler.Menu.FocusEntry", textInset + 5, h / 2, MenuColors.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			if self:IsEditing() and (x < w - 15) and (SysTime() % 1 > 0.5) then
				local caretPos = self:GetCaretPos()
				local text = self:GetText()
				surface.SetFont("GProfiler.Menu.FocusEntry")
				local textWidth = surface.GetTextSize(text)
				local textWidthBeforeCaret = surface.GetTextSize(string.sub(text, 1, caretPos))
				draw.RoundedBox(0, textInset + textWidthBeforeCaret + 5, 1, 2, h - 2, MenuColors.White)
			end
		end

		return lbl, input
	end

	function GProfiler.Menu.CreateRealmSelector(parent, profiler, x, y, onSelect)
		local Data = GProfiler[profiler]
		local Selected = Data.Realm == "Client" and 1 or 2
		Data.Lerp = Data.Lerp or (Selected - 1)
		local SelectorBase = vgui.Create("DPanel", parent)
		SelectorBase:SetPos(x, y)
		SelectorBase:SetSize(200, parent:GetTall() - 6)
		SelectorBase.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

			local lerp = Lerp(0.1, Data.Lerp, Data.LerpTo or (Selected - 1))
			Data.Lerp = lerp

			draw.RoundedBox(4, 2 + w / 2 * lerp, 2, w / 2 - 4, h - 4, MenuColors.ButtonHover)
		end

		local Realms = {"Client", "Server"}
		for i = 1, 2 do
			local Button = vgui.Create("DButton", SelectorBase)
			Button:SetText(i == 1 and "Client" or "Server")
			Button:SetFont("GProfiler.Menu.RealmSelector")
			Button:SetTextColor(color_white)
			Button:SetSize(SelectorBase:GetWide() / 2, SelectorBase:GetTall())
			Button:SetPos(SelectorBase:GetWide() / 2 * (i - 1), 0)
			Button.Paint = nil
			Button.DoClick = function()
				Selected = i
				Data.LerpTo = i - 1
			end
			Button.Think = function(s)
				if Data.ProfileActive then
					s:SetEnabled(false)
				else
					s:SetEnabled(true)
				end

				if s:IsEnabled() then
					s:SetCursor("hand")
				else
					s:SetCursor("no")
				end
			end

			function Button:DoClick()
				onSelect(self, nil, Realms[i])
			end

			Button.Text = i == 1 and "Client" or "Server"
		end

		return SelectorBase
	end

	function GProfiler.TimeRunning(start, endd, profileActive)
		local time = 0

		if profileActive then
			time = SysTime() - start
		else
			time = endd - start
		end

		return string.format("%.2f", time)
	end

	function GProfiler.CopyLang(copy)
		copy = string.lower(string.Replace(copy, " ", "_"))
		return string.format("%s %s", GProfiler.Language.GetPhrase("copy"), GProfiler.Language.GetPhrase(copy))
	end

	function GProfiler.RequestFunctionSource(file, lineStart, lineEnd, callback)
		net.Start("GProfiler_RequestFunctionSource")
		net.WriteString(file)
		net.WriteUInt(lineStart, 32)
		net.WriteUInt(lineEnd, 32)
		net.SendToServer()

		local lines = {}
		net.Receive("GProfiler_RequestFunctionSource", function()
			local isFirst = net.ReadBool()
			local isLast = net.ReadBool()
			local count = net.ReadUInt(32)
			for i = 1, count do
				table.insert(lines, net.ReadString())
			end

			if isLast then
				callback(lines)
			end
		end)
	end
else
	util.AddNetworkString("GProfiler_RequestFunctionSource")

	local chunkSizeLimit = 65535
	net.Receive("GProfiler_RequestFunctionSource", function(l, ply)
		if not GProfiler.Access.HasAccess(ply) then return end

		local f = net.ReadString()
		local start = net.ReadUInt(32)
		local endd = net.ReadUInt(32)

		local res = GProfiler.ReadFunctionSource(f, start, endd)
		local chunkCount = 1
		local currentChunkSize = 0
		local chunks = {}

		if type(res) == "string" then res = {res} end

		for k, v in ipairs(res) do
			local str = string.Replace(v, "\t", "    ")
			if currentChunkSize + string.len(str) > (chunkSizeLimit - 1300) then
				chunkCount = chunkCount + 1
				currentChunkSize = 0
			end

			if not chunks[chunkCount] then chunks[chunkCount] = {} end
			table.insert(chunks[chunkCount], str)
			currentChunkSize = currentChunkSize + string.len(str)
		end

		for k, v in ipairs(chunks) do
			net.Start("GProfiler_RequestFunctionSource")
			net.WriteBool(k == 1)
			net.WriteBool(k == table.Count(chunks))
			net.WriteUInt(table.Count(v), 32)
			for k, v1 in ipairs(v) do
				net.WriteString(v1)
			end
			net.Send(ply)
		end
	end)

	function GProfiler.ReadFunctionSource(f, start, endd)
		if f == "[C]" then return "Cannot get source for C functions!" end
		if not file.Exists(f, "GAME") then return "File not found" end
		if start < 0 or endd < 0 or endd < start then return "" end

		local f = file.Open(f, "r", "GAME")

		for i = 1, start - 1 do f:ReadLine() end

		local lines = {}
		for i = start, endd do table.insert(lines, f:ReadLine() or "") end

		f:Close()

		return lines
	end
end

function GProfiler.GetFunctionLocation(func)
	local info = debug.getinfo(func, "S")
	if info.short_src == "[C]" then return "C" end
	return info.short_src .. ":" .. info.linedefined
end

function GProfiler.ExpressAvailable() return !!((express and express.shSend) and GProfiler.Config.UseExpressNetworking) end
