GProfiler.AutoProfile = GProfiler.AutoProfile or {}
GProfiler.AutoProfile.States = GProfiler.AutoProfile.States or {}

net.Receive("GProfiler.AutoProfile.SendState", function()
	local count = net.ReadUInt(8)
	for i = 1, count do
		GProfiler.AutoProfile.States[net.ReadString()] = net.ReadUInt(2)
	end
end)
