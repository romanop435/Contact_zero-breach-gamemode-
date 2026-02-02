if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Hammer"
SWEP.Instructions = "A regular household hammer, which has a blunt and a sharp side. Use it to block off paths or restrict someone from moving. R+LMB - Change mode, RMB - Nail"
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Ammo = "Nails"

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_hammer")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_hammer"
	SWEP.BounceWeaponIcon = false
end

SWEP.WorldModel = "models/weapons/w_jjife_t.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_hatchet.mdl"
SWEP.WorldModelExchange = "models/weapons/w_jjife_t.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""

SWEP.HoldType = "melee"

SWEP.HoldPos = Vector(-15,2,-4)
SWEP.HoldAng = Angle(-15,0,0)

SWEP.AttackTime = 0.3
SWEP.AnimTime1 = 1.2
SWEP.WaitTime1 = 0.9
SWEP.AttackLen1 = 45
SWEP.ViewPunch1 = Angle(1,1,0)

SWEP.Attack2Time = 0.1
SWEP.AnimTime2 = 0.7
SWEP.WaitTime2 = 0.7
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,5,-2)
SWEP.weaponAng = Angle(-5,-90,0)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.setlh = false
SWEP.setrh = true

SWEP.AttackHit = "Concrete.ImpactHard"
SWEP.Attack2Hit = "Concrete.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_solid_impact_soft1.wav"


SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 55
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0


SWEP.AttackPos = Vector(0,0,0)

SWEP.UnNailables={MAT_METAL,MAT_SAND,MAT_SLOSH,MAT_GLASS}

game.AddDecal("hmcd_jackanail","decals/mat_jack_hmcd_nailhead")

function hgCheckBindObjects(ent1)
	if not ent1.Nails then return end

    return ( ent1.Nails and ent1.Nails[0] and #ent1.Nails[0]) or 0
end

function SWEP:CanPrimaryAttack()
    return not hg.KeyDown(self:GetOwner(), IN_RELOAD)
end

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 10

function SWEP:ThinkAdd()
    local ply = self:GetOwner()
	
    if self:GetNetVar("AttackMode",1) == 1 then
        self.DamagePrimary = 9
        self.DamageType = DMG_CLUB
        self.weaponPos = Vector(0,4,-3)
        self.weaponAng = Angle(-5,-90,0)

		self.PenetrationPrimary = 2
		self.MaxPenLen = 1
		self.PainMultiplier = 1.65
		self.PenetrationSizePrimary = 1
		self.StaminaPrimary = 17
    else
        self.DamagePrimary = 8
        self.DamageType = DMG_SLASH
        self.weaponPos = Vector(-0.5,-3,-6.5)
        self.weaponAng = Angle(-55,90,0)

		self.PenetrationPrimary = 4
		self.PainMultiplier = 1
		self.MaxPenLen = 4
		self.PenetrationSizePrimary = 0.5
		self.StaminaPrimary = 20
    end

    if CLIENT then return end

    if IsValid(ply) then
        if hg.KeyDown(ply, IN_ATTACK) and hg.KeyDown(ply, IN_RELOAD) then
            if not self.setmode then
                local int = self:GetNetVar("AttackMode",1)
                
                self:SetNetVar("AttackMode",int >= 2 and 1 or (int + 1))
                self.setmode = true
            end
        else
            self.setmode = false
        end
    end
end

local function BindObjects(ent1,pos1,ent2,pos2,power,bone1,bone2)
	ent1.Nails = ent1.Nails or {}
	ent2.Nails = ent2.Nails or {}
	
	if not ent1.Nails[bone1] then
		local weld = (!ent1:IsRagdoll() and !ent2:IsRagdoll() and constraint.Ballsocket(ent1,ent2,bone1 or 0,bone2 or 0,ent1:WorldToLocal(pos1),(500+1*100)*5) ) or constraint.Weld(ent1,ent2,bone1 or 0,bone2 or 0,(500+1*100)*15,false,false)
		if weld then
    		ent1.Nails[bone1] = {weld,1}
			weld:CallOnRemove("removefromtbl",function() ent1.Nails[bone1] = nil end)
		end
	else
		if !ent1:IsRagdoll() and !ent2:IsRagdoll() then
			local weld = (!ent1:IsRagdoll() and !ent2:IsRagdoll() and constraint.Ballsocket(ent1,ent2,bone1 or 0,bone2 or 0,ent1:WorldToLocal(pos1),(500+1*100)*5) ) or false
		end
		ent1.Nails[bone1][2] = ent1.Nails[bone1][2] + 1
	end

	if not ent2.Nails[bone2] then
		local weld = (!ent1:IsRagdoll() and !ent2:IsRagdoll() and constraint.Ballsocket(ent1,ent2,bone1 or 0,bone2 or 0,ent2:WorldToLocal(pos2),(500+1*100)*5) ) or constraint.Weld(ent1,ent2,bone1 or 0,bone2 or 0,(500+1*100)*15,false,false)
		if weld then
    		ent2.Nails[bone2] = {weld,1}
			weld:CallOnRemove("removefromtbl",function() ent2.Nails[bone2] = nil end)
		end
	else
		if !ent1:IsRagdoll() and !ent2:IsRagdoll() then
			local weld = (!ent1:IsRagdoll() and !ent2:IsRagdoll() and constraint.Ballsocket(ent1,ent2,bone1 or 0,bone2 or 0,ent2:WorldToLocal(pos2),(500+1*100)*5) ) or false
		end
		ent2.Nails[bone2][2] = ent2.Nails[bone2][2] + 1
	end
    
	return ent1:IsWorld() and ((ent2.Nails[bone2] and ent2.Nails[bone2][2]) or 1) or ((ent1.Nails[bone1] and ent1.Nails[bone1][2]) or 1)
end

if SERVER then
	hook.Add("Should Fake Up","NailTaped",function(ply)
		if ply and IsValid(ply.FakeRagdoll) then
			local Nails = ply.FakeRagdoll.Nails

			if Nails then
				for i,tbl in pairs(Nails) do
					if tbl[2] > 0 then
						tbl[2] = tbl[2] - 0.05
						if math.random(3) == 1 then
							local dmginfo = DamageInfo()
							dmginfo:SetDamage(5)
							dmginfo:SetAttacker(ply)
							dmginfo:SetInflictor(ply)
							dmginfo:SetDamagePosition(ply.FakeRagdoll:GetPhysicsObjectNum(tbl[1]:GetTable()["Bone1"]):GetPos())
							dmginfo:SetDamageType(DMG_SLASH)
							dmginfo:SetDamageForce(vector_up)
							ply.Penetration = 5
							ply.FakeRagdoll:TakeDamageInfo(dmginfo)
							ply.Penetration = nil
						end
						--ply.FakeRagdoll:EmitSound("tape_friction"..math.random(3)..".mp3",65)
						if tbl[2] <= 0 then
							if IsValid(Nails[i][1]) then
								Nails[i][1]:Remove()
								Nails[i][1] = nil
							end
							Nails[i] = nil
						end
					end
				end

				if table.Count(Nails) > 0 then
					ply.fakecd = CurTime() + 1
					return false
				end
			end
		end
	end)
end

function SWEP:SprayDecals()
    local Owner = self:GetOwner()
	local Tr=util.QuickTrace(Owner:GetShootPos(),Owner:GetAimVector()*70,{Owner})
	util.Decal("hmcd_jackanail",Tr.HitPos+Tr.HitNormal,Tr.HitPos-Tr.HitNormal)

	local Tr2=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(0,0,.15))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr2.HitPos+Tr2.HitNormal,Tr2.HitPos-Tr2.HitNormal)

	local Tr3=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(0,0,-.15))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr3.HitPos+Tr3.HitNormal,Tr3.HitPos-Tr3.HitNormal)

	local Tr4=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(0,.15,0))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr4.HitPos+Tr4.HitNormal,Tr4.HitPos-Tr4.HitNormal)

	local Tr5=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(0,-.15,0))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr5.HitPos+Tr5.HitNormal,Tr5.HitPos-Tr5.HitNormal)

	local Tr6=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(.15,0,0))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr6.HitPos+Tr6.HitNormal,Tr6.HitPos-Tr6.HitNormal)

	local Tr7=util.QuickTrace(Owner:GetShootPos(),(Owner:GetAimVector()+Vector(-.15,0,0))*70,{Owner})
	util.Decal("hmcd_jackanail",Tr7.HitPos+Tr7.HitNormal,Tr7.HitPos-Tr7.HitNormal)
end

function SWEP:InitAdd()
    if CLIENT then return end
    self.AmmoGive = 3
end

function SWEP:OwnerChanged()
    if IsValid(self:GetOwner()) and SERVER then
        self:GetOwner():GiveAmmo(self.AmmoGive,self.Ammo,true)
        self.AmmoGive = 0
    end
end

function SWEP:CanNail(Tr)
    local Owner = self:GetOwner()
	return (Owner:GetAmmoCount(self.Ammo)>0) and (Tr.Hit) and (Tr.Entity) and ((IsValid(Tr.Entity)) or (Tr.Entity:IsWorld())) and not ((Tr.Entity:IsPlayer())or(Tr.Entity:IsNPC())) and not (table.HasValue(self.UnNailables,Tr.MatType))
end

function DoorIsOpen( door )
	
	return !door:GetInternalVariable("m_bLocked")

end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	if self:GetLastAttack() + 3 > CurTime() then return end
	local Tr = hg.eyeTrace(self:GetOwner())
    
	if self:GetNetVar("AttackMode",1) == 2 then
		if self:CutDuct() then return end

		if ((Tr.Entity.Nails and Tr.Entity.Nails[Tr.PhysicsBone]) or Tr.Entity.LockedDoorNail) and not self.pulling then
			self:GetOwner():EmitSound("nail_pull.mp3",65,100,1,CHAN_AUTO)
            self.pulling = true
			timer.Simple(2,function()
                self.pulling = false
				if Tr.Entity.LockedDoorNail then
					if !Tr.Entity.LockedDoor and !Tr.Entity.LockedDoorMap then Tr.Entity:Fire("unlock","",0) end
					Tr.Entity.LockedDoorNail = nil
					self:GetOwner():SetAmmo(self:GetOwner():GetAmmoCount(self.Ammo)+3,self.Ammo)
					return
				end
				local tbl = Tr.Entity.Nails[Tr.PhysicsBone]
				if tbl then
					tbl[2] = tbl[2] - 1

					self:GetOwner():SetAmmo(self:GetOwner():GetAmmoCount(self.Ammo)+1,self.Ammo)

					if tbl[2] > 0 then return end

					if IsValid(tbl[1]) then
						tbl[1]:Remove()
						tbl[1] = nil
					end

					Tr.Entity.Nails[Tr.PhysicsBone] = nil
				end
			end)
		end
	else
		local Owner = self:GetOwner()
		if Owner:KeyDown(IN_SPEED) then return end
        
		if not ((Owner:GetAmmoCount(self.Ammo)) > 0) then
			return
		end
        
		local AimVec = Owner:GetAimVector()
		local Tr = hg.eyeTrace(self:GetOwner())

		if(self:CanNail(Tr))then
			
			local NewTr,NewEnt=util.QuickTrace(Tr.HitPos,AimVec*10,{Owner,Tr.Entity}),nil

			if(self:CanNail(NewTr))then
				
				if not NewTr.HitSky then NewEnt = NewTr.Entity end
				if ( NewEnt ) and ((IsValid(NewEnt)) or (NewEnt:IsWorld())) and not ((NewEnt:IsPlayer()) or (NewEnt:IsNPC()) or (NewEnt==Tr.Entity)) then
					if hgIsDoor(Tr.Entity) then
						if (Owner:GetAmmoCount(self.Ammo)) > 2 then
							if !DoorIsOpen(Tr.Entity) then
								if !Tr.Entity.LockedDoorNail then
									Tr.Entity.LockedDoorMap = true
								end
							else
								Tr.Entity.LockedDoorMap = false
							end
							Tr.Entity:Fire("lock","",0)
							Tr.Entity.LockedDoorNail = true
							Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo)-3,self.Ammo)

							sound.Play("snd_jack_hmcd_hammerhit.wav",Tr.HitPos,65,math.random(90,110))
							self:SprayDecals()
                            
							Owner:PrintMessage(HUD_PRINTCENTER,"Door Sealed")
							Owner:ViewPunch(Angle(3,0,0))
							Owner:SetAnimation(PLAYER_ATTACK1)
						else
							Owner:PrintMessage(HUD_PRINTCENTER,"Need at least 3 nails to seal door.")
						end

					else
						if Tr.Entity:IsRagdoll() then
							local DmgInfo = DamageInfo()
							DmgInfo:SetDamage(15)
							DmgInfo:SetDamageType(DMG_SLASH)
							DmgInfo:SetDamageForce(AimVec * 5)
							DmgInfo:SetDamagePosition(Tr.HitPos)
							DmgInfo:SetInflictor(self)
							DmgInfo:SetAttacker(self:GetOwner())
							self.Penetration = 15
							Tr.Entity:TakeDamageInfo(DmgInfo)
							self.Penetration = nil
						end

						if NewEnt:IsRagdoll() then
							local DmgInfo = DamageInfo()
							DmgInfo:SetDamage(15)
							DmgInfo:SetDamageType(DMG_SLASH)
							DmgInfo:SetDamageForce(AimVec * 5)
							DmgInfo:SetDamagePosition(NewTr.HitPos)
							DmgInfo:SetInflictor(self)
							DmgInfo:SetAttacker(self:GetOwner())
							self.Penetration = 15
							NewEnt:TakeDamageInfo(DmgInfo)
							self.Penetration = nil
						end

						local Strength, Weld = BindObjects(Tr.Entity, Tr.HitPos, NewEnt, NewTr.HitPos, 3.5, Tr.PhysicsBone or 0, NewTr.PhysicsBone or 0)
						--print(Tr.Entity,Weld)
						if Weld or Weld == nil then
							Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo)-1,self.Ammo)
						end

						sound.Play("snd_jack_hmcd_hammerhit.wav",Tr.HitPos,65,math.random(90,110))
						util.Decal("hmcd_jackanail",Tr.HitPos+Tr.HitNormal,Tr.HitPos-Tr.HitNormal)

						--Owner:PrintMessage(HUD_PRINTCENTER,"Bond strength: "..tostring(Strength))
						Owner:Notify("Bond strength: " .. tostring(Strength))
						Owner:ViewPunch(Angle(3,0,0))
						self:PlayAnim("attack",0.6,false,nil,false,true)
					end
				end
			end
			self:SetNextSecondaryFire(CurTime()+2.5)
			self:SetNextPrimaryFire(CurTime()+2.5)
		end
	end
end
