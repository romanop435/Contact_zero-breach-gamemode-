if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Buck 120 General"
SWEP.Instructions = "Large hunting knife, has a blood drain, which allows you to make stabs with strong bleeding. Used in the movie Scream as the killer's primary weapon. LMB to stab. RMB to slash."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/combatknife/tactical_knife_iw7_wm.mdl"
SWEP.WorldModelReal = "models/weapons/combatknife/tactical_knife_iw7_vm.mdl"
SWEP.WorldModelExchange = "models/zcity/weapons/custom_knife/buck.mdl"
SWEP.DontChangeDropped = true
SWEP.modelscale = 1.2
SWEP.modelscale2 = 1

SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 1.8

SWEP.DamagePrimary = 15
SWEP.DamageSecondary = 4

SWEP.setlh = false
SWEP.setrh = true

SWEP.basebone = 1

SWEP.HoldType = "knife"

SWEP.weaponPos = Vector(0,0.2,-0.6)
SWEP.weaponAng = Angle(0,90,0)

--SWEP.InstantPainMul = 0.25

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
    local mat = Material("vgui/icons/ico_buck120.png")
	SWEP.WepSelectIcon = Material("vgui/icons/ico_buck120.png")
	SWEP.IconOverride = "vgui/icons/ico_buck120.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.BreakBoneMul = 0.5
SWEP.ImmobilizationMul = 0.45
SWEP.StaminaMul = 0.5

SWEP.HoldAng = Angle(-5,-5,15)
SWEP.attack_ang = Angle(-55,23,0)

function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetAttackLength(60)
    self:SetAttackWait(0)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
        self:SecondaryAttack()
        self.allowsec = nil
        return false
    end
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.Swing = false -- Это отвесает за первый вид удара, изначально с права на лево
SWEP.LSwing = true -- Это отвесает за второй вид удара, изначально с права на лево
SWEP.SwingLeft = false -- Это отвесает за первый вид удара, переключает с лева на право
SWEP.LSwingLeft = false -- Это отвесает за второй вид удара, переключает с лева на право
SWEP.UpSwing = true -- Это отвесает за первый вид удара, Сверху вниз
SWEP.LUpSwing = false -- Это отвесает за второй вид удара, Сверху вниз

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.15

SWEP.AttackRads = 35
SWEP.AttackRads2 = 65

SWEP.SwingAng = -80
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true

SWEP.HadBackBonus = true