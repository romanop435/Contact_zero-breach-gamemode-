if SERVER then AddCSLuaFile() end

SWEP.PrintName = "SLAM"
SWEP.Category = "Weapons - Explosive"
SWEP.Instructions = "I love that slugcat girl with her explosive thing"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "slam"
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 4

SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.ViewModel = ""

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_slam")
    SWEP.IconOverride = "vgui/wep_jack_hmcd_slam"
    SWEP.BounceWeaponIcon = false
end

SWEP.offsetVec = Vector(2.7, -5, 0)
SWEP.offsetAng = Angle(-80, 180, 190)
local SLAMPlacementRadius = 100

function SWEP:DrawWorldModel()
    self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
    local WorldModel = self.model
    local owner = self:GetOwner()

    if not IsValid(WorldModel) then return end

    WorldModel:SetNoDraw(true)
    WorldModel:SetModelScale(self.ModelScale or 1)
    WorldModel:SetModel(self:GetModel())
    if IsValid(owner) then
        local offsetVec = self.offsetVec
        local offsetAng = self.offsetAng
        local boneid = owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end
        local matrix = owner:GetBoneMatrix(boneid)
        if not matrix then return end
        local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
        WorldModel:SetPos(newPos)
        WorldModel:SetAngles(newAng)
        WorldModel:SetupBones()
    else
        WorldModel:SetPos(self:GetPos())
        WorldModel:SetAngles(self:GetAngles())
    end

    WorldModel:DrawModel()
end

function SWEP:PlaceSLAM(pos, ang, tr)
    ang:RotateAroundAxis(ang:Right(), -90)
    ang:RotateAroundAxis(ang:Up(), 180)

    local ent = ents.Create("ent_hg_slam")
    ent:SetAngles(ang)
    ent:SetPos(pos)
    ent:Spawn()

    constraint.Weld(ent, tr.Entity, 0, tr.PhysicsBone or 0, 9999, true, true)
    self:SetPlaced(true) -- ЗАЧЕМ А?
    self:SetSLAM(ent) -- НАХЕР ЭТО НУЖНО ЕСЛИ У ТЕБЯ И ТАК ПОТОМ ОРУЖИЕ УДАЛЯЕТСЯ?
    ent.owner = self:GetOwner()

    self:Remove() -- ДЕКА ТЫ ЧЕ ЧАТДЖП ИСПОЛЬЗУЕШЬ? ЧТО ЭТО ЗА КОД БЛЯТЬ
end

function SWEP:Initialize()
    self:SetHoldType("slam")
    self.WorldModel = "models/weapons/w_slam.mdl"
end

function SWEP:Think()
    self:SetHoldType("slam")
    self:SetHolding(math.max(self:GetHolding() - 3, 0))
end

local bone, name
function SWEP:BoneSet(lookup_name, vec, ang)
    if IsValid(self:GetOwner()) and !self:GetOwner():IsPlayer() then return end
	hg.bone.Set(self:GetOwner(), lookup_name, vec, ang)
end

function SWEP:Animation()
    local hold = self:GetHolding()
	self:BoneSet("r_upperarm", vector_origin, Angle(20,-hold/2 - 20,0))
    self:BoneSet("r_forearm", vector_origin, Angle(0,hold,0))
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Placed")
    self:NetworkVar("Float", 0, "Holding")
    self:NetworkVar("Entity", 0, "SLAM")
    self:NetworkVarNotify("Placed", self.OnVarChanged)
end

function SWEP:OnVarChanged(name, old, new)
    if not new then return end
    self.WorldModel = "models/weapons/w_slam.mdl"
    self.offsetVec = Vector(1.5, -12, -1)
    self.offsetAng = Angle(180, 80, 30)
end

local function InPlacementRadius(ply, tr)
    return tr.HitPos:DistToSqr(ply:GetPos()) <= SLAMPlacementRadius * SLAMPlacementRadius
end

if CLIENT then
    local csent = ClientsideModel(SWEP.WorldModel)
    csent:SetNoDraw(true)
    
    function SWEP:DrawHUD()
        if self:GetPlaced() then return end
        if not IsValid(csent) then
            csent = ClientsideModel(self.WorldModel)
            csent:SetNoDraw(true)
        end
        local ply = self:GetOwner()
        local tr = ply:GetEyeTrace()
        

        if not tr.Hit or tr.HitSky or not tr.HitPos or not InPlacementRadius(ply, tr) then return end
		if tr.Entity and tr.Entity:IsPlayer() then return end

        local pos, ang = tr.HitPos, tr.HitNormal:Angle()
        ang:RotateAroundAxis(ang:Right(), -90)
        ang:RotateAroundAxis(ang:Up(), 180)

        cam.Start3D()
            csent:SetPos(pos)
            csent:SetAngles(ang)
            csent:SetMaterial("models/wireframe")
            csent:DrawModel()
        cam.End3D()
    end
end

function SWEP:SecondaryAttack()
    local ply = self:GetOwner()
    
    if not self:GetPlaced() then
        local tr = ply:GetEyeTrace()
        if not tr.Hit or tr.HitSky or not InPlacementRadius(ply, tr) then return end

        self:SetHolding(math.min(self:GetHolding() + 6, 100))

        if self:GetHolding() < 100 then return end
        if CLIENT then return end
        local pos, ang = tr.HitPos, tr.HitNormal:Angle()
        pos = pos + ang:Forward() * 2
        
        self:PlaceSLAM(pos, ang, tr)
    end
end

function SWEP:PrimaryAttack()
    self:SecondaryAttack()
end