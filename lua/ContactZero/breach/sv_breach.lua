hg = hg or {}
if not hg.Breach then
	include("ContactZero/breach/sh_breach.lua")
end
local BR = hg.Breach
if not BR then return end

util.AddNetworkString("CZ_SpectateCycle")
util.AddNetworkString("CZ_KeycardAnim")
util.AddNetworkString("CZ_SetScpOptOut")

local MIN_PLAYERS = 2
local MIN_SCP_PLAYERS = 10
local PREP_TIME = 30
local ROUND_TIME = 15 * 60
local POST_TIME = 12

local roundState = BR.RoundStates.WAITING
local roundStateEnd = 0

local getRoleOverride

local function SetRoundState(state, duration, winnerFaction)
	roundState = state
	roundStateEnd = duration and duration > 0 and (CurTime() + duration) or 0
	SetGlobalInt("CZ_RoundState", state)
	SetGlobalFloat("CZ_RoundStateEnd", roundStateEnd)
	SetGlobalString("CZ_RoundWinner", winnerFaction or "")
end

SetRoundState(BR.RoundStates.WAITING, 0)

local function GetPlayCandidates()
	local list = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			if not ply:GetNWBool("CZ_WantsSpectator", false) then
				table.insert(list, ply)
			end
		end
	end
	return list
end

local function Shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

local function AssignClasses()
	local pool = Shuffle(GetPlayCandidates())
	local count = #pool

	for _, ply in ipairs(player.GetAll()) do
		ply.CZ_AssignedRole = "spectator"
	end

	if count < MIN_PLAYERS then return end

	local scpCount = 0
	if count >= MIN_SCP_PLAYERS then
		if count >= 50 then
			scpCount = 3
		elseif count >= 30 then
			scpCount = 2
		else
			scpCount = 1
		end
	end
	local remaining = math.max(count - scpCount, 0)
	local sciCount = remaining >= 4 and math.max(1, math.floor(remaining * 0.25)) or 0
	local guardCount = remaining >= 6 and math.max(1, math.floor(remaining * 0.2)) or 0
	local classdCount = math.max(remaining - sciCount - guardCount, 0)

	if sciCount < guardCount then
		local shift = guardCount - sciCount
		guardCount = guardCount - shift
		classdCount = classdCount + shift
	end

	if classdCount <= sciCount and sciCount > 0 then
		local shift = math.min(sciCount - classdCount + 1, sciCount)
		sciCount = sciCount - shift
		classdCount = classdCount + shift
	end

	local function takePlayer(predicate)
		for i, ply in ipairs(pool) do
			if IsValid(ply) and (not predicate or predicate(ply)) then
				table.remove(pool, i)
				return ply
			end
		end
		return nil
	end

	local function assignFaction(ply, faction)
		local role = BR.PickRoleForFaction(faction)
		ply.CZ_AssignedRole = role and role.id or (faction .. "_default")
	end

	for i = 1, scpCount do
		local ply = takePlayer(function(p)
			return not p:GetNWBool("CZ_NoScp", false)
		end)
		if not IsValid(ply) then break end
		assignFaction(ply, "scp")
	end

	for i = 1, classdCount do
		local ply = takePlayer()
		if not IsValid(ply) then break end
		assignFaction(ply, "classd")
	end

	for i = 1, sciCount do
		local ply = takePlayer()
		if not IsValid(ply) then break end
		assignFaction(ply, "sci")
	end

	for i = 1, guardCount do
		local ply = takePlayer()
		if not IsValid(ply) then break end
		assignFaction(ply, "guard")
	end

	for _, ply in ipairs(pool) do
		if IsValid(ply) then
			assignFaction(ply, "classd")
		end
	end
end

local function GetSpectateTargets(ply)
	local targets = {}
	for _, v in ipairs(player.GetAll()) do
		if IsValid(v) and v ~= ply and v:Alive() and not BR.IsSpectator(v) then
			targets[#targets + 1] = v
		end
	end
	return targets
end

local function SetPlayerSpectator(ply, roaming)
	if not IsValid(ply) then return end
	ply.CZ_AssignedRole = "spectator"
	BR.SetPlayerClass(ply, "spectator")
	if ply.organism then
		ply.organism.disabled = ply:GetNWBool("CZ_NoOrganism", false)
	end
	ply:StripWeapons()
	ply:Spectate(roaming and OBS_MODE_ROAMING or OBS_MODE_CHASE)
	ply:SetNoDraw(true)
	ply:SetNotSolid(true)
	ply:GodEnable()
	ply:SetNWEntity("spect", NULL)

	if not roaming then
		local targets = GetSpectateTargets(ply)
		if #targets > 0 then
			local target = targets[1]
			ply:SpectateEntity(target)
			ply:SetNWEntity("spect", target)
		else
			ply:UnSpectate()
			ply:Spectate(OBS_MODE_ROAMING)
			roaming = true
		end
	end

	ply:SetNWInt("viewmode", roaming and 0 or 1)
end

local function ApplyRole(ply, roleId)
	local role = BR.GetRole(roleId)
	if not role then return end
	local override = getRoleOverride(role.id)

	if role.id == "spectator" then
		SetPlayerSpectator(ply, true)
		return
	end

	BR.SetPlayerClass(ply, role.id)
	if ply.organism then
		ply.organism.disabled = ply:GetNWBool("CZ_NoOrganism", false)
	end
	ply:UnSpectate()
	ply:SetNoDraw(false)
	ply:SetNotSolid(false)
	ply:GodDisable()

	local model = override and override.model or role.model
	if model then
		ply:SetModel(model)
	end

	local health = override and override.health or role.health
	if health then
		ply:SetMaxHealth(health)
		ply:SetHealth(health)
	end

	local walkSpeed = override and override.walkSpeed or role.walkSpeed or ply:GetWalkSpeed()
	local runSpeed = override and override.runSpeed or role.runSpeed or ply:GetRunSpeed()
	if runSpeed <= walkSpeed then
		runSpeed = walkSpeed + 20
	end
	ply:SetWalkSpeed(walkSpeed)
	ply:SetRunSpeed(runSpeed)

	local keycard = override and override.keycard or role.keycard or 0
	BR.SetKeycardLevel(ply, keycard)

	ply:StripWeapons()
	local loadout = role.loadout
	if override then
		if override.loadout == false then
			loadout = nil
		elseif istable(override.loadout) then
			loadout = override.loadout
		end
	end
	if loadout then
		for _, wep in ipairs(loadout) do
			ply:Give(wep)
		end
	end

	if keycard > 0 then
		local card = ply:Give("weapon_cz_keycard")
		if IsValid(card) and card.SetKeycardLevel then
			card:SetKeycardLevel(keycard)
		end
	end

	if role.faction ~= "scp" and role.faction ~= "spectator" then
		if not ply:HasWeapon("weapon_spawnmenu_pda") then
			ply:Give("weapon_spawnmenu_pda")
		end
	end

	if not ply:HasWeapon("weapon_hands_sh") then
		ply:Give("weapon_hands_sh")
	end

	local blocked = {
		["weapon_physgun"] = true,
		["weapon_physcannon"] = true,
		["gmod_tool"] = true,
		["gmod_camera"] = true
	}
	for class in pairs(blocked) do
		if ply:HasWeapon(class) then
			ply:StripWeapon(class)
		end
	end

	if ply:HasWeapon("weapon_fists") then
		ply:StripWeapon("weapon_fists")
	end
end

local function ShouldFreezeRole(roleId)
	roleId = BR.NormalizeRoleId(roleId or "spectator")
	if roleId == "spectator" then return false end
	local role = BR.GetRole(roleId)
	local faction = role and role.faction or nil
	if faction == "sci" or faction == "guard" then return false end
	return true
end

local function lockDoor(ent)
	if not IsValid(ent) then return end
	if ent.Fire then
		ent:Fire("Close", "", 0)
		ent:Fire("Lock", "", 0)
	end
	ent.CZ_TimedLocked = true
end

local function unlockDoor(ent, open)
	if not IsValid(ent) then return end
	if ent.Fire then
		ent:Fire("Unlock", "", 0)
		if open then
			ent:Fire("Open", "", 0)
		end
	end
	ent.CZ_TimedLocked = false
end

local function normalizeOverridePos(pos)
	if isvector(pos) then return pos end
	if istable(pos) then
		return Vector(tonumber(pos[1]) or 0, tonumber(pos[2]) or 0, tonumber(pos[3]) or 0)
	end
	return nil
end

local function normalizeAngle(ang)
	if isangle(ang) then return ang end
	if istable(ang) then
		return Angle(tonumber(ang[1]) or 0, tonumber(ang[2]) or 0, tonumber(ang[3]) or 0)
	end
	return Angle(0, 0, 0)
end

local function getMapConfig(tbl)
	if not istable(tbl) then return nil end
	local map = game.GetMap() or ""
	return tbl[map] or tbl[string.lower(map)] or tbl[string.upper(map)] or tbl["default"]
end

function getRoleOverride(roleId)
	local cfg = getMapConfig(rawget(_G, "CZ_ROLE_CONFIG"))
	if not istable(cfg) then return nil end
	if istable(cfg.roles) and cfg.roles[roleId] then
		return cfg.roles[roleId]
	end

	local role = BR.GetRole(roleId)
	local faction = role and role.faction or nil
	if faction and istable(cfg.factions) and cfg.factions[faction] then
		return cfg.factions[faction]
	end
	return nil
end

local function getSpawnOverride(roleId)
	local cfg = getMapConfig(rawget(_G, "CZ_ROLE_CONFIG"))
	if not istable(cfg) then return nil end
	if istable(cfg.roles) and istable(cfg.roles[roleId]) and istable(cfg.roles[roleId].spawnpoints) then
		return cfg.roles[roleId]
	end

	local role = BR.GetRole(roleId)
	local faction = role and role.faction or nil
	if faction and istable(cfg.factions) and istable(cfg.factions[faction]) and istable(cfg.factions[faction].spawnpoints) then
		return cfg.factions[faction]
	end
	return nil
end

local function pickSpawnPoint(cfg)
	if not istable(cfg) or not istable(cfg.spawnpoints) then return nil end
	if #cfg.spawnpoints == 0 then return nil end
	local entry = cfg.spawnpoints[math.random(#cfg.spawnpoints)]
	if not istable(entry) then return nil end
	local pos = normalizeOverridePos(entry.pos)
	if not pos then return nil end
	local ang = normalizeAngle(entry.ang or entry.angle)
	return pos, ang
end

local function applyRoleSpawn(ply, roleId)
	if not IsValid(ply) then return end
	local forced = ply.CZ_ForcedSpawn
	if istable(forced) and forced.pos then
		local pos = normalizeOverridePos(forced.pos)
		local ang = normalizeAngle(forced.ang or forced.angle)
		ply.CZ_ForcedSpawn = nil
		if pos then
			ply:SetPos(pos)
			ply:SetEyeAngles(ang)
		end
		return
	end

	local override = getSpawnOverride(roleId)
	local pos, ang = pickSpawnPoint(override)
	if pos then
		ply:SetPos(pos)
		ply:SetEyeAngles(ang)
	end
end

local lootEntities = {}

local function clearLootSpawns()
	for _, ent in ipairs(lootEntities) do
		if IsValid(ent) then
			ent:Remove()
		end
	end
	lootEntities = {}
end

local function spawnLootEntity(class, pos, ang, initFn, data)
	if not class or class == "" then return end
	local ent = ents.Create(class)
	if not IsValid(ent) then return end
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:Spawn()
	ent:Activate()
	if initFn then
		initFn(ent, data)
	end
	lootEntities[#lootEntities + 1] = ent
end

local function spawnLootGroup(list, defaultClass, resolveClass, initFn)
	if not istable(list) then return end
	for _, entry in ipairs(list) do
		if not istable(entry) then continue end
		local pos = normalizeOverridePos(entry.pos)
		if not pos then continue end
		local ang = normalizeAngle(entry.ang or entry.angle)
		local class = resolveClass and resolveClass(entry) or defaultClass
		if not class or class == "" then continue end
		spawnLootEntity(class, pos, ang, initFn, entry)
	end
end

local function applyLootSpawns()
	clearLootSpawns()

	local all = rawget(_G, "CZ_LOOT_SPAWNS")
	if not istable(all) then return end

	local map = game.GetMap() or ""
	local data = all[map] or all[string.lower(map)] or all[string.upper(map)]
	if not istable(data) then return end

	spawnLootGroup(data.keycards, "weapon_cz_keycard", function(entry)
		return entry.class or entry.weapon or "weapon_cz_keycard"
	end, function(ent, entry)
		local level = tonumber(entry.level or entry.keycard) or 1
		if ent.SetKeycardLevel then
			ent:SetKeycardLevel(level)
		end
		if ent.SetSkin and hg and hg.Breach and hg.Breach.GetKeycardSkin then
			ent:SetSkin(hg.Breach.GetKeycardSkin(level))
		end
	end)

	spawnLootGroup(data.weapons, nil, function(entry)
		return entry.class or entry.weapon
	end)

	spawnLootGroup(data.ammo, nil, function(entry)
		return entry.class or entry.ammo
	end)

	spawnLootGroup(data.items, nil, function(entry)
		return entry.class
	end)
end

local timedCloseDoors = {}

local function unlockTimedCloseDoors()
	for ent in pairs(timedCloseDoors) do
		if IsValid(ent) then
			unlockDoor(ent, false)
			ent.CZ_TimedClosed = false
		end
	end
	timedCloseDoors = {}
end

local function applyTimedDoorOverrides(baseTime)
	local overrides = rawget(_G, "CZ_TIMED_DOORS")
	if not istable(overrides) then return end
	baseTime = tonumber(baseTime) or CurTime()

	for _, data in ipairs(overrides) do
		if not istable(data) then continue end

		local delay = tonumber(data.time or data.unlock or data.delay) or 0
		local open = data.open == true or data.autoOpen == true
		local class = data.class
		local entList = {}

		if isstring(data.name) and data.name ~= "" then
			entList = ents.FindByName(data.name)
		else
			local pos = normalizeOverridePos(data.pos)
			if not pos then continue end
			local radius = tonumber(data.radius) or 4
			for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
				if not IsValid(ent) or ent:IsWorld() then continue end
				if class and ent:GetClass() ~= class then continue end
				entList[#entList + 1] = ent
				break
			end
		end

		for _, ent in ipairs(entList) do
			if not IsValid(ent) then continue end
			local unlockAt = baseTime + math.max(delay, 0)
			ent.CZ_TimedUnlockAt = unlockAt
			lockDoor(ent)
			timer.Create("CZ_TimedDoor_" .. ent:EntIndex(), math.max(unlockAt - CurTime(), 0), 1, function()
				if not IsValid(ent) then return end
				unlockDoor(ent, open)
			end)
		end
	end
end

local function applyTimedCloseOverrides(baseTime)
	local overrides = rawget(_G, "CZ_TIMED_CLOSE_DOORS")
	if not istable(overrides) then return end
	baseTime = tonumber(baseTime) or CurTime()

	for _, data in ipairs(overrides) do
		if not istable(data) then continue end

		local delay = tonumber(data.time or data.close or data.delay) or 0
		local class = data.class
		local entList = {}

		if isstring(data.name) and data.name ~= "" then
			entList = ents.FindByName(data.name)
		else
			local pos = normalizeOverridePos(data.pos)
			if not pos then continue end
			local radius = tonumber(data.radius) or 4
			for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
				if not IsValid(ent) or ent:IsWorld() then continue end
				if class and ent:GetClass() ~= class then continue end
				entList[#entList + 1] = ent
				break
			end
		end

		for _, ent in ipairs(entList) do
			if not IsValid(ent) then continue end
			local closeAt = baseTime + math.max(delay, 0)
			ent.CZ_TimedCloseAt = closeAt
			timer.Create("CZ_TimedCloseDoor_" .. ent:EntIndex(), math.max(closeAt - CurTime(), 0), 1, function()
				if not IsValid(ent) then return end
				ent.CZ_TimedClosed = true
				timedCloseDoors[ent] = true
				lockDoor(ent)
			end)
		end
	end
end

local function getNtfConfig()
	local cfg = getMapConfig(rawget(_G, "CZ_NTF_CONFIG"))
	if not istable(cfg) then return nil end
	if cfg.enabled == false then return nil end
	return cfg
end

local function getSpectatorCandidates()
	local list = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and BR.IsSpectator(ply) and not ply:GetNWBool("CZ_WantsSpectator", false) then
			list[#list + 1] = ply
		end
	end
	return list
end

local function spawnNtfWave()
	local cfg = getNtfConfig()
	if not cfg then return end
	local roles = istable(cfg.roles) and cfg.roles or {"guard_default"}
	if #roles == 0 then return end
	local spawnpoints = istable(cfg.spawnpoints) and cfg.spawnpoints or {}
	if #spawnpoints == 0 then return end

	local count = tonumber(cfg.count) or #roles
	if count <= 0 then return end

	local pool = Shuffle(getSpectatorCandidates())
	if #pool == 0 then return end

	local maxCount = math.min(count, #pool)
	for i = 1, maxCount do
		local ply = pool[i]
		if not IsValid(ply) then continue end
		local roleId = roles[math.random(#roles)] or "guard_default"
		ply.CZ_ForcedSpawn = spawnpoints[math.random(#spawnpoints)]
		ply.CZ_AssignedRole = roleId
			ply:Spawn()
			hook.Run("CZ_PlayerBecameNTF", ply, roleId)
	end
end

local function stopNtfWaves()
	timer.Remove("CZ_NTF_Initial")
	timer.Remove("CZ_NTF_Wave")
end

local function startNtfWaves()
	stopNtfWaves()
	local cfg = getNtfConfig()
	if not cfg then return end
	local initialDelay = tonumber(cfg.initialDelay) or 300
	local repeatDelay = tonumber(cfg.repeatDelay) or 240
	timer.Create("CZ_NTF_Initial", math.max(0, initialDelay), 1, function()
		if roundState ~= BR.RoundStates.ACTIVE then return end
		spawnNtfWave()
		if repeatDelay > 0 then
			timer.Create("CZ_NTF_Wave", repeatDelay, 0, function()
				if roundState ~= BR.RoundStates.ACTIVE then return end
				spawnNtfWave()
			end)
		end
	end)
end

local function getEscapeZones()
	return getMapConfig(rawget(_G, "CZ_ESCAPE_ZONES")) or {}
end

local function valueInList(val, list)
	if not istable(list) then return false end
	for _, entry in ipairs(list) do
		if entry == val then return true end
	end
	return false
end

local function isEscapeAllowed(ply, zone)
	if not IsValid(ply) or not istable(zone) then return false end
	if BR.IsSpectator(ply) then return false end
	local role = BR.GetPlayerClass(ply)
	if not role then return false end
	if istable(zone.roles) and not valueInList(role.id, zone.roles) then return false end
	if istable(zone.factions) and not valueInList(role.faction, zone.factions) then return false end
	return true
end

local function StartPrep()
	unlockTimedCloseDoors()
	stopNtfWaves()
	SetRoundState(BR.RoundStates.PREP, PREP_TIME)
	AssignClasses()
	applyLootSpawns()
	applyTimedDoorOverrides(CurTime() + PREP_TIME)
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			ply:Spawn()
			if ShouldFreezeRole(ply.CZ_AssignedRole) then
				ply:Freeze(true)
			else
				ply:Freeze(false)
			end
		end
	end
end

local function StartActive()
	SetRoundState(BR.RoundStates.ACTIVE, ROUND_TIME)
	applyTimedCloseOverrides(CurTime())
	startNtfWaves()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			ply:Freeze(false)
		end
	end
end

local function EndRound(winnerFaction)
	SetRoundState(BR.RoundStates.POST, POST_TIME, winnerFaction)
	stopNtfWaves()
	if BR.TriggerRoundEndBoom then
		BR.TriggerRoundEndBoom()
	end
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and not BR.IsSpectator(ply) then
			hook.Run("CZ_PlayerSurvivedRound", ply, winnerFaction)
		end
	end
	hook.Run("CZ_RoundEnded", winnerFaction)
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			SetPlayerSpectator(ply, true)
		end
	end
end

local function GetAliveFactions()
	local counts = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and not BR.IsSpectator(ply) then
			local class = BR.GetPlayerClass(ply)
			local faction = class and class.faction or nil
			if faction then
				counts[faction] = (counts[faction] or 0) + 1
			end
		end
	end
	return counts
end

local function CheckForWinner()
	local counts = GetAliveFactions()
	local aliveFactions = {}
	for faction, cnt in pairs(counts) do
		if cnt > 0 then
			aliveFactions[#aliveFactions + 1] = faction
		end
	end

	if #aliveFactions == 1 then
		EndRound(aliveFactions[1])
		return true
	end

	if #aliveFactions == 0 then
		EndRound("dead")
		return true
	end

	return false
end

hook.Add("Think", "CZ_BreachRoundThink", function()
	local players = GetPlayCandidates()
	if roundState == BR.RoundStates.WAITING then
		if #players >= MIN_PLAYERS then
			StartPrep()
		end
		return
	end

	if roundState == BR.RoundStates.PREP then
		if roundStateEnd > 0 and CurTime() >= roundStateEnd then
			StartActive()
		end
		return
	end

	if roundState == BR.RoundStates.ACTIVE then
		if roundStateEnd > 0 and CurTime() >= roundStateEnd then
			EndRound("")
			return
		end
		CheckForWinner()
		return
	end

	if roundState == BR.RoundStates.POST then
		if roundStateEnd > 0 and CurTime() >= roundStateEnd then
			SetRoundState(BR.RoundStates.WAITING, 0)
		end
	end
end)

local nextEscapeCheck = 0
hook.Add("Think", "CZ_EscapeZoneThink", function()
	if roundState ~= BR.RoundStates.ACTIVE then return end
	if CurTime() < nextEscapeCheck then return end
	nextEscapeCheck = CurTime() + 0.5

	local zones = getEscapeZones()
	if not istable(zones) or #zones == 0 then return end

	for _, zone in ipairs(zones) do
		if not istable(zone) then continue end
		local pos = normalizeOverridePos(zone.pos)
		if not pos then continue end
		local radius = tonumber(zone.radius) or 64
		local radiusSqr = radius * radius

		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:Alive() then continue end
			if ply.CZ_Escaped then continue end
			if not isEscapeAllowed(ply, zone) then continue end
			if ply:GetPos():DistToSqr(pos) <= radiusSqr then
				ply.CZ_Escaped = true
				hook.Run("CZ_PlayerEscaped", ply, zone)
				SetPlayerSpectator(ply, true)
				if zone.message then
					ply:ChatPrint(tostring(zone.message))
				else
					ply:ChatPrint("You escaped.")
				end
			end
		end
	end
end)

hook.Add("PlayerInitialSpawn", "CZ_BreachInitial", function(ply)
	ply:SetNWBool("CZ_WantsSpectator", false)
	ply:SetNWBool("CZ_NoScp", false)
	ply.CZ_AssignedRole = "spectator"
	timer.Simple(0, function()
		if IsValid(ply) then
			ply:Spawn()
		end
	end)
end)

hook.Add("PlayerSpawn", "CZ_BreachApplyClass", function(ply)
	local roleId = ply.CZ_AssignedRole or "spectator"
	ply.CZ_Escaped = nil
	ApplyRole(ply, roleId)
	if roleId ~= "spectator" then
		BR.AssignDisplayName(ply, false)
		local card = ply:GetWeapon("weapon_cz_keycard")
		if IsValid(card) and card.InitCardData then
			card:InitCardData(ply, roleId)
		end
	end
	timer.Simple(0, function()
		if IsValid(ply) then
			applyRoleSpawn(ply, roleId)
		end
	end)
	if roundState == BR.RoundStates.PREP and ShouldFreezeRole(roleId) then
		ply:Freeze(true)
	else
		ply:Freeze(false)
	end
end)

hook.Add("PlayerDeath", "CZ_NoDeathWeaponDrop", function(ply)
	if not IsValid(ply) then return end
	ply.CZ_DeathDropAt = CurTime()
end)

hook.Add("PlayerDroppedWeapon", "CZ_RemoveDeathDroppedWeapon", function(owner, wep)
	if not IsValid(owner) then return end
	if (owner.CZ_DeathDropAt or 0) + 0.25 < CurTime() then return end
	if IsValid(wep) then
		wep:Remove()
	end
end)

hook.Add("PlayerDeath", "CZ_BreachSpectateOnDeath", function(ply)
	if roundState == BR.RoundStates.WAITING then return end
	ply.CZ_AssignedRole = "spectator"
	timer.Simple(0, function()
		if IsValid(ply) then
			SetPlayerSpectator(ply, false)
		end
	end)
end)

hook.Add("PlayerDeathThink", "CZ_BreachNoRespawn", function(ply)
	if roundState ~= BR.RoundStates.WAITING then
		return false
	end
end)

hook.Add("PlayerDisconnected", "CZ_BreachPlayerLeft", function()
	if roundState == BR.RoundStates.ACTIVE then
		CheckForWinner()
	end
end)

hook.Add("PlayerCanPickupWeapon", "CZ_BreachBlockSCPWeapon", function(ply, wep)
	if BR.IsSpectator(ply) then return false end
	if BR.IsSCP(ply) then return false end
	if IsValid(wep) and wep:GetClass() == "weapon_fists" then return false end
	if IsValid(wep) then
		local class = wep:GetClass()
		if class == "weapon_physgun" or class == "weapon_physcannon"
			or class == "gmod_tool" or class == "gmod_camera" then
			return false
		end
	end
end)

hook.Add("PlayerCanPickupItem", "CZ_BreachBlockSCPItem", function(ply)
	if BR.IsSpectator(ply) then return false end
	if BR.IsSCP(ply) then return false end
end)

hook.Add("PlayerUse", "CZ_BreachKeycardUse", function(ply, ent)
	if not IsValid(ply) or not IsValid(ent) then return end
	if BR.IsSpectator(ply) then return false end
	if BR.IsSCP(ply) and (ent:IsWeapon() or string.StartWith(ent:GetClass(), "item_")) then
		return false
	end
	if ent.CZ_TimedClosed then
		if (ply._CZ_TimedDoorNotify or 0) < CurTime() then
			ply._CZ_TimedDoorNotify = CurTime() + 1
			ply:ChatPrint("Door locked until round end.")
		end
		return false
	end
	if ent.CZ_TimedUnlockAt and CurTime() < ent.CZ_TimedUnlockAt then
		if (ply._CZ_TimedDoorNotify or 0) < CurTime() then
			ply._CZ_TimedDoorNotify = CurTime() + 1
			local left = math.max(0, math.ceil(ent.CZ_TimedUnlockAt - CurTime()))
			ply:ChatPrint("Door locked. Unlocks in " .. left .. "s.")
		end
		return false
	end

	local required = BR.GetRequiredKeycard(ent)
	if required <= 0 then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.CZ_IsKeycard then
		if (ply._CZ_KeycardNotify or 0) < CurTime() then
			ply._CZ_KeycardNotify = CurTime() + 1
			ply:ChatPrint("Access denied. Keycard required.")
		end
		return false
	end

	net.Start("CZ_KeycardAnim")
	net.WriteEntity(ent)
	net.Send(ply)

	wep:UseKeycard(ent)
	return false
end)

hook.Add("EntityTakeDamage", "CZ_BlockHandsDamage", function(target, dmg)
	local attacker = dmg:GetAttacker()
	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	local wep = attacker:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "weapon_hands_sh" then return end
	dmg:SetDamage(0)
	dmg:SetDamageForce(vector_origin)
end)

local function applyKeycardOverrides()
	local overrides = rawget(_G, "CZ_KEYCARD_OVERRIDE")
	if not istable(overrides) then return end

	for _, data in ipairs(overrides) do
		if not istable(data) then continue end

		local pos = normalizeOverridePos(data.pos)
		if not pos then continue end

		local level = tonumber(data.level) or tonumber(data.keycard) or 0
		if level <= 0 then continue end

		local radius = tonumber(data.radius) or 4
		local class = data.class
		local found

		for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
			if not IsValid(ent) or ent:IsWorld() then continue end
			if class and ent:GetClass() ~= class then continue end
			found = ent
			break
		end

		if IsValid(found) then
			BR.SetRequiredKeycard(found, level)
		end
	end
end

hook.Add("InitPostEntity", "CZ_KeycardOverrides", applyKeycardOverrides)
hook.Add("PostCleanupMap", "CZ_KeycardOverrides", function()
	timer.Simple(0, applyKeycardOverrides)
end)

net.Receive("CZ_SetScpOptOut", function(_, ply)
	if not IsValid(ply) then return end
	local optout = net.ReadBool()
	ply:SetNWBool("CZ_NoScp", optout)
end)

net.Receive("CZ_SpectateCycle", function(_, ply)
	if not IsValid(ply) then return end
	local dir = net.ReadInt(3)
	if dir == 0 then dir = 1 end

	local targets = GetSpectateTargets(ply)

	if #targets == 0 then
		SetPlayerSpectator(ply, true)
		return
	end

	local idx = (ply.CZ_SpecIndex or 0) + dir
	if idx < 1 then idx = #targets end
	if idx > #targets then idx = 1 end
	ply.CZ_SpecIndex = idx

	local target = targets[idx]
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(target)
	ply:SetNWInt("viewmode", 1)
	ply:SetNWEntity("spect", target)
end)

local function FindPlayerByQuery(query)
	if not query or query == "" then return nil end
	local bySteam = player.GetBySteamID(query) or player.GetBySteamID64(query)
	if IsValid(bySteam) then return bySteam end

	local q = string.lower(query)
	for _, ply in ipairs(player.GetAll()) do
		if string.find(string.lower(ply:Nick()), q, 1, true) then
			return ply
		end
	end
	return nil
end

concommand.Add("cz_setrole", function(ply, _, args)
	local isConsole = not IsValid(ply)
	if not isConsole and not ply:IsSuperAdmin() then return end

	local targetArg = args[1]
	local roleArg = args[2]
	if not targetArg or not roleArg then
		if IsValid(ply) then
			ply:ChatPrint("Usage: cz_setrole <player> <roleId>")
		else
			print("Usage: cz_setrole <player> <roleId>")
		end
		return
	end

	local target = FindPlayerByQuery(targetArg)
	if not IsValid(target) then
		if IsValid(ply) then
			ply:ChatPrint("Player not found.")
		else
			print("Player not found.")
		end
		return
	end

	local role = BR.GetRole(roleArg)
	if not role then
		if IsValid(ply) then
			ply:ChatPrint("Unknown role: " .. roleArg)
		else
			print("Unknown role: " .. roleArg)
		end
		return
	end

	target.CZ_AssignedRole = role.id
	BR.AssignDisplayName(target, true)
	target:Spawn()
end)

concommand.Add("cz_spectator", function(ply)
	if not IsValid(ply) then return end
	local want = not ply:GetNWBool("CZ_WantsSpectator", false)
	ply:SetNWBool("CZ_WantsSpectator", want)
	ply.CZ_AssignedRole = "spectator"
	if want then
		SetPlayerSpectator(ply, true)
	else
		if roundState == BR.RoundStates.WAITING then
			ply:Spawn()
		end
	end
end)
