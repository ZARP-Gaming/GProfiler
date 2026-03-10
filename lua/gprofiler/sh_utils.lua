if CLIENT then
-- 	GProfiler.Menu = GProfiler.Menu or {}

-- 	local MenuColors = GProfiler.MenuColors
-- 	local BorderColor = MenuColors.DListColumnOutline
-- 	local TabPadding = 10

-- 	local draw = draw
-- 	local table = table
-- 	local ipairs = ipairs
-- 	local string = string
-- 	local surface = surface

-- 	local function PaintColumn(s, w, h)
-- 		surface.SetDrawColor(BorderColor.r, BorderColor.g, BorderColor.b, BorderColor.a)
-- 		surface.DrawRect(w - 2, 0, 2, h)
-- 	end

-- 	local function PaintLine(s, w, h)
-- 		if s:IsHovered() then
-- 			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowHover)
-- 		else
-- 			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowBackground)
-- 		end

-- 		if s:IsLineSelected() then
-- 			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListRowSelected)
-- 		end
-- 	end

-- 	local function PaintHeader(s, w, h)
-- 		draw.RoundedBox(1, 0, 0, w, h, MenuColors.DListColumnOutline)
-- 		draw.RoundedBox(1, 1, 1, w - 2, h - 2, MenuColors.DListColumnBackground)

-- 		if s:IsHovered() then
-- 			draw.RoundedBox(1, 0, 0, w, h, MenuColors.DListColumnOutline)
-- 		end
-- 	end

-- 	function GProfiler.StyleDListView(v)
-- 		local Columns = v.Columns
-- 		for k, v1 in ipairs(Columns) do
-- 			v1.Header:SetFont("GProfiler.Menu.ListHeader")
-- 			v1.Header.Paint = PaintHeader
-- 			v1.Header:SetTextColor(MenuColors.White)
-- 		end

-- 		local Lines = v.Lines
-- 		for k, v in ipairs(Lines) do
-- 			local columnCount = table.Count(v.Columns)
-- 			for k, v in ipairs(v.Columns) do
-- 				v:SetTextColor(MenuColors.DListRowTextColor)
-- 				v.Paint = PaintColumn
-- 			end
-- 			v.Paint = PaintLine
-- 		end

-- 		GProfiler.StyleScrollbar(v)

-- 		function v:Paint(w, h)
-- 			draw.RoundedBox(2, 0, 0, w, h, MenuColors.DListBackground)
-- 			surface.SetDrawColor(BorderColor.r, BorderColor.g, BorderColor.b, BorderColor.a)
-- 			surface.DrawOutlinedRect(0, 0, w, h)
-- 		end
-- 	end

-- 	local function PaintGrip(s, w, h)
-- 		draw.RoundedBox(2, 0, 0, w, h, MenuColors.ScrollBarGripOutline)
-- 		draw.RoundedBox(2, 1, 1, w - 2, h - 2, MenuColors.ScrollBarGrip)

-- 		if s:IsHovered() or s.Depressed then
-- 			draw.RoundedBox(2, 0, 0, w, h, MenuColors.ScrollBarGripOutline)
-- 		end
-- 	end

-- 	local function PaintScrollbar(s, w, h)
-- 		draw.RoundedBox(0, 0, 0, w, h, MenuColors.ScrollBar)
-- 	end

-- 	function GProfiler.StyleScrollbar(v)
-- 		local ScrollBar = v.VBar or (v.GetVBar and v:GetVBar()) or nil
-- 		if not IsValid(ScrollBar) then return end
-- 		ScrollBar.btnUp:SetVisible(false)
-- 		ScrollBar.btnDown:SetVisible(false)
-- 		ScrollBar.Paint = PaintScrollbar
-- 		ScrollBar.btnGrip.Paint = PaintGrip
-- 		ScrollBar.PerformLayout = function()
-- 			local wide = ScrollBar:GetWide()
-- 			local scroll = ScrollBar:GetScroll() / ScrollBar.CanvasSize
-- 			local barSize = math.max(ScrollBar:BarScale() * (ScrollBar:GetTall() - (wide * 2)), 10)
-- 			local track = ScrollBar:GetTall() - (wide * 2) - barSize

-- 			ScrollBar.btnGrip:SetPos(0, (wide + (scroll * (track + 3))) - 16)
-- 			ScrollBar.btnGrip:SetSize(wide, barSize + 30)
-- 		end
-- 	end

-- 	function GProfiler.StyleDropdown(v)
-- 		v.Paint = function(s, w, h)
-- 			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
-- 			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

-- 			if s:IsHovered() then
-- 				draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
-- 			end
-- 		end
-- 	end

-- 	local function PaintSeperator(s, w, h)
-- 		draw.RoundedBox(4, 0, 0, w, h, MenuColors.HeaderSeparator)
-- 	end

-- 	function GProfiler.Menu.CreateHeader(parent, text, x, y, w, h, noPadding)
-- 		local TabPadding = noPadding and 0 or TabPadding
-- 		local header = vgui.Create("DPanel", parent)
-- 		header:SetSize(w, h)
-- 		header:SetPos(x, y)
-- 		header.Paint = nil

-- 		local headerText = vgui.Create("DLabel", header)
-- 		headerText:SetFont("GProfiler.Menu.SectionHeader")
-- 		headerText:SetText(text)
-- 		headerText:SizeToContents()
-- 		headerText:SetPos(TabPadding, header:GetTall() / 2 - headerText:GetTall() / 2)
-- 		headerText:SetTextColor(MenuColors.White)

-- 		local separator = vgui.Create("DPanel", header)
-- 		separator:SetSize(header:GetWide() - TabPadding * 2, 1)
-- 		separator:SetPos(TabPadding, header:GetTall() - 1)
-- 		separator.Paint = PaintSeperator

-- 		return header, headerText
-- 	end

-- 	local function PaintRealmSelector(s, w, h)
-- 		draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
-- 		draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

-- 		if s:IsHovered() then
-- 			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonHover)
-- 		end
-- 	end

-- 	function GProfiler.Menu.CreateLabeledInput(parent, labelText, x, y, w, h, textInset)
-- 		textInset = textInset or 0
-- 		local lbl = vgui.Create("DLabel", parent)
-- 		lbl:SetFont("GProfiler.Menu.SectionHeader")
-- 		lbl:SetText(labelText)
-- 		lbl:SizeToContents()
-- 		lbl:SetTextColor(MenuColors.White)
-- 		lbl:SetPos(x, y + 3)

-- 		local input = vgui.Create("DTextEntry", parent)
-- 		input:SetFont("GProfiler.Menu.SectionHeader")
-- 		input:SetText("")
-- 		input:SetSize(w, h)
-- 		input:SetPos(x + lbl:GetWide() + 5, y)
-- 		input:SetTextColor(MenuColors.White)
-- 		function input:Paint(w, h)
-- 			draw.RoundedBox(4, 0, 0, w, h, MenuColors.RealmSelectorOutline)
-- 			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.RealmSelectorBackground)
-- 			local x = draw.SimpleText(self:GetText(), "GProfiler.Menu.FocusEntry", textInset + 5, h / 2, MenuColors.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
-- 			if self:IsEditing() and (x < w - 15) and (SysTime() % 1 > 0.5) then
-- 				local caretPos = self:GetCaretPos()
-- 				local text = self:GetText()
-- 				surface.SetFont("GProfiler.Menu.FocusEntry")
-- 				local textWidth = surface.GetTextSize(text)
-- 				local textWidthBeforeCaret = surface.GetTextSize(string.sub(text, 1, caretPos))
-- 				draw.RoundedBox(0, textInset + textWidthBeforeCaret + 5, 1, 2, h - 2, MenuColors.White)
-- 			end
-- 		end

-- 		return lbl, input
-- 	end

-- 	function GProfiler.Menu.CreateRealmSelector(parent, profiler, x, y, onSelect)
-- 		local Data = GProfiler[profiler]
-- 		local Selected = Data.Realm == "Client" and 1 or 2
-- 		Data.Lerp = Data.Lerp or (Selected - 1)
-- 		local SelectorBase = vgui.Create("DPanel", parent)
-- 		SelectorBase:SetPos(x, y)
-- 		SelectorBase:SetSize(200, parent:GetTall() - 6)
-- 		SelectorBase.Paint = function(s, w, h)
-- 			draw.RoundedBox(4, 0, 0, w, h, MenuColors.ButtonOutline)
-- 			draw.RoundedBox(4, 1, 1, w - 2, h - 2, MenuColors.ButtonBackground)

-- 			local lerp = Lerp(0.1, Data.Lerp, Data.LerpTo or (Selected - 1))
-- 			Data.Lerp = lerp

-- 			draw.RoundedBox(4, 2 + w / 2 * lerp, 2, w / 2 - 4, h - 4, MenuColors.ButtonHover)
-- 		end

-- 		local Realms = {"Client", "Server"}
-- 		for i = 1, 2 do
-- 			local Button = vgui.Create("DButton", SelectorBase)
-- 			Button:SetText(i == 1 and "Client" or "Server")
-- 			Button:SetFont("GProfiler.Menu.RealmSelector")
-- 			Button:SetTextColor(color_white)
-- 			Button:SetSize(SelectorBase:GetWide() / 2, SelectorBase:GetTall())
-- 			Button:SetPos(SelectorBase:GetWide() / 2 * (i - 1), 0)
-- 			Button.Paint = nil
-- 			Button.DoClick = function()
-- 				Selected = i
-- 				Data.LerpTo = i - 1
-- 			end
-- 			Button.Think = function(s)
-- 				if Data.ProfileActive then
-- 					s:SetEnabled(false)
-- 				else
-- 					s:SetEnabled(true)
-- 				end

-- 				if s:IsEnabled() then
-- 					s:SetCursor("hand")
-- 				else
-- 					s:SetCursor("no")
-- 				end
-- 			end

-- 			function Button:DoClick()
-- 				onSelect(self, nil, Realms[i])
-- 			end

-- 			Button.Text = i == 1 and "Client" or "Server"
-- 		end

-- 		return SelectorBase
-- 	end

-- 	function GProfiler.CopyLang(copy)
-- 		copy = string.lower(string.Replace(copy, " ", "_"))
-- 		return string.format("%s %s", GProfiler.Language.GetPhrase("copy"), GProfiler.Language.GetPhrase(copy))
-- 	end

	
else
	
end

-- function GProfiler.GetFunctionLocation(func)
-- 	local info = debug.getinfo(func, "S")
-- 	if info.short_src == "[C]" then return "C" end
-- 	return info.short_src .. ":" .. info.linedefined
-- end

function GProfiler.ExpressAvailable() return !!((express and express.shSend) and GProfiler.Config.UseExpressNetworking) end

GProfiler.Utils = GProfiler.Utils or {}

if SERVER then
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

		if isstring(res) then res = {res} end

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

	return
end

local function GetTabName(tabName) return GProfiler.Language.GetPhrase(string.format("tab_%s", string.gsub(string.lower(tabName), " ", "_"))) end

function GProfiler.Utils.SetupHeader(Outer, Title, Icon, Sub)
	local Header = vgui.Create("DPanel", Outer)
	Header:SetSize(Outer:GetWide(), GProfiler.GetScaledSize(Sub and 50 or 100))
	Header.Paint = function(s, w, h)
		GProfiler.RNDX.Draw(8, 0, 0, w, h, Color(34, 77, 122, 255), GProfiler.RNDX.NO_BL + GProfiler.RNDX.NO_BR)
	end

	local IconPanel
	if Icon then
		local IconMat = Material(Icon, "noclamp smooth")
		local IconSize = GProfiler.GetScaledSize(64) * 0.75
		IconPanel = vgui.Create("DPanel", Header)
		IconPanel:SetSize(GProfiler.GetScaledSize(64), GProfiler.GetScaledSize(64))
		IconPanel:SetPos(GProfiler.GetScaledSize(20), Header:GetTall() / 2 - IconPanel:GetTall() / 2)
		IconPanel.Paint = function(s, w, h)
			GProfiler.RNDX.Draw(4, 0, 0, w, h, Color(22, 50, 80, 255))
			GProfiler.RNDX.Draw(4, 2, 2, w - 4, h - 4, Color(26, 59, 94, 255))
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(IconMat)
			surface.DrawTexturedRect(w / 2 - IconSize / 2, h / 2 - IconSize / 2, IconSize, IconSize)
		end
	end

	local TitleLabel = vgui.Create("DLabel", Header)
	TitleLabel:SetText(Sub and Title or GetTabName(Title))
	TitleLabel:SetTextColor(color_white)
	TitleLabel:SetFont(Sub and "GProfiler.Inter28" or "GProfiler.InnerTitle")
	TitleLabel:SizeToContents()
	TitleLabel:SetMouseInputEnabled(false)
	if Icon then
		TitleLabel:SetPos(IconPanel:GetWide() + IconPanel:GetX() + GProfiler.GetScaledSize(20), Header:GetTall() / 2 - TitleLabel:GetTall() / 2)
	else
		TitleLabel:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() / 2 - TitleLabel:GetTall() / 2)
	end

	local ItemsXOffset = Header:GetWide() - GProfiler.GetScaledSize(20)
	local RNDX = GProfiler.RNDX

	local Button, Selector, Timer

	function Header:SetupStartStop(state)
		local ButtonW = GProfiler.GetScaledSize(155)
		local ButtonH = Header:GetTall() * 0.65

		ItemsXOffset = ItemsXOffset - ButtonW

		Button = vgui.Create("DButton", Header)
		Button:SetSize(ButtonW, ButtonH)
		Button:SetPos(ItemsXOffset, Header:GetTall() / 2 - ButtonH / 2)
		Button:SetTextColor(color_white)
		Button:SetFont("GProfiler.HeaderInteract")
		Button.Paint = function(s, w, h)
			RNDX.Draw(6, 0, 0, w, h, Color(18, 46, 74, 255))
			if s:IsHovered() then
				RNDX.Draw(6, 0, 0, w, h, Color(0, 0, 0, 50))
			end
		end

		Button.State = state
		Button:SetText(state and "Stop" or "Start")

		function Button:DoClick()
			self.State = not self.State
			self:SetText(self.State and "Stop" or "Start")
			if self.OnStateChanged then self:OnStateChanged(self.State) end

			if Selector then
				Selector.Enabled = not self.State
				for k, v in ipairs(Selector:GetChildren()) do
					if v.SetCursor then
						if Selector.Enabled then v:SetCursor("hand")
						else v:SetCursor("no") end
					end
				end
			end
		end

		return Button
	end

	function Header:SetupRealmSelector(IsClient)
		if IsClient == nil then IsClient = true end

		local Width = GProfiler.GetScaledSize(366)
		local Height = Header:GetTall() * 0.65

		ItemsXOffset = ItemsXOffset - Width - GProfiler.GetScaledSize(10)

		Selector = vgui.Create("DPanel", Header)
		Selector:SetSize(Width, Height)
		Selector:SetPos(ItemsXOffset, Header:GetTall() / 2 - Height / 2)

		Selector.State = IsClient and "Client" or "Server"
		Selector.LerpTo = Selector.State == "Client" and 0 or 1
		Selector.LerpPos = Selector.LerpTo
		Selector.IsClient = IsClient
		Selector.Enabled = true

		Selector.Paint = function(s, w, h)
			RNDX.Draw(6, 0, 0, w, h, Color(18, 46, 74, 255))

			local lerp = Lerp(0.1, Selector.LerpPos, Selector.LerpTo)
			Selector.LerpPos = lerp
			local Padding = 6
			local SelectorW = w / 2 - Padding * 2
			RNDX.Draw(6, Padding + (SelectorW * lerp), Padding, SelectorW + (Selector.LerpTo == 1 and Padding * 2 or 0), h - Padding * 2, Color(31, 79, 128, 255))
		end

		local ItemW = Selector:GetWide() / 2

		local Items = {"Client", "Server"}
		for i = 1, 2 do
			local Button = vgui.Create("DButton", Selector)
			Button:SetSize(ItemW, Selector:GetTall())
			Button:SetPos((i - 1) * ItemW, 0)
			Button:SetText(Items[i])
			Button:SetFont("GProfiler.HeaderInteract")
			Button:SetTextColor(color_white)
			Button.Paint = nil

			Button.DoClick = function()
				if not Selector.Enabled then return end

				Selector.LerpTo = i - 1
				Selector.State = Items[i]
				Selector.IsClient = Items[i] == "Client"
				if Selector.OnStateChanged then Selector:OnStateChanged(Selector.State) end
			end
		end

		return Selector
	end

	function Header:SetupTimer(profiler)
		Timer = vgui.Create("DLabel", Header)
		Timer:SetFont("GProfiler.HeaderInteract")
		Timer:SetTextColor(color_white)
		Timer:SetText(GProfiler.TimeRunning(profiler.StartTime or 0, profiler.EndTime or 0, profiler.ProfileActive) .. "s")
		Timer:SizeToContents()
		Timer:SetPos(ItemsXOffset - Timer:GetWide() - GProfiler.GetScaledSize(10), Header:GetTall() / 2 - Timer:GetTall() / 2)

		local OldSetText = Timer.SetText
		function Timer:SetText(text)
			OldSetText(self, text)
			self:SizeToContents()
			self:SetPos(ItemsXOffset - self:GetWide() - GProfiler.GetScaledSize(10), Header:GetTall() / 2 - self:GetTall() / 2)
		end

		function Timer:Think()
			if not profiler.ProfileActive then return end
			self:SetText(GProfiler.TimeRunning(profiler.StartTime or 0, profiler.EndTime or 0, true) .. "s")
		end

		return Timer
	end

	Header.OnHandleMoved = function()
		ItemsXOffset = Header:GetWide() - GProfiler.GetScaledSize(20)
		if Button then
			Button:SetPos(ItemsXOffset - Button:GetWide(), Button:GetY())
			ItemsXOffset = ItemsXOffset - Button:GetWide() - GProfiler.GetScaledSize(10)
		end
		if Selector then
			Selector:SetPos(ItemsXOffset - Selector:GetWide(), Selector:GetY())
			ItemsXOffset = ItemsXOffset - Selector:GetWide() - GProfiler.GetScaledSize(10)
		end
		if Timer then
			Timer:SetPos(ItemsXOffset - Timer:GetWide() - GProfiler.GetScaledSize(10), Timer:GetY())
		end
	end

	return Header
end

function GProfiler.TimeRunning(startTime, endTime, active)
	local time = 0

	if active then
		time = SysTime() - startTime
	else
		time = endTime - startTime
	end

	return string.format("%.2f", time)
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