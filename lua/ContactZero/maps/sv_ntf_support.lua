CZ_NTF_CONFIG = CZ_NTF_CONFIG or {}

-- NTF support config.
-- NTF is spawned from spectators randomly.
-- Format:
-- CZ_NTF_CONFIG["map_name"] = {
--     enabled = true,
--     initialDelay = 300, -- 5 minutes
--     repeatDelay = 240,  -- 4 minutes
--     count = 3,
--     roles = { "guard_default" },
--     spawnpoints = {
--         { pos = Vector(0, 0, 0), ang = Angle(0, 0, 0) }
--     }
-- }

-- Example placeholder:
-- CZ_NTF_CONFIG["gm_flatgrass"] = {
--     enabled = true,
--     initialDelay = 300,
--     repeatDelay = 240,
--     count = 3,
--     roles = { "guard_default" },
--     spawnpoints = {
--         { pos = Vector(400, 0, 0), ang = Angle(0, 90, 0) }
--     }
-- }
