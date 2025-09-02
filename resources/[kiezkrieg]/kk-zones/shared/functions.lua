-- KiezKrieg Zones Shared Functions
ZoneTypes = {
    FFA = 'ffa',
    CUSTOM = 'custom',
    HELIFIGHT = 'helifight',
    GANGWAR = 'gangwar'
}

ZoneStatus = {
    WAITING = 'waiting',
    ACTIVE = 'active',
    FINISHED = 'finished'
}

-- Zone validation functions
function IsValidZoneType(zoneType)
    for _, validType in pairs(ZoneTypes) do
        if validType == zoneType then
            return true
        end
    end
    return false
end

function IsValidZoneCoords(coords)
    return coords and coords.x and coords.y and coords.z and
           type(coords.x) == 'number' and type(coords.y) == 'number' and type(coords.z) == 'number'
end

function IsValidZoneRadius(radius)
    return radius and type(radius) == 'number' and radius > 0 and radius <= 500
end

-- Zone utility functions
function GetZoneDistance(coords1, coords2)
    return math.sqrt(
        (coords1.x - coords2.x) ^ 2 +
        (coords1.y - coords2.y) ^ 2 +
        (coords1.z - coords2.z) ^ 2
    )
end

function IsPlayerInZoneArea(playerCoords, zoneCoords, radius)
    local distance = GetZoneDistance(playerCoords, zoneCoords)
    return distance <= radius
end

function GetRandomSpawnInZone(zoneCoords, radius, minDistance)
    minDistance = minDistance or radius * 0.2
    local maxDistance = radius * 0.8
    
    local angle = math.random() * 2 * math.pi
    local distance = math.random(minDistance, maxDistance)
    
    local x = zoneCoords.x + math.cos(angle) * distance
    local y = zoneCoords.y + math.sin(angle) * distance
    local z = zoneCoords.z
    local heading = math.random(0, 360)
    
    return {x = x, y = y, z = z, h = heading}
end

-- Zone data structure helpers
function CreateZoneData(id, name, type, coords, radius, color, maxPlayers)
    return {
        id = id,
        name = name,
        type = type,
        coords = coords,
        radius = radius,
        color = color,
        maxPlayers = maxPlayers,
        currentPlayers = {},
        isActive = true,
        createdAt = os.time(),
        lastActivity = os.time()
    }
end

function UpdateZoneActivity(zone)
    if zone then
        zone.lastActivity = os.time()
    end
end

function GetZonePlayerCount(zone)
    if not zone or not zone.currentPlayers then
        return 0
    end
    return #zone.currentPlayers
end

function IsZoneFull(zone)
    if not zone then return true end
    return GetZonePlayerCount(zone) >= zone.maxPlayers
end

function CanJoinZone(zone, playerIdentifier)
    if not zone then return false, 'Zone not found' end
    if not zone.isActive then return false, 'Zone is inactive' end
    if IsZoneFull(zone) then return false, 'Zone is full' end
    
    -- Check if player is already in zone
    for _, identifier in ipairs(zone.currentPlayers) do
        if identifier == playerIdentifier then
            return false, 'Already in zone'
        end
    end
    
    return true, 'OK'
end

-- Zone color utilities
function GetZoneColorRGB(hexColor)
    hexColor = hexColor:gsub("#", "")
    return {
        r = tonumber("0x" .. hexColor:sub(1, 2)),
        g = tonumber("0x" .. hexColor:sub(3, 4)),
        b = tonumber("0x" .. hexColor:sub(5, 6))
    }
end

function GetBlipColorFromHex(hexColor)
    local colorMap = {
        ['#e74c3c'] = 1, -- Red
        ['#3498db'] = 3, -- Blue  
        ['#f39c12'] = 5, -- Yellow
        ['#9b59b6'] = 7, -- Purple
        ['#27ae60'] = 2, -- Green
        ['#ff6b6b'] = 1, -- Red variant
        ['#2ecc71'] = 2, -- Green variant
        ['#f1c40f'] = 5, -- Yellow variant
    }
    return colorMap[hexColor] or 3 -- Default to blue
end