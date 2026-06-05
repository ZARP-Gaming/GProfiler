local function DefaultSplitPaint(s, w, h)
	GProfiler.RNDX.DrawScaled(8, 0, 0, w, h, Color(38, 63, 89, 255))
end

local function CreateSplitPanel(parent, isVertical, spacing, name, initialPercentage)
	parent.Paint = nil
	spacing = spacing or GProfiler.GetScaledSize(10)
	local handleThickness = spacing

	local panel1 = vgui.Create("DPanel", parent)
	local panel2 = vgui.Create("DPanel", parent)
	local handle = vgui.Create("DPanel", parent)

	panel1.Paint = DefaultSplitPaint
	panel2.Paint = DefaultSplitPaint

	handle:SetCursor(isVertical and "sizewe" or "sizens")
	handle.isDragging = false
	handle.startPos = 0
	handle.startHandlePos = 0
	handle.Fraction = nil

	local minSize = 50

	if name then
		local saved = cookie.GetNumber("gprofiler_" .. name)
		if saved and saved > 0 and saved <= 1 then
			handle.Fraction = saved
		end
	end

	local function updateLayout()
		local w, h = parent:GetSize()

		if w == 0 or h == 0 then return end

		local totalSize = isVertical and w or h

		if not handle.Fraction then
			handle.Fraction = initialPercentage or 0.5
		end

		local currentPos = (totalSize - spacing) * handle.Fraction
		local handlePos = math.Clamp(currentPos, minSize, totalSize - minSize - spacing)

		if isVertical then
			handle:SetSize(handleThickness, h)
			handle:SetPos(handlePos + (spacing - handleThickness) / 2, 0)
			panel1:SetSize(handlePos, h)
			panel1:SetPos(0, 0)
			panel2:SetSize(w - handlePos - spacing, h)
			panel2:SetPos(handlePos + spacing, 0)
		else
			handle:SetSize(w, handleThickness)
			handle:SetPos(0, handlePos + (spacing - handleThickness) / 2)
			panel1:SetSize(w, handlePos)
			panel1:SetPos(0, 0)
			panel2:SetSize(w, h - handlePos - spacing)
			panel2:SetPos(0, handlePos + spacing)
		end

		if panel1.OnHandleMoved then panel1:OnHandleMoved() end
		if panel2.OnHandleMoved then panel2:OnHandleMoved() end
	end

	handle.Paint = function(s, w, h)
		if not s:IsHovered() and not s.isDragging then return end
		local MenuColors = GProfiler.MenuColors
		if isVertical then
			GProfiler.RNDX.DrawScaled(4, 2, 0, w - 4, h, Color(26, 53, 80))
		else
			GProfiler.RNDX.DrawScaled(4, 0, 2, w, h - 4, Color(26, 53, 80))
		end
	end

	handle.OnMousePressed = function(s, mousecode)
		if mousecode == MOUSE_LEFT then
			s.isDragging = true
			local mx, my = parent:ScreenToLocal(gui.MouseX(), gui.MouseY())
			s.startPos = isVertical and mx or my

			local w, h = parent:GetSize()
			local totalSize = isVertical and w or h
			local currentPos = (totalSize - spacing) * (s.Fraction or initialPercentage or 0.5)
			s.startHandlePos = currentPos

			s:MouseCapture(true)
		elseif mousecode == MOUSE_RIGHT then
			if name then
				cookie.Set("gprofiler_" .. name, nil)
			end
			handle.Fraction = nil
			updateLayout()
		end
	end

	handle.OnMouseReleased = function(s, mousecode)
		if mousecode == MOUSE_LEFT then
			s.isDragging = false
			s:MouseCapture(false)
			if name and s.Fraction then
				cookie.Set("gprofiler_" .. name, s.Fraction)
			end
		end
	end

	handle.Think = function(s)
		if s.isDragging then
			local mx, my = parent:ScreenToLocal(gui.MouseX(), gui.MouseY())
			local currentPos = isVertical and mx or my
			local delta = currentPos - s.startPos

			local w, h = parent:GetSize()
			local totalSize = isVertical and w or h
			local availableSize = totalSize - spacing

			if availableSize < minSize * 2 then return end

			local newHandlePos = s.startHandlePos + delta
			newHandlePos = math.Clamp(newHandlePos, minSize, availableSize - minSize)

			local newFraction = newHandlePos / availableSize
			if newFraction ~= s.Fraction then
				s.Fraction = newFraction
				updateLayout()
			end
		end
	end

	local oldPerformLayout = parent.PerformLayout
	parent.PerformLayout = function(pnl, w, h)
		if oldPerformLayout then oldPerformLayout(pnl, w, h) end
		updateLayout()
	end

	updateLayout()

	return panel1, panel2
end

function GProfiler.Utils.VSplitPanel(parent, spacing, name, initialPercentage)
	if isstring(spacing) then
		if isnumber(name) then
			initialPercentage = name
		end
		name = spacing
		spacing = nil
	end

	return CreateSplitPanel(parent, true, spacing, name, initialPercentage)
end

function GProfiler.Utils.HSplitPanel(parent, spacing, name, initialPercentage)
	if isstring(spacing) then
		if isnumber(name) then
			initialPercentage = name
		end

		name = spacing
		spacing = nil
	end

	return CreateSplitPanel(parent, false, spacing, name, initialPercentage)
end