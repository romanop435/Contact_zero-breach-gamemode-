if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Big bandage"
SWEP.Instructions = "A wad of gauze bandage, can help stop light bleeding. Since the bandage is not in its packaging, there is little chance that it is sterilized. RMB to use on someone else."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.modeValuesdef = {
	[1] = {80, true},
}

SWEP.ModelScale = 1
SWEP.offsetVec = Vector(3, -4.5, 0)
SWEP.offsetAng = Angle(90, 90, 0)
SWEP.Category = "Medicine"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_bandage")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_bandage.png"
	SWEP.BounceWeaponIcon = false
end

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	self.ModelScale = 1.1
	self.modeValues = {
		[1] = 80,
	}
end