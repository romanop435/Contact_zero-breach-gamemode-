if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Stunstick"
SWEP.Instructions = "Metrocop issued electrified melee weapon used for stopping riots and misbehavings. Pick up dat can."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_pipe_lead.mdl"
SWEP.WorldModelExchange = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModel = ""

SWEP.HoldType = "melee"

SWEP.HoldPos = Vector(-13,0,0)

SWEP.AttackTime = 0.4
SWEP.AnimTime1 = 1.3
SWEP.WaitTime1 = 1
SWEP.ViewPunch1 = Angle(0,-5,3)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-4)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(-0.5,1,0)
SWEP.weaponAng = Angle(90,0,90)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 20
SWEP.DamageSecondary = 14

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 3

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 20
SWEP.StaminaSecondary = 15

SWEP.AttackLen1 = 55
SWEP.AttackLen2 = 30

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_stunstick")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_stunstick"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true

SWEP.AttackSwing = "weapons/stunstick/stunstick_swing1.wav"
SWEP.AttackHit = "weapons/stunstick/stunstick_impact1.wav"
SWEP.Attack2Hit = "weapons/stunstick/stunstick_impact1.wav"
SWEP.AttackHitFlesh = "weapons/stunstick/stunstick_fleshhit1.wav"
SWEP.Attack2HitFlesh = "weapons/stunstick/stunstick_fleshhit1.wav"
SWEP.DeploySnd = "weapons/stunstick/spark1.wav"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanPrimaryAttack()
    self.PainMultiplier = 2
    self.AttackHit = "weapons/stunstick/stunstick_impact1.wav"
    self.Attack2Hit = "weapons/stunstick/stunstick_impact1.wav"
    self.AttackHitFlesh = "weapons/stunstick/stunstick_fleshhit1.wav"
    self.Attack2HitFlesh = "weapons/stunstick/stunstick_fleshhit1.wav"
    return true
end

function SWEP:CanSecondaryAttack()
    self.PainMultiplier = 1
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    self.AttackHitFlesh = "Flesh.ImpactHard"
    self.Attack2HitFlesh = "Flesh.ImpactHard"
    return false
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 85
SWEP.AttackRads2 = 0

SWEP.SwingAng = 180
SWEP.SwingAng2 = 0