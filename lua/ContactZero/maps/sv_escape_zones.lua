CZ_ESCAPE_ZONES = CZ_ESCAPE_ZONES or {}

-- Escape zones config.
-- Format:
-- CZ_ESCAPE_ZONES["map_name"] = {
--     { pos = Vector(0, 0, 0), radius = 128, factions = { "classd" }, message = "Escaped." },
--     { pos = Vector(500, 0, 0), radius = 128, roles = { "sci_default" }, message = "Scientist escaped." }
-- }

-- Example placeholder:
-- CZ_ESCAPE_ZONES["gm_flatgrass"] = {
--     { pos = Vector(600, 0, 0), radius = 128, factions = { "classd" }, message = "Class-D escaped." },
--     { pos = Vector(700, 0, 0), radius = 128, factions = { "sci", "guard" }, message = "Personnel escaped." }
-- }
