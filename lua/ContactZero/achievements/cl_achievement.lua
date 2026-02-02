hg = hg or {}
hg.achievements = hg.achievements or {}

local ACH = hg.achievements
ACH.achievements_data = ACH.achievements_data or {}
ACH.achievements_data.player_achievements = ACH.achievements_data.player_achievements or {}
ACH.achievements_data.created_achevements = ACH.achievements_data.created_achevements or {}

ACH.MenuPanel = ACH.MenuPanel or nil

concommand.Add("hg_achievements", function()
    if ACH.OpenMenu then
        ACH.OpenMenu()
    end
end)

local function getLocalSteamId()
    local lp = LocalPlayer()
    if not IsValid(lp) then return nil end
    return lp:SteamID64()
end

local function createButton(frame, ach)
    local button = vgui.Create("DButton", frame)

    ach.img = isstring(ach.img) and Material(ach.img) or ach.img

    local localach = ACH.GetLocalAchievements()
    local desc = markup.Parse("<font=ZCity_Small>" .. (ach.description or "") .. "</font>", 500)

    function button:Paint(w, h)
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0, self:IsHovered() and 1 or 0)

        local val = (localach and localach[ach.key] and localach[ach.key].value) or ach.start_value or 0
        local needed = ach.needed_value or 1
        local pct = math.Clamp(val / math.max(needed, 1), 0, 1)

        local pad = ScreenScale(1)
        surface.SetDrawColor(35, 35, 45, 230)
        surface.DrawRect(pad, pad, w - pad * 2, h - pad * 2)

        surface.SetDrawColor(180, 30, 30, 200)
        surface.DrawRect(pad, pad, (w - pad * 2) * pct, h - pad * 2)

        surface.SetDrawColor(0, 0, 0, pct >= 1 and 255 or 0)
        surface.SetMaterial(ach.img)
        surface.DrawTexturedRect(pad * 2, pad * 2, h - pad * 4, h - pad * 4)

        surface.SetFont("ZCity_Medium")
        local txt = ach.name .. (ach.showpercent and (" " .. math.floor(pct * 100) .. "%") or "")
        local wt, ht = surface.GetTextSize(txt)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(w / 2 - (wt / 2), (h * 0.22) - (ht / 2))
        surface.DrawText(txt)

        desc:Draw(w / 2, (h * 0.65), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(120, 25, 25, 255)
        surface.DrawOutlinedRect(0, 0, w, h, pad)
    end

    button:SetText("")
    button:SetSize(0, ScreenScale(22))
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ScreenScale(2.5))
    button.DoClick = function() end
    return button
end

function ACH.OpenMenu()
    ACH.LoadAchievements()

    if IsValid(ACH.MenuPanel) then
        ACH.MenuPanel:Remove()
        ACH.MenuPanel = nil
    end

    local frame = vgui.Create("DFrame")
    ACH.MenuPanel = frame
    frame:SetTitle("")
    frame:SetSize(ScrW() * 0.36, ScrH() * 0.6)
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetAlpha(0)

    frame:AlphaTo(255, 0.2, 0, nil)

    function frame:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(12, 12, 18, 230))
        if hg and hg.DrawBlur then
            hg.DrawBlur(self, 5)
        end
        surface.SetDrawColor(180, 30, 30, 180)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("ACHIEVEMENTS", "ZCity_Big", 16, 8, Color(255, 255, 255), TEXT_ALIGN_LEFT)
        draw.SimpleText("REALISM PROTOCOL", "ZCity_Tiny", 18, 36, Color(180, 180, 180), TEXT_ALIGN_LEFT)
    end

    function frame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE then
            self:Close()
        end
    end

    function frame:Close()
        self:AlphaTo(0, 0.1, 0, function()
            if IsValid(self) then self:Remove() end
        end)
        self:SetKeyboardInputEnabled(false)
        self:SetMouseInputEnabled(false)
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetSize(30, 22)
    close:SetPos(frame:GetWide() - 42, 12)
    close.Paint = function(self, w, h)
        local hover = self:IsHovered()
        draw.RoundedBox(4, 0, 0, w, h, hover and Color(200, 60, 60, 220) or Color(20, 20, 28, 220))
        surface.SetDrawColor(255, 255, 255, 40)
        surface.DrawOutlinedRect(0, 0, w, h)
        draw.SimpleText("X", "ZCity_Small", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close.DoClick = function()
        if IsValid(frame) then
            frame:Close()
        end
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(12, 50, 12, 12)

    local sbar = scroll:GetVBar()
    sbar:SetHideButtons(true)
    function sbar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
    end
    function sbar.btnGrip:Paint(w, h)
        self.lerpcolor = Lerp(FrameTime() * 10, self.lerpcolor or 0.2, (self:IsHovered() and 1 or 0.2))
        draw.RoundedBox(0, 0, 0, w, h, Color(120 * self.lerpcolor, 25, 25))
    end

    function frame:UpdateValues()
        scroll:Clear()
        for _, ach in pairs(ACH.achievements_data.created_achevements) do
            scroll:AddItem(createButton(scroll, ach))
        end
    end

    frame:UpdateValues()
end

function ACH.LoadAchievements()
    if (ACH._loadCooldown or 0) > CurTime() then return end
    ACH._loadCooldown = CurTime() + 2
    net.Start("req_ach")
    net.SendToServer()
end

function ACH.GetLocalAchievements()
    local steamID = getLocalSteamId()
    if not steamID then return {} end
    return ACH.achievements_data.player_achievements[steamID] or {}
end

net.Receive("req_ach", function()
    ACH.achievements_data.created_achevements = net.ReadTable() or {}
    local steamID = getLocalSteamId()
    if steamID then
        ACH.achievements_data.player_achievements[steamID] = net.ReadTable() or {}
    else
        net.ReadTable()
    end

    if IsValid(ACH.MenuPanel) then
        ACH.MenuPanel:UpdateValues()
    end
end)

ACH.NewAchievements = ACH.NewAchievements or {}
local AchTable = ACH.NewAchievements

net.Receive("hg_NewAchievement", function()
    local Ach = {time = CurTime() + 6.5, name = net.ReadString(), img = net.ReadString()}
    table.insert(AchTable, 1, Ach)
    surface.PlaySound("garrysmod/achievement_earned.wav")
end)

hook.Add("HUDPaint", "CZ_NewAchievement", function()
    local frametime = FrameTime() * 10
    for i = 1, #AchTable do
        local ach = AchTable[i]
        if not ach then continue end
        local txt = "Achievement: " .. ach.name
        ach.img = isstring(ach.img) and Material(ach.img) or ach.img

        ach.Lerp = Lerp(frametime, ach.Lerp or 0, math.min(ach.time - CurTime(), 1) * i)
        local wSize, hSize = ScrW() * 0.22, ScrH() * 0.06
        local hPos = ScrH() - (hSize * ach.Lerp)

        draw.RoundedBox(0, 12, hPos, wSize, hSize, Color(200, 25, 25, 230))
        draw.RoundedBox(0, 14, hPos + 2, wSize - 4, hSize - 4, Color(80, 20, 20, 230))

        surface.SetFont("ZCity_Small")
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(hSize * 1.1, hPos + (hSize * 0.3))
        surface.DrawText(txt)

        surface.SetDrawColor(0, 0, 0, 200)
        surface.SetMaterial(ach.img)
        surface.DrawTexturedRect(14, hPos + 2, hSize - 4, hSize - 4)

        if ach.time < CurTime() then
            table.remove(AchTable, i)
        end
    end
end)
