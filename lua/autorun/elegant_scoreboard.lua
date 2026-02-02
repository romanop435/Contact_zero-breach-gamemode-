--[[
     _____ _                        _     _____ _____ ___________ ___________  _____  ___  ____________
    |  ___| |                      | |   /  ___/  __ \  _  | ___ \  ___| ___ \|  _  |/ _ \ | ___ \  _  \
    | |__ | | ___  __ _  __ _ _ __ | |_  \ `--.| /  \/ | | | |_/ / |__ | |_/ /| | | / /_\ \| |_/ / | | |
    |  __|| |/ _ \/ _` |/ _` | '_ \| __|  `--. \ |   | | | |    /|  __|| ___ \| | | |  _  ||    /| | | |
    | |___| |  __/ (_| | (_| | | | | |_  /\__/ / \__/\ \_/ / |\ \| |___| |_/ /\ \_/ / | | || |\ \| |/ /
    \____/|_|\___|\__, |\__,_|_| |_|\__| \____/ \____/\___/\_| \_\____/\____/  \___/\_| |_/\_| \_|___/
                  __/ |
                 |___/

    Coded by: ted.lua (http://steamcommunity.com/id/tedlua/)
--]]
if SERVER then AddCSLuaFile( 'scoreboard_config.lua' ) resource.AddWorkshop( '1255424390' ) end
include( 'scoreboard_config.lua' )

if not CLIENT then return end

hg = hg or {}
if not hg.Breach then
    include( 'ContactZero/breach/sh_breach.lua' )
end
local BR = hg.Breach

local hg_font = ConVarExists( "hg_font" ) and GetConVar( "hg_font" ) or CreateClientConVar( "hg_font", "Bahnschrift", true, false, "ui font" )
local function ScoreFont()
    local usefont = "Bahnschrift"
    if hg_font:GetString() ~= "" then
        usefont = hg_font:GetString()
    end
    return usefont
end

surface.CreateFont( "ElegantScoreFont", { font = ScoreFont(), size = 32, weight = 800, antialias = true } )
surface.CreateFont( "ElegantScoreFontSmall", { font = ScoreFont(), size = 18, weight = 700, antialias = true } )
surface.CreateFont( "ElegantScoreFontUnder", { font = ScoreFont(), size = 18, weight = 700, antialias = true } )
surface.CreateFont( "ElegantScoreFontTiny", { font = ScoreFont(), size = 18, weight = 700, antialias = true } )
surface.CreateFont( "ElegantScoreFontMedium", { font = ScoreFont(), size = 26, weight = 800, antialias = true } )
surface.CreateFont( "ElegantScoreFontHeader", { font = ScoreFont(), size = 18, weight = 800, antialias = true } )

local UNKNOWN_TEXT = Elegant_Score_Config.UnknownText or "Unknown"
local STATUS_ALIVE = Elegant_Score_Config.StatusAlive or "Alive"
local STATUS_DEAD = Elegant_Score_Config.StatusDead or "Dead"
local STATUS_SPEC = Elegant_Score_Config.StatusSpectator or "Spectator"

local Elegant = nil

local function CanSee()
    if not Elegant_Score_Config.StaffGroups[ LocalPlayer():GetUserGroup() ] then
        return false
    end
    return true
end

local function LerpColor( t, from, to )
    return Color(
        Lerp( t, from.r, to.r ),
        Lerp( t, from.g, to.g ),
        Lerp( t, from.b, to.b ),
        Lerp( t, from.a or 255, to.a or 255 )
    )
end

local function CanReveal( viewer, target )
    if not IsValid( viewer ) or not IsValid( target ) then return false end
    if viewer == target then return true end
    if BR and BR.IsSpectator then
        return BR.IsSpectator( viewer )
    end
    return false
end

local function GetDisplayName( viewer, target )
    if CanReveal( viewer, target ) then
        if BR and BR.GetDisplayName then
            return BR.GetDisplayName( target )
        end
        return target:Nick()
    end
    return UNKNOWN_TEXT
end

local function GetRoleName( viewer, target )
    if CanReveal( viewer, target ) then
        if BR and BR.GetPlayerClass then
            local role = BR.GetPlayerClass( target )
            return role and role.name or UNKNOWN_TEXT
        end
        return UNKNOWN_TEXT
    end
    return UNKNOWN_TEXT
end

local function GetStatusName( viewer, target )
    if not CanReveal( viewer, target ) then
        return UNKNOWN_TEXT
    end
    if BR and BR.IsSpectator and BR.IsSpectator( target ) then
        return STATUS_SPEC
    end
    return target:Alive() and STATUS_ALIVE or STATUS_DEAD
end

local function GetFactionColor( viewer, target )
    if not CanReveal( viewer, target ) then
        return Color( 90, 90, 90 )
    end
    if BR and BR.GetPlayerClass then
        local role = BR.GetPlayerClass( target )
        if role and BR.Factions and BR.Factions[ role.faction or "" ] then
            return BR.Factions[ role.faction ].color
        end
    end
    return Color( 110, 110, 110 )
end

local function CreateSimpleButton( parent, x, y, txt, font, col, target, click, cusFunc )
    local self = vgui.Create( 'DButton', parent )
    self:SetPos( x, y )
    self:SetSize( 120, 40 )
    self:SetFont( font )
    self:SetText( txt )
    self:SetTextColor( col )
    if not cusFunc then
        self.DoClick = function()
            if not IsValid( target ) then return end
            LocalPlayer():ConCommand( click )
        end
    else
        self.DoClick = cusFunc
    end
    self.OnCursorEntered = function() self.Hover = true end
    self.OnCursorExited = function() self.Hover = false end
    self.Paint = function( me, w, h )
        if self.Hover then
            ElegantDrawing.DrawRect( 0, 0, w, h, Color( 12, 12, 12, 100 ) )
        else
            ElegantDrawing.DrawRect( 0, 0, w, h, Color( 32, 32, 32, 200 ) )
        end
    end
    return self
end

local function TranslateGroup( x, c )
    if not c then
        if Elegant_Score_Config.Groups[ x ] then
            return Elegant_Score_Config.Groups[ x ].name
        else
            return 'User'
        end
    else
        if Elegant_Score_Config.Groups[ x ] then
            return Elegant_Score_Config.Groups[ x ].color
        else
            return Color( 255, 255, 255 )
        end
    end
end

local function ElegantCreateInspect( x )
    Inspect = vgui.Create( 'DFrame' )
    Inspect:SetSize( 400, 610 )
    Inspect:SetTitle( '' )
    Inspect:SetDraggable( false )
    Inspect:SetVisible( true )
    Inspect:ShowCloseButton( false )
    Inspect:Center()
    Inspect.Paint = function( me, w, h )
        if not IsValid( x ) then Inspect:Remove() return end
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 22, 22, 22 ) )
        ElegantDrawing.DrawRect( 5, 50, w - 10, 3, Color( 3,169,244, 255 ) )
        ElegantDrawing.DrawRect( 5, 5, w - 10, 3, Color( 3,169,244, 255 ) )

        ElegantDrawing.DrawRect( 5, 12, w - 10, 37, Color( 36, 36, 36, 230 ) )
        ElegantDrawing.DrawOutlinedRect( 0, 0, w, h, 4, Color( 0, 0, 0 ) )

        ElegantDrawing.DrawRect( 5, h / 2 + 110, w - 10, 3, Color( 178, 34, 34 ) )
        ElegantDrawing.DrawRect( 5, h / 2 + 50, w - 10, 3, Color( 178, 34, 34 ) )

        ElegantDrawing.DrawText( x:Nick(), "ElegantScoreFontMedium", w / 2, 15, Color( 255, 255, 255 ) )
        ElegantDrawing.DrawText( TranslateGroup( x:GetUserGroup(), false ), "ElegantScoreFontMedium", w / 2 - 5, 70, TranslateGroup( x:GetUserGroup(), true ) )
        ElegantDrawing.DrawText( x:SteamID(), "ElegantScoreFontMedium", w / 2, h / 2 + 65, Color( 255, 255, 255 ) )
        ElegantDrawing.DrawText( 'Basic Commands', "ElegantScoreFontMedium", w / 2, h / 2 + 125, Color( 255, 255, 255 ) )
    end

    local model = vgui.Create( 'DModelPanel', Inspect )
    model:SetSize( 210, 225 )
    model:SetPos( 90, 115 )
    model:SetModel( x:GetModel() )
    model:SetMouseInputEnabled( true )
    model:SetCamPos( Vector( 50, 0, 60 ) )
    function model:LayoutEntity() return end
    local obj = baseclass.Get( 'DModelPanel' )
    model.Paint = function( me, w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 28, 28, 28, 200 ) )
        obj.Paint( me, w, h )
    end

    local steam_copy = vgui.Create( 'DImageButton', Inspect )
    steam_copy:SetPos( Inspect:GetWide() / 2 + 150, Inspect:GetTall() / 2 + 73 )
    steam_copy:SetSize( 16, 16 )
    steam_copy:SetIcon( 'icon16/paste_plain.png' )
    steam_copy.DoClick = function()
        if not IsValid( x ) then return end
        SetClipboardText( x:SteamID() )
        LocalPlayer():ChatPrint( x:Nick() .. "'s SteamID has been copied to your clipboard." )
    end

    CreateSimpleButton( Inspect, 15, Inspect:GetTall() / 2 + 175, 'Teleport To', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'ulx goto ' .. x:Nick() )
    CreateSimpleButton( Inspect, 140, Inspect:GetTall() / 2 + 175, 'Bring', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'ulx bring ' .. x:Nick() )
    CreateSimpleButton( Inspect, Inspect:GetWide() / 2 + 65, Inspect:GetTall() / 2 + 175, x.FreezeState and x.FreezeState or 'Freeze', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, nil, function( self )
        if not x.Is_Frozen then
            x.FreezeState = 'Unfreeze'
            self:SetText( x.FreezeState )
            LocalPlayer():ConCommand( 'ulx freeze ' .. x:Nick() )
            x.Is_Frozen = true
        else
            x.FreezeState = 'Freeze'
            self:SetText( x.FreezeState )
            LocalPlayer():ConCommand( 'ulx unfreeze ' .. x:Nick() )
            x.Is_Frozen = false
        end
    end )
    CreateSimpleButton( Inspect, 80, Inspect:GetTall() / 2 + 225, x.JailState and x.JailState or 'Jail', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, nil, function( self )
        if not x.Is_Jailed then
            x.JailState = 'Unjail'
            self:SetText( x.JailState )
            LocalPlayer():ConCommand( 'ulx jail ' .. x:Nick() )
            x.Is_Jailed = true
        else
            x.JailState = 'Jail'
            self:SetText( x.JailState )
            LocalPlayer():ConCommand( 'ulx unjail ' .. x:Nick() )
            x.Is_Jailed = false
        end
    end )
    CreateSimpleButton( Inspect, 210, Inspect:GetTall() / 2 + 225, 'Spectate', 'ElegantScoreFontTiny', Color( 255, 255, 255 ), x, 'fspectate ' .. x:Nick() )
end

local function CreatePlayerRow( parent, ply, index )
    local row = vgui.Create( 'DPanel', parent )
    row:Dock( TOP )
    row:DockMargin( 8, 6, 8, 0 )
    row:SetTall( 38 )
    row.AlphaLerp = 0
    row.HoverLerp = 0
    row.OffsetLerp = 0

    row.OnCursorEntered = function() row.Hover = true end
    row.OnCursorExited = function() row.Hover = false end

    row.Paint = function( me, w, h )
        if not IsValid( ply ) then me:Remove() return end

        local viewer = LocalPlayer()
        local reveal = CanReveal( viewer, ply )
        row.AlphaLerp = Lerp( FrameTime() * 8, row.AlphaLerp, 1 )
        row.HoverLerp = Lerp( FrameTime() * 10, row.HoverLerp, row.Hover and 1 or 0 )
        row.OffsetLerp = 0

        local baseCol = Color( 18, 18, 18, math.floor( 170 * row.AlphaLerp ) )
        local hoverCol = Color( 35, 35, 35, math.floor( 210 * row.AlphaLerp ) )
        local backCol = LerpColor( row.HoverLerp, baseCol, hoverCol )
        ElegantDrawing.DrawRect( 0, 0, w, h, backCol )

        local accent = GetFactionColor( viewer, ply )
        local accentBright = LerpColor( row.HoverLerp, accent, Color( 255, 255, 255 ) )
        surface.SetDrawColor( accentBright.r, accentBright.g, accentBright.b, math.floor( 180 * row.AlphaLerp ) )
        surface.DrawRect( 0, 0, 3, h )

        local name = reveal and GetDisplayName( viewer, ply ) or UNKNOWN_TEXT
        local role = reveal and GetRoleName( viewer, ply ) or UNKNOWN_TEXT
        local status = reveal and GetStatusName( viewer, ply ) or UNKNOWN_TEXT

        local nameCol = reveal and Color( 235, 235, 235, math.floor( 230 * row.AlphaLerp ) ) or Color( 160, 160, 160, math.floor( 200 * row.AlphaLerp ) )
        local roleCol = reveal and Color( accent.r, accent.g, accent.b, math.floor( 220 * row.AlphaLerp ) ) or Color( 150, 150, 150, math.floor( 180 * row.AlphaLerp ) )
        local statusCol = Color( 160, 160, 160, math.floor( 210 * row.AlphaLerp ) )
        if status == STATUS_ALIVE then
            statusCol = Color( 120, 210, 120, math.floor( 220 * row.AlphaLerp ) )
        elseif status == STATUS_DEAD then
            statusCol = Color( 220, 120, 120, math.floor( 220 * row.AlphaLerp ) )
        elseif status == STATUS_SPEC then
            statusCol = Color( 170, 170, 210, math.floor( 220 * row.AlphaLerp ) )
        end

        local contentX = 40
        draw.SimpleText( name, "ElegantScoreFontTiny", contentX, h / 2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( role, "ElegantScoreFontTiny", w * 0.52, h / 2, roleCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( status, "ElegantScoreFontTiny", w * 0.72, h / 2, statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( ply:Ping(), "ElegantScoreFontTiny", w - 55, h / 2, Color( 230, 230, 230, math.floor( 220 * row.AlphaLerp ) ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    row.PerformLayout = function( me )
        if IsValid( me.Avatar ) then
            me.Avatar:SetPos( 8, math.floor( ( me:GetTall() - 28 ) * 0.5 ) )
        end
    end

    local avatar = vgui.Create( "AvatarImage", row )
    avatar:SetSize( 28, 28 )
    avatar:SetPos( 8, 5 )
    avatar:SetPlayer( ply, 32 )
    row.Avatar = avatar

    local bounds = vgui.Create( "DButton", row )
    bounds:Dock( FILL )
    bounds:SetText( "" )
    bounds.Paint = nil
    bounds.DoDoubleClick = function()
        if not CanSee() then return end
        if IsValid( Inspect ) then Inspect:Remove() end
        ElegantCreateInspect( ply )
    end
end

local function ElegantCreateBase()
    Elegant = vgui.Create( 'DFrame' )
    Elegant:SetSize( math.min( ScrW() * 0.78, 1100 ), math.min( ScrH() * 0.82, 760 ) )
    Elegant:SetTitle( '' )
    Elegant:SetDraggable( false )
    Elegant:SetVisible( true )
    Elegant:ShowCloseButton( false )
    Elegant:Center()
    Elegant.AlphaLerp = 0
    Elegant.OffsetLerp = 24
    gui.EnableScreenClicker( true )

    Elegant.Paint = function( me, w, h )
        me.AlphaLerp = Lerp( FrameTime() * 6, me.AlphaLerp, 1 )
        me.OffsetLerp = Lerp( FrameTime() * 6, me.OffsetLerp, 0 )
        local alpha = math.floor( 255 * me.AlphaLerp )
        ElegantDrawing.BlurMenu( me, 12, 18, 180 )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 10, 10, 10, alpha ) )
        ElegantDrawing.DrawRect( 0, 0, w, 70, Color( 18, 18, 18, math.floor( 180 * me.AlphaLerp ) ) )
        ElegantDrawing.DrawRect( 12, 72, w - 24, 26, Color( 30, 30, 30, math.floor( 150 * me.AlphaLerp ) ) )

        draw.SimpleText( Elegant_Score_Config.ServerName, "ElegantScoreFont", w / 2, 18 + me.OffsetLerp, Color( 240, 240, 240, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        local total = #player.GetAll()
        local info = total == 1 and 'There is currently 1 person online.' or 'There are currently ' .. total .. ' players online.'
        draw.SimpleText( info, "ElegantScoreFontUnder", w / 2, h - 18, Color( 120, 170, 220, alpha ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

        draw.SimpleText( "Name", "ElegantScoreFontHeader", 50, 77, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( "Role", "ElegantScoreFontHeader", w * 0.52, 77, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( "Status", "ElegantScoreFontHeader", w * 0.72, 77, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
        draw.SimpleText( "Ping", "ElegantScoreFontHeader", w - 60, 77, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
    end

    local website = vgui.Create( 'DLabel', Elegant )
    website:SetPos( Elegant:GetWide() - 240, 8 )
    website:SetSize( 230, 30 )
    website:SetFont( "ElegantScoreFontSmall" )
    website:SetTextColor( Color( 120, 170, 220, 220 ) )
    website:SetText( Elegant_Score_Config.WebsiteLinkName )
    website:SetCursor( "hand" )
    website:SetMouseInputEnabled( true )
    website.OnMousePressed = function()
        gui.OpenURL( 'http://' .. Elegant_Score_Config.WebsiteLink )
    end

    Elegant.PlayerList = vgui.Create( "DScrollPanel", Elegant )
    Elegant.PlayerList:SetSize( Elegant:GetWide() - 24, Elegant:GetTall() - 130 )
    Elegant.PlayerList:SetPos( 12, 110 )
    Elegant.PlayerList.Paint = function( me, w, h )
        ElegantDrawing.DrawRect( 0, 0, w, h, Color( 24, 24, 24, 210 ) )
    end

    local sbar = Elegant.PlayerList.VBar
    function sbar:Paint( w, h ) ElegantDrawing.DrawRect( 0, 0, w, h, Color( 0, 0, 0, 90 ) ) end
    function sbar.btnUp:Paint( w, h ) ElegantDrawing.DrawRect( 0, 0, w, h, Color( 40, 40, 40 ) ) end
    function sbar.btnDown:Paint( w, h ) ElegantDrawing.DrawRect( 0, 0, w, h, Color( 40, 40, 40 ) ) end
    function sbar.btnGrip:Paint( w, h ) ElegantDrawing.DrawRect( 0, 0, w, h, Color( 60, 60, 60 ) ) end

    function Elegant:RefreshPlayers()
        if not IsValid( self.PlayerList ) then return end
        self.PlayerList:Clear()

        local players = player.GetAll()
        table.sort( players, function( a, b )
            local ta, tb = a:Team(), b:Team()
            if ta == tb then
                return a:Nick() < b:Nick()
            end
            return ta < tb
        end )

        for i, ply in ipairs( players ) do
            CreatePlayerRow( self.PlayerList, ply, i )
        end
        self.PlayerCount = #players
    end

    Elegant:RefreshPlayers()
    Elegant.NextRefresh = CurTime() + 0.4
    Elegant.Think = function( me )
        if me.NextRefresh and me.NextRefresh < CurTime() then
            local count = #player.GetAll()
            if me.PlayerCount ~= count then
                me:RefreshPlayers()
            end
            me.NextRefresh = CurTime() + 0.4
        end
    end
end

local function ElegantHide()
    if IsValid( Elegant ) then
        Elegant:SetVisible( false )
    end
    gui.EnableScreenClicker( false )
end

hook.Add( 'ScoreboardShow', 'ELEGANT_CREATE_BOARD', function()
    if not IsValid( Elegant ) then
        ElegantCreateBase()
    else
        Elegant:SetVisible( true )
    end
    return true
end )

hook.Add( 'ScoreboardHide', 'ELEGANT_REMOVE_BOARD', function()
    if IsValid( Elegant ) then ElegantHide() end
    if IsValid( Inspect ) then Inspect:Remove() end
    return true
end )
