cz = cz or {}
cz.Inventory = cz.Inventory or {}

-- Core networking strings
if SERVER then
    util.AddNetworkString("CZ_Inventory_Update")
    util.AddNetworkString("CZ_Inventory_MoveItem")
    util.AddNetworkString("CZ_Inventory_DropItem")
end
