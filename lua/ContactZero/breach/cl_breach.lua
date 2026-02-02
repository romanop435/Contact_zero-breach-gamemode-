hg = hg or {}
if not hg.Breach then
	include("ContactZero/breach/sh_breach.lua")
end
local BR = hg.Breach
if not BR then return end

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "ui font")
local function getFont()
	local usefont = "Bahnschrift"
	if hg_font:GetString() ~= "" then
		usefont = hg_font:GetString()
	end
	return usefont
end

surface.CreateFont("CZ_HUD_Small", {
	font = getFont(),
	size = 14,
	weight = 700
})

surface.CreateFont("CZ_HUD_Title", {
	font = getFont(),
	size = 20,
	weight = 800
})

surface.CreateFont("CZ_End_Title", {
	font = getFont(),
	size = 26,
	weight = 800
})

surface.CreateFont("CZ_End_Body", {
	font = getFont(),
	size = 18,
	weight = 700
})

surface.CreateFont("CZ_End_Small", {
	font = getFont(),
	size = 16,
	weight = 600
})

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}

hook.Add("HUDShouldDraw", "CZ_BreachHideDefaultHUD", function(name)
	if hide[name] then return false end
end)

local displayStamina = 100
local displayRoundLeft = 0
local panelAlpha = 0
local panelSlide = 0
local breachFadeStart = nil
local breachFadeIn = 0.05
local breachFadeHold = 0.6
local breachFadeOut = 1.0

local lastRoundState = nil
local lastAlive = nil
local deathSound = "player/death_1.ogg"
local deathSoundLevel = 90
local deathSoundVolume = 1
local breachSound = "breach.mp3"
local prepSound = "start_ambience1.ogg"
local prepChannel = nil
local prepLastState = nil

BR.RoundEndLogos = BR.RoundEndLogos or {
	classd = "icons/class_d.png",
	sci = "icons/sci.png",
	guard = "icons/sb.png",
	scp = "icons/scp.png",
	default = "icons/scp.png"
}
BR.RoundEndText = BR.RoundEndText or {}

local roundEndLogoCache = {}

local function getRoundEndLogo(factionId)
	if factionId == "" or factionId == "dead" or factionId == "spectator" then
		return nil
	end

	local overrides = rawget(_G, "CZ_ROUND_END_LOGOS") or BR.RoundEndLogos
	local entry = overrides and overrides[factionId] or nil
	if entry == nil then
		entry = overrides and overrides.default or "icons/scp.png"
	end

	if entry == false then
		return nil
	end

	if type(entry) == "IMaterial" then
		return entry
	end

	if isstring(entry) and entry ~= "" then
		roundEndLogoCache[entry] = roundEndLogoCache[entry] or Material(entry, "smooth")
		return roundEndLogoCache[entry]
	end

	return BR.GetFactionIcon(factionId)
end

local function getRoundEndResultText(factionId)
	local overrides = rawget(_G, "CZ_ROUND_END_TEXT") or BR.RoundEndText
	local entry = overrides and overrides[factionId] or nil
	if isstring(entry) and entry ~= "" then
		return entry
	end

	if factionId == "dead" then
		return "Никого не осталось в живых"
	end

	if not factionId or factionId == "" or factionId == "spectator" then
		return "Containment Breach has ended"
	end

	return BR.GetFactionDisplayName(factionId) .. " victory"
end

local function GetHudMetrics()
	local x, y = BR.GetHudAnchor()
	local barW = math.floor(ScrW() * 0.18)
	barW = math.Clamp(barW, 180, 320)
	local barH = ScreenScale(10)
	return x, y, barW, barH
end

local function DrawStamina()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local maxStamina = tonumber(MAX_STAMINA) or 100
	maxStamina = math.max(maxStamina, 1)
	local stamina = math.Clamp(ply:GetNWInt("Stamina", maxStamina), 0, maxStamina)
	displayStamina = Lerp(FrameTime() * 10, displayStamina, stamina)

	local x, y, barW, barH = GetHudMetrics()
	local frac = math.Clamp(displayStamina / maxStamina, 0, 1)

	local low = 1 - frac
	local r = Lerp(low, 70, 40)
	local g = Lerp(low, 200, 110)
	local b = Lerp(low, 240, 120)

	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(x, y, barW, barH)

	surface.SetDrawColor(r, g, b, 230)
	surface.DrawRect(x, y, barW * frac, barH)

	surface.SetDrawColor(255, 255, 255, 30)
	surface.DrawOutlinedRect(x, y, barW, barH)

	draw.SimpleText(math.ceil(displayStamina), "CZ_HUD_Small", x + barW - 2, y - 1, Color(255, 255, 255, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
end

local function FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local function TriggerBreachIntro()
	breachFadeStart = CurTime()
	surface.PlaySound(breachSound)

	if AMBIENT and AMBIENT.MuteFor then
		if AMBIENT.Pause then
			AMBIENT.Pause()
		end
		local duration = SoundDuration(breachSound)
		if duration <= 0 then
			duration = 5
		end
		AMBIENT.MuteFor(duration)
	end
end

local function stopPrepAmbience()
	if IsValid(prepChannel) then
		prepChannel:Stop()
		prepChannel = nil
	end
end

local function startPrepAmbience()
	if IsValid(prepChannel) then
		if prepChannel:GetState() == 2 then
			prepChannel:Play()
		end
		if prepChannel:GetState() ~= 0 then return end
	end
	sound.PlayFile("sound/" .. prepSound, "", function(station, errCode, errStr)
		if not IsValid(station) then
			print("Error playing prep ambience!", errCode, errStr)
			return
		end

		prepChannel = station
		station:Play()
	end)
end

local function shouldPlayPrepMusic()
	local ply = LocalPlayer()
	if not IsValid(ply) then return false end
	if BR and BR.IsSpectator and BR.IsSpectator(ply) then return false end
	local state = GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING)
	return state == BR.RoundStates.PREP
end

local function DrawRoundTimer()
	local state = GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING)
	if state ~= BR.RoundStates.PREP and state ~= BR.RoundStates.ACTIVE then return end

	local endTime = GetGlobalFloat("CZ_RoundStateEnd", 0)
	if endTime <= 0 then return end

	local remaining = math.max(0, endTime - CurTime())
	local label = state == BR.RoundStates.PREP and "Freeze ends in" or "Round ends in"
	local text = label .. ": " .. FormatTime(remaining)

	local w = math.min(ScrW() * 0.4, 420)
	local h = ScreenScale(14)
	local x = (ScrW() - w) * 0.5
	local y = ScreenScale(8)

	surface.SetDrawColor(0, 0, 0, 170)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(255, 255, 255, 30)
	surface.DrawOutlinedRect(x, y, w, h)
	draw.SimpleText(text, "CZ_HUD_Title", x + w * 0.5, y + h * 0.5, Color(255, 255, 255, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawRoundEnd()
	local state = GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING)
	local isPost = state == BR.RoundStates.POST
	panelAlpha = Lerp(FrameTime() * 6, panelAlpha, isPost and 1 or 0)
	panelSlide = Lerp(FrameTime() * 6, panelSlide, isPost and 0 or -20)
	if panelAlpha <= 0.01 then return end

	local endTime = GetGlobalFloat("CZ_RoundStateEnd", 0)
	local remaining = math.max(0, endTime - CurTime())
	displayRoundLeft = Lerp(FrameTime() * 6, displayRoundLeft, remaining)

	local winner = GetGlobalString("CZ_RoundWinner", "")
	local w = math.min(ScrW() * 0.45, 520)
	local h = math.min(ScrH() * 0.42, 320)
	local x = (ScrW() - w) * 0.5
	local y = (ScrH() - h) * 0.45 + panelSlide

	local a = math.floor(210 * panelAlpha)
	surface.SetDrawColor(12, 12, 12, a)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(255, 255, 255, math.floor(25 * panelAlpha))
	surface.DrawOutlinedRect(x, y, w, h)

	local corner = math.floor(math.min(w, h) * 0.06)
	local cornerAlpha = math.floor(180 * panelAlpha)
	surface.SetDrawColor(255, 255, 255, cornerAlpha)
	surface.DrawRect(x, y, corner, 2)
	surface.DrawRect(x, y, 2, corner)
	surface.DrawRect(x + w - corner, y, corner, 2)
	surface.DrawRect(x + w - 2, y, 2, corner)
	surface.DrawRect(x, y + h - 2, corner, 2)
	surface.DrawRect(x, y + h - corner, 2, corner)
	surface.DrawRect(x + w - corner, y + h - 2, corner, 2)
	surface.DrawRect(x + w - 2, y + h - corner, 2, corner)

	local pad = ScreenScale(10)
	local titleY = y + pad
	local bodyY = titleY + 28
	local smallY = bodyY + 20

	draw.SimpleText("Round complete", "CZ_End_Title", x + w * 0.5, titleY, Color(255, 255, 255, math.floor(235 * panelAlpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Round result: " .. getRoundEndResultText(winner), "CZ_End_Body", x + w * 0.5, bodyY, Color(220, 220, 220, math.floor(215 * panelAlpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText("Next round in: " .. math.ceil(displayRoundLeft), "CZ_End_Small", x + w * 0.5, smallY, Color(200, 200, 200, math.floor(200 * panelAlpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	local textBottom = smallY + 18
	local logoY = textBottom + pad
	local logoAvailH = math.max((y + h - pad) - logoY, 0)
	local logoSize = math.min(logoAvailH, w * 0.55)
	logoSize = math.max(logoSize, 48)
	if logoAvailH >= logoSize then
		logoY = logoY + (logoAvailH - logoSize) * 0.5
	else
		logoY = y + h - pad - logoSize
	end

	local logo = getRoundEndLogo(winner)
	if logo then
		surface.SetMaterial(logo)
		surface.SetDrawColor(255, 255, 255, math.floor(255 * panelAlpha))
		surface.DrawTexturedRect(x + (w - logoSize) * 0.5, logoY, logoSize, logoSize)
	end
end

local function getSpectateTarget(ply)
	if not IsValid(ply) then return nil end
	local target = ply:GetObserverTarget()
	if IsValid(target) then return target end
	local nwTarget = ply:GetNWEntity("spect")
	if IsValid(nwTarget) then return nwTarget end
	return nil
end

local function DrawSpectatorInfo()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not BR.IsSpectator(ply) then return end

	local target = getSpectateTarget(ply)
	if not IsValid(target) then return end

	local role = BR.GetPlayerClass(target)
	local roleName = role and role.name or "Unknown"
	local name = BR.GetDisplayName(target)

	local x = ScrW() * 0.5
	local y = ScrH() * 0.72
	draw.SimpleText("Spectating: " .. name, "CZ_HUD_Title", x, y, Color(255, 255, 255, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Role: " .. roleName, "CZ_HUD_Small", x, y + 20, Color(200, 200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawBreachFade()
	if not breachFadeStart then return end
	local elapsed = CurTime() - breachFadeStart
	local alpha = 0

	if elapsed < breachFadeIn then
		alpha = Lerp(elapsed / breachFadeIn, 0, 230)
	elseif elapsed < breachFadeIn + breachFadeHold then
		alpha = 230
	elseif elapsed < breachFadeIn + breachFadeHold + breachFadeOut then
		local t = (elapsed - breachFadeIn - breachFadeHold) / breachFadeOut
		alpha = Lerp(t, 230, 0)
	else
		breachFadeStart = nil
		return
	end

	surface.SetDrawColor(0, 0, 0, math.floor(alpha))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end

hook.Add("HUDPaint", "CZ_BreachHUD", function()
	DrawStamina()
	DrawRoundTimer()
	DrawRoundEnd()
	DrawSpectatorInfo()
	DrawBreachFade()
end)

hook.Add("PlayerBindPress", "CZ_BreachSpectateBind", function(ply, bind, pressed)
	if not pressed or not IsValid(ply) then return end
	if ply:Alive() and not BR.IsSpectator(ply) then return end

	if bind == "+attack" or bind == "+attack2" or bind == "+jump" then
		local dir = bind == "+attack2" and -1 or 1
		net.Start("CZ_SpectateCycle")
		net.WriteInt(dir, 3)
		net.SendToServer()
		return true
	end
end)

hook.Add("Think", "CZ_BreachRoundStateWatcher", function()
	local state = GetGlobalInt("CZ_RoundState", BR.RoundStates.WAITING)
	local endTime = GetGlobalFloat("CZ_RoundStateEnd", 0)

	if state ~= prepLastState then
		if state ~= BR.RoundStates.PREP then
			stopPrepAmbience()
		end
		prepLastState = state
	end

	if shouldPlayPrepMusic() then
		startPrepAmbience()
		if AMBIENT and AMBIENT.MuteFor then
			if AMBIENT.Pause then
				AMBIENT.Pause()
			end
			local remaining = math.max(0, endTime - CurTime())
			if remaining > 0 then
				AMBIENT.MuteFor(remaining)
			end
		end
	else
		stopPrepAmbience()
	end

	if lastRoundState ~= nil and lastRoundState == BR.RoundStates.PREP and state == BR.RoundStates.ACTIVE then
		TriggerBreachIntro()
	end
	lastRoundState = state
end)

hook.Add("Think", "CZ_BreachDeathSound", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local alive = ply:Alive()
	if lastAlive == nil then
		lastAlive = alive
		return
	end

	if lastAlive and not alive then
		ply:EmitSound(deathSound, deathSoundLevel, 100, deathSoundVolume, CHAN_AUTO)
	end
	lastAlive = alive
end)
