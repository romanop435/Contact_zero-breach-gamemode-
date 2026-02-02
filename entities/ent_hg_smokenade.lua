if SERVER then AddCSLuaFile() end
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ent_hg_smokenade"
ENT.Spawnable = false
ENT.Model = "models/props_junk/jlare.mdl"
ENT.timeToBoom = 1
ENT.Fragmentation = 300 * 3 --300 не страшно
ENT.BlastDis = 5 --meters
ENT.Penetration = 8

ENT.spoon = "models/codww2/equipment/mk,ii hand grenade spoon.mdl"

ENT.Sound = {"m67/m67_detonate_01.wav", "m67/m67_detonate_02.wav", "m67/m67_detonate_03.wav"}
ENT.SoundFar = {"m67/m67_detonate_far_dist_01.wav", "m67/m67_detonate_far_dist_02.wav", "m67/m67_detonate_far_dist_03.wav"}
ENT.SoundWater = "m67/water/m67_water_detonate_01.wav"
ENT.Exploded = false
if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:SetUseType(USE_TOGGLE)
		self:DrawShadow(true)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetMass(5)
			phys:Wake()
			phys:EnableMotion(true)
		end
	end

	function ENT:Use(ply)
		if self:IsPlayerHolding() then return end

		ply:PickupObject(self)
	end

	function ENT:Think()
		if CLIENT then return end
		self:NextThink(CurTime())
		if not self.Exploded then self:Explode() end
		return true
	end

	local vecCone = Vector(20, 20, 0)
	function ENT:Explode()
		local ent = self
		self.Exploded = true
		local snd = self:StartLoopingSound("Weapon_FlareGun.Burn")
		timer.Create("smokenade"..ent:EntIndex(),1,25,function()
			if IsValid(ent) then
				local pos = ent:GetPos()
				self.Burn = (self.Burn or 0) + 1 
				if self.Burn == 24 then self:StopLoopingSound(snd) end
				ParticleEffect("pcf_jack_smokebomb3",pos,-vector_up:Angle())
			end
		end)
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end
end