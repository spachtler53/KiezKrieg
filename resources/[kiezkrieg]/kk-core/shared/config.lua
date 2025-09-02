KiezKrieg = {}
KiezKrieg.Config = {}

-- Game Modes
KiezKrieg.GAME_MODES = {
    FFA_HEADSHOT = 'ffa_headshot',
    FFA_BODYSHOT = 'ffa_bodyshot',
    CUSTOM_LOBBY = 'custom_lobby',
    HELIFIGHT = 'helifight',
    GANGWAR = 'gangwar'
}

-- Zone Configuration
KiezKrieg.Config.Zones = {
    FFA = {
        {
            id = 1,
            name = "Downtown FFA",
            coords = vector3(-1037.0, -2737.0, 20.2),
            radius = 100.0,
            maxPlayers = 10,
            color = {r = 0, g = 100, b = 255, a = 100}
        },
        {
            id = 2,
            name = "Airport FFA",
            coords = vector3(-1336.0, -3044.0, 13.9),
            radius = 100.0,
            maxPlayers = 10,
            color = {r = 0, g = 100, b = 255, a = 100}
        },
        {
            id = 3,
            name = "Industrial FFA",
            coords = vector3(715.0, -962.0, 30.4),
            radius = 100.0,
            maxPlayers = 10,
            color = {r = 0, g = 100, b = 255, a = 100}
        },
        {
            id = 4,
            name = "Beach FFA",
            coords = vector3(-1212.0, -1607.0, 4.6),
            radius = 100.0,
            maxPlayers = 10,
            color = {r = 0, g = 100, b = 255, a = 100}
        },
        {
            id = 5,
            name = "Hills FFA",
            coords = vector3(-2072.0, 3170.0, 32.8),
            radius = 100.0,
            maxPlayers = 10,
            color = {r = 0, g = 100, b = 255, a = 100}
        }
    }
}

-- Weapon Configuration
KiezKrieg.Config.Weapons = {
    HEADSHOT_MODE = {
        primary = GetHashKey("WEAPON_PISTOL")
    },
    BODYSHOT_MODE = {
        primary = GetHashKey("WEAPON_SPECIALCARBINE"),
        secondary = GetHashKey("WEAPON_ADVANCEDRIFLE")
    },
    HELIFIGHT = {
        pilot = nil, -- No weapon for pilot
        copilot = GetHashKey("WEAPON_REVOLVER"),
        rear = GetHashKey("WEAPON_SPECIALCARBINE")
    }
}

-- Vehicle Configuration
KiezKrieg.Config.Vehicles = {
    LOBBY_VEHICLES = {
        "drafter",
        "schafter2",
        "jugular",
        "revolter"
    },
    HELIFIGHT_VEHICLE = "supervolito"
}

-- Spawn Points Configuration
KiezKrieg.Config.SpawnPoints = {
    FFA = {
        {coords = vector3(-1000.0, -2700.0, 20.2), heading = 180.0},
        {coords = vector3(-1074.0, -2774.0, 20.2), heading = 90.0},
        {coords = vector3(-1037.0, -2700.0, 20.2), heading = 0.0},
        {coords = vector3(-1000.0, -2774.0, 20.2), heading = 270.0}
    }
}

-- Admin Configuration
KiezKrieg.Config.Admin = {
    GROUPS = {
        'admin',
        'superadmin',
        'owner'
    }
}

-- UI Configuration
KiezKrieg.Config.UI = {
    MENU_KEY = 289, -- F2 key
    GRADIENT_COLORS = {
        start = "#007BFF", -- Blue
        end = "#FF69B4"    -- Pink
    }
}