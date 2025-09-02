-- KiezKrieg Server-side Core
local ESX = exports["es_extended"]:getSharedObject()

-- Player data storage
local Players = {}
local ActiveLobbies = {}
local RoutingBuckets = {
    ffa = {},
    lobbies = {},
    helifight = {}
}

-- Initialize player data
RegisterNetEvent('kk-core:playerReady')
AddEventHandler('kk-core:playerReady', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        Players[src] = {
            identifier = xPlayer.identifier,
            name = xPlayer.name,
            currentGameMode = nil,
            routingBucket = 0,
            stats = {}
        }
        
        -- Load player from database
        loadPlayerFromDatabase(src, xPlayer.identifier)
    end
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local src = source
    if Players[src] then
        -- Clean up any active game modes
        if Players[src].currentGameMode then
            leaveGameMode(src)
        end
        Players[src] = nil
    end
end)

-- Load player stats
RegisterNetEvent('kk-core:loadPlayerStats')
AddEventHandler('kk-core:loadPlayerStats', function()
    local src = source
    if Players[src] then
        loadPlayerStats(src)
    end
end)

-- Get player stats
RegisterNetEvent('kk-core:getPlayerStats')
AddEventHandler('kk-core:getPlayerStats', function()
    local src = source
    if Players[src] and Players[src].stats then
        TriggerClientEvent('kk-core:receivePlayerStats', src, Players[src].stats)
    end
end)

-- FFA Join handler
RegisterNetEvent('kk-core:joinFFA')
AddEventHandler('kk-core:joinFFA', function(mode, zoneId)
    local src = source
    if not Players[src] then return end
    
    local zone = nil
    for _, z in pairs(KiezKrieg.Config.Zones.FFA) do
        if z.id == zoneId then
            zone = z
            break
        end
    end
    
    if not zone then
        TriggerClientEvent('esx:showNotification', src, '~r~Invalid zone!')
        return
    end
    
    -- Check if zone is full
    local playersInZone = getPlayersInZone(zoneId)
    if #playersInZone >= zone.maxPlayers then
        TriggerClientEvent('esx:showNotification', src, '~r~Zone is full!')
        return
    end
    
    -- Assign routing bucket
    local bucket = getAvailableBucket('ffa')
    SetPlayerRoutingBucket(src, bucket)
    
    -- Set player game mode
    local gameMode = mode == 'headshot' and KiezKrieg.GAME_MODES.FFA_HEADSHOT or KiezKrieg.GAME_MODES.FFA_BODYSHOT
    Players[src].currentGameMode = gameMode
    Players[src].routingBucket = bucket
    Players[src].zoneId = zoneId
    
    -- Add to routing bucket tracking
    if not RoutingBuckets.ffa[bucket] then
        RoutingBuckets.ffa[bucket] = {}
    end
    RoutingBuckets.ffa[bucket][src] = {zoneId = zoneId, mode = mode}
    
    -- Trigger client setup
    TriggerClientEvent('kk-core:setGameMode', src, gameMode, {
        zone = zone,
        mode = mode,
        bucket = bucket
    })
    
    TriggerClientEvent('esx:showNotification', src, '~g~Joined ' .. mode .. ' FFA in ' .. zone.name)
end)

-- Create Lobby handler
RegisterNetEvent('kk-core:createLobby')
AddEventHandler('kk-core:createLobby', function(data)
    local src = source
    if not Players[src] then return end
    
    local lobbyId = generateLobbyId()
    local bucket = getAvailableBucket('lobbies')
    
    ActiveLobbies[lobbyId] = {
        id = lobbyId,
        name = data.name,
        password = data.password,
        isPrivate = data.isPrivate,
        maxPlayers = data.maxPlayers or 20,
        creator = src,
        players = {src},
        bucket = bucket,
        map = data.map or 'default'
    }
    
    SetPlayerRoutingBucket(src, bucket)
    Players[src].currentGameMode = KiezKrieg.GAME_MODES.CUSTOM_LOBBY
    Players[src].routingBucket = bucket
    
    RoutingBuckets.lobbies[bucket] = lobbyId
    
    TriggerClientEvent('kk-core:setGameMode', src, KiezKrieg.GAME_MODES.CUSTOM_LOBBY, {
        lobby = ActiveLobbies[lobbyId]
    })
    
    TriggerClientEvent('esx:showNotification', src, '~g~Created lobby: ' .. data.name)
end)

-- Join Lobby handler
RegisterNetEvent('kk-core:joinLobby')
AddEventHandler('kk-core:joinLobby', function(lobbyId, password)
    local src = source
    if not Players[src] then return end
    
    local lobby = ActiveLobbies[lobbyId]
    if not lobby then
        TriggerClientEvent('esx:showNotification', src, '~r~Lobby not found!')
        return
    end
    
    if lobby.isPrivate and lobby.password ~= password then
        TriggerClientEvent('esx:showNotification', src, '~r~Invalid password!')
        return
    end
    
    if #lobby.players >= lobby.maxPlayers then
        TriggerClientEvent('esx:showNotification', src, '~r~Lobby is full!')
        return
    end
    
    table.insert(lobby.players, src)
    SetPlayerRoutingBucket(src, lobby.bucket)
    Players[src].currentGameMode = KiezKrieg.GAME_MODES.CUSTOM_LOBBY
    Players[src].routingBucket = lobby.bucket
    
    TriggerClientEvent('kk-core:setGameMode', src, KiezKrieg.GAME_MODES.CUSTOM_LOBBY, {
        lobby = lobby
    })
    
    TriggerClientEvent('esx:showNotification', src, '~g~Joined lobby: ' .. lobby.name)
end)

-- Helifight handler
RegisterNetEvent('kk-core:joinHelifight')
AddEventHandler('kk-core:joinHelifight', function()
    local src = source
    if not Players[src] then return end
    
    local bucket = getAvailableBucket('helifight')
    SetPlayerRoutingBucket(src, bucket)
    
    Players[src].currentGameMode = KiezKrieg.GAME_MODES.HELIFIGHT
    Players[src].routingBucket = bucket
    
    if not RoutingBuckets.helifight[bucket] then
        RoutingBuckets.helifight[bucket] = {}
    end
    RoutingBuckets.helifight[bucket][src] = true
    
    TriggerClientEvent('kk-core:setGameMode', src, KiezKrieg.GAME_MODES.HELIFIGHT, {
        bucket = bucket
    })
    
    TriggerClientEvent('esx:showNotification', src, '~g~Joined Helifight!')
end)

-- Helper functions
function leaveGameMode(src)
    if not Players[src] or not Players[src].currentGameMode then return end
    
    local bucket = Players[src].routingBucket
    local gameMode = Players[src].currentGameMode
    
    -- Clean up routing bucket data
    if gameMode == KiezKrieg.GAME_MODES.FFA_HEADSHOT or gameMode == KiezKrieg.GAME_MODES.FFA_BODYSHOT then
        if RoutingBuckets.ffa[bucket] then
            RoutingBuckets.ffa[bucket][src] = nil
        end
    elseif gameMode == KiezKrieg.GAME_MODES.CUSTOM_LOBBY then
        local lobbyId = RoutingBuckets.lobbies[bucket]
        if lobbyId and ActiveLobbies[lobbyId] then
            for i, playerId in ipairs(ActiveLobbies[lobbyId].players) do
                if playerId == src then
                    table.remove(ActiveLobbies[lobbyId].players, i)
                    break
                end
            end
            
            -- Remove lobby if empty
            if #ActiveLobbies[lobbyId].players == 0 then
                ActiveLobbies[lobbyId] = nil
                RoutingBuckets.lobbies[bucket] = nil
            end
        end
    elseif gameMode == KiezKrieg.GAME_MODES.HELIFIGHT then
        if RoutingBuckets.helifight[bucket] then
            RoutingBuckets.helifight[bucket][src] = nil
        end
    end
    
    -- Reset player data
    SetPlayerRoutingBucket(src, 0)
    Players[src].currentGameMode = nil
    Players[src].routingBucket = 0
    Players[src].zoneId = nil
    
    TriggerClientEvent('kk-core:leaveGameMode', src)
end

function getAvailableBucket(type)
    local bucket = 1
    local maxBucket = 1000
    
    if type == 'ffa' then
        while bucket <= maxBucket do
            if not RoutingBuckets.ffa[bucket] or tableLength(RoutingBuckets.ffa[bucket]) == 0 then
                return bucket
            end
            bucket = bucket + 1
        end
    elseif type == 'lobbies' then
        while bucket <= maxBucket do
            if not RoutingBuckets.lobbies[bucket] then
                return bucket
            end
            bucket = bucket + 1
        end
    elseif type == 'helifight' then
        while bucket <= maxBucket do
            if not RoutingBuckets.helifight[bucket] or tableLength(RoutingBuckets.helifight[bucket]) == 0 then
                return bucket
            end
            bucket = bucket + 1
        end
    end
    
    return bucket
end

function getPlayersInZone(zoneId)
    local players = {}
    for src, player in pairs(Players) do
        if player.zoneId == zoneId then
            table.insert(players, src)
        end
    end
    return players
end

function generateLobbyId()
    return math.random(100000, 999999)
end

function tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function loadPlayerFromDatabase(src, identifier)
    -- Initialize default stats
    Players[src].stats = {
        headshot = {kills = 0, deaths = 0, kda = 0.0},
        bodyshot = {kills = 0, deaths = 0, kda = 0.0},
        helifight = {kills = 0, deaths = 0, kda = 0.0}
    }
    
    -- This would typically load from database
    -- For now, we'll use defaults
end

function loadPlayerStats(src)
    if Players[src] then
        -- This would load updated stats from database
        -- For now, we'll use existing stats
        TriggerClientEvent('kk-core:receivePlayerStats', src, Players[src].stats)
    end
end

-- Command to leave current game mode
ESX.RegisterCommand('leave', 'user', function(xPlayer, args, showError)
    local src = xPlayer.source
    if Players[src] and Players[src].currentGameMode then
        leaveGameMode(src)
        TriggerClientEvent('esx:showNotification', src, '~g~Left current game mode')
    else
        TriggerClientEvent('esx:showNotification', src, '~r~You are not in any game mode')
    end
end, false, {help = 'Leave current game mode'})

-- Export functions
exports('getPlayerGameMode', function(src)
    return Players[src] and Players[src].currentGameMode or nil
end)

exports('isPlayerInGameMode', function(src)
    return Players[src] and Players[src].currentGameMode ~= nil
end)