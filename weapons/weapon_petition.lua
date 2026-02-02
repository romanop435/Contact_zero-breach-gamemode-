if SERVER then AddCSLuaFile() end

-- Petition (Postal 2) converted to weapon_tpik_base style
-- Original SWEP logic from shared.lua (Postal 2 petition) and patterned after weapon_painkillers_tpik
-- Base: weapon_tpik_base

SWEP.Base = "weapon_tpik_base"

SWEP.PrintName = "Petition"
SWEP.Category  = "Postal 2"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.DrawCrosshair = true

SWEP.Author       = ""
SWEP.Contact      = ""
SWEP.Purpose      = ""
SWEP.Instructions = ""

SWEP.Slot    = 1
SWEP.SlotPos = 0

-- weapon_tpik_base renders a "held" model via WorldModelReal in front of the player (TPIK style)
SWEP.ViewModel = ""

-- Dropped / world model
SWEP.WorldModel = "models/postal/clipboard.mdl"

-- Held (animated) model. Using your original ViewModel model here.
-- IMPORTANT: this must exist on client, and it must contain the sequences you want to play.
SWEP.WorldModelReal = "models/postal/c_petition.mdl"

SWEP.WorldModelExchange = false

SWEP.HoldType = "slam"
SWEP.WorkWithFake = true

-- Hand IK flags (like painkillers example)
SWEP.setlh = true
SWEP.setrh = true

-- TPIK placement in front of camera (tune these if needed)
SWEP.HoldPos = Vector(-5, 0, -1)
SWEP.HoldAng = Angle(0, 0, 0)

-- Cooldowns
SWEP.Primary.Wait = 0.85
SWEP.Primary.Next = 0

SWEP.Secondary.Wait = 1.05
SWEP.Secondary.Next = 0

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- Sounds from your original SWEP
local PetitionSounds = {
    "petition/petition_1.wav",
    "petition/petition_2.wav",
    "petition/petition_3.wav",
    "petition/petition_4.wav",
    "petition/petition_5.wav",
    "petition/petition_6.wav",
}

local PetitionSignSound = "petition/petition_sign.wav"

-- Optional: deploy/holster/fall sounds (safe defaults)
SWEP.DeploySnd = PetitionSounds[1]
SWEP.FallSnd   = PetitionSounds[1]

-- Animation mapping.
-- weapon_tpik_base expects AnimList entries with:
-- ["key"] = { "sequence_name", time, cycling, callback, reverse, callbackTimeAdjust }
--
-- We do NOT know your model sequence names here, so:
-- 1) Provide sane defaults.
-- 2) On client, try to auto-pick the first existing sequence from a list of candidates.
SWEP.AnimList = {
    ["deploy"] = { "draw", 1, false },
    ["idle"]   = { "idle", 4, true },
    ["attack"] = { "attack", 2.2, false },
    ["attack2"]= { "attack2", 2.2, false },
}

-- Auto-pick sequences if model uses different names (client-side only)
if CLIENT then
    local function pickSeq(wm, candidates, fallback)
        for _, name in ipairs(candidates) do
            local seq = wm:LookupSequence(name)
            if seq and seq > -1 then return name end
        end
        return fallback
    end

    function SWEP:InitAdd()
        -- Delay to ensure clientside worldmodel exists
        timer.Simple(0, function()
            if not IsValid(self) then return end
            local wm = self:GetWM()
            if not IsValid(wm) then return end

            -- Try held model for sequence lookup
            if self.WorldModelReal and wm:GetModel() ~= self.WorldModelReal then
                wm:SetModel(self.WorldModelReal)
            end

            self.AnimList["deploy"][1]  = pickSeq(wm, {"draw","deploy","anim_draw","anim_draw_1","idle"}, self.AnimList["deploy"][1])
            self.AnimList["idle"][1]    = pickSeq(wm, {"idle","anim_idle","idle_1"}, self.AnimList["idle"][1])
            self.AnimList["attack"][1]  = pickSeq(wm, {"primary","attack","anim_attack","hit","pills"}, self.AnimList["attack"][1])
            self.AnimList["attack2"][1] = pickSeq(wm, {"secondary","attack2","anim_attack2","sign","use"}, self.AnimList["attack2"][1])
        end)
    end
end

-- If you want to tweak hold type dynamically, do it here (pattern from painkillers)
function SWEP:InitializeAdd()
    self:SetHold(self.HoldType)
end

if SERVER then
    function SWEP:Initialize()
        self:SetHold(self.HoldType)
        self:InitializeAdd()
        if self.InitAdd then self:InitAdd() end
    end
else
    -- weapon_tpik_base already defines Initialize(), but having this keeps parity across realms.
    -- It will still call weapon_tpik_base:Initialize() first via Base.
end

-- Helpers
local function canUse(self, isSecondary)
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    if owner.IsSprinting and owner:IsSprinting() then
        -- Optional: block using while sprinting (many ZCity items do)
        -- return false
    end

    local t = CurTime()
    if isSecondary then
        if (self.Secondary.Next or 0) > t then return false end
        self.Secondary.Next = t + (self.Secondary.Wait or 1)
    else
        if (self.Primary.Next or 0) > t then return false end
        self.Primary.Next = t + (self.Primary.Wait or 1)
    end

    return true
end

-- Primary: play random petition line
function SWEP:PrimaryAttack()
    if not IsFirstTimePredicted() then return end
    if not canUse(self, false) then return end

    self:PlayAnim("attack")

    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound(table.Random(PetitionSounds), 70, math.random(95, 105), 1, CHAN_WEAPON)
end

-- Secondary: "sign" sound
function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    if not canUse(self, true) then return end

    self:PlayAnim("attack2")

    local owner = self:GetOwner()
    if IsValid(owner) then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound(PetitionSignSound, 70, math.random(95, 105), 1, CHAN_WEAPON)
end

-- Optional: no reload behavior for item-like SWEP
function SWEP:Reload()
end
