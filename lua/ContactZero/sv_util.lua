--
//if util.IsBinaryModuleInstalled( "serversecure" ) then require("serversecure") end

local getBloodColor = FindMetaTable( "Entity" ).GetBloodColor
local isBulletDamage = FindMetaTable( "CTakeDamageInfo" ).IsBulletDamage

local hg_legacycam = ConVarExists("hg_legacycam") and GetConVar("hg_legacycam") or CreateConVar("hg_legacycam", 0, FCVAR_REPLICATED, "ragdoll combat", 0, 1)

local host_timescale = game.GetTimeScale

local util_Decal = util.Decal
local math_random = math.random
local rawget = rawget
local IsValid = IsValid

local bloodColors = {
    [0] = "Blood",
    [1] = "YellowBlood",
    [2] = "YellowBlood",
    [3] = "ManhackSparks",
    [4] = "YellowBlood",
    [5] = "YellowBlood",
    [6] = "YellowBlood"
}
function hgCheckDuctTapeObjects(ent1)
    if not ent1.DuctTape then return end

    return (ent1.DuctTape and ent1.DuctTape[0] and #ent1.DuctTape[0]) or 0 
end
function hgCheckBindObjects(ent1)
    if not ent1.Nails then return end

    return ( ent1.Nails and ent1.Nails[0] and #ent1.Nails[0]) or 0
end
heldents = heldents or {}
--if (!istable(query)) then
--    require("query")
--end
--
--query.EnableInfoDetour(true)
--
--hook.Add("A2S_INFO", "reply", function(ip, port, info)
--    print("A2S_INFO from", ip, port)
--    PrintTable(info)
--    return info
--end)

local function playEffects( ent, data )
    if not IsValid( ent ) or not data then return end

    if not ( ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() ) or not isBulletDamage( data ) then return end

    if getBloodColor( ent ) ~= -1 then
        ent.bloodColorHitFix = getBloodColor( ent )
        ent:SetBloodColor( -1 )
    end

    if getBloodColor( ent ) ~= -1 then return end

    local bloodColor = ent.bloodColorHitFix

    -- 3 Because robots don't bleed yet they have their own blood type for some reason.
    if not bloodColor or bloodColor == 3 then return end

    local hitPos = data:GetDamagePosition()
    local inflictorEyepos = data:GetAttacker():EyePos()
    local effectData = EffectData()

    
    --effectData:SetOrigin( hitPos )
    --effectData:SetColor( bloodColor )
    --util.Effect( "BloodImpact", effectData )
    

    local tempBloodPos = ( hitPos + ( ( inflictorEyepos - hitPos ):GetNormalized() * math_random( -25, -200 ) ) ) + Vector( math_random( -15, 15 ), math_random( -15, 15 ), 0 )
    local bloodPos = tempBloodPos - Vector( 0, 0, 75 )

    local bloodMat = rawget( bloodColors, bloodColor )
    if not bloodMat then return end

    util_Decal( bloodMat, hitPos, tempBloodPos, ent )
    util_Decal( bloodMat, tempBloodPos, bloodPos, ent )
end

hook.Add( "PostEntityTakeDamage", "ResponsiveHits_PostEntityTakeDamage", playEffects )

local function setBloodonSpawn( ent )
    if getBloodColor( ent ) == -1 then return end
    ent.bloodColorHitFix = getBloodColor( ent )
    ent:SetBloodColor( -1 )
end

hook.Add( "PlayerSpawn", "ResponsiveHits_PlayerSpawn", setBloodonSpawn )
hook.Add( "OnEntityCreated", "ResponsiveHits_OnEntityCreated", function( ent )
    timer.Simple( 0, function()
        if not IsValid( ent ) then return end
        if not ent:IsNPC() then return end
        setBloodonSpawn( ent )
    end )
end )

-- Looking Away 
util.AddNetworkString("LookAway")
net.Receive("LookAway",function(len,ply)
    if len > 64 or !IsValid(ply) then return end
    if (ply.cooldown_lookaway or 0) > CurTime() then return end
    ply.cooldown_lookaway = CurTime() + 0.1

    local rf = RecipientFilter()
    rf:AddPVS(ply:GetPos())
    rf:RemovePlayer(ply)

    net.Start("LookAway", true)
        net.WriteEntity(ply)
        net.WriteFloat(net.ReadFloat())
        net.WriteFloat(net.ReadFloat())
    net.Send(rf)
end)

local hg = hg or {}
-- С помощью этой функции можно пугать неписей.. Либо наоборот приманивать туда куда надо, мгс5 режим можно устроить
function hg.EmitAISound(pos, vol, dur, typ) -- https://developer.valvesoftware.com/wiki/Ai_sound
    local snd = ents.Create("ai_sound")
    snd:SetPos(pos)
    snd:SetKeyValue("volume", tostring(vol))
    snd:SetKeyValue("duration", tostring(dur))
    snd:SetKeyValue("soundtype", tostring(typ))
    snd:Spawn()
    snd:Activate()
    snd:Fire("EmitAISound")
    SafeRemoveEntityDelayed(snd, dur + .5)
end


--// Аирстрайк и его мега шедевро супер мега классная офигенная хуйня тупа но норм логика

-- зак придэ порядок наведЭ

local realismMode = CreateConVar( "hg_fullrealismmode", "1", FCVAR_SERVER_CAN_EXECUTE, "huy", 0, 1 )

cvars.AddChangeCallback("hg_fullrealismmode", function(convar_name, value_old, value_new)
    SetGlobalBool("FullRealismMode",realismMode:GetBool())
end)

SetGlobalBool("FullRealismMode",true)

hook.Add("Player Death","huhuhuhy",function(ply)
    if IsValid(ply.bull) then
        ply.bull:Remove()
        ply.bull = nil
    end
    ply:AddFlags(FL_NOTARGET)
end)

hook.Add("Player Think", "homigrad-dropholstered", function(ply)
    if (ply.thinkdropwep or 0) > CurTime() then return end
    ply.thinkdropwep = CurTime() + 0.1
    --local inv = ply:GetNetVar("Inventory")
    local activewep = ply:GetActiveWeapon()
    for i,wep in ipairs(ply:GetWeapons()) do
        if wep.NoHolster and activewep ~= wep and wep.picked then --and not inv["Weapons"]["hg_sling"]
            ply:DropWeapon(wep)
        end
    end
end)

hook.Add("Player Death","setcam",function(ply)

end)

util.AddNetworkString( "DoPlayerFlinch" )

hook.Add( "ScalePlayerDamage", "FlinchPlayersOnHit", function(ply, grp)
    if ply:IsPlayer() then
        --could maybe return end,
        --but would that override other Scale hooks? -- no.
        local group = nil
        local hitpos = {}
        hitpos = {
            [HITGROUP_HEAD] = ACT_FLINCH_HEAD, --1
            [HITGROUP_CHEST] = ACT_FLINCH_STOMACH, --2
            [HITGROUP_STOMACH] = ACT_FLINCH_STOMACH, --3
            [HITGROUP_LEFTARM] = ply:GetSequenceActivity(ply:LookupSequence("flinch_shoulder_l")), --4
            [HITGROUP_RIGHTARM] = ply:GetSequenceActivity(ply:LookupSequence("flinch_shoulder_r")), --5
            [HITGROUP_LEFTLEG] = ply:GetSequenceActivity(ply:LookupSequence("flinch_01")), --6
            [HITGROUP_RIGHTLEG] =  ply:GetSequenceActivity(ply:LookupSequence("flinch_02")) --7
        }
        if hitpos[grp] == nil then
            group = ACT_FLINCH_PHYSICS
        elseif hitpos[grp] then
            group = hitpos[grp]
        else
            group = ACT_FLINCH_PHYSICS
        end

        net.Start( "DoPlayerFlinch" )
            net.WriteInt( group, 32 )
            net.WriteEntity( ply )
        net.Broadcast()

    end

end )

--\\ supression

util.AddNetworkString("add_supression")
util.AddNetworkString("return_supression")

net.Receive("return_supression", function(len, ply)
    local dist = net.ReadFloat()
    local ang = net.ReadAngle()

    dist = math.Clamp(dist,25,100000)

    --local org = ply.organism
    --if not org.otrub then
    --    org.adrenalineAdd = org.adrenalineAdd + math.min(50 / dist, 1)
    --    org.disorientation = org.disorientation + (200 / dist)
    --end
end)

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return true end
    local diff = targetVec - ply:GetShootPos()
    return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8
end

hook.Add("PostEntityFireBullets","bulletsuppression",function(ent,bullet)
    local tr = bullet.Trace
    local dmg = bullet.Damage
    if ent == Entity(0) then return end
    if ent:IsNPC() then ent:SetAngles(ent:GetAimVector():Angle()) end
    for i,ply in player.Iterator() do--five pebbles
        if (IsValid(ent:GetOwner()) and ply == ent:GetOwner()) or ent == ply then continue end
        if not ply:Alive() then continue end
        local dist,pos = util.DistanceToLine(tr.StartPos,tr.HitPos,ply:EyePos())
        local org = ply.organism
        local eyePos = ply:EyePos()
        
        local isVisible = not util.TraceLine({
            start = pos,
            endpos = eyePos,
            filter = {ent, ply, hg.GetCurrentCharacter(ply), ent:GetOwner()},
            mask = MASK_SHOT
        }).Hit

        if not isVisible then continue end

        local shooterdist = tr.StartPos:Distance(eyePos)

        if dist > 120 then continue end

        if shooterdist < 500 and not IsLookingAt(ent:GetOwner(),eyePos) then continue end

        if ent:GetOwner():IsPlayer() then
            hg.DynaMusic:AddPanic(ent:GetOwner(),0.5)
        end

        if not org.otrub then
            org.adrenalineAdd = org.adrenalineAdd + 0.05 * dmg / math.max(dist / 2,10) / 1
            org.fearadd = org.fearadd + 0.2
        end
    end
end)

--//

function hg.StunPlayer(ply,time)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ply.FakeRagdoll) then hg.Fake(ply) end

    ply.organism.stun = CurTime() + (time or 1)
end

function hg.LightStunPlayer(ply,time)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ply.FakeRagdoll) then hg.Fake(ply,nil,true) end
    
    ply.organism.lightstun = CurTime() + (time or 1)
end

oldEmitSound = oldEmitSound or EmitSound
function host_timescale()
    return game.GetTimeScale()
end
local entMeta = FindMetaTable("Entity")
function EmitSound( soundName, position, entity, channel, volume, soundLevel, soundFlags, pitch, dsp, filter )
    soundName = soundName or ""
    position = position or vectorZero
    entity = entity or 0
    volume = volume or 1
    soundLevel = soundLevel or 75
    soundFlags = soundFlags or 0
    pitch = pitch or 100
    pitch = pitch * host_timescale()
    dsp = dsp or 0
    filter = filter or nil
    oldEmitSound(soundName, position, entity, channel, volume, soundLevel, soundFlags, pitch, dsp, filter)
end

oldEntEmitSound = oldEntEmitSound or entMeta.EmitSound
function entMeta.EmitSound(self,soundName,soundLevel,pitch,volume,channel,soundFlags,dsp,filter)
    soundName = soundName or ""
    position = position or vectorZero
    entity = entity or 0
    volume = volume or 1
    soundLevel = soundLevel or 75
    soundFlags = soundFlags or 0
    pitch = pitch or 100
    pitch = pitch * host_timescale()
    dsp = dsp or 0
    filter = filter or nil
    oldEntEmitSound(self, soundName, soundLevel, pitch, volume, channel, soundFlags, dsp, filter)
end

function hg.ExplosionEffect(pos, dis, dmg)
    net.Start("add_supression")
    net.WriteVector(pos)
    net.Broadcast()
end

-- MANUAL PICKUP
local hlguns = {
    ["weapon_357"] = true,
    ["weapon_pistol"] = true,
    ["weapon_crossbow"] = true,
    ["weapon_crowbar"] = true,
    ["weapon_frag"] = true,
    ["weapon_ar2"] = true,
    ["weapon_rpg"] = true,
    ["weapon_slam"] = true,
    ["weapon_shotgun"] = true,
    ["weapon_smg1"] = true,
    ["weapon_stunstick"] = true
}

hook.Add( "PlayerCanPickupWeapon", "CanPickup", function( ply, weapon )
    if hlguns[weapon:GetClass()] then return false end
    if weapon.IsSpawned then
        if not ply:KeyDown(IN_USE) and not ply.force_pickup then
            return false
        end
        local ductcount = hgCheckDuctTapeObjects(weapon)
        local nailscount = hgCheckBindObjects(weapon)
        if (ductcount and ductcount > 0) or (nailscount and nailscount > 0) then return false end
    end
end )

hook.Add( "OnPlayerPhysicsPickup", "CanPickup", function( ply, weapon )
    if not IsValid(weapon) or not weapon:IsWeapon() then return end
    
    if weapon.IsSpawned then
        local ductcount = hgCheckDuctTapeObjects(weapon)
        local nailscount = hgCheckBindObjects(weapon)
        if ((ductcount or 0) == 0) or ((nailscount or 0) == 0) then
            ply.force_pickup = true
            local can = hook.Run("PlayerCanPickupWeapon",ply,weapon)
            ply.force_pickup = nil
            if can then
                ply:PickupWeapon(weapon)
            end
        end
    end

end )

hook.Add( "AllowPlayerPickup", "CanPickup", function( ply, ent )
    if heldents[ent:EntIndex()] or IsValid(ent:GetNetVar("ply")) then
        return false
    end
end )

hook.Add("PlayerDroppedWeapon", "ManualPickup", function(owner, wep)
    wep.IsSpawned = true
end)

hook.Add("PlayerSpawnedSWEP", "ManualPickup", function(ply, wep) wep.IsSpawned = true end)

hook.Add("Player Death", "FLASHLIGHTHUY", function(ply)
    ply:SetNetVar("flashlight",false)
end)

concommand.Add("hg_dropflashlight",function(ply)
    if not ply:Alive() then return end
    local inv = ply:GetNetVar("Inventory")
    if not inv["Weapons"]["hg_flashlight"] then return end
    local ent = ents.Create("hg_flashlight")
    ent:SetPos(ply:EyePos())
    ent:SetAngles(ply:EyeAngles())
    ent:Spawn()
    ent:SetNetVar("enabled",ply:GetNetVar("flashlight",false))
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:ApplyForceCenter(ply:GetAimVector() * 150 * phys:GetMass())
    end
    ply:SetNetVar("flashlight",false)
    inv["Weapons"]["hg_flashlight"] = nil
    ply:SetNetVar("Inventory",inv)
    --hook.Run("PlayerSwitchFlashlight",ply,false)
end)

concommand.Add("hg_dropsling",function(ply)
    if not ply:Alive() then return end
    local inv = ply:GetNetVar("Inventory")
    if not inv["Weapons"] or not inv["Weapons"]["hg_sling"] then return end
    local ent = ents.Create("hg_sling")
    ent:SetPos(ply:EyePos())
    ent:SetAngles(ply:EyeAngles())
    ent:Spawn()
    ent:EmitSound("npc/footsteps/softshoe_generic6.wav", 75, math.random(90, 110), 1, CHAN_ITEM)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:ApplyForceCenter(ply:GetAimVector() * 200 * phys:GetMass())
    end
    inv["Weapons"]["hg_sling"] = nil
    ply:SetNetVar("Inventory",inv)

    local activewep = ply:GetActiveWeapon()
    for i,wep in ipairs(ply:GetWeapons()) do
        if not wep.bigNoDrop and wep.weaponInvCategory == 1 and activewep ~= wep then
            ply:DropWeapon(wep)
        end
    end
end)

concommand.Add("hg_dropkastet",function(ply)
    if not ply:Alive() then return end
    local inv = ply:GetNetVar("Inventory")
    if not inv["Weapons"] or not inv["Weapons"]["hg_brassknuckles"] then return end
    local ent = ents.Create("hg_brassknuckles")
    ent:SetPos(ply:EyePos())
    ent:SetAngles(ply:EyeAngles())
    ent:Spawn()
    ent:EmitSound("npc/footsteps/softshoe_generic6.wav", 75, math.random(90, 110), 1, CHAN_ITEM)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:ApplyForceCenter(ply:GetAimVector() * 200 * phys:GetMass())
    end
    inv["Weapons"]["hg_brassknuckles"] = nil
    ply:SetNetVar("Inventory",inv)
end)

hook.Add("SetupMove", "SV_SYNC", function(ply)
    if not ply.sync then
        ply.sync = true
        hook.Run("PlayerSync", ply)
    end
end)


local WreckBlacklist = {"gmod_lamp", "gmod_cameraprop", "gmod_light", "ent_jack_gmod_nukeflash"}

function hgWreckBuildings(blaster, pos, power, range, ignoreVisChecks)
    local origPower = power
    power = power * 1
    local maxRange = 250 * power * (range or 1) -- todo: this still doesn't do what i want for the nuke
    local maxMassToDestroy = 10 * power ^ .8
    local masMassToLoosen = 30 * power
    local allProps = ents.FindInSphere(pos, maxRange)

    for k, prop in pairs(allProps) do
        if not (table.HasValue(WreckBlacklist, prop:GetClass()) or hook.Run("hg_CanDestroyProp", prop, blaster, pos, power, range, ignore) == false or prop.ExplProof == true) then
            local physObj = prop:GetPhysicsObject()
            local propPos = prop:LocalToWorld(prop:OBBCenter())
            local DistFrac = 1 - propPos:Distance(pos) / maxRange
            local myDestroyThreshold = DistFrac * maxMassToDestroy
            local myLoosenThreshold = DistFrac * masMassToLoosen

            if DistFrac >= .85 then
                myDestroyThreshold = myDestroyThreshold * 7
                myLoosenThreshold = myLoosenThreshold * 7
            end

            if (prop ~= blaster) and physObj:IsValid() then
                local mass, proceed = physObj:GetMass(), ignoreVisChecks

                if not proceed then
                    local tr = util.QuickTrace(pos, propPos - pos, blaster)
                    proceed = IsValid(tr.Entity) and (tr.Entity == prop)
                end

                if proceed then
                    --[[if mass <= myDestroyThreshold then
                        SafeRemoveEntity(prop)
                    else--]]
                    if mass <= myLoosenThreshold then
                        physObj:EnableMotion(true)
                        constraint.RemoveAll(prop)
                        physObj:ApplyForceOffset((propPos - pos):GetNormalized() * 1000 * DistFrac * power * mass, propPos + VectorRand() * 10)
                    else
                        physObj:ApplyForceOffset((propPos - pos):GetNormalized() * 200 * DistFrac * origPower * mass, propPos + VectorRand() * 10)
                    end
                end
            end
        end
    end
end

function hgIsDoor(ent)
    local Class = ent:GetClass()

    return (Class == "prop_door") or (Class == "prop_door_rotating") or (Class == "func_door") or (Class == "func_door_rotating")
end

function hgBlastDoors(blaster, pos, power, range, ignoreVisChecks)
    for k, door in pairs(ents.FindInSphere(pos, 40 * power * (range or 1))) do
        if hgIsDoor(door) and hook.Run("hg_CanDestroyDoor", door, blaster, pos, power, range, ignore) ~= false then
            local proceed = ignoreVisChecks

            if not proceed then
                local tr = util.QuickTrace(pos, door:LocalToWorld(door:OBBCenter()) - pos, blaster)
                proceed = IsValid(tr.Entity) and (tr.Entity == door)
            end

            if proceed then
                hgBlastThatDoor(door, (door:LocalToWorld(door:OBBCenter()) - pos):GetNormalized() * 1000)
            end
        end
        if door:GetClass() == "func_breakable_surf" then
            door:Fire("Break")
        end
    end
end

function hgBlastThatDoor(ent, vel)
    ent.JModDoorBreachedness = nil
    local Moddel, Pozishun, Ayngul, Muteeriul, Skin = ent:GetModel(), ent:GetPos(), ent:GetAngles(), ent:GetMaterial(), ent:GetSkin()
    sound.Play("Wood_Crate.Break", Pozishun, 60, 100)
    sound.Play("Wood_Furniture.Break", Pozishun, 60, 100)
    ent:Fire("unlock", "", 0)
    ent:Fire("open", "", 0)
    ent:SetNoDraw(true)
    ent:SetNotSolid(true)

    for _, portal in ipairs(ents.FindByClass("func_areaportal")) do
        if (portal:GetInternalVariable("target") == ent:GetName()) then
            portal:Fire("Open")
            portal:SetSaveValue("target", "")
        end
    end

    if Moddel and Pozishun and Ayngul then
        local Replacement = ents.Create("prop_physics")
        Replacement:SetModel(Moddel)
        Replacement:SetPos(Pozishun + Vector(0, 0, 1))
        Replacement:SetAngles(Ayngul)

        if Muteeriul then
            Replacement:SetMaterial(Muteeriul)
        end

        if Skin then
            Replacement:SetSkin(Skin)
        end

        Replacement:SetModelScale(.9, 0)
        Replacement:Spawn()
        Replacement:Activate()

        if vel then
            Replacement:GetPhysicsObject():SetVelocity(vel)

            timer.Simple(0, function()
                if IsValid(Replacement) then
                    Replacement:GetPhysicsObject():ApplyForceCenter(vel * 100)
                end
            end)
        end

        timer.Simple(5, function()
            if IsValid(Replacement) then
                Replacement:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            end
        end)
    end
end

hook.Add( "OnEntityCreated", "VechicleChairs", function( ent )
    if ent:IsVehicle() and ent.IsValidVehicle and ent:IsValidVehicle() then
        timer.Simple(0.1,function()
            if ent:IsVehicle() and ent.IsValidVehicle and ent:IsValidVehicle() then
                ent:SetVehicleEntryAnim(false)
            end
        end)
    end
    
    timer.Simple(0, function()
        if ent:IsVehicle() and ent:GetModel() == "models/nova/airboat_seat.mdl" and not ent.shitass then
            //ent:SetModel("models/props_junk/PopCan01a.mdl")
            --print(ent:GetModel())
            local nigger = IsValid(ent:GetParent()) and (
                (ent:GetParent():GetModel() == "models/vehicles/7seatvan.mdl") or 
                (ent:GetParent():GetModel() == "models/buggy.mdl") or 
                (ent:GetParent():GetModel() == "models/vehicles/buggy_elite.mdl") or 
                (ent:GetParent():GetModel() == "models/vehicle.mdl")
            ) and ent:GetParent().DriverSeat == ent
            
			ent:SetModel("models/props_junk/PopCan01a.mdl")
            ent:SetAngles(ent:LocalToWorldAngles(nigger and Angle(0, -1, 0) or Angle(0,90,0)))
        end
    end)
    
    if ent:GetClass() == "prop_vehicle_airboat" then
        timer.Simple(0.1,function()
            for i = 1, 4 do
                local entang = ent:GetAngles()
                local pos = ent:GetPos() + entang:Right() * 25 *i + entang:Forward() * 25 + entang:Up() * 20 + entang:Right() * - 60
                local chair = ents.Create("prop_vehicle_prisoner_pod")
                chair:SetModel("models/nova/airboat_seat.mdl")
                chair.shitass = true
                chair:SetPos(pos)
                chair:SetAngles(entang+Angle(0,-80,0))
                chair:SetColor4Part(0,0,0,0)
                chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
                chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
                chair:Spawn()
                chair:SetVehicleEntryAnim(false)

                --[[chair:AddCallback( "OnAngleChange", function( entity, newangle )
                    if newangle[1] > 170 or newangle[1] < -170 then
                        if IsValid(ent:GetDriver()) then
                            ent:GetDriver():ExitVehicle()
                        end
                    end
                end )]]--

                local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

                local physobj = chair:GetPhysicsObject()
                if physobj:IsValid() then
                    physobj:EnableCollisions(false)
                end
            end

            for i = 1, 4 do
                local entang = ent:GetAngles()
                local pos = ent:GetPos() + entang:Right() * 25 *i + entang:Forward() * -25 + entang:Up() * 20 + entang:Right() * - 60
                local chair = ents.Create("prop_vehicle_prisoner_pod")
                chair:SetModel("models/nova/airboat_seat.mdl")
                chair.shitass = true
                chair:SetPos(pos)
                chair:SetAngles(entang+Angle(0,80,0))
                chair:SetColor4Part(0,0,0,0)
                chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
                chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
                chair:Spawn()
                chair:SetVehicleEntryAnim(false)

                --[[chair:AddCallback( "OnAngleChange", function( entity, newangle )
                    if newangle[1] > 170 or newangle[1] < -170 then
                        if IsValid(ent:GetDriver()) then
                            ent:GetDriver():ExitVehicle()
                        end
                    end
                end )]]--

                local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

                local physobj = chair:GetPhysicsObject()
                if physobj:IsValid() then
                    physobj:EnableCollisions(false)
                    physobj:SetMass(1)
                end
            end
        end)
    end

    if ent:GetClass() == "prop_vehicle_jeep" then
        timer.Simple(0,function()
            local entang = ent:GetAngles()
            local pos = ent:GetPos() + entang:Right() * 30 + entang:Forward() * 17 + entang:Up() * 25
            local chair = ents.Create("prop_vehicle_prisoner_pod")
            chair:SetModel("models/nova/airboat_seat.mdl")
            chair.shitass = true
            chair:SetPos(pos)
            chair:SetAngles(entang+Angle(0,0,25))
            chair:SetColor4Part(255,255,255,255)
            chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
            chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
            chair:Spawn()
            chair:SetVehicleEntryAnim(false)

            --[[chair:AddCallback( "OnAngleChange", function( entity, newangle )
                if newangle[1] > 170 or newangle[1] < -170 then
                    if IsValid(ent:GetDriver()) then
                        ent:GetDriver():ExitVehicle()
                    end
                end
            end )]]--

            local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

            local physobj = chair:GetPhysicsObject()
            if physobj:IsValid() then
                physobj:EnableCollisions(false)
            end

            local entang = ent:GetAngles()
            local pos = ent:GetPos() + entang:Right() * 70 + entang:Up() * 75
            local chair = ents.Create("prop_vehicle_prisoner_pod")
            chair:SetModel("models/nova/airboat_seat.mdl")
            chair.shitass = true
            chair:SetPos(pos)
            chair:SetAngles(entang+Angle(0,0,0))
            chair:SetColor4Part(255,255,255,0)
            chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
            chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
            chair:Spawn()
            chair:SetVehicleEntryAnim(false)

            --[[chair:AddCallback( "OnAngleChange", function( entity, newangle )
                if newangle[1] > 170 or newangle[1] < -170 then
                    if IsValid(ent:GetDriver()) then
                        ent:GetDriver():ExitVehicle()
                    end
                end
            end )]]--

            local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

            local physobj = chair:GetPhysicsObject()
            if physobj:IsValid() then
                physobj:EnableCollisions(false)
            end

            local entang = ent:GetAngles()
            local pos = ent:GetPos() + entang:Right() * 90 + entang:Up() * 45 + entang:Forward() * 30
            local chair = ents.Create("prop_vehicle_prisoner_pod")
            chair:SetModel("models/nova/airboat_seat.mdl")
            chair.shitass = true
            chair:SetPos(pos)
            chair:SetAngles(entang+Angle(0,-90,0))
            chair:SetColor4Part(255,255,255,0)
            chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
            chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
            chair:Spawn()
            chair:SetVehicleEntryAnim(false)

            --[[chair:AddCallback( "OnAngleChange", function( entity, newangle )
                if newangle[1] > 170 or newangle[1] < -170 then
                    if IsValid(ent:GetDriver()) then
                        ent:GetDriver():ExitVehicle()
                    end
                end
            end )]]--

            local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

            local physobj = chair:GetPhysicsObject()
            if physobj:IsValid() then
                physobj:EnableCollisions(false)
            end

            local entang = ent:GetAngles()
            local pos = ent:GetPos() + entang:Right() * 90 + entang:Up() * 45 + entang:Forward() * -30
            local chair = ents.Create("prop_vehicle_prisoner_pod")
            chair:SetModel("models/nova/airboat_seat.mdl")
            chair.shitass = true
            chair:SetPos(pos)
            chair:SetAngles(entang+Angle(0,90,0))
            chair:SetColor4Part(255,255,255,0)
            chair:SetRenderMode(RENDERGROUP_TRANSLUCENT)
            chair:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
            chair:Spawn()
            chair:SetVehicleEntryAnim(false)

            chair:AddCallback( "OnAngleChange", function( entity, newangle )
                --[[if newangle[1] > 170 or newangle[1] < -170 then
                    if IsValid(ent:GetDriver()) then
                        ent:GetDriver():ExitVehicle()
                    end
                end]]--
            end )

            local weld = constraint.Weld( chair, ent, 0, 0, 0, true, true )

            local physobj = chair:GetPhysicsObject()
            if physobj:IsValid() then
                physobj:EnableCollisions(false)
            end
        end)
    end
end )

local replace_ammo = {
    [1] = "Pulse",
    [3] = "9x19 mm Parabellum",
    [4] = "4.6x30 mm",
    [5] = ".357 Magnum",
    [6] = "Armature",
    [7] = "12/70 gauge",
    [8] = "RPG-7 Projectile"
}

hook.Add("PlayerAmmoChanged","AmmoReplace",function(ply,id,old,new)
    if replace_ammo[id] ~= nil then
        ply:GiveAmmo(new, replace_ammo[id], true)
        ply:SetAmmo(0,id)
    end
end)

util.AddNetworkString("sssprays")
hook.Add("PlayerSpray", "SSSprays", function(ply)
end)

local sdist = CreateConVar("ssspray_range", 128, FCVAR_ARCHIVE+FCVAR_REPLICATED, "Spray distance.", 0, 1024)

hook.Add("FinishMove", "SSSprays", function(ply, mv)

end)

if SERVER then
    hook.Add( "Move", "hg_RagdollIntoWalls", function( ply, mv)
        local vel = mv:GetVelocity()
        if ply:GetMoveType() == MOVETYPE_WALK and vel:Length() > 750 and not hg.GetCurrentCharacter(ply):IsRagdoll() then
            local tr = util.TraceLine({
                start = ply:GetPos(),
                endpos = ply:GetPos() + vel:Angle():Forward() * 100,
                mask = MASK_SOLID,
                filter = ply
            })
            if tr.Hit then
                hg.Fake(ply)
            end
        end
    end)
end

--[[if not eightbit then
    require("eightbit")
end]]

local success, err = pcall(require, "eightbit")
if not success then
    print("gavno ", err)
    eightbit = {}
end

if eightbit.SetDamp1 then
    eightbit.SetDamp1(0.1)
end

hook.Add("PlayerInitialSpawn","nigger_nigger",function(ply)
    if eightbit.EnableEffect then
        --eightbit.EnableEffect(ply:UserID(), eightbit.EFF_MASKVOICE)
    elseif eightbit.EnableEffects then
        eightbit.EnableEffects(ply:UserID(), 1)
    end
end)

util.AddNetworkString("sendbuf")

local function lowpass(samples, count, dt, RC)
    local samples2 = table.Copy(samples)
    local a = dt / (RC + dt)
    //samples2[1] = a * samples[1]

    for i = 2, count do
        samples2[i] = a * samples[i] + (1 - a) * samples2[i - 1]
    end

    return samples2
end

local hg_developer = GetConVar("hg_developer")

local function funco(userId, buffer, count)
    local ply = Player(userId)
    
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return buffer end

    local armor = ply:GetNetVar("Armor", {})
    local face = armor and armor["face"]

    local amt = count / 480

    for i = 1, count do
        //buffer[i] = math.abs(buffer[i])
    end

    /*if hg_developer:GetBool() then
        for i = 1, count do
            //buffer[i] = math.random(100) == 1 and 1000 or math.abs(math.cos(i / count * math.pi * 25)) * 1000
        end

        if (nextsend or 0) < CurTime() and amt == 1 then
            nextsend = CurTime() + 1

            net.Start("sendbuf")
            net.WriteTable(buffer)
            net.Broadcast()
        end
    end*/
    
    local oldbuf = table.Copy(buffer)
    
    local hist = {buffer[start]}
    local histPos = 1

    if face then
        local mask = hg.armor.face[face].voice_change
        
        if mask then
            buffer = lowpass(buffer, count, 0.2, 2)
            //buffer = lowpass(buffer, count, 0.5, 1)
            //buffer = lowpass(buffer, count, 0.1, 1)
        end
    end
    
    for i = 1, count do
        //buffer[i] = math.Clamp(buffer[i] / 32768, -1, 1) * 32768
    end

    local model = ply:GetModel()

    if model == "models/distac/player/ghostface.mdl" then
        for i = 2, count, 4 do
            buffer[i] = buffer[i] - oldbuf[i-1] * 1
            buffer[i] = buffer[i] * 5
        end
    end

    return buffer
end

hook.Add("ApplyVoiceEffect", "test", function(userId, buffer, count)
    local err, val = pcall(funco, userId, buffer, count)

    if !isstring(val) then
        return val
    else
        print(val)
        return buffer
    end
end)

hook.Add("InitPostEntity", "ffuckk", function()
    local perf = physenv.GetPerformanceSettings()
    perf.MaxVelocity = 100000 --default 2000
    physenv.SetPerformanceSettings(perf)
    --physenv.SetAirDensity(2)
    --PrintTable(physenv.GetPerformanceSettings())
end)

hg.ServersIP = {
    "5.42.211.48:24215",
    "5.42.211.48:24217"
}

hg.ServersInfo = hg.ServersInfo or {
    --["5.42.211.48:24215"] = {bla bla bla}
}

function hg.GetServerInfo(ip)
    http.Fetch("https://api.steampowered.com/IGameServersService/GetServerList/v1/?key=2BB7E2D6B2D13600133300BB9C19033F&filter=addr\\"..ip,
    function(body, length, headers, code)
        if !hg.ServersInfo[ip] then return end
        hg.ServersInfo[ip] = util.JSONToTable(body)["response"]["servers"][1]
        --PrintTable(hg.ServersInfo[ip])
    end)
    --https://api.steampowered.com/IGameServersService/GetServerList/v1/?key=2BB7E2D6B2D13600133300BB9C19033F&filter=addr\185.254.99.6:27015
end
hook.Add("InitPostEntity","FetchServersInfo",function()
    for _, v in ipairs(hg.ServersIP) do
        hg.GetServerInfo(v)
    end
end)

timer.Create("FetchServersInfo",300,0,function()
    for _, v in ipairs(hg.ServersIP) do
        hg.GetServerInfo(v)
    end
end)

for _, v in ipairs(hg.ServersIP) do
    hg.GetServerInfo(v)
end


--util.AddNetworkString("GetServersInfo")
local cooldown = {}
function hg.SendServersInfoToClient(ply)
    if cooldown[ply:SteamID()] and cooldown[ply:SteamID()] > CurTime() then
        net.Start("GetServersInfo")
            net.WriteTable({})
        net.Send(ply)
        return 
    end
    local sendTable = {}
    for _,k in ipairs(hg.ServersIP) do
        local v = hg.ServersInfo[k]
        if not v then continue end
        sendTable[k] = {}
        sendTable[k]["name"] = v["name"]
        sendTable[k]["map"] = v["map"]
        sendTable[k]["players"] = v["players"]
        sendTable[k]["max_players"] = v["max_players"]
        sendTable[k]["addr"] = v["addr"]
    end 
    net.Start("GetServersInfo")
        net.WriteTable(sendTable)
    net.Send(ply)

    cooldown[ply:SteamID()] = CurTime() + 60

    if table.Count(hg.ServersInfo) < 1 then 
        --print("huy")
        for _, v in ipairs(hg.ServersIP) do
            hg.GetServerInfo(v)
        end
    end
end

net.Receive("GetServersInfo",function(len,ply)
    hg.SendServersInfoToClient(ply)
end)


local TrackedEnts = {
	["weapon_crowbar"]={"weapon_hg_crowbar"},
	["weapon_stunstick"]={"weapon_pocketknife"},
	["weapon_pistol"]={"weapon_hk_usp"},
	["weapon_357"]={"weapon_revolver2"},
	["weapon_shotgun"]={"weapon_remington870"},
	["weapon_crossbow"]={"weapon_ar15","weapon_mp7"},
	["weapon_ar2"]={"weapon_akm","weapon_m4a1"},
	["weapon_smg1"]={"weapon_mp7"},
	["weapon_slam"]={"weapon_hg_molotov_tpik"},
	["weapon_rpg"]={"*ammo*"},
	["item_ammo_ar2_altfire"]={"weapon_hg_molotov_tpik"},
	["item_ammo_357"]={"*ammo*"},
	["item_ammo_357_large"]={"*ammo*"},
	["item_ammo_pistol"]={"*ammo*"},
	["item_ammo_pistol_large"]={"*ammo*"},
	["item_ammo_ar2"]={"*ammo*"},
	["item_ammo_ar2_large"]={"*ammo*"},
	["item_ammo_ar2_smg1"]={"*ammo*"},
	["item_ammo_ar2_large"]={"*ammo*"},
	["item_ammo_smg1"]={"*ammo*"},
	["item_ammo_smg1_large"]={"*ammo*"},
	["item_box_buckshot"]={"*ammo*"},
	["item_box_buckshot_large"]={"*ammo*"},
	["item_rpg_round"]={"*ammo*"},
	["item_healthvial"]={"weapon_bandage_sh"},
	["item_healthkit"]={"weapon_medkit_sh"},
	["item_battery"]={"weapon_painkillers"},
	["item_suit"]={"*ammo*"},
	["weapon_alyxgun"] = {"weapon_smallconsumable","weapon_bigconsumable"},
	["weapon_frag"] = {"weapon_hg_grenade_hl2grenade"},
	["Grenade"] = {"weapon_hg_grenade_hl2grenade"},
	["npc_grenade_frag"] = {"ent_hg_grenade_hl2grenade"},
	["ent_jack_hmcd_ducttape"] = {"weapon_ducttape"},
}

local TrackedEntsHalfLife = {
	["weapon_crowbar"]={"weapon_hg_crowbar"},
	["weapon_stunstick"]={"weapon_hg_stunstick"},
	["weapon_pistol"]={"weapon_hk_usp"},
	["weapon_357"]={"weapon_revolver357"},
	["weapon_shotgun"]={"weapon_spas12"},
	["weapon_crossbow"]={"weapon_hg_crossbow"},
	["weapon_ar2"]={"weapon_osipr"},
	["weapon_smg1"]={"weapon_mp7"},
	["weapon_slam"]={"weapon_hg_slam"},
	["weapon_rpg"]={"weapon_hg_rpg"},
	["item_ammo_357"]={"ent_ammo_.357magnum"},
	["item_ammo_357_large"]={"ent_ammo_.357magnum"},
	["item_ammo_pistol"]={"ent_ammo_9x19mmparabellum"},
	["item_box_srounds"]={"ent_ammo_9x19mmparabellum"},
	["item_ammo_pistol_large"]={"ent_ammo_9x19mmparabellum"},
	["item_ammo_ar2"]={"ent_ammo_pulse"},
	["item_ammo_ar2_large"]={"ent_ammo_pulse"},
	["item_ammo_ar2_altfire"]={"ent_ammo_pulse"},--TODO: add altfire!!!!
	["item_ammo_smg1"]={"ent_ammo_4.6x30mm"},
	["item_box_mrounds"]={"ent_ammo_4.6x30mm"},
	["item_ammo_smg1_grenade"]={"ent_ammo_4.6x30mm"},--add smg grenade
	["item_ar2_grenade"]={"ent_ammo_4.6x30mm"},--add smg grenade
	["item_ammo_crossbow"]={"ent_ammo_armature"},
	["item_ammo_smg1_large"]={"ent_ammo_4.6x30mm"},
	["item_box_buckshot"]={"ent_ammo_12/70gauge","ent_ammo_12/70slug"},
	["item_box_buckshot_large"]={"ent_ammo_12/70gauge","ent_ammo_12/70slug"},
	["item_rpg_round"]={"ent_ammo_rpg-7projectile"},
	["item_healthvial"]={"weapon_bandage_sh","item_healthvial"},
	["item_healthkit"]={"weapon_medkit_sh","item_healthkit"},
	["item_battery"]={"weapon_painkillers","item_battery"},
	["item_suit"]={"item_suit"},
}

local TrackedModels = {
	["models/props_interiors/pot02a.mdl"] = "ent_armor_helmet4",
	["models/props_c17/metalPot002a.mdl"] = "weapon_pan",
	["models/props_junk/Shovel01a.mdl"] = "weapon_hg_shovel",
	["models/props_junk/glassbottle01a.mdl"] = "weapon_hg_bottle",
	["models/props_junk/glassbottle01a_chunk01a.mdl"] = "weapon_hg_bottlebroken",
	["models/props_junk/garbage_glassbottle003a.mdl"] = "weapon_hg_bottle",
	["models/props_junk/garbage_glassbottle003a_chunk01.mdl"] = "weapon_hg_bottlebroken",
	["models/props_canal/mattpipe.mdl"] = "weapon_leadpipe",
	["models/props_junk/harpoon002a.mdl"] = "weapon_hg_spear",
	["models/props_junk/garbage_coffeemug001a.mdl"] = "weapon_hg_mug",
	//["models/props/cs_office/fire_extinguisher.mdl"] = "weapon_hg_extinguisher",
	["models/weapons/w_fire_extinguisher.mdl"] = "weapon_hg_extinguisher",
    ["models/props_junk/glassbottle01a_chunk01a.mdl"] = "weapon_hg_bottlebroken",
	--!!["models/props/CS_militia/axe.mdl"] = "weapon_hg_axe",!! Убрал т.к реально бред
}

for str,ent in pairs(TrackedModels) do
	if string.lower(str) == str then continue end
	TrackedModels[string.lower(str)] = ent
	TrackedModels[str] = nil
end

local TrackedEntsNpc = table.Copy(TrackedEnts)

TrackedEntsNpc["weapon_ar2"] = {"weapon_osipr"}
TrackedEntsNpc["weapon_crowbar"]={"weapon_bat"}
TrackedEntsNpc["weapon_stunstick"]={"weapon_hg_stunstick"}
TrackedEntsNpc["weapon_shotgun"]={"weapon_spas12"}
TrackedEntsNpc["npc_grenade_frag"]={"ent_hg_grenade_hl2grenade"}

local fuckingwait = 0
hook.Add("PreCleanupMap","asdsadasdashuc",function()
	fuckingwait = CurTime() + 5
end)

hook.Add( "OnEntityCreated", "ReplaceEnt", function( ent )
	hook.Run("ZB_OnEntCreated",ent)
	if OverrideWeaponSpawn then return end
    
	timer.Simple(fuckingwait > CurTime() and 5 or 0,function()
		if ( not IsValid(ent) or (not TrackedEnts[ ent:GetClass() ] and not TrackedEntsHalfLife[ ent:GetClass() ] and not TrackedModels[ent:GetModel()]) ) then return end
		if TrackedModels[ent:GetModel()] and not (string.find(ent:GetClass(),"prop_") and not (game.GetMap() == "ttt_clue_2022" and ent:GetModel() == "models/props_canal/mattpipe.mdl") and not ent.notprop) then
			return
		end
				
		local entclass = ent:GetClass()
		local replacmentEnt = (CurrentRound and CurrentRound().name == "coop" and TrackedEntsHalfLife[ entclass ] or TrackedEnts[ entclass ]) or TrackedModels[ent:GetModel()]
		
		if istable(replacmentEnt) then replacmentEnt = table.Random(replacmentEnt) end

		if replacmentEnt == "*ammo*" then
			replacmentEnt = "ent_ammo_" .. table.Random(hg.ammotypeshuy).name
		end

		if replacmentEnt == entclass then return end
		if not replacmentEnt or replacmentEnt == "" then return end
		if not IsValid(ent) then return end

		OverrideWeaponSpawn = true
		local owner = ent.GetOwner and ent:GetOwner()
		local entPos = ent:GetPos()
		local entAngles = ent:GetAngles()
		local phys = ent:GetPhysicsObject()
		local vel = ent:GetVelocity()

		if IsValid(phys) then
			vel = phys:GetVelocity()
		end
		
		SafeRemoveEntity(ent)

		if owner and owner:IsNPC() and ent:GetClass() ~= "npc_grenade_frag" then
			local replacmentEntNpc = TrackedEntsNpc[ entclass ][math.random( #TrackedEntsNpc[ entclass ] )]
			local cap = owner:CapabilitiesGet()
			if bit.band(cap, CAP_USE_WEAPONS) != CAP_USE_WEAPONS then OverrideWeaponSpawn = false return end
			owner:Give(replacmentEntNpc)
			OverrideWeaponSpawn = false
			return
		end
		
		--if CurrentRound().name == "coop" and (CurrentRound().LootTimer or 0) > CurTime() then OverrideWeaponSpawn = false return end
		local Replacment = ents.Create(replacmentEnt)
		
		if not IsValid(Replacment) then
			OverrideWeaponSpawn = false
			return
		end
		
		Replacment:SetPos(entPos)
		Replacment:SetAngles(entAngles)
		Replacment.IsSpawned = true
		Replacment.init = true
		Replacment:Spawn()
		Replacment.IsSpawned = true
		Replacment.init = true
		--Replacment:Activate()
		Replacment:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		
		local phys = Replacment:GetPhysicsObject()
		if IsValid(phys) then
			--[[if CurrentRound().name == "coop" then
				phys:EnableMotion(false)
				timer.Simple(3,function()
					if IsValid(phys) then
						phys:EnableMotion(true)
					end
				end)
			end--]]

			phys:SetVelocity(vel)
		end

		if ent:GetClass() == "npc_grenade_frag" then
			Replacment.timer = CurTime()
		end

		OverrideWeaponSpawn = false
	end)
end )