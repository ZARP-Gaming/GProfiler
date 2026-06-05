GProfiler.Utils.Graphs = GProfiler.Utils.Graphs or {}

function GProfiler.Utils.Graphs.ConstantLengthNumericalQueue(capacity)
	-- Thanks to https://github.com/ACF-Team/ACF-3-DevTools
	local obj = {}
	obj.Divisor = 1

	local pointer = 0
	local length = 0
	local startat = 0
	local backing = {}
	for i = 1, capacity do backing[i - 1] = 0 end

	function obj:Add(item)
		if length < capacity then
			length = length + 1
		else
			startat = startat + 1
			if startat >= capacity then startat = 0 end
		end

		if pointer >= capacity then pointer = pointer % capacity end

		backing[pointer] = item
		pointer = pointer + 1
	end

	function obj:Length() return length end
	function obj:Start() return startat end
	function obj:Get(i) return backing[(i + startat) % capacity] / self.Divisor end

	function obj:Min()
		local ret = math.huge
		for i = 1, length do ret = math.min(ret, backing[i - 1]) end
		return ret / self.Divisor
	end

	function obj:Max()
		local ret = 0
		for i = 1, length do ret = math.max(ret, backing[i - 1]) end
		return ret / self.Divisor
	end

	function obj:Average()
		local ret = 0
		for i = 1, length do ret = ret + backing[i - 1] end
		return ret / length / self.Divisor
	end

	function obj:Resize(newCapacity)
		if newCapacity == capacity then return end

		local newBacking = {}
		for i = 1, newCapacity do newBacking[i - 1] = 0 end

		for i = 1, math.min(length, newCapacity) do
			newBacking[i - 1] = backing[(startat + i - 1) % capacity]
		end

		backing = newBacking
		capacity = newCapacity
		startat = 0
		pointer = math.min(length, newCapacity)
		length = math.min(length, newCapacity)
	end

	return obj
end

function GProfiler.Utils.Graphs.Render(x, y, w, h, title, visualMax, mainIcon, segments, isPinned)
	draw.RoundedBox(8, x, y, w, h, Color(16, 16, 24, isPinned and 200 or 255))

	local titleX = x + 16
	if mainIcon then
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(mainIcon)
		surface.DrawTexturedRect(x + 16, y + 16, 20, 20)
		titleX = titleX + 20 + 8
	end

	draw.SimpleText(title, "GProfiler.Graph.Title", titleX, y + 16, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local iconX = x + w - 16
	if isPinned then iconX = x + w - 16 end

	for i = #segments, 1, -1 do
		local seg = segments[i]
		if seg.icon then
			surface.SetDrawColor(seg.color)
			surface.SetMaterial(seg.icon)
			surface.DrawTexturedRect(iconX - 20, y + 16, 20, 20)
			iconX = iconX - 20 - 8
		end
	end

	local currentMax = 0
	for _, seg in ipairs(segments) do
		local m = seg.queue:Max()
		if m > currentMax then currentMax = m end
	end

	visualMax = Lerp(FrameTime() * 5, visualMax or 1, currentMax)
	local max = visualMax
	if max == 0 or max ~= max then max = 1 end

	local poly = GProfiler.Utils.Graphs.PolyBuffer or {
		{ x = 0, y = 0 },
		{ x = 0, y = 0 },
		{ x = 0, y = 0 },
		{ x = 0, y = 0 },
	}
	GProfiler.Utils.Graphs.PolyBuffer = poly

	for _, seg in ipairs(segments) do
		local queue = seg.queue
		local count = queue:Length()
		if count < 2 then continue end

		local col = seg.color
		surface.SetDrawColor(col.r, col.g, col.b, 150)
		draw.NoTexture()

		for i = 0, count - 2 do
			local val1 = queue:Get(i)
			local x1 = x + (i / (count - 1)) * w
			local y1 = y + h - (val1 / max) * (h * 0.60)
			local val2 = queue:Get(i + 1)
			local x2 = x + ((i + 1) / (count - 1)) * w
			local y2 = y + h - (val2 / max) * (h * 0.60)

			poly[1].x = x1
			poly[1].y = y + h
			poly[2].x = x1
			poly[2].y = y1
			poly[3].x = x2
			poly[3].y = y2
			poly[4].x = x2
			poly[4].y = y + h

			surface.DrawPoly(poly)
		end
	end

	local rightX = x + w - 72

	for i, seg in ipairs(segments) do
		local val = seg.queue:Get(seg.queue:Length() - 1)
		if not val then val = 0 end

		local txt = string.format("%.2f", val)
		if seg.formatter then txt = seg.formatter(val) end

		local fullText = txt .. " " .. (seg.suffix or "")

		draw.SimpleText(fullText, "GProfiler.Graph.Title", rightX, y + 14, seg.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		rightX = rightX - surface.GetTextSize(fullText) - 8
	end

	return visualMax
end

GProfiler.Utils.Graphs.Pinned = GProfiler.Utils.Graphs.Pinned or {}

hook.Add("HUDPaint", "GProfiler.Graphs.Pinned", function() -- TODO: Scaling/Only hood when necessary
	local width = 512
	local x = ScrW() - width - 20
	local y = 200
	local h = 150

	for id, data in pairs(GProfiler.Utils.Graphs.Pinned) do
		data.visualMax = GProfiler.Utils.Graphs.Render(x, y, width, h, data.title, data.visualMax, data.icon, data.segments, true)
		y = y + h + 10
	end
end)

surface.CreateFont("GProfiler.Graph.Title", { font = "Roboto", size = 20, weight = 500, antialias = true })
surface.CreateFont("GProfiler.Graph.ValueLarge", { font = "Roboto", size = 32, weight = 800, antialias = true })
surface.CreateFont("GProfiler.Graph.Small", { font = "Roboto", size = 14, weight = 500, antialias = true })

local graphBg = Color(16, 16, 24)
local graphTitle = Color(220, 220, 220)
local poly = {
	{ x = 0, y = 0 },
	{ x = 0, y = 0 },
	{ x = 0, y = 0 },
	{ x = 0, y = 0 }
}

local PANEL = {}
AccessorFunc(PANEL, "m_strTitle", "Title", FORCE_STRING)
AccessorFunc(PANEL, "m_fVisualMax", "VisualMax", FORCE_NUMBER)
AccessorFunc(PANEL, "m_MainIcon", "Icon")

function PANEL:Init()
	self.Data = {}
	self:SetTitle("Graph")
	self:SetVisualMax(1)

	self.HistorySlider = vgui.Create("DNumSlider", self)
	self.HistorySlider:SetText("History")
	self.HistorySlider:SetMin(32)
	self.HistorySlider:SetMax(1024)
	self.HistorySlider:SetDecimals(0)
	self.HistorySlider:SizeToContents()
	self.HistorySlider:SetPos(16, 40)
	self.HistorySlider:SetSize(250, 40)
	self.HistorySlider.Label:SetFont("GProfiler.Graph.Title")
	self.HistorySlider.Label:SetTextColor(Color(220, 220, 220))
	self.HistorySlider.TextArea:SetFont("GProfiler.Graph.Title")
	self.HistorySlider.TextArea:SetTextColor(Color(220, 220, 220))
	self.HistorySlider.OnValueChanged = function(s, val)
		self:ResizeQueues(math.Round(val))
	end
	self.HistorySlider.Slider.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, h / 2 - 2, w, 4, Color(60, 60, 70))
	end
	self.HistorySlider.Slider.Knob.Paint = function(s, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(220, 220, 220))
	end
	self.HistorySlider:SetVisible(false)

	self.PinBtn = vgui.Create("DImageButton", self)
	self.PinBtn:SetImage("icon16/pin.png") -- TODO
	self.PinBtn:SetSize(24, 24)
	self.PinBtn:SetPos(16, 16)
	self.PinBtn.DoClick = function(s)
		self:TogglePin()
	end
	self.PinBtn:SetVisible(false)
end

function PANEL:ResizeQueues(size)
	for _, seg in ipairs(self.Data) do
		seg.queue:Resize(size)
	end
	cookie.Set("gprofiler_graph_" .. self:GetTitle() .. "_size", size)
end

function PANEL:TogglePin()
	local id = self:GetTitle()
	if GProfiler.Utils.Graphs.Pinned[id] then
		GProfiler.Utils.Graphs.Pinned[id] = nil
	else
		GProfiler.Utils.Graphs.Pinned[id] = {
			title = self:GetTitle(),
			segments = self.Data,
			icon = self.MainIcon,
			visualMax = self:GetVisualMax()
		}
	end
end

function PANEL:Think()
	if self.Data[1] and not self.InitialSizeLoaded then
		self.InitialSizeLoaded = true
		local savedSize = cookie.GetNumber("gprofiler_graph_" .. self:GetTitle() .. "_size", self.Data[1].queue:Length())
		savedSize = math.Max(savedSize, 32)
		self.HistorySlider:SetValue(savedSize)
		self:ResizeQueues(savedSize)
	end

	local hover = self:IsHovered() or self:IsChildHovered()
	if hover != self.LastHover then
		self.LastHover = hover
		self.HistorySlider:SetVisible(hover)
		self.PinBtn:SetVisible(hover)
	end
end

function PANEL:AddSegment(queue, color, suffix, formatter, icon)
	if isstring(icon) then icon = Material(icon) end
	table.insert(self.Data, {
		queue = queue,
		color = color,
		textColor = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5),
		suffix = suffix or "",
		formatter = formatter,
		icon = icon
	})
end

function PANEL:SetMainIcon(iconMat)
	if isstring(iconMat) then
		self.MainIcon = Material(iconMat)
	else
		self.MainIcon = iconMat
	end
end

function PANEL:Paint(w, h)
	draw.RoundedBox(8, 0, 0, w, h, graphBg)

	local titleX = 16
	if self.MainIcon then
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(self.MainIcon)
		surface.DrawTexturedRect(16, 16, 20, 20)
		titleX = 16 + 20 + 8
	end

	draw.SimpleText(self:GetTitle(), "GProfiler.Graph.Title", titleX, 16, graphTitle, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local iconX = w - 16
	for i = #self.Data, 1, -1 do
		local seg = self.Data[i]
		if seg.icon then
			surface.SetDrawColor(seg.color)
			surface.SetMaterial(seg.icon)
			surface.DrawTexturedRect(iconX - 20, 16, 20, 20)
			iconX = iconX - 20 - 8
		end
	end

	local currentMax = 0
	for _, seg in ipairs(self.Data) do
		local m = seg.queue:Max()
		if m > currentMax then currentMax = m end
	end

	self:SetVisualMax(Lerp(FrameTime() * 5, self:GetVisualMax(), currentMax))
	local max = self:GetVisualMax()
	if max == 0 or max ~= max then max = 1 end

	for _, seg in ipairs(self.Data) do
		local queue = seg.queue
		local count = queue:Length()
		if count < 2 then continue end

		local col = seg.color
		surface.SetDrawColor(col.r, col.g, col.b, 150)
		draw.NoTexture()

		poly[1].y = h
		poly[4].y = h

		for i = 0, count - 2 do
			local val1 = queue:Get(i)
			local x1 = (i / (count - 1)) * w
			local y1 = h - (val1 / max) * (h * 0.60)
			local val2 = queue:Get(i + 1)
			local x2 = ((i + 1) / (count - 1)) * w
			local y2 = h - (val2 / max) * (h * 0.60)

			poly[1].x = x1
			poly[2].x = x1
			poly[2].y = y1
			poly[3].x = x2
			poly[3].y = y2
			poly[4].x = x2

			surface.DrawPoly(poly)
		end
	end

	local rightX = w - 16 - (#self.Data * 28) - 8

	for i, seg in ipairs(self.Data) do
		local val = seg.queue:Get(seg.queue:Length() - 1)
		if not val then val = 0 end

		local fmt = seg.formatter or function(v) return string.format("%.2f", v) end
		local fullText = fmt(val) .. " " .. (seg.suffix or "")

		surface.SetFont("GProfiler.Graph.Title")
		local valW = surface.GetTextSize(fullText)

		local statTxt, statW = nil, 0
		if seg.queue:Length() > 1 then
			statTxt = string.format("min %s   avg %s   max %s", fmt(seg.queue:Min()), fmt(seg.queue:Average()), fmt(seg.queue:Max()))
			surface.SetFont("GProfiler.Graph.Small")
			statW = surface.GetTextSize(statTxt)
		end

		local colW = math.max(valW, statW)

		draw.SimpleText(fullText, "GProfiler.Graph.Title", rightX, 16, seg.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		if statTxt then
			draw.SimpleText(statTxt, "GProfiler.Graph.Small", rightX, 42, Color(seg.color.r, seg.color.g, seg.color.b, 170), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		end

		rightX = rightX - colW - 28
	end

	if self.PinBtn and self.PinBtn:IsVisible() then
		self.PinBtn:SetPos(w - 32, h - 32)
		self.HistorySlider:SetPos(16, h - 36)
	end
end

vgui.Register("GP.Graph", PANEL, "DPanel")
