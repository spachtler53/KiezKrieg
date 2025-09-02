-- KiezKrieg Zone Management Server
local ESX = exports["es_extended"]:getSharedObject()

-- Track players in zones
local PlayersInZones = {}

-- Initialize zone data from database
Citizen.CreateThread(function()
    loadZonesFromDatabase()
end)

-- Zone info request
RegisterNetEvent('kk-zones:requestZoneInfo')
AddEventHandler('kk-zones:requestZoneInfo', function(zoneId)
    local src = source
    local playerCount = getPlayersInZone(zoneId)
    local maxPlayers = getZoneMaxPlayers(zoneId)
    
    TriggerClientEvent('kk-zones:updateZoneInfo', src, zoneId, playerCount, maxPlayers)
end)

-- Player enters zone
RegisterNetEvent('kk-zones:playerEnterZone')
AddEventHandler('kk-zones:playerEnterZone', function(zoneId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if not PlayersInZones[zoneId] then
        PlayersInZones[zoneId] = {}
    end
    
    PlayersInZones[zoneId][src] = {
        identifier = xPlayer.identifier,
        name = xPlayer.name,
        enteredAt = os.time()
    }
    
    -- Notify other players in zone
    for playerId, _ in pairs(PlayersInZones[zoneId]) do
        if playerId ~= src then
            TriggerClientEvent('esx:showNotification', playerId, 
                '~b~' .. xPlayer.name .. '~w~ entered the zone')
        end
    end
end)

-- Player leaves zone
RegisterNetEvent('kk-zones:playerLeaveZone')
AddEventHandler('kk-zones:playerLeaveZone', function(zoneId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if PlayersInZones[zoneId] and PlayersInZones[zoneId][src] then
        PlayersInZones[zoneId][src] = nil
        
        -- Notify other players in zone
        for playerId, _ in pairs(PlayersInZones[zoneId]) do
            TriggerClientEvent('esx:showNotification', playerId, 
                '~r~' .. xPlayer.name .. '~w~ left the zone')
        end
    end
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Remove player from all zones
    for zoneId, players in pairs(PlayersInZones) do
        if players[src] then
            players[src] = nil
        end
    end
end)

-- Helper functions
function getPlayersInZone(zoneId)
    if not PlayersInZones[zoneId] then
        return 0
    end
    
    local count = 0
    for _ in pairs(PlayersInZones[zoneId]) do
        count = count + 1
    end
    return count
end

function getZoneMaxPlayers(zoneId)
    -- Get from config or database
    for _, zone in pairs(KiezKrieg.Config.Zones.FFA) do
        if zone.id == zoneId then
            return zone.maxPlayers
        end
    end
    return 10 -- Default
end

function loadZonesFromDatabase()
    -- Load zones from database when available
    -- For now, use config data
    print("[KiezKrieg Zones] Loaded " .. #KiezKrieg.Config.Zones.FFA .. " FFA zones")
end

-- Zone management commands for admins
ESX.RegisterCommand('createzone', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local zoneName = args.name
    local zoneType = args.type or 'ffa'
    local radius = tonumber(args.radius) or 100.0
    
    if not zoneName then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /createzone [name] [type] [radius]')
        return
    end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    -- This would create zone in database
    TriggerClientEvent('esx:showNotification', src, 
        '~g~Zone created: ~w~' .. zoneName .. ' ~g~at your location')
    
    -- Log admin action
    print(string.format("[KiezKrieg Zones] Admin %s created zone '%s' at %s", 
        xPlayer.name, zoneName, playerCoords))
    
end, false, {
    help = 'Create a new zone at your location',
    validate = false,
    arguments = {
        {name = 'name', help = 'Zone name', type = 'string'},
        {name = 'type', help = 'Zone type (ffa, lobby, helifight)', type = 'string'},
        {name = 'radius', help = 'Zone radius in meters', type = 'number'}
    }
})

ESX.RegisterCommand('deletezone', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local zoneName = args.name
    
    if not zoneName then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /deletezone [name]')
        return
    end
    
    -- This would delete zone from database
    TriggerClientEvent('esx:showNotification', src, '~r~Zone deleted: ~w~' .. zoneName)
    
    print(string.format("[KiezKrieg Zones] Admin %s deleted zone '%s'", 
        xPlayer.name, zoneName))
    
end, false, {
    help = 'Delete a zone by name',
    validate = false,
    arguments = {
        {name = 'name', help = 'Zone name to delete', type = 'string'}
    }
})

ESX.RegisterCommand('listzones', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    
    TriggerClientEvent('esx:showNotification', src, '~b~Available Zones:')
    
    for _, zone in pairs(KiezKrieg.Config.Zones.FFA) do
        local playerCount = getPlayersInZone(zone.id)
        TriggerClientEvent('esx:showNotification', src, 
            string.format('~w~%s ~g~(%d/%d players)', zone.name, playerCount, zone.maxPlayers))
    end
    
end, false, {help = 'List all available zones'})

-- Export functions
exports('getPlayersInZone', getPlayersInZone)
exports('getZoneMaxPlayers', getZoneMaxPlayers)
exports('getAllZonePlayers', function()
    return PlayersInZones
end)