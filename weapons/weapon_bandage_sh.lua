if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_base"
SWEP.PrintName = "Bandage"
SWEP.Instructions = "A wad of gauze bandage, can help stop light bleeding. Since the bandage is not in its packaging, there is little chance that it is sterilized. RMB to use on someone else."
SWEP.Category = "Medicine"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/bandages.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_bandage")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_bandage.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.ScrappersSlot = "Medicine"

SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -3.5, 0)
SWEP.offsetAng = Angle(90, 90, 0)

modelshuy = modelshuy or {}

function SWEP:DrawWorldModel()
	if not IsValid(self:GetOwner()) then
		self:DrawWorldModel2()
	end
end

function SWEP:DrawWorldModel2(nodraw)
	local mdl = self.Model or self.WorldModel
	modelshuy[mdl] = IsValid(modelshuy[mdl]) and modelshuy[mdl] or ClientsideModel(mdl)
	modelshuy[mdl]:SetNoDraw(true)
	local WorldModel = modelshuy[mdl]
	local owner = self:GetOwner()
	owner = hg.GetCurrentCharacter(owner)
	if not IsValid(WorldModel) then return end

	WorldModel:SetModelScale(self.ModelScale or 1)
	
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

	WorldModel:SetupBones()
	if not nodraw then WorldModel:DrawModel() end
end

function SWEP:OnRemove()
	if SERVER then return end
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float",0,"Holding")
end

local bone, name
function SWEP:BoneSet(lookup_name, vec, ang)
    if IsValid(self:GetOwner()) and !self:GetOwner():IsPlayer() then return end
	hg.bone.Set(self:GetOwner(), lookup_name, vec, ang, "bandage", 0.1)
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local aimvec = self:GetOwner():GetAimVector()
	local hold = self:GetHolding()
    self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 4, -30 + hold / 2 + 20 * aimvec[3], 5 - hold / 3.5))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 10, -hold / 2.5, 35 -hold/1.5))
end

SWEP.usetime = 2
function SWEP:Think()
	self:SetHold(self.HoldType)
	self:SetHolding(math.max(self:GetHolding() - 4,0))
	
	--[[if self.modeValuesdef[self.mode][2] then
		local time = CurTime()
		local ply = self:GetOwner()
		local entownr = hg.GetCurrentCharacter(ply)

		if not self.attack and ply:KeyPressed(IN_ATTACK) then
			self.startedheal = CurTime()
			self.healsubject = ply
			self.attack = 1
		end

		if self.attack == 1 and ply:KeyReleased(IN_ATTACK) then
			self.endheal = CurTime()
		end

		if not self.attack and ply:KeyPressed(IN_ATTACK2) then
			self.startedheal = CurTime()
			self.healsubject = hg.eyeTrace(self:GetOwner()).Entity
			self.attack = 2
		end

		if self.attack == 2 and ply:KeyReleased(IN_ATTACK2) then
			self.endheal = CurTime()
		end

		if self.startheal and (self.endheal or (self.startheal + self.usetime <= CurTime())) then
			self.endheal = self.endheal or self.startheal + self.usetime
			local usedmuch = (self.endheal - self.startheal) / self.usetime

			self:Heal(self.healsubject, self.mode, usedmuch)
			self.startheal = nil 
			self.endheal = nil 
			self.attack = nil 
			self.healsubject = nil
		end
	end--]]
end

function SWEP:PrimaryAttack()
	//self:SetHolding(math.min(self:GetHolding() + 9, 100))
	if SERVER then--and not self.modeValuesdef[self.mode][2] then
		//if self:GetHolding() < 100 then return end

		self.healbuddy = self:GetOwner()
		local done = self:Heal(self.healbuddy, self.mode)
		
		if(done and self.PostHeal)then
			self:PostHeal(self.healbuddy, self.mode)
		end
		
		self:SetNetVar("modeValues",self.modeValues)
	end
end

if CLIENT then
	surface.CreateFont("huyhuy", {
		font = "CloseCaption_Normal", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = true,
		size = ScreenScale(15),
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		strikeout = false,
		shadow = false,
		outline = false,
	})
	

	local colWhite = Color(255, 255, 255, 255)
	local colGray = Color(200, 200, 200, 200)
	local lerpthing = 1
	local colBrown = Color(40,40,40)
	SWEP.showstats = true
	SWEP.ofsV = Vector(10,-2,1)
	SWEP.ofsA = Angle(-90,-40,270)
	local vector_one = Vector(1,1,1)
	function SWEP:DrawHUD()
		local owner = self:GetOwner()
		if !owner:IsPlayer() then return end
		if GetViewEntity() ~= owner then return end
		if owner:InVehicle() then return end
		if not IsValid(modelshuy[self.Model or self.WorldModel]) then return end
		local Tr = hg.eyeTrace(owner)
		if !Tr then return end
		local Size = math.max(math.min(1 - Tr.Fraction, 0.5), 0.1)
		local x, y = Tr.HitPos:ToScreen().x, Tr.HitPos:ToScreen().y
		if Tr.Hit then
			lerpthing = Lerp(0.1, lerpthing, 1)
			colWhite.a = 255 * Size
			surface.SetDrawColor(colGray)
			draw.NoTexture()
			surface.SetDrawColor(colWhite)
			draw.NoTexture()
			surface.DrawRect(x - 25 * lerpthing, y - 2.5, 50 * lerpthing, 5)
			surface.DrawRect(x - 2.5, y - 25 * lerpthing, 5, 50 * lerpthing)
			local col = Tr.Entity:GetPlayerColor():ToColor()
			local coloutline = (col.r < 50 and col.g < 50 and col.b < 50) and Color(255,255,255) or Color(0,0,0)
			coloutline.a = 255 * Size * 2
			draw.DrawText(Tr.Entity:IsPlayer() and Tr.Entity:GetPlayerName() or Tr.Entity:IsRagdoll() and Tr.Entity:GetPlayerName() or "", "HomigradFontLarge", x + 1, y + 31, coloutline, TEXT_ALIGN_CENTER)
			draw.DrawText(Tr.Entity:IsPlayer() and Tr.Entity:GetPlayerName() or Tr.Entity:IsRagdoll() and Tr.Entity:GetPlayerName() or "", "HomigradFontLarge", x, y + 30, col, TEXT_ALIGN_CENTER)
		end
		local mdl = modelshuy[self.Model or self.WorldModel]
		self:DrawWorldModel2(true)
		local p,a = mdl:GetPos(), mdl:GetAngles()
		local pos,ang = LocalToWorld(self.ofsV,self.ofsA,p,a)
		if self.showstats and self.modeValues and istable(self.modeValues) then
			//cam.Start3D()
				//cam.Start3D2D(pos,ang,0.01)
				render.PushFilterMag( TEXFILTER.LINEAR )
				render.PushFilterMin( TEXFILTER.LINEAR )
				local m = Matrix()
				m:Translate( Vector(  ScrW() / 2-ScreenScale(60), ScrH() / 2 + ScreenScaleH(125), 0 ) )
				m:Scale( vector_one * 0.5 )

				cam.PushModelMatrix( m, true )
					for i, val in pairs(self.modeValues) do
						if not isnumber(i) or not val or not self.modeValuesdef or not self.modeValuesdef[i][1] then continue end
						local val = math.Round(val / self.modeValuesdef[i][1] * 100)
						local x,y = 0, i * ScrH() / 20
						local reveal = 1//math.Clamp(lply:EyeAngles()[1] / 90 - 0.25, 0, 1) * 4 / 3
						colBrown.a = reveal * 185
						draw.RoundedBox(2,x,y,x + ScreenScale(210) + ScrW() / 10,ScrH() / 25 + (#self.modeValues > 0 and 0 or 0),colBrown)
						surface.SetFont("ZCity_Small")
						surface.SetTextPos(x,y)
						surface.SetTextColor(255,255,255,255 * reveal)
						local txt = string.NiceName(tostring(self.modeNames[i]))
						local w, h = surface.GetTextSize(txt)
						--surface.DrawText(tostring(self.modeNames[i]))
						colBrown.a = reveal * 255
						draw.SimpleTextOutlined(txt, "ZCity_Small", x, y, Color(255,i == self.mode and 0 or 255,i == self.mode and 0 or 255, 255 * reveal), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1.5, colBrown)
					
						surface.SetDrawColor(0,100,0,255 * reveal)
						surface.DrawRect(x + ScreenScale(210),y,ScrW() / 10 * val / 100,ScrH() / 25)
						surface.SetDrawColor(0,0,0,255 * reveal)
						surface.DrawOutlinedRect(x + ScreenScale(210),y,ScrW() / 10,ScrH() / 25, 4)
					end
				cam.PopModelMatrix()

				render.PopFilterMag()
				render.PopFilterMin()
				//cam.End3D2D()
			//cam.End3D()
		end
	end
end

SWEP.mode = 1
SWEP.modes = 1
SWEP.modeNames = {
	[1] = "bandaging"
}

function SWEP:InitializeAdd()
	self.ModelScale = 0.9
end

SWEP.DeploySnd = "physics/body/body_medium_impact_soft5.wav"
SWEP.HolsterSnd = ""
SWEP.FallSnd = "physics/body/body_medium_impact_soft5.wav"

function SWEP:Initialize()
	self:SetHold(self.HoldType)
	self.modeValues = {
		[1] = 40,
	}

	util.PrecacheSound(self.DeploySnd)
	util.PrecacheSound(self.HolsterSnd)
	util.PrecacheSound(self.FallSnd)
	util.PrecacheSound("snd_jack_hmcd_needleprick.wav")
	
	self:AddCallback("PhysicsCollide",function(ent,data)
		if data.Speed > 200 then
			ent:EmitSound(self.FallSnd or self.DeploySnd,65,math.random(90,110))
		end
	end)

	self:InitializeAdd()
end

SWEP.modeValuesdef = {
	[1] = {40,true},
}

function SWEP:GetInfo()
	if not IsValid(self) then
		local modevalues = {}
		for i,val in ipairs(self.modeValuesdef) do
			modevalues[i] = istable(val) and val[1] or val
		end
		return modevalues
	end
	return self.modeValues
end

function SWEP:SetInfo(info)
	self:SetNetVar("modeValues",info)
	self.modeValues = info
end

function SWEP:SecondaryAttack()
	--self:SetHolding(math.min(self:GetHolding() + 9, 100))
	if SERVER then
		if IsValid(self:GetNWEntity("fakeGun")) then return end
		local ent = hg.eyeTrace(self:GetOwner()).Entity
		self.healbuddy = ent
		local done = self:Heal(self.healbuddy, self.mode)

		if(done and self.PostHeal)then
			self:PostHeal(self.healbuddy, self.mode)
		end		

		self:SetNetVar("modeValues",self.modeValues)
	end
end

if SERVER then
	util.AddNetworkString("select_mode")
else
	net.Receive("select_mode",function()
		net.ReadEntity().mode = net.ReadInt(4)
	end)
end

function SWEP:Reload()
	if SERVER and self:GetOwner():KeyPressed(IN_RELOAD) and #self.modeValuesdef > 1 then
		self.mode = ((self.mode + 1) > self.modes) and 1 or (self.mode + 1)
		--self:GetOwner():ChatPrint("You have chosen the " .. self.modeNames[self.mode] .. " mode")
		net.Start("select_mode")
		net.WriteEntity(self)
		net.WriteInt(self.mode,4)
		net.Broadcast()
	end
end
if CLIENT then
	hook.Add("OnNetVarSet","bandage-net-var",function(index,key,var)
		if key == "modeValues" then
			local ent = Entity(index)

			ent.modeValues = var
		end
	end)
end
-- WoundTBL = {dmgBlood / 2, localPos, localAng, bone, time}
SWEP.ShouldDeleteOnFullUse = true
if SERVER then
	function SWEP:Bandage(ent, bone)
		-- Переделано под новый organism (кровотечение хранится в organism state, без ent.organism)
		local owner = self:GetOwner()
		if not IsValid(owner) then return false end

		-- Разрешаем бинтовать игроков и их ragdoll (если есть hg.RagdollOwner)
		local target = ent
		if IsValid(target) and target:IsRagdoll() and hg and hg.RagdollOwner then
			local ro = hg.RagdollOwner(target)
			if IsValid(ro) and ro:IsPlayer() then
				target = ro
			end
		end

		if not IsValid(target) or not target:IsPlayer() then return false end
		if not organism or not organism.Get then return false end

		local st = organism.Get(target)
		if not st then return false end

		local charges = self.modeValues and self.modeValues[1] or 0
		if charges <= 0 then return false end

		local bleed = st.bleed or 0
		if bleed <= 0.5 then return false end

		-- Расход “материала” бинта: 20 единиц за успешную перевязку (можешь поменять)
		local cost = math.min(charges, 20)
		self.modeValues[1] = math.max(charges - cost, 0)

		-- Бинт: полностью останавливает лёгкое кровотечение, сильное — сильно режет.
		if bleed <= 120 then
			st.bleed = 0
		else
			if organism.StopBleeding then
				organism.StopBleeding(target, 0.65) -- -65% bleed
			else
				st.bleed = math.max(st.bleed * 0.35, 0)
			end
		end

		-- Небольшое облегчение боли (опционально)
		if organism.AddPain then
			organism.AddPain(target, -5)
		end

		owner:EmitSound("snd_jack_hmcd_bandage.wav", 60, math.random(95, 105))
		return true
	end

	function SWEP:Heal(ent, mode, bone)
		local done = self:Bandage(ent, bone)

		if self.modeValues and self.modeValues[1] <= 0 and self.ShouldDeleteOnFullUse then
			if IsValid(self:GetOwner()) then
				self:GetOwner():SelectWeapon("weapon_hands_sh")
			end
			self:Remove()
		end

		return done
	end

	function SWEP:PostHeal(ent, mode)
		local org = ent.organism
		if not zb then return end 
		if not zb.modes then return end
		local mode_hmcd = zb.modes["hmcd"]
		
		if(org and IsValid(org.owner) and mode_hmcd)then
			local organism_owner = org.owner
			
			if(organism_owner.SubRole == "traitor_chemist")then
				if(self.FoodModelsKCNNeutralizers and self.FoodModelsKCNNeutralizers[self:GetModel()])then
					self.ConsumePoisoned_KCN = math.max(self.ConsumePoisoned_KCN or 0 - self.FoodModelsKCNNeutralizers[self:GetModel()], 0)
				end
				
				if((self.ConsumePoisoned_KCN or 0) > 0)then
					local ply_kcn_accumulated = mode_hmcd.AddChemicalToPlayer(organism_owner, "KCN", 50 * (self.ConsumePoisoned_KCN or 0))
					
					if(ply_kcn_accumulated > 100)then
						self:PoisonKCNOrganism(org)
					end
					
					mode_hmcd.NetworkChemicalResistanceOfPlayer(organism_owner)
					
					organism_owner.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			else
				if(self.FoodModelsKCNNeutralizers and self.FoodModelsKCNNeutralizers[self:GetModel()])then
					self.ConsumePoisoned_KCN = math.max(self.ConsumePoisoned_KCN or 0 - self.FoodModelsKCNNeutralizers[self:GetModel()], 0)
				end
				
				if((self.ConsumePoisoned_KCN or 0) > 0)then
					self:PoisonKCNOrganism(org)
				end
			end
		end
	end
	
	function SWEP:PoisonKCNOrganism(org)
		if(org and self.ConsumePoisoned_KCN)then
			org.Poison_KCN = org.Poison_KCN or {}
			org.Poison_KCN.StartTime = org.Poison_KCN.StartTime or CurTime()
			org.Poison_KCN.Potency = (org.Poison_KCN.Potency or 0) + self.ConsumePoisoned_KCN
			self.ConsumePoisoned_KCN = nil
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
		local ent = ents.Create("prop_physics")
		local physbonelh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_L_Hand")
		local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
		local lh = ragdoll:GetPhysicsObjectNum(physbonelh)
		local rh = ragdoll:GetPhysicsObjectNum(physbonerh)
		--rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
		--rh:SetAngles(self:GetOwner():EyeAngles() + Angle(0, 0, -90))
		--lh:SetPos(rh:GetPos())
		ent:SetModel(self.WorldModel)
		ent:SetPos(rh:GetPos())
		ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
		ent:Spawn()
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetOwner(ragdoll)
		ent:GetPhysicsObject():SetMass(0)
		ent:SetModel(self.Model or self.WorldModel)
		ent:SetNoDraw(true)
		ent.dontPickup = true
		ent.fakeOwner = self
		ragdoll:DeleteOnRemove(ent)
		ragdoll.fakeGun = ent
		if IsValid(ragdoll.ConsRH) then ragdoll.ConsRH:Remove() end
		self:SetFakeGun(ent)
		ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)
		local vec = Vector(0, 0, 0)
		vec:Set(self.RHandPos or vector_origin)
		vec:Rotate(ent:GetAngles())
		--rh:SetPos(ent:GetPos() + vec)
		constraint.Weld( ragdoll, ent, physbonerh, 0, 0, false, false )
	end

	function SWEP:RagdollFunc(pos, angles, ragdoll)
		local physbonelh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_L_Hand")
		local physbonerh = GetPhysBoneNum(ragdoll,"ValveBiped.Bip01_R_Hand")
		shadowControl = shadowControl or hg.ShadowControl
		local fakeGun = ragdoll.fakeGun
		pos:Add(angles:Forward() * 20)
		--shadowControl(fakeGun, 0, 0.001, angles, 100, 90, pos, 1000, 900)
		angles:RotateAroundAxis(angles:Forward(), 180)
		shadowControl(ragdoll, 7, 0.001, angles, 500, 30, pos, 500, 50)
	end
end


hg.TourniquetGuys = hg.TourniquetGuys or {}

if SERVER then
	util.AddNetworkString("send_tourniquets")
	function SWEP:Tourniquet(ent, bone)
		local org = ent.organism
		if not org then return end
		if #org.arterialwounds > 0 then
			local ent = org.isPly and org.owner or ent
			ent.tourniquets = ent.tourniquets or {}

			local pw
			
			if not bone then
				for i,wound in pairs(org.arterialwounds) do
					if wound[7] != "arteria" then pw = i break end
				end
			else
				for i,wound in pairs(org.arterialwounds) do
					if ent:GetBoneName(wound[4]) == bone then pw = i break end
				end
			end
			
			pw = pw or math.random(#org.arterialwounds)

			local wound = org.arterialwounds[pw]
			if not wound then return false end
			
			ent.tourniquets[#ent.tourniquets + 1] = {wound[2], wound[3], wound[4]}
			org[wound[7]] = 0

			if wound[7] == "arteria" then org.o2.regen = 0 end

			table.remove(org.arterialwounds,pw)

			org.owner:SetNetVar("arterialwounds",org.arterialwounds)

			ent:SetNetVar("Tourniquets",ent.tourniquets)
			if IsValid(ent.FakeRagdoll) then
				ent.FakeRagdoll:SetNetVar("Tourniquets",ent.tourniquets)
			end
			
			if not table.HasValue(hg.TourniquetGuys,ent) then
				table.insert(hg.TourniquetGuys,ent)
			end

			for i,ent in ipairs(hg.TourniquetGuys) do
				if not IsValid(ent) or not ent.tourniquets or table.IsEmpty(ent.tourniquets) then table.remove(hg.TourniquetGuys,i) end
			end

			SetNetVar("TourniquetGuys",hg.TourniquetGuys)

			self:GetOwner():EmitSound("snd_jack_hmcd_bandage.wav", 65, math.random(95, 105))
			return true
		end
	end

	hook.Add("Player Spawn", "remove-tourniquets", function(ply)
		if OverrideSpawn then return end
		ply:SetNetVar("Tourniquets",{})
		ply.tourniquets = {}
	end)

	hook.Add("Player Death", "remove-tourniquetshuy", function(ply)
		if IsValid(ply.FakeRagdoll) then
			ply.FakeRagdoll.tourniquets = table.Copy(ply.tourniquets)
			ply.FakeRagdoll:SetNetVar("Tourniquets",ply.FakeRagdoll.tourniquets)
		end
		ply:SetNetVar("Tourniquets",{})
		ply.tourniquets = {}
	end)

	hook.Add("Player Spawn", "remove-bandages", function(ply)
		if OverrideSpawn then return end
		ply:SetNetVar("bandaged_limbs",{})
		ply.bandaged_limbs = {}
	end)

	hook.Add("Player Death", "remove-bandageshuy", function(ply)
		if IsValid(ply.FakeRagdoll) then
			ply.FakeRagdoll.bandaged_limbs = table.Copy(ply.bandaged_limbs)
			ply.FakeRagdoll:SetNetVar("bandaged_limbs",ply:GetNetVar("bandaged_limbs",ply.FakeRagdoll.bandaged_limbs))
		end
		ply:SetNetVar("bandaged_limbs",{})
		ply.bandaged_limbs = {}
	end)
	

	hook.Add("Fake", "rtourniquetsss", function(ply,ragdoll)
		if not IsValid(ragdoll) then return end	
		
		ragdoll.tourniquets = table.Copy(ply.tourniquets)
		ply:SetNetVar("Tourniquets",ply.tourniquets)
		ragdoll:SetNetVar("Tourniquets",ragdoll.tourniquets)
	end)

	hook.Add("Fake", "bandages-setfake", function(ply,ragdoll)
		if not IsValid(ragdoll) then return end	
		
		ragdoll.bandaged_limbs = table.Copy(ply.bandaged_limbs)
		ply:SetNetVar("bandaged_limbs",ply.bandaged_limbs)
		ragdoll:SetNetVar("bandaged_limbs",ragdoll.bandaged_limbs)
	end)
	
else
	local boneScale = {
		["ValveBiped.Bip01_Head1"] = 1,
		["ValveBiped.Bip01_Neck1"] = 0.8,
		["ValveBiped.Bip01_L_UpperArm"] = 0.9,
		["ValveBiped.Bip01_L_Forearm"] = 0.8,
		["ValveBiped.Bip01_R_UpperArm"] = 0.9,
		["ValveBiped.Bip01_R_Forearm"] = 0.8,
		["ValveBiped.Bip01_L_Thigh"] = 1.4,
		["ValveBiped.Bip01_L_Calf"] = 1.1,
		["ValveBiped.Bip01_R_Thigh"] = 1.2,
		["ValveBiped.Bip01_R_Calf"] = 1.2,
	}

	local boneOffset = {
		["ValveBiped.Bip01_Neck1"] = {Vector(0, -1.5, -2), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_UpperArm"] = {Vector(5, -0.5, -3.2), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_Forearm"] = {Vector(5, -0.1, -2.8), Angle(90, 90, 90)},
		["ValveBiped.Bip01_R_UpperArm"] = {Vector(7, -0.1, -1.5), Angle(90, 90, 90)},
		["ValveBiped.Bip01_R_Forearm"] = {Vector(5, -0.2, -1.5), Angle(90, 90, 90)},
		["ValveBiped.Bip01_L_Thigh"] = {Vector(13, 0, -4.2), Angle(90, -90, 90)},
		["ValveBiped.Bip01_L_Calf"] = {Vector(5, 0.2, -3.2), Angle(90, -90, 90)},
		["ValveBiped.Bip01_R_Thigh"] = {Vector(13, -0.3, -2.6), Angle(90, -90, 90)},
		["ValveBiped.Bip01_R_Calf"] = {Vector(5, 0.3, -3.1), Angle(90, -90, 90)},
	}

	local function remove_tourniquets(ent)
		if not ent.tourniquetsM then return end
		
		for i,model in pairs(ent.tourniquetsM) do
			if IsValid(model) then
				model:Remove()
				ent.tourniquetsM[i] = nil
			end
		end
	end

	hook.Add("OnNetVarSet","tourniquetnisser",function(index, key, var)
		if not IsValid(Entity(index)) then return end
		if key == "Tourniquets" then
			local ent = Entity(index)
			
			remove_tourniquets(ent)
			
			ent.tourniquets = var
			
			ent:CallOnRemove("remove_tourniquets",function()
				remove_tourniquets(ent)
			end)
		end
	end)

	hook.Add("Fake","gsdgsdgsdgsdsdgTURNIKET",function(ply,ragdoll)
		remove_tourniquets(ply)
		if IsValid(ragdoll) then
			remove_tourniquets(ragdoll)
		end
	end)

	hook.Add("Player Death","huyhuyhuyFuckyou",function(ply)
		remove_tourniquets(ply)
	end)

	--hook.Add("PostDrawPlayerRagdoll", "draw_tourniquets", function(ent,ply)
	function hg.RenderTourniquets(ent, ply)
		if not ply.tourniquets then return end
		if table.IsEmpty(ply.tourniquets) then return end

		for i, wound in ipairs(ply.tourniquets) do
			ply.tourniquetsM = ply.tourniquetsM or {}
			ply.tourniquetsM[i] = IsValid(ply.tourniquetsM[i]) and ply.tourniquetsM[i] or ClientsideModel("models/tourniquet/tourniquet_put.mdl")
			local model = ply.tourniquetsM[i]
			model:SetNoDraw(true)

			if not IsValid(model) then return end
			
			local matrix = ent:GetBoneMatrix(wound[3])
			if not matrix then
				model:SetNoDraw(true)
				return
			end
			
			local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
			
			local tourniquetOffset = -wound[1]:GetNegated()
			tourniquetOffset[2] = 0
			tourniquetOffset[3] = 0
			tourniquetOffset[1] = 0

			if not boneOffset[ent:GetBoneName(wound[3])] then continue end

			local offset = boneOffset[ent:GetBoneName(wound[3])][1] + tourniquetOffset
			local offset2 = boneOffset[ent:GetBoneName(wound[3])][2]
			local pos, ang = LocalToWorld(offset, offset2, bonePos, boneAng)
			model:SetRenderOrigin(pos)
			model:SetRenderAngles(ang)
			model:SetModelScale(boneScale[ent:GetBoneName(wound[3])])
			model:SetupBones()
			model:DrawModel()
		end
	end
	--end)

	

	function remove_bandages(ent)
		if IsValid(ent.bandagesModel) then
			ent.bandagesModel:Remove()
		end
		ent.bandagesModel = nil
	end

	hook.Add("OnNetVarSet","bandage_netvar",function(index, key, var)
		if key == "bandaged_limbs" then
			local ent = Entity(index)
	
			if IsValid(ent) then
	
				remove_bandages(ent)
	
				ent.bandaged_limbs = var
	
				ent:CallOnRemove("remove_bandages",function()
					remove_bandages(ent)
				end)
			end
		end
	end)

	local BadagesModelMale = "models/distac/newbandage.mdl"
	local BadagesModelFemale = "models/distac/newbandage_f.mdl"
	local BodyGroupsMale = {
		["ValveBiped.Bip01_Pelvis"] = "belly",
		["ValveBiped.Bip01_Spine"] = "groin",
		["ValveBiped.Bip01_Spine1"] = "belly",
		["ValveBiped.Bip01_Spine2"] = "Chest",
		["ValveBiped.Bip01_L_UpperArm"] = "HandUpLeft",
		["ValveBiped.Bip01_L_Forearm"] = "HandDownLeft",
		["ValveBiped.Bip01_L_Hand"] = "HandLeft",
		["ValveBiped.Bip01_R_UpperArm"] = "HandUpRight",
		["ValveBiped.Bip01_R_Forearm"] = "HandDownRight",
		["ValveBiped.Bip01_R_Hand"] = "HandRight",
		["ValveBiped.Bip01_L_Thigh"] = "LegUpLeft",
		["ValveBiped.Bip01_L_Calf"] = "LegDownLeft",
		["ValveBiped.Bip01_R_Thigh"] = "LegUpRught",
		["ValveBiped.Bip01_R_Calf"] = "LegDownRught",
	}

	local BodyGroupsFemale = {
		["ValveBiped.Bip01_Pelvis"] = "belly-f",
		["ValveBiped.Bip01_Spine"] = "groin-f",
		["ValveBiped.Bip01_Spine1"] = "belly-f",
		["ValveBiped.Bip01_Spine2"] = "Chest-f",
		["ValveBiped.Bip01_L_UpperArm"] = "HandUpLeft-f",
		["ValveBiped.Bip01_L_Forearm"] = "HandDownLeft-f",
		["ValveBiped.Bip01_L_Hand"] = "HandLeft-f",
		["ValveBiped.Bip01_R_UpperArm"] = "HandUpRight-f",
		["ValveBiped.Bip01_R_Forearm"] = "HandDownRight-f",
		["ValveBiped.Bip01_R_Hand"] = "HandRight-f",
		["ValveBiped.Bip01_L_Thigh"] = "LegUpLeft-f",
		["ValveBiped.Bip01_L_Calf"] = "LegDownLeft-f",
		["ValveBiped.Bip01_R_Thigh"] = "LegUpRught-f",
		["ValveBiped.Bip01_R_Calf"] = "LegDownRught-f",
	}

	--hook.Add("PostDrawPlayerRagdoll", "draw_bandages", function(ent,ply)
	function hg.RenderBandages(ent, ply)
		--PrintTable(ent.bandaged_limbs)
		if not ent.bandaged_limbs then return end
		if table.IsEmpty(ent.bandaged_limbs) then return end
		if not IsValid( ent.bandagesModel ) then
			ent.bandagesModel = (ThatPlyIsFemale(ent) and ClientsideModel(BadagesModelFemale) or ClientsideModel(BadagesModelMale))
			local model = ent.bandagesModel
			ent:CallOnRemove("removebandages",function()
				if IsValid(model) then
					model:Remove()
					model = nil
				end
			end)
		end
		
		local model = ent.bandagesModel
		model:SetNoDraw(true)
		model:SetPos(ent:GetPos()+vector_up * 1)
		model:SetParent(ent)
		model:AddEffects(EF_BONEMERGE)
		if not model.BodygroupsApplied then 
			for k,v in pairs(ent.bandaged_limbs) do
				model:SetBodygroup(model:FindBodygroupByName( ThatPlyIsFemale(ent) and BodyGroupsFemale[k] or BodyGroupsMale[k] or ""),1)
			end
			model.BodygroupsApplied = true 
		end
		model:DrawModel()
	end
	--end)
end

function SWEP:IsLocal()
	return CLIENT and self:GetOwner() == LocalPlayer()
end

function SWEP:Holster(wep)
	if not IsValid(wep) or wep == self then return true end

	if SERVER or CLIENT and self:IsLocal() then
		self:EmitSound(self.HolsterSnd,50)
	end

	return true
end

function SWEP:Deploy()
	
	if SERVER or CLIENT and self:IsLocal() then
		self:EmitSound(self.DeploySnd,50,math.random(90,110))
	end
	
	return true
end
