if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Brick"
SWEP.Instructions = "A heavy construction brick, that can be used as a deadly weapon."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/w_brick.mdl"
SWEP.WorldModelReal = "models/weapons/combatknife/tactical_knife_iw7_vm.mdl"
SWEP.WorldModelExchange = "models/weapons/w_brick.mdl"
SWEP.DontChangeDropped = true

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_brick")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_brick"
	SWEP.BounceWeaponIcon = false
end

SWEP.weaponPos = Vector(0,-1,0)
SWEP.weaponAng = Angle(0,0,0)

SWEP.AttackHit = "Concrete.ImpactHard"
SWEP.Attack2Hit = "Concrete.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "Concrete.ImpactHard"

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 15
SWEP.DamageSecondary = 8

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 2

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 15
SWEP.StaminaSecondary = 10

SWEP.AttackTime = 0.25
SWEP.AnimTime1 = 0.7
SWEP.WaitTime1 = 0.5
SWEP.AttackLen1 = 30

SWEP.Attack2Time = 0.1
SWEP.AnimTime2 = 0.5
SWEP.WaitTime2 = 0.4
SWEP.AttackLen2 = 30

if SERVER then
    local punchang = Angle(0, 0, -8)
    function SWEP:CustomAttack2()
        local ent = ents.Create("ent_throwable")
        ent.WorldModel = self.WorldModelExchange
        local ply = self:GetOwner()
        ent:SetPos(select(1, hg.eye(ply,60,hg.GetCurrentCharacter(ply))) - ply:GetAimVector() * 2)
        ent:SetAngles(ply:EyeAngles())
        ent:SetOwner(self:GetOwner())
        ent:Spawn()
        ent.localshit = Vector(0,0,0)
        ent.wep = self:GetClass()
        ent.owner = ply
        ent.damage = 20
        ent.MaxSpeed = 1300
		ent.DamageType = DMG_CLUB
		ent.AttackHit = "Concrete.ImpactHard"
		ent.AttackHitFlesh = "Flesh.ImpactHard"
        ent.noStuck = true
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(ply:GetAimVector() * ent.MaxSpeed)
            phys:AddAngleVelocity(VectorRand() * 500)
        end
        ply:EmitSound("weapons/slam/throw.wav",50,math.random(95,105))
        ply:ViewPunch(punchang)
        ply:SelectWeapon("weapon_hands_sh")
        self:Remove()
        return true
    end
end
-- УЖЕ НЕ НУЖНОЕ ГОВНО!!!!
SWEP.Swing = false -- Это отвесает за первый вид удара, изначально с права на лево 
SWEP.LSwing = false -- Это отвесает за второй вид удара, изначально с права на лево
SWEP.SwingLeft = false -- Это отвесает за первый вид удара, переключает с лева на право
SWEP.LSwingLeft = false -- Это отвесает за второй вид удара, переключает с лева на право
SWEP.UpSwing = true -- Это отвесает за первый вид удара, Сверху вниз
SWEP.LUpSwing = false -- Это отвесает за второй вид удара, Сверху вниз

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.001

SWEP.AttackRads = 35
SWEP.AttackRads2 = 0

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0