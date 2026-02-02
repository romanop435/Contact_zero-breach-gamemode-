CZ_LOOT_SPAWNS = CZ_LOOT_SPAWNS or {}

-- Edit this file to add loot spawns per map.
-- Each entry supports:
--   pos = Vector(x, y, z) or {x, y, z}
--   ang = Angle(p, y, r) or {p, y, r} (optional)
-- Keycards:
--   level = keycard level (number)
-- Weapons/Ammo/Items:
--   class = entity class name

-- Example:
-- CZ_LOOT_SPAWNS["gm_flatgrass"] = {
--     keycards = {
--         { pos = Vector(0, 0, 0), ang = Angle(0, 0, 0), level = 1 },
--         { pos = Vector(50, 0, 0), level = 3 }
--     },
--     weapons = {
--         { class = "weapon_pistol", pos = Vector(100, 0, 0), ang = Angle(0, 90, 0) }
--     },
--     ammo = {
--         { class = "item_ammo_pistol", pos = Vector(120, 0, 0) }
--     },
--     items = {
--         { class = "item_healthkit", pos = Vector(140, 0, 0) }
--     }
-- }
