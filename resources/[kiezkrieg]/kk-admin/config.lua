Config = {}

-- Admin groups that have access to admin commands
Config.AdminGroups = {
    'admin',
    'superadmin',
    'owner'
}

-- Commands configuration
Config.Commands = {
    aduty = {
        name = 'aduty',
        description = 'Toggle admin duty',
        permission = 'admin'
    },
    goto = {
        name = 'goto',
        description = 'Teleport to player',
        permission = 'admin'
    },
    tpm = {
        name = 'tpm',
        description = 'Teleport to marker',
        permission = 'admin'
    },
    bring = {
        name = 'bring',
        description = 'Bring player to you',
        permission = 'admin'
    },
    car = {
        name = 'car',
        description = 'Spawn vehicle',
        permission = 'admin'
    },
    dv = {
        name = 'dv',
        description = 'Delete nearby vehicles',
        permission = 'admin'
    },
    nametags = {
        name = 'nametags',
        description = 'Toggle nametags',
        permission = 'admin'
    },
    createfaction = {
        name = 'createfaction',
        description = 'Create a new faction',
        permission = 'admin'
    }
}

-- Vehicle spawn settings
Config.VehicleSpawn = {
    defaultFuel = 100,
    spawnInside = true,
    deleteOnExit = false
}

-- Nametag settings
Config.Nametags = {
    distance = 50.0,
    showHealth = true,
    showArmor = true,
    showId = true
}