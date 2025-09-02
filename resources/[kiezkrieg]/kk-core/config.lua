Config = {}

-- General Settings
Config.Debug = true
Config.ESXTrigger = 'esx:getSharedObject'

-- Game Modes
Config.GameModes = {
    FFA = {
        enabled = true,
        maxPlayers = 10,
        zoneRadius = 100,
        modes = {
            headshot = {
                weapon = 'WEAPON_PISTOL',
                ammo = 250
            },
            bodyshot = {
                primaryWeapon = 'WEAPON_SPECIALCARBINE',
                secondaryWeapon = 'WEAPON_ADVANCEDRIFLE',
                ammo = 250
            }
        }
    },
    CustomLobbies = {
        enabled = true,
        maxTeams = 2,
        vehicles = {
            'drafter',
            'schafter2',
            'jugular',
            'revolter'
        }
    },
    Helifight = {
        enabled = true,
        maxRounds = 15,
        teamSize = 3,
        helicopter = 'supervolito',
        roles = {
            pilot = { weapon = nil },
            copilot = { weapon = 'WEAPON_REVOLVER' },
            passenger = { weapon = 'WEAPON_SPECIALCARBINE' }
        }
    }
}

-- FFA Zones (Placeholder coordinates)
Config.FFAZones = {
    {
        id = 1,
        name = 'Downtown Arena',
        coords = vector3(-265.0, -957.0, 31.0),
        radius = 100.0,
        color = { r = 0, g = 162, b = 232, a = 100 },
        spawnPoints = {
            vector4(-265.0, -957.0, 31.0, 0.0),
            vector4(-245.0, -937.0, 31.0, 90.0),
            vector4(-285.0, -977.0, 31.0, 180.0),
            vector4(-225.0, -917.0, 31.0, 270.0)
        }
    },
    {
        id = 2,
        name = 'Airport Battleground',
        coords = vector3(-1037.0, -2737.0, 20.0),
        radius = 100.0,
        color = { r = 0, g = 162, b = 232, a = 100 },
        spawnPoints = {
            vector4(-1037.0, -2737.0, 20.0, 0.0),
            vector4(-1017.0, -2717.0, 20.0, 90.0),
            vector4(-1057.0, -2757.0, 20.0, 180.0),
            vector4(-997.0, -2697.0, 20.0, 270.0)
        }
    },
    {
        id = 3,
        name = 'Beach Combat Zone',
        coords = vector3(-1223.0, -1491.0, 4.0),
        radius = 100.0,
        color = { r = 0, g = 162, b = 232, a = 100 },
        spawnPoints = {
            vector4(-1223.0, -1491.0, 4.0, 0.0),
            vector4(-1203.0, -1471.0, 4.0, 90.0),
            vector4(-1243.0, -1511.0, 4.0, 180.0),
            vector4(-1183.0, -1451.0, 4.0, 270.0)
        }
    },
    {
        id = 4,
        name = 'Industrial Warfare',
        coords = vector3(170.0, -1799.0, 29.0),
        radius = 100.0,
        color = { r = 0, g = 162, b = 232, a = 100 },
        spawnPoints = {
            vector4(170.0, -1799.0, 29.0, 0.0),
            vector4(190.0, -1779.0, 29.0, 90.0),
            vector4(150.0, -1819.0, 29.0, 180.0),
            vector4(210.0, -1759.0, 29.0, 270.0)
        }
    },
    {
        id = 5,
        name = 'Mountain Peak',
        coords = vector3(-1616.0, 4763.0, 53.0),
        radius = 100.0,
        color = { r = 0, g = 162, b = 232, a = 100 },
        spawnPoints = {
            vector4(-1616.0, 4763.0, 53.0, 0.0),
            vector4(-1596.0, 4783.0, 53.0, 90.0),
            vector4(-1636.0, 4743.0, 53.0, 180.0),
            vector4(-1576.0, 4803.0, 53.0, 270.0)
        }
    }
}

-- Keybinds
Config.Keys = {
    MainMenu = 0x4AF4D473 -- F2
}

-- UI Settings
Config.UI = {
    gradient = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', -- Blue to pink gradient
    borderRadius = '12px'
}

-- Admin Settings
Config.Admin = {
    groups = {'admin', 'superadmin', 'owner'},
    commands = {
        aduty = 'aduty',
        goto = 'goto',
        tpm = 'tpm',
        bring = 'bring',
        car = 'car',
        dv = 'dv',
        nametags = 'nametags'
    }
}