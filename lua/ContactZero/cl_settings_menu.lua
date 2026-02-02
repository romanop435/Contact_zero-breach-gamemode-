if SERVER then return end

hg = hg or {}
if not hg.Breach then
	include("ContactZero/breach/sh_breach.lua")
end

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font")
	or CreateClientConVar("hg_font", "Bahnschrift", true, false, "ui font")

local function uiFont()
	local font = hg_font:GetString()
	if font == "" then
		font = "Bahnschrift"
	end
	return font
end

surface.CreateFont("CZ_Menu_Title", {
	font = uiFont(),
	size = 30,
	weight = 900
})

surface.CreateFont("CZ_Menu_Tab", {
	font = uiFont(),
	size = 18,
	weight = 800
})

surface.CreateFont("CZ_Menu_Section", {
	font = uiFont(),
	size = 16,
	weight = 700
})

surface.CreateFont("CZ_Menu_Text", {
	font = uiFont(),
	size = 14,
	weight = 600
})

surface.CreateFont("CZ_Menu_Small", {
	font = uiFont(),
	size = 12,
	weight = 600
})

local colors = {
	bg = Color(8, 10, 16, 238),
	bgSoft = Color(12, 16, 24, 230),
	panel = Color(14, 18, 28, 230),
	panelEdge = Color(255, 255, 255, 14),
	accent = Color(92, 195, 205, 255),
	accentSoft = Color(92, 195, 205, 80),
	text = Color(235, 238, 242, 230),
	muted = Color(160, 170, 185, 200),
	dark = Color(0, 0, 0, 160)
}

local gradUp = Material("vgui/gradient-u")
local gradDown = Material("vgui/gradient-d")

local function drawCorners(x, y, w, h, size, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, size, 1)
	surface.DrawRect(x, y, 1, size)
	surface.DrawRect(x + w - size, y, size, 1)
	surface.DrawRect(x + w - 1, y, 1, size)
	surface.DrawRect(x, y + h - 1, size, 1)
	surface.DrawRect(x, y + h - size, 1, size)
	surface.DrawRect(x + w - size, y + h - 1, size, 1)
	surface.DrawRect(x + w - 1, y + h - size, 1, size)
end

local function styleScroll(scroll)
	local bar = scroll:GetVBar()
	if not IsValid(bar) then return end
	bar:SetWide(6)
	function bar:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end
	function bar.btnUp:Paint() end
	function bar.btnDown:Paint() end
	function bar.btnGrip:Paint(w, h)
		surface.SetDrawColor(colors.accentSoft)
		surface.DrawRect(0, 0, w, h)
	end
end

local function addSection(parent, text)
	local section = vgui.Create("DPanel", parent)
	section:Dock(TOP)
	section:DockMargin(0, 6, 0, 8)
	section:SetTall(28)
	section.Paint = function(self, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawRect(0, h - 1, w, 1)
	end

	local label = vgui.Create("DLabel", section)
	label:SetText(text)
	label:SetFont("CZ_Menu_Section")
	label:SetTextColor(colors.text)
	label:SizeToContents()
	label:SetPos(4, 4)
	return section
end

local function addCheckbox(parent, text, convar, hint)
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 6)
	row:SetTall(30)
	row.Paint = function(self, w, h)
		surface.SetDrawColor(colors.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local box = vgui.Create("DCheckBox", row)
	box:SetPos(8, 7)
	box:SetSize(16, 16)
	if convar and convar ~= "" then
		box:SetConVar(convar)
	end
	box.Paint = function(self, w, h)
		surface.SetDrawColor(colors.dark)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
		if self:GetChecked() then
			surface.SetDrawColor(colors.accent)
			surface.DrawRect(3, 3, w - 6, h - 6)
		end
	end

	local label = vgui.Create("DLabel", row)
	label:SetFont("CZ_Menu_Text")
	label:SetTextColor(colors.text)
	label:SetText(text)
	label:SizeToContents()
	label:SetPos(32, 6)

	if hint and hint ~= "" then
		local hintLabel = vgui.Create("DLabel", row)
		hintLabel:SetFont("CZ_Menu_Small")
		hintLabel:SetTextColor(colors.muted)
		hintLabel:SetText(hint)
		hintLabel:SizeToContents()
		hintLabel:SetPos(32, 16)
	end

	return row
end

local function addSlider(parent, text, convar, minVal, maxVal, decimals)
	local slider = vgui.Create("DNumSlider", parent)
	slider:Dock(TOP)
	slider:DockMargin(0, 0, 0, 8)
	slider:SetText(text)
	slider:SetMin(minVal)
	slider:SetMax(maxVal)
	slider:SetDecimals(decimals or 0)
	if convar and convar ~= "" then
		slider:SetConVar(convar)
	end
	slider.Label:SetFont("CZ_Menu_Text")
	slider.Label:SetTextColor(colors.text)
	slider.TextArea:SetFont("CZ_Menu_Small")
	slider.TextArea:SetTextColor(colors.muted)
	slider.Slider:SetTall(12)

	slider.Slider.Paint = function(self, w, h)
		surface.SetDrawColor(colors.dark)
		surface.DrawRect(0, h / 2 - 1, w, 2)
		surface.SetDrawColor(colors.accentSoft)
		surface.DrawRect(0, h / 2 - 1, w * (slider:GetValue() - minVal) / (maxVal - minVal), 2)
	end
	slider.Slider.Knob.Paint = function(self, w, h)
		surface.SetDrawColor(colors.accent)
		surface.DrawRect(0, 2, w, h - 4)
	end

	return slider
end

local function addSpacer(parent, height)
	local spacer = vgui.Create("DPanel", parent)
	spacer:Dock(TOP)
	spacer:SetTall(height or 8)
	spacer.Paint = function() end
	return spacer
end

CZ_SettingsMenu = CZ_SettingsMenu or {}

function CZ_SettingsMenu.Open()
	if IsValid(CZ_SettingsMenu.Frame) then
		CZ_SettingsMenu.Frame:Remove()
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(math.floor(ScrW() * 0.9), math.floor(ScrH() * 0.86))
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.2, 0)
	frame.startTime = SysTime()
	frame.Paint = function(self, w, h)
		Derma_DrawBackgroundBlur(self, self.startTime)
		surface.SetDrawColor(colors.bg)
		surface.DrawRect(0, 0, w, h)

		surface.SetMaterial(gradDown)
		surface.SetDrawColor(10, 12, 18, 120)
		surface.DrawTexturedRect(0, 0, w, h)

		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
		drawCorners(0, 0, w, h, 12, colors.accentSoft)
	end

	frame.OnRemove = function()
		gui.EnableScreenClicker(false)
	end

	local top = vgui.Create("DPanel", frame)
	top:Dock(TOP)
	top:SetTall(64)
	top.Paint = function(self, w, h)
		surface.SetDrawColor(colors.bgSoft)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawRect(0, h - 1, w, 1)
	end

	local title = vgui.Create("DLabel", top)
	title:SetFont("CZ_Menu_Title")
	title:SetTextColor(colors.text)
	title:SetText("Contact Zero")
	title:SizeToContents()
	title:SetPos(24, 16)

	local navButtons = {
		{ text = "Играть", active = false },
		{ text = "Настройки", active = true },
		{ text = "Сервисы", active = false },
		{ text = "Выйти", active = false }
	}

	local nav = vgui.Create("DPanel", top)
	nav:Dock(RIGHT)
	nav:SetWide(520)
	nav:DockMargin(0, 10, 12, 10)
	nav.Paint = function() end

	for i, data in ipairs(navButtons) do
		local btn = vgui.Create("DButton", nav)
		btn:Dock(LEFT)
		btn:DockMargin(6, 0, 0, 0)
		btn:SetWide(120)
		btn:SetText("")
		btn.Paint = function(self, w, h)
			local active = data.active
			surface.SetDrawColor(active and colors.accentSoft or colors.dark)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(colors.panelEdge)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.SimpleText(data.text, "CZ_Menu_Tab", w / 2, h / 2, active and colors.accent or colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			if data.text == "Выйти" then
				frame:Close()
			end
		end
	end

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body:DockMargin(12, 12, 12, 12)
	body.Paint = function() end

	local left = vgui.Create("DPanel", body)
	left:Dock(LEFT)
	left:SetWide(220)
	left:DockMargin(0, 0, 10, 0)
	left.Paint = function(self, w, h)
		surface.SetDrawColor(colors.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local main = vgui.Create("DPanel", body)
	main:Dock(FILL)
	main:DockMargin(0, 0, 10, 0)
	main.Paint = function(self, w, h)
		surface.SetDrawColor(colors.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local right = vgui.Create("DPanel", body)
	right:Dock(RIGHT)
	right:SetWide(270)
	right.Paint = function(self, w, h)
		surface.SetDrawColor(colors.panel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local rightBanner = vgui.Create("DPanel", right)
	rightBanner:Dock(TOP)
	rightBanner:SetTall(180)
	rightBanner:DockMargin(10, 10, 10, 8)
	rightBanner.Paint = function(self, w, h)
		surface.SetDrawColor(6, 6, 10, 240)
		surface.DrawRect(0, 0, w, h)
		surface.SetMaterial(gradUp)
		surface.SetDrawColor(colors.accentSoft)
		surface.DrawTexturedRect(0, 0, w, h)
		drawCorners(0, 0, w, h, 10, colors.accentSoft)
		draw.SimpleText("Обновления", "CZ_Menu_Tab", 12, 12, colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Настройки системы", "CZ_Menu_Small", 12, 34, colors.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local rightList = vgui.Create("DLabel", right)
	rightList:Dock(TOP)
	rightList:DockMargin(16, 0, 16, 0)
	rightList:SetFont("CZ_Menu_Small")
	rightList:SetTextColor(colors.muted)
	rightList:SetText("- Оптимизация плавности\n- Новые профили камеры\n- Настройки эффекта дыхания\n- Пакеты звука и фона")
	rightList:SetAutoStretchVertical(true)
	rightList:SetWrap(true)
	rightList:SetContentAlignment(7)

	local navScroll = vgui.Create("DScrollPanel", left)
	navScroll:Dock(FILL)
	navScroll:DockMargin(6, 8, 6, 8)
	styleScroll(navScroll)

	local pages = {}
	local current = nil

	local function showPage(id)
		current = id
		for key, panel in pairs(pages) do
			panel:SetVisible(key == id)
		end
		for _, btn in ipairs(navScroll:GetChildren()) do
			if IsValid(btn) and btn.CZ_PageId then
				btn.CZ_Selected = btn.CZ_PageId == id
			end
		end
	end

	local function addCategory(id, name, build)
		local btn = vgui.Create("DButton", navScroll)
		btn:Dock(TOP)
		btn:DockMargin(0, 0, 0, 6)
		btn:SetTall(34)
		btn:SetText("")
		btn.CZ_PageId = id
		btn.CZ_Selected = false
		btn.Paint = function(self, w, h)
			local active = self.CZ_Selected
			surface.SetDrawColor(active and colors.accentSoft or colors.dark)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(colors.panelEdge)
			surface.DrawOutlinedRect(0, 0, w, h)
			draw.SimpleText(name, "CZ_Menu_Text", 10, h / 2, active and colors.accent or colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			showPage(id)
		end

		local page = vgui.Create("DScrollPanel", main)
		page:Dock(FILL)
		page:DockMargin(10, 10, 10, 10)
		page:SetVisible(false)
		styleScroll(page)
		build(page)
		pages[id] = page
	end



	addCategory("sound", "Звук", function(panel)
		addSection(panel, "Окружение")
		addSlider(panel, "Громкость амбиента", "cz_ambient_volume", 0, 1, 2)
		if ConVarExists("hg_dmusic") then
			addCheckbox(panel, "Динамическая музыка", "hg_dmusic", "Фоновая музыка по ситуации")
		end
	end)

	addCategory("hud", "Интерфейс", function(panel)
		addSection(panel, "Интерфейс")
		addCheckbox(panel, "Показывать HUD", "cl_drawhud", "Скрыть стандартный HUD")
		addSlider(panel, "Громкость чата", "voice_scale", 0, 1, 2)
		addSpacer(panel, 6)
		addSection(panel, "Match")
		addCheckbox(panel, "Disable SCP spawn", "cz_optout_scp", "Never spawn as SCP")
	end)


	showPage("sound")

	local close = vgui.Create("DButton", frame)
	close:SetText("")
	close:SetSize(36, 28)
	close:SetPos(frame:GetWide() - 52, 18)
	close.Paint = function(self, w, h)
		local hover = self:IsHovered()
		surface.SetDrawColor(hover and Color(200, 70, 70, 200) or colors.dark)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colors.panelEdge)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("X", "CZ_Menu_Tab", w / 2, h / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close.DoClick = function()
		frame:Close()
	end

	CZ_SettingsMenu.Frame = frame
	gui.EnableScreenClicker(true)
end

concommand.Add("cz_settings", function()
	CZ_SettingsMenu.Open()
end)
