if SERVER then AddCSLuaFile() end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Motion Detector"
ENT.Spawnable = false
ENT.WorldModel = "models/weapons/w_slam.mdl"

ENT.Sound = "ambient/alarms/klaxon1.wav"
ENT.AlarmCD = 0

if SERVER then
	local clr = Color(115, 135, 255)
	function ENT:Initialize()
		self:SetModel(self.WorldModel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self:SetUseType(ONOFF_USE)
		self:DrawShadow(true)
		self:SetColor(clr)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
	end
end

local developer = GetConVar("developer")
local offsetPos, offsetAng = Vector(0, 0, 6), Angle(-90, 180, 0)
local mat = Material("sprites/rollermine_shock")
function ENT:Think()
	local tr = {}
	local pos, ang = self:GetPos(), self:GetAngles()
	local pos, ang = LocalToWorld(offsetPos, offsetAng, pos, ang)
	tr.start = pos
	tr.endpos = tr.start + ang:Forward() * 700
	tr.filter = self
	tr.collisiongroup = COLLISION_GROUP_PLAYER
	local tr = util.TraceLine(tr)

	if developer:GetBool() and LocalPlayer():IsAdmin() then
		debugoverlay.Line(pos, tr.HitPos, 1, color_white, true)
	end

	if SERVER and tr.Hit and (tr.Entity:IsPlayer() or tr.Entity:IsNPC() or (tr.Entity:IsRagdoll() and tr.Entity:GetVelocity():LengthSqr() > 1)) then
		if self.AlarmCD > CurTime() or (tr.Entity:IsPlayer() and tr.Entity.PlayerClassName == "sc_guard") then return end
		self:ActivateAlarm(tr)

		self.AlarmCD = CurTime() + 1
	end

	self:NextThink(CurTime())
	return true
end

if SERVER then
	function ENT:ActivateAlarm(tr)
		local selfPos = self:GetPos()

		local pitch = math.random(90, 110)
		self:EmitSound(self.Sound, 100, pitch)
		sound.Play(self.Sound, selfPos, 70, pitch)
		sound.Play(self.Sound, selfPos, 100, pitch) -- "npc/stalker/go_alert2a.wav"

		if tr and tr ~= nil then
			self:EmitSound("ambient/water/water_splash"..math.random(3)..".wav", 60)
			for i = 1, 5 do
				local Spark = EffectData()
				Spark:SetOrigin(self:GetPos())
				Spark:SetScale(i)
				Spark:SetNormal(self:GetUp())
				util.Effect("eff_jack_hmcd_fuzeburn",Spark,true,true)
				util.Decal("PaintSplatGreen", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
			end
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		if dmginfo:GetInflictor() == self then return end
		self:ActivateAlarm()

		for i = 1, 5 do
			local Spark = EffectData()
			Spark:SetOrigin(self:GetPos())
			Spark:SetScale(i)
			Spark:SetNormal(self:GetUp())
			util.Effect("eff_jack_hmcd_fuzeburn",Spark,true,true)
		end
		SafeRemoveEntity(self)
	end
end
