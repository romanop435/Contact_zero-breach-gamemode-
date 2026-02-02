if SERVER then AddCSLuaFile() end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ent_hg_slam"
ENT.Spawnable = false
ENT.WorldModel = "models/weapons/w_slam.mdl"

ENT.SoundFar = {"iedins/ied_detonate_dist_01.wav", "ied/ied_detonate_dist_02.wav", "ied/ied_detonate_dist_03.wav"}
ENT.Sound = {"ied/ied_detonate_01.wav", "ied/ied_detonate_02.wav", "ied/ied_detonate_03.wav"}
ENT.SoundWater = "iedins/water/ied_water_detonate_01.wav"
ENT.BlastDis = 3
ENT.BlastDamage = 70

if SERVER then
    function ENT:Initialize()
        self:SetModel(self.WorldModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)  -- ниггер
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(SIMPLE_USE) 
        self:DrawShadow(true)
        

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(true)
            --phys:Sleep()
        end
        
        
        if IsValid(phys) then
            phys:SetMass(20)
        end
    end
    

    function ENT:Use(activator, caller)
        return false
    end
    

    function ENT:PhysgunPickup(ply, ent)
       -- return false
    end
end

local developer = GetConVar("developer")
local offsetPos, offsetAng = Vector(0, 0, 6), Angle(-90, 180, 0)

function ENT:Think()
    local tr = {}
    local pos, ang = self:GetPos(), self:GetAngles()
    local pos, ang = LocalToWorld(offsetPos, offsetAng, pos, ang)
    tr.start = pos
    tr.endpos = tr.start + ang:Forward() * 700
    tr.filter = self
    tr.collisiongroup = COLLISION_GROUP_PLAYER
    local tr = util.TraceLine(tr)

    --if developer:GetBool() and self.owner:IsAdmin() then
    --    debugoverlay.Line(pos, tr.HitPos, 1, color_white, true)
    --end

    if SERVER and tr.Hit and tr.Entity:GetVelocity():LengthSqr() > 1 then
		if tr.Entity:IsPlayer() and tr.Entity.PlayerClassName ~= "sc_guard" then return end
        self:ActivateExplosive()
    end

    self:NextThink(CurTime())
    return true
end

if SERVER then
    function ENT:ActivateExplosive()
        if self.Exploded then return end
        self.Exploded = true
        local selfPos = self:GetPos()
        local pos, ang = LocalToWorld(offsetPos, offsetAng, self:GetPos(), self:GetAngles())

        local bullet = {}
        bullet.Src = pos
        bullet.Penetration = 100
        bullet.Dir = ang:Forward()
        bullet.Force = 100
        bullet.Damage = 250
        bullet.Speed = 1000
        bullet.AmmoType = "14.5x114mm B32" 
        bullet.Attacker = self.owner
        bullet.Distance = 56756
        bullet.Callback = hg.bulletHit
        bullet.Tracer = 10000
		bullet.DisableLagComp = true
		bullet.Filter = {self}
        bullet.HullSize = Vector(5,5,5)

        local num = 120

        local co = coroutine.create(function()
            local LastShrapnel = SysTime()

            for i = 1, num do
                LastShrapnel = SysTime()
                local vecCone = Vector(
                    (i / num) ^ 4 / 5 * 5 * 5 + (math.random(0, 1) and math.random(100) / 100),
                    (i / num) ^ 4 / 2 * 5 + (math.random(0, 1) and math.random(100) / 100),
                    0
                )
                bullet.Spread = vecCone
                bullet.Penetration = math.Clamp(num / i, 5, 10) * 10
                -- for i2 = 1, 5 do
                    --if not IsValid(self) then return end
                if not IsValid(self) then return end
                self:FireLuaBullets(bullet,true)

                LastShrapnel = SysTime() - LastShrapnel

                if LastShrapnel > 0.001 then
                    coroutine.yield()
                end

                self.ShrapnelDone = true
                --end
            end
        end)

        coroutine.resume(co)
        local index = self:EntIndex()
        timer.Create("GrenadeCheck_" .. index, 0, 0, function()
            if !IsValid(self) then
                timer.Remove("GrenadeCheck_" .. index)
            end

            coroutine.resume(co)

            if self.ShrapnelDone then
                util.ScreenShake(selfPos, 20, 20, 1, 500)
                SafeRemoveEntity(self)
                timer.Remove("GrenadeCheck_" .. index)
            end
        end)

        net.Start("projectileFarSound")
            net.WriteString(table.Random(self.Sound))
            net.WriteString(table.Random(self.SoundFar))
            net.WriteVector(selfPos)
            net.WriteEntity(self)
            net.WriteBool(self:WaterLevel() > 0)
            net.WriteString(self.SoundWater)
        net.Broadcast()

        timer.Simple(0.1,function()
            ParticleEffect("pcf_jack_airsplode_small",selfPos+vector_up*-5,vector_up:Angle())
            --hg.ExplosionEffect(selfPos, blastdist, 80)
        end)
        hg.ExplosionEffect(selfPos, self.BlastDis, 5)

        timer.Simple(0, function()
            if not IsValid(self) then return end
            util.BlastDamage(self, Entity(0), selfPos, self.BlastDis / 0.01905, self.BlastDamage * 1)
        end)
    end

    function ENT:OnTakeDamage(dmginfo)
        if dmginfo:GetInflictor() == self then return end
        if dmginfo:IsDamageType(DMG_BLAST + DMG_BULLET + DMG_BUCKSHOT + DMG_BURN) then
            self:ActivateExplosive()
        end
    end
end
