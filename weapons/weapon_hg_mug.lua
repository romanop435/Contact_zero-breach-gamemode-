if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Сoffee Mug"
SWEP.Instructions = "Probably someone's favorite mug that you decided to use for something other than coffee."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/props_junk/garbage_coffeemug001a.mdl"
SWEP.WorldModelReal = "models/weapons/combatknife/tactical_knife_iw7_vm.mdl"
SWEP.WorldModelExchange = "models/props_junk/garbage_coffeemug001a.mdl"

SWEP.weaponPos = Vector(0,0.4,-3.8)
SWEP.weaponAng = Angle(0,-90,90)

SWEP.BreakBoneMul = 0.25

SWEP.AnimList = {
    ["idle"] = "vm_knifeonly_idle",
    ["deploy"] = "vm_knifeonly_raise",
    ["attack"] = "vm_knifeonly_stab",
    ["attack2"] = "vm_knifeonly_swipe",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/icons/ico_mug.png")
	SWEP.IconOverride = "vgui/icons/ico_mug.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true


SWEP.NoHolster = true

SWEP.AttackPos = Vector(0,0,0)
SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 15
SWEP.DamageSecondary = 12

SWEP.PenetrationPrimary = 1.3
SWEP.PenetrationSecondary = 1

SWEP.MaxPenLen = 4

SWEP.PainMultiplier = 0.5

SWEP.PenetrationSizePrimary = 1
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 6
SWEP.StaminaSecondary = 3

SWEP.AttackLen1 = 45
SWEP.AttackLen2 = 30


SWEP.AttackHit = "GlassBottle.ImpactHard"
SWEP.Attack2Hit = "GlassBottle.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "GlassBottle.ImpactSoft"

function SWEP:PrimaryAttackAdd(ent,trace)
    if SERVER and ent and math.random(1,2) == 2 then -- я либо забыл это добавить либо ктото убрал если шо простите
        self:PrecacheGibs()
        self:GibBreakServer(trace.HitNormal * -100)
        self:GetOwner():EmitSound("physics/glass/glass_pottery_break"..math.random(1,4)..".wav")
        self:Remove()
    end
end

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:SecondaryAttackAdd(ent,trace)
    if SERVER and ent and math.random(1,2) == 2 then
        self:PrecacheGibs()
        self:GibBreakServer(trace.HitNormal * -100)
        self:GetOwner():EmitSound("physics/glass/glass_pottery_break"..math.random(1,4)..".wav")
        self:Remove()
    end
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 45
SWEP.AttackRads2 = 0

SWEP.SwingAng = -85
SWEP.SwingAng2 = 0