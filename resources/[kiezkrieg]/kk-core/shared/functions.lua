-- KiezKrieg Shared Functions
KK = {}
KK.Players = {}
KK.Zones = {}
KK.Lobbies = {}

-- Player data structure
function KK.CreatePlayerData(identifier, playerName)
    return {
        identifier = identifier,
        playerName = playerName,
        currentMode = 'lobby',
        currentZone = nil,
        currentLobby = nil,
        faction = nil,
        team = nil,
        kills = 0,
        deaths = 0,
        routingBucket = 0,
        preferences = {
            autoOpenMenu = true,
            preferredWeaponMode = 'bodyshot',
            uiColorTheme = 'blue_pink',
            soundEnabled = true,
            notificationsEnabled = true
        },
        stats = {
            headshot = {kills = 0, deaths = 0},
            bodyshot = {kills = 0, deaths = 0},
            ffa = {kills = 0, deaths = 0},
            custom = {kills = 0, deaths = 0},
            helifight = {kills = 0, deaths = 0},
            gangwar = {kills = 0, deaths = 0},
            totalPlaytime = 0
        }
    }
end

-- Zone data structure
function KK.CreateZoneData(id, name, type, coords, radius, color, maxPlayers)
    return {
        id = id,
        name = name,
        type = type,
        coords = coords,
        radius = radius,
        color = color,
        maxPlayers = maxPlayers,
        currentPlayers = {},
        isActive = true
    }
end

-- Lobby data structure
function KK.CreateLobbyData(id, name, creator, zoneId, maxPlayers, isPrivate, password)
    return {
        id = id,
        name = name,
        creator = creator,
        zoneId = zoneId,
        maxPlayers = maxPlayers,
        isPrivate = isPrivate,
        password = password,
        currentPlayers = {},
        teams = {
            [1] = {},
            [2] = {}
        },
        status = 'waiting',
        routingBucket = nil
    }
end

-- Utility functions
function KK.GetDistance(pos1, pos2)
    return math.sqrt(
        (pos1.x - pos2.x) ^ 2 +
        (pos1.y - pos2.y) ^ 2 +
        (pos1.z - pos2.z) ^ 2
    )
end

function KK.IsPlayerInZone(playerPos, zonePos, radius)
    local distance = KK.GetDistance(playerPos, zonePos)
    return distance <= radius
end

function KK.GetRandomSpawnPoint(points)
    if not points or #points == 0 then
        return {x = 0.0, y = 0.0, z = 100.0, h = 0.0}
    end
    return points[math.random(1, #points)]
end

function KK.GenerateSpawnPointsAroundZone(zoneCoords, radius, count)
    local spawnPoints = {}
    local angleStep = 360 / count
    
    for i = 1, count do
        local angle = math.rad(angleStep * i)
        local spawnRadius = radius * 0.8 -- Spawn inside the zone
        local x = zoneCoords.x + math.cos(angle) * spawnRadius
        local y = zoneCoords.y + math.sin(angle) * spawnRadius
        local z = zoneCoords.z
        local h = (angleStep * i) + 180 -- Face inward
        
        table.insert(spawnPoints, {x = x, y = y, z = z, h = h})
    end
    
    return spawnPoints
end

function KK.GetPlayerKDA(stats)
    local totalKills = stats.headshot.kills + stats.bodyshot.kills + stats.ffa.kills + 
                      stats.custom.kills + stats.helifight.kills + stats.gangwar.kills
    local totalDeaths = stats.headshot.deaths + stats.bodyshot.deaths + stats.ffa.deaths + 
                       stats.custom.deaths + stats.helifight.deaths + stats.gangwar.deaths
    
    local kda = totalDeaths > 0 and (totalKills / totalDeaths) or totalKills
    return {
        kills = totalKills,
        deaths = totalDeaths,
        kda = math.floor(kda * 100) / 100
    }
end

function KK.GetModeKDA(stats, mode)
    if not stats[mode] then return {kills = 0, deaths = 0, kda = 0.0} end
    
    local kills = stats[mode].kills
    local deaths = stats[mode].deaths
    local kda = deaths > 0 and (kills / deaths) or kills
    
    return {
        kills = kills,
        deaths = deaths,
        kda = math.floor(kda * 100) / 100
    }
end

-- Color utility functions
function KK.HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber("0x" .. hex:sub(1, 2)),
        g = tonumber("0x" .. hex:sub(3, 4)),
        b = tonumber("0x" .. hex:sub(5, 6))
    }
end

function KK.RGBToHex(r, g, b)
    return string.format("#%02x%02x%02x", r, g, b)
end

-- Validation functions
function KK.IsValidIdentifier(identifier)
    return identifier and type(identifier) == 'string' and #identifier > 0
end

function KK.IsValidPlayerName(name)
    return name and type(name) == 'string' and #name >= 3 and #name <= 50
end

function KK.IsValidZoneName(name)
    return name and type(name) == 'string' and #name >= 3 and #name <= 100
end