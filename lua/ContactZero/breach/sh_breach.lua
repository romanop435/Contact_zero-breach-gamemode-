if SERVER then AddCSLuaFile() end

hg = hg or {}
hg.Breach = hg.Breach or {}
local BR = hg.Breach

BR.RoundStates = BR.RoundStates or {
	WAITING = 0,
	PREP = 1,
	ACTIVE = 2,
	POST = 3
}

TEAM_CLASSD = TEAM_CLASSD or 1
TEAM_SCI = TEAM_SCI or 2
TEAM_GUARD = TEAM_GUARD or 3
TEAM_SCP = TEAM_SCP or 4
TEAM_SPECTATOR = TEAM_SPECTATOR or 5

team_classd = TEAM_CLASSD
team_sci = TEAM_SCI
team_guard = TEAM_GUARD
team_scp = TEAM_SCP
team_spectator = TEAM_SPECTATOR

BR.TeamIds = BR.TeamIds or {
	classd = TEAM_CLASSD,
	sci = TEAM_SCI,
	guard = TEAM_GUARD,
	scp = TEAM_SCP,
	spectator = TEAM_SPECTATOR
}

if not BR.TeamsSetup then
	team.SetUp(TEAM_CLASSD, "Class D", Color(200, 130, 60), true)
	team.SetUp(TEAM_SCI, "Scientists", Color(90, 160, 210), true)
	team.SetUp(TEAM_GUARD, "Guards", Color(120, 140, 200), true)
	team.SetUp(TEAM_SCP, "SCP", Color(200, 60, 60), true)
	team.SetUp(TEAM_SPECTATOR, "Spectator", Color(160, 160, 160), true)
	BR.TeamsSetup = true
end

BR.Factions = BR.Factions or {
	classd = {
		id = "classd",
		name = "Class D",
		team = TEAM_CLASSD,
		color = Color(200, 130, 60),
		icon = "icon16/user_orange.png"
	},
	sci = {
		id = "sci",
		name = "Science",
		team = TEAM_SCI,
		color = Color(90, 160, 210),
		icon = "icon16/vcard.png"
	},
	guard = {
		id = "guard",
		name = "Guard",
		team = TEAM_GUARD,
		color = Color(120, 140, 200),
		icon = "icon16/shield.png"
	},
	scp = {
		id = "scp",
		name = "SCP",
		team = TEAM_SCP,
		color = Color(200, 60, 60),
		icon = "icon16/exclamation.png"
	},
	spectator = {
		id = "spectator",
		name = "Spectator",
		team = TEAM_SPECTATOR,
		color = Color(160, 160, 160),
		icon = "icon16/eye.png"
	}
}

BR.Roles = BR.Roles or {
	classd_default = {
		id = "classd_default",
		name = "Class D",
		faction = "classd",
		model = "models/player/Group01/male_02.mdl",
		health = 100,
		walkSpeed = 130,
		runSpeed = 280,
		weight = 8,
		canPickup = true,
		canUseCamera = true
	},
	classd_kripper = {
		id = "classd_kripper",
		name = "Class D - Проныра",
		faction = "classd",
		model = "models/player/Group01/male_05.mdl",
		health = 95,
		walkSpeed = 130,
		runSpeed = 285,
		keycard = 1,
		weight = 2,
		canPickup = true,
		canUseCamera = true
	},
	sci_default = {
		id = "sci_default",
		name = "Scientist",
		faction = "sci",
		model = "models/player/Group03/male_07.mdl",
		health = 100,
		walkSpeed = 130,
		runSpeed = 280,
		keycard = 2,
		weight = 10,
		canPickup = true,
		canUseCamera = true
	},
	guard_default = {
		id = "guard_default",
		name = "Guard",
		faction = "guard",
		model = "models/player/police.mdl",
		health = 120,
		walkSpeed = 130,
		runSpeed = 300,
		keycard = 3,
		weight = 10,
		canPickup = true,
		canUseCamera = true
	},
	scp_default = {
		id = "scp_default",
		name = "SCP",
		faction = "scp",
		model = "models/player/charple.mdl",
		health = 300,
		walkSpeed = 130,
		runSpeed = 320,
		keycard = 0,
		weight = 10,
		canPickup = false,
		canUseCamera = false
	},
	spectator = {
		id = "spectator",
		name = "Spectator",
		faction = "spectator",
		health = 100,
		walkSpeed = 130,
		runSpeed = 280,
		keycard = 0,
		weight = 0,
		canPickup = false,
		canUseCamera = true
	}
}

BR.RandomNames = BR.RandomNames or {
	first = {
		"Alex", "Dylan", "Ethan", "Jacob", "Leo", "Liam", "Logan", "Mason", "Noah", "Owen",
		"Ryan", "Tyler", "Victor", "Zane", "Henry", "Lucas", "Nolan", "Caleb", "Miles", "Oscar"
	},
	last = {
		"Adams", "Baker", "Carter", "Collins", "Evans", "Foster", "Garcia", "Hayes", "Hughes",
		"Irwin", "Jackson", "King", "Morris", "Parker", "Reed", "Sullivan", "Turner", "Ward",
		"Wood", "Young"
	}
}
hook.Add("InitPostEntity", "CZ_SetSiteName", function()
    SetGlobalString("CZ_SiteName", "SITE-19")
end)

function BR.GenerateDisplayName()
	local first = BR.RandomNames.first[math.random(#BR.RandomNames.first)] or "Alex"
	local last = BR.RandomNames.last[math.random(#BR.RandomNames.last)] or "Adams"
	return first .. " " .. last
end

function BR.AssignDisplayName(ply, force)
	if not IsValid(ply) then return end
	if not force and ply:GetNWString("CZ_DisplayName", "") ~= "" then return end
	if SERVER then
		ply:SetNWString("CZ_DisplayName", BR.GenerateDisplayName())
	end
end

function BR.NormalizeRoleId(roleId)
	if not roleId then return "spectator" end
	roleId = string.lower(roleId)
	if roleId == "classd" or roleId == "d" then return "classd_default" end
	if roleId == "scientist" or roleId == "sci" then return "sci_default" end
	if roleId == "security" or roleId == "guard" then return "guard_default" end
	if roleId == "scp" then return "scp_default" end
	return roleId
end

function BR.GetRole(roleId)
	roleId = BR.NormalizeRoleId(roleId)
	return BR.Roles[roleId]
end

function BR.GetClass(roleId)
	return BR.GetRole(roleId)
end

function BR.GetPlayerClassId(ply)
	if not IsValid(ply) then return "spectator" end
	local id = ply:GetNWString("CZ_Role", "")
	if id == "" then
		id = ply:GetNWString("CZ_Class", "spectator")
	end
	return BR.NormalizeRoleId(id)
end

function BR.GetPlayerClass(ply)
	return BR.GetRole(BR.GetPlayerClassId(ply))
end

function BR.IsSCP(ply)
	if not IsValid(ply) then return false end
	if ply:GetNWBool("CZ_IsSCP", false) then return true end
	local role = BR.GetPlayerClass(ply)
	return role and role.faction == "scp" or false
end

function BR.IsSpectator(ply)
	if not IsValid(ply) then return false end
	if ply:Team() == TEAM_SPECTATOR then return true end
	return BR.GetPlayerClassId(ply) == "spectator"
end

function BR.GetKeycardLevel(ply)
	if not IsValid(ply) then return 0 end
	return ply:GetNWInt("CZ_Keycard", 0)
end

function BR.SetKeycardLevel(ply, level)
	if not IsValid(ply) then return 0 end
	level = math.max(0, math.floor(tonumber(level) or 0))
	if SERVER then
		ply:SetNWInt("CZ_Keycard", level)
	end
	return level
end

BR.KeycardSkins = BR.KeycardSkins or {
	[1] = 0,
	[2] = 8,
	[3] = 12,
	[4] = 3,
	[5] = 4,
	[6] = 16,
	[7] = 18,
	default = 0
}

function BR.GetKeycardSkin(level)
	local map = rawget(_G, "CZ_KEYCARD_SKINS") or BR.KeycardSkins
	local idx = map[tonumber(level) or 1]
	if idx == nil then
		idx = map.default
	end
	idx = tonumber(idx) or 0
	local max = 0
	for _, v in pairs(map) do
		local num = tonumber(v)
		if num and num > max then
			max = num
		end
	end
	return math.Clamp(idx, 0, max)
end

function BR.SetPlayerClass(ply, roleId)
	if not IsValid(ply) then return end
	local role = BR.GetRole(roleId)
	if not role then return end
	local faction = BR.Factions[role.faction or ""] or nil
	if SERVER then
		ply:SetNWString("CZ_Role", role.id)
		ply:SetNWString("CZ_Class", role.id)
		ply:SetNWString("CZ_Faction", role.faction or "")
		ply:SetNWBool("CZ_IsSCP", role.faction == "scp")
		ply:SetNWBool("CZ_NoOrganism", role.faction == "scp" or role.faction == "spectator")
		ply:SetTeam(faction and faction.team or TEAM_UNASSIGNED)
	end
	return role
end

function BR.GetRequiredKeycard(ent)
	if not IsValid(ent) then return 0 end
	if ent.CZKeycardLevel then return ent.CZKeycardLevel end
	if ent.GetNWInt and ent:GetNWInt("CZ_KeycardLevel", 0) > 0 then
		return ent:GetNWInt("CZ_KeycardLevel", 0)
	end
	if ent.GetKeyValues then
		local kv = ent:GetKeyValues() or {}
		local raw = kv.cz_keycard_level or kv.keycard_level or kv.cz_keycard or kv.keycard
		local level = tonumber(raw)
		if level then return level end
	end
	return 0
end

function BR.SetRequiredKeycard(ent, level)
	if not IsValid(ent) then return end
	level = math.max(0, math.floor(tonumber(level) or 0))
	ent.CZKeycardLevel = level
	if ent.SetNWInt then
		ent:SetNWInt("CZ_KeycardLevel", level)
	end
end

function BR.GetRoleDisplayName(roleId)
	local role = BR.GetRole(roleId)
	return role and role.name or "Unknown"
end

function BR.GetFactionDisplayName(factionId)
	local faction = BR.Factions[factionId or ""]
	return faction and faction.name or "Unknown"
end

function BR.GetDisplayName(ply)
	if not IsValid(ply) then return "Unknown" end
	if BR.IsSpectator(ply) then
		return ply:Nick()
	end
	local name = ply:GetNWString("CZ_DisplayName", "")
	if name == "" then
		return ply:Nick()
	end
	return name
end

function BR.GetRolesByFaction(factionId)
	local list = {}
	for _, role in pairs(BR.Roles) do
		if role.faction == factionId then
			list[#list + 1] = role
		end
	end
	return list
end

function BR.PickRoleForFaction(factionId)
	local roles = BR.GetRolesByFaction(factionId)
	if #roles == 0 then return nil end

	local totalWeight = 0
	for _, role in ipairs(roles) do
		totalWeight = totalWeight + (role.weight or 1)
	end

	local roll = math.Rand(0, totalWeight)
	local accum = 0
	for _, role in ipairs(roles) do
		accum = accum + (role.weight or 1)
		if roll <= accum then
			return role
		end
	end

	return roles[1]
end

if CLIENT then
	BR._FactionMats = BR._FactionMats or {}

	function BR.GetFactionIcon(factionId)
		local faction = BR.Factions[factionId or ""] or BR.Factions.spectator
		local path = faction.icon or "icon16/eye.png"
		BR._FactionMats[path] = BR._FactionMats[path] or Material(path, "smooth")
		return BR._FactionMats[path]
	end

	function BR.GetHudAnchor()
		local pad = ScreenScale(12)
		return pad, ScrH() - ScreenScale(70)
	end
end

local BOOM_NET = "Fake_Boom_Effectus"

local function normalizeVector(pos)
	if isvector(pos) then return pos end
	if istable(pos) then
		return Vector(tonumber(pos[1]) or 0, tonumber(pos[2]) or 0, tonumber(pos[3]) or 0)
	end
	return nil
end

local function getWarheadOrigin()
	local override = rawget(_G, "CZ_WARHEAD_ORIGIN") or rawget(_G, "CZ_WARHEAD_POS")
	local pos = normalizeVector(override)
	if pos then return pos end

	local players = player.GetAll()
	if players and #players > 0 then
		local sum = Vector(0, 0, 0)
		local count = 0
		for _, ply in ipairs(players) do
			if IsValid(ply) then
				sum = sum + ply:GetPos()
				count = count + 1
			end
		end
		if count > 0 then
			return sum / count
		end
	end

	local world = game.GetWorld()
	if IsValid(world) then
		local mins, maxs = world:GetModelBounds()
		return (mins + maxs) * 0.5
	end

	return vector_origin
end

local function getWarheadPositions()
	local dustOverride = normalizeVector(rawget(_G, "CZ_WARHEAD_DUST_POS"))
	local particleOverride = normalizeVector(rawget(_G, "CZ_WARHEAD_PARTICLE_POS"))
	if dustOverride and particleOverride then
		return dustOverride, particleOverride
	end

	local origin = getWarheadOrigin()
	local trace = util.TraceLine({
		start = origin + Vector(0, 0, 16384),
		endpos = origin - Vector(0, 0, 16384),
		mask = MASK_SOLID_BRUSHONLY
	})
	local ground = trace.HitPos or origin
	local dust = dustOverride or ground
	local particle = particleOverride or (ground + Vector(0, 0, 256))

	return dust, particle
end

if SERVER then
	util.AddNetworkString(BOOM_NET)

	function BR.TriggerRoundEndBoom()
		local dustVector, particleOrigin = getWarheadPositions()
		net.Start(BOOM_NET)
		net.WriteVector(dustVector)
		net.WriteVector(particleOrigin)
		net.Broadcast()
	end

	function FakeAlphaWarheadBoomEffect()
		BR.TriggerRoundEndBoom()
	end
end

if CLIENT then
	local viewPunchAngle = Angle(-12, 0, 0)

	net.Receive(BOOM_NET, function()
		local dustVector = net.ReadVector()
		local particleOrigin = net.ReadVector()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		if dustVector == vector_origin then
			dustVector = ply:GetPos()
		end
		if particleOrigin == vector_origin then
			particleOrigin = dustVector + Vector(0, 0, 256)
		end

		surface.PlaySound("nuke.mp3")
		util.ScreenShake(vector_origin, 200, 10, 20, 32768)
		ParticleEffect("vman_nuke", dustVector, angle_zero)
		ParticleEffect("vman_nuke", particleOrigin, angle_zero)

		timer.Simple(7, function()
			if not IsValid(ply) then return end
			if ply:Health() > 0 and not BR.IsSpectator(ply) then
				ply:ViewPunch(viewPunchAngle)
			end
		end)

		timer.Simple(5, function()
			ParticleEffect("dustwave_tracer", dustVector, angle_zero)
		end)

		timer.Simple(5, function()
			util.ScreenShake(vector_origin, 200, 100, 10, 32768)
			timer.Simple(4, function()
				RunConsoleCommand("stopsound")
			end)
		end)
	end)
end
