if not CLIENT then return end
cz = cz or {}
cz.Inventory = cz.Inventory or {}

local invPanel = nil

local function OpenInventory()
    if IsValid(invPanel) then return end

    local w, h = ScrW() * 0.7, ScrH() * 0.7

    invPanel = vgui.Create("DFrame")
    invPanel:SetSize(w, h)
    invPanel:Center()
    invPanel:SetTitle("")
    invPanel:MakePopup()
    invPanel:SetDraggable(false)
    invPanel:ShowCloseButton(false)

    invPanel.Paint = function(self, w, h)
        Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 220))
        draw.RoundedBoxEx(8, 0, 0, w, 30, Color(20, 20, 20, 240), true, true, false, false)
        draw.SimpleText("Inventory", "Trebuchet24", 10, 15, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local closeBtn = vgui.Create("DButton", invPanel)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(w - 30, 0)
    closeBtn:SetText("X")
    closeBtn:SetTextColor(Color(255,255,255))
    closeBtn.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(0, 0, 0, w, h, Color(200, 50, 50))
        end
    end
    closeBtn.DoClick = function()
        invPanel:Close()
    end

    -- Left: Player Model
    local modelPanel = vgui.Create("DModelPanel", invPanel)
    modelPanel:SetSize(w * 0.3, h - 50)
    modelPanel:SetPos(20, 40)
    modelPanel:SetModel(LocalPlayer():GetModel())

    -- Function to frame the model nicely
    function modelPanel:LayoutEntity(Entity) return end

    local eyepos = modelPanel.Entity:GetBonePosition(modelPanel.Entity:LookupBone("ValveBiped.Bip01_Head1") or 0) or Vector(0,0,64)
    modelPanel:SetLookAt(eyepos - Vector(0, 0, 20))
    modelPanel:SetCamPos(eyepos - Vector(-70, 0, 20))
    modelPanel.Entity:SetEyeTarget(eyepos - Vector(-70, 0, 20))

    -- Middle: Equipment Slots
    local equipX = w * 0.3 + 30
    local equipY = 40
    local slotSize = (h - 80) / 4

    local equipTypes = {"Helmet", "Armor", "Backpack", "Accessory"}

    for i, eqp in ipairs(equipTypes) do
        local eqpSlot = vgui.Create("DPanel", invPanel)
        eqpSlot:SetSize(slotSize, slotSize)
        eqpSlot:SetPos(equipX, equipY + (i - 1) * (slotSize + 10))
        eqpSlot.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
            surface.SetDrawColor(100, 100, 100)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText(eqp, "DermaDefault", w/2, h/2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        eqpSlot:Receiver("inv_item", function(pnl, tbl, dropped, menu, x, y)
            if dropped then
                -- Handle item equip
            end
        end)
    end

    -- Right: Inventory Grid
    local gridX = equipX + slotSize + 20
    local gridW = w - gridX - 20

    local scroll = vgui.Create("DScrollPanel", invPanel)
    scroll:SetSize(gridW, h - 60)
    scroll:SetPos(gridX, 40)

    local grid = vgui.Create("DIconLayout", scroll)
    grid:Dock(FILL)
    grid:SetSpaceX(10)
    grid:SetSpaceY(10)

    local itemSlotSize = 70
    for i = 1, 24 do -- 24 slots for example
        local slot = grid:Add("DPanel")
        slot:SetSize(itemSlotSize, itemSlotSize)
        slot.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(60, 60, 60, 200))
            surface.SetDrawColor(120, 120, 120)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        slot:Receiver("inv_item", function(pnl, tbl, dropped, menu, x, y)
            if dropped then
                -- Handle item move
            end
        end)
    end
end

-- Override default Q menu logic in Sandbox if needed
hook.Add("SpawnMenuOpen", "CZ_OpenInventory", function()
    local ply = LocalPlayer()
    if IsValid(ply) and ply:Alive() then
        if not ply:IsSuperAdmin() then
            OpenInventory()
            return false
        else
            -- If superadmin, still open inventory, but maybe we shouldn't block the spawnmenu?
            -- To be safe, let's open inventory but allow default behaviour too if they want
            OpenInventory()
            return false -- If user just wants Inventory. Superadmins can use other keys or command if they need real spawnmenu, or we can just always block.
        end
    end
    return false
end)

concommand.Add("cz_inventory", function()
    OpenInventory()
end)
