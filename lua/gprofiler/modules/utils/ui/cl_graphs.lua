-- TODO + credits to whoever posted this in gmod discord

-- local MAX_DEBUG_ITEMS = 512
-- local function ConstantLengthNumericalQueue(capacity)
--     local obj = {}
--     local pointer = 0
--     local length = 0
--     local startat = 0
--     local backing = {}
--     for i = 1, capacity do
--         backing[i - 1] = 0
--     end
--     function obj:Add(item)
--         if length < capacity then
--             length = length + 1
--         else
--             startat = startat + 1
--             if startat >= capacity then
--                 startat = 0
--             end
--         end

--         if pointer >= capacity then pointer = 0 end
--         backing[pointer] = item
--         pointer = pointer + 1
--     end
--     function obj:Get(i)
--         return backing[(i + startat) % capacity]
--     end

--     function obj:Length() return length end


--     function obj:Start() return startat end

--     function obj:Min()
--         local ret = 0
--         for i = 1, length do
--             ret = math.min(ret, backing[i - 1])
--         end
--         return ret
--     end

--     function obj:Max()
--         local ret = 0
--         for i = 1, length do
--             ret = math.max(ret, backing[i - 1])
--         end
--         return ret
--     end

--     function obj:Average()
--         local ret = 0
--         for i = 1, length do
--             ret = ret + backing[i - 1]
--         end
--         return ret / length
--     end

--     return obj
-- end

-- local perfgraph = ConstantLengthNumericalQueue(MAX_DEBUG_ITEMS)

-- -- during frames call perfgraph:Add(v)

-- local v1, v2 = Vector(), Vector()
-- function draw.Line(startX, startY, endX, endY, thickness, color)
--     if not startX then return end
--     if not startY then return end
--     if not endX then return end
--     if not endY then return end

--     thickness = thickness or 1
--     color = color or color_white

--     local x, y   = endX - startX, endY - startY
--     local cx, cy = (startX + endX) / 2, (startY + endY) / 2
--     local dist   = math.sqrt((x^2) + (y^2))

--     local a      = -math.atan2(y, x)
--     local s, c   = math.sin(a), math.cos(a)

--     v1:SetUnpacked(cx, cy, 0)
--     v2:SetUnpacked(s, c, -thickness)
--     mesh.Begin(MATERIAL_QUADS, 1)
--     xpcall(function()
--         mesh.QuadEasy(v1, v2, dist, thickness, color)
--         mesh.End()
--     end, function() mesh.End() print(debug.traceback(err)) end)
-- end

-- local color_grey = Color(173, 173, 173)
-- local formatString = "%.2f"
-- local formatString2 = "avg: %.2f"
-- local function DrawGraph(data, label, x, y, c)
--     local w, h = 450, 64
--     surface.SetDrawColor(20, 25, 35, 200)
--     surface.DrawRect(x, y, w, h)

--     local xPadding = 48

--     local count, min, max, avg = data:Length(), data:Min(), data:Max(), data:Average()
--     draw.Line(x + xPadding, y + 4, x + xPadding, y + h - 4, 2, color_grey)
--     draw.Line(x + xPadding, y + h - 4, x + w - 4, y + h - 4, 2, color_grey)
--     for i = 0, MAX_DEBUG_ITEMS - 1 do
--         if i + 1 >= count then break end

--         local finalPos = i + 1
--         local x1 = x + xPadding + 4 + math.Remap(i, 0, MAX_DEBUG_ITEMS, 0, w - xPadding - 8)
--         local x2 = x + xPadding + 4 + math.Remap(finalPos, 0, MAX_DEBUG_ITEMS, 0, w - xPadding - 8)
--         local y1 = data:Get(i)
--         local y2 = data:Get(finalPos)

--         draw.Line(
--             x1, y + math.Remap(y1, min, max, h - 4, 16),
--             x2, y + math.Remap(y2, min, max, h - 4, 16),
--             3, c)
--     end

--     draw.SimpleText(label, "DebugFixed", x + (w / 2), y, color_white, TEXT_ALIGN_CENTER)
--     draw.SimpleText(formatString:format(max), "DebugFixed", x + xPadding - 4, y, color_white, TEXT_ALIGN_RIGHT)
--     draw.SimpleText(formatString:format(min), "DebugFixed", x + xPadding - 4, y + h, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
--     draw.SimpleText(formatString2:format(avg), "DebugFixed", x + w - 4, y, color_white, TEXT_ALIGN_RIGHT)
-- end