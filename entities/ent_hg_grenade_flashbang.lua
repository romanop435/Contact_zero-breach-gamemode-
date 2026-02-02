if SERVER then AddCSLuaFile() end
ENT.Base = "ent_hg_grenade"
ENT.Spawnable = false
ENT.Model = "models/weapons/w_m84.mdl"
ENT.timeToBoom = 2.5


ENT.SoundMain = "weapons/m84/m84_detonate.wav"
ENT.SoundFar = "weapons/m84/m84_detonate_far_dist.wav"


ENT.SoundBass = {
    "snd_jack_fireworksplodeclose.wav",
    "snd_jack_fireworksplodefar.wav"
}

local burnDamageRadius = 20  
local explosionDamageRadius = 30  
local disorientationRadius = 300  

if SERVER then
    util.AddNetworkString("flashbang")
else
    local function IsLookingAt(ply, targetVec)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        local view = render.GetViewSetup(true)
        local diff = (view.origin - targetVec):GetNormalized()
        return view.angles:Forward():Dot(diff)
    end

    net.Receive("flashbang",function()
        local pos = net.ReadVector()
         

        local time = math.Clamp(5200-(lply:GetPos():Distance(pos)), 1, 5)

        lply:AddTinnitus(time,true)

        local IsLookingFlash = IsLookingAt(lply, pos)
        local viewsetup = render.GetViewSetup(true)
        
        if IsLookingFlash < -0.5 then
            hg.AddFlash(viewsetup.origin,IsLookingFlash,pos,time*5,50000)
        end
        hook.Add("RenderScreenspaceEffects", "Flashed", function()
            if lply.tinnitus - CurTime() < 0 then lply.tinnitus = nil
                hook.Remove("RenderScreenspaceEffects", "Flashed")
                return
            end
            local flash = math.Clamp(lply.tinnitus - CurTime(), 0, 1)
            --lply:SetDSP(32) -- 36
        end)
    end)
end

function ENT:InitAdd()
    self:SetModelScale(1)
    self:Activate()
end

function ENT:Explode()
    if self:PoopBomb() then
        self:EmitSound("weapons/p99/slideback.wav", 75)
        self.Exploded = true
        return
    end
    local SelfPos = self:GetPos()

    local effectdata = EffectData()
    effectdata:SetOrigin(SelfPos)
    effectdata:SetScale(0.5)
    effectdata:SetNormal(-self:GetAngles():Forward())
    util.Effect("eff_jack_genericboom", effectdata)
    hg.EmitAISound(SelfPos, 512, 16, 1)


    net.Start("projectileFarSound")
        net.WriteString(self.SoundMain)
        net.WriteString(self.SoundFar)
        net.WriteVector(SelfPos)
        net.WriteEntity(self)
        net.WriteBool(self:WaterLevel() > 0)
        net.WriteString("")
    net.Broadcast()
    
    self:EmitSound(self.SoundMain, 145, 85, 1, CHAN_WEAPON)
    self:EmitSound(self.SoundFar, 140, 85, 0.9, CHAN_WEAPON)
    
    timer.Simple(0.05, function()
        if IsValid(self) then
            self:EmitSound(table.Random(self.SoundBass), 150, 70, 0.95, CHAN_AUTO)
        end
    end)
    
    timer.Simple(0.1, function()
        if IsValid(self) then
            self:EmitSound(table.Random(self.SoundBass), 155, 60, 0.9, CHAN_BODY)
        end
    end)

    EmitSound(self.SoundMain, SelfPos, self:EntIndex() + 100, CHAN_STATIC, 1, 140, nil, math.random(75, 85))
    
    EmitSound("snd_jack_fireworkpop5.wav", SelfPos, self:EntIndex() + 200, CHAN_VOICE, 1, 150, nil, math.random(100, 110))

    for _, ply in ipairs(ents.FindInSphere(SelfPos, 700)) do
        if not ply:IsPlayer() or not ply:Alive() then continue end

        if hg.isVisible(ply:GetShootPos(), SelfPos, {ply, self}, MASK_VISIBLE) then
            net.Start("flashbang")
                net.WriteVector(SelfPos)
            net.Send(ply)
        end

        local tr = hg.ExplosionTrace(SelfPos,ply:GetPos(),{self})
        if tr.Entity != ply then continue end

        local distance = ply:GetPos():Distance(SelfPos)
        local org = ply.organism  

        if distance <= burnDamageRadius then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(50)
            dmginfo:SetDamageType(DMG_BURN)


            if IsValid(self.Owner) then
                dmginfo:SetAttacker(self.Owner)
            else
                dmginfo:SetAttacker(self)  
            end

            ply:TakeDamageInfo(dmginfo)
        end

        if distance <= explosionDamageRadius then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(75)
            dmginfo:SetDamageType(DMG_BLAST)

            if IsValid(self.Owner) then
                dmginfo:SetAttacker(self.Owner)
            else
                dmginfo:SetAttacker(self)  
            end

            ply:TakeDamageInfo(dmginfo)
        end

        if distance <= disorientationRadius then
            if org then
                org.disorientation = org.disorientation + 5  
                --timer.Create("RemoveDisorientation_"..ply:UserID(), 15, 1, function()
                --    if org then org.disorientation = 0 end  -- да сделал по говну -- а зачем тут таймер вы че шизофреники?
                --end)
            end
        end
    end

    self:Remove()
end