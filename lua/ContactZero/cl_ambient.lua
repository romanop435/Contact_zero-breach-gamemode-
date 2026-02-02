if SERVER then return end

hg = hg or {}
if not hg.Breach then
	include("ContactZero/breach/sh_breach.lua")
end
local BR = hg.Breach

AMBIENT = AMBIENT or {}
AMBIENT.CHANNEL = AMBIENT.CHANNEL or nil
AMBIENT.SOUND = AMBIENT.SOUND or nil
AMBIENT.BAN = AMBIENT.BAN or 0
AMBIENT.VOLUME = AMBIENT.VOLUME or 0.5
AMBIENT.FOLDER = AMBIENT.FOLDER or "sound/ambience/"
AMBIENT.COUNT = AMBIENT.COUNT or 5
AMBIENT.EXT = AMBIENT.EXT or ".mp3"
AMBIENT.TIME = AMBIENT.TIME or 0
AMBIENT.MUTE_UNTIL = AMBIENT.MUTE_UNTIL or 0
AMBIENT.SWITCH_INTERVAL = AMBIENT.SWITCH_INTERVAL or 120
AMBIENT.NEXT_SWITCH = AMBIENT.NEXT_SWITCH or 0
AMBIENT.SOUNDS = AMBIENT.SOUNDS or {
	AMBIENT.FOLDER .. "ambient_1.mp3",
	AMBIENT.FOLDER .. "ambient_2.mp3",
	AMBIENT.FOLDER .. "ambient_3.mp3",
	AMBIENT.FOLDER .. "ambient_4.ogg"
}

local cvAmbientVolume = ConVarExists("cz_ambient_volume") and GetConVar("cz_ambient_volume")
	or CreateClientConVar("cz_ambient_volume", "0.5", true, false, "Ambient volume")

local function getAmbientList()
	local override = rawget(_G, "CZ_AMBIENT_SOUNDS")
	if istable(override) then return override end
	return AMBIENT.SOUNDS
end

local function pickAmbientSound()
	local list = getAmbientList()
	if istable(list) and #list > 0 then
		return list[math.random(#list)]
	end

	local count = tonumber(AMBIENT.COUNT) or 0
	if count > 0 then
		return string.format("%s%d%s", AMBIENT.FOLDER, math.random(count), AMBIENT.EXT)
	end

	return nil
end

local function getVolume()
	return math.Clamp((AMBIENT.VOLUME or 0.5) * cvAmbientVolume:GetFloat(), 0, 1)
end

local function shouldPlayAmbient()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end
	if BR and BR.IsSpectator and BR.IsSpectator(ply) then return false end
	if (AMBIENT.MUTE_UNTIL or 0) > CurTime() then return false end

	if BR and BR.RoundStates then
		local state = GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING)
		return state == BR.RoundStates.PREP or state == BR.RoundStates.ACTIVE
	end

	return true
end

function AMBIENT.Restart(name)
	AMBIENT.Remove()
	local picked = name or pickAmbientSound()
	if not picked or picked == "" then return end

	AMBIENT.SOUND = picked
	if (AMBIENT.SWITCH_INTERVAL or 0) > 0 then
		AMBIENT.NEXT_SWITCH = CurTime() + AMBIENT.SWITCH_INTERVAL
	else
		AMBIENT.NEXT_SWITCH = 0
	end
	sound.PlayFile(picked, "", function(station, errCode, errStr)
		if not IsValid(station) then
			print("Error playing ambience!", errCode, errStr)
			return
		end

		AMBIENT.CHANNEL = station
		station:SetVolume(getVolume())
		station:Play()
	end)
end

function AMBIENT.Pause()
	if AMBIENT.CHANNEL ~= nil then
		AMBIENT.CHANNEL:Pause()
	end
end

function AMBIENT.Start()
	if AMBIENT.CHANNEL ~= nil then
		AMBIENT.CHANNEL:Play()
	end
end

function AMBIENT.Stop()
	if AMBIENT.CHANNEL ~= nil then
		AMBIENT.CHANNEL:Stop()
	end
end

function AMBIENT.Remove()
	if AMBIENT.CHANNEL ~= nil then
		AMBIENT.CHANNEL:Stop()
		AMBIENT.CHANNEL = nil
	end
end

function AMBIENT.Ban(time)
	AMBIENT.BAN = tonumber(time) or 0
end

function AMBIENT.MuteFor(seconds)
	local dur = tonumber(seconds) or 0
	if dur <= 0 then return end
	AMBIENT.MUTE_UNTIL = math.max(AMBIENT.MUTE_UNTIL or 0, CurTime() + dur)
end

function AMBIENT.SetSounds(list)
	if not istable(list) then return end
	AMBIENT.SOUNDS = list
end

local checkTime = 0
local ambThinkDelay = 1
local lastRoundState = nil
local lastAlive = nil
hook.Add("Think", "CZ_Ambience", function()
	if checkTime > CurTime() then return end
	checkTime = CurTime() + ambThinkDelay

	local channel = AMBIENT.CHANNEL
	local ply = LocalPlayer()
	local alive = IsValid(ply) and ply:Alive() or false
	local state = BR and BR.RoundStates and GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING) or nil

	if BR and BR.RoundStates and state ~= lastRoundState then
		if state == BR.RoundStates.PREP then
			if shouldPlayAmbient() then
				AMBIENT.Restart()
			end
		end
		lastRoundState = state
	end

	if lastAlive ~= nil and alive and not lastAlive then
		if shouldPlayAmbient() then
			AMBIENT.Restart()
		end
	end
	lastAlive = alive

	if not shouldPlayAmbient() then
		if IsValid(channel) and channel:GetState() ~= 0 then
			channel:Pause()
		end
		return
	end

	if (AMBIENT.NEXT_SWITCH or 0) > 0 and CurTime() >= AMBIENT.NEXT_SWITCH then
		AMBIENT.Restart()
		return
	end

	if IsValid(channel) and channel:GetState() == 2 then
		channel:Play()
	end

	if channel == nil or not IsValid(channel) or channel:GetState() == 0 then
		if IsValid(channel) and math.floor(channel:GetLength()) <= math.ceil(AMBIENT.TIME or 0) then
			AMBIENT.SOUND = nil
		end

		if (AMBIENT.BAN or 0) <= 0 then
			AMBIENT.Restart()
		else
			AMBIENT.BAN = math.max(0, (AMBIENT.BAN or 0) - ambThinkDelay)
		end
		return
	end

	AMBIENT.TIME = channel:GetTime()
	local desired = getVolume()
	if AMBIENT._lastVolume ~= desired then
		AMBIENT._lastVolume = desired
		channel:SetVolume(desired)
	end
end)

hook.Add("ShutDown", "CZ_AmbienceShutdown", function()
	AMBIENT.Remove()
end)
