if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Broken Bottle"
SWEP.Instructions = "Broken beer bottle, looks like someone was too drunk."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HoldType = "melee"

SWEP.WorldModel = "models/props_junk/glassbottle01a_chunk01a.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_kitknife.mdl"
SWEP.WorldModelExchange = "models/props_junk/glassbottle01a_chunk01a.mdl"

SWEP.BreakBoneMul = 0.1

SWEP.AnimTime1 = 1.0
SWEP.AttackTime = 0.2
SWEP.WaitTime1 = 0.5

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/icons/ico_botle_broken.png")
	SWEP.IconOverride = "vgui/icons/ico_botle_broken.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true

SWEP.NoHolster = true

SWEP.DamagePrimary = 9

SWEP.PenetrationPrimary = 1.3

SWEP.StaminaPrimary = 15

SWEP.BleedMultiplier = 1.5

SWEP.AttackLen1 = 40

SWEP.AttackHit = "GlassBottle.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_slash.wav"

SWEP.DeploySnd = "GlassBottle.ImpactSoft"

SWEP.DamageType = DMG_SLASH
SWEP.PainMultiplier = .4
SWEP.MaxPenLen = 0.7
SWEP.PenetrationSizePrimary = 1.2

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.HoldAng = Angle(30, 0, -22)
SWEP.HoldPos = Vector(-7,4,8)
SWEP.weaponAng = Angle(180,0,-5)
SWEP.basebone = 95

function SWEP:CanSecondaryAttack()
    return false
end

SWEP.weaponPos = Vector(-0.2,0.5,1.8)
SWEP.AttackPos = Vector(-3,8,-20)

function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and ent and math.random(1, self:IsEntSoft(ent) and 30 or 10) == 1 then
        self:PrecacheGibs()
        self:GibBreakServer(trace.HitNormal * -100)
        self:GetOwner():EmitSound("physics/glass/glass_pottery_break" .. math.random(1, 4) .. ".wav")
        self:Remove()
    end
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 65
SWEP.AttackRads2 = 0

SWEP.SwingAng = -35
SWEP.SwingAng2 = 0