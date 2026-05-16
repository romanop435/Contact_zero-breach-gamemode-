if SERVER then
    AddCSLuaFile("sh_inventory.lua")
    AddCSLuaFile("cl_inventory.lua")
    include("sh_inventory.lua")
    include("sv_inventory.lua")
else
    include("sh_inventory.lua")
    include("cl_inventory.lua")
end
