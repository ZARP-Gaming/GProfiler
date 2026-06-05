GProfiler.Overview = GProfiler.Overview or {}

local COL_CARD = Color(38, 63, 89, 255)
local COL_HEADER = Color(34, 77, 122, 255)
local COL_INPUT = Color(18, 46, 74, 255)
local COL_SUBTLE = Color(255, 255, 255, 8)
local COL_TEXT = Color(235, 240, 248)
local COL_SUBTEXT = Color(150, 175, 205)
local COL_SV = Color(220, 80, 80)
local COL_CL = Color(48, 160, 220)

local AutoProfileOptions = {
	{ label = "Disabled", value = 0 },
	{ label = "As soon as possible", value = 1 },
	{ label = "When gamemode is loaded", value = 2 },
	{ label = "When a player joins", value = 3 },
}

local function CreateQueue(name, defaultCapacity)
	local SavedCapacity = cookie.GetNumber("gprofiler_overview_" .. name .. "_capacity", defaultCapacity)
	return GProfiler.Utils.Graphs.ConstantLengthNumericalQueue(SavedCapacity)
end

hook.Add("GProfiler.Loaded", "GProfiler.Overview.Init", function()
	GProfiler.Overview.Data = GProfiler.Overview.Data or {
		CL = {
			Frametime = CreateQueue("cl_frametime", 512),
			Simtime = CreateQueue("cl_simtime", 512),
			MemUsage = CreateQueue("cl_memusage", 512),
			FPS = CreateQueue("cl_fps", 512)
		},
		SV = {
			Frametime = CreateQueue("sv_frametime", 512),
			Simtime = CreateQueue("sv_simtime", 512),
			MemUsage = CreateQueue("sv_memusage", 512)
		}
	}
end)

local function qLast(q)
	local len = q:Length()
	return len > 0 and q:Get(len - 1) or 0
end

local function fmtUptime(secs)
	secs = math.floor(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then return string.format("%dh %dm %ds", h, m, s) end
	if m > 0 then return string.format("%dm %ds", m, s) end
	return string.format("%ds", s)
end

local function StyleCombo(combo)
	local RNDX = GProfiler.RNDX
	combo:SetFont("GProfiler.Inter24")
	combo:SetTextColor(COL_TEXT)
	combo:SetSortItems(false)
	combo.Paint = function(s, w, h)
		RNDX.Draw(4, 0, 0, w, h, COL_INPUT)
		if s:IsHovered() or s:IsMenuOpen() then
			RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 12))
		end
		draw.SimpleText("▾", "GProfiler.Inter24", w - GProfiler.GetScaledSize(8), h / 2, COL_SUBTEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
	for _, opt in ipairs(AutoProfileOptions) do
		combo:AddChoice(opt.label, opt.value)
	end
	return combo
end

function GProfiler.Overview.DoTab(Base, Outer)
	local RNDX = GProfiler.RNDX

	GProfiler.Overview.StartUpdating()

	net.Start("GProfiler.OverviewSubscribe")
	net.WriteBool(true)
	net.SendToServer()

	Base.OnRemove = function(s)
		if next(GProfiler.Utils.Graphs.Pinned) then return end
		net.Start("GProfiler.OverviewSubscribe")
		net.WriteBool(false)
		net.SendToServer()
	end

	local Data = GProfiler.Overview.Data
	local pad = GProfiler.GetScaledSize(8)

	local Scroll = vgui.Create("DScrollPanel", Base)
	Scroll:Dock(FILL)
	Scroll:DockMargin(pad, pad, pad, pad)
	local sbar = Scroll.VBar
	sbar:SetWide(GProfiler.GetScaledSize(12))
	sbar:SetHideButtons(true)
	sbar.Paint = function(s, w, h) RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 10)) end
	sbar.btnGrip.Paint = function(s, w, h) RNDX.Draw(4, 0, 0, w, h, Color(255, 255, 255, 20)) end

	local function AddSection(title, first)
		local Sec = vgui.Create("DPanel", Scroll)
		Sec:Dock(TOP)
		Sec:DockMargin(0, first and GProfiler.GetScaledSize(2) or GProfiler.GetScaledSize(24), 0, GProfiler.GetScaledSize(4))
		Sec:SetTall(GProfiler.GetScaledSize(36))
		Sec.Paint = function(s, w, h)
			RNDX.Draw(6, 0, 0, w, h, COL_HEADER)
			draw.SimpleText(title, "GProfiler.Inter28", GProfiler.GetScaledSize(12), h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		return Sec
	end

	AddSection("Server", true)

	local infoRows = {
		{ "Map", function() return game.GetMap() end },
		{ "Gamemode", function() return (GAMEMODE and GAMEMODE.Name) or engine.ActiveGamemode() end },
		{ "Players", function() return player.GetCount() .. " / " .. game.MaxPlayers() end },
		{ "Tickrate", function() return string.format("%.0f", 1 / engine.TickInterval()) end },
		{ "Uptime", function() return fmtUptime(CurTime()) end },
	}

	local InfoCard = vgui.Create("DPanel", Scroll)
	InfoCard:Dock(TOP)
	InfoCard:SetTall(GProfiler.GetScaledSize(60))
	InfoCard.Paint = function(s, w, h)
		RNDX.Draw(6, 0, 0, w, h, COL_CARD)
		local n = #infoRows
		local cw = w / n
		for i, row in ipairs(infoRows) do
			local cx = (i - 1) * cw
			if i > 1 then
				surface.SetDrawColor(255, 255, 255, 12)
				surface.DrawRect(cx, GProfiler.GetScaledSize(12), 1, h - GProfiler.GetScaledSize(24))
			end
			draw.SimpleText(row[1], "GProfiler.Inter24", cx + GProfiler.GetScaledSize(16), h / 2 - GProfiler.GetScaledSize(12), COL_SUBTEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(tostring(row[2]() or "?"), "GProfiler.Inter28", cx + GProfiler.GetScaledSize(16), h / 2 + GProfiler.GetScaledSize(11), COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	AddSection("Graphs")

	local function AddGraph(title)
		local g = vgui.Create("GP.Graph", Scroll)
		g:Dock(TOP)
		g:SetTall(GProfiler.GetScaledSize(150))
		g:DockMargin(0, 0, 0, pad)
		g:SetTitle(title)
		return g
	end

	local g = AddGraph("Frametime")
	g:AddSegment(Data.SV.Frametime, COL_SV, "ms (SV)", function(v) return string.format("%.2f", v * 1000) end, "icon16/server.png")
	g:AddSegment(Data.CL.Frametime, COL_CL, "ms (CL)", function(v) return string.format("%.2f", v * 1000) end, "icon16/monitor.png")

	g = AddGraph("Simulation Time")
	g:AddSegment(Data.SV.Simtime, Color(255, 120, 0), "ms (SV)", function(v) return string.format("%.2f", v * 1000) end, "icon16/server.png")
	g:AddSegment(Data.CL.Simtime, Color(220, 160, 48), "ms (CL)", function(v) return string.format("%.2f", v * 1000) end, "icon16/monitor.png")

	g = AddGraph("Memory Usage")
	g:AddSegment(Data.SV.MemUsage, Color(255, 48, 160), "MiB (SV)", function(v) return string.format("%.1f", v / 1024) end, "icon16/server.png")
	g:AddSegment(Data.CL.MemUsage, Color(160, 48, 220), "MiB (CL)", function(v) return string.format("%.1f", v / 1024) end, "icon16/monitor.png")

	g = AddGraph("Client FPS")
	g:AddSegment(Data.CL.FPS, Color(48, 220, 160), "FPS", function(v) return string.format("%.0f", v) end, "icon16/monitor.png")

	AddSection("Auto Profile")

	local AP = GProfiler.AutoProfile
	for name, profiler in SortedPairs(GProfiler.Profilers.GetAll()) do
		local hasCL = table.HasValue(profiler.Realms, "Client")
		local hasSV = table.HasValue(profiler.Realms, "Server")
		if not hasCL and not hasSV then continue end

		local Row = vgui.Create("DPanel", Scroll)
		Row:Dock(TOP)
		Row:DockMargin(0, GProfiler.GetScaledSize(4), 0, 0)
		Row:SetTall(GProfiler.GetScaledSize(44))
		Row.Paint = function(s, w, h)
			RNDX.Draw(4, 0, 0, w, h, COL_SUBTLE)
		end

		local NameLabel = vgui.Create("DLabel", Row)
		NameLabel:Dock(LEFT)
		NameLabel:DockMargin(GProfiler.GetScaledSize(12), 0, 0, 0)
		NameLabel:SetFont("GProfiler.Inter24")
		NameLabel:SetText(name)
		NameLabel:SetTextColor(COL_TEXT)
		NameLabel:SizeToContents()

		local function AddRealmCombo(realmLabel, accent, getState, setState)
			local Wrap = vgui.Create("DPanel", Row)
			Wrap:Dock(RIGHT)
			Wrap:DockMargin(GProfiler.GetScaledSize(8), GProfiler.GetScaledSize(8), GProfiler.GetScaledSize(8), GProfiler.GetScaledSize(8))
			Wrap:SetWide(GProfiler.GetScaledSize(250))
			Wrap.Paint = nil

			local Tag = vgui.Create("DLabel", Wrap)
			Tag:Dock(LEFT)
			Tag:DockMargin(0, 0, GProfiler.GetScaledSize(6), 0)
			Tag:SetFont("GProfiler.Inter24")
			Tag:SetText(realmLabel)
			Tag:SetTextColor(accent)
			Tag:SetWide(GProfiler.GetScaledSize(30))

			local Combo = vgui.Create("DComboBox", Wrap)
			Combo:Dock(FILL)
			StyleCombo(Combo)
			Combo:ChooseOptionID((getState() or 0) + 1)
			Combo.OnSelect = function(s, index, value, data)
				setState(name, data)
			end
		end

		if hasSV then
			AddRealmCombo("SV", COL_SV, function() return AP.GetServerState(name) end, AP.SetServerState)
		end
		if hasCL then
			AddRealmCombo("CL", COL_CL, function() return AP.GetClientState(name) end, AP.SetClientState)
		end
	end

	local Spacer = vgui.Create("DPanel", Scroll)
	Spacer:Dock(TOP)
	Spacer:SetTall(GProfiler.GetScaledSize(12))
	Spacer.Paint = nil
end

GProfiler.Menu.RegisterTab("Overview", "gprofiler/home.png", 0, GProfiler.Overview.DoTab, function() end)

net.Receive("GProfiler.OverviewUpdate", function()
	GProfiler.Overview.Data.SV.Frametime:Add(net.ReadFloat())
	GProfiler.Overview.Data.SV.Simtime:Add(net.ReadFloat())
	GProfiler.Overview.Data.SV.MemUsage:Add(net.ReadUInt(32))
end)

function GProfiler.Overview.StartUpdating()
	local lastUpdate = 0
	local updateInterval = .025
	hook.Add("Think", "GProfiler.Overview.UpdateData", function()
		if CurTime() - lastUpdate < updateInterval then return end
		lastUpdate = CurTime()
		GProfiler.Overview.Data.CL.Frametime:Add(FrameTime())
		GProfiler.Overview.Data.CL.Simtime:Add(physenv.GetLastSimulationTime())
		GProfiler.Overview.Data.CL.MemUsage:Add(collectgarbage("count"))
		GProfiler.Overview.Data.CL.FPS:Add(1 / FrameTime())
	end)
end
