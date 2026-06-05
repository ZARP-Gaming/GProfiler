GProfiler.Menu = GProfiler.Menu or {}

local Menu = GProfiler.Menu
Menu.Tabs = Menu.Tabs or {}
Menu.Background = Menu.Background or nil
Menu.Content = Menu.Content or nil
Menu.LastTab = Menu.LastTab or 1

local CachedSizes = {}
function GProfiler.GetScaledSize(s)
	if CachedSizes[s] then return CachedSizes[s] end
	local scalingFactor = math.min(ScrW() / 3840, ScrH() / 2160)
	CachedSizes[s] = s * scalingFactor
	return s * scalingFactor
end

local function GetTabName(tabName) return GProfiler.Language.GetPhrase(string.format("tab_%s", string.gsub(string.lower(tabName), " ", "_"))) end

function GProfiler.Menu:Open()
	if not GProfiler.Access.HasAccess(LocalPlayer()) then return end
	if IsValid(GProfiler.Menu.Background) then GProfiler.Menu.Background:Remove() end

	local MenuColors = GProfiler.MenuColors
	local RNDX = GProfiler.RNDX

	local MenuBackground = vgui.Create("DFrame")
	MenuBackground:SetSize(ScrW(), ScrH())
	MenuBackground:Center()
	MenuBackground:SetDraggable(false)
	MenuBackground:ShowCloseButton(false)
	MenuBackground:SetTitle("")
	MenuBackground:MakePopup()
	MenuBackground:SetMouseInputEnabled(false)
	MenuBackground.Paint = function(s, w, h)
		-- RNDX.DrawBlur(0, 0, w, h, nil, nil, nil, nil, nil, (ScrW() - (ScrW() * 0.79)) / 2)
		RNDX.DrawScaled(4, 0, 0, w, h, MenuColors.Black100) -- better than eating fps
	end
	if GProfiler.Config.MenuCommands.Closekey then
		MenuBackground.Think = function(s)
			if input.IsKeyDown(GProfiler.Config.MenuCommands.Closekey) then
				s:Close()
			end
		end
	end
	GProfiler.Menu.Background = MenuBackground

	local Main = vgui.Create("DFrame", MenuBackground)
	Main:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	Main:Center()
	Main:SetDraggable(false)
	Main:ShowCloseButton(false)
	Main:SetTitle("")
	Main:MakePopup()
	Main.Paint = function(s, w, h) RNDX.DrawScaled(4, 0, 0, w, h, Color(10, 32, 55, 255)) end
	Main.OnClose = function() MenuBackground:Remove() end

	local Header = vgui.Create("DPanel", Main)
	Header:SetSize(Main:GetWide() - GProfiler.GetScaledSize(20), GProfiler.GetScaledSize(92))
	Header:SetPos(GProfiler.GetScaledSize(10), GProfiler.GetScaledSize(10))
	Header.Paint = function(s, w, h)
		RNDX.DrawScaled(4, 0, 0, w, h, Color(24, 45, 67, 255))

		surface.SetFont("GProfiler.HeaderTitle")
		local TitleWidth, TitleHeight = surface.GetTextSize("GProfiler")
		local StartX = GProfiler.GetScaledSize(20)

		draw.SimpleText("GProfiler", "GProfiler.HeaderTitle", StartX, h / 2, Color(191, 237, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("v" .. GProfiler.Version, "GProfiler.HeaderSubtitle", StartX + 5 + TitleWidth, h / 2 + GProfiler.GetScaledSize(10), Color(210, 210, 210), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local CloseButton = vgui.Create("DButton", Header)
	CloseButton:SetSize(GProfiler.GetScaledSize(56), GProfiler.GetScaledSize(56))
	CloseButton:SetPos(Header:GetWide() - CloseButton:GetWide() - GProfiler.GetScaledSize(20), Header:GetTall() / 2 - CloseButton:GetTall() / 2)
	CloseButton:SetText("X")
	CloseButton:SetTextColor(Color(255, 215, 215))
	CloseButton:SetFont("GProfiler.HeaderTitle")
	CloseButton.Paint = function(s, w, h)
		RNDX.DrawScaled(4, 0 ,0, w, h, Color(176, 64, 64))
		if s:IsHovered() then
			RNDX.DrawScaled(4, 0, 0, w, h, Color(255, 64, 64))
		end
	end
	CloseButton.DoClick = function() Main:Close() end

	local InnerMain = vgui.Create("DPanel", Main)
	InnerMain:SetSize(Main:GetWide() - GProfiler.GetScaledSize(20), Main:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(30))
	InnerMain:SetPos(GProfiler.GetScaledSize(10), Header:GetTall() + GProfiler.GetScaledSize(20))
	InnerMain.Paint = nil

	local SidebarBase, ContentBase = GProfiler.Utils.VSplitPanel(InnerMain, GProfiler.GetScaledSize(10), "sb_cnt", 0.185)
	SidebarBase.Paint = nil
	ContentBase.Paint = nil

	local Sidebar = vgui.Create("DPanel", SidebarBase)
	Sidebar:SetSize(GProfiler.GetScaledSize(600), Main:GetTall() - Header:GetTall() - GProfiler.GetScaledSize(30))
	Sidebar.Paint = nil

	local Scroller = vgui.Create("DScrollPanel", Sidebar)
	Scroller:SetSize(Sidebar:GetSize())

	local sbar = Scroller:GetVBar()
	sbar:SetWide(GProfiler.GetScaledSize(12))
	sbar:SetHideButtons(true)
	sbar.Paint = function(s, w, h)
		RNDX.DrawScaled(4, 0, 0, w, h, MenuColors.ScrollBar)
	end
	sbar.btnGrip.Paint = function(s, w, h)
		RNDX.DrawScaled(4, 0, 0, w, h, MenuColors.ScrollBarGrip)
		if s:IsHovered() then
			RNDX.DrawScaled(4, 0, 0, w, h, MenuColors.ScrollBarGripOutline)
		end
	end

	local List = vgui.Create("DIconLayout", Scroller)
	List:SetSize(Scroller:GetSize())
	List:SetSpaceY(GProfiler.GetScaledSize(10))

	for k, v in ipairs(Menu.Tabs) do
		local Icon = Material(v.Icon, "smooth noclamp")
		local IconSize = GProfiler.GetScaledSize(60)

		local Tab = vgui.Create("DButton", List)
		Tab:SetSize(Scroller:GetWide(), GProfiler.GetScaledSize(100))
		Tab:SetText("")
		Tab.Paint = function(s, w, h)
			RNDX.DrawScaled(4, 0, 0, w, h, Color(25, 60, 97, 255))
			if Menu.LastTab == k then
				RNDX.DrawScaled(4, 0, 0, w, h, Color(30, 90, 152, 255))
			elseif s:IsHovered() then
				RNDX.DrawScaled(4, 0, 0, w, h, Color(34, 77, 122, 255))
			end

			surface.SetDrawColor(191, 237, 255, 255)
			surface.SetMaterial(Icon)
			surface.DrawTexturedRect(GProfiler.GetScaledSize(20), h / 2 - IconSize / 2, IconSize, IconSize)

			draw.SimpleText(GetTabName(v.Name), "GProfiler.Menu.TabText", GProfiler.GetScaledSize(100), h / 2, MenuColors.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			if not v.BadgeFunc then return end

			local time, isActive = v.BadgeFunc()
			if time then
				surface.SetFont("GProfiler.Menu.TabText")
				local timeWidth, timeHeight = surface.GetTextSize(time)
				local badgeWidth = timeWidth + GProfiler.GetScaledSize(10)
				local badgeHeight = timeHeight + GProfiler.GetScaledSize(5)

				local badgeX = w - badgeWidth - GProfiler.GetScaledSize(20)
				local badgeY = h / 2 - badgeHeight / 2

				RNDX.DrawScaled(4, badgeX, badgeY, badgeWidth, badgeHeight, isActive and Color(36, 172, 82, 255) or Color(196, 79, 79))
				draw.SimpleText(time, "GProfiler.Menu.TabBadge", badgeX + badgeWidth / 2, badgeY + badgeHeight / 2, MenuColors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		Tab.DoClick = function()
			Menu.OpenTab(v.Name, v.Function)
			Menu.LastTab = k
		end

		List:Add(Tab)
	end

	local Content = vgui.Create("DPanel", ContentBase)
	Content:SetSize(ContentBase:GetSize())
	Content.Paint = function(s, w, h)
		RNDX.DrawScaled(8, 0, 0, w, h, Color(18, 48, 74, 255))
	end

	Menu.Content = Content

	local LastTab = Menu.Tabs[Menu.LastTab or 1]
	Menu.OpenTab(LastTab.Name, LastTab.Function)

	SidebarBase.OnHandleMoved = function()
		Sidebar:SetSize(SidebarBase:GetWide(), Sidebar:GetTall())
		Scroller:SetSize(Sidebar:GetSize())
		List:SetSize(Scroller:GetSize())
		for k, v in ipairs(List:GetChildren()) do
			v:SetSize(Scroller:GetWide(), GProfiler.GetScaledSize(100))
		end
	end

	ContentBase.OnHandleMoved = function()
		Content:SetSize(ContentBase:GetWide(), ContentBase:GetTall())
		if IsValid(Content.Tab) then
			if Content.Tab.OnHandleMoved then Content.Tab:OnHandleMoved() end
		end
	end
end
if GProfiler.Ready then Menu:Open() end

function Menu.RegisterTab(name, icon, weight, func, badgeFunc)
	local tbl = {
		["Name"] = name,
		["Icon"] = icon,
		["Weight"] = weight,
		["Function"] = func,
		["BadgeFunc"] = badgeFunc
	}

	for k, v in ipairs(Menu.Tabs) do
		if v.Name == name then
			table.Merge(v, tbl)
			table.sort(Menu.Tabs, function(a, b) return a.Weight < b.Weight end)
			return
		end
	end

	table.insert(Menu.Tabs, tbl)
	table.sort(Menu.Tabs, function(a, b) return a.Weight < b.Weight end)
end

function Menu.OpenTab(name, func)
	if not IsValid(Menu.Content) then return end
	if not name or not func then return end

	Menu.Content:Clear()

	local Tab = vgui.Create("DPanel", Menu.Content)
	Tab:SetSize(Menu.Content:GetWide(), Menu.Content:GetTall())
	Tab.Paint = nil
	Menu.Content.Tab = Tab

	func(Tab, Menu.Content)

	if Menu.Title then
		Menu.Title:SetText("GProfiler - " .. GetTabName(name))
		Menu.Title:SizeToContents()
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
	concommand.Add(GProfiler.Config.MenuCommands.Console, Menu.Open)
end

local function InterScale(h) return math.Round((h / 2160) * ScrH()) end
local function CreateFonts()
	CachedSizes = {}
	surface.CreateFont("GProfiler.HeaderTitle", { font = "Inter Bold", size = InterScale(64), weight = 800, antialias = true })
	surface.CreateFont("GProfiler.InnerTitle", { font = "Inter Bold", size = InterScale(44), weight = 800, antialias = true })
	surface.CreateFont("GProfiler.HeaderSubtitle", { font = "Inter", size = InterScale(24), weight = 400, antialias = true })
	surface.CreateFont("GProfiler.Menu.TabText", { font = "Inter Bold", size = InterScale(38), weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Menu.TabBadge", { font = "Inter Bold", size = InterScale(32), weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Code", { font = "Roboto", size = GProfiler.GetScaledSize(22), weight = 500 })
	surface.CreateFont("GProfiler.HeaderInteract", { font = "Inter", size = InterScale(32), weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Inter24", { font = "Inter", size = InterScale(24), weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Inter28", { font = "Inter", size = InterScale(28), weight = 500, antialias = true })

	surface.CreateFont("GProfiler.Graph.Title", { font = "Inter", size = InterScale(26), weight = 500, antialias = true })
	surface.CreateFont("GProfiler.Graph.Small", { font = "Inter", size = InterScale(20), weight = 500, antialias = true })
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "GProfiler.Menu.RescaleFonts", CreateFonts)
