if SERVER then AddCSLuaFile() end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ent_claymore"
ENT.Spawnable = false
ENT.WorldModel = "models/hoff/weapons/seal6_claymore/w_claymore.mdl"

ENT.SoundFar = {"iedins/ied_detonate_dist_01.wav", "ied/ied_detonate_dist_02.wav", "ied/ied_detonate_dist_03.wav"}
ENT.Sound = {"ied/ied_detonate_01.wav", "ied/ied_detonate_02.wav", "ied/ied_detonate_03.wav"}
ENT.SoundWater = "iedins/water/ied_water_detonate_01.wav"
ENT.BlastDis = 680 
ENT.BlastDamage = 100 
ENT.ShrapnelDis = 500 
ENT.ShrapnelDamage = 65 
ENT.ConcussionDis = 1365 
ENT.ConcussionDamage = 30 
ENT.DetectionAngle = 60
ENT.DetectionDistance = 700
ENT.DetectionRays = 5

if SERVER then
    function ENT:Initialize()
        self:SetModel(self.WorldModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(ONOFF_USE)
        self:DrawShadow(true)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:EnableMotion(false) 
        end
    end
    
    function ENT:PhysicsCollide(data, phys)
        if self.CanBeKnockedOver and data.Speed > 80 then
            phys:EnableMotion(true)
            phys:Wake()

            local force = data.Speed * 0.2
            phys:ApplyForceOffset(data.HitNormal * force * 10, data.HitPos)
        end
    end
end

local developer = GetConVar("developer")
local offsetPos, offsetAng = Vector(0, 2, 11.5), Angle(1, 90, 0)

function ENT:Think()
    local pos, ang = self:GetPos(), self:GetAngles()
    local pos, ang = LocalToWorld(offsetPos, offsetAng, pos, ang)
    
    local halfAngle = self.DetectionAngle / 2
    local angleStep = self.DetectionAngle / (self.DetectionRays - 1)
    local triggered = false
    
    for i = 0, self.DetectionRays - 1 do
        local rayAngle = Angle(ang.p, ang.y, ang.r)
        rayAngle:RotateAroundAxis(rayAngle:Up(), -halfAngle + i * angleStep)
        
        local tr = {}
        tr.start = pos
        tr.endpos = tr.start + rayAngle:Forward() * self.DetectionDistance
        tr.filter = self
        tr.mask = MASK_SHOT
        local trace = util.TraceLine(tr)

        if developer:GetBool() and CLIENT and LocalPlayer():IsAdmin() then
            local color = trace.Hit and Color(255, 0, 0) or Color(255, 255, 255)
            debugoverlay.Line(pos, trace.HitPos, 1, color, true)
        end

        if SERVER and trace.Hit and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or (trace.Entity:IsRagdoll() and trace.Entity:GetVelocity():LengthSqr() > 1)) then
            triggered = true
            break
        end
    end
    
    if SERVER and triggered then
        self:ActivateExplosive()
    end

    self:NextThink(CurTime())
    return true
end

if SERVER then
    local vec_huy = Vector(0,0,0)
    function ENT:ActivateExplosive()
        if self.Exploded then return end
        self.Exploded = true
        local selfPos = self:GetPos()
        local pos, ang = LocalToWorld(offsetPos, offsetAng, self:GetPos(), self:GetAngles())
        local num = 700

        local bullet = {}
        bullet.Force = 2
        bullet.Damage = 10
        bullet.AmmoType = "Metal Debris"
        bullet.Attacker = self.owner
        bullet.Distance = 56756
        bullet.Callback = hg.bulletHit
        bullet.IgnoreEntity = self
        bullet.Tracer = 10000
        bullet.DisableLagComp = true
        bullet.Filter = {self}

        local co = coroutine.create(function()
            local LastShrapnel = SysTime()

            for i = 1, num do
                LastShrapnel = SysTime()

                local dir = (ang + Angle(math.Rand(-12, 2), math.Rand(-30, 30), 0)):Forward()
                dir:Normalize()

                local tr = util.TraceLine({
                    start = pos,
                    endpos = pos + dir * bullet.Distance,
                    filter = bullet.Filter,
                    mask = MASK_SHOT
                })
                if i > 100 and tr.Entity == game.GetWorld() then util.Decal("ExplosiveGunshot",tr.HitPos+tr.HitNormal,tr.HitPos-tr.HitNormal) continue end

                bullet.Src = pos
                bullet.Dir = dir
                bullet.Penetration = math.Clamp(num / i, 5, 10) * 10
                if not IsValid(self) then return end
                self:FireLuaBullets(bullet,true)

                LastShrapnel = SysTime() - LastShrapnel

                if LastShrapnel > 0.001 then
                    coroutine.yield()
                end
            end

            self.ShrapnelDone = true
        end)

        coroutine.resume(co)

        local index = self:EntIndex()

        timer.Create("GrenadeCheck_" .. index, 0, 0, function()
            if !IsValid(self) then
                timer.Remove("GrenadeCheck_" .. index)
            end

            coroutine.resume(co)

            if self.ShrapnelDone then
                util.ScreenShake(selfPos, 20, 20, 1, self.ConcussionDis)
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
        local normal = self:GetAngles():Right()
        local blastdist = self.BlastDis
        timer.Simple(0.3,function()
            ParticleEffect("pcf_jack_groundsplode_medium",selfPos+vector_up*1,-normal:Angle())
            --hg.ExplosionEffect(selfPos, blastdist, 80)
        end)

        local attacker = IsValid(self.owner) and self.owner or Entity(0)
        
        for _, ply in ipairs(ents.FindInSphere(selfPos,self.ConcussionDis)) do
            if not ply:IsPlayer() then continue end
            local tr = hg.ExplosionTrace(selfPos,ply:GetPos(),{self})
			if tr.Entity != ply then continue end
            local dist = ply:GetPos():Distance(selfPos)
            local tinnitusDuration = math.Clamp(10 * (1 - dist/self.ConcussionDis), 2, 10)
            ply:AddTinnitus(math.max(tinnitusDuration,1.5), true)
        end
           
        --util.BlastDamage(self, attacker, selfPos, self.ShrapnelDis, self.BlastDamage)
        util.BlastDamage(self, attacker, selfPos, self.BlastDis, self.ShrapnelDamage)
        --util.BlastDamage(self, attacker, selfPos, self.ConcussionDis, self.ConcussionDamage)
    end

    function ENT:OnTakeDamage(dmginfo)
        if dmginfo:GetInflictor() == self then return end
        if dmginfo:IsDamageType(DMG_BLAST + DMG_BULLET + DMG_BUCKSHOT + DMG_BURN) then
            self:ActivateExplosive()
        end
    end
end
