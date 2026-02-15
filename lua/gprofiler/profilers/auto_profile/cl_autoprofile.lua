local ProfilerList = {
	"Hooks", "Networking", "Functions", "Commands", "Timers",
	--[["Entity Variables",]] "Network Variables", "Database"
}

local CurrentStates = {}
local DropdownOptions = {
	["Disabled"] = 0,
	["As soon as possible"] = 1,
	["When the gamemode is fully loaded"] = 2,
	["When a player joins the server"] = 3,
}

local Black50 = Color(0, 0, 0, 50)

local MenuColors = GProfiler.MenuColors
function GProfiler.AutoProfileTab(Content)
	local Header = vgui.Create("DPanel", Content)
	Header:SetSize(Content:GetWide() - 10, 150)
	Header:SetPos(5, 10)
	Header.Paint = nil

	local Text = [[
		Here you can configure profilers to start automatically!
		You can choose to have the profiler start as soon as possible (when GProfiler loads), when the gamemode is fully loaded, or when a player joins the server.

		Currently, this is limited to the Server Realm.
	]]

	local TextLabel = vgui.Create("DLabel", Header)
	TextLabel:SetFont("GProfiler.Menu.TabText")
	TextLabel:SetText(Text)
	TextLabel:SetWrap(true)
	TextLabel:SetAutoStretchVertical(true)
	TextLabel:SizeToContents()
	TextLabel:SetWide(Header:GetWide() - 20)
	TextLabel:SetPos(10, 10)
	TextLabel:SetTextColor(MenuColors.White)

	local TabContent = vgui.Create("DPanel", Content)
	TabContent:SetSize(Content:GetWide() - 10, Content:GetTall() - Header:GetTall() - 25)
	TabContent:SetPos(5, Header:GetTall() + 20)
	TabContent.Paint = nil

	local Profilers = vgui.Create("DPanelList", TabContent)
	Profilers:SetSize(TabContent:GetWide(), TabContent:GetTall())
	Profilers:EnableVerticalScrollbar(true)
	Profilers:EnableHorizontal(false)
	Profilers:SetSpacing(5)
	Profilers:SetPadding(5)

	for k, v in ipairs(ProfilerList) do
		local Profiler = vgui.Create("DPanel", Profilers)
		Profiler:SetSize(Profilers:GetWide(), 70)
		Profiler.Paint = function(s, w, h)
			draw.RoundedBox(4, 2, 2, w - 4, h - 4, MenuColors.DListRowBackground)
			draw.RoundedBox(4, 4, 4, w - 8, h - 8, Black50)

			draw.SimpleText(v, "GProfiler.Menu.Title", 10, h / 2, MenuColors.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		surface.SetFont("GProfiler.Menu.RealmSelector")
		local textWidth, textHeight = surface.GetTextSize("When the gamemode is fully loaded")

		local Dropdown = vgui.Create("DComboBox", Profiler)
		Dropdown:SetSize(textWidth + 20, 30)
		Dropdown:SetPos(Profiler:GetWide() - Dropdown:GetWide() - 40, Profiler:GetTall() / 2 - Dropdown:GetTall() / 2)
		Dropdown:SetValue(CurrentStates[v] or "Disabled")
		Dropdown:SetTextColor(MenuColors.White)
		Dropdown:SetFont("GProfiler.Menu.RealmSelector")
		Dropdown:SetTall(30)
		Dropdown:SetWide(Dropdown:GetWide() + 10)
		Dropdown:SetSortItems(false)
		Dropdown.OnSelect = function(s, index, value, data)
			net.Start("GProfiler.AutoProfile.Configure")
			net.WriteString(v)
			net.WriteUInt(DropdownOptions[value], 2)
			net.SendToServer()

			CurrentStates[v] = value
		end

		for option, index in SortedPairsByValue(DropdownOptions) do
			Dropdown:AddChoice(option, index)
		end

		GProfiler.StyleDropdown(Dropdown)

		Profilers:AddItem(Profiler)
	end
end

GProfiler.Menu.RegisterTab("Auto Profile", "icon16/map_go.png", 999, GProfiler.AutoProfileTab)

net.Receive("GProfiler.AutoProfile.SendState", function()
	for i = 1, net.ReadUInt(4) do
		local profiler = net.ReadString()
		local state = net.ReadUInt(2)

		CurrentStates[profiler] = table.KeyFromValue(DropdownOptions, state)
	end
end)