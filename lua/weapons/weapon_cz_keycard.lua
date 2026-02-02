if SERVER then AddCSLuaFile() end

-- Keycard SWEP using weapon_tpik_base style (patterned after weapon_petition)

SWEP.Base = "weapon_tpik_base"

SWEP.PrintName = "Keycard"
SWEP.Category = "Contact Zero"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.CZ_IsKeycard = true

SWEP.DrawCrosshair = false

SWEP.Author = "romanop435 & kutarum"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""

SWEP.Slot = 1
SWEP.SlotPos = 0

-- TPIK base renders held model via WorldModelReal
SWEP.ViewModel = ""

-- Dropped / world model
SWEP.WorldModel = "models/kutarum/scpfp/w_keycard.mdl"

-- Held (animated) model
SWEP.WorldModelReal = "models/kutarum/scpfp/c_keycard.mdl"

SWEP.WorldModelExchange = false

SWEP.HoldType = "slam"
SWEP.WorkWithFake = true

SWEP.setlh = false
SWEP.setrh = true

SWEP.HoldPos = Vector(0, 0, -1)
SWEP.HoldAng = Angle(0, 0, 0)

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local KEYCARD_CALM = 0
local KEYCARD_USED = 1

SWEP.UseWait = 0.9

SWEP.AnimList = {
    ["deploy"] = { "draw", 1, false },
    ["idle"] = { "idle", 4, true },
    ["use"] = { "use", 1.6, false },
}

local function GetSkinForLevel(level)
    if hg and hg.Breach and hg.Breach.GetKeycardSkin then
        return hg.Breach.GetKeycardSkin(level)
    end
    local idx = math.max(0, (tonumber(level) or 1) - 1)
    return math.Clamp(idx, 0, 6)
end

local function canUse(self)
    local t = CurTime()
    if (self.NextUse or 0) > t then return false end
    self.NextUse = t + (self.UseWait or 0.9)
    return true
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "KeycardLevel")
    self:NetworkVar("Int", 1, "State")
    self:NetworkVar("String", 0, "CardArea")
    self:NetworkVar("String", 1, "CardDepartment")
    self:NetworkVar("String", 2, "CardName")
    self:NetworkVar("Bool", 0, "CardLocked")

    if SERVER then
        self:SetState(KEYCARD_CALM)
        if self:GetKeycardLevel() <= 0 then
            self:SetKeycardLevel(1)
        end
    end

    if CLIENT then
        self:NetworkVarNotify("KeycardLevel", function()
            self:InitKeycardName()
        end)
    end
end

function SWEP:InitKeycardName()
    if SERVER then return end
    self.PrintName = "Keycard - Level " .. tostring(self:GetKeycardLevel())
end

function SWEP:ApplyCardSkin()
    local skin = GetSkinForLevel(self:GetKeycardLevel())
    self.WMSkin = skin
    local wm = self.GetWM and self:GetWM() or nil
    if IsValid(wm) then
        wm:SetSkin(skin)
    end
    self:SetSkin(skin)
end

if SERVER then
    function SWEP:InitCardData(ply, roleId)
        if not IsValid(ply) then return end
        if self:GetCardLocked() then return end
        if not hg or not hg.Breach then return end

        local role = roleId and hg.Breach.GetRole and hg.Breach.GetRole(roleId) or hg.Breach.GetPlayerClass(ply)
        local faction = role and role.faction or ""

        local dept = ""
        if faction == "guard" then
            dept = "SECURITY"
        elseif faction == "sci" then
            dept = "SCIENCE"
        end

        local name = ""
        if faction ~= "classd" and faction ~= "scp" then
            name = hg.Breach.GetDisplayName(ply)
        end

        self:SetCardArea("SITE19")
        self:SetCardDepartment(dept)
        self:SetCardName(name)
        self:SetCardLocked(true)
    end
end

if CLIENT then
    local function pickSeq(wm, candidates, fallback)
        for _, name in ipairs(candidates) do
            local seq = wm:LookupSequence(name)
            if seq and seq > -1 then return name end
        end
        return fallback
    end

    function SWEP:InitAdd()
        timer.Simple(0, function()
            if not IsValid(self) then return end
            local wm = self.GetWM and self:GetWM() or nil
            if not IsValid(wm) then return end

            if self.WorldModelReal and wm:GetModel() ~= self.WorldModelReal then
                wm:SetModel(self.WorldModelReal)
            end

            self.AnimList["deploy"][1] = pickSeq(wm, {"draw","deploy","anim_draw","idle"}, self.AnimList["deploy"][1])
            self.AnimList["idle"][1] = pickSeq(wm, {"idle","anim_idle","idle_1"}, self.AnimList["idle"][1])
            self.AnimList["use"][1] = pickSeq(wm, {"use","attack","primary","anim_use","swipe"}, self.AnimList["use"][1])
        end)
    end
end

function SWEP:InitializeAdd()
    self:SetHold(self.HoldType)
end

if SERVER then
    function SWEP:Initialize()
        self:SetHold(self.HoldType)
        self:InitializeAdd()
        if self.InitAdd then self:InitAdd() end
    end
end

function SWEP:Deploy()
    self:InitKeycardName()
    self:ApplyCardSkin()
    if self.PlayAnim then
        self:PlayAnim("deploy")
    end
    return true
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

function SWEP:CanUseKeycard(ent)
    if not IsValid(ent) then return false end
    if not hg or not hg.Breach then return false end
    local required = hg.Breach.GetRequiredKeycard(ent)
    return required and required > 0
end

function SWEP:HandleKeycardAccess(ent)
    if not hg or not hg.Breach then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local required = hg.Breach.GetRequiredKeycard(ent)
    if required <= 0 then return end

    local level = self:GetKeycardLevel()
    local granted = level >= required
    if granted then
        if ent.Fire then
            ent:Fire("Unlock", "", 0)
            ent:Fire("Open", "", 0)
        end
        if ent.Input then
            ent:Input("Use", ply, ply)
        end
        ply:EmitSound("scpfp/doors/granted.wav", 65, 100, 1, CHAN_ITEM)
    else
        ply:EmitSound("scpfp/doors/denied.wav", 65, 100, 1, CHAN_ITEM)
    end
    hook.Run("CZ_KeycardAccess", ply, ent, required, level, granted)
end

function SWEP:UseKeycard(ent, force)
    print("use")
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if CLIENT then
        if not force then return end
        if not canUse(self) then return end
        if self.PlayAnim then
            self:PlayAnim("use")
        end
        return
    end

    if not self:CanUseKeycard(ent) then return end
    if not canUse(self) then return end

    if self.PlayAnim then
        self:PlayAnim("use")
    end

    self:SetState(KEYCARD_USED)

    local animTime = (self.AnimList and self.AnimList["use"] and self.AnimList["use"][2]) or 1.2
    local delay = animTime / 2.5
    local timerId = tostring(ply:SteamID64() or ply:EntIndex()) .. "_cz_keycard_use"

    timer.Create(timerId, delay, 1, function()
        if IsValid(ply) and IsValid(self) then
            self:HandleKeycardAccess(ent)
            self:SetState(KEYCARD_CALM)
        end
    end)
end

function SWEP:DrawWorldModel()
    local skin = GetSkinForLevel(self:GetKeycardLevel())
    self:SetSkin(skin)
    self.WMSkin = skin
    local wm = self.GetWM and self:GetWM() or nil
    if IsValid(wm) then
        wm:SetSkin(skin)
    end
    if self.DrawWorldModel2 then
        self:DrawWorldModel2()
        return
    end
    self:DrawModel()
end

-- === CZ Keycard: 3D2D label ===
if CLIENT then
    local fontsReady = false
    local textScale = 0.015
    local worldOffset = Vector(0, 0, 0)
    local worldAngle = Angle(0, 0, 0)
    local heldOffset = Vector(0, 0, 0)
    local heldAngle = Angle(0, 0, 0)
    local worldPad = 0.01
    local heldPad = 0.02
    local faceOffset = 0.02
    local textW, textH = 200, 120

    local function ensureFonts()
        if fontsReady then return end
        surface.CreateFont("CZ_Keycard3D_Label", {
            font = "Bahnschrift",
            size = 16,
            weight = 700
        })
        surface.CreateFont("CZ_Keycard3D_Value", {
            font = "Bahnschrift",
            size = 18,
            weight = 800
        })
        fontsReady = true
    end

    local function getCardText(wep)
        local area = wep.GetCardArea and wep:GetCardArea() or "SITE19"
        if area == "" then area = "SITE19" end
        local dept = wep.GetCardDepartment and wep:GetCardDepartment() or ""
        local name = wep.GetCardName and wep:GetCardName() or ""
        local level = tostring(wep:GetKeycardLevel() or 0)
        return area, dept, name, level
    end

    local function drawPanel(pos, ang, scale, area, dept, name, level, ignoreZ)
        if ignoreZ then
            cam.IgnoreZ(true)
        end
        cam.Start3D2D(pos, ang, scale)
            surface.SetDrawColor(235, 232, 224, 210)
            surface.DrawRect(0, 0, textW, textH)
            surface.SetDrawColor(0, 0, 0, 30)
            surface.DrawOutlinedRect(0, 0, textW, textH)

            draw.SimpleText("AREA", "CZ_Keycard3D_Label", 8, 6, Color(20, 20, 20, 220))
            draw.SimpleText(area, "CZ_Keycard3D_Value", 8, 22, Color(10, 10, 10, 230))

            draw.SimpleText("DEPARTMENT", "CZ_Keycard3D_Label", 8, 46, Color(20, 20, 20, 220))
            draw.SimpleText(dept, "CZ_Keycard3D_Value", 8, 62, Color(10, 10, 10, 230))

            draw.SimpleText("LVL", "CZ_Keycard3D_Label", 8, 86, Color(20, 20, 20, 220))
            draw.SimpleText(level, "CZ_Keycard3D_Value", 44, 82, Color(10, 10, 10, 230))

            draw.SimpleText("NAME", "CZ_Keycard3D_Label", textW - 8, 86, Color(20, 20, 20, 220), TEXT_ALIGN_RIGHT)
            draw.SimpleText(name, "CZ_Keycard3D_Value", textW - 8, 102, Color(10, 10, 10, 230), TEXT_ALIGN_RIGHT)
        cam.End3D2D()
        if ignoreZ then
            cam.IgnoreZ(false)
        end
    end

    local function getRenderPosAng(ent)
        if not IsValid(ent) then return nil end
        local pos = ent:GetRenderOrigin()
        local ang = ent:GetRenderAngles()
        if not pos or pos == vector_origin then
            pos = ent:GetPos()
        end
        if not ang then
            ang = ent:GetAngles()
        end
        if not pos or not ang then return nil end
        return pos, ang
    end

    local function axisRotation(textAng, axisKey)
        if axisKey == "y" then
            textAng:RotateAroundAxis(textAng:Up(), 90)
        elseif axisKey == "z" then
            textAng:RotateAroundAxis(textAng:Right(), -90)
        end
    end

    local function getAxisDir(ang)
        return {
            x = ang:Forward(),
            y = ang:Right(),
            z = ang:Up()
        }
    end

    local function axisVec(axisKey)
        if axisKey == "x" then
            return Vector(1, 0, 0)
        elseif axisKey == "y" then
            return Vector(0, 1, 0)
        end
        return Vector(0, 0, 1)
    end

    local function buildPosAng(ent, extraOffset, extraRot, pad)
        if not IsValid(ent) then return nil end
        local pos, ang = getRenderPosAng(ent)
        if not pos or not ang then return nil end

        local mins, maxs = ent:GetModelBounds()
        if not mins or not maxs then
            pos = pos + ang:Forward() * extraOffset.x
                + ang:Right() * extraOffset.y
                + ang:Up() * extraOffset.z

            local textAng = Angle(ang.p, ang.y, ang.r)
            textAng:RotateAroundAxis(textAng:Right(), extraRot.p)
            textAng:RotateAroundAxis(textAng:Up(), extraRot.y)
            textAng:RotateAroundAxis(textAng:Forward(), extraRot.r)
            return pos, textAng
        end

        local size = maxs - mins
        local axes = {
            { key = "x", size = math.abs(size.x) },
            { key = "y", size = math.abs(size.y) },
            { key = "z", size = math.abs(size.z) }
        }

        table.sort(axes, function(a, b) return a.size < b.size end)
        local thicknessAxis = axes[1].key
        local heightAxis = axes[3].key
        local center = (mins + maxs) * 0.5
        local thickness = (thicknessAxis == "x" and size.x)
            or (thicknessAxis == "y" and size.y)
            or size.z

        local normalLocal = axisVec(thicknessAxis)
        local baseOffset = center + normalLocal * ((thickness * 0.5) + pad)
        local offset = baseOffset + extraOffset

        pos = pos + ang:Forward() * offset.x
            + ang:Right() * offset.y
            + ang:Up() * offset.z

        local textAng = Angle(ang.p, ang.y, ang.r)
        axisRotation(textAng, thicknessAxis)

        local axisDir = getAxisDir(textAng)
        local desiredUp = getAxisDir(ang)[heightAxis]
        local curUp = axisDir.z
        local dot = math.Clamp(curUp:Dot(desiredUp), -1, 1)
        local rot = math.deg(math.acos(dot))
        if rot > 0.01 then
            local cross = curUp:Cross(desiredUp)
            if cross:Dot(textAng:Forward()) < 0 then
                rot = -rot
            end
            textAng:RotateAroundAxis(textAng:Forward(), rot)
        end

        textAng:RotateAroundAxis(textAng:Right(), extraRot.p)
        textAng:RotateAroundAxis(textAng:Up(), extraRot.y)
        textAng:RotateAroundAxis(textAng:Forward(), extraRot.r)

        return pos, textAng
    end

    function SWEP:DrawCard3D2D(ent, isHeld)
        if not IsValid(ent) then return end
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        if not isHeld then
            local renderPos = ent.GetRenderOrigin and ent:GetRenderOrigin() or ent:GetPos()
            if not renderPos or renderPos == vector_origin then
                renderPos = ent:GetPos()
            end
            if not renderPos or lp:GetPos():DistToSqr(renderPos) > 80000 then return end
        end

        ensureFonts()
        local area, dept, name, level = getCardText(self)

        local pos
        local ang
        if isHeld then
            pos, ang = buildPosAng(ent, heldOffset, heldAngle, heldPad)
        else
            pos, ang = buildPosAng(ent, worldOffset, worldAngle, worldPad)
        end
        if not pos or not ang then return end

        local ignoreZ = isHeld
        local frontPos = pos + ang:Forward() * faceOffset
        drawPanel(frontPos, ang, textScale, area, dept, name, level, ignoreZ)

        local backAng = Angle(ang.p, ang.y, ang.r)
        backAng:RotateAroundAxis(backAng:Up(), 180)
        local backPos = pos - ang:Forward() * faceOffset
        drawPanel(backPos, backAng, textScale, area, dept, name, level, ignoreZ)
    end

    function SWEP:DrawPostWorldModel()
        local wm = self.GetWM and self:GetWM() or nil
        if IsValid(wm) then
            local owner = self:GetOwner()
            local isHeld = IsValid(owner) and owner:GetActiveWeapon() == self
            self:DrawCard3D2D(wm, isHeld)
        end
    end
end
if CLIENT then
    net.Receive("CZ_KeycardAnim", function()
        local ent = net.ReadEntity()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.CZ_IsKeycard and wep.UseKeycard then
            wep:UseKeycard(ent, true)
        end
    end)
end
