hg = hg or {}

hg.ConVars = hg.ConVars or {}
hg.bulletholes = hg.bulletholes or {}
hg.GunPositions = hg.GunPositions or {}
hg.weaponInv = hg.weaponInv or {}
hg.ragdollFake = hg.ragdollFake or {}
hg.radialOptions = hg.radialOptions or {}

hg.TPIKBones = hg.TPIKBones or {}
hg.TPIKBonesTranslate = hg.TPIKBonesTranslate or {}
hg.TPIKBonesLHDict = hg.TPIKBonesLHDict or {}
hg.TPIKBonesRHDict = hg.TPIKBonesRHDict or {}

hg.attachmentFunc = hg.attachmentFunc or function() end
hg.RenderTPIKBase = hg.RenderTPIKBase or function() end
hg.RenderMelees = hg.RenderMelees or function() end
hg.MainTPIKFunction = hg.MainTPIKFunction or function() end

hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}
hg.organism.input_list.rarmdown = hg.organism.input_list.rarmdown or function() end

local default_organism = {
	canmove = true,
	otrub = false,
	larm = 0,
	rarm = 0,
	spine1 = 0,
	spine2 = 0,
	spine3 = 0,
	holdingbreath = false,
	adrenaline = 0,
	immobilization = 0,
	recoilmul = 1,
	stun = 0,
	stamina = {180},
	pain = 0,
	temperature = 36.6,
	larmdislocation = false,
	analgesia = 0,
	fearadd = 0,
	adrenalineAdd = 0,
	superfighter = false,
}

function hg.EnsureOrganism(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	ply.organism = ply.organism or {}
	local org = ply.organism
	for key, value in pairs(default_organism) do
		if org[key] == nil then
			org[key] = istable(value) and table.Copy(value) or value
		end
	end
	if org.owner == nil then
		org.owner = ply
	end
	org.disabled = ply:GetNWBool("CZ_NoOrganism", false)
end

if SERVER then
	hook.Add("PlayerInitialSpawn", "hg_weapons_org_init", function(ply)
		hg.EnsureOrganism(ply)
	end)

	hook.Add("PlayerSpawn", "hg_weapons_org_spawn", function(ply)
		hg.EnsureOrganism(ply)
		if not ply:HasWeapon("weapon_hands_sh") then
			ply:Give("weapon_hands_sh")
		end
	end)
else
	hook.Add("InitPostEntity", "hg_weapons_org_local", function()
		local ply = LocalPlayer()
		if IsValid(ply) then
			hg.EnsureOrganism(ply)
		end
	end)

	hook.Add("OnEntityCreated", "hg_weapons_org_client", function(ent)
		if not IsValid(ent) or not ent:IsPlayer() then return end
		timer.Simple(0, function()
			if IsValid(ent) then
				hg.EnsureOrganism(ent)
			end
		end)
	end)
end

if CLIENT then
	hg.ConVars.potatopc = GetConVar("hg_potatopc") or CreateClientConVar(
		"hg_potatopc",
		"0",
		true,
		false,
		"Low FX mode",
		0,
		1
	)
end

if SERVER then
	util.AddNetworkString("hg_keydown_sync")

	local function send_key(ply, key, down)
		if not IsValid(ply) then return end
		net.Start("hg_keydown_sync")
		net.WriteEntity(ply)
		net.WriteInt(key, 16)
		net.WriteBool(down)
		net.Broadcast()
	end

	hook.Add("KeyPress", "hg_keydown_sync", function(ply, key)
		send_key(ply, key, true)
	end)

	hook.Add("KeyRelease", "hg_keydown_sync", function(ply, key)
		send_key(ply, key, false)
	end)
else
	net.Receive("hg_keydown_sync", function()
		local ply = net.ReadEntity()
		local key = net.ReadInt(16)
		local down = net.ReadBool()
		if not IsValid(ply) then return end
		ply.keydown = ply.keydown or {}
		if down then
			ply.keydown[key] = true
		else
			ply.keydown[key] = nil
		end
	end)
end

function hg.KeyDown(owner, key)
	if not IsValid(owner) then return false end
	if CLIENT then
		if owner == LocalPlayer() then
			return owner:KeyDown(key)
		end
		owner.keydown = owner.keydown or {}
		return owner.keydown[key] or false
	end
	return owner:KeyDown(key)
end

function hg.GetCurrentCharacter(ply)
	if not IsValid(ply) then return ply end
	if IsValid(ply.FakeRagdoll) then
		return ply.FakeRagdoll
	end
	return ply
end

function hg.RagdollOwner(ent)
	if not IsValid(ent) then return nil end
	if ent.owner and IsValid(ent.owner) then
		return ent.owner
	end
	local owner = ent:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		return owner
	end
	return nil
end

function hg.Fake(ply)
end

function hg.realPhysNum(_, phys_number)
	return phys_number
end

hg.PhysBullet = hg.PhysBullet or {}
hg.PhysBullet.MaxKeyBits = hg.PhysBullet.MaxKeyBits or 13
hg.PhysSilk = hg.PhysSilk or nil

hg.PhysBullet.CreateBullet = hg.PhysBullet.CreateBullet or function(bullet)
	if not bullet then return end
	local attacker = bullet.Attacker
	if not IsValid(attacker) then
		attacker = game.GetWorld()
	end
	local dir = bullet.Dir or (attacker.GetAimVector and attacker:GetAimVector()) or Vector(1, 0, 0)
	local src = bullet.Pos or (attacker.GetShootPos and attacker:GetShootPos()) or Vector(0, 0, 0)
	local spread = bullet.Spread or Vector(0, 0, 0)
	local data = {
		Num = bullet.Num or 1,
		Src = src,
		Dir = dir,
		Spread = spread,
		Force = bullet.Force or 0,
		Damage = bullet.Damage or 0,
		Tracer = bullet.Tracer or 0,
		TracerName = bullet.TracerName or "Tracer",
		Callback = bullet.Callback,
	}
	if IsValid(bullet.IgnoreEntity) then
		data.Filter = bullet.IgnoreEntity
	end
	if attacker.FireBullets then
		attacker:FireBullets(data)
	end
end

function hg.isVisible(pos1, pos2, filter, mask)
	return not util.TraceLine({
		start = pos1,
		endpos = pos2,
		filter = filter,
		mask = mask
	}).Hit
end

local function lerpFrameTime2(lerp, frameTime)
	frameTime = frameTime or FrameTime()
	local tick = engine.TickInterval()
	if tick <= 0 then return lerp end
	return math.Clamp(lerp * frameTime / tick, 0, 1)
end

hg.lerpFrameTime2 = lerpFrameTime2

function hg.bone_apply_matrix(ent, bone, new_matrix)
	if not IsValid(ent) then return end
	local bone_id = isstring(bone) and ent:LookupBone(bone) or bone
	if not bone_id or bone_id == -1 then return end
	ent:SetBoneMatrix(bone_id, new_matrix)
end

function hg.IsOnGround(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then
		return ent:IsOnGround()
	end
	return IsValid(ent:GetGroundEntity())
end

function hg.CalculateWeight()
	return 1
end

function hg.CanSuicide()
	return true
end

function hg.CanUseLeftHand()
	return true
end

function hg.CanUseRightHand()
	return true
end

function hg.set_hold()
end

function hg.set_holdrh()
end

function hg.eye(ply, dist, ent, aim_vector, startpos)
	if not IsValid(ply) then return end
	local aim = aim_vector or (ply.GetAimVector and ply:GetAimVector()) or Vector(1, 0, 0)
	local start = startpos or (ply.EyePos and ply:EyePos()) or Vector(0, 0, 0)
	return start, aim * (dist or 60), {ply, ent}
end

function hg.eyeTrace(ply, dist, ent, aim_vector, startpos)
	local start, aim, filter = hg.eye(ply, dist, ent, aim_vector, startpos)
	if not start then return end
	return util.TraceLine({
		start = start,
		endpos = start + aim,
		filter = filter,
		mask = MASK_SHOT
	})
end

function hg.torsoTrace(ply, dist, ent, aim_vector)
	return hg.eyeTrace(ply, dist, ent, aim_vector)
end

if CLIENT then
	local tpik_distance = GetConVar("hg_tpik_distance") or CreateClientConVar(
		"hg_tpik_distance",
		"1024",
		true,
		false,
		"TPIK render distance, 0 = infinite",
		0,
		2048
	)

	function hg.ShouldTPIK(ply)
		if not IsValid(ply) then return false end
		local dist = tpik_distance:GetInt()
		if dist <= 0 then return true end
		local lp = LocalPlayer()
		if not IsValid(lp) then return true end
		return ply:GetPos():DistToSqr(lp:GetPos()) <= dist * dist
	end
else
	function hg.ShouldTPIK()
		return true
	end
end

function hg.AddForceRag()
end

function hg.AddFlash()
end

local function stun_player(ply, time)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
	time = time or 1
	ply:Freeze(true)
	timer.Simple(time, function()
		if IsValid(ply) then
			ply:Freeze(false)
		end
	end)
end

function hg.StunPlayer(ply, time)
	stun_player(ply, time)
end

function hg.LightStunPlayer(ply, time)
	stun_player(ply, time)
end

function hg.ExplosionTrace(start, endpos, filter)
	return util.TraceLine({
		start = start,
		endpos = endpos,
		filter = filter,
		mask = MASK_SHOT
	})
end

function hg.ExplosionEffect(pos, dis, dmg, attacker, inflictor)
	if not SERVER then return end
	local atk = IsValid(attacker) and attacker or game.GetWorld()
	local inf = IsValid(inflictor) and inflictor or atk
	util.BlastDamage(inf, atk, pos, dis, dmg)
	local ed = EffectData()
	ed:SetOrigin(pos)
	util.Effect("Explosion", ed, true, true)
end

function hg.ExplosionDisorientation(enta, _, disorientation)
	if not IsValid(enta) or not enta:IsPlayer() then return end
	local punch = math.Clamp(disorientation or 0, 0, 10)
	enta:ViewPunch(Angle(-punch, 0, 0))
end

function hg.PrecacheSoundsSWEP(self)
	if not IsValid(self) then return end
	local function precache(value)
		if isstring(value) then
			util.PrecacheSound(value)
		elseif istable(value) then
			for _, entry in ipairs(value) do
				if isstring(entry) then
					util.PrecacheSound(entry)
				end
			end
		end
	end

	precache(self.Primary and self.Primary.Sound)
	precache(self.SupressedSound)
	precache(self.DeploySnd)
	precache(self.HolsterSnd)
	precache(self.ReloadSound)
	precache(self.ReloadSoundes)
end
