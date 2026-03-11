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

surface.CreateFont("GProfiler.Graph.Title", { font = "Roboto", size = 20, weight = 500, antialias = true })
surface.CreateFont("GProfiler.Graph.ValueLarge", { font = "Roboto", size = 32, weight = 800, antialias = true })

local PANEL = {}

AccessorFunc(PANEL, "m_strTitle", "Title", FORCE_STRING)
AccessorFunc(PANEL, "m_fVisualMax", "VisualMax", FORCE_NUMBER)
AccessorFunc(PANEL, "m_MainIcon", "Icon")

function PANEL:Init()
	self.Data = {}
	self:SetTitle("Graph")
	self:SetVisualMax(1)
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
	draw.RoundedBox(8, 0, 0, w, h, Color(16, 16, 24))

	local titleX = 16
	if self.MainIcon then
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(self.MainIcon)
		surface.DrawTexturedRect(16, 16, 20, 20)
		titleX = 16 + 20 + 8
	end

	draw.SimpleText(self:GetTitle(), "GProfiler.Graph.Title", titleX, 16, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

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
		surface.SetDrawColor(Color(col.r, col.g, col.b, 150))
		draw.NoTexture()

		for i = 0, count - 2 do
			local val1 = queue:Get(i)
			local x1 = (i / (count - 1)) * w
			local y1 = h - (val1 / max) * (h * 0.60)
			local val2 = queue:Get(i + 1)
			local x2 = ((i + 1) / (count - 1)) * w
			local y2 = h - (val2 / max) * (h * 0.60)

			local quad = {
				{ x = x1, y = h },
				{ x = x1, y = y1 },
				{ x = x2, y = y2 },
				{ x = x2, y = h }
			}
			surface.DrawPoly(quad)
		end
	end

	local leftX = 16
	local rightX = w - 16

	for i, seg in ipairs(self.Data) do
		local val = seg.queue:Get(seg.queue:Length() - 1)
		if not val then val = 0 end

		local txt = string.format("%.2f", val)
		if seg.formatter then txt = seg.formatter(val) end

		local fullText = txt .. " " .. (seg.suffix or "")

		if i == 1 then
			draw.SimpleText(fullText, "GProfiler.Graph.ValueLarge", rightX, 16, seg.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			rightX = rightX - surface.GetTextSize(fullText) - 8
		else -- todo: multiple segments is nice, but needs to look better
			draw.SimpleText(fullText, "GProfiler.Graph.ValueLarge", rightX, 16, seg.color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			rightX = rightX - surface.GetTextSize(fullText) - 8
		end
	end
end

vgui.Register("GP.Graph", PANEL, "DPanel")