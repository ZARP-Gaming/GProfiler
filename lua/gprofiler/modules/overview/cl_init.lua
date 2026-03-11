GProfiler.Overview = GProfiler.Overview or {}

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

function GProfiler.Overview.DoTab(Base)
	GProfiler.Overview.StartUpdating()

	net.Start("GProfiler.OverviewSubscribe")
	net.WriteBool(true)
	net.SendToServer()

	Base.OnRemove = function(s)
		net.Start("GProfiler.OverviewSubscribe")
		net.WriteBool(false)
		net.SendToServer()
	end

	local Container = vgui.Create("DPanel", Base)
	Container:Dock(FILL)
	Container.Paint = nil

	local TopPnl, BottomPnl = GProfiler.Utils.HSplitPanel(Container, 4, "overview_split", 0.5)

	local function AddHeader(pnl, title, icon)
		local header, lbl = GProfiler.Menu.CreateHeader(pnl, title, 0, 0, pnl:GetWide(), 32, true)
		header:Dock(TOP)

		if IsValid(lbl) and icon then
			local iconImg = vgui.Create("DImage", header)
			iconImg:SetImage(icon)
			iconImg:SetSize(20, 20)
			iconImg:SetPos(8, 6)

			local x, y = lbl:GetPos()
			lbl:SetPos(36, y)
		end
		return header
	end

	local function AddGraphEntry(parent, title, queue, color, suffix, formatter)
		local g = vgui.Create("GP.Graph", parent)
		g:Dock(TOP)
		g:SetTall(150)
		g:DockMargin(8, 8, 8, 0)
		g:SetTitle(title)
		g:AddSegment(queue, color, suffix, formatter)
		return g
	end

	-- AddHeader(TopPnl, "Client Performance", "icon16/monitor.png")
	local ClientScroll = vgui.Create("DScrollPanel", TopPnl)
	ClientScroll:Dock(FILL)

	AddGraphEntry(ClientScroll, "Frametime", GProfiler.Overview.Data.CL.Frametime, Color(48, 160, 220), " ms", function(v) return string.format("%.2f", v * 1000) end)
	AddGraphEntry(ClientScroll, "Simtime", GProfiler.Overview.Data.CL.Simtime, Color(220, 160, 48), " ms", function(v) return string.format("%.2f", v * 1000) end)
	AddGraphEntry(ClientScroll, "Memory", GProfiler.Overview.Data.CL.MemUsage, Color(160, 48, 220), " MiB", function(v) return string.format("%.1f", v / 1024) end)
	AddGraphEntry(ClientScroll, "FPS", GProfiler.Overview.Data.CL.FPS, Color(48, 220, 160), " FPS", function(v) return string.format("%.0f", v) end)

	-- AddHeader(BottomPnl, "Server Performance", "icon16/server.png")
	local ServerScroll = vgui.Create("DScrollPanel", BottomPnl)
	ServerScroll:Dock(FILL)

	AddGraphEntry(ServerScroll, "Frametime", GProfiler.Overview.Data.SV.Frametime, Color(220, 80, 80), " ms", function(v) return string.format("%.2f", v * 1000) end)
	AddGraphEntry(ServerScroll, "Simtime", GProfiler.Overview.Data.SV.Simtime, Color(220, 140, 60), " ms", function(v) return string.format("%.2f", v * 1000) end)
	AddGraphEntry(ServerScroll, "Memory", GProfiler.Overview.Data.SV.MemUsage, Color(140, 60, 220), " MiB", function(v) return string.format("%.1f", v / 1024) end)
end

GProfiler.Menu.RegisterTab("Overview", "gprofiler/home.png", 0, GProfiler.Overview.DoTab, function()

end)

net.Receive("GProfiler.OverviewUpdate", function()
	GProfiler.Overview.Data.SV.Frametime:Add(net.ReadFloat())
	GProfiler.Overview.Data.SV.Simtime:Add(net.ReadFloat())
	GProfiler.Overview.Data.SV.MemUsage:Add(net.ReadUInt(32))

	-- print(string.format("Server - Frametime: %.2fms, Simtime: %.2fms, MemUsage: %.2fmb",
	-- 	GProfiler.Overview.Data.SV.Frametime:Average() * 1000,
	-- 	GProfiler.Overview.Data.SV.Simtime:Average() * 1000,
	-- 	GProfiler.Overview.Data.SV.MemUsage:Average() / 1024
	-- ))
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

		-- print(string.format("Client - Frametime: %.2fms, Simtime: %.2fms, MemUsage: %.2fmb, FPS: %.2f",
		-- 	GProfiler.Overview.Data.CL.Frametime:Average() * 1000,
		-- 	GProfiler.Overview.Data.CL.Simtime:Average() * 1000,
		-- 	GProfiler.Overview.Data.CL.MemUsage:Average() / 1024,
		-- 	GProfiler.Overview.Data.CL.FPS:Average()
		-- ))
	end)
end