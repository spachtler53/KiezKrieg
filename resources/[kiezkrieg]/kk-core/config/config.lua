-- KiezKrieg Core Configuration
Config = {}

-- Framework settings
Config.ESXVersion = 'legacy'
Config.FrameworkName = 'es_extended'

-- Database settings
Config.DatabaseResource = 'oxmysql'

-- Main menu settings
Config.MenuKey = 'F2'
Config.AutoOpenMenuAfterSpawn = true

-- Game modes configuration
Config.GameModes = {
    ffa = {
        enabled = true,
        maxPlayersPerZone = 10,
        weapons = {
            headshot = {'WEAPON_PISTOL'},
            bodyshot = {'WEAPON_SPECIALCARBINE', 'WEAPON_ADVANCEDRIFLE'}
        },
        defaultAmmo = 999
    },
    custom = {
        enabled = true,
        maxPlayers = 20,
        teams = 2,
        vehicles = {'drafter', 'schafter2', 'jugular', 'revolter'}
    },
    helifight = {
        enabled = true,
        maxPlayers = 6,
        rounds = 15,
        helicopter = 'supervolito',
        roles = {
            pilot = {weapon = nil},
            copilot = {weapon = 'WEAPON_REVOLVER'},
            rear = {weapon = 'WEAPON_SPECIALCARBINE'}
        }
    },
    gangwar = {
        enabled = true,
        openWorldFactions = true,
        maxFactionsPerPlayer = 1
    }
}

-- Zone settings
Config.Zones = {
    markerType = 1,
    markerSize = {x = 2.0, y = 2.0, z = 1.0},
    drawDistance = 100.0,
    interactionDistance = 3.0,
    blipSettings = {
        sprite = 84,
        color = 2,
        scale = 1.0
    }
}

-- UI Configuration
Config.UI = {
    theme = 'blue_pink',
    position = 'center',
    fadeTime = 300,
    soundEnabled = true
}

-- Admin settings
Config.Admin = {
    groups = {'admin', 'superadmin', 'owner'},
    commands = {
        aduty = true,
        goto = true,
        tpm = true,
        bring = true,
        vehicle = true,
        nametags = true
    }
}

-- Weapon hashes for easy reference
Config.Weapons = {
    WEAPON_PISTOL = GetHashKey('WEAPON_PISTOL'),
    WEAPON_SPECIALCARBINE = GetHashKey('WEAPON_SPECIALCARBINE'),
    WEAPON_ADVANCEDRIFLE = GetHashKey('WEAPON_ADVANCEDRIFLE'),
    WEAPON_REVOLVER = GetHashKey('WEAPON_REVOLVER')
}

-- Vehicle hashes
Config.Vehicles = {
    drafter = GetHashKey('drafter'),
    schafter2 = GetHashKey('schafter2'),
    jugular = GetHashKey('jugular'),
    revolter = GetHashKey('revolter'),
    supervolito = GetHashKey('supervolito')
}

-- Spawn points for different modes
Config.SpawnPoints = {
    lobby = {
        {x = -1037.8, y = -2737.9, z = 20.2, h = 240.0}
    },
    ffa = {
        -- Will be populated dynamically based on zone centers
    },
    helifight = {
        team1 = {x = -100.0, y = -100.0, z = 500.0, h = 0.0},
        team2 = {x = 100.0, y = 100.0, z = 500.0, h = 180.0}
    }
}

-- Routing buckets for isolated gameplay
Config.RoutingBuckets = {
    lobby = 0,
    ffa_start = 100,
    custom_start = 200,
    helifight_start = 300,
    gangwar_start = 400
}