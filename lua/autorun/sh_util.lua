if engine.ActiveGamemode() ~= "realism" then
    return
end
if CLIENT then
	lply = LocalPlayer()
	hook.Add("InitPostEntity", "hg_cache_lply", function()
		lply = LocalPlayer()
	end)
	hook.Add("Think", "hg_cache_lply", function()
		if not IsValid(lply) then
			lply = LocalPlayer()
		end
	end)
	local plymeta = FindMetaTable("Player")
	hg.GetAimVector = hg.GetAimVector or plymeta.GetAimVector
	function plymeta:GetAimVector()
		if self == LocalPlayer() then
			return hg.GetAimVector(self)
		elseif self:InVehicle() then
			local ang = self:EyeAngles()
			--ang:Add(-self:GetVehicle():GetAngles())
			return ang:Forward()
		end

		return hg.GetAimVector(self)
	end
end
hg.ConVars = hg.ConVars or {}

--\\Is Changed
local ChangedTable = {}

function hg.IsChanged(val, id, meta)
	if(meta == nil)then
		meta = ChangedTable
	end

	if(meta.ChangedTable == nil)then
		meta["ChangedTable"] = {}
	end

	if(meta.ChangedTable[id] == val)then
		return false
	end

	meta.ChangedTable[id] = val
	return true
end
--//

function ishgweapon(wep)
	if not wep or not IsValid(wep) then return false end
	return wep.ishgweapon
end

function hg.isVisible(pos1, pos2, filter, mask)
	return not util.TraceLine({
		start = pos1,
		endpos = pos2,
		filter = filter,
		mask = mask
	}).Hit
end

--hg.DeathCam = true

if SERVER then
	util.AddNetworkString("keyDownply2")
	hook.Add("KeyPress", "huy-hg", function(ply, key)
		net.Start("keyDownply2")
		net.WriteInt(key, 26)
		net.WriteBool( ply.organism.canmove )
		net.WriteEntity(ply)
		net.Broadcast()
	end)

	hook.Add("KeyRelease", "huy-hg2", function(ply, key)
		net.Start("keyDownply2")
		net.WriteInt(key, 26)
		net.WriteBool(false)
		net.WriteEntity(ply)
		net.Broadcast()
	end)
else
	net.Receive("keyDownply2", function(len)
		local key = net.ReadInt(26)
		local down = net.ReadBool()
		local ply = net.ReadEntity()
		if not IsValid(ply) then return end
		ply.keydown = ply.keydown or {}
		ply.keydown[key] = down
		if ply.keydown[key] == false then ply.keydown[key] = nil end
	end)
end

function hg.IsValidPlayer(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply.organism
end

local function replace_by_index(str, index, char)
	return utf8.sub(str, 1, index - 1)..char..utf8.sub(str, index + 1)
end

local function utf8_reverse(codes, len)
	local characters = {}
	local characters2 = {}
	
	local curlen = 1

	for i, code in codes do
		characters[curlen] = utf8.char(code)
		curlen = curlen + 1
	end

	for i = 1, #characters do
		characters2[#characters - i + 1] = characters[i]
	end

	return table.concat(characters2)
end

hg.replace_by_index = replace_by_index
hg.utf8_reverse = utf8_reverse

function hg.KeyDown(owner,key)
	if not IsValid(owner) then return false end
	owner.keydown = owner.keydown or {}
	local localKey
	if CLIENT then
		if owner == LocalPlayer() then
			localKey = owner.organism and owner:KeyDown(key) or false
		else
			localKey = owner.keydown[key]
		end
	end
	return SERVER and owner:IsPlayer() and owner:KeyDown(key) or CLIENT and localKey
end

if CLIENT then
	hook.Add("Player Think", "fucking bullshit", function(ply)
		local wep = ply:GetActiveWeapon()

		if IsValid(wep) and wep.ismelee and ply != LocalPlayer() then
			if wep.Think and not wep.HomicideSWEP then
				wep:Think()
			end

			if hg.KeyDown(ply, IN_ATTACK) and wep:CanPrimaryAttack() and not wep.HomicideSWEP then
				if not wep.Primary.Automatic then
					if not ply.keypress1 then
						wep:PrimaryAttack()
						ply.keypress1 = true
					end
				else
					wep:PrimaryAttack()
				end
			else
				ply.keypress1 = false
			end

			if hg.KeyDown(ply, IN_ATTACK2) and wep:CanSecondaryAttack() and not wep.HomicideSWEP then
				if not wep.Primary.Automatic then
					if not ply.keypress2 then
						wep:SecondaryAttack()
						ply.keypress2 = true
					end
				else
					wep:SecondaryAttack()
				end
			else
				ply.keypress2 = false
			end
		end
	end)
end

local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

local function setbonematrix(self, bone, matrix)
	do return end
	local parent = self:GetBoneParent(bone)
	parent = parent ~= -1 and parent or 0

	local matp = self.unmanipulated[parent] or self:GetBoneMatrix(parent)
	--print(matp:GetAngles(),parent)
	local new_matrix = matrix
	local old_matrix = self.unmanipulated[bone]
	
	local lmat = old_matrix:GetInverse() * new_matrix
	local ang = lmat:GetAngles()
	local vec, _ = WorldToLocal(new_matrix:GetTranslation(), angle_zero, old_matrix:GetTranslation(), matp:GetAngles())
	
	--self:ManipulateBonePosition(bone, vec)
	--self:ManipulateBoneAngles(bone, lmat:GetAngles())
	hg.bone.Set(self, bone, vector_origin, lmat:GetAngles(), "huy1")
end

function PLAYER:SetBoneMatrix2(boneID, matrix)
	setbonematrix(self, boneID, matrix)
end

function ENTITY:SetBoneMatrix2(boneID, matrix)
	setbonematrix(self, boneID, matrix)
end

if CLIENT then
	local cached_children = {}

	function hg.get_children(ent, bone, endbone)
		local bones = {}

		local mdl = ent:GetModel()
		if cached_children[mdl] and cached_children[mdl][bone] then return cached_children[mdl][bone] end

		hg.recursive_get_children(ent, bone, bones, endbone)

		cached_children[mdl] = cached_children[mdl] or {}
		cached_children[mdl][bone] = bones

		return bones
	end

	function hg.recursive_get_children(ent, bone, bones, endbone)
		local bone = isstring(bone) and ent:LookupBone(bone) or bone

		if not bone or isstring(bone) or bone == -1 then return end
		
		local children = ent:GetChildBones(bone)
		if #children > 0 then
			local id
			for i = 1,#children do
				id = children[i]
				if id == endbone then continue end
				hg.recursive_get_children(ent, id, bones, endbone)
				table.insert(bones, id)
			end
		end
	end

	function hg.bone_apply_matrix(ent, bone, new_matrix, endbone)
		local bone = isstring(bone) and ent:LookupBone(bone) or bone

		if not bone or isstring(bone) or bone == -1 then return end

		local matrix = ent:GetBoneMatrix(bone)
		if not matrix then return end
		local inv_matrix = matrix:GetInverse()
		if not inv_matrix then return end

		local children = hg.get_children(ent, bone, endbone)
		//print(bone, ent:GetBoneName(bone))
		//PrintTable(children)
		local translate = new_matrix * inv_matrix
		local id
		for i = 1,#children do
			id = children[i]
			local mat = ent:GetBoneMatrix(id)
			if not mat then continue end
			ent:SetBoneMatrix(id, translate * mat)
		end

		ent:SetBoneMatrix(bone, new_matrix)
	end

	local hand_poses = {
		["ak_hold"] = {
			['ValveBiped.Anim_Attachment_LH'] = Matrix({
				{-0.00000,	0.00000,	1.00000,	2.67615},
				{1.00000,	0.00000,	-0.00000,	-1.71259},
				{0.00000,	1.00000,	0.00000,	0.00000},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger42'] = Matrix({
				{-0.94591,	0.27700,	0.16890,	3.54791},
				{-0.30619,	-0.93432,	-0.18247,	-1.92862},
				{0.10726,	-0.22431,	0.96860,	-1.02161},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger41'] = Matrix({
				{-0.33096,	0.89941,	0.28551,	3.78937},
				{-0.94323,	-0.32425,	-0.07194,	-1.24072},
				{0.02788,	-0.29311,	0.95567,	-1.04199},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger4'] = Matrix({
				{-0.04830,	0.87322,	0.48492,	3.85278},
				{-0.99005,	-0.10611,	0.09247,	0.05881},
				{0.13220,	-0.47563,	0.86966,	-1.21545},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger32'] = Matrix({
				{-0.89734,	0.43983,	0.03652,	3.88898},
				{-0.43921,	-0.89806,	0.02398,	-2.14607},
				{0.04334,	0.00548,	0.99905,	-0.27673},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger31'] = Matrix({
				{-0.55578,	0.82941,	0.05636,	4.55377},
				{-0.82883,	-0.55809,	0.03974,	-1.15453},
				{0.06441,	-0.02463,	0.99762,	-0.35364},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger3'] = Matrix({
				{0.40515,	0.90826,	0.10449,	3.93042},
				{-0.91189,	0.39324,	0.11756,	0.24893},
				{0.06568,	-0.14292,	0.98755,	-0.45465},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger22'] = Matrix({
				{-0.80179,	0.59719,	-0.02193,	4.12610},
				{-0.59716,	-0.79926,	0.06765,	-2.30994},
				{0.02287,	0.06736,	0.99747,	0.36749},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger21'] = Matrix({
				{-0.55616,	0.82995,	-0.04349,	4.79871},
				{-0.83102,	-0.55479,	0.03996,	-1.30507},
				{0.00905,	0.05838,	0.99825,	0.35626},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger2'] = Matrix({
				{0.53286,	0.84495,	-0.04613,	3.88226},
				{-0.84567,	0.52979,	-0.06446,	0.14911},
				{-0.03002,	0.07336,	0.99686,	0.40833},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger12'] = Matrix({
				{-0.76564,	0.60825,	-0.20935,	4.27423},
				{-0.64018,	-0.75231,	0.15556,	-2.53366},
				{-0.06288,	0.25312,	0.96540,	1.28217},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger11'] = Matrix({
				{-0.31689,	0.90408,	-0.28674,	4.62231},
				{-0.94762,	-0.31451,	0.05561,	-1.49168},
				{-0.03991,	0.28934,	0.95639,	1.32605},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger1'] = Matrix({
				{0.43860,	0.83784,	-0.32505,	3.86847},
				{-0.89863,	0.41297,	-0.14808,	0.05353},
				{0.01017,	0.35704,	0.93404,	1.30878},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger02'] = Matrix({
				{0.50243,	0.85495,	0.12890,	2.51984},
				{-0.49077,	0.15927,	0.85660,	-1.93399},
				{0.71183,	-0.49365,	0.49961,	3.16608},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger01'] = Matrix({
				{0.52369,	0.82281,	0.22077,	1.88818},
				{-0.63107,	0.20059,	0.74934,	-1.17212},
				{0.57228,	-0.53174,	0.62429,	2.47565},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger0'] = Matrix({
				{0.59067,	0.80398,	0.06873,	0.83069},
				{-0.48029,	0.28184,	0.83060,	-0.31262},
				{0.64841,	-0.52362,	0.55262,	1.31488},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				
				
				
		},
		["pistol_hold"] = {
			['ValveBiped.Anim_Attachment_LH'] = Matrix({
				{-0.00000,	0.00000,	1.00000,	2.67621},
				{1.00000,	-0.00000,	0.00000,	-1.71246},
				{0.00000,	1.00000,	-0.00000,	0.00003},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger22'] = Matrix({
				{-0.01749,	0.99334,	0.11387,	6.02985},
				{-0.97449,	-0.04242,	0.22040,	-1.66858},
				{0.22376,	-0.10711,	0.96874,	0.55327},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger21'] = Matrix({
				{0.51410,	0.85003,	0.11468,	5.40814},
				{-0.84802,	0.48365,	0.21666,	-0.64301},
				{0.12871,	-0.20863,	0.96949,	0.39767},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger2'] = Matrix({
				{0.88753,	0.44555,	0.11738,	3.88190},
				{-0.46071,	0.86152,	0.21339,	0.14917},
				{-0.00605,	-0.24347,	0.96989,	0.40808},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger12'] = Matrix({
				{-0.09313,	0.95159,	-0.29292,	5.74945},
				{-0.98149,	-0.03829,	0.18766,	-1.67291},
				{0.16736,	0.30498,	0.93754,	2.22884},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger11'] = Matrix({
				{0.42919,	0.85458,	-0.29240,	5.27753},
				{-0.85153,	0.49078,	0.18449,	-0.73663},
				{0.30116,	0.16981,	0.93833,	1.89777},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger1'] = Matrix({
				{0.81943,	0.49413,	-0.29047,	3.86847},
				{-0.45961,	0.86925,	0.18211,	0.05353},
				{0.34248,	-0.01572,	0.93939,	1.30884},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger02'] = Matrix({
				{0.45101,	0.46180,	0.76376,	0.99359},
				{-0.89058,	0.28921,	0.35103,	-2.93256},
				{-0.05879,	-0.83851,	0.54171,	2.74484},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger01'] = Matrix({
				{0.11163,	0.71261,	0.69263,	0.85889},
				{-0.90098,	-0.22147,	0.37307,	-1.84503},
				{0.41925,	-0.66569,	0.61732,	2.23883},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger0'] = Matrix({
				{0.01574,	0.63272,	0.77422,	0.83069},
				{-0.85632,	-0.39123,	0.33713,	-0.31244},
				{0.51620,	-0.66829,	0.53565,	1.31491},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
		},
		["pistol_hold2"] = {
			['ValveBiped.Anim_Attachment_LH'] = Matrix({
				{0.00000,	0.00000,	1.00000,	2.67624},
				{1.00000,	0.00000,	0.00000,	-1.71219},
				{0.00000,	1.00000,	0.00000,	0.00125},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger22'] = Matrix({
				{-0.01749,	0.99334,	0.11387,	6.02979},
				{-0.97449,	-0.04242,	0.22040,	-1.66882},
				{0.22376,	-0.10711,	0.96874,	0.55479},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger21'] = Matrix({
				{0.51410,	0.85003,	0.11468,	5.40826},
				{-0.84802,	0.48365,	0.21666,	-0.64151},
				{0.12871,	-0.20863,	0.96949,	0.39841},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger2'] = Matrix({
				{0.88753,	0.44555,	0.11738,	3.88205},
				{-0.46071,	0.86152,	0.21339,	0.14990},
				{-0.00605,	-0.24347,	0.96989,	0.40967},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger12'] = Matrix({
				{0.04883,	0.93152,	0.36040,	5.93692},
				{-0.94806,	-0.07033,	0.31021,	-1.68707},
				{0.31431,	-0.35683,	0.87971,	1.06296},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger11'] = Matrix({
				{0.53655,	0.76259,	0.36135,	5.34744},
				{-0.84070,	0.44598,	0.30712,	-0.76180},
				{0.07304,	-0.46857,	0.88040,	0.98254},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger1'] = Matrix({
				{0.85928,	0.35981,	0.36356,	3.86862},
				{-0.47470,	0.82571,	0.30475,	0.05447},
				{-0.19054,	-0.43444,	0.88032,	1.30991},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger02'] = Matrix({
				{0.96372,	-0.25079,	0.09129,	3.71692},
				{-0.23753,	-0.65006,	0.72180,	-0.67805},
				{-0.12168,	-0.71731,	-0.68605,	2.00784},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger01'] = Matrix({
				{0.96779,	0.00605,	0.25170,	2.54880},
				{-0.18421,	-0.66437,	0.72434,	-0.45737},
				{0.17162,	-0.74738,	-0.64186,	1.80225},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger0'] = Matrix({
				{0.95950,	0.11401,	0.25760,	0.83066},
				{-0.08016,	-0.76613,	0.63767,	-0.31189},
				{0.27007,	-0.63250,	-0.72596,	1.31686},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				
		},
		["grip_hold"] = {
			['ValveBiped.Anim_Attachment_LH'] = Matrix({
				{-0.00000,	0.00000,	1.00000,	2.67603},
				{1.00000,	-0.00000,	0.00000,	-1.71242},
				{0.00000,	1.00000,	-0.00000,	-0.00003},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger22'] = Matrix({
				{-0.97924,	0.20271,	-0.00014,	3.74866},
				{-0.20076,	-0.96973,	0.13898,	-2.21208},
				{0.02804,	0.13613,	0.99029,	0.41345},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger21'] = Matrix({
				{-0.73487,	0.67761,	-0.02840,	4.63727},
				{-0.67613,	-0.72870,	0.10877,	-1.39452},
				{0.05301,	0.09914,	0.99366,	0.34940},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger2'] = Matrix({
				{0.43925,	0.89832,	-0.00901,	3.88190},
				{-0.89772,	0.43853,	-0.04240,	0.14917},
				{-0.03413,	0.02671,	0.99906,	0.40808},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger12'] = Matrix({
				{-0.99956,	-0.01974,	-0.02234,	3.86542},
				{0.01938,	-0.99968,	0.01623,	-2.35136},
				{-0.02265,	0.01579,	0.99962,	1.09308},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger11'] = Matrix({
				{-0.63952,	0.75470,	-0.14642,	4.56860},
				{-0.76220,	-0.64730,	-0.00734,	-1.51318},
				{-0.10032,	0.10691,	0.98920,	1.20340},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger1'] = Matrix({
				{0.40735,	0.87616,	-0.25768,	3.86835},
				{-0.91121,	0.37097,	-0.17910,	0.05359},
				{-0.06132,	0.30776,	0.94949,	1.30881},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger02'] = Matrix({
				{0.85313,	-0.04293,	0.51993,	2.97278},
				{-0.41533,	0.54722,	0.72667,	-2.11815},
				{-0.31571,	-0.83589,	0.44902,	2.23587},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger01'] = Matrix({
				{0.76975,	0.35296,	0.53189,	2.04376},
				{-0.63041,	0.28937,	0.72031,	-1.35727},
				{0.10032,	-0.88977,	0.44525,	2.11478},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger0'] = Matrix({
					{0.94183,	0.32924,	-0.06756,	0.83057},
					{-0.17855,	0.66041,	0.72936,	-0.31244},
					{0.28475,	-0.67487,	0.68078,	1.31494},
					{0.00000,	0.00000,	0.00000,	1.00000},
				}),
		},
		["normal"] = {
			['ValveBiped.Anim_Attachment_LH'] = Matrix({
				{-0.00000,	0.00000,	1.00000,	2.67612},
				{1.00000,	0.00000,	0.00000,	-1.71246},
				{0.00000,	1.00000,	-0.00000,	0.00011},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger22'] = Matrix({
				{-0.29595,	0.95278,	0.06800,	5.70983},
				{-0.95268,	-0.29959,	0.05143,	-1.95068},
				{0.06937,	-0.04956,	0.99636,	0.37529},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger21'] = Matrix({
				{0.33266,	0.94060,	0.06787,	5.30755},
				{-0.94279,	0.33004,	0.04704,	-0.81073},
				{0.02185,	-0.07964,	0.99658,	0.34882},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger2'] = Matrix({
				{0.82903,	0.55477,	0.07033,	3.88195},
				{-0.55815,	0.82863,	0.04294,	0.14893},
				{-0.03446,	-0.07485,	0.99660,	0.40813},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger12'] = Matrix({
				{-0.08428,	0.99281,	0.08499,	5.85923},
				{-0.99636,	-0.08288,	-0.01983,	-1.77557},
				{-0.01264,	-0.08635,	0.99618,	1.09001},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger11'] = Matrix({
				{0.46127,	0.88312,	0.08559,	5.35198},
				{-0.88521,	0.46461,	-0.02311,	-0.80212},
				{-0.06017,	-0.06510,	0.99606,	1.15631},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger1'] = Matrix({
				{0.86281,	0.49787,	0.08766,	3.86842},
				{-0.49768,	0.86698,	-0.02563,	0.05341},
				{-0.08876,	-0.02151,	0.99582,	1.30876},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger02'] = Matrix({
				{0.93636,	-0.05663,	0.34646,	3.07861},
				{-0.33561,	0.14505,	0.93076,	-1.36694},
				{-0.10297,	-0.98780,	0.11681,	2.87762},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger01'] = Matrix({
				{0.87590,	0.36578,	0.31466,	2.02138},
				{-0.37139,	0.09478,	0.92363,	-0.91876},
				{0.30802,	-0.92586,	0.21886,	2.50584},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_L_Finger0'] = Matrix({
				{0.66529,	0.65242,	0.36297,	0.83065},
				{-0.33863,	-0.16960,	0.92551,	-0.31274},
				{0.66537,	-0.73864,	0.10810,	1.31494},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),				
		},
			
	}

	local hand_posesrh = {
		["pistol_hold"] = {
			['ValveBiped.Anim_Attachment_RH'] = Matrix({
				{0.00000,	0.00000,	1.00000,	2.67606},
				{-1.00000,	0.00000,	0.00000,	-1.71246},
				{-0.00000,	-1.00000,	0.00000,	0.00002},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger22'] = Matrix({
				{-0.72247,	-0.69045,	0.03619,	3.59613},
				{0.68088,	-0.71960,	-0.13627,	-2.10107},
				{0.12013,	-0.07381,	0.99001,	-0.70821},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger21'] = Matrix({
				{-0.81663,	0.57602,	0.03631,	4.58354},
				{-0.57506,	-0.80666,	-0.13638,	-1.40582},
				{-0.04927,	-0.13225,	0.98999,	-0.64864},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger2'] = Matrix({
				{0.40803,	0.91223,	0.03655,	3.88191},
				{-0.90229,	0.40904,	-0.13621,	0.14581},
				{-0.13920,	0.02260,	0.99001,	-0.40927},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger12'] = Matrix({
				{0.38305,	0.89067,	0.24489,	6.36687},
				{-0.87335,	0.43556,	-0.21806,	-0.71552},
				{-0.30089,	-0.13035,	0.94471,	-2.29142},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger11'] = Matrix({
				{0.82500,	0.46776,	0.31714,	5.45959},
				{-0.43831,	0.88385,	-0.16339,	-0.23364},
				{-0.35672,	-0.00421,	0.93420,	-1.89915},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger1'] = Matrix({
				{0.92545,	0.20620,	0.31783,	3.86839},
				{-0.16063,	0.97334,	-0.16376,	0.04260},
				{-0.34312,	0.10050,	0.93390,	-1.30919},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger02'] = Matrix({
				{0.91919,	0.01437,	-0.39356,	2.56244},
				{-0.22476,	0.83975,	-0.49427,	-2.46594},
				{0.32339,	0.54278,	0.77512,	-1.12394},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger01'] = Matrix({
				{0.89306,	0.24370,	-0.37822,	1.48447},
				{-0.39602,	0.82473,	-0.40371,	-1.98792},
				{0.21354,	0.51032,	0.83305,	-1.38169},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger0'] = Matrix({
				{0.36535,	0.67044,	-0.64578,	0.83058},
				{-0.93006,	0.23399,	-0.28325,	-0.32336},
				{-0.03880,	0.70410,	0.70904,	-1.31224},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),

		},
		["pistol_hold2"] = {
			['ValveBiped.Anim_Attachment_RH'] = Matrix({
				{-0.00000,	-0.00000,	1.00000,	2.67590},
				{-1.00000,	0.00000,	0.00000,	-1.71245},
				{-0.00000,	-1.00000,	0.00000,	-0.00018},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger22'] = Matrix({
				{-0.72247,	-0.69045,	0.03619,	3.59595},
				{0.68088,	-0.71960,	-0.13627,	-2.10101},
				{0.12013,	-0.07381,	0.99001,	-0.70869},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger21'] = Matrix({
				{-0.81663,	0.57602,	0.03631,	4.58325},
				{-0.57506,	-0.80666,	-0.13638,	-1.40576},
				{-0.04927,	-0.13225,	0.98999,	-0.64896},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger2'] = Matrix({
				{0.40803,	0.91223,	0.03655,	3.88184},
				{-0.90229,	0.40904,	-0.13621,	0.14584},
				{-0.13920,	0.02260,	0.99001,	-0.40953},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger12'] = Matrix({
				{-0.64674,	0.67462,	0.35582,	5.34323},
				{-0.72666,	-0.68676,	-0.01868,	-1.51030},
				{0.23174,	-0.27064,	0.93437,	-1.63513},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger11'] = Matrix({
				{-0.13709,	0.89443,	0.42567,	5.49384},
				{-0.99051,	-0.11955,	-0.06781,	-0.42105},
				{-0.00976,	-0.43093,	0.90233,	-1.62455},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger1'] = Matrix({
				{0.94541,	0.27139,	0.18037,	3.86847},
				{-0.26957,	0.96235,	-0.03501,	0.04260},
				{-0.18308,	-0.01552,	0.98298,	-1.30880},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger02'] = Matrix({
				{0.99624,	0.06471,	-0.05769,	2.81659},
				{-0.08661,	0.77220,	-0.62945,	-2.12851},
				{0.00382,	0.63207,	0.77490,	-1.95563},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger01'] = Matrix({
				{0.96151,	0.27211,	-0.03794,	1.65674},
				{-0.24833,	0.80174,	-0.54364,	-1.82861},
				{-0.11751,	0.53214,	0.83846,	-1.81313},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger0'] = Matrix({
				{0.46226,	0.81687,	-0.34503,	0.83054},
				{-0.84134,	0.28111,	-0.46166,	-0.32336},
				{-0.28012,	0.50369,	0.81720,	-1.31165},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				
		},
		["ak_hold"] = {
			['ValveBiped.Anim_Attachment_RH'] = Matrix({
				{-0.00000,	0.00000,	1.00000,	2.67609},
				{-1.00000,	-0.00000,	-0.00000,	-1.71246},
				{-0.00000,	-1.00000,	0.00000,	0.00006},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger22'] = Matrix({
				{-0.93110,	0.35667,	-0.07637,	5.55054},
				{-0.31636,	-0.89387,	-0.31766,	-1.13599},
				{-0.18157,	-0.27162,	0.94512,	-0.15540},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger21'] = Matrix({
				{-0.01361,	0.98969,	-0.14256,	5.56680},
				{-0.99768,	-0.02294,	-0.06406,	0.07031},
				{-0.06667,	0.14136,	0.98771,	-0.07477},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger2'] = Matrix({
				{0.97992,	0.04619,	-0.19397,	3.88190},
				{-0.04384,	0.99890,	0.01639,	0.14563},
				{0.19451,	-0.00755,	0.98087,	-0.40924},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger12'] = Matrix({
				{-0.79259,	0.58780,	0.16215,	5.92780},
				{-0.55895,	-0.80666,	0.19203,	-1.24109},
				{0.24368,	0.06157,	0.96790,	-1.39969},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger11'] = Matrix({
				{0.34147,	0.92588,	0.16172,	5.55237},
				{-0.93122,	0.30995,	0.19173,	-0.21698},
				{0.12739,	-0.21607,	0.96803,	-1.53979},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger1'] = Matrix({
				{0.97941,	0.12047,	0.16201,	3.86835},
				{-0.15089,	0.96993,	0.19095,	0.04248},
				{-0.13414,	-0.21146,	0.96814,	-1.30917},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger02'] = Matrix({
				{0.99825,	0.01739,	-0.05635,	3.03442},
				{-0.04002,	0.90167,	-0.43059,	-2.16174},
				{0.04332,	0.43209,	0.90079,	-1.86401},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger01'] = Matrix({
				{0.90272,	0.42076,	-0.08968,	1.94482},
				{-0.41680,	0.80369,	-0.42469,	-1.65881},
				{-0.10661,	0.42075,	0.90088,	-1.73535},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger0'] = Matrix({
				{0.62252,	0.77258,	-0.12482,	0.83057},
				{-0.74605,	0.53767,	-0.39285,	-0.32355},
				{-0.23639,	0.33768,	0.91109,	-1.31219},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
		},
		["normal"] = {
			['ValveBiped.Anim_Attachment_RH'] = Matrix({
				{0.00000,	0.00000,	1.00000,	2.67609},
				{-1.00000,	0.00000,	0.00000,	-1.71240},
				{0.00000,	-1.00000,	0.00000,	-0.00003},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger22'] = Matrix({
				{-0.96502,	0.21943,	0.14350,	4.92922},
				{-0.22411,	-0.97441,	-0.01712,	-2.37482},
				{0.13607,	-0.04868,	0.98950,	-0.60452},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger21'] = Matrix({
				{-0.04046,	0.98880,	0.14365,	4.97814},
				{-0.99912,	-0.03840,	-0.01709,	-1.16669},
				{-0.01138,	-0.14422,	0.98948,	-0.59076},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger2'] = Matrix({
				{0.63750,	0.75694,	0.14366,	3.88191},
				{-0.76319,	0.64595,	-0.01679,	0.14569},
				{-0.10551,	-0.09894,	0.98948,	-0.40930},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger12'] = Matrix({
				{-0.06498,	0.97425,	0.21589,	6.14457},
				{-0.99649,	-0.05193,	-0.06558,	-1.45105},
				{-0.05268,	-0.21940,	0.97421,	-1.85055},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger11'] = Matrix({
				{0.67922,	0.70148,	0.21586,	5.39766},
				{-0.70660,	0.70452,	-0.06612,	-0.67401},
				{-0.19846,	-0.10761,	0.97418,	-1.63230},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger1'] = Matrix({
				{0.88940,	0.41611,	0.18924,	3.86839},
				{-0.41671,	0.90822,	-0.03854,	0.04260},
				{-0.18791,	-0.04458,	0.98117,	-1.30923},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger02'] = Matrix({
				{0.96589,	0.23494,	-0.10889,	2.51287},
				{-0.25337,	0.77071,	-0.58465,	-2.42767},
				{-0.05343,	0.59230,	0.80395,	-1.96227},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger01'] = Matrix({
				{0.90463,	0.41992,	-0.07287,	1.42098},
				{-0.39736,	0.76919,	-0.50046,	-1.94806},
				{-0.15410,	0.48169,	0.86269,	-1.77628},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				['ValveBiped.Bip01_R_Finger0'] = Matrix({
				{0.32986,	0.86917,	-0.36843,	0.83059},
				{-0.90773,	0.18485,	-0.37663,	-0.32330},
				{-0.25925,	0.45867,	0.84995,	-1.31228},
				{0.00000,	0.00000,	0.00000,	1.00000},
				}),
				
		},
	}

	function hg.set_hold(ent, hold, copyent)
		local lhmat = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_L_Hand"))
		ent.hold = hold
		for bone, invmat in pairs(hand_poses[hold]) do
			local name = bone
			bone = isstring(bone) and ent:LookupBone(bone) or bone
			if not bone or isstring(bone) or bone == -1 then continue end
			if not ent:GetBoneMatrix(bone) then continue end
			if IsValid(copyent) and copyent:LookupBone(name) then
				local mat = copyent:GetBoneMatrix(copyent:LookupBone(name))
				if mat then
					ent:SetBoneMatrix(bone, mat)
				else
					ent:SetBoneMatrix(bone,lhmat * invmat)
				end
			else
				ent:SetBoneMatrix(bone,lhmat * invmat)
			end
		end
	end

	function hg.set_holdrh(ent, hold, copyent)
		local lhmat = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_R_Hand"))
		ent.holdrh = hold
		for bone,invmat in pairs(hand_posesrh[hold]) do
			local name = bone
			bone = isstring(bone) and ent:LookupBone(bone) or bone
			if not bone or isstring(bone) or bone == -1 then continue end
			if not ent:GetBoneMatrix(bone) then continue end
			if IsValid(copyent) and copyent:LookupBone(name) then
				local mat = copyent:GetBoneMatrix(copyent:LookupBone(name))
				if mat then
					ent:SetBoneMatrix(bone, mat)
				else
					ent:SetBoneMatrix(bone,lhmat * invmat)
				end
			else
				ent:SetBoneMatrix(bone,lhmat * invmat)
			end
		end
	end

	function hg.copy_hold(ply)
		local lh = ply:LookupBone("ValveBiped.Bip01_L_Hand")
		local lhmat = ply:GetBoneMatrix(lh)
		print("\n")
		for i,bone in pairs(hg.get_children(ply,lh)) do
			local bon = ply:GetBoneName(bone)
			print("['"..bon.."'] = Matrix({\n"..string.Replace(string.Replace(tostring(lhmat:GetInverse() * ply:GetBoneMatrix(bone)),"[","{"),"]","},").."\n}),")
		end
		print("\n")
	end

	function hg.copy_holdrh(ply)
		local lh = ply:LookupBone("ValveBiped.Bip01_R_Hand")
		local lhmat = ply:GetBoneMatrix(lh)
		print("\n")
		for i,bone in pairs(hg.get_children(ply,lh)) do
			local bon = ply:GetBoneName(bone)
			print("['"..bon.."'] = Matrix({\n"..string.Replace(string.Replace(tostring(lhmat:GetInverse() * ply:GetBoneMatrix(bone)),"[","{"),"]","},").."\n}),")
		end
		print("\n")
	end

	local hg_tpik_distance = ConVarExists("hg_tpik_distance") and GetConVar("hg_tpik_distance") or CreateClientConVar("hg_tpik_distance",1024,true,false,"The distance (in hammer units) at which the third person inverse kinematics enables, 0 = inf",0,2048)

	local render_GetViewSetup = render.GetViewSetup
	function hg.ShouldTPIK(ply,wpn)
		local time = CurTime()
		if (ply.cachedtpik or 0) > time then return ply.cachedval end
		ply.cachedtpik = time + 0.1
		local int = hg_tpik_distance:GetInt()
		if (int == 0 or ply == LocalPlayer() or ply == LocalPlayer():GetNWEntity("spect")) then ply.cachedval = true return true end
		local view = render.GetViewSetup(true)
		if (ply:GetPos():DistToSqr(view.origin) > int*int) then ply.cachedval = false return false end
		ply.cachedval = true
		return true
	end

	--copy hold делаешь когда нужно скопировать пальчики левой руки
	--set hold когда хочешь чтобы пальчики встали ровно как надо по копии (и не двигались)
	--hg.copy_hold(Entity(1))
end

--\\Weighted Random Select
function hg.WeightedRandomSelect(tab, mul)
	if not tab or not istable(tab) then return end
	mul = mul or 1
	local total_weight = 0
	
	for i = 1, #tab do
		total_weight = total_weight + tab[i][1]
	end
	local total_weight_with_mul = total_weight * (mul - 1)
	local random_weight = math.Rand(math.min(total_weight_with_mul,math.Rand(total_weight_with_mul/2,total_weight)), math.min(total_weight * mul,total_weight) )
	local current_weight = 0
	
	for i = 1, #tab do
		current_weight = current_weight + tab[i][1]
		--print(current_weight,random_weight,current_weight <= random_weight)
		if(current_weight >= random_weight)then
			
			return i, tab[i][2]
		end
	end	
end
--//

if CLIENT then
	hg.oldClientsideModel = hg.oldClientsideModel or ClientsideModel

	hg.ClientsideModels = hg.ClientsideModels or {}

	function ClientsideModel(...)
		local model = hg.oldClientsideModel(...)

		table.insert(hg.ClientsideModels,model)
		--print(model)

		return model
	end
	
	function hg.PrintModels()
		for i,mdl in ipairs(hg.ClientsideModels) do
			if not IsValid(mdl) then continue end
			print(mdl,mdl:GetModel())
		end
	end

	function hg.ClearClientsideModels()
		for i,mdl in pairs(hg.ClientsideModels) do
			if not IsValid(mdl) then continue end
			mdl:Remove()
			//table.remove(hg.ClientsideModels,i)
		end
		hg.ClientsideModels = {}
	end

	hook.Add("PostCleanupMap","fuckclientsidemodels",hg.ClearClientsideModels)
end

function qerp(delta, a, b)
    local qdelta = -(delta ^ 2) + (delta * 2)
    qdelta = math.Clamp(qdelta, 0, 1)

    return Lerp(qdelta, a, b)
end

FrameTimeClamped = 1/66
ftlerped = 1/66

local def = 1 / 144

local FrameTime, TickInterval, engine_AbsoluteFrameTime = FrameTime, engine.TickInterval, engine.AbsoluteFrameTime
local Lerp, LerpVector, LerpAngle = Lerp, LerpVector, LerpAngle
local math_min = math.min
local math_Clamp = math.Clamp

local host_timescale = game.GetTimeScale

hook.Add("Think", "Mul lerp", function()
	local ft = FrameTime()
	ftlerped = Lerp(0.5,ftlerped,math_Clamp(ft,0.001,0.1))
end)

function hg.FrameTimeClamped(ft)
	--do return math.Clamp(ft or ftlerped,0.001,0.1) end
	return math_Clamp(1 - math.exp(-0.5 * (ft or ftlerped) * host_timescale()), 0.000, 0.02)
end

--[[function hg.FrameTimeClamped(ft)
	--do return math.Clamp(ftlerped,0.001,0.016) end
	return math_Clamp(1 - (0.5 ^ (ft or ftlerped)), 0.001, 0.016)
end--]]

local FrameTimeClamped_ = hg.FrameTimeClamped

local function lerpFrameTime(lerp,frameTime)
	return math_Clamp(1 - lerp ^ (frameTime or FrameTime()), 0, 1)-- * (host_timescale())
end

local function lerpFrameTime2(lerp,frameTime)
	--do return math_Clamp(lerp * ftlerped * 150,0,1) end
	--do return math_Clamp(1 - lerp ^ ftlerped,0,1) end
	if lerp == 1 then return 1 end
	return math_Clamp(lerp * FrameTimeClamped_(frameTime) * 150, 0, 1)-- * (host_timescale())
end

hg.lerpFrameTime2 = lerpFrameTime2
hg.lerpFrameTime = lerpFrameTime

function LerpFT(lerp, source, set)
	return Lerp(lerpFrameTime2(lerp), source, set)
end

function LerpVectorFT(lerp, source, set)
	return LerpVector(lerpFrameTime2(lerp), source, set)
end

function LerpAngleFT(lerp, source, set)
	return LerpAngle(lerpFrameTime2(lerp), source, set)
end

local max, min = math.max, math.min
function util.halfValue(value, maxvalue, k)
	k = maxvalue * k
	return max(value - k, 0) / k
end

function util.halfValue2(value, maxvalue, k)
	k = maxvalue * k
	return min(value / k, 1)
end

function util.safeDiv(a, b)
	if a == 0 and b == 0 then
		return 0
	else
		return a / b
	end
end

function player.GetListByName(name)
	local list = {}
	if name == "^" then
		return
	elseif name == "*" then
		return player.GetAll()
	end

	for i, ply in pairs(player.GetAll()) do
		if string.find(string.lower(ply:Name()), string.lower(name)) then list[#list + 1] = ply end
	end
	return list
end

function hg.spiralGrid(rings)
	local grid = {}
	local col, row

	for ring=1, rings do -- For each ring...
		row = ring
		for col=1-ring, ring do -- Walk right across top row
			table.insert( grid, {col, row} )
		end

		col = ring
		for row=ring-1, -ring, -1 do -- Walk down right-most column
			table.insert( grid, {col, row} )
		end

		row = -ring
		for col=ring-1, -ring, -1 do -- Walk left across bottom row
			table.insert( grid, {col, row} )
		end

		col = -ring
		for row=1-ring, ring do -- Walk up left-most column
			table.insert( grid, {col, row} )
		end
	end

	return grid
end

local hull = 10
local HullMaxs = Vector(hull, hull, 72)
local HullMins = -Vector(hull, hull, 0)
local HullDuckMaxs = Vector(hull, hull, 36)
local HullDuckMins = -Vector(hull, hull, 0)
local ViewOffset = Vector(0, 0, 64)
local ViewOffsetDucked = Vector(0, 0, 38)

local gridsize = 24
local tpGrid = hg.spiralGrid(gridsize)
local cell_size = 50

function hg.tpPlayer(pos, ply, i, yaw, forced)
	if !tpGrid[i] then
		return hg.tpPlayer(pos, ply, math.random(gridsize), yaw, true)
	end

	local c = tpGrid[i][1]
	local r = tpGrid[i][2]

	local yawForward = yaw or 0
	local offset = Vector( r * cell_size, c * cell_size, 0 )
	offset:Rotate( Angle( 0, yawForward, 0 ) )

	local t = {}
	t.start = pos + Vector( 0, 0, 32 )
	t.collisiongroup = COLLISION_GROUP_WEAPON
	t.endpos = t.start + offset

	if !IsValid(ply) then
		t.hullmaxs = HullMaxs
		t.hullmins = HullMins
	end

	local tr
	if IsValid(ply) then
		tr = util.TraceEntity( t, ply )
	else
		tr = util.TraceHull(t)
	end
	
	if !tr.Hit or forced then
		if IsValid(ply) then ply:SetPos(tr.HitPos) end
		
		return tr.HitPos
	else
		return hg.tpPlayer(pos, ply, i + 1, yaw)
	end
end

//for i, ply in ipairs(player.GetAll()) do
//	hg.tpPlayer(Vector(44.917309, 1.110850, -82.409622), ply, i, 0)
//end

function hg.clamp(vecOrAng, val)
	vecOrAng[1] = math.Clamp(vecOrAng[1], -val, val)
	vecOrAng[2] = math.Clamp(vecOrAng[2], -val, val)
	vecOrAng[3] = math.Clamp(vecOrAng[3], -val, val)
	return vecOrAng
end

local PLAYER = FindMetaTable("Player")
hg.SetEyeAngles = hg.SetEyeAngles or PLAYER.SetEyeAngles

function PLAYER:SetEyeAngles(ang)
	if !self.lockcamera then
		hg.SetEyeAngles(self, ang)
	end
end

if CLIENT then
	local PUNCH_DAMPING = 9
	local PUNCH_SPRING_CONSTANT = 95
	vp_punch_angle = vp_punch_angle or Angle()
	local vp_punch_angle_velocity = Angle()
	vp_punch_angle_last = vp_punch_angle_last or vp_punch_angle

	vp_punch_angle2 = vp_punch_angle2 or Angle()
	local vp_punch_angle_velocity2 = Angle()
	vp_punch_angle_last2 = vp_punch_angle_last2 or vp_punch_angle2


	local fuck_you_debil = 0

	hook.Add("Think", "viewpunch_think", function()
		--if LocalPlayer():InVehicle() then return end

		if not vp_punch_angle:IsZero() or not vp_punch_angle_velocity:IsZero() then
			vp_punch_angle = vp_punch_angle + vp_punch_angle_velocity * ftlerped
			local damping = 1 - (PUNCH_DAMPING * ftlerped)
			if damping < 0 then damping = 0 end
			vp_punch_angle_velocity = vp_punch_angle_velocity * damping
			local spring_force_magnitude = PUNCH_SPRING_CONSTANT * 0.01-- * ftlerped
			vp_punch_angle_velocity = vp_punch_angle_velocity - vp_punch_angle * spring_force_magnitude
			local x, y, z = vp_punch_angle:Unpack()
			vp_punch_angle = Angle(math.Clamp(x, -89, 89), math.Clamp(y, -179, 179), math.Clamp(z, -89, 89))
		else
			vp_punch_angle = Angle()
			vp_punch_angle_velocity = Angle()
		end

		local ang = LocalPlayer():EyeAngles() + vp_punch_angle - vp_punch_angle_last
		--LocalPlayer():SetEyeAngles(ang)

		--

		if not vp_punch_angle2:IsZero() or not vp_punch_angle_velocity2:IsZero() then
			vp_punch_angle2 = vp_punch_angle2 + vp_punch_angle_velocity2 * ftlerped
			local damping = 1 - (PUNCH_DAMPING * ftlerped)
			if damping < 0 then damping = 0 end
			vp_punch_angle_velocity2 = vp_punch_angle_velocity2 * damping
			local spring_force_magnitude = PUNCH_SPRING_CONSTANT * 0.01-- * ftlerped
			vp_punch_angle_velocity2 = vp_punch_angle_velocity2 - vp_punch_angle2 * spring_force_magnitude
			local x, y, z = vp_punch_angle2:Unpack()
			vp_punch_angle2 = Angle(math.Clamp(x, -89, 89), math.Clamp(y, -179, 179), math.Clamp(z, -89, 89))
		else
			vp_punch_angle2 = Angle()
			vp_punch_angle_velocity2 = Angle()
		end

		--if not LocalPlayer():Alive() then vp_punch_angle:Zero() vp_punch_angle_velocity:Zero() vp_punch_angle2:Zero() vp_punch_angle_velocity2:Zero() end

		if vp_punch_angle:IsZero() and vp_punch_angle_velocity:IsZero() and vp_punch_angle2:IsZero() and vp_punch_angle_velocity2:IsZero() then return end
		local add = vp_punch_angle - vp_punch_angle_last + vp_punch_angle2 - vp_punch_angle_last2
		local ang = LocalPlayer():EyeAngles() + add

		LocalPlayer():SetEyeAngles(ang)
		vp_punch_angle_last = vp_punch_angle
		vp_punch_angle_last2 = vp_punch_angle2
	end)

	function SetViewPunchAngles(angle)
		if not angle then
			print("[Local Viewpunch] SetViewPunchAngles called without an angle. wtf?")
			return
		end

		vp_punch_angle = angle
	end

	function SetViewPunchVelocity(angle)
		if not angle then
			print("[Local Viewpunch] SetViewPunchVelocity called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity = angle * 20
	end

	function Viewpunch(angle)
		if not angle then
			print("[Local Viewpunch] Viewpunch called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity = vp_punch_angle_velocity + angle * 20
	end

	function Viewpunch2(angle)
		if not angle then
			print("[Local Viewpunch] Viewpunch called without an angle. wtf?")
			return
		end

		vp_punch_angle_velocity2 = vp_punch_angle_velocity2 + angle * 20
	end

	function ViewPunch(angle)
		Viewpunch(angle)
	end

	function ViewPunch2(angle)
		Viewpunch2(angle)
	end

	function GetViewPunchAngles()
		return vp_punch_angle
	end

	function GetViewPunchAngles2()
		return vp_punch_angle2
	end

	function GetViewPunchVelocity()
		return vp_punch_angle_velocity
	end

	local angle_hitground = Angle(0, 0, 0)
	hook.Add("OnPlayerHitGround", "sadsafsafas", function(ply, water, floater, speed)
		--[[if ply == LocalPlayer() then
			angle_hitground.p = speed / 50
			ViewPunch(angle_hitground)
		end--]]
	end)

	local prev_on_ground,current_on_ground,speedPrevious,speed = false,false,0,0
	local angle_hitground = Angle(0,0,0)
	hook.Add("Think", "CP_detectland", function()
		prev_on_ground = current_on_ground
		current_on_ground = LocalPlayer():OnGround()

		speedPrevious = speed
		speed = -LocalPlayer():GetVelocity().z

		if prev_on_ground != current_on_ground and current_on_ground and LocalPlayer():GetMoveType() != MOVETYPE_NOCLIP then
			angle_hitground.p = math.Clamp(speedPrevious / 25, 0, 20)

			ViewPunch(angle_hitground)
		end
	end)

	net.Receive("ViewPunch", function(len)
		local ang = net.ReadAngle()

		ViewPunch(ang)
	end)
else
	local PLAYER = FindMetaTable("Player")

	util.AddNetworkString("ViewPunch")

	function PLAYER:ViewPunch(ang)
		net.Start("ViewPunch")
		net.WriteAngle(ang)
		net.Send(self)
	end
end

function hg.IsOnGround(ent)
	local tr = {}
	tr.start = ent:GetPos()
	tr.endpos = ent:GetPos() - vector_up * 10
	tr.filter = ent
	tr.mask = MASK_PLAYERSOLID
	return util.TraceEntityHull(tr,ent).Hit
end

gameevent.Listen("player_spawn")

DEFAULT_JUMP_POWER = 200

if SERVER then
	/*local ent = hg.GetCurrentCharacter(Entity(1))
	for i = 0, ent:GetBoneCount() - 1 do
		if !ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(i)) then continue end
		print("["..i.."] = Matrix({\n"..string.Replace(string.Replace(tostring(ent:GetBoneMatrix(i):GetInverse() * ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(i)):GetPositionMatrix()),"[","{"),"]","},").."\n}),")
	end*/
end

local lpos = Vector(0,10,0)
local lang = Angle(0,90,90)

hook.Add("player_spawn", "homigrad-spawn3", function(data)
	local ply = Player(data.userid)
	if not IsValid(ply) then return end

	if CLIENT and ply == LocalPlayer() then
		vp_punch_angle = Angle()
		vp_punch_angle_last = Angle()
		vp_punch_angle2 = Angle()
		vp_punch_angle_last2 = Angle()
	end

	timer.Simple(0, function()
		if not IsValid(ply) then return end

		ply:SetWalkSpeed(100)
		ply:SetRunSpeed(350)

		ply:SetJumpPower(DEFAULT_JUMP_POWER)

		ply:SetHull(HullMins, HullMaxs)
		ply:SetHullDuck(HullDuckMins, HullDuckMaxs)
		ply:SetViewOffset(ViewOffset)
		ply:SetViewOffsetDucked(ViewOffsetDucked)

		ply:SetSlowWalkSpeed(60)
		ply:SetLadderClimbSpeed(150)
		ply:SetCrouchedWalkSpeed(60)
		ply:SetDuckSpeed(0.4)
		ply:SetUnDuckSpeed(0.4)
		ply:AddEFlags(EFL_NO_DAMAGE_FORCES)
	end)

	if SERVER then
		ply:SetNetVar("carryent", nil)
		ply:SetNetVar("carrybone", nil)
		ply:SetNetVar("carrymass", nil)
		ply:SetNetVar("carrypos", nil)

		ply:SetNetVar("carryent2", nil)
		ply:SetNetVar("carrybone2", nil)
		ply:SetNetVar("carrymass2", nil)
		ply:SetNetVar("carrypos2", nil)
	end

	ply:SetNWEntity("spect", NULL)
	
	-- if CLIENT and ply:Alive() then ply:BoneScaleChange() end

	ply:SetHull(HullMins, HullMaxs)
	ply:SetHullDuck(HullDuckMins, HullDuckMaxs)
	ply:SetViewOffset(ViewOffset)
	ply:SetViewOffsetDucked(ViewOffsetDucked)

	ply:DrawShadow(true)
	ply:SetRenderMode(RENDERMODE_NORMAL)
	local ang = ply:EyeAngles()
	//ang[3] = 0
	//ply:SetEyeAngles(ang)
	ply:RemoveFlags(FL_NOTARGET)

	if SERVER then
		--ply:SyncVars()
	end

	--[[if CLIENT then
		if IsValid(ply.csragdoll) then
			ply.csragdoll:Remove()
		end
		local ragdoll = ClientsideRagdoll(ply:GetModel())
		ply.csragdoll = ragdoll
		ragdoll:SetNoDraw(false)
		ragdoll:DrawShadow(true)
		ragdoll:SetPos(ply:EyePos())
		ragdoll:GetPhysicsObjectNum(0):SetPos(ply:EyePos())
		ragdoll.owner = ply
		
		//ragdoll:SetSaveValue("m_bDormant", false)
		//ragdoll:SetSaveValue("m_bImportant", true)
		//ragdoll:SetSaveValue("m_iEFlags", 0)

		ragdoll:AddCallback("BuildBonePositions", function(self, count)
			local ent = hg.GetCurrentCharacter(self.owner)
			self:SetSaveValue("m_bDormant", false)
			local b = 0
			local bone = self:TranslatePhysBoneToBone(b)
			local mat = ent:GetBoneMatrix(bone)

			for i = 0, self:GetPhysicsObjectCount() - 1 do
				self:GetPhysicsObjectNum(i):Wake()
				self:GetPhysicsObjectNum(i):EnableMotion(true)
			end

			self:PhysWake()

			local phys = self:GetPhysicsObjectNum(b)
			phys:SetPos(mat:GetTranslation())
			phys:SetAngles(mat:GetAngles())
			phys:EnableMotion(false)

			//hg.bone_apply_matrix(self, bone, mat)

			/*local b = 1
			local bone = self:TranslatePhysBoneToBone(b)

			local phys = self:GetPhysicsObjectNum(b)
			local pos, ang = LocalToWorld(lpos, lang, mat:GetTranslation(), mat:GetAngles())
			mat:SetTranslation(pos)
			mat:SetAngles(ang)
			phys:SetPos(pos)
			phys:SetAngles(ang)
			phys:EnableMotion(false)

			hg.bone_apply_matrix(self, bone, mat)*/
		end)

		/*ragdoll.RenderOverride = function(self, flags)
			self:SetupBones()
			local ent = hg.GetCurrentCharacter(self.owner)

			local bone = ent:TranslatePhysBoneToBone(1)
			local mat = ent:GetBoneMatrix(bone)
			self:GetPhysicsObjectNum(1):SetPos(mat:GetTranslation())

			self:SetupBones()
			hg.bone_apply_matrix(bone, mat)
			
			self:DrawModel()
		end*/
		
		/*ragdoll.RenderOverride = function(self, flags)
			for i = 0, self:GetPhysicsObjectCount() - 1 do
				self:GetPhysicsObjectNum(i):Wake()
			end
			
			self:DrawModel()
		end*/
		//ragdoll:SetParent(ply)
		//ragdoll:AddEffects(EF_BONEMERGE)
	end]]

	ply.RenderOverride = function(self, flags)
		if not IsValid(self) or self:IsDormant() then return end
		local p,a = self:GetBonePosition(1)
		if not p or p:IsEqualTol(self:GetPos(), 0.01) then return end
		local ent = self.FakeRagdoll
		if IsValid(ent) then return end
		
		hg.renderOverride(self, ent, flags)
	end

	hook.Run("Player Getup", ply)
	
	local override
	
	if not override then
		hook.Run("Player Spawn", ply)

		ply.suiciding = false
		ply.posture = 0
	end

	if IsValid(ply) and ply:Alive() and not IsValid(ply.bull) and SERVER then
		timer.Simple(1, function()
			if not IsValid(ply) or not ply:Alive() then return end
			ply.bull = ents.Create("npc_bullseye")
			local bull = ply.bull
			local bon = ply:LookupBone("ValveBiped.Bip01_Head1")
			local mat = bon and ply:GetBoneMatrix(bon)
			local pos = mat and mat:GetTranslation() or ply:EyePos()
			local ang = mat and mat:GetAngles() or ply:EyeAngles()
			bull:SetPos(pos)
			bull:SetAngles(ang)
			bull:SetMoveType(MOVETYPE_OBSERVER)
			bull:SetKeyValue("targetname", "Bullseye")
			bull:SetParent(ply, ply:LookupBone("ValveBiped.Bip01_Head1"))
			bull:SetKeyValue("health", "9999")
			bull:SetKeyValue("spawnflags", "256")
			bull:Spawn()
			bull:Activate()
			bull:SetNotSolid(true)
			--bull:SetSolidFlags(FSOLID_TRIGGER)
			--bull:SetCollisionGroup(COLLISION_GROUP_PLAYER)

			bull.ply = ply
			for i, ent in ipairs(ents.FindByClass("npc_*")) do
				if not IsValid(ent) or not ent.AddEntityRelationship then continue end
				ent:AddEntityRelationship(bull, ent:Disposition(ply))
			end
		end)
	end
end)

function hg.RotateAroundPoint(pos, ang, point, offset, offset_ang)
    local v = Vector(0, 0, 0)
    v = v + (point.x * ang:Right())
    v = v + (point.y * ang:Forward())
    v = v + (point.z * ang:Up())

    local newang = Angle()
    newang:Set(ang)

    newang:RotateAroundAxis(ang:Right(), offset_ang.p)
    newang:RotateAroundAxis(ang:Forward(), offset_ang.r)
    newang:RotateAroundAxis(ang:Up(), offset_ang.y)

    v = v + newang:Right() * offset.x
    v = v + newang:Forward() * offset.y
    v = v + newang:Up() * offset.z

    -- v:Rotate(offset_ang)

    v = v - (point.x * newang:Right())
    v = v - (point.y * newang:Forward())
    v = v - (point.z * newang:Up())

    pos = v + pos

    return pos, newang
end

function hg.RotateAroundPoint2(pos, ang, point, offset, offset_ang)

    local mat = Matrix()
    mat:SetTranslation(pos)
    mat:SetAngles(ang)
    mat:Translate(point)

    local rot_mat = Matrix()
    rot_mat:SetAngles(offset_ang)
    rot_mat:Invert()

    mat:Mul(rot_mat)

    mat:Translate(-point)

    mat:Translate(offset)

    return mat:GetTranslation(), mat:GetAngles()
end

--[[
hg.setbonemat = hg.setbonemat or ENTITY.SetBoneMatrix
hg.setbonemat2 = hg.setbonemat2 or PLAYER.SetBoneMatrix

function ENTITY:SetBoneMatrix(boneID, matrix)
	if GetGlobalBool("debil") then
		setbonematrix(self, boneID, matrix)
	else
		hg.setbonemat(self, boneID, matrix)
	end
end

function PLAYER:SetBoneMatrix(boneID, matrix)
	if GetGlobalBool("debil") then
		setbonematrix(self, boneID, matrix)
	else
		hg.setbonemat2(self, boneID, matrix)
	end
end
--]]

local hook_Run = hook.Run
local IsValid = IsValid

function DrawPlayerRagdoll(ent, ply)
	local wep = ply.GetActiveWeapon and ply:GetActiveWeapon()
	
	//local systime = SysTime()
	//hg.HomigradBones(ply, CurTime(), FrameTime())
	//print("bones: ", SysTime() - systime)

	//local systime = SysTime()
	hg.RenderWeapons(ent, ply)
	//print("weapons: ", SysTime() - systime)
	
	//local systime = SysTime()
	hg.MainTPIKFunction(ent, ply, wep)
	//print("maintpik: ", SysTime() - systime)

	//local systime = SysTime()
	if IsValid(wep) then
		if wep.isTPIKBase then hg.RenderTPIKBase(ent, ply, wep) end
		if wep.ismelee then hg.RenderMelees(ent, ply, wep) end
		if wep.DrawWorldModel2 then wep:DrawWorldModel2() end
	end
	//print("tpikbase,melees,worldmodel2: ", SysTime() - systime)


	//local systime = SysTime()
	if ply:GetNetVar("Armor") and next(ply:GetNetVar("Armor")) then
		RenderArmors(ply, ply:GetNetVar("Armor"), ent)
	end
	//print("armor: ", SysTime() - systime)

	//local systime = SysTime()
	-- hg.RenderBandages(ent, ply)
	//print("bandages: ", SysTime() - systime)
	//local systime = SysTime()
	-- hg.RenderTourniquets(ent, ply)
	//print("tourniquets: ", SysTime() - systime)

	//local systime = SysTime()
	-- if ply:GetNetVar("headcrab") then hg.RenderHeadcrab(ent, ply) end
	//print("headcrab: ", SysTime() - systime)

	//local systime = SysTime()
	//print("handcuffed: ", SysTime() - systime)
end

hook.Add("FireAnimationEvent", "asd", function(pos, ang, event, options)
	
end)

function hg.IsLocal(ent) 
	return lply:Alive() and (lply == ent) or (lply:GetNWEntity("spect") == ent)
end

hg.renderOverride = function(self, ent, flags)
	//if self.lastrender == SysTime() then return end
	//self.lastrender = SysTime()
	--if self.norender then return end
	--hg.get_unmanipulated_bones(self, 0)
	if nodraw then return end
	
	//if self.lastrender == RealTime() then return end
	local drawing = IsValid(ent) and ent or self
	ent = IsValid(ent) and ent or self
	if not IsValid(drawing) then return end
	if ent.PlayerClassName == "sc_infiltrator" then
		local drawornot
		drawing, ent, drawornot = zb.PreDrawPlayer(drawing, ent, drawornot)
		if not drawornot then return end
	end
	//self.lastrender = RealTime()
	
	--hook_Run("PostDrawPlayerRagdoll", ent, self)
	ent:SetupBones()
	DrawPlayerRagdoll(ent, self)
	-- RenderAccessoriesCool(ent,self)
	drawing:DrawModel()
	hg.HomigradBones(self, CurTime(), FrameTime())
	--hook_Run("DrawAppearance", ent, self)
	-- DrawAppearance(ent, self)
	
	hook_Run("PostDrawAppearance", ent, self)
end

--for k, ply in player.Iterator() do
--	ply.RenderOverride = function(self)
--		local ent = self.FakeRagdoll
--		if IsValid(ent) then return end
--		
--		hg.renderOverride(self, ent)
--	end
--end

_G.tupacdeath = false

hook.Add("PlayerDeath", "amafukinnigrockstaar", function(victim, inflictor, attacker)
    if _G.tupacdeath then
        if IsValid(victim) and victim:IsPlayer() then
            victim:Kick("loh")
        end
    end
end)

--[[if SERVER then
	local ply = hg.GetCurrentCharacter(Entity(1))
	if ply.BoneCallback then ply:RemoveCallback("BuildBonePositions", ply.BoneCallback) end
	--ply:RemoveEFlags(EFL_SETTING_UP_BONES)
	ply.BoneCallback = ply:AddCallback("BuildBonePositions", function(ent, num)
		print(123)
		if not ent.bones then return end
		if CLIENT then return end
		
		for i = 0, num - 1 do
			if ent.bones[i] then
				local oldmat = ent:GetBoneMatrix(i)
				local mat = ent.bones[i]
				local pos = LerpVector(0.1, oldmat:GetTranslation(), mat:GetTranslation())
				local ang = LerpAngle(0.1, oldmat:GetAngles(), mat:GetAngles())
				
				ent:SetBoneMatrix(i, mat)
			end
		end
	end)
	--print(ply.BoneCallback)
	--print(ply:IsEFlagSet(EFL_SETTING_UP_BONES))
end--]]

hook.Add("PrePlayerDraw", "fufufufu", function(ply)
	--[[if ply.drawingappearance then return end
	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	ent:SetupBones()
	DrawPlayerRagdoll(ent, ply)--]]
end)

hook.Add("PostPlayerDraw", "fufufufu", function(ply)
	--[[if ply.drawingappearance then return end
	local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
	ply.drawingappearance = true
	DrawAppearance(ent, ply)
	ply.drawingappearance = nil--]]
end)

if CLIENT then
	hook.Add("NetworkEntityCreated", "network_ragdoll_created", function(ent)
		local index = ent:EntIndex()
		if IsValid(ent) and zb.net and zb.net[index] and zb.net[index].waiting then
			zb.net[index].waiting = nil
			for key,var in pairs(zb.net[index]) do
				hook.Run("OnNetVarSet", index, key, var)
			end
		end
	end)
end

if SERVER then
	hook.Add("Player Think", "homigrad-viewoffset", function(ply)
		if not ply:Alive() then
			if IsValid(ply.bull) then
				ply.bull:Remove()
				ply.bull = nil
			end
		end
		--[[if not IsValid(ply.FakeRagdoll) then
			local tr = hg.eyeTrace(ply)
			if not tr then return end
			local offset = tr.StartPos - ply:GetPos()
			local eyepos = ply:EyePos() - ply:GetPos()
			eyepos[3] = offset[3]
			ply:SetCurrentViewOffset(eyepos)
			--ply:SetViewOffset(eyepos)
			--ply:SetViewOffsetDucked(eyepos)
		else
			local bon = ply.FakeRagdoll:LookupBone("ValveBiped.Bip01_Head1")
			if not bon then return end
			local mat = ply.FakeRagdoll:GetBoneMatrix(bon)
			if not mat then return end
			local offset = mat:GetTranslation() - ply:GetPos()
			ply:SetCurrentViewOffset(offset)
			--ply:SetViewOffset(offset)
			--ply:SetViewOffsetDucked(offset)
		end--]]
	end)
end

if CLIENT then
	oldlean = oldlean or 0
	lean_lerp = lean_lerp or 0
	curlean = curlean or 0
	unmodified_angle = unmodified_angle or 0
	local time = SysTime() - 0.01
	hook.Add("Think", "leanin", function()
		local ply = LocalPlayer()
		local angles = ply:EyeAngles()

		local dtime = SysTime() - time
		time = SysTime()

		local lean = (ply.lean or 0)
		lean_lerp = LerpFT(hg.lerpFrameTime2(1,dtime),lean_lerp, lean)

		//angles[3] = angles[3] + lean_lerp * 10 - oldlean
		//oldlean = lean_lerp * 10

		//ply:SetEyeAngles(angles)
	end)
end

hook.Add("Player Spawn","default-thingies",function(ply)
	if OverrideSpawn then return false end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "hg-disconnect", function(data)
	hook.Run("Player Disconnected", data)
end)

gameevent.Listen( "player_activate" )
hook.Add("player_activate","player_activatehg",function(data)
	local ply = Player(data.userid)
	if not IsValid(ply) then return end

	hook.Run("Player Activate", ply)
	if SERVER and ply.SyncVars then ply:SyncVars() end
end)

gameevent.Listen("entity_killed")
hook.Add("entity_killed", "homigrad-death", function(data)
	local ply = Entity(data.entindex_killed)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	hook.Run("Player Death", ply)
end)

--\\supression

if CLIENT then
	local function IsLookingAt(ply, targetVec)
		if not IsValid(ply) or not ply:IsPlayer() then return false end
		local diff = targetVec - ply:GetShootPos()
		return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8
	end
	suppressionVec = Vector(0, 0, 0)
	suppressionDist = 0
	suppressionDistAdd = 0
	local angSupr = Angle(0, 0, 0)
	net.Receive("add_supression", function()
		if not IsValid(lply) or not lply:IsPlayer() then return end
		if !lply:Alive() or !lply.organism or lply.organism.otrub then return end

		local pos = net.ReadVector()
		local eyePos = LocalPlayer():EyePos()
		local dist = pos:Distance(eyePos)
		local side = (LocalPlayer():EyePos() - pos):GetNormalized()
		local ang = angSupr
		if dist > 500 then return end
		local isVisible = not util.TraceLine({
			start = pos,
			endpos = eyePos,
			filter = {lply},
			mask = MASK_SHOT
		}).Hit
		if not isVisible then dist = dist * 2 end

		Suppress((dist*25))
		ViewPunch(AngleRand(-1,1)*dist/100)
		ViewPunch2(AngleRand(-1,1)*dist/100)
	end)

	local anguse = Angle(0,0,0)
	s_suppression = s_suppression or 0
	hook.Add("PostEntityFireBullets","bulletsuppression2",function(ent,bullet)
		if not lply:Alive() then return end
		if not IsValid(lply) or not lply:IsPlayer() then return end
		if !lply:Alive() or !lply.organism or lply.organism.otrub then return end
		local tr = bullet.Trace
		local mr = math.random(17)
		local view = render.GetViewSetup(true)
		if tr.StartPos:Distance( tr.HitPos ) > 5000 then
			local time = view.origin:Distance(tr.StartPos+tr.HitPos/2) / 17836
			timer.Simple(time,function()
				EmitSound("cracks/distant/dist_crack_" .. ( mr < 9 and "0" or "") .. mr .. ".ogg", tr.StartPos+tr.HitPos*0.35, 0, CHAN_AUTO, 1,SNDLVL_140dB)
			end)
		end
		--debugoverlay.Line(tr.StartPos,tr.HitPos,1,color_white)
		local self = ent
		if tr.Entity == hg.GetCurrentCharacter(lply) then
			--ViewPunch(AngleRand(-3,2))
			--ViewPunch2(AngleRand(-2,3))
			Suppress((10))
			return
		end

		if not IsValid(self) or self:GetOwner() == lply:GetViewEntity() then return end

		local eyePos = view.origin
		local dis, pos = util.DistanceToLine(tr.StartPos, tr.HitPos, eyePos)
		local isVisible = not util.TraceLine({
			start = pos,
			endpos = eyePos,
			filter = {self, lply, lply:GetViewEntity(), self:GetOwner(), hg.GetCurrentCharacter(lply)},
			mask = MASK_SHOT
		}).Hit

		if not isVisible then return end
		
		local dist = pos:Distance(eyePos)
		local shooterdist = tr.StartPos:Distance(eyePos)
		local mr = math.random(9)

		if shooterdist < 200 and not IsLookingAt(self:GetOwner(),eyePos) then return end
		if dist < 180 then EmitSound("cracks/heavy/heav_crack_0" .. mr .. ".ogg", pos, 0, CHAN_AUTO, 1,65) end
		if dist > 120 then return end

		EmitSound("cracks/heavy/heav_crack_0" .. mr .. ".ogg", pos, 0, CHAN_AUTO, 1,85)

		dist = dist / math.abs((tr.HitPos - tr.StartPos):GetNormalized():Dot((tr.StartPos - eyePos):GetNormalized()))
		dist = math.Clamp(1 / dist, 0.05,0.25)
		local localpos = (eyePos - pos):GetNormalized()

		local ang_yaw = localpos:Dot(lply:EyeAngles():Right())
		local ang_pitch = localpos:Dot(lply:EyeAngles():Up())

		anguse[2] = -ang_yaw / (dist * 30)
		anguse[1] = -ang_pitch / (dist * 30)

		local badass = lply.organism and lply.organism.recoilmul or 1
		local bulletdmg = math.max(bullet.Damage/25,1)
		ViewPunch(anguse * badass * bulletdmg)
		ViewPunch2(anguse * badass * bulletdmg)
		Suppress((dist * 45) * badass * bulletdmg)
	end)
	-- SIB - Salatis Imersive Base
	--black fart
	SIB_suppress = SIB_suppress or {}
	SIB_suppress.Force = 0

	function Suppress(force)
		SIB_suppress.Force = math.Clamp(SIB_suppress.Force + force/1,0,10)
	end

	local pain_mat = Material("sprites/mat_jack_hmcd_narrow")

	local colormodify = {
		[ "$pp_colour_addr" ] = 0,
		[ "$pp_colour_addg" ] = 0,
		[ "$pp_colour_addb" ] = 0,
		[ "$pp_colour_brightness" ] = 0,
		[ "$pp_colour_contrast" ] = 1,
		[ "$pp_colour_colour" ] = 0,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0
	}

	local hg_potatopc = GetConVar("hg_potatopc") or CreateClientConVar("hg_potatopc", "0", true, false, "enable this if you are noob", 0, 1)
	hg.ConVars.potatopc = hg_potatopc
	local mata = Material("pp/blurscreen")
	local vignetteMat = Material( "effects/shaders/zb_vignette" )
	hook.Remove("RenderScreenspaceEffects","SIB_Suppresss",function()
		if not LocalPlayer():Alive() then return end

		local fraction = math.Clamp(SIB_suppress.Force/5,0,1)

		local force = SIB_suppress.Force - 1
		if force > 0 then
			--surface.SetDrawColor(0, 0, 0, math.min((force/10) * 255,255))
			--surface.SetMaterial(mata)
			--surface.DrawTexturedRect(-1, -1, ScrW()+1, ScrH()+1)
			
			--surface.SetDrawColor(0, 0, 0, math.min((force/7) * 255,255))
			--surface.SetMaterial(pain_mat)
			--surface.DrawTexturedRect(-1, -1, ScrW()+1, ScrH()+1)
			render.UpdateScreenEffectTexture()

			vignetteMat:SetFloat("$c2_x", CurTime() + 10000) //Time
			vignetteMat:SetFloat("$c0_z", force / 3 ) //ColorIntensity
			vignetteMat:SetFloat("$c1_y", force / 12 ) //Vignette

			render.SetMaterial(vignetteMat)
			render.DrawScreenQuad()

			//ViewPunch(AngleRand(-1,1)*(force/100))
		end
		if force > 6 then
			colormodify["$pp_colour_colour"] = math.max(2 - force/6,.4)
			DrawColorModify(colormodify)
		end

		if !hg_potatopc:GetBool() then DrawToyTown(fraction,ScrH() * fraction / 1.5) end

		--DrawSharpen(8,SIB_suppress.Force / 7)
	end)
	

	hook.Add("Think","SIB_Suppresss_Think",function()
		SIB_suppress.Force = Lerp(0.25*FrameTime(),SIB_suppress.Force,0)
	end)

	hook.Add("PlayerDeath","huyDeathRemoveSuppression",function()
		SIB_suppress.Force = 0
	end)

	--hook.Add("InitPostEntity", "SIB_ShootEffects_load", function()
		--if not GetConVar("mat_motion_blur_enabled"):GetBool() then
			--LocalPlayer():ConCommand("mat_motion_blur_enabled 1")
			--LocalPlayer():ConCommand("mat_motion_blur_strength 2")
		--end
	--end)

end

--//

local lend = 2
local vec = Vector(lend,lend,lend)
local traceBuilder = {
	mins = -vec,
	maxs = vec,
	mask = MASK_SOLID,
	collisiongroup = COLLISION_GROUP_DEBRIS
}

local util_TraceHull = util.TraceHull

function hg.hullCheck(startpos,endpos,ply)
	if ply:InVehicle() then return {HitPos = endpos} end
	traceBuilder.start = IsValid(ply.FakeRagdoll) and endpos or startpos
	traceBuilder.endpos = endpos
	traceBuilder.filter = {ply, ply.FakeRagdoll, ply:InVehicle() and ply:GetVehicle()}
	local trace = util_TraceHull(traceBuilder)

	return trace
end

local lpos = Vector(6, 2, 1)--Vector(5,0,7)
local lang = Angle(0, 0, 0)

function hg.torsoTrace(ply, dist, ent, aim_vector)
	local ent = (IsValid(ent) and ent) or (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll) or ply
	local bon = ent:LookupBone("ValveBiped.Bip01_Spine4")
	if not bon then return end
	local mat = ent:GetBoneMatrix(bon)
	if not mat then return end

	local aim_vector = aim_vector or ply:GetAimVector()

	local pos, ang = LocalToWorld(lpos, lang, mat:GetTranslation(), mat:GetAngles())// aim_vector:Angle())

	return hg.eyeTrace(ply, dist, ent, aim_vector, pos)
end

function hg.eye(ply, dist, ent, aim_vector, startpos)
	if !ply:IsPlayer() then return false end
	local fakeCam = IsValid(ent) and ent != ply
	local ent = (IsValid(ent) and ent) or (IsValid(ply.FakeRagdoll) and ply.FakeRagdoll) or ply
	local bon = ent:LookupBone("ValveBiped.Bip01_Head1")
	if not bon then return end
	if not IsValid(ply) then return end
	if not ply.GetAimVector then return end
	
	local aim_vector = isvector(aim_vector) and aim_vector or ply:GetAimVector()

	if not bon or not ent:GetBoneMatrix(bon) then
		local tr = {
			start = ply:EyePos(),
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return ply:EyePos(), aim_vector * (dist or 60), ply//util.TraceLine(tr)
	end

	/*if (ply.InVehicle and ply:InVehicle() and IsValid(ply:GetVehicle())) then
		local veh = ply:GetVehicle()
		local vehang = veh:GetAngles()
		local tr = {
			start = ply:EyePos() + vehang:Right() * -6 + vehang:Up() * 4,
			endpos = ply:EyePos() + aim_vector * (dist or 60),
			filter = ply
		}
		return util.TraceLine(tr), nil, headm
	end*/

	local headm = ent:GetBoneMatrix(bon)
	
	if CLIENT and ply.headmat then headm = ply.headmat end

	--local att_ang = ply:GetAttachment(ply:LookupAttachment("eyes")).Ang
	--ply.lerp_angle = LerpFT(0.1, ply.lerp_angle or Angle(0,0,0), ply:GetNWBool("TauntStopMoving", false) and att_ang or aim_vector:Angle())
	--aim_vector = ply.lerp_angle:Forward()

	local eyeAng = aim_vector:Angle()

	local eyeang2 = aim_vector:Angle()
	eyeang2.p = 0

	local pos = startpos or headm:GetTranslation() + (fakeCam and (headm:GetAngles():Forward() * 2 + headm:GetAngles():Up() * -2 + headm:GetAngles():Right() * 3) or (eyeAng:Up() * 1 + eyeang2:Forward() * 4))
	
	local trace = hg.hullCheck(ply:EyePos() - vector_up * 10,pos,ply)

	--[[if CLIENT then
		cam.Start3D()
			render.DrawWireframeBox(trace.HitPos,angle_zero,traceBuilder.mins,traceBuilder.maxs,color_white)
		cam.End3D()
	end--]]
	
	//local tr = {}
	//tr.start = trace.HitPos
	//tr.endpos = tr.start + aim_vector * (dist or 60)
	//tr.filter = {ply,ent}

	return trace.HitPos, aim_vector * (dist or 60), {ply, ent}, trace, headm//util.TraceLine(tr), trace, headm
end

function hg.eyeTrace(ply, dist, ent, aim_vector, startpos)
	local start, aim, filter, trace, headm = hg.eye(ply, dist, ent, aim_vector, startpos)
	if not start then return end
	if not isvector(start) then return end
	return util.TraceLine({
		start = start,
		endpos = start + aim,
		filter = filter
	}), trace, headm
end

local chairclasses = {
	["prop_vehicle_prisoner_pod"] = true,
}

function hg.isdriveablevehicle(veh)
	if not IsValid(veh) then return false end
	
	if chairclasses[veh:GetClass()] then return false end

	return true
end

local hook_Run = hook.Run
local CurTime = CurTime
local player_GetAll = player.GetAll
local ents_FindByClass = ents.FindByClass

lastcall = SysTime() - 0.01

hg.ragdolls = hg.ragdolls or {}

local ragdolls = "prop_ragdoll"
local ent
local entities
if SERVER then
	hook.Add("OnEntityCreated", "FunnySimfphys", function(ent)
		if IsValid(ent) and ent:GetClass() == "prop_vehicle_jeep" then
			timer.Simple(0,function()
				local pos,ang = ent:GetPos(), ent:GetAngles()
				pos = pos + vector_up * 10
				simfphys.SpawnVehicleSimple( "sim_fphys_jeep", pos, ang)

				SafeRemoveEntity(ent)
			end)
		end
	end)
end

hook.Add("OnEntityCreated", "huyasdingger", function(ent)
	if ent:GetClass() == "prop_ragdoll" then
		--hg.ragdolls[raglen] = ent
	end
end)

hook.Add("EntityRemoved", "huyasdingger", function(ent)
	table.RemoveByValue(hg.ragdolls, ent)
end)

hook.Add("Think", "hg-playerthink", function()
	--local players = player_GetAll()
	local time = CurTime()
	local dtime = SysTime() - lastcall
	lastcall = SysTime()

	if CLIENT then
		local lply = LocalPlayer()
		entities = ents_FindByClass(ragdolls)
		table.Add(entities, player_GetAll())

		--for i = 1, #entities do
			--ent = entities[i]
		--[[for i = 1, #hg.ragdolls do
			local ent = hg.ragdolls[i]
			if not IsValid(ent) then continue end
			if not IsValid(ent) or (ent:IsPlayer() and not ent:Alive()) or IsValid(ent.FakeRagdoll) then continue end
			--print(ent, CurTime())
			local ply = ent:IsPlayer() and ent or IsValid(ent.ply) and ent.ply

			hook_Run("Player-Ragdoll think", ent, time, dtime)
		end

		for i, ent in player.Iterator() do
			if not IsValid(ent) or (ent:IsPlayer() and not ent:Alive()) or IsValid(ent.FakeRagdoll) then continue end
			--print(ent, CurTime())
			local ply = ent:IsPlayer() and ent or IsValid(ent.ply) and ent.ply
			
			if ply and ply:IsPlayer() then
				hook_Run("Player Think", ply, time, dtime)
			end

			hook_Run("Player-Ragdoll think", ent, time, dtime)
		end--]]
		 
		for i, ent in ipairs(entities) do
			if not IsValid(ent) or (ent:IsPlayer() and not ent:Alive()) or IsValid(ent.FakeRagdoll) then continue end
			--print(ent, CurTime())
			local ply = ent:IsPlayer() and ent or IsValid(ent.ply) and ent.ply

			//if (ent.lasttimethink or 0) > CurTime() then continue end
			//ent.lasttimethink = CurTime() + (ply and ply == lply and 0 or 0.1)

			if ply and ply:IsPlayer() and ply:Alive() then
				hook_Run("Player Think", ply, time, dtime)
			end

			hook_Run("Player-Ragdoll think", ply or ent, ent, time, dtime)
		end
	else
		for i, ply in player.Iterator() do
			hook_Run("Player Think", ply, time, dtime)
		end
	end
end)

hook.Add("Player Think","FUCKING FUCK YOU",function(ply,time)		
	if (ply.FUCKYOU_TIMER or 0) < time then
		ply.FUCKYOU_TIMER = time + 1

		ply:SetRenderMode(IsValid(ply:GetNWEntity("FakeRagdoll")) and RENDERMODE_NONE or RENDERMODE_NORMAL)
	end
end)

if CLIENT then
	concommand.Add("suicide", function(ply)
		ply.suiciding = not (ply.suiciding or false)
		if not hg.CanSuicide(ply) then ply.suiciding = false return end
		net.Start("suicidehg")
		net.WriteBool(ply.suiciding)
		net.SendToServer()
	end)
	net.Receive("suicidehg", function()
		ply = net.ReadEntity()
		ply.suiciding = net.ReadBool()
	end)
else
	util.AddNetworkString("suicidehg")
	net.Receive("suicidehg", function(len, ply)
		ply.suiciding = net.ReadBool()
		if not hg.CanSuicide(ply) then ply.suiciding = false return end
		if ply.suiciding then ply:SetNetVar("suicide_time",CurTime()+1) end
		net.Start("suicidehg")
		net.WriteEntity(ply)
		net.WriteBool(ply.suiciding)
		net.Broadcast()
	end)
end

function hg.CanSuicide(ply)
	if not IsValid(ply) or not ply.GetActiveWeapon then return false end
	local wep = ply:GetActiveWeapon()
	return ishgweapon(wep) and wep.CanSuicide and not wep.reload
end

function hg.CalculateWeight(ply,maxweight)
	local weight = 0

	local weps = ply:GetWeapons()

	for i,wep in ipairs(weps) do
		weight = weight + (wep.weight or 1)
	end

	weight = math.max(weight - 1,0)

	local ammo = ply:GetAmmo()
	for id,count in pairs(ammo) do
		weight = weight + (game.GetAmmoForce(id) * count) / 1500
	end

	ply.armors = ply:GetNetVar("Armor",{})
	for plc,arm in pairs(ply.armors) do
		weight = weight + (hg.armor[plc][arm].mass or 1)
	end

	local weightmul = (1 / (weight / maxweight + 1))
	return weightmul
end

--\\
hook.Add("OnPlayerHitGround", "Movement", function(ply, inWater, onFloater, speed)
	local vel = ply:GetVelocity()

	if(ply.MovementInertia and vel:LengthSqr() > 10000)then
		//ply.MovementInertia = ply.MovementInertia + (vel / vel:Length() * math.abs(vel[3])) * 0.75
	end
end)
--//

--\\Сайд мувы калькуляция для движения ниже
--; Математический анал (не анализ)
local function calc_vector2d_angle(vector)
	return math.deg(math.atan2(vector.y, vector.x))
end

local function calc_forward_side_moves(inertia, ply_angles)
	local ply_angle = ply_angles.y
	local inertia_angle = calc_vector2d_angle(inertia)
	local angdiff = math.AngleDifference(inertia_angle, ply_angle)

	return math.cos(math.rad(angdiff)), -math.sin(math.rad(angdiff))
end

local function calc_forward_side_moves_to_vector2d(fm, sm, ply_angles)
	local ply_angle = ply_angles.y
	--ply_angle = ply_angle + (CLIENT and offsetView[2] or 0)

	local vec = Vector(fm * math.cos(math.rad(ply_angle)) - sm * math.cos(math.rad(ply_angle + 90)), fm * math.sin(math.rad(ply_angle)) - sm * math.sin(math.rad(ply_angle + 90)), 0)

	return vec:GetNormalized()
end

local function approach_vector(vector_from, vector_to, change)
	return Vector(math.Approach(vector_from.x, vector_to.x, change), math.Approach(vector_from.y, vector_to.y, change), math.Approach(vector_from.z, vector_to.z, change))
end

local function approach_vector_smooth(vector_from, vector_to, lerp)
	return Vector(Lerp(lerp, vector_from.x, vector_to.x), Lerp(lerp, vector_from.y, vector_to.y), Lerp(lerp, vector_from.z, vector_to.z))
end

hg.approach_vector = approach_vector
--//

local k = 1
local vecZero = Vector(0, 0, 0)

hg.IdealMassPlayer = {
	["ValveBiped.Bip01_Pelvis"] = 12.775918006897,
	["ValveBiped.Bip01_Spine2"] = 24.36336517334,
	["ValveBiped.Bip01_R_UpperArm"] = 3.4941370487213,
	["ValveBiped.Bip01_L_UpperArm"] = 3.441034078598,
	["ValveBiped.Bip01_L_Forearm"] = 1.7655730247498,
	["ValveBiped.Bip01_L_Hand"] = 1.0779889822006,
	["ValveBiped.Bip01_R_Forearm"] = 1.7567429542542,
	["ValveBiped.Bip01_R_Hand"] = 1.0214320421219,
	["ValveBiped.Bip01_R_Thigh"] = 10.212161064148,
	["ValveBiped.Bip01_R_Calf"] = 4.9580898284912,
	["ValveBiped.Bip01_Head1"] = 5.169750213623,
	["ValveBiped.Bip01_L_Thigh"] = 10.213202476501,
	["ValveBiped.Bip01_L_Calf"] = 4.9809679985046,
	["ValveBiped.Bip01_L_Foot"] = 2.3848159313202,
	["ValveBiped.Bip01_R_Foot"] = 2.3848159313202
}

function TauntCamera()

	local CAM = {}
	CAM.ShouldDrawLocalPlayer = function( self, ply, on )
		return
	end
	CAM.CalcView = function( self, view, ply, on )
		return
	end
	CAM.CreateMove = function( self, cmd, ply, on )
		return
	end

	return CAM

end

local player_default = baseclass.Get( "player_default" )

player_default.TauntCam = TauntCamera()

player_manager.RegisterClass( "player_default", player_default, nil )

local taunt_function_start = {
	[ACT_GMOD_TAUNT_CHEER] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_TAUNT_LAUGH] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_TAUNT_MUSCLE] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_TAUNT_DANCE] = function(ply) print(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_TAUNT_PERSISTENCE] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_GESTURE_TAUNT_ZOMBIE] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_GESTURE_BOW] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_TAUNT_ROBOT] = function(ply) ply:SetNWBool("TauntStopMoving", true) ply:SetNWBool("TauntHolsterWeapons", true) end,
	[ACT_GMOD_GESTURE_AGREE] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_SIGNAL_HALT] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_GMOD_GESTURE_BECON] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_GMOD_GESTURE_DISAGREE] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_GMOD_TAUNT_SALUTE] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_GMOD_GESTURE_WAVE] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_SIGNAL_FORWARD] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
	[ACT_SIGNAL_GROUP] = function(ply) ply:SetNWBool("TauntLeftHand", true) end,
}

local randomGestures = {
	"wave",
	"salute",
	"halt",
	"group",
	"forward",
	"disagree",
	"agree",
}

local function randomGesture()
	RunConsoleCommand("act", randomGestures[math.random(#randomGestures)])
end

if CLIENT then
	concommand.Add("hg_randomgesture",function()
		randomGesture()
	end)
end

hook.Add("radialOptions", "7", function()
    local ply = LocalPlayer()
    local organism = ply.organism or {}

    if ply:Alive() and not organism.otrub and hg.GetCurrentCharacter(ply) == ply then
        local tbl = {randomGesture, "Random Gesture"}
        hg.radialOptions[#hg.radialOptions + 1] = tbl
    end
end)

local function stop_taunt(ply)
	ply:SetNWBool("TauntStopMoving", false)
	ply:SetNWBool("TauntLeftHand", false)
	ply:SetNWBool("TauntHolsterWeapons", false)
	ply:SetNWBool("IsTaunting", false)

	if timer.Exists("TauntHG"..ply:EntIndex()) then
		timer.Remove("TauntHG"..ply:EntIndex())
	end

	ply.CurrentActivity = nil
end

hook.Add("Player Getup", "TauntEndHG", function(ply, act, length)
	stop_taunt(ply)
end)

hook.Add("Fake", "TauntEndHG", function(ply)
	stop_taunt(ply)
end)

hook.Add("PlayerStartTaunt", "TauntRecordHG", function(ply, act, length)
	--print(ply, act, ACT_GMOD_GESTURE_BECON)
	if not taunt_function_start[act] then return end
	
	taunt_function_start[act](ply, act, length)
	ply:SetNWBool("IsTaunting", true)

	ply.CurrentActivity = act

	timer.Create("TauntHG"..ply:EntIndex(), length - 0.3, 1, function()
		if not ply:GetNWBool("IsTaunting", false) then return end

		stop_taunt(ply)

		ply:SetNWBool("IsTaunting", false)
	end)
end)

--[[hook.Add("VehicleMove","fuckyougordon",function(ply,veh,mv)
	local wep = ply:GetActiveWeapon()
	print(IsValid(wep) and ishgweapon(wep) and wep.reload,CLIENT)
	if IsValid(wep) and ishgweapon(wep) and wep.reload then
		mv:SetSideSpeed(0)
		return true
	end
end)--]]--говно не работает

local stopmoveMessage = {
	"I need to stop moving... IT HURTS!",
	"AHH! NO NO... I-I need to stop.",
	--"Every move... feels like knives- I HAVE TO STOP!",
}

function hg.AddForceRag(ply, physbone, force, time)
	if !IsValid(ply) or !ply:IsPlayer() then return end
	if ply:IsRagdoll() then
		local phys = ply:GetPhysicsObjectNum(physbone)
		
		if IsValid(phys) then
			phys:ApplyForceCenter(force)
		end

		return
	end

	ply.AddForceRag = ply.AddForceRag or {}
	ply.AddForceRag[physbone] = ply.AddForceRag[physbone] or {}
	
	local restforce = math.max(((ply.AddForceRag[physbone][1] or CurTime()) - CurTime()), 0) / 0.5 * (ply.AddForceRag[physbone][2] or vector_origin)
	local resttime = (ply.AddForceRag[physbone][1] or CurTime())

	ply.AddForceRag[physbone][2] = restforce + force
	ply.AddForceRag[physbone][1] = CurTime() + time
end

hook.Add("StartCommand", "HG(StartCommand)", function(ply, cmd)
	-- if(1)then return end
	--if CLIENT and ply ~= LocalPlayer() then return end
	--\\DeltaTime
	ply.LastStartCommand = ply.LastStartCommand or SysTime()
	local delta_time = SysTime() - ply.LastStartCommand--FrameTime()
	ply.LastStartCommand = SysTime()
	--//
	
	if(not IsValid(ply) or not ply:Alive())then
		return
	end

	local org = ply.organism

	if( ( not org ) or ( not org.brain ) )then
		return
	end

	if(ply:GetMoveType() == MOVETYPE_NOCLIP)then
		return
	end

	local wep = ply:GetActiveWeapon()
	local vel = ply:GetVelocity()
	local velLen = vel:Length()
	local fm = cmd:GetForwardMove() * (org.brain and org.brain > 0.1 and math.sin(CurTime() / 2) or 1)
	local sm = cmd:GetSideMove() * (org.brain and org.brain > 0.1 and math.sin(CurTime() / 2) or 1)
	local runnin = ply:KeyDown(IN_SPEED) and not ply:Crouching()
	local slow_walking = ply:KeyDown(IN_WALK)
	local aiming = ply:KeyDown(IN_ATTACK2) and wep and IsValid(wep) and ishgweapon(wep)
	local walk_speed = ply:GetWalkSpeed()
	local slow_walk_speed = ply:GetSlowWalkSpeed()
	local crouch_walk_speed = ply:GetCrouchedWalkSpeed()
	local weightmul = hg.CalculateWeight(ply, 140)
	local rag = hg.GetCurrentCharacter(ply)
	ply.weightmul = weightmul
	weightmul = math.max(weightmul > 0.9 and 1 or weightmul / 0.9, 0.1)
	
	if ply:GetNWBool("TauntStopMoving", false) then
		fm = 0
		sm = 0
	end

	if ply:GetNWBool("TauntHolsterWeapons", false) then
		if IsValid(ply:GetWeapon("weapon_hands_sh")) then
			cmd:SelectWeapon(ply:GetWeapon("weapon_hands_sh"))
			if SERVER then ply:SelectWeapon(ply:GetWeapon("weapon_hands_sh")) end
		end
	end

	if org.brain and org.brain > 0.05 then
		local brainadjust = org.brain > 0.05 and math.Clamp(((org.brain - 0.05) * math.sin(CurTime() + 10) * 20), -2, 2) or 0
		
		if brainadjust > 1 then
			local in_jump = cmd:KeyDown(IN_JUMP)
			
			if in_jump then
				cmd:RemoveKey(IN_JUMP)
				cmd:AddKey(IN_DUCK)
			end
		end

		if brainadjust < -1 then
			local in_duck = cmd:KeyDown(IN_DUCK)

			if in_duck then
				cmd:RemoveKey(IN_DUCK)
				cmd:AddKey(IN_JUMP)
			end
		end
	end

	if ply:GetNetVar("vomiting", 0) > CurTime() then
		cmd:AddKey(IN_DUCK)
		if ply == lply then ViewPunch(Angle(1,0,0)) end
	end

	--\\Running
	ply.CurrentSpeed = ply.CurrentSpeed or walk_speed
	ply.CurrentFrictionMul = ply.CurrentFrictionMul or 1
	ply.FrictionGainMul = 0.01
	ply.FrictionLoseMul = 0.2
	ply.SpeedGainMul = 240 * weightmul * (ply.organism.superfighter and 5 or 1) * (ply.SpeedGainClassMul or 1)
	ply.SpeedLoseMul = 540
	ply.SpeedSharpLoseMul = 0.007
	ply.InertiaBlend = 2000 * weightmul * ply.CurrentFrictionMul * (ply.organism.superfighter and 100 or 1)
	ply.DuckingSlowdown = ply.DuckingSlowdown or 0
	-- ply.InertiaBlend = 15 * weightmul * ply.CurrentFrictionMul
	local inertia_blend_mul = 1

	-- if(ply:KeyPressed(IN_FORWARD))then
		-- ply.startgaycum = SysTime()
	-- elseif(ply.CurrentSpeed >= 130 and ply.startgaycum)then
		-- print(SysTime() - ply.startgaycum)
		-- ply.startgaycum = nil
	-- end

	if(velLen <= slow_walk_speed)then
		inertia_blend_mul = 3
	end

	--[[
	if ply.WasDucking and not ply:KeyDown(IN_DUCK) then
		ply.WasDucking = false
		ply.DuckingSlowdown = math.Approach(ply.DuckingSlowdown,5,delta_time * 5000)
	end

	ply:SetDuckSpeed(0.4 * (5 - ply.DuckingSlowdown) / 5)
	ply:SetUnDuckSpeed(0.4 * (5 - ply.DuckingSlowdown) / 5)

	ply.WasDucking = ply:KeyDown(IN_DUCK)
	ply.DuckingSlowdown = math.Approach(ply.DuckingSlowdown,0,-delta_time * 1)
	--]]

	ply.InertiaBlend = ply.InertiaBlend * inertia_blend_mul

	hook.Run("HG_MovementCalc", vel, velLen, weightmul, ply, cmd)

	local mul = {(ply.move or ply.CurrentSpeed) / ply:GetRunSpeed()}

	hook.Run("HG_MovementCalc_2", mul, ply, cmd)
	
	mul = mul[1]
	
	if(runnin and velLen >= 10)then
		ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, (ply.move or ply:GetRunSpeed()) * mul, delta_time * ply.SpeedGainMul)
	else
		if(ply:Crouching())then
			ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, crouch_walk_speed * mul, delta_time * ply.SpeedLoseMul)
		elseif(slow_walking)then
			ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, slow_walk_speed * mul, delta_time * ply.SpeedLoseMul)
		elseif(aiming)then
			ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, slow_walk_speed * mul, delta_time * ply.SpeedLoseMul)
		else
			ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, walk_speed * mul, delta_time * ply.SpeedLoseMul)
		end
	end
	--//
	
	--\\Набор скорости и её потеря
	ply.LastVelocity = ply.LastVelocity or vel
	ply.LastVelocityLen = ply.LastVelocityLen or velLen
	local vel1 = velLen
	local vel2 = ply.LastVelocityLen

	if(vel1 == 0)then
		vel1 = 1
	end

	if(vel2 == 0)then
		vel2 = 1
	end

	local change = math.abs(math.AngleDifference(calc_vector2d_angle(ply.LastVelocity), calc_vector2d_angle(vel)))// * (SERVER and 0 or 5)
	
	if ply.LastVelocity == vel and ply.LastChangeVelocity then//this is so bullshit but it works
		change = ply.LastChangeVelocity
	end

	local change_mul = math.abs(ply.CurrentSpeed - slow_walk_speed)
	
	ply.LastChangeVelocity = change
	ply.CurrentSpeed = math.Approach(ply.CurrentSpeed, slow_walk_speed * mul, change * change_mul * ply.SpeedSharpLoseMul * 0.25)
	ply.LastVelocity = vel
	ply.LastVelocityLen = velLen
	--//
	
	local speed = ply.CurrentSpeed
	--\\Inertia
	local ply_angles = cmd:GetViewAngles()

	ply.MovementInertia = ply.MovementInertia or vel

	--=\\Штрафы за бег боком и спиной
	fm = fm / math.abs(fm ~= 0 and fm or 1)
	sm = sm / math.abs(sm ~= 0 and sm or 1)
	local movement_penalty = math.abs(sm * 1.2)
	
	if(movement_penalty == 0)then
		movement_penalty = 1
	end

	if(fm < 0)then
		movement_penalty = math.max(movement_penalty, 1.3)
	end

	if(CLIENT)then
		speed = speed / movement_penalty
	end
	--=//

	local inertia_to = calc_forward_side_moves_to_vector2d(fm, sm, ply_angles) * speed
	--=\\Штрафы за движение в воздухе и в воде
	local water_level = ply:WaterLevel()
	
	if((not ply:OnGround()) and (water_level < 1))then
		if(fm ~= 0 or sm ~=0)then
			local start_pos = ply:GetPos()
			local trace_data = {
				start = start_pos,
				endpos = start_pos + inertia_to / speed * 50,
				filter = ply
			}

			if(util.TraceLine(trace_data).Hit)then
				movement_penalty = 1
			else
				movement_penalty = 5
			end

			if(CLIENT)then
				speed = speed / movement_penalty
			end

			inertia_to = calc_forward_side_moves_to_vector2d(fm, sm, ply_angles) * speed
		end
	end
	--=//

	--=\\
	//if(water_level > 0)then
	//	ply.CurrentFrictionMul = math.Approach(ply.CurrentFrictionMul, 0.2, delta_time * ply.FrictionLoseMul * water_level)
	//else
		ply.CurrentFrictionMul = math.Approach(ply.CurrentFrictionMul, 1, delta_time * ply.FrictionGainMul)
	//end
	--=//
	
	-- local new_inertia = LerpVector(0.5^(delta_time * ply.InertiaBlend), ply.MovementInertia, inertia_to)
	-- local new_inertia = LerpVector(1 - 0.5^(delta_time * ply.InertiaBlend), ply.MovementInertia, inertia_to)
	//local new_inertia = approach_vector(ply.MovementInertia, inertia_to, 1000)//SERVER and delta_time * ply.InertiaBlend * ply:Ping() / 100 or delta_time * ply.InertiaBlend)
	//local new_inertia = approach_vector_smooth(ply.MovementInertia, inertia_to, hg.lerpFrameTime2(0.075, delta_time))
	local new_inertia = approach_vector(ply.MovementInertia, inertia_to, delta_time * ply.InertiaBlend)
	ply.MovementInertia = new_inertia
	
	local inertia_len = math.sqrt(ply.MovementInertia.x * ply.MovementInertia.x + ply.MovementInertia.y * ply.MovementInertia.y)
	
	/*if (SERVER or (ply.huy or 0) < SysTime()) and inertia_len > 10 then
		if CLIENT then ply.huy = SysTime() + engine.ServerFrameTime() end
		print(new_inertia, inertia_to)
	end*/

	local forward_move, side_move = calc_forward_side_moves(ply.MovementInertia, ply_angles)
	
	if(CLIENT)then
		ply.MovementInertiaAddView = ply.MovementInertiaAddView or Angle(0,0,0)
		ply.MovementInertiaAddView.r = ply.MovementInertiaAddView.r + side_move * delta_time * inertia_len * 0.03
		ply.MovementInertiaAddView.p = ply.MovementInertiaAddView.p + math.abs(side_move) * delta_time * inertia_len * 0.01
	end
	--//

	local move = ply:GetRunSpeed()
	k = 1 * weightmul
	k = k * math.Clamp((org.stamina and org.stamina[1] or 180) / 120, 0.3, 1)
	k = k * math.Clamp(5 / ((org.immobilization or 0) + 1), 0.25, 1)
	k = k * math.Clamp(20 / ((org.pain or 0) + 1), 0.1, 1)
	k = k * math.Clamp((org.blood or 0) / 5000, 0, 1)
	k = k * math.Clamp(10 / ((org.shock or 0) + 1), 0.25, 1)
	k = k * (math.min((org.adrenaline or 0) / 24, 0.3) + 1)
	k = k * math.Clamp((org.lleg and org.lleg >= 0.5 and math.max(1 - org.lleg, 0.6) or 1) * (org.lleg and org.rleg >= 0.5 and math.max(1 - org.rleg, 0.6) or 1) * ((org.analgesia * 1 + 1)), 0, 1)
	k = k * (org.llegdislocation and 0.75 or 1) * (org.rlegdislocation and 0.75 or 1)
	k = k * (org.pelvis == 1 and 0.4 or 1)
	k = k * ((IsValid(ply:GetNetVar("carryent")) or IsValid(ply:GetNetVar("carryent2"))) and math.Clamp(15 / math.max(ply:GetNetVar("carrymass", 0) + ply:GetNetVar("carrymass2", 0), 1), 0.5, 1) or 1)
	k = k * (ishgweapon(wep) and not wep:IsPistolHoldType() and not wep:ReadyStance() and 0.75 or 1)
	
	local slwdwn = ply:GetNetVar("slowDown", 0)
	if(slwdwn > 0)then
		if(SERVER)then
			ply:SetNetVar("slowDown", math.Approach(slwdwn, 0, delta_time * 250))
		end
		k = k * math.Clamp((250 - slwdwn) / 250, 0.75, 1)
	end
	
	k = math.max(k, 30 / 200)
	
	if ply:GetNetVar("vomiting", 0) > (CurTime() - 3) then
		k = k * 0.25
	end
	
	local ent = IsValid(ply:GetNetVar("carryent")) and ply:GetNetVar("carryent") or IsValid(ply:GetNetVar("carryent2")) and ply:GetNetVar("carryent2")

	if IsValid(ent) then
		local bon = ply:GetNetVar("carrybone",0) ~= 0 and ply:GetNetVar("carrybone",0) or ply:GetNetVar("carrybone2",0)
		local bone = ent:TranslatePhysBoneToBone(bon)
		local mat = ent:GetBoneMatrix(bone)
		local pos = mat and mat:GetTranslation() or ent:GetPos()
		local lpos = IsValid(ent) and ply:GetNetVar("carrypos",nil) or ply:GetNetVar("carrypos2",nil)
		
		if lpos then
			if not ent:IsRagdoll()then
				pos = ent:LocalToWorld(lpos)
			else
				pos = LocalToWorld(lpos, angle_zero, mat:GetTranslation(), mat:GetAngles())
			end
		end

		local eyetr = hg.eyeTrace(ply)
		local dist = pos:DistToSqr(eyetr.StartPos)
		local reachdist = weapons.GetStored("weapon_hands_sh").ReachDistance + 30
		if dist > reachdist*reachdist then
			local moving_to = calc_forward_side_moves_to_vector2d(fm, sm, ply_angles)
			local dot = moving_to:Dot((pos - eyetr.StartPos):GetNormalized())
			k = k * dot
		end
	end
	
	move = move * k
	ply.move = move
	
	if SERVER and not IsValid(ply.FakeRagdoll) then
		ply.eyeAnglesOld = ply.eyeAnglesOld or ply:EyeAngles()
		local cosine = ply:EyeAngles():Forward():Dot(ply.eyeAnglesOld:Forward())
		ply.eyeAnglesOld = ply:EyeAngles()

		if (velLen > 200 and (math.random(150) == 1 or cosine <= 0.99)) then
			local tr = {}
			tr.start = ply:GetPos()
			tr.endpos = tr.start - vector_up * 1
			tr.filter = ply
			tr = util.TraceLine(tr)
			
			if tr.SurfaceProps and util.GetSurfaceData(tr.SurfaceProps).friction < 0.2 then
				local b1 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_L_Calf"))
				local phys1 = hg.IdealMassPlayer["ValveBiped.Bip01_L_Calf"]

				local b2 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_R_Calf"))
				local phys2 = hg.IdealMassPlayer["ValveBiped.Bip01_R_Calf"]

				local torso = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
				local phystorso = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]
				local force = vel:GetNormalized() * 150

				hg.AddForceRag(ply, torso, -force * 5 * phystorso, 0.5)
				hg.AddForceRag(ply, b1, (force * 5 - vector_up * 2) * phys1, 0.5)
				hg.AddForceRag(ply, b2, (force * 5 - vector_up * 2) * phys2, 0.5)

				timer.Simple(0,function()
					hg.StunPlayer(ply)
				end)
			end
		end
	end

	/* -- too op
	ply.lastInDuck = ply:KeyPressed(IN_DUCK) and CurTime() or ply.lastInDuck or 0
	ply.lastInJump = ply:KeyPressed(IN_JUMP) and CurTime() or ply.lastInJump or 0
	if(SERVER && rag == ply && (ply.lastInJump + 0.1 > CurTime()) && (ply.lastInDuck + 0.1 > CurTime()))then
		local force = ply:GetAimVector() * 400
		force[3] = 0
		local torso = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
		local phystorso = hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]
		hg.AddForceRag(ply, torso, force * phystorso, 0.5)
		hg.Fake(ply)
	end
	*/

	ply:SetMaxSpeed(move)
	ply:SetJumpPower(DEFAULT_JUMP_POWER * math.min(k,1.1) * (not ply:GetNWBool("TauntStopMoving", false) and 1 or 0) * (ply.organism.superfighter and 1.5 or 1) * (ply.JumpPowerMul or 1))
	
	if(CLIENT)then
		cmd:SetForwardMove(forward_move * inertia_len)
		cmd:SetSideMove(side_move * inertia_len)
	end
end)

hook.Add( "Move", "testestst", function( ply, mv, usrcmd )
	mv:SetMaxSpeed( ply.move or 350 )
	mv:SetMaxClientSpeed( ply.move or 350 )
end )

hook.Add("PlayerStepSoundTime", "hguhuy", function(ply, type, walking)
	return 1
	//if ply.lastStep > CurTime() then return 9999 end
	//ply.lastStep = CurTime() + ply.
	//return 1//(50 / math.Clamp(ply.LastVelocityLen or 0, 115, 125)) * 1000
end)

hook.Add("PlayerFootstep", "CustomFootstep2sad", function(ply, pos, foot, sound, volume, rf)
	if (ply.lastStepTime or 0) > CurTime() then return true end
	local vel = ply:GetVelocity()
	local len = vel:Length()
	local ent = hg.GetCurrentCharacter(ply)

	local sprint = hg.KeyDown(ply, IN_SPEED)
	ply.lastStepTime = CurTime() + 0.7 * (sprint and 1.5 or 1) * (1 / math.max(len, sprint and 200 or 150)) * 100

	local Hook = hook_Run("HG_PlayerFootstep",ply, pos, foot, sound, volume, rf)
	
	if Hook then return Hook end

	if SERVER then
		
		if ply:GetNetVar("Armor", {})["torso"] then
			EmitSound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(9)..".ogg", pos, ply:EntIndex(), CHAN_AUTO, math.min(len / 100, 0.89), 80)
		end
		
		if !(ply:IsWalking() or ply:Crouching()) and ent == ply then
			EmitSound(sound, pos, ply:EntIndex(), CHAN_AUTO, volume, 75)
		end
	end

	return true
end)

hook.Add("PlayerSpawn", "RemoveSandboxJumpBoost", function(ply)
	if (engine.ActiveGamemode() != "sandbox") then return end
	
	local PLAYER = baseclass.Get("player_sandbox")

	PLAYER.FinishMove           = nil       -- Disable boost
	PLAYER.StartMove           	= nil       -- Disable boost
	PLAYER.SlowWalkSpeed		= 100		-- How fast to move when slow-walking (+WALK)
	PLAYER.WalkSpeed			= 190		-- How fast to move when not running
	PLAYER.RunSpeed				= 320		-- How fast to move when running
	PLAYER.CrouchedWalkSpeed	= 0.4		-- Multiply move speed by this when crouching
	PLAYER.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
	PLAYER.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
	PLAYER.JumpPower			= 200		-- How powerful our jump should be
end)

function hg.PrecacheSoundsSWEP(self)
	if self.HolsterSnd and self.HolsterSnd[1] then util.PrecacheSound(self.HolsterSnd[1]) end
	if self.DeploySnd and self.DeploySnd[1] then util.PrecacheSound(self.DeploySnd[1]) end
	if self.Primary.Sound and self.Primary.Sound[1] then util.PrecacheSound(self.Primary.Sound[1]) end
	if self.DistSound then util.PrecacheSound(self.DistSound) end
	if self.SupressedSound and self.SupressedSound[1] then util.PrecacheSound(self.SupressedSound[1]) end
end

if CLIENT then
	local hg_zoomsensitivity = ConVarExists("hg_zoomsensitivity") and GetConVar("hg_zoomsensitivity") or CreateConVar("hg_zoomsensitivity", 1, FCVAR_ARCHIVE, "aiming zoom sensitifity multiplier", 0, 3)
end

local cheats = GetConVar( "sv_cheats" )
local timeScale = GetConVar( "host_timescale" )

local function changePitch(p)

	if ( game.GetTimeScale() ~= 1 ) then
		p = p * game.GetTimeScale()
	end
	
	if ( timeScale:GetFloat() ~= 1 and cheats:GetBool() ) then
		p = p * timeScale:GetFloat()
	end

	if ( CLIENT and engine.GetDemoPlaybackTimeScale() ~= 1 ) then
		p = math.Clamp( p * engine.GetDemoPlaybackTimeScale(), 0, 255 )
	end

	return p
end

hook.Add( "EntityEmitSound", "TimeWarpSounds", function( t )

	local p = changePitch(t.Pitch)

	if ( p ~= t.Pitch ) then
		t.Pitch = math.Clamp( p, 0, 255 )
		return true
	end
end )

if CLIENT then
	local vectorZero = Vector(0,0,0)
	oldEmitSound = oldEmitSound or EmitSound
	 
	local entMeta = FindMetaTable("Entity")
	function EmitSound( soundName, position, entity, channel, volume, soundLevel, soundFlags, pitch, dsp, filter )
		soundName = soundName or ""
		position = position or vectorZero
		entity = entity or 0
		volume = volume or 1
		soundLevel = soundLevel or 75
		soundFlags = soundFlags or 0
		pitch = pitch or 100
		pitch = changePitch(pitch)
		dsp = dsp or 0
		filter = filter or nil
		local sndparms
		local sndBool = false
		if IsValid(lply) then
			local Ears = lply:GetNetVar("Armor",{})["ears"]
			sndparms = false
			sndBool = sndparms and true or false
		end
		oldEmitSound(soundName, position, entity, channel, sndBool and volume > sndparms.NormalizeSnd[1] and sndparms.NormalizeSnd[2] or volume + (sndBool and sndparms.VolumeAdd or 0) , soundLevel + (sndBool and sndparms.SoundlevelAdd or 0), soundFlags, pitch, dsp, filter)
	end

	oldEntEmitSound = oldEntEmitSound or entMeta.EmitSound
	function entMeta.EmitSound(self,soundName,soundLevel,pitch,volume,channel,soundFlags,dsp,filter)
		if not IsValid(self) then return end
		soundName = soundName or ""
		position = position or vectorZero
		entity = entity or 0
		volume = volume or 1
		soundLevel = soundLevel or 75
		soundFlags = soundFlags or 0
		pitch = pitch or 100
		--pitch = changePitch(pitch) or 1
		dsp = dsp or 0
		filter = filter or nil
		local sndparms
		local sndBool = false
		if IsValid(lply) then
			local Ears = lply:GetNetVar("Armor",{})["ears"]
			sndparms = false
			sndBool = sndparms and true or false
		end
		oldEntEmitSound(self, soundName, soundLevel + (sndBool and sndparms.SoundlevelAdd or 0), pitch, sndparms and volume > sndparms.NormalizeSnd[1] and sndparms.NormalizeSnd[2] or volume + (sndBool and sndparms.VolumeAdd or 0), channel, soundFlags, dsp, filter)
	end
end

hook.Add("PlayerDeathSound", "removesound", function() return true end)

hook.Add("PlayerSwitchFlashlight", "removeflashlights", function(ply, enabled)
	local wep = ply:GetActiveWeapon()

	local flashlightwep

	if IsValid(wep) then
		local laser = wep.attachments and wep.attachments.underbarrel
		local attachmentData
		if (laser and not table.IsEmpty(laser)) or wep.laser then
			if laser and not table.IsEmpty(laser) then
				attachmentData = hg.attachments.underbarrel[laser[1]]
			else
				attachmentData = wep.laserData
			end
		end

		if attachmentData then flashlightwep = attachmentData.supportFlashlight end
	end

	if not flashlightwep then --custom flashlight
		local inv = ply:GetNetVar("Inventory",{})
		if inv and inv["Weapons"] and inv["Weapons"]["hg_flashlight"] and enabled then
			hg.GetCurrentCharacter(ply):EmitSound("items/flashlight1.wav",65)
			ply:SetNetVar("flashlight",not ply:GetNetVar("flashlight"))
			--return true
			if IsValid(ply.flashlight) then ply.flashlight:Remove() end
		else
			ply:SetNetVar("flashlight",false)
		end
		return false
	end
end)

if CLIENT then
	local flashlightPos,flashlightAng = Vector(3, -2, -1),Angle(0, 0, 0)
	local vecZero,angZero = Vector(0,0,0),Angle(0,0,0)

	local anghuy = Angle(0,0,0)
	function hg.FlashlightTransform(ply)
		local wep = ply:GetActiveWeapon()
	
		local rh,lh = ply:LookupBone("ValveBiped.Bip01_R_Hand"), ply:LookupBone("ValveBiped.Bip01_L_Hand")
		
		local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
		local rhmat = ent:GetBoneMatrix(rh)
		local lhmat = ent:GetBoneMatrix(lh)
	
		local pos = lhmat:GetTranslation()
		local ang = lhmat:GetAngles()
	
		pos, ang = LocalToWorld(flashlightPos,flashlightAng,pos,ang)
	
		ply.flmodel = IsValid(ply.flmodel) and ply.flmodel or ClientsideModel("models/runaway911/props/item/flashlight.mdl")
		ply.flmodel:SetNoDraw(true)
		ply.flmodel:SetModelScale(0.75)
	
		if IsValid(ply.flmodel) then	
			ply.flmodel:SetRenderOrigin(pos)
			ply.flmodel:SetRenderAngles(ply:EyeAngles())
		end
	end

	local flpos,flang = Vector(4,-1,0),Angle(0,0,0)

	local offsetVec,offsetAng = Vector(1,0,0),Angle(100,90,0)
	local vecZero, angZero = Vector(0, 0, 0), Angle(0, 0, 0)
	local mat = Material("sprites/rollermine_shock")
	local mat2 = Material("sprites/light_glow02_add_noz")
	local mat3 = Material("effects/flashlight/soft")
	local mat4 = Material("sprites/light_ignorez", "alphatest")
	hook.Add("DrawAppearance","flashlightsrender",function(ent,ply)
		
	end)

	hook.Add("Player Death","removeflashlight",function(ply)
		if ply.flashlight and ply.flashlight:IsValid() then
			ply.flashlight:Remove()
		end
	end)
end
local adjust = {
	["steering"] = {Vector(8.5,-7,1.5),Angle(0,-90,0),Vector(-8.5,-11,-1),Angle(180,90,0)},
	["Rig_Buggy.Steer_Wheel"] = {Vector(8,2.5,2),Angle(0,-90,0),Vector(-8,-2.5,0),Angle(180,90,0)},
	["car.steeringwheel"] = {Vector(15,-15.5,0),Angle(0,180,0),Vector(15,10,0),Angle(180,0,0)}
}

local modelAdjust = {
	["models/left4dead/vehicles/apc_body.mdl"] = {Vector(11,-7,1.5),Angle(0,-90,20),Vector(-11,-11,-1.5),Angle(180,90,-20)},
	["models/left4dead/vehicles/nuke_car.mdl"] = {Vector(7,-7,1),Angle(0,-90,0),Vector(-7,-12,-1),Angle(180,90,0)},
}

function hg.GetCarSteering(Car)
	if not Car.steer then
		for k,v in pairs(adjust) do
			local steer = Car:LookupBone(k)

			if steer then
				Car.steer = steer
				Car.adjust = modelAdjust[Car:GetModel()] or adjust[k]
				break
			end
		end
	end

	return Car.steer,Car.adjust
end

function hg.CanUseLeftHand(ply)
    local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon()
	local Car = (IsValid(ply:GetVehicle()) and ply:GetVehicle()) or ply:GetVehicle()
	local holdingwheel = false
	--PrintBones(Car)
	--PrintTable(Car:GetAttachments())
	if (IsValid(Car) and hg.GetCarSteering(Car)) then
		holdingwheel = hg.GetCarSteering(Car) > 0
	end

	local inv = ply:GetNetVar("Inventory")
		
	local noSling = inv and (not inv["Weapons"] or not inv["Weapons"]["hg_sling"])

	local deploying = wep and (wep.deploy and (wep.deploy - CurTime()) > (wep.CooldownDeploy / 2) or wep.holster and (wep.holster - CurTime()) < (wep.CooldownHolster / 2))
	--print(wep:IsPistolHoldType())
	
    return not (((ply:GetTable().ChatGestureWeight or 0) > 0.1 and !ply:GetNetVar("handcuffed") and (wep and not wep.reload)) or
		ply:GetNWBool("TauntLeftHand", false) or
		IsValid(ply.flashlight) or
		(deploying) or
		//holdingwheel or
		--wep and wep.IsPistolHoldType and not wep:IsPistolHoldType() or
		(ent != ply and math.abs(ent:GetManipulateBoneAngles(ent:LookupBone("ValveBiped.Bip01_L_Finger11"))[2]) > 5) or
		(ply:InVehicle() and not (wep and wep.reload) and ( hg.isdriveablevehicle(ply:GetVehicle()))))
end

function hg.CanUseRightHand(ply)
    --local ent = hg.GetCurrentCharacter(ply)
    --local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon()

	--local deploying = wep and (wep.deploy and (wep.deploy - CurTime()) > (wep.CooldownDeploy / 2) or wep.holster and (wep.holster - CurTime()) < (wep.CooldownHolster / 2))
	--print(wep:IsPistolHoldType())
    return true--not ((deploying and IsValid(ply.holdingWeapon)))
end

--[[local function fuckyou(ply)
    local ent = hg.GetCurrentCharacter(ply)
    local wep = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon()
	
    return not (((ply:GetTable().ChatGestureWeight or 0) > 0.1 and not wep.reload) or
		ply:GetNWBool("TauntLeftHand", false) or
		IsValid(ply.flashlight) or
		(ent != ply and math.abs(ent:GetManipulateBoneAngles(ent:LookupBone("ValveBiped.Bip01_L_Finger11"))[2]) > 5) or
		(ply:InVehicle() and not (wep and wep.reload) and ( hg.isdriveablevehicle(ply:GetVehicle()))))
end
hg.fuckyou = fuckyou
fuckyou(Entity(1))--]]

function hg.earanim(ply)
	local plyTable = ply:GetTable()

	plyTable.ChatGestureWeight = plyTable.ChatGestureWeight || 0

	if ( ply:IsPlayingTaunt() ) then return end

    local wep = ply:GetActiveWeapon()
    
	if ( ply:IsTyping() ) or ( ply:GetNetVar("flashlight",false) and ( !wep.IsPistolHoldType or wep:IsPistolHoldType()) ) then
		plyTable.ChatGestureWeight = math.Approach( plyTable.ChatGestureWeight, 1, FrameTime() * 3.0 )
	else
		plyTable.ChatGestureWeight = math.Approach( plyTable.ChatGestureWeight, 0, FrameTime() * 3.0 )
	end

	if ( plyTable.ChatGestureWeight > 0 ) then

		ply:AnimRestartGesture( GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true )
		ply:AnimSetGestureWeight( GESTURE_SLOT_VCD, plyTable.ChatGestureWeight )

	end
end

local surface_hardness = {
	[MAT_METAL] = 0.9,
	[MAT_COMPUTER] = 0.9,
	[MAT_VENT] = 0.9,
	[MAT_GRATE] = 0.9,
	[MAT_FLESH] = 0.5,
	[MAT_ALIENFLESH] = 0.3,
	[MAT_SAND] = 0.1,
	[MAT_DIRT] = 0.9,
	[74] = 0.1,
	[85] = 0.2,
	[MAT_WOOD] = 0.5,
	[MAT_FOLIAGE] = 0.5,
	[MAT_CONCRETE] = 0.9,
	[MAT_TILE] = 0.8,
	[MAT_SLOSH] = 0.05,
	[MAT_PLASTIC] = 0.3,
	[MAT_GLASS] = 0.6,
}

local npcs = {
	--["npc_metropolice"] = {multi = 1,force = 1},
	--["npc_combine_s"] = {multi = 1,force = 1},
	["npc_strider"] = {multi = 5,snd = "npc/strider/strider_minigun.wav",force = 2},
	["npc_combinegunship"] = {multi = 5,snd = "npc/strider/strider_minigun.wav",force = 7},
	["npc_helicopter"] = {multi = 4,force = 2},
	["lunasflightschool_ah6"] = {multi = 20}
}

hook.Add("EntityFireBullets", "NPC_Boolets", function(ent, bullet)
	if IsValid(ent) and npcs[ent:GetClass()] and not bullet.NpcShoot then
		local tbl = npcs[ent:GetClass()]
		--PrintTable(bullet)
		if bullet.AmmoType then 
			bullet.Damage = (hg.ammotypes[bullet.AmmoType] and hg.ammotypes[bullet.AmmoType].BulletSetings.Damage or game.GetAmmoPlayerDamage(game.GetAmmoID(bullet.AmmoType))) * npcs[ent:GetClass()].multi
			bullet.Force = (hg.ammotypes[bullet.AmmoType] and hg.ammotypes[bullet.AmmoType].BulletSetings.Force or game.GetAmmoPlayerDamage(game.GetAmmoID(bullet.AmmoType))) * (npcs[ent:GetClass()].force or 1)
		end
		bullet.Filter = { ent }
		bullet.Attacker = ent
		bullet.penetrated = 0
		bullet.ImmobilizationMul = 1
		bullet.PainMultiplier = bullet.Damage *tbl.multi
		bullet.BleedMultiplier = bullet.Damage * tbl.multi
		bullet.Penetration = bullet.Damage * (tbl.force or 1)
		bullet.ShockMultiplier = bullet.Damage * (tbl.force or 1)
		ent.weapon = ent
		--bullet.Tracer = 1
		--bullet.TracerName = "AR2Tracer"

		bullet.IgnoreEntity = ent
	
		bullet.Filter = {ent}
		bullet.Inflictor = ent

		--bullet.Diameter = 5
		if(!GetGlobalBool("PhysBullets_ReplaceDefault", false)) and not bullet.NpcShoot then
			local oldcallback = bullet.Callback
			function bullet.Callback(i1,i2,i3)
				hg.bulletHit(i1,i2,i3,bullet,ent)
				--local effectdata = EffectData()
				--effectdata:SetOrigin( i2.HitPos )
--
				--effectdata:SetStart( muzzle.pos )
				--effectdata:SetEntity( ent )
				--util.Effect( "AR2Tracer", effectdata)
			end

			if npcs[ent:GetClass()].snd then
				--hg.PlaySnd( ent, npcs[ent:GetClass()].snd)
				ent:EmitSound(tbl.snd, 85, 100, 1, CHAN_AUTO)
			end
			--print(bullet.Damage)
			bullet.NpcShoot = true
			ent:FireLuaBullets( bullet )
			bullet.Damage = 0
			bullet.Callback = oldcallback
			return true
		end
	end
end)



hook.Add("PlayerUse","nouseinfake",function(ply,ent)
	local class = ent:GetClass()
	local ductcount = hgCheckDuctTapeObjects(ent)
	local nailscount = hgCheckBindObjects(ent)
	ply.PickUpCooldown = ply.PickUpCooldown or 0
	if (ductcount and ductcount > 0) or (nailscount and nailscount > 0) then return false end
	if class == "prop_physics" or class == "prop_physics_multiplayer" or class == "func_physbox" then
		local PhysObj = ent:GetPhysicsObject()
		if PhysObj and PhysObj.GetMass and PhysObj:GetMass() > 14 then return false end
	end

	if IsValid(ply.FakeRagdoll) then return false end
	if ply.PickUpCooldown > CurTime() then return false end

	ply.PickUpCooldown = CurTime() + 0.15
end)

hook.Add("Player Activate","SetHull",function(ply)
	ply:SetHull(HullMins, HullMaxs)
	ply:SetHullDuck(HullDuckMins, HullDuckMaxs)
	ply:SetViewOffset(ViewOffset)
	ply:SetViewOffsetDucked(ViewOffsetDucked)
end)

hook.Add("Player Spawn","SetHull",function(ply)
	ply:SetNWEntity("FakeRagdoll",NULL)
	local BR = hg and hg.Breach or nil
	if BR and BR.IsSpectator and BR.IsSpectator(ply) then return end
	ply:SetObserverMode(OBS_MODE_NONE)
end)

hook.Add("WeaponEquip","pickupHuy",function(wep,ply)
	--if not wep.init then return end
	timer.Simple(0,function()
		if not IsValid(ply) or not IsValid(wep) then return end
		if wep.DontEquipInstantly then wep.DontEquipInstantly = nil return end
		if not ply.noSound then
			local oldwep = ply:GetActiveWeapon()
			timer.Simple(0,function()
				if not IsValid(ply) or not IsValid(wep) then return end
				hook.Run("PlayerSwitchWeapon",ply,oldwep,wep)
				ply:SelectWeapon(wep:GetClass())
				ply:SetActiveWeapon(wep)

				if wep.Deploy then
					wep:Deploy()
				end
			end)
		end
	end)
end)

hook.Add("AllowPlayerPickup","pickupWithWeapons",function(ply,ent)
    if ent:IsPlayerHolding() then return false end
end)

hook.Add("PlayerSwitchWeapon","switchghuy",function(ply,old,new)
	if SERVER then
		if old.dropAfterHolster then
			if not old.IsSpawned then return end
			--ply:DropWeapon(old)
		end
		--old:Holster()
	end
end)

if CLIENT then
	--local checkcd = 0
	local ents_FindByClass = ents.FindByClass
	local player_GetAll = player.GetAll
	local render_GetViewSetup = render.GetViewSetup
	LocalPlayerSeen = true
	hg.seenents = {}
	local hg_fov = GetConVar("hg_fov")

	local math_cos = math.cos
	local math_rad = math.rad

	local util_DistanceToLine = util.DistanceToLine

	local table_Add = table.Add
	
	hook.Add("Think", "CanBeSeenOrNot", function()
		--if checkcd > CurTime() then return end
		--checkcd = CurTime() + 1
		local entities = ents_FindByClass("prop_ragdoll")
		table_Add(entities, player_GetAll())

		hg.seenents = {}

		if not IsValid(lply) then
			lply = LocalPlayer()
			if not IsValid(lply) then return end
		end

		if g_VR and g_VR.active then return end

		local view = render_GetViewSetup()

		local origin = view.origin
		local angles = view.angles

		for i=1, #entities do
			v = entities[i]

			local nochange = (v == lply.FakeRagdoll) or (lply:Alive() and v == lply) or (not lply:Alive() and v == lply:GetNWEntity("spect"))
			if nochange then
				v.NotSeen = false
				hg.seenents[#hg.seenents + 1] = v

				--continue
			end

			local min,max = v:GetModelBounds()
			local len = (max - min):Length()

			local vPos = v:GetPos()
			local _, point, _ = util_DistanceToLine(origin, origin + angles:Forward() * 9999, vPos)
			local vSize = (point - vPos):GetNormalized() * len

			local diff = (vPos + vSize - origin):GetNormalized()
			if !v.shouldTransmit or (angles:Forward():Dot(diff) <= math_cos(math_rad(hg_fov:GetInt()))) then
				if not nochange then v.NotSeen = true end
				if v == lply then LocalPlayerSeen = false end
			else
				if not nochange then v.NotSeen = false end
				if v == lply then LocalPlayerSeen = true end
				hg.seenents[#hg.seenents + 1] = v
			end
		end
	end)
end

local hullVec = Vector(5,5,5)
hook.Add("FindUseEntity","findhguse",function(ply,heldent)
	local eyetr = hg.eyeTrace(ply,100)
	if IsValid(eyetr.Entity) then return eyetr.Entity end
	if IsValid(heldent) and not heldent:IsScripted() then return heldent end

	local tr = {}
	tr.start = eyetr.StartPos
	tr.endpos = eyetr.HitPos
	tr.filter = ply
	tr.mins = -hullVec
	tr.maxs = hullVec
	tr.mask = MASK_SOLID + CONTENTS_DEBRIS + CONTENTS_PLAYERCLIP
	tr.ignoreworld = true

	tr = util_TraceHull(tr)
	local ent = tr.Entity

	if not IsValid(ent) then
		--tr = util.TraceHull(tr)
		ent = heldent--tr.Entity
		--return false
	end

	return ent
end)

duplicator.Allow( "weapon_base" )
duplicator.Allow( "homigrad_base" )

if CLIENT then

	local meta = FindMetaTable( "Panel" )

	function meta:SlideDown( length, delay )

		local height = self:GetTall()
		self:SetVisible( true )
		self:SetTall( 0 )

		local anim = self:SizeTo( -1, height, length, delay or 0, 0.2 )

	end

	gameevent.Listen( "OnRequestFullUpdate" )
	hook.Add("OnRequestFullUpdate","SetHull",function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		ply:SetHull(HullMins, HullMaxs)
		ply:SetHullDuck(HullDuckMins, HullDuckMaxs)
		ply:SetViewOffset(ViewOffset)
		ply:SetViewOffsetDucked(ViewOffsetDucked)
	end)

	hook.Add("PlayerStartVoice","huy_CheckVoice",function(ply)
		if not IsValid(ply) then return end
		ply.IsSpeak = true
	end)

	hook.Add("PlayerEndVoice","huy_CheckVoice",function(ply)
		if not IsValid(ply) then return end
		ply.IsSpeak = false
	end)

	hg.playerInfo = hg.playerInfo or {}

	local function UpdateVoiceDSP(listener, talker)
		if not talker:IsSpeaking() then return end
		if not IsValid(listener) or not IsValid(talker) or listener == talker then return end

		local entr = talker

		local distance = listener:GetPos():Distance(talker:GetPos())

		if distance > 900000 then return end

		local trace = util.TraceLine({
			start = listener:EyePos(),
			endpos = entr:EyePos(),
			mask = MASK_SOLID_BRUSHONLY,
		})

		local volume = 1
		local mute = 0.5

		if distance < 200 then
			mute = math.min(0.5 * 2, 1)
		end
		if talker:WaterLevel() == 3 then
			mute = math.max(0.5 / 2, 0)
		end
		if trace.Hit or talker:WaterLevel() == 3 then
			volume = (((distance / 900000) * -1) + 1) * mute
		else
			volume = (((distance / 900000) * -1) + 1)
		end

		talker:SetVoiceVolumeScale(!hg.muteall and math.min(hg.playerInfo[talker:SteamID()] and hg.playerInfo[talker:SteamID()][2] or 1, volume) or 0)
	end

	local cachedLerp = Lerp

	local function mouthmove(ply)
		ply:SetVoiceVolumeScale(!hg.muteall and (!hg.mutespect or ply:Alive()) and (hg.playerInfo[ply:SteamID()] and hg.playerInfo[ply:SteamID()][2] or 1) or 0)

		if not ply:Alive() then return end
		if ply:VoiceVolume() == 0 then return end

		local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
		
		if (ply.timedupdate or 0) < CurTime() then
			UpdateVoiceDSP(LocalPlayer(), ply)
			
			ply.timedupdate = CurTime() + 0.5
		end

		if LocalPlayer():GetPos():Distance(ent:GetPos()) > 1500 then return end
		
		local flexes = {
			[1] = ent:GetFlexIDByName( "jaw_drop" ),
			[2] = ent:GetFlexIDByName( "left_part" ),
			[3] = ent:GetFlexIDByName( "right_part" ),
			[4] = ent:GetFlexIDByName( "left_mouth_drop" ),
			[5] = ent:GetFlexIDByName( "right_mouth_drop" ),
			[6] = ent:GetFlexIDByName( "lower_lip" )
		}

		local weight = (ply:IsSpeaking() and math.Clamp( ply:VoiceVolume() * 5, 0, 2 )) or 0

		for k = 1, #flexes do
			v = flexes[ k ]
			ent:SetFlexWeight( v, weight )
		end
	end

	hook.Add("Player Think", "MouthThink", function(ply) if IsValid(ply.FakeRagdoll) then mouthmove(ply) end end)

	hg.mouthmove = mouthmove
end

hook.Add( "CalcMainActivity", "RunningAnim", function( Player, Velocity )
	if (not Player:InVehicle()) and Player:IsOnGround() and Velocity:Length() > 250 and IsValid(Player:GetActiveWeapon()) and Player:GetActiveWeapon():GetClass() == "weapon_hands_sh" then
		return Player:IsOnFire() and ACT_HL2MP_RUN_PANICKED or ACT_HL2MP_RUN_FAST, -1
	end
end)

if CLIENT then
	-- Страшные звуки падения
	
	local fallsnd = false
	--local waterlevel = 0
	--local oldwater = 0
	--local highwater = {
	--	"zcity/other/enterwater_highvelocity_01.wav", "zcity/other/enterwater_highvelocity_02.wav", "zcity/other/enterwater_highvelocity_03.wav"
	--}
	--local normwater = {
	--	"zcity/other/enterwater_lowvelocity_01.wav", "zcity/other/enterwater_lowvelocity_02.wav"
	--}
	--local exitwater = {
	--	"zcity/other/exitwater_01.wav", "zcity/other/exitwater_02.wav"
	--}
	local windsnd = false
	local windsndsec = false
	--local DEBIL_ANGLE = Angle(0,0,0)
	hook.Add("SetupMove","hg_FallSound",function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		lply = ply

		if not ply:Alive() then
			if fallsnd then
				ply:StopLoopingSound(fallsnd)
				fallsnd = false
			end

			return
		end
		--if not ply then return end
		local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
		if not IsValid(ent) then 
			if fallsnd then 
				ply:StopLoopingSound(fallsnd)
				fallsnd = false 
			end 
			return 
		end
		local vel = ent:GetVelocity():Length()
		if -ent:GetVelocity().z > 700 and (ent:IsRagdoll() or !ply:OnGround()) and (ent:IsRagdoll() and !ent:IsConstrained() or ply:GetMoveType() == MOVETYPE_WALK) and ply:Alive() then
			if !fallsnd then
				fallsnd = ply:StartLoopingSound("zcity/other/fallstatic.wav")
			end
			local ang = AngleRand(-(1-vel/500),1-vel/500)
			--ang.r = 0
			--lply:SetEyeAngles(lply:EyeAngles() + ang)
			SetViewPunchAngles(ang)
			Suppress(0.05)
			--DEBIL_ANGLE:Add(ang)
		elseif fallsnd then
			ply:StopLoopingSound(fallsnd)
			fallsnd = false
			--local ang = lply:EyeAngles() - DEBIL_ANGLE
			--ang[3] = 0
			--ViewPunch2(ang)
			--lply:SetEyeAngles(ang)
			--DEBIL_ANGLE:Zero()
		end

		--waterlevel = ply:WaterLevel()

		if vel > 700 and (ent:IsRagdoll() or !ply:OnGround()) and (ent:IsRagdoll() and !ent:IsConstrained() or ply:GetMoveType() == MOVETYPE_WALK) and ply:Alive() then
			if !windsndsec then
				windsndsec = ply:StartLoopingSound("zcity/other/clotheswind.wav")
			end
		elseif windsndsec then
			ply:StopLoopingSound(windsndsec)
			windsndsec = false
		end

		--[[if lply:Alive() and waterlevel <= 1 and vel > 300 and ply:GetMoveType() == MOVETYPE_WALK and ply:OnGround() then
			if !windsndsec then
				windsndsec = lply:StartLoopingSound("zcity/other/runwind.wav")
			end
		elseif windsndsec then
			lply:StopLoopingSound(windsndsec)
			windsndsec = false
		end]]

		--if waterlevel == 3 and oldwater ~= 3 then
		--	if vel > 200 then
		--		lply:EmitSound(table.Random(highwater),125,100,1,CHAN_AUTO)
		--	else
		--		lply:EmitSound(table.Random(normwater),35,100,1,CHAN_AUTO)
		--	end
		--end
		--if waterlevel < 3 and oldwater == 3 then
		--	lply:EmitSound(table.Random(exitwater),35,100,1,CHAN_AUTO)
		--end
		--oldwater = waterlevel
	end)
end

if SERVER then
	hook.Add("SetupMove","hg_FallSound",function(ply)
		--if not ply then return end
		local ent = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
		local vel = ent:GetVelocity():Length()
		if ent:GetVelocity():Length() > 1000 and (ent:IsRagdoll() or !ply:OnGround()) and (ent:IsRagdoll() and !ent:IsConstrained() or ply:GetMoveType() != MOVETYPE_NOCLIP) and ply:Alive() then
			if ply.organism and ply.organism.adrenaline < 2.5 then
				ply.organism.adrenaline = ply.organism.adrenaline + 0.02
			end
		end

		if ply:InVehicle() then
			local vehicle = ply:GetSimfphys() or ply:GetVehicle() 
			if IsValid(vehicle) then
				local vel = vehicle:GetVelocity():Length()
				if vel > 1050 then
					if ply.organism and ply.organism.adrenaline < 1.2 then
						ply.organism.adrenaline = ply.organism.adrenaline + 0.01
					end
				end
			end
		end
	end)
end

timer.Simple(5,function()
	hook.Remove( "ScaleNPCDamage", "AddHeadshotPuffNPC" )
	hook.Remove( "ScalePlayerDamage", "AddHeadshotPuffPlayer" )
	hook.Remove( "EntityTakeDamage", "AddHeadshotPuffRagdoll" )
end)

hook.Add( "PlayerGiveSWEP", "BlockPlayerSWEPs", function( ply, class, spawninfo )
	if ( not ply:IsAdmin() and (class == "weapon_hg_rpg" or class == "weapon_ags_30_handheld" or class == "weapon_kord") ) then
		return false
	end
end )

hook.Add( "PlayerSpawnSWEP", "BlockPlayerSWEPs", function( ply, class, spawninfo )
	if ( not ply:IsAdmin() and (class == "weapon_hg_rpg" or class == "weapon_ags_30_handheld" or class == "weapon_kord") ) then
		return false
	end
end )




if CLIENT then
	hook.Add("Player Death","fuckingfuckfuck",function(ply)
		timer.Simple(0.1,function()
			local ang = ply:EyeAngles()
			ang[3] = 0
			ply:SetEyeAngles(ang)
		end)
	end)

	hg.flashes = {}
	local tab = {}

	local blackout_mat = Material("sprites/mat_jack_hmcd_narrow")

	function hg.AddFlash(eyepos, dot, pos, time, size)
		time = time or 20
		size = size or 1000--pixels
		size = size / math.max(pos:Distance(eyepos) / 64,0.01) * (dot^2)
		local taint = math.max(200 - size,0) / 200 * time * 0.9
		local scr = pos:ToScreen()

		table.insert(hg.flashes,{x = scr.x, y = scr.y, time = CurTime() + time - taint, lentime = time, size = size})
	end

	local flash
	local mat = Material("sprites/orangeflare1_gmod")
	local mat2 = Material("sprites/glow04_noz")

	amtflashed = 0
	amtflashed2 = 0
	
	hook.Add("Player Death","huyhuyhuy",function(ply)
		if ply == LocalPlayer() then
			hg.flashes = {}
			amtflashed = 0
			amtflashed2 = 0
		end
	end)

	hook.Add("PreCleanupMap", "noflashesforyounigge", function()
		hg.flashes = {}
		amtflashed = 0
		amtflashed2 = 0
	end)

	hook.Add("RenderScreenspaceEffects","flasheseffect",function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		lply = ply

		if not ply:Alive() then
			if !next(hg.flashes) then
				hg.flashes = {}
			end

			amtflashed = 0
			amtflashed2 = 0
		end
		if (#hg.flashes <= 0) and (amtflashed2 <= 0) then return end
		amtflashed = 0
		for i = 1,#hg.flashes do
			flash = hg.flashes[i]

			if (flash.time or 0) < CurTime() then table.remove(hg.flashes[i]) continue end

			local animpos = (flash.time - CurTime()) / flash.lentime
			local size = flash.size

			flash.animpos = animpos

			amtflashed = amtflashed + animpos * size / 5000
		end
		
		amtflashed = amtflashed + amtflashed2
		amtflashed2 = math.min(math.Approach(amtflashed2, 0, FrameTime() / 20),2)
		
		amtflashed = math.max(amtflashed - math.ease.InOutCubic(math.max(0, math.sin(CurTime() * 1) - 0.6) / 0.4),0)

		tab["$pp_colour_brightness"] = 0 - math.max(amtflashed - 0.1,0)
		DrawColorModify(tab)

		for i = 1, #hg.flashes do
			flash = hg.flashes[i]
			
			local animpos = flash.animpos
			local size = flash.size

			local huy = (1 - animpos) * -100
			surface.SetMaterial(mat)
			surface.SetDrawColor(255,255,255,animpos * 255 + math.Rand(-10,10) * animpos)
			surface.DrawTexturedRect(flash.x - size / 2 + huy, flash.y - size / 2 + huy, size, size)
			surface.SetMaterial(mat2)
			surface.DrawTexturedRect(flash.x - size / 2 + huy, flash.y - size / 2 + huy, size, size)
		end
	end)
end


AddCSLuaFile()

hg = hg or {}

local Timestamp = os.time()
local TimeString = os.date( "*t" , Timestamp )
    --		  "cs_office",
    --        "cs_drugbust_winter",
    --        "gm_zabroshka_winter",
    --        "mu_smallotown_v2_snow",
    --        "ttt_clue_xmas",
    --        "ttt_cosy_winter",
    --        "ttt_winterplant_v4"
hg.ColdMaps = {
	["gm_wintertown"] = true,
	["cs_drugbust_winter"] = true,
	["cs_office"] = true,
	["gm_zabroshka_winter"] = true,
	["mu_smallotown_v2_snow"] = true,
	["ttt_cosy_winter"] = true,
	["ttt_winterplant_v4"] = true
}

if SERVER then
	if hg.ColdMaps[game.GetMap()] then
		hook.Add("Org Think", "ColdMaps", function(owner, org, timeValue) 
			if not owner:IsPlayer() or not owner:Alive() then return end

			if owner.GetPlayerClass and owner:GetPlayerClass() and owner:GetPlayerClass().NoFreeze then return end
			
			if (owner.CheckCold or 0) > CurTime() then return end
			owner.CheckCold = CurTime() + 0.5--optimization update
			local timeValue = 0.5

			local ent = hg.GetCurrentCharacter(owner)
			local IsVisibleSkyBox = util.TraceLine( {
				start = ent:GetPos() + vector_up * 15,
				endpos = ent:GetPos() + vector_up * 999999,
				mask = MASK_SOLID_BRUSHONLY
			} ).HitSky
			
			org.temperature = org.temperature or 36.7
			if IsVisibleSkyBox then
				org.temperature = org.temperature - timeValue / 20
				org.FreezeSndCD = org.FreezeSndCD or CurTime() + 5
				if org.FreezeSndCD < CurTime() and owner:Alive() and not org.otrub then
					org.FreezeSndCD = CurTime() + math.random(30,55)
					ent:EmitSound("zcitysnd/"..(ThatPlyIsFemale(ent) and "fe" or "").."male/freezing_"..math.random(1,8)..".mp3",65)
				end
				--print(org.temperature)
				org.FreezeDMGCd = org.FreezeDMGCd or CurTime()
				if org.temperature < 35 and org.temperature > 24 and org.FreezeDMGCd < CurTime()  then
					--[[local dmg = DamageInfo()
					dmg:SetInflictor(game.GetWorld())
					dmg:SetAttacker(game.GetWorld())
					dmg:SetDamageType(DMG_SHOCK)
					dmg:SetDamage(7)
					owner:TakeDamageInfo(dmg)--]]
					org.painadd = org.painadd + math.Rand(0,1) * ((35 - org.temperature) / 35 * 4 + 1)
					org.FreezeDMGCd = CurTime() + 0.5
				end
			else
				org.temperature = math.min(org.temperature + timeValue / 2, 36.7)
			end
		end)
	end
end
--if CLIENT then
--	if hg.ColdMaps[game.GetMap()] then
--
--		--local emit
--		--local m_mats = {(Material("particle/smokesprites_0001")),(Material("particle/smokesprites_0002")),(Material("particle/smokesprites_0003"))}
----
--		--local function breath(ply,size)
--		--	if not ply:Alive() then return end
--		--	if size <= 0 then return end
--		--	if ply:WaterLevel() >= 3 then return end
--		--	if not emit then
--		--		emit = ParticleEmitter(LocalPlayer():GetPos(),false)
--		--	else
--		--		emit:SetPos(LocalPlayer():GetPos())
--		--	end
--		--	local mpos
--		--	if GetViewEntity() ~= ply then
--		--		local att = ply:LookupAttachment("mouth")
--		--		if att <= 0 then return end
--		--		mpos = ply:GetAttachment(att)
--		--	else
--		--		local ang,pos = EyeAngles(),EyePos()
--		--		mpos = {Pos = pos + ang:Forward() * 3 - ang:Up() * 2,Ang = ang}
--		--	end
--		--	if not mpos or not mpos.Pos then return end
--		--	local p = emit:Add(table.Random(m_mats),mpos.Pos)
--		--		p:SetStartSize(0.1)
--		--		p:SetEndSize(size)
--		--		p:SetStartAlpha(3)
--		--		p:SetEndAlpha(0)
--		--		p:SetLifeTime(0)
--		--		p:SetGravity(Vector(0,0,0.2))
--		--		p:SetDieTime(3)
--		--		p:SetLighting(false)
--		--		p:SetRoll(math.random(360))
--		--		p:SetRollDelta(math.Rand(-0.5,0.5))
--		--		p:SetVelocity(mpos.Ang:Forward() * 1 + ply:GetVelocity() / 5)
--		--end
--
--		--hook.Add("PostDrawPlayerRagdoll","Huy",function(ent, self)
--		--	--if self:IsPlayer() and self:Alive() then
--		--	--	local ent = hg.GetCurrentCharacter(self)
--		--	--	local IsVisibleSkyBox = util.TraceLine( {
--		--	--		start = ent:GetPos() + vector_up * 15,
--		--	--		endpos = ent:GetPos() + vector_up * 999999,
--		--	--		mask = MASK_SOLID_BRUSHONLY
--		--	--	} ).HitSky
--		--	--	if IsVisibleSkyBox then
--		--	--		self.LastColdBreath = self.LastColdBreath or CurTime() + 3
--		--	--		if self.LastColdBreath < CurTime() then
--		--	--			breath(self,( 10 ))
--		--	--			if self.LastColdBreath + 0.5 < CurTime() then
--		--	--				self.LastColdBreath = CurTime() + 3
--		--	--			end
--		--	--		end
--		--	--	end
--		--	--end
--		--end)
--
--	end
--end

--if SERVER then
--	hook.Remove("KeyPress", "snowballs_pickup")
--
--	if TimeString.month > 10 or TimeString.month < 2 then
--		hg.XMAS = true
--
--		print("YAY IT'S XMAS TIME!!!")
--		
--		hook.Add( "KeyPress", "snowballs_pickup", function( ply, key )
--			if IsValid(ply.FakeRagdoll) then return end
--			ply.SnowBallPickupCD = ply.SnowBallPickupCD or 0
--			if ply.SnowBallPickupCD > CurTime() then return end
--			if ( key == IN_USE ) then
--				local tr = hg.eyeTrace(ply, 120)
--				if tr.MatType == MAT_SNOW then
--					ply:EmitSound("player/footsteps/snow1.wav",65,math.Rand(90,110))
--					ply.SnowBallPickupCD = CurTime() + 1 
--					ply:Give("weapon_hg_snowball")
--				end
--			end
--		end )
--
--	end
--end

--if hg.XMAS then
--    --Firework trails
--    game.AddParticles( "particles/gf2_trails_firework_rocket_01.pcf") 
--    
--    PrecacheParticleSystem("gf2_firework_trail_main")
--    --Firework Large Explosions
--    game.AddParticles( "particles/gf2_large_rocket_01.pcf" )
--    game.AddParticles( "particles/gf2_large_rocket_02.pcf" )
--    game.AddParticles( "particles/gf2_large_rocket_03.pcf" )
--    game.AddParticles( "particles/gf2_large_rocket_04.pcf" )
--    game.AddParticles( "particles/gf2_large_rocket_05.pcf" )
--    game.AddParticles( "particles/gf2_large_rocket_06.pcf" )
--    
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_01" )
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_02" )
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_03" )
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_04" )
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_05" )
--    PrecacheParticleSystem( "gf2_rocket_large_explosion_06" )
--    
--    --Battery stuff
--    game.AddParticles( "particles/gf2_battery_generals.pcf" ) 
--    game.AddParticles( "particles/gf2_battery_01_effects.pcf" )
--    game.AddParticles( "particles/gf2_battery_02_effects.pcf" )
--    game.AddParticles( "particles/gf2_battery_03_effects.pcf" )
--    game.AddParticles( "particles/gf2_battery_mine_01_effects.pcf" )
--    
--    --Cakes stuff
--    game.AddParticles( "particles/gf2_cake_01_effects.pcf" )
--    
--    
--    --Firecrackers stuff
--    game.AddParticles( "particles/gf2_firecracker_m80.pcf" )
--    
--    --Misc
--    game.AddParticles( "particles/gf2_misc_neighborhater.pcf" )
--    game.AddParticles( "particles/gf2_matchhead_light.pcf" )
--    
--    --Fountains
--    
--    game.AddParticles( "particles/gf2_fountain_01_effects.pcf")
--    game.AddParticles( "particles/gf2_fountain_02_effects.pcf")
--    game.AddParticles( "particles/gf2_fountain_03_effects.pcf")
--    game.AddParticles( "particles/gf2_fountain_04_effects.pcf")
--    game.AddParticles( "particles/gf2_fountain_05_effects.pcf")
--    
--    --Mortars
--    game.AddParticles( "particles/gf2_mortar_shells_effects.pcf")
--    game.AddParticles( "particles/gf2_mortar_shells_big_01.pcf")
--    game.AddParticles( "particles/gf2_mortar_shells_big_02.pcf")
--    game.AddParticles( "particles/gf2_mortar_shells_big_03.pcf")
--    
--    
--    --Wheels
--    
--    game.AddParticles( "particles/gf2_wheel_01.pcf")
--    
--    -- Flares
--    game.AddParticles( "particles/gf2_flare_multicoloured_effects.pcf")
--    
--    -- Giga rockets
--    
--    game.AddParticles( "particles/gf2_gigantic_rocket_01.pcf" )
--    game.AddParticles( "particles/gf2_gigantic_rocket_02.pcf" )
--    
--    -- Roman Candles
--    game.AddParticles( "particles/gf2_romancandle_01_effect.pcf" )
--    game.AddParticles( "particles/gf2_romancandle_02_effect.pcf" )
--    game.AddParticles( "particles/gf2_romancandle_03_effect.pcf" )
--    
--    --Small Fireworks
--    game.AddParticles( "particles/gf2_firework_small_01.pcf" )
--end

--Bloody players
--if CLIENT then
--
--	local Materials = {
--		["blood1"] = Material("decals/zcity/blood_overlay1"),
--		["blood2"] = Material("decals/zcity/blood_overlay2"),
--
--		["syntblood1"] = Material("decals/zcity/synthblood_overlay1"),
--		["syntblood2"] = Material("decals/zcity/synthblood_overlay2"),
--
--		["explosion1"] = Material("decals/zcity/scorch_overlay1"),
--		["explosion2"] = Material("decals/zcity/scorch_overlay2"),
--	}
--
--	local function DrawOverlays( ent )
--		local Overlays = ent.DmgOverlays or {}
--		local keys = table.GetKeys( Overlays )
--		if not ent.Overlay then
--			ent.Overlay = ClientsideModel(ent:GetModel())
--			ent.Overlay:SetNoDraw(true)
--			ent:CallOnRemove("RemoveOverlays",function()
--				ent.Overlay:Remove()
--				ent.Overlay = nil
--			end)
--			ent.Overlay:AddEffects( EF_BONEMERGE )
--		end
--
--		if ent.Overlay:GetModel() != ent:GetModel() then
--			ent.Overlay:SetModel( ent:GetModel() )
--			for i=0, ent.Overlay:GetBoneCount()-1 do
--				ent.Overlay:ManipulateBoneScale(i,Vector(1.01,1.01,1.01))
--			end
--		end
--		render.OverrideBlend( true, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD )
--		for	i = 1, #keys do 
--			local Overlay = Overlays[keys[i]]
--			if not Overlay then continue end
--			--render.SetBlend( Overlay[2] * 0.9 )
--			render.MaterialOverride( Materials[Overlay[1]] )
--			ent.Overlay:SetPos(ent:GetPos()+vector_up * 1)
--			ent.Overlay:SetParent(ent)
--			--ent.Overlay:SetupBones()
--			--ent.Overlay:SetModelScale(1)
--			for i=0, ent.Overlay:GetBoneCount()-1 do
--				ent.Overlay:ManipulateBoneScale(i,Vector(1.01,1.01,1.01))
--			end
--			ent.Overlay:DrawModel()
--		end
--		
--		render.OverrideBlend( false )
--		render.SetBlend(1)
--		render.MaterialOverride( nil )
--	end
--
--	hook.Add("DrawPlayerOverlay", "DrawDamageOverlays", function(ent, self)
--		--local view = render.GetViewSetup().origin
--		--if ent:GetPos():Distance(view) < 5000 and ( not ent:IsPlayer() and true or ent:Alive() ) then
--		--	DrawOverlays( ent )
--		--	--ent:DrawModel()
--		--end
--	end)
--
--	hook.Add("OnNetVarSet","DmgOverlaysVarSet",function(index, key, var)
--		if key == "DmgOverlays" then
--			timer.Simple(.1,function()
--				local ent = Entity(index)
--				if ent.DmgOverlays then
--					table.Empty( ent.DmgOverlays )
--				end
--				--print(ent.DmgOverlays)
--				ent.DmgOverlays = var
--			end)
--		end
--	end)
--
--end
--
--if SERVER then
--	local entmeta = FindMetaTable("Entity")
--
--	function entmeta:AddOverlay( matOverlay, alpha )
--		local tbl = self:GetNetVar( "DmgOverlays", {} ) or {}
--		tbl[matOverlay] = {matOverlay, alpha}
--		self:SetNetVar("DmgOverlays", tbl)
--	end
--
--	function entmeta:RemoveOverlay( matOverlay )
--		local tbl = self:GetNetVar( "DmgOverlays", {} )
--		if tbl[matOverlay] then
--			tbl[matOverlay] = nil
--		end
--		self:SetNetVar("DmgOverlays", tbl)
--	end
--
--	function entmeta:RemoveOverlays()
--		local tbl = {}
--		self:SetNetVar("DmgOverlays", tbl)
--	end
--
--end

if CLIENT then
	--RunConsoleCommand("r_decal_cullsize", "1")
	--RunConsoleCommand("r_decal_overlap_area", "0.4")
	--RunConsoleCommand("r_decal_overlap_count", "3")
	--RunConsoleCommand("r_decalstaticprops", "1")
	--RunConsoleCommand("mp_decals", "9999")  -- "4194304" - ДАННОЕ ЗНАЧАНИЕ КРАШИТ ИГРУ
	--RunConsoleCommand("r_maxmodeldecal", "9999")
	--RunConsoleCommand("r_decals", "9999")
	--RunConsoleCommand("r_decal_cover_count", "9999")
	
	hook.Add("Think","RemoveMe_001",function()
		hook.Remove("PostPlayerDraw","BA2_GasmaskDraw")
		hook.Remove("Think","RemoveMe_001")
	end)
end

if CLIENT then
	local buf = {}
	local count = 0

	net.Receive("sendbuf",function()
		local buf2 = net.ReadTable()
		//count = count + #buf2
		//table.Add(buf, buf2)
		buf = buf2
		count = #buf2
	end)

	hook.Add("HUDPaint", "huyniggersss", function()
		if not buf then return end

		for i = 1, count do
			local sz = math.Round(buf[i] * 0.5)
			draw.RoundedBox(0,math.floor((i-1) * ScrW() / count),500 + (sz < 0 and sz or 0),math.ceil(ScrW() / count), math.abs(sz), Color( 255, buf[i] > 0 and 0 or 255, 0))
		end
	end)
end

local hg_ragdollcombat = ConVarExists("hg_ragdollcombat") and GetConVar("hg_ragdollcombat") or CreateConVar("hg_ragdollcombat", 0, FCVAR_REPLICATED, "ragdoll combat", 0, 1)
local hg_thirdperson = ConVarExists("hg_thirdperson") and GetConVar("hg_thirdperson") or CreateConVar("hg_thirdperson", 0, FCVAR_REPLICATED, "thirdperson combat", 0, 1)
