GM.Name = "Contact:Zero"
GM.Author = "romanop435"
GM.Email = ""
GM.Website = ""

DeriveGamemode("sandbox")

-- =========================================================
-- Early globals (avoid hg nil everywhere)
-- =========================================================
hg = hg or {}
ywb = ywb or {}
FP_SERVER_COLOR, FP_SERVER_NAME = Color(175, 25, 25), "Contact:Zero"

-- =========================================================
-- Gamemode paths
-- =========================================================
BASE_LUA_PATH      = GM.FolderName
BASE_GAMEMODE_PATH = GM.FolderName .. "/gamemode"

MODULES_PATH    = BASE_GAMEMODE_PATH .. "/modules"
BASE_PATH       = BASE_GAMEMODE_PATH .. "/base"
LANGUAGES_PATH  = BASE_GAMEMODE_PATH .. "/languages"
MAP_CONFIG_PATH = BASE_GAMEMODE_PATH.."/mapconfigs"

-- =========================================================
-- RNG (must be included BEFORE use)
-- =========================================================
if SERVER then AddCSLuaFile("base/xoshiro128.lua") end
include("base/xoshiro128.lua")

-- =========================================================
-- Recursive loader for addon lua trees
-- Loads: lua/libraries, lua/romanop435, lua/autorun
-- =========================================================
local function norm(p) return string.Replace(p, "\\", "/") end

local function includeFile(path)
    path = norm(path)

    local name = string.GetFileFromFilename(path)
    local left = string.lower(string.Left(name, 3))

    if SERVER then
        if left == "sv_" then
            include(path)
            return
        elseif left == "sh_" then
            AddCSLuaFile(path)
            include(path)
            return
        elseif left == "cl_" then
            AddCSLuaFile(path)
            return
        else
            -- no prefix => shared
            AddCSLuaFile(path)
            include(path)
            return
        end
    else
        -- CLIENT
        if left == "sv_" then return end
        include(path)
    end
end

local function includeDirRecursive(dir)
    dir = norm(dir)
    if dir:sub(-1) == "/" then dir = dir:sub(1, -2) end

    local files, dirs = file.Find(dir .. "/*", "LUA")
    if files then
        for _, f in ipairs(files) do
            if string.EndsWith(f, ".lua") then
                includeFile(dir .. "/" .. f)
            end
        end
    end
    if dirs then
        for _, d in ipairs(dirs) do
            includeDirRecursive(dir .. "/" .. d)
        end
    end
end

-- =========================================================
-- Load base gamemode modules (your existing logic)
-- =========================================================
local function includeCommonModules()
    if SERVER then
        include(MODULES_PATH .. "/sv_module.lua")
        AddCSLuaFile(MODULES_PATH .. "/sh_module.lua")
        AddCSLuaFile(MODULES_PATH .. "/cl_module.lua")
        print("||||| LOADED MAIN MODULES")
    else
        include(MODULES_PATH .. "/cl_module.lua")
    end

    include(MODULES_PATH .. "/sh_module.lua")
end

-- =========================================================
-- Load languages (server sends to clients)
-- =========================================================
local function GetAllLanguages()
    return file.Find(LANGUAGES_PATH .. "/*.lua", "LUA")
end

local function loadLanguages()
    if not SERVER then return end
    local files = GetAllLanguages()
    for _, v in ipairs(files) do
        AddCSLuaFile(LANGUAGES_PATH .. "/" .. v)
        print("Loaded: " .. v)
    end
    print("Contact:Zero | LOADED LOCALIZATION FILES")
end
if SERVER then
    AddCSLuaFile( MAP_CONFIG_PATH.."/"..game.GetMap()..".lua" )
    print( "Contact:Zero | LOADED MAP CONFIG" )
end
include( MAP_CONFIG_PATH.."/"..game.GetMap()..".lua" )

includeDirRecursive(BASE_PATH)
includeCommonModules()
includeDirRecursive(MODULES_PATH)

-- These are exactly the three folders you requested:
includeDirRecursive("libraries")
includeDirRecursive("romanop435")
includeDirRecursive("autorun")

-- RNG instance
FPRandom = xoshiro128()

-- Send languages
loadLanguages()
