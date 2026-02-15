GProfiler.Menu.Tabs = GProfiler.Menu.Tabs or {}
GProfiler.Menu.Background = GProfiler.Menu.Background or nil
GProfiler.Menu.Content = GProfiler.Menu.Content or nil
GProfiler.Menu.LastTab = GProfiler.Menu.LastTab or 1

local MenuColors = GProfiler.MenuColors

local function GetTabName(tabName)
	return GProfiler.Language.GetPhrase(string.format("tab_%s", string.gsub(string.lower(tabName), " ", "_")))
end

local function formatTime(seconds)
	local days = math.floor(seconds / 86400)
	if days > 0 then
		local hours = math.floor((seconds - days * 86400) / 3600)
		local minutes = math.floor((seconds - days * 86400 - hours * 3600) / 60)
		local seconds = math.floor(seconds - days * 86400 - hours * 3600 - minutes * 60)
		return string.format("%dd %02d:%02d:%02d", days, hours, minutes, seconds)
	else
		local hours = math.floor(seconds / 3600)
		local minutes = math.floor((seconds - hours * 3600) / 60)
		local seconds = math.floor(seconds - hours * 3600 - minutes * 60)
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end
end

function GProfiler.Menu:Open()
	if not GProfiler.Access.HasAccess(LocalPlayer()) then return end
	if IsValid(GProfiler.Menu.Background) then GProfiler.Menu.Background:Remove() end

	local SColor = MenuColors.HeaderSeparator

	local MenuBackground = vgui.Create("DFrame")
	MenuBackground:SetSize(ScrW(), ScrH())
	MenuBackground:Center()
	MenuBackground:SetDraggable(false)
	MenuBackground:ShowCloseButton(false)
	MenuBackground:SetTitle("")
	MenuBackground:MakePopup()
	MenuBackground:SetMouseInputEnabled(false)
	MenuBackground.Paint = function(s) Derma_DrawBackgroundBlur(s) end
	if GProfiler.Config.MenuCommands.Closekey then
		MenuBackground.Think = function(s)
			if input.IsKeyDown(GProfiler.Config.MenuCommands.Closekey) then
				s:Close()
			end
		end
	end
	GProfiler.Menu.Background = MenuBackground

	local Menu = vgui.Create("DFrame", MenuBackground)
	Menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	Menu:Center()
	Menu:SetDraggable(false)
	Menu:ShowCloseButton(false)
	Menu:SetTitle("")
	Menu:MakePopup()
	Menu.Paint = function(s, w, h) draw.RoundedBox(4, 0, 0, w, h, MenuColors.Background) end
	Menu.OnClose = function() MenuBackground:Remove() end

	local MenuTopBar = vgui.Create("DPanel", Menu)
	MenuTopBar:SetSize(Menu:GetWide(), 40)
	MenuTopBar:SetPos(0, 0)
	MenuTopBar.Paint = function(s, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, MenuColors.OpaqueBlack, true, true, false, false)
		surface.SetDrawColor(SColor.r, SColor.g, SColor.b, SColor.a)
		surface.DrawLine(0, h - 1, w, h - 1)
	end

	local MenuTitle = vgui.Create("DLabel", MenuTopBar)
	MenuTitle:SetSize(MenuTopBar:GetWide(), MenuTopBar:GetTall())
	MenuTitle:SetPos(0, 0)
	MenuTitle:SetFont("GProfiler.Menu.Title")
	MenuTitle:SetTextColor(MenuColors.White)
	MenuTitle:SetText("GProfiler")
	MenuTitle:SizeToContents()
	MenuTitle:SetPos(5, MenuTopBar:GetTall() / 2 - MenuTitle:GetTall() / 2)

	GProfiler.Menu.Title = MenuTitle

	local LeftSideBar = vgui.Create("DPanel", Menu)
	LeftSideBar:SetSize(250, Menu:GetTall() - MenuTopBar:GetTall() - 35)
	LeftSideBar:SetPos(0, MenuTopBar:GetTall())
	LeftSideBar.Paint = function(s, w, h) draw.RoundedBoxEx(4, 0, 0, w, h, MenuColors.OpaqueBlack, false, false, true, false) end

	local UptimeBar = vgui.Create("DPanel", Menu)
	UptimeBar:SetSize(LeftSideBar:GetWide(), 35)
	UptimeBar:SetPos(0, Menu:GetTall() - UptimeBar:GetTall())
	UptimeBar.Paint = function(s, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, MenuColors.OpaqueBlack, false, false, false, true)
		surface.SetDrawColor(SColor.r, SColor.g, SColor.b, SColor.a)
		surface.DrawLine(0, 0, w, 0)
	end

	local VersionLbl = vgui.Create("DLabel", UptimeBar)
	VersionLbl:SetSize(UptimeBar:GetWide(), UptimeBar:GetTall())
	VersionLbl:SetPos(0, 0)
	VersionLbl:SetFont("GProfiler.Menu.VersionLbl")
	VersionLbl:SetTextColor(MenuColors.White)
	VersionLbl:SetText("GProfiler • v" .. GProfiler.Version)
	VersionLbl:SetContentAlignment(5)
	VersionLbl.Paint = nil

	local CloseButton = vgui.Create("DButton", MenuTopBar)
	CloseButton:SetSize(MenuTopBar:GetTall(), MenuTopBar:GetTall())
	CloseButton:SetPos(Menu:GetWide() - CloseButton:GetWide(), 0)
	CloseButton:SetText("X")
	CloseButton:SetFont("GProfiler.Menu.SectionHeader")
	CloseButton:SetTextColor(MenuColors.White)
	CloseButton.Paint = nil
	CloseButton.DoClick = function() Menu:Close() end

	local MenuContent = vgui.Create("DPanel", Menu)
	MenuContent:SetSize(Menu:GetWide() - LeftSideBar:GetWide(), Menu:GetTall() - MenuTopBar:GetTall())
	MenuContent:SetPos(LeftSideBar:GetWide(), MenuTopBar:GetTall())
	MenuContent.Paint = nil

	GProfiler.Menu.Content = MenuContent

	local TabList = vgui.Create("DPanelList", LeftSideBar)
	TabList:SetSize(LeftSideBar:GetWide(), LeftSideBar:GetTall())
	TabList:SetPos(0, 0)
	TabList:EnableVerticalScrollbar(true)
	TabList:SetSpacing(0)
	TabList.Paint = nil

	local padding = 10

	local activeTab = nil
	local BottomTabs = {}

	local function AddTab(k, v, alt)
		local Tab = vgui.Create("DButton")
		Tab.Lerped = 0
		Tab:SetSize(TabList:GetWide(), 50)
		Tab:SetText("")
		Tab.Paint = function(s, w, h)
			if alt then
				draw.RoundedBox(4, 0, 0, w, h, MenuColors.HeaderSeparator)
				draw.RoundedBox(4, 2, 2, w - 4, h - 4, MenuColors.OpaqueBlack)

				if s:IsHovered() or activeTab == s then
					draw.RoundedBox(4, 0, 0, w, h, MenuColors.HeaderSeparator)
				end
				return
			end
			surface.SetDrawColor(SColor.r, SColor.g, SColor.b, SColor.a)
			surface.DrawLine(0, h - 1, w, h - 1)

			if s:IsHovered() or activeTab == s then
				s.Lerped = Lerp(FrameTime() * 5, s.Lerped, w + 2)
			else
				s.Lerped = Lerp(FrameTime() * 5, s.Lerped, 0)
			end

			draw.RoundedBox(0, 0, 0, s.Lerped, h, MenuColors.TopBarSeparator)
		end
		Tab.DoClick = function()
			GProfiler.Menu.OpenTab(v.Name, v.Function)
			activeTab = Tab
			GProfiler.Menu.LastTab = k
		end

		local TabIcon = vgui.Create("DImage", Tab)
		TabIcon:SetSize(Tab:GetTall() - padding * 2, Tab:GetTall() - padding * 2)
		TabIcon:SetPos(padding, padding)
		TabIcon:SetImage(v.Icon)

		local TabText = vgui.Create("DLabel", Tab)
		TabText:SetFont("GProfiler.Menu.TabText")
		TabText:SetText(GetTabName(v.Name))
		TabText:SetTextColor(MenuColors.White)
		TabText:SizeToContents()
		TabText:SetPos(TabIcon:GetWide() + padding * 2, Tab:GetTall() / 2 - TabText:GetTall() / 2)
		TabText:SetContentAlignment(5)

		if v.BadgeFunc then
			local TabBadge = vgui.Create("DLabel", Tab)
			TabBadge:SetSize(1, 1)
			TabBadge:SetText("")
			TabBadge:SetFont("GProfiler.Menu.TabText")
			TabBadge:SetPos(Tab:GetWide() - TabBadge:GetWide() - padding, Tab:GetTall() / 2 - TabBadge:GetTall() / 2)
			TabBadge:SetContentAlignment(5)
			TabBadge.Think = function(s)
				local text = v.BadgeFunc()
				if not s.CurrentText or s.CurrentText ~= text then
					s.CurrentText = text
					surface.SetFont(s:GetFont())
					local w, h = surface.GetTextSize(text or "")
					if text == "" then
						s:SetSize(h / 2, h / 2)
					else
						s:SetSize(w + 5, h + 5)
					end
					s:SetPos(Tab:GetWide() - s:GetWide() - padding, Tab:GetTall() / 2 - s:GetTall() / 2)
				end
			end
			TabBadge.Paint = function(s, w, h)
				local text, color = v.BadgeFunc()
				if text and color then
					if text == "" then
						draw.RoundedBox(h / 2, 0, 0, w, h, color)
					else
						draw.RoundedBox(4, 0, 0, w, h, color)
						draw.SimpleText(text, "GProfiler.Menu.TabBadge", w / 2, h / 2, MenuColors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end
			end
		end

		return Tab
	end

	for k, v in ipairs(GProfiler.Menu.Tabs) do
		if v.Weight == 999 then
			table.insert(BottomTabs, v)
			continue
		end

		local Tab = AddTab(k, v)
		TabList:AddItem(Tab)
	end

	if #BottomTabs > 0 then
		local BottomTabList = vgui.Create("DPanelList", LeftSideBar)
		BottomTabList:SetSize(LeftSideBar:GetWide() - 6, 50 * #BottomTabs)
		BottomTabList:SetPos(3, LeftSideBar:GetTall() - BottomTabList:GetTall() - 5)
		BottomTabList:EnableVerticalScrollbar(true)
		BottomTabList:SetSpacing(0)
		BottomTabList.Paint = nil

		for k, v in ipairs(BottomTabs) do
			local Tab = AddTab(k, v, true)
			BottomTabList:AddItem(Tab)
		end
	end

	TabList:GetItems()[GProfiler.Menu.LastTab]:DoClick()
end

function GProfiler.Menu.RegisterTab(name, icon, weight, func, badgeFunc)
	local tbl = {
		["Name"] = name,
		["Icon"] = icon,
		["Weight"] = weight,
		["Function"] = func,
		["BadgeFunc"] = badgeFunc
	}

	for k, v in ipairs(GProfiler.Menu.Tabs) do
		if v.Name == name then
			GProfiler.Menu.Tabs[k] = tbl
			table.sort(GProfiler.Menu.Tabs, function(a, b) return a.Weight < b.Weight end)
			return
		end
	end

	table.insert(GProfiler.Menu.Tabs, tbl)
	table.sort(GProfiler.Menu.Tabs, function(a, b) return a.Weight < b.Weight end)
end

function GProfiler.Menu.OpenTab(name, func)
	if not IsValid(GProfiler.Menu.Content) then return end
	if not name or not func then return end

	GProfiler.Menu.Content:Clear()

	local Tab = vgui.Create("DPanel", GProfiler.Menu.Content)
	Tab:SetSize(GProfiler.Menu.Content:GetWide(), GProfiler.Menu.Content:GetTall())
	Tab.Paint = nil

	func(Tab)

	if GProfiler.Menu.Title then
		GProfiler.Menu.Title:SetText("GProfiler - " .. GetTabName(name))
		GProfiler.Menu.Title:SizeToContents()
	end
end

if isstring(GProfiler.Config.MenuCommands.Chat) then
	hook.Add("OnPlayerChat", "GProfiler.MenuCommands.Chat", function(ply, text)
		if text == GProfiler.Config.MenuCommands.Chat then
			if ply == LocalPlayer() then GProfiler.Menu:Open() end
			return true
		end
	end)
else hook.Remove("OnPlayerChat", "GProfiler.MenuCommands.Chat") end

if isstring(GProfiler.Config.MenuCommands.Console) then
	concommand.Add(GProfiler.Config.MenuCommands.Console, GProfiler.Menu.Open)
end

local function CreateFonts()
	surface.CreateFont("GProfiler.Menu.Title", { font = "Roboto", size = 26, weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.SectionHeader", { font = "Roboto", size = 18, weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.TabText", { font = "Roboto", size = 20, weight = 400, antialias = true })
	surface.CreateFont("GProfiler.Menu.TabBadge", { font = "Roboto", size = 18, weight = 400, antialias = true })
	surface.CreateFont("GProfiler.Menu.VersionLbl", { font = "Roboto", size = 18, weight = 400, antialias = true })
	surface.CreateFont("GProfiler.Menu.RealmSelector", { font = "Roboto", size = 18, weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.StartButton", { font = "Roboto", size = 16, weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.ListHeader", { font = "Roboto", size = ScreenScale(4), weight = 400,	antialias = true })
	surface.CreateFont("GProfiler.Menu.FunctionDetails", { font = "Roboto", size = 16, weight = 400, antialias = true })
	surface.CreateFont("GProfiler.Menu.FocusEntry", { font = "Roboto", size = 16, weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.RowText", { font = "Roboto", size = 16, weight = 400, antialias = true })
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "GProfiler.Menu.RescaleFonts", CreateFonts)

net.Receive("GProfiler.SendState", function()
	local count = net.ReadUInt(4)
	for i = 1, count do
		local Profiler = net.ReadString()
		local StartedAt = net.ReadFloat()

		local Tbl = GProfiler[Profiler]
		if not Tbl then continue end

		Tbl.ProfileActive = true
		Tbl.Realm = "Server"
		Tbl.StartTime = SysTime() - StartedAt
	end
end)