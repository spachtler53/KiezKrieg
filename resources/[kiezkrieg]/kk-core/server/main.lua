ESX = exports['es_extended']:getSharedObject()

-- Variables
local ffaLobbies = {}
local customLobbies = {}
local helifightLobbies = {}
local playerGameModes = {}
local routingBuckets = {
    nextFFA = 1000,
    nextCustom = 2000,
    nextHelifight = 3000,
    nextGangwar = 4000
}

-- Initialize database
Citizen.CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_player_stats (
            identifier VARCHAR(50) PRIMARY KEY,
            ffa_headshot_kills INT DEFAULT 0,
            ffa_headshot_deaths INT DEFAULT 0,
            ffa_headshot_assists INT DEFAULT 0,
            ffa_bodyshot_kills INT DEFAULT 0,
            ffa_bodyshot_deaths INT DEFAULT 0,
            ffa_bodyshot_assists INT DEFAULT 0,
            custom_lobby_kills INT DEFAULT 0,
            custom_lobby_deaths INT DEFAULT 0,
            custom_lobby_assists INT DEFAULT 0,
            helifight_kills INT DEFAULT 0,
            helifight_deaths INT DEFAULT 0,
            helifight_assists INT DEFAULT 0,
            gangwar_kills INT DEFAULT 0,
            gangwar_deaths INT DEFAULT 0,
            gangwar_assists INT DEFAULT 0
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_factions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            leader VARCHAR(50) NOT NULL,
            members JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS kk_custom_lobbies (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            creator VARCHAR(50) NOT NULL,
            password VARCHAR(50),
            max_players INT DEFAULT 20,
            map_name VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    print('[KiezKrieg] Database tables initialized')
end)

-- Player Stats
RegisterServerEvent('kk-core:requestPlayerStats')
AddEventHandler('kk-core:requestPlayerStats', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    MySQL.query('SELECT * FROM kk_player_stats WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        local stats = {
            ffa_headshot = { kills = 0, deaths = 0, assists = 0 },
            ffa_bodyshot = { kills = 0, deaths = 0, assists = 0 },
            custom_lobby = { kills = 0, deaths = 0, assists = 0 },
            helifight = { kills = 0, deaths = 0, assists = 0 },
            gangwar = { kills = 0, deaths = 0, assists = 0 }
        }
        
        if result[1] then
            local data = result[1]
            stats.ffa_headshot = { kills = data.ffa_headshot_kills, deaths = data.ffa_headshot_deaths, assists = data.ffa_headshot_assists }
            stats.ffa_bodyshot = { kills = data.ffa_bodyshot_kills, deaths = data.ffa_bodyshot_deaths, assists = data.ffa_bodyshot_assists }
            stats.custom_lobby = { kills = data.custom_lobby_kills, deaths = data.custom_lobby_deaths, assists = data.custom_lobby_assists }
            stats.helifight = { kills = data.helifight_kills, deaths = data.helifight_deaths, assists = data.helifight_assists }
            stats.gangwar = { kills = data.gangwar_kills, deaths = data.gangwar_deaths, assists = data.gangwar_assists }
        else
            -- Create new stats entry
            MySQL.insert('INSERT INTO kk_player_stats (identifier) VALUES (?)', {
                xPlayer.identifier
            })
        end
        
        TriggerClientEvent('kk-core:playerStatsReceived', source, stats)
    end)
end)

-- FFA System
RegisterServerEvent('kk-core:joinFFA')
AddEventHandler('kk-core:joinFFA', function(mode, zoneId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local zone = Config.FFAZones[zoneId]
    if not zone then return end
    
    -- Check if zone has space
    if not ffaLobbies[zoneId] then
        ffaLobbies[zoneId] = {
            players = {},
            mode = mode,
            routingBucket = routingBuckets.nextFFA
        }
        routingBuckets.nextFFA = routingBuckets.nextFFA + 1
    end
    
    if #ffaLobbies[zoneId].players >= Config.GameModes.FFA.maxPlayers then
        TriggerClientEvent('esx:showNotification', source, 'Zone is full!')
        return
    end
    
    -- Add player to lobby
    table.insert(ffaLobbies[zoneId].players, source)
    playerGameModes[source] = 'ffa_' .. mode
    
    -- Set player routing bucket
    SetPlayerRoutingBucket(source, ffaLobbies[zoneId].routingBucket)
    
    TriggerClientEvent('kk-core:joinedFFA', source, mode, zone, ffaLobbies[zoneId].routingBucket)
end)

-- Leave Game
RegisterServerEvent('kk-core:leaveGame')
AddEventHandler('kk-core:leaveGame', function()
    local source = source
    playerGameModes[source] = nil
    
    -- Remove from all lobbies
    for zoneId, lobby in pairs(ffaLobbies) do
        for i, playerId in ipairs(lobby.players) do
            if playerId == source then
                table.remove(lobby.players, i)
                break
            end
        end
        
        -- Clean up empty lobbies
        if #lobby.players == 0 then
            ffaLobbies[zoneId] = nil
        end
    end
    
    -- Reset routing bucket
    SetPlayerRoutingBucket(source, 0)
    
    TriggerClientEvent('kk-core:leftGame', source)
end)

-- Player Death
RegisterServerEvent('kk-core:playerDied')
AddEventHandler('kk-core:playerDied', function(gameMode, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Update death stats
    local deathColumn = gameMode:gsub('_', '_') .. '_deaths'
    MySQL.update('UPDATE kk_player_stats SET ' .. deathColumn .. ' = ' .. deathColumn .. ' + 1 WHERE identifier = ?', {
        xPlayer.identifier
    })
    
    -- Request updated stats
    TriggerEvent('kk-core:requestPlayerStats')
end)

-- Player Kill
RegisterServerEvent('kk-core:playerKilled')
AddEventHandler('kk-core:playerKilled', function(gameMode, victimId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Update kill stats
    local killColumn = gameMode:gsub('_', '_') .. '_kills'
    MySQL.update('UPDATE kk_player_stats SET ' .. killColumn .. ' = ' .. killColumn .. ' + 1 WHERE identifier = ?', {
        xPlayer.identifier
    })
    
    -- Request updated stats
    TriggerEvent('kk-core:requestPlayerStats')
end)

-- Custom Lobbies
RegisterServerEvent('kk-core:createCustomLobby')
AddEventHandler('kk-core:createCustomLobby', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local lobbyId = #customLobbies + 1
    customLobbies[lobbyId] = {
        id = lobbyId,
        name = data.name,
        creator = source,
        password = data.password,
        maxPlayers = data.maxPlayers or 20,
        players = { source },
        teams = { {}, {} },
        routingBucket = routingBuckets.nextCustom
    }
    
    routingBuckets.nextCustom = routingBuckets.nextCustom + 1
    playerGameModes[source] = 'custom_lobby'
    
    SetPlayerRoutingBucket(source, customLobbies[lobbyId].routingBucket)
    TriggerClientEvent('esx:showNotification', source, 'Custom lobby created!')
end)

-- Helifight
RegisterServerEvent('kk-core:joinHelifight')
AddEventHandler('kk-core:joinHelifight', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Create or join helifight lobby
    local lobbyId = #helifightLobbies + 1
    helifightLobbies[lobbyId] = {
        id = lobbyId,
        players = { source },
        maxRounds = data.rounds or 5,
        currentRound = 0,
        routingBucket = routingBuckets.nextHelifight
    }
    
    routingBuckets.nextHelifight = routingBuckets.nextHelifight + 1
    playerGameModes[source] = 'helifight'
    
    SetPlayerRoutingBucket(source, helifightLobbies[lobbyId].routingBucket)
    TriggerClientEvent('esx:showNotification', source, 'Joined Helifight!')
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local source = source
    playerGameModes[source] = nil
    
    -- Remove from all lobbies
    for zoneId, lobby in pairs(ffaLobbies) do
        for i, playerId in ipairs(lobby.players) do
            if playerId == source then
                table.remove(lobby.players, i)
                break
            end
        end
    end
    
    for lobbyId, lobby in pairs(customLobbies) do
        for i, playerId in ipairs(lobby.players) do
            if playerId == source then
                table.remove(lobby.players, i)
                break
            end
        end
    end
    
    for lobbyId, lobby in pairs(helifightLobbies) do
        for i, playerId in ipairs(lobby.players) do
            if playerId == source then
                table.remove(lobby.players, i)
                break
            end
        end
    end
end)

-- Export functions
exports('GetPlayerGameMode', function(playerId)
    return playerGameModes[playerId]
end)

exports('GetFFALobbies', function()
    return ffaLobbies
end)

exports('GetCustomLobbies', function()
    return customLobbies
end)