if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_hg_grenade"
SWEP.PrintName = "Snowball"
SWEP.Instructions = "funnies"
SWEP.Category = "Weapons - Other"
SWEP.Spawnable = true
SWEP.HoldType = "grenade"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/zerochain/props_christmas/snowballswep/zck_w_snowballswep.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_snowball")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_snowball"
	SWEP.BounceWeaponIcon = false
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.ENT = "ent_hg_snowball"

SWEP.nofunnyfunctions = true
SWEP.timetothrow = 0.1

SWEP.throwsound = ""

SWEP.offsetVec = Vector(3, -2, -1)
SWEP.offsetAng = Angle(145, 0, 0)
SWEP.NoTrap = true

function SWEP:OnDrop()
	self:Remove()
end