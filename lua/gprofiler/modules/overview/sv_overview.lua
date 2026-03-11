util.AddNetworkString("GProfiler.OverviewSubscribe")
util.AddNetworkString("GProfiler.OverviewUpdate")

GProfiler.Overview = GProfiler.Overview or {}
GProfiler.Overview.SubscribedPlayers = GProfiler.Overview.SubscribedPlayers or {}

net.Receive("GProfiler.OverviewSubscribe", function(len, ply)
	if not GProfiler.Access.HasAccess(ply) then return end
	local subscribe = net.ReadBool()
	table[subscribe and "insert" or "RemoveByValue"](GProfiler.Overview.SubscribedPlayers, ply)

	GProfiler.Overview.OnSubscriptionUpdate()
end)

function GProfiler.Overview.OnSubscriptionUpdate()
	if #GProfiler.Overview.SubscribedPlayers == 0 then timer.Remove("GProfiler.Overview.SendData") return end
	if timer.Exists("GProfiler.Overview.SendData") then return end

	timer.Create("GProfiler.Overview.SendData", 0, 0, function()
		for i = #GProfiler.Overview.SubscribedPlayers, 1, -1 do
			if not IsValid(GProfiler.Overview.SubscribedPlayers[i]) then
				table.remove(GProfiler.Overview.SubscribedPlayers, i)
			end
		end

		if #GProfiler.Overview.SubscribedPlayers == 0 then timer.Remove("GProfiler.Overview.SendData") return end

		net.Start("GProfiler.OverviewUpdate")
			net.WriteFloat(FrameTime())
			net.WriteFloat(physenv.GetLastSimulationTime())
			net.WriteUInt(collectgarbage("count"), 32)
		net.Send(GProfiler.Overview.SubscribedPlayers)
	end)
end
