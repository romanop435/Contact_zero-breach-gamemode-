hg = hg or {}
hg.achievements = hg.achievements or {}

local ACH = hg.achievements
ACH.achievements_data = ACH.achievements_data or {}
ACH.achievements_data.player_achievements = ACH.achievements_data.player_achievements or {}
ACH.achievements_data.created_achevements = ACH.achievements_data.created_achevements or {}

local DATA_ROOT = "contact_zero"
local ACH_DIR = DATA_ROOT .. "/achievements"
local PLAYER_DIR = ACH_DIR .. "/players"

local function ensureDir(path)
    if not file.Exists(path, "DATA") then
        file.CreateDir(path)
    end
end

function ACH.Init()
    ensureDir(DATA_ROOT)
    ensureDir(ACH_DIR)
    ensureDir(PLAYER_DIR)
end

ACH.Init()

function ACH.LoadAchievements()
    local json = file.Read(ACH_DIR .. "/definitions.json", "DATA")
    if json then
        local data = util.JSONToTable(json)
        if istable(data) then
            ACH.achievements_data.created_achevements = data
        end
    end
end

function ACH.SaveAchievements()
    file.Write(ACH_DIR .. "/definitions.json", util.TableToJSON(ACH.achievements_data.created_achevements or {}, true))
end

local function playerFilePath(ply)
    local steamID64 = IsValid(ply) and ply:SteamID64() or nil
    if not steamID64 or steamID64 == "0" then return nil end
    return PLAYER_DIR .. "/" .. steamID64 .. ".json"
end

function ACH.LoadPlayerAchievements(ply)
    local path = playerFilePath(ply)
    if not path then return end
    local json = file.Read(path, "DATA")
    local data = json and util.JSONToTable(json) or {}
    ACH.achievements_data.player_achievements[ply:SteamID64()] = istable(data) and data or {}
end

function ACH.SavePlayerAchievements(ply, data)
    local path = playerFilePath(ply)
    if not path then return end
    file.Write(path, util.TableToJSON(data or ACH.GetPlayerAchievements(ply) or {}, true))
end

function ACH.CreateAchievementType(key, needed_value, start_value, description, name, img, showpercent)
    ACH.achievements_data.created_achevements[key] = {
        start_value = start_value or 0,
        needed_value = needed_value or 1,
        description = description or "",
        name = name or key,
        img = img or "icon16/star.png",
        key = key,
        showpercent = showpercent or false
    }
end

function ACH.GetCreatedAchievements()
    return ACH.achievements_data.created_achevements
end

function ACH.GetAchievementInfo(key)
    return ACH.achievements_data.created_achevements[key]
end

function ACH.GetPlayerAchievements(ply)
    local steamID = ply:SteamID64()
    ACH.achievements_data.player_achievements[steamID] = ACH.achievements_data.player_achievements[steamID] or {}
    return ACH.achievements_data.player_achievements[steamID]
end

function ACH.GetPlayerAchievement(ply, key)
    local data = ACH.GetPlayerAchievements(ply)
    data[key] = data[key] or {}
    return data[key]
end

local function isAchievementCompleted(ply, key, val)
    local ach = ACH.achievements_data.created_achevements[key]
    if not ach then return false end
    local current = ACH.GetPlayerAchievement(ply, key).value or ach.start_value or 0
    return val >= ach.needed_value and current < ach.needed_value
end

util.AddNetworkString("hg_NewAchievement")

function ACH.SetPlayerAchievement(ply, key, val)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local playerAchievements = ACH.GetPlayerAchievements(ply)
    playerAchievements[key] = playerAchievements[key] or {}

    if isAchievementCompleted(ply, key, val) then
        local ach = ACH.achievements_data.created_achevements[key]
        if ach then
            net.Start("hg_NewAchievement")
                net.WriteString(ach.name)
                net.WriteString(ach.img)
            net.Send(ply)
        end
    end

    playerAchievements[key].value = val
    ACH.SavePlayerAchievements(ply, playerAchievements)
end

function ACH.ApproachPlayerAchievement(ply, key, val)
    local ach_info = ACH.GetAchievementInfo(key)
    if not ach_info then return end
    local ach = ACH.GetPlayerAchievement(ply, key)
    local startValue = ach.value or ach_info.start_value or 0
    local newValue = math.Approach(startValue, ach_info.needed_value, val or 1)
    ACH.SetPlayerAchievement(ply, key, newValue)
end

util.AddNetworkString("req_ach")

net.Receive("req_ach", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.ach_cooldown or 0) > CurTime() then return end
    ply.ach_cooldown = CurTime() + 2
    net.Start("req_ach")
        net.WriteTable(ACH.GetCreatedAchievements())
        net.WriteTable(ACH.GetPlayerAchievements(ply))
    net.Send(ply)
end)

local function isSpectator(ply)
    return hg and hg.Breach and hg.Breach.IsSpectator and hg.Breach.IsSpectator(ply) or false
end

local function shouldTrack(ply)
    return IsValid(ply) and ply:IsPlayer() and not isSpectator(ply)
end

hook.Add("PlayerInitialSpawn", "CZ_Achievements_LoadPlayer", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then
            ACH.LoadPlayerAchievements(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "CZ_Achievements_SavePlayer", function(ply)
    if IsValid(ply) then
        ACH.SavePlayerAchievements(ply)
    end
end)

hook.Add("ShutDown", "CZ_Achievements_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do
        ACH.SavePlayerAchievements(ply)
    end
end)

hook.Add("PlayerDeath", "CZ_Achievements_Death", function(ply, inf, att)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "die_once", 1)
    end
    if IsValid(att) and att:IsPlayer() and att ~= ply and shouldTrack(att) then
        if hg and hg.Breach and hg.Breach.IsSCP and hg.Breach.IsSCP(ply) then
            ACH.ApproachPlayerAchievement(att, "kill_scp", 1)
        end
    end
end)

hook.Add("CZ_PlayerBleedStart", "CZ_Achievements_Bleed", function(ply)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "first_bleed", 1)
    end
end)

hook.Add("CZ_PlayerLegsBroken", "CZ_Achievements_Legs", function(ply)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "first_fracture", 1)
    end
end)

hook.Add("CZ_KeycardAccess", "CZ_Achievements_Keycard", function(ply, ent, required, level, granted)
    if not shouldTrack(ply) then return end
    if granted then
        ACH.ApproachPlayerAchievement(ply, "access_granted", 1)
    else
        ACH.ApproachPlayerAchievement(ply, "access_denied", 1)
    end
end)

hook.Add("CZ_PlayerEscaped", "CZ_Achievements_Escape", function(ply)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "escape_once", 1)
    end
end)

hook.Add("CZ_PlayerSurvivedRound", "CZ_Achievements_Survive", function(ply)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "survive_round", 1)
    end
end)

hook.Add("CZ_PlayerBecameNTF", "CZ_Achievements_NTF", function(ply)
    if shouldTrack(ply) then
        ACH.ApproachPlayerAchievement(ply, "ntf_arrival", 1)
    end
end)

local function registerDefaults()
    ACH.achievements_data.created_achevements = {}
    ACH.CreateAchievementType("first_bleed", 1, 0, "Start bleeding for the first time.", "First Blood", "icon16/drop.png", false)
    ACH.CreateAchievementType("first_fracture", 1, 0, "Break your leg for the first time.", "Crack", "icon16/user_red.png", false)
    ACH.CreateAchievementType("access_granted", 1, 0, "Open a door with a keycard.", "Access Granted", "icon16/accept.png", false)
    ACH.CreateAchievementType("access_denied", 1, 0, "Get denied by a keycard door.", "Access Denied", "icon16/cancel.png", false)
    ACH.CreateAchievementType("escape_once", 1, 0, "Escape the facility.", "Free At Last", "icon16/door_out.png", false)
    ACH.CreateAchievementType("survive_round", 1, 0, "Survive until round end.", "Survivor", "icon16/heart.png", false)
    ACH.CreateAchievementType("ntf_arrival", 1, 0, "Join an NTF wave.", "Reinforcements", "icon16/shield.png", false)
    ACH.CreateAchievementType("kill_scp", 1, 0, "Eliminate an SCP.", "Containment", "icon16/gun.png", false)
    ACH.CreateAchievementType("die_once", 1, 0, "Die once.", "Not Like This", "icon16/skull.png", false)

    ACH.SaveAchievements()
end

ACH.LoadAchievements()
registerDefaults()
