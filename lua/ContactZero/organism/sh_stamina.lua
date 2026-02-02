local PLAYER = FindMetaTable("Player")
function PLAYER:BlockStamina()
    if SERVER then
        self:SetNWBool("StaminaBlocked", true)
    end
end

function PLAYER:UnblockStamina()
    if SERVER then
        self:SetNWBool("StaminaBlocked", false)
    end
end

MAX_STAMINA = 100
STAMINA_REGEN_RATE = 15
JUMP_STAMINA_COST = 17
SPRINT_STAMINA_DRAIN = 6

local function getJumpPower(ply)
    if istable(cfg) and cfg.jumppower ~= nil then
        return cfg.jumppower
    end
    local defaults = ply and ply.CZ_MoveDefaults or nil
    if defaults and defaults.jumppower ~= nil then
        return defaults.jumppower
    end
    return IsValid(ply) and ply:GetJumpPower() or 200
end

local breathSounds = {}

if SERVER then
    util.AddNetworkString("UpdateStamina")
    util.AddNetworkString("PlayBreathSound")
    util.AddNetworkString("StopBreathSound")
    util.AddNetworkString("SendBreathSound")



    function PLAYER:TakeStamina(amount)
        if self:GetNWBool("StaminaBlocked", false) then return false end
        
        local currentStamina = self:GetNWInt("Stamina")
        local newStamina = math.max(0, currentStamina - amount)
        
        self:SetNWInt("Stamina", newStamina)
        
        net.Start("UpdateStamina")
        net.WriteFloat(newStamina)
        net.Send(self)
        
        if newStamina <= 0 and currentStamina > 0 then
            self:SetNWBool("IsStaminaRegenFromZero", true)
            breathSounds[self:EntIndex()] = nil
            net.Start("StopBreathSound")
            net.Send(self)
            
            self:SetNWBool("IsSprinting", false)
            self:ConCommand("-speed")
        elseif newStamina > 0 then
            if newStamina <= 0 then
                self:SetNWBool("IsStaminaRegenFromZero", true)
                self:SetNWBool("IsSprinting", false)
                self:ConCommand("-speed")
            end
        end
        
        return true
    end



    local function GetBreathSound(ply)
        local model = ply:GetModel():lower()
        if string.find(model, "female") then
            return "dontscream/otdishka/ustal_f.wav"
        else
            return "dontscream/otdishka/ustal_m.wav"
        end
    end

    local function RegenerateStamina(ply)
        if IsValid(ply) and ply:Alive() then
            if ply:GetNWBool("StaminaBlocked", false) then return end
            local currentStamina = ply:GetNWInt("Stamina")
            local isStaminaRegenFromZero = ply:GetNWBool("IsStaminaRegenFromZero", false)
            
            if currentStamina < MAX_STAMINA and not ply:IsSprinting() and not ply:KeyDown(IN_SPEED) then
                local newStamina = math.min(MAX_STAMINA, currentStamina + STAMINA_REGEN_RATE * FrameTime())
                ply:SetNWInt("Stamina", newStamina)
                net.Start("UpdateStamina")
                net.WriteFloat(newStamina)
                net.Send(ply)

                if isStaminaRegenFromZero and not breathSounds[ply:EntIndex()] then
                    breathSounds[ply:EntIndex()] = true
                    local soundPath = GetBreathSound(ply)
                    net.Start("SendBreathSound")
                    net.WriteString(soundPath)
                    net.Send(ply)
                end

                if isStaminaRegenFromZero and newStamina >= MAX_STAMINA then
                    ply:SetNWBool("IsStaminaRegenFromZero", false)
                    breathSounds[ply:EntIndex()] = nil
                    net.Start("StopBreathSound")
                    net.Send(ply)
                end
            elseif currentStamina >= MAX_STAMINA and isStaminaRegenFromZero then
                ply:SetNWBool("IsStaminaRegenFromZero", false)
                breathSounds[ply:EntIndex()] = nil
                net.Start("StopBreathSound")
                net.Send(ply)
            end
        end
    end

    hook.Add("Think", "StaminaThink", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then
                if ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetNWBool("StaminaBlocked", false) then 
                    RegenerateStamina(ply)
                else
                    local isStaminaRegenFromZero = ply:GetNWBool("IsStaminaRegenFromZero", false)
                    
                    if ply:KeyPressed(IN_JUMP) then
                        local currentStamina = ply:GetNWInt("Stamina")
                        if currentStamina <= JUMP_STAMINA_COST or isStaminaRegenFromZero then
                            ply:SetNWInt("Stamina", 0)
                            ply:SetNWBool("IsSprinting", false)
                            ply:ConCommand("-speed")
                            ply:SetJumpPower(0)
                            timer.Simple(0.1, function()
                                if IsValid(ply) then
                                    ply:SetJumpPower(getJumpPower(ply))
                                end
                            end)
                        else
                            ply:SetNWInt("Stamina", currentStamina - JUMP_STAMINA_COST)
                            ply:SetJumpPower(getJumpPower(ply))
                        end
                    end

                    if ply:KeyDown(IN_SPEED) then
                        local vel = ply:GetVelocity()
                        local moveSpeed = math.sqrt(vel.x^2 + vel.y^2)
                        
                        local currentStamina = ply:GetNWInt("Stamina")
                        if isStaminaRegenFromZero then
                            ply:SetNWBool("IsSprinting", false)
                            ply:ConCommand("-speed")
                        elseif currentStamina > 0 and moveSpeed > 10 then
                            local newStamina = math.max(0, currentStamina - SPRINT_STAMINA_DRAIN * FrameTime())
                            ply:SetNWInt("Stamina", newStamina)
                            ply:SetNWBool("IsSprinting", true)
                            net.Start("UpdateStamina")
                            net.WriteFloat(newStamina)
                            net.Send(ply)
                            if newStamina <= 0 then
                                ply:ConCommand("-speed")
                            end
                        else
                            ply:SetNWBool("IsSprinting", false)
                            if moveSpeed <= 10 then
                                RegenerateStamina(ply)
                            end
                        end
                    else
                        ply:SetNWBool("IsSprinting", false)

                        local currentStamina = ply:GetNWInt("Stamina")
                        if currentStamina == 0 and not ply:GetNWBool("IsStaminaRegenFromZero", false) then
                            ply:SetNWBool("IsStaminaRegenFromZero", true)
                            breathSounds[ply:EntIndex()] = nil
                        end
                        
                        RegenerateStamina(ply)
                    end
                end
            end
        end
    end)

    hook.Add("StartCommand", "BlockCommandsDuringRegen", function(ply, cmd)
        if IsValid(ply) and ply:Alive() then
            if ply:GetMoveType() == MOVETYPE_NOCLIP or ply:GetNWBool("StaminaBlocked", false) then return end
            if not ply:GetMoveType() == MOVETYPE_WALK then return end
            if ply:GetNWBool("IsStaminaRegenFromZero", false) then
                cmd:RemoveKey(IN_SPEED)
                cmd:RemoveKey(IN_JUMP)
            end
        end
    end)

    net.Receive("PlayBreathSound", function(len, ply)
    end)
end

if CLIENT then
    local stamina = MAX_STAMINA
    local lastStamina = MAX_STAMINA
    local displayStamina = MAX_STAMINA
    local lerpSpeed = 5
    local breathSound = nil
    local currentBreathSoundPath = ""

    net.Receive("UpdateStamina", function()
        stamina = net.ReadFloat()
    end)

    net.Receive("SendBreathSound", function()
        local soundPath = net.ReadString()
        if soundPath ~= currentBreathSoundPath then
            currentBreathSoundPath = soundPath
        end

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        if not breathSound or not breathSound:IsPlaying() then
            ply:EmitSound(soundPath, 75, 100, 0.5)
        end
    end)

    net.Receive("StopBreathSound", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if currentBreathSoundPath ~= "" then
            ply:StopSound(currentBreathSoundPath)
        end
    end)
end
