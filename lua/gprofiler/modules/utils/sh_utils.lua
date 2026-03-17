GProfiler.Utils = GProfiler.Utils or {}

function GProfiler.ExpressAvailable() return !!((express and express.shSend) and GProfiler.Config.UseExpressNetworking) end

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

	function Header:SetupRealmSelector(currentState, includeBoth)
		if isbool(currentState) then
			currentState = currentState and "Client" or "Server"
		end
		currentState = currentState or "Client"

		local Items = {"Client", "Server"}
		if includeBoth then table.insert(Items, "Both") end
		local numItems = #Items

		local Width = GProfiler.GetScaledSize(183) * numItems
		local Height = Header:GetTall() * 0.65

		ItemsXOffset = ItemsXOffset - Width - GProfiler.GetScaledSize(10)

		Selector = vgui.Create("DPanel", Header)
		Selector:SetSize(Width, Height)
		Selector:SetPos(ItemsXOffset, Header:GetTall() / 2 - Height / 2)

		local initialIndex = 1
		for i, item in ipairs(Items) do
			if item == currentState then initialIndex = i; break end
		end

		Selector.State = currentState
		Selector.LerpTo = (initialIndex - 1) / math.max(1, numItems - 1)
		Selector.LerpPos = Selector.LerpTo
		Selector.IsClient = currentState == "Client"
		Selector.Enabled = true

		Selector.Paint = function(s, w, h)
			RNDX.Draw(6, 0, 0, w, h, Color(18, 46, 74, 255))

			local lerp = Lerp(0.1, Selector.LerpPos, Selector.LerpTo)
			Selector.LerpPos = lerp
			local Padding = 6
			local SelectorW = (w - Padding * 2) / numItems
			local SelectorX = Padding + lerp * (w - SelectorW - Padding * 2)
			RNDX.Draw(6, SelectorX, Padding, SelectorW, h - Padding * 2, Color(31, 79, 128, 255))
		end

		local ItemW = Selector:GetWide() / numItems

		for i, item in ipairs(Items) do
			local Button = vgui.Create("DButton", Selector)
			Button:SetSize(ItemW, Selector:GetTall())
			Button:SetPos((i - 1) * ItemW, 0)
			Button:SetText(item)
			Button:SetFont("GProfiler.HeaderInteract")
			Button:SetTextColor(color_white)
			Button.Paint = nil

			Button.DoClick = function()
				if not Selector.Enabled then return end

				Selector.LerpTo = (i - 1) / math.max(1, numItems - 1)
				Selector.State = item
				Selector.IsClient = item == "Client"
				if Selector.OnStateChanged then Selector:OnStateChanged(Selector.State) end
			end
		end

		return Selector
	end

	function Header:SetupTimer(getter)
		local profiler = getter()
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
			local p = getter()
			self:SetText(GProfiler.TimeRunning(p.StartTime or 0, p.EndTime or 0, p.ProfileActive) .. "s")
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

