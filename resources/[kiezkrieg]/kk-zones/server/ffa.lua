-- KiezKrieg FFA Server
ESX = exports['es_extended']:getSharedObject()

-- FFA Variables
local FFAPlayers = {}  -- Players currently in FFA
local FFAZones = {}    -- Zone data with active players
local RoutingBuckets = {} -- Track used routing buckets

-- Initialize FFA system
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for other resources
    LoadFFAZones()
    print('[KiezKrieg] FFA system initialized')
end)

-- Load FFA zones from database
function LoadFFAZones()
    MySQL.Async.fetchAll('SELECT * FROM kk_zones WHERE type = @type AND is_active = 1', {
        ['@type'] = 'ffa'
    }, function(result)
        for _, zone in pairs(result) do
            FFAZones[zone.id] = {
                id = zone.id,
                name = zone.name,
                coords = vector3(zone.x, zone.y, zone.z),
                radius = zone.radius,
                color = zone.color,
                maxPlayers = zone.max_players,
                currentPlayers = {},
                headshotPlayers = {},
                bodyshotPlayers = {},
                routingBucket = Config.RoutingBuckets.ffa_start + zone.id
            }
        end
        print('[KiezKrieg] Loaded ' .. #result .. ' FFA zones')
    end)
end

-- Server Events
RegisterServerEvent('kk-ffa:joinZone')
AddEventHandler('kk-ffa:joinZone', function(zoneId, weaponMode)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local zone = FFAZones[zoneId]
    if not zone then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Zone not found', 'error')
        return
    end
    
    -- Check if zone is full
    if #zone.currentPlayers >= zone.maxPlayers then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Zone is full', 'error')
        return
    end
    
    -- Check if player is already in FFA
    if FFAPlayers[identifier] then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You are already in FFA', 'error')
        return
    end
    
    -- Join the zone
    JoinFFAZone(source, identifier, zoneId, weaponMode)
end)

RegisterServerEvent('kk-ffa:leaveZone')
AddEventHandler('kk-ffa:leaveZone', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if FFAPlayers[identifier] then
        LeaveFFAZone(source, identifier)
    end
end)

RegisterServerEvent('kk-ffa:playerKilled')
AddEventHandler('kk-ffa:playerKilled', function(killerId)
    local source = source -- victim
    local victimIdentifier = GetPlayerIdentifier(source, 0)
    local killerIdentifier = GetPlayerIdentifier(killerId, 0)
    
    if FFAPlayers[victimIdentifier] and FFAPlayers[killerIdentifier] then
        local victimData = FFAPlayers[victimIdentifier]
        local killerData = FFAPlayers[killerIdentifier]
        
        -- Update stats
        TriggerEvent('kk-core:updatePlayerStats', killerId, victimData.weaponMode, 'kills', 1)
        TriggerEvent('kk-core:updatePlayerStats', killerId, 'ffa', 'kills', 1)
        TriggerEvent('kk-core:updatePlayerStats', source, victimData.weaponMode, 'deaths', 1)
        TriggerEvent('kk-core:updatePlayerStats', source, 'ffa', 'deaths', 1)
        
        -- Respawn victim
        Citizen.SetTimeout(3000, function()
            RespawnPlayerInZone(source, victimData.zoneId)
        end)
        
        -- Notify players
        exports['kk-ui']:ShowNotificationToPlayer(killerId, 'Kill! +1', 'success')
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You were killed! Respawning...', 'info')
    end
end)

-- Join FFA Zone
function JoinFFAZone(playerId, identifier, zoneId, weaponMode)
    local zone = FFAZones[zoneId]
    if not zone then return end
    
    -- Create player data
    local playerData = {
        playerId = playerId,
        identifier = identifier,
        zoneId = zoneId,
        weaponMode = weaponMode,
        kills = 0,
        deaths = 0,
        joinTime = GetGameTimer()
    }
    
    -- Add to zone and global tracking
    table.insert(zone.currentPlayers, identifier)
    if weaponMode == 'headshot' then
        table.insert(zone.headshotPlayers, identifier)
    else
        table.insert(zone.bodyshotPlayers, identifier)
    end
    FFAPlayers[identifier] = playerData
    
    -- Set routing bucket for isolation
    SetPlayerRoutingBucket(playerId, zone.routingBucket)
    
    -- Teleport to zone
    TeleportPlayerToZone(playerId, zone)
    
    -- Give weapons based on mode
    TriggerClientEvent('kk-ffa:giveWeapons', playerId, weaponMode)
    
    -- Notify player
    exports['kk-ui']:ShowNotificationToPlayer(playerId, 'Joined ' .. zone.name .. ' (' .. weaponMode .. ' mode)', 'success')
    
    -- Update zone info for all players
    BroadcastZoneUpdate(zoneId)
    
    print('[KiezKrieg] Player ' .. identifier .. ' joined FFA zone ' .. zone.name .. ' (' .. weaponMode .. ')')
end

-- Leave FFA Zone
function LeaveFFAZone(playerId, identifier)
    local playerData = FFAPlayers[identifier]
    if not playerData then return end
    
    local zone = FFAZones[playerData.zoneId]
    if zone then
        -- Remove from zone
        for i, id in ipairs(zone.currentPlayers) do
            if id == identifier then
                table.remove(zone.currentPlayers, i)
                break
            end
        end
        
        -- Remove from weapon mode list
        if playerData.weaponMode == 'headshot' then
            for i, id in ipairs(zone.headshotPlayers) do
                if id == identifier then
                    table.remove(zone.headshotPlayers, i)
                    break
                end
            end
        else
            for i, id in ipairs(zone.bodyshotPlayers) do
                if id == identifier then
                    table.remove(zone.bodyshotPlayers, i)
                    break
                end
            end
        end
        
        -- Update zone info
        BroadcastZoneUpdate(playerData.zoneId)
    end
    
    -- Remove from global tracking
    FFAPlayers[identifier] = nil
    
    -- Reset routing bucket to lobby
    SetPlayerRoutingBucket(playerId, Config.RoutingBuckets.lobby)
    
    -- Teleport to lobby
    TriggerClientEvent('kk-ffa:teleportToLobby', playerId)
    
    -- Remove weapons
    TriggerClientEvent('kk-ffa:removeWeapons', playerId)
    
    -- Notify player
    exports['kk-ui']:ShowNotificationToPlayer(playerId, 'Left FFA zone', 'info')
    
    print('[KiezKrieg] Player ' .. identifier .. ' left FFA')
end

-- Teleport player to zone
function TeleportPlayerToZone(playerId, zone)
    -- Generate random spawn point within zone
    local angle = math.random() * 2 * math.pi
    local distance = math.random(zone.radius * 0.3, zone.radius * 0.8)
    local x = zone.coords.x + math.cos(angle) * distance
    local y = zone.coords.y + math.sin(angle) * distance
    local z = zone.coords.z
    
    TriggerClientEvent('kk-ffa:teleportToPosition', playerId, {x = x, y = y, z = z, h = math.random(0, 360)})
end

-- Respawn player in zone
function RespawnPlayerInZone(playerId, zoneId)
    local zone = FFAZones[zoneId]
    if zone then
        TeleportPlayerToZone(playerId, zone)
        TriggerClientEvent('kk-ffa:respawned', playerId)
    end
end

-- Broadcast zone updates to all players
function BroadcastZoneUpdate(zoneId)
    local zone = FFAZones[zoneId]
    if not zone then return end
    
    local zoneData = {
        id = zone.id,
        name = zone.name,
        type = 'ffa',
        coords = zone.coords,
        radius = zone.radius,
        color = zone.color,
        maxPlayers = zone.maxPlayers,
        currentPlayers = zone.currentPlayers,
        headshotCount = #zone.headshotPlayers,
        bodyshotCount = #zone.bodyshotPlayers
    }
    
    TriggerClientEvent('kk-zones:zoneUpdated', -1, zoneData)
end

-- Player disconnect handler
AddEventHandler('esx:playerDropped', function(playerId, reason)
    local identifier = GetPlayerIdentifier(playerId, 0)
    if FFAPlayers[identifier] then
        LeaveFFAZone(playerId, identifier)
    end
end)

-- Export functions
exports('GetFFAZones', function()
    return FFAZones
end)

exports('GetFFAPlayers', function()
    return FFAPlayers
end)

exports('IsPlayerInFFA', function(identifier)
    return FFAPlayers[identifier] ~= nil
end)