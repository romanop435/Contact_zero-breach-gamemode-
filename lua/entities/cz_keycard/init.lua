AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local BR = hg and hg.Breach

local function GetSkinForLevel(level)
	if BR and BR.GetKeycardSkin then
		return BR.GetKeycardSkin(level)
	end
	local idx = math.max(0, (tonumber(level) or 1) - 1)
	return math.Clamp(idx, 0, 6)
end

function ENT:Initialize()
	self:SetModel("models/kutarum/scpfp/w_keycard.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetSkin(GetSkinForLevel(self:GetKeycardLevel()))

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
end

function ENT:Think()
	local level = self:GetKeycardLevel()
	if self._cz_last_level ~= level then
		self._cz_last_level = level
		self:SetSkin(GetSkinForLevel(level))
	end
	self:NextThink(CurTime() + 0.2)
	return true
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "cz_keycard_level" or key == "keycard_level" or key == "level" then
		self:SetKeycardLevel(tonumber(value) or 1)
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if BR and BR.IsSCP(activator) then return end

	local level = self:GetKeycardLevel()
	local wep = activator:GetWeapon("weapon_cz_keycard")
	if not IsValid(wep) then
		wep = activator:Give("weapon_cz_keycard")
	end

	if IsValid(wep) and wep.SetKeycardLevel then
		local current = wep:GetKeycardLevel()
		local nextLevel = math.max(current, level)
		wep:SetKeycardLevel(nextLevel)
		if BR then
			BR.SetKeycardLevel(activator, nextLevel)
		else
			activator:SetNWInt("CZ_Keycard", nextLevel)
		end
		if wep.InitCardData then
			wep:InitCardData(activator)
		end
	end

	activator:EmitSound("buttons/button14.wav", 60, 100)
	self:Remove()
end
