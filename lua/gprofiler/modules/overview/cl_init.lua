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
		if next(GProfiler.Utils.Graphs.Pinned) then return end
		net.Start("GProfiler.OverviewSubscribe")
		net.WriteBool(false)
		net.SendToServer()
	end

	local Container = vgui.Create("DPanel", Base)
	Container:Dock(FILL)
	Container.Paint = nil

	local Scroll = vgui.Create("DScrollPanel", Container)
	Scroll:Dock(FILL)

	local function AddGraph(title)
		local g = vgui.Create("GP.Graph", Scroll)
		g:Dock(TOP)
		g:SetTall(150)
		g:DockMargin(8, 8, 8, 0)
		g:SetTitle(title)
		return g
	end

	local g = AddGraph("Frametime")
	g:AddSegment(GProfiler.Overview.Data.SV.Frametime, Color(220, 80, 80), "ms (SV)", function(v) return string.format("%.2f", v * 1000) end, "icon16/server.png")
	g:AddSegment(GProfiler.Overview.Data.CL.Frametime, Color(48, 160, 220), "ms (CL)", function(v) return string.format("%.2f", v * 1000) end, "icon16/monitor.png")

	g = AddGraph("Simulation Time")
	g:AddSegment(GProfiler.Overview.Data.CL.Simtime, Color(220, 160, 48), "ms (CL)", function(v) return string.format("%.2f", v * 1000) end, "icon16/monitor.png")
	g:AddSegment(GProfiler.Overview.Data.SV.Simtime, Color(255, 120, 0), "ms (SV)", function(v) return string.format("%.2f", v * 1000) end, "icon16/server.png")

	g = AddGraph("Memory Usage")
	g:AddSegment(GProfiler.Overview.Data.CL.MemUsage, Color(160, 48, 220), "MiB (CL)", function(v) return string.format("%.1f", v / 1024) end, "icon16/monitor.png")
	g:AddSegment(GProfiler.Overview.Data.SV.MemUsage, Color(255, 48, 160), "MiB (SV)", function(v) return string.format("%.1f", v / 1024) end, "icon16/server.png")

	g = AddGraph("Client FPS")
	g:AddSegment(GProfiler.Overview.Data.CL.FPS, Color(48, 220, 160), "FPS", function(v) return string.format("%.0f", v) end, "icon16/monitor.png")
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