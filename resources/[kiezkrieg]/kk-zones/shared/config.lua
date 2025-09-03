-- KiezKrieg Zones Configuration
Config = Config or {}

-- Routing buckets for isolated gameplay
Config.RoutingBuckets = {
    lobby = 0,
    ffa_start = 100,
    custom_start = 200,
    helifight_start = 300,
    gangwar_start = 400
}

-- FFA Configuration
Config.FFA = {
    enabled = true,
    maxPlayersPerZone = 10,
    weapons = {
        headshot = {'WEAPON_PISTOL'},
        bodyshot = {'WEAPON_SPECIALCARBINE', 'WEAPON_ADVANCEDRIFLE'}
    },
    defaultAmmo = 999,
    defaultArmor = 100,
    defaultHealth = 200,
    respawnDelay = 3000, -- 3 seconds
    killReward = 100, -- Money reward per kill
    headshotMultiplier = 1.5
}

-- Zone Configuration
Config.Zones = {
    markerType = 1,
    markerSize = {x = 2.0, y = 2.0, z = 1.0},
    drawDistance = 100.0,
    interactionDistance = 3.0,
    blipSettings = {
        sprite = 84,
        color = 2,
        scale = 1.0
    },
    -- Default zone settings
    defaultRadius = 50.0,
    defaultMaxPlayers = 10,
    defaultColor = '#3498db'
}

-- Database Configuration
Config.Database = {
    tables = {
        zones = 'kk_zones',
        players = 'kk_players',
        stats = 'kk_player_stats',
        preferences = 'kk_user_preferences'
    },
    updateInterval = 30000 -- Update database every 30 seconds
}

-- UI Configuration
Config.UI = {
    theme = 'blue_pink',
    position = 'center',
    fadeTime = 300,
    soundEnabled = true,
    notifications = {
        duration = 5000, -- 5 seconds
        position = 'top-right'
    }
}

-- Weapon Configuration
Config.Weapons = {
    hashes = {
        WEAPON_PISTOL = GetHashKey('WEAPON_PISTOL'),
        WEAPON_SPECIALCARBINE = GetHashKey('WEAPON_SPECIALCARBINE'),
        WEAPON_ADVANCEDRIFLE = GetHashKey('WEAPON_ADVANCEDRIFLE'),
        WEAPON_REVOLVER = GetHashKey('WEAPON_REVOLVER')
    },
    -- Weapon mode configurations
    modes = {
        headshot = {
            weapons = {'WEAPON_PISTOL'},
            damageMultiplier = 2.0,
            accuracyRequired = 0.8
        },
        bodyshot = {
            weapons = {'WEAPON_SPECIALCARBINE', 'WEAPON_ADVANCEDRIFLE'},
            damageMultiplier = 1.0,
            accuracyRequired = 0.6
        }
    }
}

-- Spawn Points Configuration
Config.SpawnPoints = {
    lobby = {
        {x = -1037.8, y = -2737.9, z = 20.2, h = 240.0}
    },
    ffa = {
        -- Will be populated dynamically based on zone centers
    }
}

-- Error Handling and Fallbacks
Config.ErrorHandling = {
    enableLogging = true,
    fallbackRoutingBucket = 0, -- Lobby bucket as fallback
    maxRetries = 3,
    retryDelay = 1000 -- 1 second
}

-- Debug Configuration
Config.Debug = {
    enabled = false,
    verboseLogging = false,
    showZoneMarkers = true,
    showPlayerBlips = true
}

-- Validation Functions
function Config.ValidateRoutingBucket(bucket)
    if not bucket or type(bucket) ~= 'number' then
        print('[KiezKrieg-Zones] WARNING: Invalid routing bucket, using fallback')
        return Config.ErrorHandling.fallbackRoutingBucket
    end
    return bucket
end

function Config.GetSafeRoutingBucket(bucketType, zoneId)
    local buckets = Config.RoutingBuckets
    if not buckets then
        print('[KiezKrieg-Zones] ERROR: RoutingBuckets not configured')
        return Config.ErrorHandling.fallbackRoutingBucket
    end
    
    local baseBucket = buckets[bucketType .. '_start']
    if not baseBucket then
        print('[KiezKrieg-Zones] ERROR: Unknown bucket type: ' .. tostring(bucketType))
        return Config.ErrorHandling.fallbackRoutingBucket
    end
    
    local finalBucket = baseBucket + (zoneId or 0)
    return Config.ValidateRoutingBucket(finalBucket)
end

-- Initialize default values
function Config.Initialize()
    -- Ensure all required tables exist
    Config.RoutingBuckets = Config.RoutingBuckets or {}
    Config.FFA = Config.FFA or {}
    Config.Zones = Config.Zones or {}
    Config.Database = Config.Database or {}
    Config.UI = Config.UI or {}
    Config.Weapons = Config.Weapons or {}
    Config.SpawnPoints = Config.SpawnPoints or {}
    
    if Config.Debug.enabled then
        print('[KiezKrieg-Zones] Configuration initialized successfully')
        print('[KiezKrieg-Zones] FFA Start Bucket: ' .. tostring(Config.RoutingBuckets.ffa_start))
    end
end

-- Auto-initialize when config is loaded
Config.Initialize()