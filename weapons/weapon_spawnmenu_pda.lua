if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tpik1_base"
SWEP.PrintName = "Tablet"
SWEP.Instructions = ""
SWEP.Category = "Weapons - Other"
SWEP.Instructions = "Just a tablet"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_phone")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_phone"
	SWEP.BounceWeaponIcon = false
end

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.WorldModel = "models/nirrti/tablet/tablet_sfm.mdl"
SWEP.ViewModel = ""
SWEP.HoldType = "normal"

SWEP.setrhik = true
SWEP.setlhik = true

SWEP.LHPos = Vector(0, -6.6, 0)
SWEP.LHAng = Angle(0, 0, 180)

SWEP.RHPosOffset = Vector(0, 0, -7.6)
SWEP.RHAngOffset = Angle(0, 15, -90)

SWEP.LHPosOffset = Vector(0, 0, -0.4)
SWEP.LHAngOffset = Angle(5, 0, 15)

SWEP.handPos = Vector(0, 0, 0)
SWEP.handAng = Angle(0, 0, 0)

SWEP.UsePistolHold = false

SWEP.offsetVec = Vector(5, -7, -1)
SWEP.offsetAng = Angle(0, 90, 195)

SWEP.HeadPosOffset = Vector(15, 1.7, -5)
SWEP.HeadAngOffset = Angle(-90, 0, -90)

SWEP.BaseBone = "ValveBiped.Bip01_Head1"

SWEP.HoldLH = "normal"
SWEP.HoldRH = "normal"

SWEP.HoldClampMax = 35
SWEP.HoldClampMin = 35

SWEP.Skin = 1

function SWEP:PrimaryAttack()
	if CLIENT and IsValid(self.menu) then
		self.menu:SetMouseInputEnabled(true)
		self.menu:SetKeyboardInputEnabled(true)
		self.menu:MakePopup()
		self.MouseHasControl = true
		gui.EnableScreenClicker(true)
	end
end

function SWEP:SecondaryAttack()
end

if SERVER then return end

local function canShowPDA(ply)
	if not IsValid(ply) then return false end
	if ply:GetNWBool("CZ_NoOrganism", false) then return false end
	if hg and hg.Breach then
		if hg.Breach.IsSCP and hg.Breach.IsSCP(ply) then return false end
		if hg.Breach.IsSpectator and hg.Breach.IsSpectator(ply) then return false end
	end
	return true
end

function SWEP:CreateMenu()
	if IsValid(self.menu) then self.menu:Remove() end

	self.menu = vgui.Create("DFrame")
	self.menu:SetSize(625, 468)
	self.menu:Center()
	self.menu:SetY(ScrH() - 470)
	self.menu:SetTitle("PDA")
	self.menu:SetDraggable(false)
	self.menu:ShowCloseButton(false)
	self.menu:SetMouseInputEnabled(false)
	self.menu:SetKeyboardInputEnabled(false)
	self.menu.bNoBackgroundBlur = true
	self.menu.NoBlur = true

	local tablet = self
	function self.menu:Think()
		local wep = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon() or nil
		if not IsValid(wep) or wep:GetClass() ~= "weapon_spawnmenu_pda" or not canShowPDA(LocalPlayer()) then
			if tablet.MouseHasControl then
				gui.EnableScreenClicker(false)
				tablet.MouseHasControl = false
				self:SetMouseInputEnabled(false)
				self:SetKeyboardInputEnabled(false)
			end
		end
		if not IsValid(tablet) then
			gui.EnableScreenClicker(false)
			self:Remove()
		end
	end

	local toolbar = vgui.Create("DPanel", self.menu)
	toolbar:Dock(TOP)
	toolbar:SetTall(30)
	toolbar.Paint = function() end

	local timeLabel = vgui.Create("DLabel", toolbar)
	timeLabel:Dock(FILL)
	timeLabel:SetFont("ZCity_Fixed_SuperTiny")
	timeLabel:SetContentAlignment(5)
	function timeLabel:Think()
		self:SetText(os.date("%H:%M"))
	end

	local sheet = vgui.Create("DPropertySheet", self.menu)
	sheet:Dock(FILL)

	local info = vgui.Create("DPanel", sheet)
	info:Dock(FILL)
	info.Paint = function() end

	local title = vgui.Create("DLabel", info)
	title:SetFont("ZCity_Fixed_Tiny")
	title:SetText("Player Info")
	title:Dock(TOP)
	title:DockMargin(10, 10, 10, 4)
	title:SetContentAlignment(7)

	local nameLabel = vgui.Create("DLabel", info)
	nameLabel:SetFont("ZCity_Fixed_Tiny")
	nameLabel:SetText("Name:")
	nameLabel:Dock(TOP)
	nameLabel:DockMargin(10, 0, 10, 2)
	nameLabel:SetContentAlignment(7)

	local hpLabel = vgui.Create("DLabel", info)
	hpLabel:SetFont("ZCity_Fixed_Tiny")
	hpLabel:SetText("HP:")
	hpLabel:Dock(TOP)
	hpLabel:DockMargin(10, 0, 10, 2)
	hpLabel:SetContentAlignment(7)

	local bleedLabel = vgui.Create("DLabel", info)
	bleedLabel:SetFont("ZCity_Fixed_Tiny")
	bleedLabel:SetText("Bleeding:")
	bleedLabel:Dock(TOP)
	bleedLabel:DockMargin(10, 0, 10, 2)
	bleedLabel:SetContentAlignment(7)

	local legsLabel = vgui.Create("DLabel", info)
	legsLabel:SetFont("ZCity_Fixed_Tiny")
	legsLabel:SetText("Broken leg:")
	legsLabel:Dock(TOP)
	legsLabel:DockMargin(10, 0, 10, 2)
	legsLabel:SetContentAlignment(7)

	local bloodLabel = vgui.Create("DLabel", info)
	bloodLabel:SetFont("ZCity_Fixed_Tiny")
	bloodLabel:SetText("Blood:")
	bloodLabel:Dock(TOP)
	bloodLabel:DockMargin(10, 0, 10, 2)
	bloodLabel:SetContentAlignment(7)

	function info:Think()
		if not IsValid(tablet) then return end
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local displayName = ply:Nick()
		if hg and hg.Breach and hg.Breach.GetDisplayName then
			displayName = hg.Breach.GetDisplayName(ply)
		end

		local hp = math.max(0, ply:Health())
		local maxHp = math.max(ply:GetMaxHealth(), 1)
		local bleeding = ply:GetNWBool("CZ_Bleeding", false)
		local legs = ply:GetNWBool("CZ_LegsBroken", false)
		local liters = 0
		if ply.BloodLevel ~= nil then
			liters = math.max(0, tonumber(ply.BloodLevel) or 0) / 1000
		end

		nameLabel:SetText("Name: " .. displayName)
		hpLabel:SetText(string.format("HP: %d / %d", hp, maxHp))
		bleedLabel:SetText("Bleeding: " .. (bleeding and "YES" or "NO"))
		legsLabel:SetText("Broken leg: " .. (legs and "YES" or "NO"))
		bloodLabel:SetText(string.format("Blood: %.1f L", liters))
	end

	sheet:AddSheet("Info", info)
end

function SWEP:AddDrawModel(ent)
	if not IsValid(self.menu) then self:CreateMenu() end
	if not canShowPDA(LocalPlayer()) then return end
	if IsValid(self:GetOwner()) and self:GetOwner() ~= LocalPlayer() then return end
	local ply = LocalPlayer()
	if not IsValid(ply) or ply:GetActiveWeapon() ~= self then return end

	local pos, ang = ent:GetRenderOrigin(), ent:GetRenderAngles()
	pos = pos + ang:Up() * 1.2 + ang:Forward() * -14.82 + ang:Right() * -12.7
	local scale = 0.0151
	vgui.Start3D2D(pos, ang, scale)
		self.menu:Paint3D2D()
	vgui.End3D2D()
end
