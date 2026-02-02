include("shared.lua")

local fontsReady = false
local textScale = 0.015
local textOffset = Vector(1.6, 0, 0.25)
local textAngle = Angle(0, 90, 90)
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

local function drawCard(ent)
    if not IsValid(ent) then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if lp:GetPos():DistToSqr(ent:GetPos()) > 80000 then return end

    ensureFonts()

    local area = "SITE19"
    local dept = ""
    local name = ""
    local level = tostring(ent:GetKeycardLevel() or 0)

    local pos = ent:GetRenderOrigin()
    local ang = ent:GetRenderAngles()
    if not pos or pos == vector_origin then
        pos = ent:GetPos()
    end
    if not ang then
        ang = ent:GetAngles()
    end
    if not pos or not ang then return end

    pos = pos + ang:Forward() * textOffset.x
        + ang:Right() * textOffset.y
        + ang:Up() * textOffset.z

    local textAng = Angle(ang.p, ang.y, ang.r)
    textAng:RotateAroundAxis(textAng:Right(), textAngle.p)
    textAng:RotateAroundAxis(textAng:Up(), textAngle.y)
    textAng:RotateAroundAxis(textAng:Forward(), textAngle.r)

    local function drawPanel(panelPos, panelAng)
        cam.Start3D2D(panelPos, panelAng, textScale)
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
    end

    local frontPos = pos + textAng:Forward() * faceOffset
    drawPanel(frontPos, textAng)

    local backAng = Angle(textAng.p, textAng.y, textAng.r)
    backAng:RotateAroundAxis(backAng:Up(), 180)
    local backPos = pos - textAng:Forward() * faceOffset
    drawPanel(backPos, backAng)
end

function ENT:Draw()
    self:DrawModel()
    drawCard(self)
end
