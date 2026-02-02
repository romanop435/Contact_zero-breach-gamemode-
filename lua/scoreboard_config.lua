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

    Elegant_Score_Config = Elegant_Score_Config or {}

    Elegant_Score_Config.ServerName = 'Breachymba' -- The name displayed on top of the scoreboard.
    Elegant_Score_Config.WebsiteLink = 'steamcommunity.com/id/tedlua/' -- The link to your website. Don't put https or http. Just the bare link such as www.google.co.uk
    Elegant_Score_Config.WebsiteLinkName = 'Developer Profile' -- The name to show on the link.
    --Super Administrator
    Elegant_Score_Config.Groups = { -- Rank Configuration
        [ 'superadmin' ] = { name = 'Super Administrator', color = Color( 199, 44, 44 ) },
        [ 'developer' ] = { name = 'Developer', color = Color( 199, 44, 44 ) },
        [ 'admin' ] = { name = 'Administrator', color = Color( 241, 196, 15 ) },
        [ 'moderator' ] = { name = 'Moderator', color = Color( 52, 152, 219 ) },
        [ 'donator' ] = { name = 'Donator', color = Color( 155, 89, 182 ) },
        [ 'vip' ] = { name = 'VIP', color = Color( 155, 89, 182 ) }
    }

Elegant_Score_Config.StaffGroups = { -- Who can see the command menu?
    [ 'superadmin' ] = true,
    [ 'admin' ] = true,
    [ 'moderator' ] = true,
    [ 'developer' ] = true
}

Elegant_Score_Config.UnknownText = 'Unknown'
Elegant_Score_Config.StatusAlive = 'Alive'
Elegant_Score_Config.StatusDead = 'Dead'
Elegant_Score_Config.StatusSpectator = 'Spectator'
