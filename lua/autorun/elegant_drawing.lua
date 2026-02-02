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

    if !CLIENT then return end

    ElegantDrawing = ElegantDrawing or {}

    function ElegantDrawing.DrawRect( x, y, w, h, col )
        surface.SetDrawColor( col )
        surface.DrawRect( x, y, w, h )
    end

    function ElegantDrawing.DrawText( msg, fnt, x, y, c, align )
        draw.SimpleText( msg, fnt, x, y, c, align and align or TEXT_ALIGN_CENTER )
    end

    function ElegantDrawing.DrawOutlinedRect( x, y, w, h, t, c )
       surface.SetDrawColor( c )
       for i = 0, t - 1 do
           surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
       end
    end

    local blur = Material( "pp/blurscreen" )
    function ElegantDrawing.BlurMenu( panel, layers, density, alpha )
        -- Its a scientifically proven fact that blur improves a script (All credit to Chessnut)
        local x, y = panel:LocalToScreen(0, 0)

        surface.SetDrawColor( 255, 255, 255, alpha )
        surface.SetMaterial( blur )

        for i = 1, 3 do
        	blur:SetFloat( "$blur", ( i / layers ) * density )
        	blur:Recompute()

        	render.UpdateScreenEffectTexture()
        	surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
        end
    end
