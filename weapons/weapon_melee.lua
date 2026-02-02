if SERVER then AddCSLuaFile() end
SWEP.PrintName = "Combat Knife"
SWEP.Instructions = "A military grade combat knife designed to neutralize the enemy during combat operations and special operations."
SWEP.Category = "Weapons - Melee"
SWEP.Instructions = "This is your trusty carbon-steel fixed-blade knife. LMB to stab. RMB to slash."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 1

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.WorldModel = "models/weapons/combatknife/tactical_knife_iw7_wm.mdl"
SWEP.WorldModelReal = "models/weapons/combatknife/tactical_knife_iw7_vm.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""
SWEP.HoldType = "knife"

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:IsSprinting()
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    if not owner.IsSprinting then return false end
    if owner:IsSprinting() and hg.GetCurrentCharacter(owner):IsPlayer() then return true end
end

function SWEP:CanSecondaryAttack()
    if self:GetClass() == "weapon_melee" then return false end
	return true
end

SWEP.supportTPIK = true
SWEP.ismelee = true
SWEP.ismelee2 = true

SWEP.AttackTime = 0.2
SWEP.AnimTime1 = 0.7
SWEP.WaitTime1 = 0.5
SWEP.AttackLen1 = 50

SWEP.Attack2Time = 0.1
SWEP.AnimTime2 = 0.6
SWEP.WaitTime2 = 0.4
SWEP.AttackLen2 = 45

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 15
SWEP.DamageSecondary = 8

SWEP.PenetrationPrimary = 8
SWEP.PenetrationSecondary = 4

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 0.75
SWEP.PenetrationSizeSecondary = 2.5

SWEP.StaminaPrimary = 10
SWEP.StaminaSecondary = 8.5

SWEP.ViewPunch1 = Angle(2,0,0)
SWEP.ViewPunch2 = Angle(0,1,0)

SWEP.AttackSize = 5

SWEP.weaponPos = Vector(2,0.1,-0.8)
SWEP.weaponAng = Angle(0,90,90)

SWEP.AnimList = {
    ["idle"] = "vm_knifeonly_idle",
    ["deploy"] = "vm_knifeonly_raise",
    ["attack"] = "vm_knifeonly_stab",
    ["attack2"] = "vm_knifeonly_swipe",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_iw7_tactical_knife")
	SWEP.IconOverride = "vgui/hud/tfa_iw7_tactical_knife.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.AttackSwing = "weapons/slam/throw.wav"
SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "snd_jack_hmcd_knifestab.wav"
SWEP.Attack2HitFlesh = "snd_jack_hmcd_slash.wav"
SWEP.DeploySnd = "snd_jack_hmcd_knifedraw.wav"

SWEP.setlh = false
SWEP.setrh = true

SWEP.attack_ang = Angle(-55,-3,0)
SWEP.sprint_ang = Angle(30,0,0)

SWEP.HoldPos = Vector(-6,2,2)
SWEP.HoldAng = Angle(0,0,0)

SWEP.basebone = 1

SWEP.AttackPos = Vector(0,0,-10)
SWEP.AttackingPos = Vector(16,0,0)

SWEP.WorkWithFake = true

function SWEP:SetHold(value)
    self:SetWeaponHoldType(value)
    self:SetHoldType(value)
    self.holdtype = value
end

SWEP.modelscale = 1
SWEP.modelscale2 = 1
if CLIENT then
    function PrintBones( entity )
        for i = 0, entity:GetBoneCount() - 1 do
            print( i, entity:GetBoneName( i ) )
        end
    end

    function PrintAnims( entity )
        PrintTable(entity:GetSequenceList())
    end

	function SWEP:GetWM()
        if IsValid(self.worldModel) then
            return self.worldModel
        else
            self.worldModel = ClientsideModel(self.WorldModel)
            self.worldModel:SetNoDraw(true)
            self:CallOnRemove("remove_worldmodel1",function()
                if IsValid(model) then
                    model:Remove()
                    model = nil
                end
            end)
        end
		return self.worldModel
	end

    function SWEP:DrawWorldModel()
        if not IsValid(self:GetOwner()) then
            self:DrawWorldModel2()
        end
        
        if self:GetOwner():IsNPC() then
            self:DrawModel()
        end
    end

	function SWEP:DrawWorldModel2()
		local owner = self:GetOwner()
        
        if not IsValid(self.worldModel) then
            self.worldModel = self:GetWM()
        end
        
        self.worldModel:SetNoDraw(true)
        
        if IsValid(owner) and (not owner.shouldTransmit or owner.NotSeen) then return end
        if not IsValid(owner) and (not self.shouldTransmit or self.NotSeen) then return end

		local WorldModel = self.worldModel
        
        self.worldModel:SetModelScale(self.modelscale2)
        
        local ent = hg.GetCurrentCharacter(owner)
        if (IsValid(owner)) and (ent == owner or hg.KeyDown(owner,IN_USE) or (owner:GetNetVar("lastFake",0) > CurTime())) then
            if not self.cycling then
                local timing = (1 - math.Clamp((self.animtime - CurTime()) / self.animspeed,0,1))
                timing = self.reverseanim and (1 - timing) or timing
                WorldModel:SetCycle(timing)
                --PrintTable( WorldModel:GetSequenceList() )
                
                if self.callback and timing == ((not self.reverseanim) and 1 or 0) then
                    self.callback(self)
                    self.callback = nil
                end
            else
                local timing = ((CurTime() - (self.animtime - self.animspeed))%self.animspeed) / self.animspeed
                WorldModel:SetCycle(timing)
            end

            if WorldModel:GetModel() ~= self.WorldModelReal then WorldModel:SetModel(self.WorldModelReal) end
            
            local pos, ang = self:ModelAnim(WorldModel)

			WorldModel:SetRenderOrigin(pos)
			WorldModel:SetRenderAngles(ang)
            WorldModel:SetPos(pos)
            WorldModel:SetAngles(ang)
		else
            if WorldModel:GetModel() ~= self.WorldModel then WorldModel:SetModel(self.WorldModel) end
			
            WorldModel:SetRenderOrigin(self:GetPos())
			WorldModel:SetRenderAngles(self:GetAngles())
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
		end

        if IsValid(owner) and not (ent == owner or hg.KeyDown(owner,IN_USE) or (owner:GetNetVar("lastFake",0) > CurTime())) then
            local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")
            if not bon then return end
            local mat = ent:GetBoneMatrix(bon)
            if not mat then return end
            local pos,ang = LocalToWorld(self.lpos or vector_origin,self.lang or angle_zero,mat:GetTranslation(),mat:GetAngles())
            WorldModel:SetRenderOrigin(pos)
			WorldModel:SetRenderAngles(ang)
            WorldModel:SetPos(pos)
            WorldModel:SetAngles(ang)
        end

        WorldModel:SetupBones()
        
        if not self.WorldModelExchange then
            WorldModel:DrawModel()
        end

        if IsValid(self.worldModel) and self.WorldModelExchange then
            if not IsValid(self.worldModel2) then
                self.worldModel2 = ClientsideModel(self.WorldModelExchange)
                self.worldModel2:SetNoDraw(true)
                local model = self.worldModel2

                self:CallOnRemove("remove_worldmodel2",function()
                    if IsValid(model) then
                        model:Remove()
                        model = nil
                    end
                end)
            end

            self.worldModel2:SetNoDraw(true)

            local pos,ang = self.worldModel:GetPos(),self.worldModel:GetAngles()
            local huy = self.worldModel:GetModel() == self.WorldModelReal
            
            if (IsValid(self:GetOwner()) or self.DontChangeDropped) then
                local mat = self.worldModel:GetBoneMatrix(self.basebone or 1)
                pos,ang = LocalToWorld(self.weaponPos,self.weaponAng,huy and mat and mat:GetTranslation() or self.worldModel:GetPos(),huy and mat and mat:GetAngles() or self.worldModel:GetAngles())
            end

            self.worldModel2:SetModelScale(self.modelscale)
            self.worldModel2:SetRenderOrigin(pos)
            self.worldModel2:SetRenderAngles(ang)
            self.worldModel2:SetPos(pos)
            self.worldModel2:SetAngles(ang)
            self.worldModel2:SetupBones()
            self.worldModel2:DrawModel()
        end
		
		if(self.DrawPostWorldModel)then
			self:DrawPostWorldModel()
		end
	end
end

local addAng = Angle()
local addPos = Vector()

local vechuy = Vector()

local addPosLerp = Vector()
local addAngLerp = Angle()

function SWEP:ModelAnim(model, pos, ang)
    local owner = self:GetOwner()

    if !IsValid(owner) or !owner:IsPlayer() then return end

    local ent = hg.GetCurrentCharacter(owner)
    local tr = hg.eyeTrace(owner, 60, ent)
    local eyeAng = owner:EyeAngles()

    local vel = ent:GetVelocity()
    local vellen = vel:Length()

    local vellenlerp = self.velocityAdd and self.velocityAdd:Length() or vellen

    if !tr then return end

    self.walkLerped = LerpFT(0.1, self.walkLerped or 0, (owner:InVehicle()) and 0 or vellenlerp * 200)
	self.walkTime = self.walkTime or 0
    
	local walk = math.Clamp(self.walkLerped / 200, 0, 1)
	
	self.walkTime = self.walkTime + walk * FrameTime() * 2 * game.GetTimeScale() * (owner:OnGround() and 1 or 0)

    self.velocityAdd = self.velocityAdd or Vector()
    self.velocityAddVel = self.velocityAddVel or Vector()

    //vel.z = vel.z + ((owner:IsFlagSet(FL_ANIMDUCKING) and !owner:IsFlagSet(FL_DUCKING)) and (100) or (!owner:IsFlagSet(FL_ANIMDUCKING) and owner:IsFlagSet(FL_DUCKING)) and (-100) or 0)
    self.velocityAddVel = LerpFT(0.9, self.velocityAddVel * 0.99, -vel * 0.01)
    self.velocityAddVel[3] = self.velocityAddVel[3]

    self.velocityAdd = LerpFT(0.03, self.velocityAdd, self.velocityAddVel)

	local huy = self.walkTime
	
	local x, y = math.cos(huy) * math.sin(huy) * walk + math.cos(CurTime() * 5) * walk * math.sin(CurTime() * 2) * 0.5, math.sin(huy) * walk * 1 + math.sin(CurTime() * 5) * walk * math.cos(CurTime() * 4) * 0.5
    
    addPos:Zero()
    addAng:Zero()
    addPosLerp:Zero()
    addAngLerp:Zero()

    addPosLerp.z = addPosLerp.z + ((hg.KeyDown(owner, IN_DUCK)) and -2 or 0)
    self.lerpedAddPos = LerpFT(0.02, self.lerpedAddPos or Vector(), addPosLerp)
    self.lerpedAddAng = LerpFT(0.02, self.lerpedAddAng or Angle(), addAngLerp)

    if self:IsLocal() then
        addPos.z = x * 2 * vellenlerp * 0.3 - vellenlerp * 1
        addPos.y = y * 2 * vellenlerp * 0.3
    
        addAng.z = -x * 2// * vellenlerp * 0.3
        addAng.y = -y * 2// * vellenlerp * 0.3

        addPos.y = addPos.y - angle_difference.y * 2
        addAng.y = addAng.y + angle_difference.y * 4

        addPos.z = addPos.z + angle_difference.p * 2
        addAng.p = addAng.p + angle_difference.p * 4

        addAng.p = addAng.p + math.cos(CurTime() * 2) * 1

        //addPos.z = addPos.z + eyeAng[1] * 0.05
        addPos.x = addPos.x + eyeAng[1] * 0.05

        local veldot = self.velocityAdd:Dot(tr.Normal:Angle():Right())
        
        addAng.r = addAng.r - veldot * 5 + math.cos(CurTime() * 5) * walk * 2 - angle_difference.y * 2

        //addAng.p = addAng.p + math.cos(CurTime() * 2) * 1
    end

    self.lastAddPos = addPos

    //local inattack1 = self:GetAttackType() == 1 and math.max(self:GetLastAttack() - CurTime(),0) / self.AttackTime > 0 or false
    //local inattack2 = self:GetAttackType() == 2 and math.max(self:GetLastAttack() - CurTime(),0) / self.AttackTime > 0 or false

    //self.attackanim = LerpFT(0.1, self.attackanim, (inattack1 and 0.8 or 0) - (inattack2 and 0.3 or 0))
    //self.sprintanim = LerpFT(0.05, self.sprintanim, self:IsSprinting() and 1 or 0)

    local hpos = self.HoldPos
    local hang = self.HoldAng

    local pos, ang = LocalToWorld(hpos + addPos + self.lerpedAddPos, hang + addAng + self.lerpedAddAng, tr.StartPos + self.velocityAdd, eyeAng)

    return pos, ang
end

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeVPShouldUseHand = false
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_Forearm"

--hook.Add("PostDrawPlayerRagdoll","ragdollhuymelee",function(ent,ply)
function hg.RenderMelees(ent, ply, wep)
    if wep.DrawWorldModel2 then
        wep:DrawWorldModel2()
    else
        wep:DrawWorldModel()
    end
end
--end)

local host_timescale = game.GetTimeScale

function SWEP:Camera(eyePos, eyeAng, view, vellen)
    self:SetHandPos()
    self:DrawWorldModel2()

    local WorldModel = self.worldModel

    if not IsValid(WorldModel) then return end

    local camBone = (WorldModel:LookupBone(self.FakeViewBobBone) or (self.FakeVPShouldUseHand and WorldModel:LookupBone("ValveBiped.Bip01_R_Hand") or WorldModel:LookupBone("Weapon"))) or WorldModel:LookupBone("ValveBiped.Bip01_R_Hand")
    
    if camBone then
        local matrix = WorldModel:GetBoneMatrix(camBone)

        if matrix then
            local gAngles = matrix:GetAngles()
            local _,gAngles = WorldToLocal(vector_origin, gAngles, eyePos, eyeAng)
            self.OldAngPunch = self.OldAngPunch or gAngles
            local punch = ( self.OldAngPunch - gAngles ) / (self.ViewPunchDiv or 120)
            
            self.punch = punch

            //ViewPunch2( -punch )
            ViewPunch( punch )
            
            self.OldAngPunch = gAngles
        end
    end

    local owner = self:GetOwner()
    if not owner.InVehicle then return end

    view.origin = eyePos - (angle_difference_localvec * 150) - (position_difference * 0.5)
    view.angles = eyeAng
    
    local lpos = self.lastAddPos or vector_origin
    //view.angles[1] = view.angles[1] + lpos.z * 1
    //view.angles[2] = view.angles[2] + lpos.y * 1
    
    return view
end

function SWEP:SetHandPos(noset)
	local ply = self:GetOwner()
	local owner = self:GetOwner()

    self.rhandik = false
	self.lhandik = false
    
    if not IsValid(ply) or not IsValid(self.worldModel) then return end
    if not ply.shouldTransmit or ply.NotSeen then return end

    local ent = hg.GetCurrentCharacter(ply)

	local bones = hg.TPIKBonesLH

    local ply_spine_index = ent:LookupBone("ValveBiped.Bip01_Spine4")
    if !ply_spine_index then return end
    local ply_spine_matrix = ent:GetBoneMatrix(ply_spine_index)
    if !ply_spine_matrix then return end
    local wmpos = ply_spine_matrix:GetTranslation()

	local wm = self:GetWM()
	if !IsValid(wm) then return end
	ent:SetupBones()

	self.rhandik = self.setrh and IsValid(owner) and (ent == owner or hg.KeyDown(owner,IN_USE) or (owner:GetNetVar("lastFake",0) > CurTime()))//self.setrh
	self.lhandik = self.setlh and IsValid(owner) and (ent == owner or hg.KeyDown(owner,IN_USE) or (owner:GetNetVar("lastFake",0) > CurTime())) and (ply:GetTable().ChatGestureWeight < 0.1)

    local rhmat,lhmat

	if self.lhandik and (ent == ply or hg.KeyDown(ply,IN_USE) or (ply:GetNetVar("lastFake",0) > CurTime())) and hg.CanUseLeftHand(ply) then
		for _, bone in ipairs(bones) do
			local wm_boneindex = wm:LookupBone(bone)
			if !wm_boneindex then continue end
			local wm_bonematrix = wm:GetBoneMatrix(wm_boneindex)
			if !wm_bonematrix then continue end
			
			local ply_boneindex = ent:LookupBone(bone)
			if !ply_boneindex then continue end
			local ply_bonematrix = ent:GetBoneMatrix(ply_boneindex)
			if !ply_bonematrix then continue end

			local bonepos = wm_bonematrix:GetTranslation()
			local boneang = wm_bonematrix:GetAngles()

			bonepos.x = math.Clamp(bonepos.x, wmpos.x - 38, wmpos.x + 38)
			bonepos.y = math.Clamp(bonepos.y, wmpos.y - 38, wmpos.y + 38)
			bonepos.z = math.Clamp(bonepos.z, wmpos.z - 38, wmpos.z + 38)

			ply_bonematrix:SetTranslation(bonepos)
			ply_bonematrix:SetAngles(boneang)
			
            --if bone == "ValveBiped.Bip01_L_Hand" then lhmat = ply_bonematrix end
			ent:SetBoneMatrix(ply_boneindex, ply_bonematrix)
			--ent:SetBonePosition(ply_boneindex, bonepos, boneang)
		end
	end

	local bones = hg.TPIKBonesRH

	if self.rhandik and (ent == ply or hg.KeyDown(ply,IN_USE) or (ply:GetNetVar("lastFake",0) > CurTime())) then
		for _, bone in ipairs(bones) do
			local wm_boneindex = wm:LookupBone(bone)
			if !wm_boneindex then continue end
			local wm_bonematrix = wm:GetBoneMatrix(wm_boneindex)
			if !wm_bonematrix then continue end
			
			local ply_boneindex = ent:LookupBone(bone)
			if !ply_boneindex then continue end
			local ply_bonematrix = ent:GetBoneMatrix(ply_boneindex)
			if !ply_bonematrix then continue end

			local bonepos = wm_bonematrix:GetTranslation()
			local boneang = wm_bonematrix:GetAngles()

			bonepos.x = math.Clamp(bonepos.x, wmpos.x - 38, wmpos.x + 38)
			bonepos.y = math.Clamp(bonepos.y, wmpos.y - 38, wmpos.y + 38)
			bonepos.z = math.Clamp(bonepos.z, wmpos.z - 38, wmpos.z + 38)

			ply_bonematrix:SetTranslation(bonepos)
			ply_bonematrix:SetAngles(boneang)

            --if bone == "ValveBiped.Bip01_R_Hand" then rhmat = ply_bonematrix end
            ent:SetBoneMatrix(ply_boneindex, ply_bonematrix)
			--ent:SetBonePosition(ply_boneindex, bonepos, boneang)
		end
	end

    --return rhmat,lhmat
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Blocking")
    self:NetworkVar("Float", 3, "AttackWait")
    self:NetworkVar("Float", 5, "LastAttack")
    self:NetworkVar("Int", 6, "AttackType")
	self:NetworkVar("Bool", 7, "InAttack")
    self:NetworkVar("Float", 8, "AttackLength")
    self:NetworkVar("Float", 9, "AttackTime")
end

function SWEP:OwnerChanged()
    if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
        self:PlayAnim("deploy",0.5,false,nil,false)
        self:SetHold(self.HoldType)
        timer.Simple(0,function() self.picked = true end)
    else
        self:SetInAttack(false)
        timer.Simple(0,function() self.picked = nil end)
    end
end

function SWEP:OnRemove()
    if IsValid(self.worldModel) then
        self.worldModel:Remove()
    end
end
SWEP.Initialzed = false
function SWEP:Deploy()
    if SERVER and self.Initialzed and not self:GetOwner().noSound then self:GetOwner():EmitSound(self.DeploySnd,65) end
    self.Initialzed = true
    self:PlayAnim("deploy",0.5,false,nil,false)
    self:SetHold(self.HoldType)
	
	return true
end

function SWEP:Holster(wep)
    self:SetInAttack(false)
    return true
end

function SWEP:IsEntSoft(ent)
	return ent:IsNPC() or ent:IsPlayer() or hg.RagdollOwner(ent) or ent:IsRagdoll()
end

function SWEP:ThinkAdd()
end

SWEP.Swing = false -- Это отвесает за первый вид удара, изначально с права на лево
SWEP.LSwing = true -- Это отвесает за второй вид удара, изначально с права на лево
SWEP.SwingLeft = false -- Это отвесает за первый вид удара, переключает с лева на право
SWEP.LSwingLeft = false -- Это отвесает за второй вид удара, переключает с лева на право
SWEP.UpSwing = true -- Это отвесает за первый вид удара, Сверху вниз
SWEP.LUpSwing = false -- Это отвесает за второй вид удара, Сверху вниз

function SWEP:Think()
end

hook.Add("Player Think","MeleeThink",function( ply )
    if not ply.GetActiveWeapon then return end
    
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep.CustomThink then
        wep:CustomThink()
    end
end)
if CLIENT then
    local Sensitivity = 1

    function SWEP:AdjustMouseSensitivity()
        local time = math.max(self:GetLastAttack() - CurTime(),0)
        local inattack1 = time / self.AttackTimeLength
        local inattack2 = time / self.Attack2TimeLength
        local mul = self:GetAttackType() == 1 and inattack1 or inattack2

        mul = math.max( (math.max(math.min(mul,self.MinSensivity or 0.35),0)) - (self.MinSensivity/10) ,0 )
        mul = 1-(mul)
        Sensitivity = math.min(Sensitivity,mul)
        Sensitivity = LerpFT(0.02,Sensitivity,mul)
        --print(Sensitivity)
        return (Sensitivity ~= nil and IsValid(hg.GetCurrentCharacter(self:GetOwner())) and hg.GetCurrentCharacter(self:GetOwner()):IsPlayer()) and math.Round(Sensitivity,2)
    end

end

SWEP.MinSensivity = 0.35

function SWEP:CustomThink()
    local owner = self:GetOwner()
    local actwep = owner.GetActiveWeapon and owner:GetActiveWeapon()

	if SERVER and not owner:IsNPC() and owner.organism and (not owner.organism.canmove or ((owner.organism.stun - CurTime()) > 0) or (owner.organism.larm == 1 and owner.organism.rarm == 1)) and IsValid(actwep) and self == actwep then
		self:RemoveFake()
		
		hg.drop(owner)

		return
	end

    self:SetHold(self.HoldType)

    self:ThinkAdd()

    if CLIENT and owner ~= LocalPlayer() then return end
    
    if self:GetInAttack() then
        local inattack1 = math.max(self:GetLastAttack() - CurTime(),0) / self.AttackTime
        local inattack2 = math.max(self:GetLastAttack() - CurTime(),0) / self.Attack2Time

        local inattackL1 = math.max(self:GetAttackTime() - CurTime(),0) / self.AttackTimeLength
        local inattackL2 = math.max(self:GetAttackTime() - CurTime(),0) / self.Attack2TimeLength
        --print(inattackL1)
        local ent = hg.GetCurrentCharacter(owner)
        local vellen = ent:GetVelocity():Length()

        local mul = 1 / math.Clamp((180 - owner.organism.stamina[1]) / 90,1,1.3)
        mul = mul * math.Clamp(vellen / 250, 0.9, 1.25)
        mul = mul * (ent ~= owner and 0.75 or 1)
        mul = mul * (owner.MeleeDamageMul or 1)

		if owner.organism.superfighter then
			mul = mul * 5
		end

        if SERVER and ent:IsPlayer() then
            local vec = owner:GetAimVector()
            vec[3] = 0
            ent:SetVelocity(vec * self.DamagePrimary * 0.1)
        end

        if self:GetAttackType() == 1 and inattack1 == 0 then
            if SERVER then owner:SetNetVar("slowDown", owner:GetNetVar("slowDown", 0) + self.DamagePrimary) end
            if not self.FirstAttackTick then 
                self.Penetration = self.PenetrationPrimary
                self.PenetrationSize = self.PenetrationSizePrimary

                if CLIENT and owner == LocalPlayer() and self.viewpunch then
                    ViewPunch(self.ViewPunch1)
                    self.viewpunch = nil
                end
            
                -- if owner.organism and SERVER then
                --     owner.organism.stamina.subadd = owner.organism.stamina.subadd + self.StaminaPrimary / 2 * math.Clamp(vellen / 200, 1, 1.5)
                -- end

                if self.CustomAttack and self:CustomAttack() then self:SetInAttack(false) return end
            end
            

            self.HitEnts = self.HitEnts or {owner,ent}
            owner:LagCompensation(true)
            local eyetr = hg.eyeTrace(owner,60,ent)

            local eyetr = hg.eyeTrace(owner,self:GetAttackLength() + math.min(owner:GetVelocity():Length()/15,40),ent)
            local trace
            if not self:IsEntSoft(eyetr.Entity) then
                for i = 1, 7 do
                    local normal = eyetr.Normal:Angle()
                    normal:RotateAroundAxis(normal:Forward(),self.SwingAng or -90)
                    normal:RotateAroundAxis(normal:Up(),((0.5 - inattackL1)*(self.AttackRads or 65)))
                    normal:RotateAroundAxis(normal:Up(),(i-4)*math.min(self.AttackRads,5))
                    
                    local tr = {}
                    tr.start = eyetr.StartPos
                    tr.endpos = eyetr.StartPos + normal:Forward() * (self:GetAttackLength() + math.min(owner:GetVelocity():Length()/15,40))
                    tr.filter = self.MultiDmg1 and {owner,ent} or self.HitEnts
                    local size = 0.15
                    tr.mins = -Vector(size,size,size)
                    tr.maxs = Vector(size,size,size)

                    trace = util.TraceLine(tr)


                    if self:IsEntSoft(trace.Entity) then break end
                end
            else
                trace = eyetr

            end

            if SERVER and ent:IsPlayer() then
                local vec = trace.Normal * math.min(self.DamagePrimary * 0.5, 20)
                vec[3] = 0
                ent:SetVelocity(vec)
            end

            if CLIENT then return end

            if self:IsEntSoft(trace.Entity) and trace.Entity:IsPlayer() and (owner:GetAimVector():Dot(trace.Entity:GetAngles():Forward()) > math.cos(math.rad(45))) then
                mul = mul * 2
            end

            owner:LagCompensation(false)
            
            if IsValid(hg.RagdollOwner(trace.Entity)) and self.HitEnts[#self.HitEnts] == hg.RagdollOwner(trace.Entity) then
                local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

                if IsValid(phys) then
                    local dmg = math.random(self.DamagePrimary - 3, self.DamagePrimary + 3) * mul
                    phys:ApplyForceOffset(trace.Normal * dmg * 100,trace.HitPos)
                end
                goto meleeskip1
            end
            
            if SERVER and (IsValid(trace.Entity) or trace.Entity == Entity(0)) and self.HitEnts[#self.HitEnts] ~= trace.Entity then
                if self:IsEntSoft(trace.Entity) then
                    owner:EmitSound(self.AttackHitFlesh,50)
                    if self.DamageType == DMG_SLASH then
                        util.Decal( "Blood", trace.HitPos + trace.HitNormal * 15, trace.HitPos - trace.HitNormal * 15, owner )
                        util.Decal( "Blood", trace.HitPos + trace.HitNormal * 2, owner:GetPos(), trace.Entity )
                    end
                elseif not self.AttackHitPlayed then
                    self.AttackHitPlayed = true
                    owner:EmitSound(self.AttackHit,50)
                end
            end
            
            if SERVER and (IsValid(trace.Entity) or trace.Entity:IsWorld()) and ( self.MultiDmg1 or (self.HitEnts[#self.HitEnts] ~= trace.Entity) ) then
                if string.find(trace.Entity:GetClass(),"break") and trace.Entity:GetBrushSurfaces()[1] and string.find(trace.Entity:GetBrushSurfaces()[1]:GetMaterial():GetName(),"glass") then
                    trace.Entity:EmitSound("physics/glass/glass_sheet_impact_hard"..math.random(3)..".wav")
                    if math.random(1,4) == 4 then
                        trace.Entity:Fire("Break")
                    end
                    goto meleeskip1
                end

                local dmg = math.random(self.DamagePrimary - 3, self.DamagePrimary + 3) * mul
                if self.MultiDmg1 or not self:IsEntSoft(trace.Entity) then
                    dmg = dmg / (self.AttackRads*self.AttackTimeLength)
                else
                    dmg = dmg / 1.5
                end
                
                local ent = trace.Entity
                local vec = trace.HitNormal
                if string.find(ent:GetClass(),"prop_") and not ent:IsRagdoll() then
                    ent:CallOnRemove("gibbreak",function()
                        ent:PrecacheGibs()
                        ent:GibBreakServer( vec * 100 )
                    end)
                    timer.Simple(1,function()
                        if IsValid(ent) then ent:RemoveCallOnRemove("gibbreak") end
                    end)
                end
                
                local dmginfo = DamageInfo()
                dmginfo:SetAttacker(owner)
                dmginfo:SetInflictor(self)
                dmginfo:SetDamage(dmg)
                dmginfo:SetDamageForce(trace.Normal * dmg)
                dmginfo:SetDamageType(self.DamageType)
                dmginfo:SetDamagePosition(trace.HitPos)
                self.slash = self.MultiDmg1 
                trace.Entity:TakeDamageInfo(dmginfo)
                self.slash = nil
                
                if SERVER and trace.Entity:IsPlayer() or trace.Entity:IsRagdoll() then 
                    local ply = hg.RagdollOwner(trace.Entity) or trace.Entity
                    if ply:IsPlayer() then
                        local normal = Angle(0,0,0)
                        normal:RotateAroundAxis(normal:Forward(),-(self.SwingAng or -90))
                        normal:RotateAroundAxis( normal:Up(),-1*(self.AttackRads or 65) )

                        local dot = ply:GetAimVector():Dot(trace.Normal)
                        
                        local angrand = AngleRand(-5, 5)

                        ply:ViewPunch((normal * -dot) * dmg / 30)
                        ply:SetVelocity((trace.Normal:Angle() + normal):Forward() * -5 * dmg + trace.Normal * dmg * 5)
                    end
                end

                local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

                if IsValid(phys) then
                    phys:ApplyForceOffset(trace.Normal * dmg * 100,trace.HitPos)
                end

                self:PrimaryAttackAdd(trace.Entity, trace)
            end
            ::meleeskip1::
            if not trace.Entity:IsWorld() and self:IsEntSoft(trace.Entity) then
                self.HitEnts[#self.HitEnts + 1] = trace.Entity
            end

            if SERVER and not self.FirstAttackTick then
                owner:EmitSound(self.AttackSwing or "weapons/slam/throw.wav",50,math.random(95,105))
            end

            self.FirstAttackTick = true

            if inattackL1 == 0 then
                self:SetInAttack(false)
                self.HitEnts = nil
                self.FirstAttackTick = false
                self.AttackHitPlayed = false
            end
            
        elseif self:GetAttackType() == 2 and inattack2 == 0 then
            if SERVER then owner:SetNetVar("slowDown", owner:GetNetVar("slowDown", 0) + self.DamageSecondary) end
            if not self.FirstAttackTick then 
                self.Penetration = self.PenetrationSecondary
                self.PenetrationSize = self.PenetrationSizeSecondary

                if CLIENT and owner == LocalPlayer() and self.viewpunch then
                    ViewPunch(self.ViewPunch2)
                    self.viewpunch = nil
                end

                -- if owner.organism and SERVER then
                --     owner.organism.stamina.subadd = owner.organism.stamina.subadd + self.StaminaSecondary / 2 * math.Clamp(vellen / 200, 1, 1.5)
                -- end

                if self.CustomAttack2 and self:CustomAttack2() then self:SetInAttack(false) return end
            end

            self.HitEnts = self.HitEnts or {owner,ent}

            owner:LagCompensation(true)
            
            local eyetr = hg.eyeTrace(owner,self:GetAttackLength() + math.min(owner:GetVelocity():Length()/15,40),ent)
            local trace
            if not self:IsEntSoft(eyetr.Entity) then
                for i = 1, 7 do
                    local normal = eyetr.Normal:Angle()
                    normal:RotateAroundAxis(normal:Forward(),self.SwingAng2 or -90)
                    normal:RotateAroundAxis(normal:Up(),((0.5 - inattackL2)*(self.AttackRads2 or 65)))
                    normal:RotateAroundAxis(normal:Up(),(i-4)*math.min(self.AttackRads2,5))

                    local tr = {}
                    tr.start = eyetr.StartPos
                    tr.endpos = eyetr.StartPos + normal:Forward() * (self:GetAttackLength() + math.min(owner:GetVelocity():Length()/15,40))
                    tr.filter = self.MultiDmg2 and {owner,ent} or self.HitEnts
                    local size = 0.15
                    tr.mins = -Vector(size,size,size)
                    tr.maxs = Vector(size,size,size)
                    
                    trace = util.TraceLine(tr)
                    
                    if self:IsEntSoft(trace.Entity) then break end
                end
            else
                trace = eyetr

            end

            if SERVER and ent:IsPlayer() then
                local vec = trace.Normal * math.min(self.DamageSecondary * 0.5, 20)
                vec[3] = 0
                ent:SetVelocity(vec)
            end

            if CLIENT then return end

            if self:IsEntSoft(trace.Entity) and trace.Entity:IsPlayer() and (owner:GetAimVector():Dot(trace.Entity:GetAngles():Forward()) > math.cos(math.rad(45))) then
                mul = mul * 2
            end

            owner:LagCompensation(false)

            if IsValid(hg.RagdollOwner(trace.Entity)) and self.HitEnts[#self.HitEnts] == hg.RagdollOwner(trace.Entity) then
                local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

                if IsValid(phys) then
                    local dmg = math.random(self.DamageSecondary - 3, self.DamageSecondary + 3) * mul
                    phys:ApplyForceOffset(trace.Normal * dmg * 100,trace.HitPos)
                end
                goto meleeskip2
            end

            if SERVER and (IsValid(trace.Entity) or trace.Entity == Entity(0)) and self.HitEnts[#self.HitEnts] ~= trace.Entity then
                if self:IsEntSoft(trace.Entity) then
                    owner:EmitSound(self.Attack2HitFlesh,50)
                    if self.DamageType == DMG_SLASH then
                        util.Decal( "Blood", trace.HitPos + trace.HitNormal * 15, trace.HitPos - trace.HitNormal * 15, owner )
                        util.Decal( "Blood", trace.HitPos + trace.HitNormal * 2, owner:GetPos(), trace.Entity )
                    end
                elseif not self.AttackHitPlayed then 
                    self.AttackHitPlayed = true
                    owner:EmitSound(self.AttackHit,50)
                end
            end

            if SERVER and (IsValid(trace.Entity) or trace.Entity:IsWorld()) and ( self.MultiDmg2 or (self.HitEnts[#self.HitEnts] ~= trace.Entity) )  then
                if string.find(trace.Entity:GetClass(),"break") and trace.Entity:GetBrushSurfaces()[1] and string.find(trace.Entity:GetBrushSurfaces()[1]:GetMaterial():GetName(),"glass") then
                    trace.Entity:EmitSound("physics/glass/glass_sheet_impact_hard"..math.random(3)..".wav")
                    if math.random(1,4) == 4 then
                        trace.Entity:Fire("Break")
                    end
                    goto meleeskip2
                end

                local dmg = math.random(self.DamageSecondary - 3, self.DamageSecondary + 3) * mul

                if self.MultiDmg2 or not self:IsEntSoft(trace.Entity) then
                    dmg = dmg / (self.AttackRads2*self.Attack2TimeLength)
                end

                local ent = trace.Entity
                local vec = trace.HitNormal
                if string.find(ent:GetClass(),"prop_") and not ent:IsRagdoll() then
                    ent:CallOnRemove("gibbreak",function()
                        ent:PrecacheGibs()
                        ent:GibBreakServer( vec * 100 )
                    end)
                    timer.Simple(1,function()
                        if IsValid(ent) then ent:RemoveCallOnRemove("gibbreak") end
                    end)
                end

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker(owner)
                dmginfo:SetInflictor(self)
                dmginfo:SetDamage(dmg)
                dmginfo:SetDamageForce(trace.Normal * dmg)
                dmginfo:SetDamageType(self.DamageType)
                dmginfo:SetDamagePosition(trace.HitPos)
                self.slash = self.MultiDmg2
                trace.Entity:TakeDamageInfo(dmginfo)
                self.slash = nil
                local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

                if SERVER and trace.Entity:IsPlayer() or trace.Entity:IsRagdoll() then 
                    local ply = hg.RagdollOwner(trace.Entity) or trace.Entity
                    if ply:IsPlayer() then
                        local normal = Angle(0,0,0)
                        normal:RotateAroundAxis(normal:Forward(),-(self.SwingAng2 or -90))
                        normal:RotateAroundAxis( normal:Up(),-1*(self.AttackRads2 or 65) )

                        local dot = ply:GetAimVector():Dot(trace.Normal)
                        
                        local angrand = AngleRand(-5, 5)

                        ply:ViewPunch((normal * -dot) * dmg / 30)
                        ply:SetVelocity((trace.Normal:Angle() + normal):Forward() * -5 * dmg + trace.Normal * dmg * 5)
                    end
                end

                if IsValid(phys) then
                    phys:ApplyForceOffset(trace.Normal * dmg * 100,trace.HitPos)
                end

                self:SecondaryAttackAdd(trace.Entity, trace)
            end
            ::meleeskip2::
            if not trace.Entity:IsWorld() and self:IsEntSoft(trace.Entity) then
                self.HitEnts[#self.HitEnts + 1] = trace.Entity
            end

            if SERVER and not self.FirstAttackTick then
                owner:EmitSound(self.AttackSwing or "weapons/slam/throw.wav",50,math.random(95,105))
            end

            self.FirstAttackTick = true

            if inattackL2 == 0 then
                self:SetInAttack(false)
                self.HitEnts = nil
                self.FirstAttackTick = false
                self.AttackHitPlayed = false
            end
        end
    end

end

function SWEP:PrimaryAttackAdd(ent)
end

function SWEP:SecondaryAttackAdd(ent)
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 45
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if not IsFirstTimePredicted() then return end
    local ply = self:GetOwner()
    if !ply:IsPlayer() then return end
    //if self:IsSprinting() then return end
    local ent = hg.GetCurrentCharacter(ply)
    if not (ent == ply or hg.KeyDown(ply,IN_USE) or (ply:GetNetVar("lastFake",0) > CurTime())) then return end
    if (self:GetLastAttack() + self:GetAttackWait()) > CurTime() then return end
    local mul = 1 / math.Clamp((180 - self:GetOwner().organism.stamina[1]) / 90,1,2)
    //mul = mul * ply.organism.meleespeed * (ply.organism.adrenaline / 16 + 1)
    self.HitEnts = nil
    self.FirstAttackTick = false
    self.AttackHitPlayed = false
    self:PlayAnim("attack",self.AnimTime1 / mul,false,nil,false)
    self:SetAttackType(1)
    self:SetLastAttack(CurTime() + self.AttackTime / mul)
    self:SetAttackTime( self:GetLastAttack() + (self.AttackTimeLength / mul) )
    self:SetAttackLength(self.AttackLen1)
    self:SetAttackWait(self.WaitTime1 / mul)
    self:SetInAttack(true)
    if CLIENT and not self:IsLocal() and ply.AnimRestartGesture then
        self:GetOwner():AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
    end
    self.viewpunch = true
end

function SWEP:CutDuct()
    if self.DamageType ~= DMG_SLASH or CLIENT then return end
    
    local ent = hg.eyeTrace(self:GetOwner()).Entity
    
    if IsValid(ent) then
        if hgIsDoor(ent) and ent.LockedDoor then
            ent.LockedDoor = ent.LockedDoor - FrameTime() * 10
            
            if (ent.SoundTime or 0) < CurTime() then
                ent.SoundTime = CurTime() + 4

                self:GetOwner():EmitSound("tapetear.mp3",65)
            end

            if ent.LockedDoor <= 0 then
                if !ent.LockedDoorNail and !ent.LockedDoorMap then ent:Fire("unlock", "", 0) end
                ent.LockedDoor = nil
            end
            
            return true
        end

        if ent.DuctTape and next(ent.DuctTape) then
            if (ent.SoundTime or 0) < CurTime() then
                ent.SoundTime = CurTime() + 4

                self:GetOwner():EmitSound("tapetear.mp3",65)
            end
            
            local key = next(ent.DuctTape)
            local duct = ent.DuctTape[key]
            
            duct[2] = duct[2] - FrameTime()
            
            if duct[2] <= 0 then
                if IsValid(duct[1]) then
                    duct[1]:Remove()
                    duct[1] = nil
                end
                
                ent.DuctTape[key] = nil
            end

            return true
        end
    end
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then self:CutDuct() return end
    if not IsFirstTimePredicted() then return end
    local ply = self:GetOwner()
    //if self:IsSprinting() then return end
    local ent = hg.GetCurrentCharacter(ply)
    if not (ent == ply or hg.KeyDown(ply,IN_USE) or (ply:GetNetVar("lastFake",0) > CurTime())) then return end
    if (hg.KeyDown(ply,IN_USE) and not IsValid(ply.FakeRagdoll)) then return end
    if (self:GetLastAttack() + self:GetAttackWait()) > CurTime() then return end
    local mul = 1 / math.Clamp((180 - ply.organism.stamina[1]) / 90,1,2)
    //mul = mul * ply.organism.meleespeed * (ply.organism.adrenaline / 16 + 1)
    self.HitEnts = nil
    self.FirstAttackTick = false
    self.AttackHitPlayed = false
    self:PlayAnim("attack2",self.AnimTime2 / mul,false,nil,false)
    self:SetAttackType(2)
    self:SetLastAttack(CurTime() + self.Attack2Time / mul)
    self:SetAttackTime( self:GetLastAttack() + (self.Attack2TimeLength / mul) )
    self:SetAttackLength(self.AttackLen2)
    self:SetAttackWait(self.WaitTime2 / mul)
    self:SetInAttack(true)
    if CLIENT and not self:IsLocal() and ply.AnimRestartGesture then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
    end
    self.viewpunch = true
end

function SWEP:InitAdd()
end

function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self:PlayAnim("idle",10,true)

    if self:GetClass() == "weapon_melee" then
        self.ImmobilizationMul = 2
        self.StaminaMul = 0.5
        self.BreakBoneMul = 0.5
        self.ShockMultiplier = 0.5
        self.PainMultiplier = 2

        function self:Reload()
            if SERVER then
                if self:GetOwner():KeyPressed(IN_ATTACK) then
                    self:SetNetVar("mode", not self:GetNetVar("mode"))
                    self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
                    --self.Swing = self:GetNetVar("mode")
                    --self.UpSwing = not self:GetNetVar("mode")
                end
            end
        end
        
        function self:CanPrimaryAttack()
            if hg.KeyDown(self:GetOwner(), IN_RELOAD) then return end
            if not self:GetNetVar("mode") then
                return true
            else
                self.allowsec = true
                self:SecondaryAttack()
                self.allowsec = nil
                return false
            end
        end
        
        function self:CanSecondaryAttack()
            return self.allowsec and true or false
        end
    end

    self:SetAttackLength(60)
    self:SetAttackWait(0)
    if self.modelscale then
        self:SetModelScale(self.modelscale)
        self:Activate()
    end
    self:SetHold(self.HoldType)
    
    util.PrecacheSound(self.AttackSwing)
    util.PrecacheSound(self.AttackHit)
    util.PrecacheSound(self.Attack2Hit)
    util.PrecacheSound(self.AttackHitFlesh)
    util.PrecacheSound(self.Attack2HitFlesh)
    util.PrecacheSound(self.DeploySnd)

    self:InitAdd()
end

function SWEP:IsLocal()
	if SERVER then return end
	return not ((self:GetOwner() ~= LocalPlayer()) or (LocalPlayer() ~= GetViewEntity()))
end

SWEP.tries = 10

if SERVER then
    util.AddNetworkString("melee_attack")
elseif CLIENT then
    net.Receive("melee_attack",function()
        local tbl = net.ReadTable()
        local ent = net.ReadEntity()
        local sendtoclient = net.ReadBool()

        if IsValid(ent) and ent.PlayAnim and ( sendtoclient and sendtoclient or !ent:IsLocal()) then
            ent:PlayAnim(tbl.anim,tbl.time,tbl.cycling,tbl.callback,tbl.reverse)
            if (tbl.anim == "attack" or tbl.anim == "attack2") and ent:GetOwner().AnimRestartGesture and IsValid(ent:GetOwner()) and not ent:GetOwner():IsWorld() then
                ent:GetOwner():AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
            end
        end
    end)
end

function SWEP:PlayAnim(anim, time, cycling, callback, reverse, sendtoclient)
    if SERVER then
        sendtoclient = sendtoclient or false
        net.Start("melee_attack")
            local netTbl = {
                anim = anim,
                time = time,
                cycling = cycling,
                callback = callback,
                reverse = reverse
            }
            net.WriteTable(netTbl) 
            net.WriteEntity(self)
            net.WriteBool(sendtoclient)
        net.SendPVS(self:GetPos())
    return end
    if not IsValid(self:GetWM()) or not IsValid(self:GetOwner()) or self:GetOwner():GetActiveWeapon() ~= self then
		self.tries = self.tries - 1
		if self.tries > 0 then
			timer.Simple(0.01,function()
                if not IsValid(self) then return end
				self:PlayAnim(anim,time,cycling,callback,reverse)
			end)
		end
		return
	end
    self.tries = 10

    if self:GetWM():GetModel() ~= self.WorldModelReal then self:GetWM():SetModel(self.WorldModelReal) end
    
    self:GetWM():SetSequence(self.AnimList[anim] or anim)
    self.animtime = CurTime() + time
    self.animspeed = time
    self.cycling = cycling
    self.reverseanim = reverse
    if callback then
        self.callback = callback
    end
end

function SWEP:SetFakeGun(ent)
	self:SetNWEntity("fakeGun", ent)
	self.fakeGun = ent
end

function SWEP:RemoveFake()
	if not IsValid(self.fakeGun) then return end
	self.fakeGun:Remove()
	self:SetFakeGun()
end

local function GetPhysBoneNum(ent,string)
	if not IsValid(ent) then return 7 end
	return ent:TranslateBoneToPhysBone(ent:LookupBone(string))
end

function SWEP:CreateFake(ragdoll)
	if IsValid(self:GetNWEntity("fakeGun")) then return end
	if not IsValid(ragdoll) then return end
	local ent = ents.Create("prop_physics")
    ent.notprop = true
	local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
	local rh = ragdoll:GetPhysicsObjectNum(physbonerh)

	ent:SetPos(rh:GetPos())
	ent:SetModel(self.WorldModel)
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:GetPhysicsObject():SetMass(0)
    ent:SetNoDraw(true)
    ent.dontPickup = true
	ent.fakeOwner = self
	ragdoll:DeleteOnRemove(ent)
	ragdoll.fakeGun = ent
	if IsValid(ragdoll.ConsRH) then ragdoll.ConsRH:Remove() end
	self:SetFakeGun(ent)
	ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)

	ent:SetNoDraw(true)
end

function SWEP:NPCThink()
    local ent = self:GetOwner()
    self:SetWeaponHoldType("melee")
    
    if ent:GetClass() == "npc_metropolice" then
        self:SetWeaponHoldType("smg")
    end
    
    --ent:Fire( "GagEnable" )
    
    if ent:GetClass() == "npc_citizen" then
        --ent:Fire( "DisableWeaponPickup" )
    end
    
    local enemy = ent:GetEnemy()
    if not enemy then return end

    local dist = enemy:GetPos():Distance(ent:GetPos())

    if enemy and dist > 85 then
        --ent:SetSchedule(SCHED_CHASE_ENEMY)
    end

    if dist < 85 and (self.LastNPCAttack or 0) < CurTime() then
        local dmg = math.random(self.DamagePrimary - 3, self.DamagePrimary + 3)
        
        local tr = {}
        tr.start = ent:EyePos()
        tr.endpos = enemy.EyePos and enemy:EyePos() or enemy:GetPos()
        tr.filter = ent

        local trace = util.TraceLine(tr)

        if IsValid(trace.Entity) and trace.Entity == enemy then
            self.LastNPCAttack = CurTime() + self.AnimTime1

            ent:SetSchedule(SCHED_MELEE_ATTACK1)

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker(ent)
            dmginfo:SetInflictor(self)
            dmginfo:SetDamage(dmg)
            dmginfo:SetDamageForce(trace.Normal * dmg * 1)
            dmginfo:SetDamageType(self.DamageType)
            dmginfo:SetDamagePosition(trace.HitPos)
            trace.Entity:TakeDamageInfo(dmginfo)
        end
    end
end

function SWEP:GetNPCRestTimes()
	return self.AnimTime1, self.AnimTime1
end

function SWEP:GetCapabilities()
    if (self.NPCThinktime or 0) < CurTime() then self.NPCThinktime = CurTime() + 0.01 self:NPCThink() end
    return bit.bor( CAP_WEAPON_MELEE_ATTACK1, CAP_MOVE_GROUND )
end

function SWEP:SetupWeaponHoldTypeForAI( t )
	self.ActivityTranslateAI = {}
	if ( t == "melee" ) then
		self.ActivityTranslateAI [ ACT_IDLE ] 						= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_ANGRY ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_RELAXED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_STIMULATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AGITATED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_RELAXED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_STIMULATED ] 		= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_AGITATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1 ] 				= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1_LOW ]          = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK1 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK2 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_SPECIAL_ATTACK1 ] 			= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		
		self.ActivityTranslateAI [ ACT_RANGE_AIM_LOW ]              = ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_COVER_LOW ] 					= ACT_HL2MP_IDLE_KNIFE
		
		self.ActivityTranslateAI [ ACT_WALK ] 						= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM ]				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_RELAXED ] 				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_STIMULATED ] 			= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_AGITATED ] 				= ACT_HL2MP_WALK_KNIFE
		
		self.ActivityTranslateAI[ ACT_RUN_RELAXED ]			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_AGITATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH ] 				= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH_AIM ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN ] 						= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_RELAXED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_STIMULATED ] 		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_AGITATED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_MP_RUN ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_SMALL_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		self.ActivityTranslateAI [ ACT_BIG_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		
		return
	end
	
	if ( t == "smg" ) then
	
		self.ActivityTranslateAI [ ACT_IDLE ] 						= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_ANGRY ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_RELAXED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_STIMULATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AGITATED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_RELAXED ]			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_AGITATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH ] 				= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH_AIM ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN ] 						= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_RELAXED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_STIMULATED ] 		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_AGITATED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_MP_RUN ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_WALK ] 						= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM ]				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_RELAXED ] 				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_STIMULATED ] 			= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_AGITATED ] 				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK1 ] 				= ACT_MELEE_ATTACK_SWING
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1 ] 				= ACT_MELEE_ATTACK_SWING
		self.ActivityTranslateAI [ ACT_SPECIAL_ATTACK1 ] 			= ACT_RANGE_ATTACK_THROW
		self.ActivityTranslateAI [ ACT_SMALL_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		self.ActivityTranslateAI [ ACT_BIG_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		
		return
	end
	
	if ( t == "shotgun" ) then
		
		self.ActivityTranslateAI [ ACT_IDLE ] 						= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_ANGRY ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_RELAXED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_STIMULATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AGITATED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_RELAXED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_STIMULATED ] 		= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_AGITATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1 ] 				= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1_LOW ]          = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK1 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK2 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_SPECIAL_ATTACK1 ] 			= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		
		self.ActivityTranslateAI [ ACT_RANGE_AIM_LOW ]              = ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_COVER_LOW ] 					= ACT_HL2MP_IDLE_KNIFE
		
		self.ActivityTranslateAI [ ACT_WALK ] 						= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM ]				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_RELAXED ] 				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_STIMULATED ] 			= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_AGITATED ] 				= ACT_HL2MP_WALK_KNIFE
		
		self.ActivityTranslateAI[ ACT_RUN_RELAXED ]			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_AGITATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH ] 				= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH_AIM ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN ] 						= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_RELAXED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_STIMULATED ] 		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_AGITATED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_MP_RUN ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_SMALL_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		self.ActivityTranslateAI [ ACT_BIG_FLINCH ] 				= ACT_RANGE_ATTACK_PISTOL
		
		return
	end
	
	if ( t == "pistol") then 
		self.ActivityTranslateAI [ ACT_IDLE ] 						= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_ANGRY ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_RELAXED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_STIMULATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AGITATED ] 				= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_RELAXED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_STIMULATED ] 		= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_IDLE_AIM_AGITATED ] 			= ACT_HL2MP_IDLE_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1 ] 				= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_RANGE_ATTACK1_LOW ]          = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK1 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_MELEE_ATTACK2 ]              = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		self.ActivityTranslateAI [ ACT_SPECIAL_ATTACK1 ] 			= ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
		
		self.ActivityTranslateAI [ ACT_RANGE_AIM_LOW ]              = ACT_IDLE_SHOTGUN
		self.ActivityTranslateAI [ ACT_COVER_LOW ] 					= ACT_IDLE_SHOTGUN
		
		self.ActivityTranslateAI [ ACT_WALK ] 						= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM ]				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_RELAXED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_STIMULATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI[ ACT_WALK_AIM_AGITATED ]		= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_RELAXED ] 				= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_STIMULATED ] 			= ACT_HL2MP_WALK_KNIFE
		self.ActivityTranslateAI [ ACT_WALK_AGITATED ] 				= ACT_HL2MP_WALK_KNIFE
		
		self.ActivityTranslateAI[ ACT_RUN_RELAXED ]			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_STIMULATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI[ ACT_RUN_AGITATED ]		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH ] 				= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_CROUCH_AIM ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN ] 						= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_RELAXED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_STIMULATED ] 		= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM_AGITATED ] 			= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_RUN_AIM ] 					= ACT_HL2MP_RUN_KNIFE
		self.ActivityTranslateAI [ ACT_MP_RUN ] 					= ACT_HL2MP_RUN_KNIFE
		
		return
	end
end
