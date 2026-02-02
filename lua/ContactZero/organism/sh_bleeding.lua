local bleedData = {}
local playerBlood = {}

function GetPlayerBlood(ply)
    if SERVER then
        local steamID = ply:SteamID()
        if not playerBlood[steamID] then
            playerBlood[steamID] = 5000
        end
        return playerBlood[steamID]
    else
        if LocalPlayer() == ply then
            return LocalPlayer().BloodLevel or 5000
        else
            return 5000
        end
    end
end

if SERVER then
    util.AddNetworkString('UpdateBlood')
    function SetPlayerBlood(ply, amount)
        local steamID = ply:SteamID()
        playerBlood[steamID] = math.max(0, math.min(5000, amount))
        net.Start("UpdateBlood")
        net.WriteFloat(playerBlood[steamID])
        net.Send(ply)
    end

    function ChangePlayerBlood(ply, changeAmount)
        local currentBlood = GetPlayerBlood(ply)
        SetPlayerBlood(ply, currentBlood + changeAmount)
    end

    function CheckPlayerBloodState(ply)
        local blood = GetPlayerBlood(ply)
        if blood <= 3000 and blood > 2000 then
            if hg and hg.Fake then
                hg.Fake(ply)
            end
        elseif blood <= 2000 then
            ply:Kill()
        end

        if blood <= 2500 then
            ply:SetNWBool("Unconscious", true)
        else
            ply:SetNWBool("Unconscious", false)
        end
    end

    function StartBleeding(ply)
        if not IsValid(ply) or not ply:Alive() then return end

        local steamID = ply:SteamID()

        if bleedData[steamID] then return end

        bleedData[steamID] = {
            active = true,
            damageTimer = 0
        }
        ply:SetNWBool("CZ_Bleeding", true)
        hook.Run("CZ_PlayerBleedStart", ply)

        timer.Create("Bleeding10hp_" .. steamID, 1, 0, function()
            local blood = GetPlayerBlood(ply)
            if blood <= 3000 and blood > 2000 then
                ply:SetHealth(10)
            end
        end)

        timer.Create("Bleeding_" .. steamID, 0.3, 0, function()
            if IsValid(ply) and ply:Alive() then
                local trace = {}
                trace.start = ply:GetPos() + Vector(0, 0, 50)
                trace.endpos = trace.start + Vector(
                    math.Rand(-0.35, 0.35),
                    math.Rand(-0.35, 0.35),
                    -1
                ) * 8000
                trace.filter = ply

                local traceResult = util.TraceHull(trace)
                local pos1 = traceResult.HitPos + traceResult.HitNormal
                local pos2 = traceResult.HitPos - traceResult.HitNormal

                local startPos = ply:GetPos()
                local endPos = startPos + Vector(0, 0, -10)
                util.Decal("Blood", startPos, endPos, ply)

                ply:EmitSound("ambient/water/drip" .. math.random(1, 4) .. ".wav", 60, math.random(230, 240), 0.2, CHAN_AUTO)

                bleedData[steamID].damageTimer = bleedData[steamID].damageTimer + 0.1

                if bleedData[steamID].damageTimer >= .2 then
                    ChangePlayerBlood(ply, -50)
                    bleedData[steamID].damageTimer = 0
                end

                CheckPlayerBloodState(ply)

                umsg.Start("StartBleedEffect", ply)
                umsg.End()
            else
                StopBleeding(ply)
            end
        end)

        ply:ChatPrint("Вы истекаете кровью!")
    end

    function StopBleeding(ply)
        if not IsValid(ply) then return end
        local steamID = ply:SteamID()

        if bleedData[steamID] then
            bleedData[steamID] = nil
            umsg.Start("StopBleedEffect", ply)
            umsg.End()

            ply:ChatPrint("Bleeding stopped.")
        end

        timer.Remove("Bleeding_" .. steamID)
        timer.Remove("Bleeding10hp_" .. steamID)
        ply:SetNWBool("CZ_Bleeding", false)
    end
    hook.Add("PlayerInitialSpawn", "InitializePlayerBlood", function(ply)
        SetPlayerBlood(ply, 5000)
        StopBleeding(ply)
        ply:SetNWBool("CZ_Bleeding", false)
    end)

    hook.Add("PlayerSpawn", "ResetPlayerBloodOnSpawn", function(ply)
        SetPlayerBlood(ply, 5000)
        StopBleeding(ply)
        ply:SetNWBool("CZ_Bleeding", false)
    end)

    local function getPlayerClassSafe(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return nil end
        if ply.GetPlayerClass then
            return ply:GetPlayerClass()
        end
        if ply.GetPlayerClassId then
            return ply:GetPlayerClassId()
        end
        if hg and hg.Breach then
            if hg.Breach.GetPlayerClassId then
                return hg.Breach.GetPlayerClassId(ply)
            end
            if hg.Breach.GetPlayerClass then
                local role = hg.Breach.GetPlayerClass(ply)
                return role and role.id or nil
            end
        end
        return nil
    end

    hook.Add("EntityTakeDamage", "AutoBleedingOnDamage", function(target, dmginfo)
        if target:IsPlayer() and target:Alive() then
            if dmginfo:GetAttacker() ~= target then
                local damageType = dmginfo:GetDamageType()
                local attacker = dmginfo:GetAttacker()
                if (damageType == DMG_FALL or damageType == DMG_CLUB) then return end
                local targetClass = getPlayerClassSafe(target)
                if TEAM_REBELJAG and targetClass == TEAM_REBELJAG then return end
                if IsValid(attacker) and attacker:IsPlayer() and zw and zw.IsRebel then
                    local attackerClass = getPlayerClassSafe(attacker)
                    if targetClass and attackerClass and zw.IsRebel(targetClass) == zw.IsRebel(attackerClass) then return end
                end
                
                StartBleeding(target)
            end
        end
    end)

    hook.Add("PlayerDeath", "StopBleedingOnDeath", function(ply)
        timer.Simple(0.2, function()
            StopBleeding(ply)
        end)
    end)

    concommand.Add("check_blood", function(ply, cmd, args)
        if IsValid(ply) and ply:IsPlayer() then
            local blood = GetPlayerBlood(ply)
            local bloodLiters = blood / 1000

            ply:ChatPrint("Уровень крови: " .. string.format("%.2f", bloodLiters) .. " литров (" .. blood .. " мл)")
        end
    end)

end

if CLIENT then
    local bleedEffectActive = false
    local unconscious = false

    net.Receive("UpdateBlood", function()
        local blood = net.ReadFloat()
        LocalPlayer().BloodLevel = blood

        if blood <= 3000 and blood > 2000 then
            unconscious = true
        else
            unconscious = false
        end
    end)

    usermessage.Hook("StartBleedEffect", function()
        bleedEffectActive = true
    end)

    usermessage.Hook("StopBleedEffect", function()
        bleedEffectActive = false
    end)

    hook.Add("RenderScreenspaceEffects", "bleedeffect", function()
        local bloodget = GetPlayerBlood(LocalPlayer())
        local sharpen = 1

        if bloodget <= 4000 then
            sharpen = 1.5
        elseif bloodget <= 3500 then
            sharpen = 2
        end

        if bleedEffectActive then
            DrawSharpen(sharpen, 1)
            if bloodget <= 3500 then
                DrawMotionBlur( 0.2, 1, 0 )
            end
        end

        if unconscious then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end
    end)
end
