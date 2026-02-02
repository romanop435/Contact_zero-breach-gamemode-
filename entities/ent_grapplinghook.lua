AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Grappling Hook"
ENT.Author = "metal factory"
ENT.Category = ""
ENT.Spawnable = true
ENT.Model = "models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl"
if SERVER then ENT.Model = "models/props_junk/cardboard_box004a.mdl" end
ENT.AdminSpawnable = false
AddCSLuaFile()
if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMaterial("models/shiny")
		self:SetColor(Color(10, 10, 10, 255))
		self:PhysicsInit(SOLID_VPHYSICS)
		self:PhysicsInitBox(Vector(-4, -4, -4), Vector(4, 4, 4))
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:DrawShadow(true)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:UseTriggerBounds(true, 24)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:SetMass(20)
			phys:SetMaterial("concrete")
			phys:SetDragCoefficient(0)
		end

		self.Stillness = 0
		self.Locked = false
		self.Stopped = false
		self:SetUseType(SIMPLE_USE)
		self:SetNWBool("Impacted", false)
		self:SetModelScale(1, 0)
	end

	function ENT:Think()
		if not self.Locked then
			local vel, ent = self:GetRelativeVelocity()
			if vel < 1 and not self.Locked then
				self.Stillness = self.Stillness + 1
				if self.Stillness > 10 then
					self.Locked = true
					self:LockToSurface(ent)
				end
			else
				self.Stillness = 0
			end
		end
	end

	function ENT:LockToSurface(ent)
		constraint.Weld(self, ent, 0, 0, 0, true, false)
		sound.Play("snds_jack_hmcd_grapple/lock.wav", self:GetPos(), 75, 100)
	end

	function ENT:GetRelativeVelocity()
		local SelfPos = self:GetPos()
		local TrDat = {
			start = SelfPos,
			endpos = SelfPos - vector_up * (self:BoundingRadius() + 1),
			filter = {self}
		}

		local Tr = util.TraceLine(TrDat)
		if Tr.Hit and not Tr.HitSky then if IsValid(Tr.Entity:GetPhysicsObject()) then return (self:GetPhysicsObject():GetVelocity() - Tr.Entity:GetPhysicsObject():GetVelocity()):Length(), Tr.Entity end end
		return 100, nil
	end

	function ENT:Use(activator)
		if not IsValid(self.Rope) and activator:IsPlayer() then
			self.Stillness = 0
			self.Locked = false
			constraint.RemoveAll(self)
			if not activator:HasWeapon("weapon_grapplinghook") then
				activator:Give("weapon_grapplinghook")
				activator:SelectWeapon("weapon_grapplinghook")
				self:Remove()
			end
		end
	end
end

function ENT:PhysicsCollide(data, physobj)
	if data.Speed > 20 and data.DeltaTime > .15 then
		if not self:GetNWBool("Impacted", false) then self:SetNWBool("Impacted", true) end
		if data.Speed > 300 then
			sound.Play("snds_jack_hmcd_grapple/hard.wav", self:GetPos(), 70, math.random(90, 110))
		else
			sound.Play("snds_jack_hmcd_grapple/soft.wav", self:GetPos(), 65, math.random(90, 110))
		end
	end
end

function ENT:Draw()
	if not self.RModel then
		self.RModel = ClientsideModel("models/weapons/c_models/c_grappling_hook/c_grappling_hook.mdl")
		self.RModel:SetNoDraw(true)
		self.RModel:SetMaterial("models/shiny")
		self.RModel:SetColor(Color(10, 10, 10, 255))
		self.RModel:SetParent(self)
		self:CallOnRemove("Remove_CLMDL", function() self.RModel:Remove() end)
	end

	--print(self.RModel)
	local Vel, Ang = self:GetVelocity(), self:GetAngles()
	if Vel:Length() > 100 then
		Ang = Vel:Angle()
		if self:GetNWBool("Impacted") then
			Ang:RotateAroundAxis(Ang:Right(), 90)
		else
			Ang:RotateAroundAxis(Ang:Right(), -90)
		end
	end

	self.RModel:SetRenderAngles(Ang)
	self.RModel:SetRenderOrigin(self:GetPos())
	self.RModel:DrawModel()
end