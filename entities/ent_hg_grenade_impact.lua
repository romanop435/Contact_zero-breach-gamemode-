if SERVER then AddCSLuaFile() end
ENT.Base = "ent_hg_grenade"
ENT.Spawnable = false
ENT.Model = "models/weapons/tfa_ins2/w_m67.mdl"
ENT.timeToBoom = 5
ENT.Fragmentation = 350 * 2 -- 450 уже страшно
ENT.BlastDis = 5 --meters
ENT.Penetration = 7

if SERVER then
    function ENT:PhysicsCollide(phys, deltaTime)
        if phys.Speed > 20 and not self.Exploded then self:Explode() end
    end
end