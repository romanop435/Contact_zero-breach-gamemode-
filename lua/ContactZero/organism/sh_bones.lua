if SERVER then 
    local meta = FindMetaTable("Player")

    local function storeMoveDefaults(ply)
        ply.CZ_MoveDefaults = ply.CZ_MoveDefaults or {}
        ply.CZ_MoveDefaults.jumppower = ply.CZ_MoveDefaults.jumppower or ply:GetJumpPower()
        ply.CZ_MoveDefaults.walkspeed = ply.CZ_MoveDefaults.walkspeed or ply:GetWalkSpeed()
        ply.CZ_MoveDefaults.runspeed = ply.CZ_MoveDefaults.runspeed or ply:GetRunSpeed()
    end

    local function getMoveValue(ply, key, fallback)
        if istable(cfg) and cfg[key] ~= nil then
            return cfg[key]
        end

        local defaults = ply.CZ_MoveDefaults
        if defaults and defaults[key] ~= nil then
            return defaults[key]
        end

        return fallback
    end

    function meta:SetLegsBroken(time)
        time = tonumber(time)
        if not time or time <= 0 then
            self.LegsBroken = math.huge
            self:SetNWBool("CZ_LegsBroken", true)
            return
        end
        self.LegsBroken = CurTime() + time
        self:SetNWBool("CZ_LegsBroken", true)
    end

    function meta:IsLegsBroken()
        return self.LegsBroken and self.LegsBroken > CurTime()
    end

    hook.Add("EntityTakeDamage", "BreakLegsOnFallDamage", function(target, dmginfo)
        if target:IsPlayer() and dmginfo:GetDamageType() == DMG_FALL then
            if target.SetLegsBroken then
                target:SetLegsBroken(0)
                target:ChatPrint("Вы сломали ногу!")
                hook.Run("CZ_PlayerLegsBroken", target, dmginfo)
            end
        end
    end)

    hook.Add("PlayerTick", "zw_legs_system", function(ply)
        if ply:IsLegsBroken() then
            if not ply:GetNWBool("CZ_LegsBroken", false) then
                ply:SetNWBool("CZ_LegsBroken", true)
            end
            storeMoveDefaults(ply)
            umsg.Start("StartBrockenLegsEffect", ply)
            umsg.End()
            ply:SetJumpPower(0)
            ply:SetRunSpeed(100)
            ply:SetWalkSpeed(100)
        else
            if ply:GetNWBool("CZ_LegsBroken", false) then
                ply:SetNWBool("CZ_LegsBroken", false)
            end
            umsg.Start("StopBrockenLegsEffect", ply)
            umsg.End()
            ply:SetJumpPower(getMoveValue(ply, "jumppower", ply:GetJumpPower()))
            ply:SetWalkSpeed(getMoveValue(ply, "walkspeed", ply:GetWalkSpeed()))
            ply:SetRunSpeed(getMoveValue(ply, "runspeed", ply:GetRunSpeed()))
        end
    end)

    hook.Add("PlayerDeath", "StopBrokenLegsOnDeath", function(ply)
        ply:SetLegsBroken(.2)
    end)

    hook.Add("PlayerSpawn", "StopBrokenLegsOnSpawn", function(ply)
        ply:SetLegsBroken(.2)
        timer.Simple(0, function()
            if IsValid(ply) then
                ply.CZ_MoveDefaults = {
                    jumppower = ply:GetJumpPower(),
                    walkspeed = ply:GetWalkSpeed(),
                    runspeed = ply:GetRunSpeed()
                }
            end
        end)
    end)
end

if CLIENT then
    local bleedEffectActive = false
    
    usermessage.Hook("StartBrockenLegsEffect", function()
        bleedEffectActive = true
    end)
    
    usermessage.Hook("StopBrockenLegsEffect", function()
        bleedEffectActive = false
    end)

    hook.Add("RenderScreenspaceEffects", "nogieffect", function()
        if bleedEffectActive then
            DrawMotionBlur( 0.2, 1, 0 )
        end
    end)
end
