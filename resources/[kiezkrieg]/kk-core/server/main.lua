-- KiezKrieg Core Server
ESX = exports['es_extended']:getSharedObject()

-- Initialize server-side variables
local Players = {}
local Zones = {}
local Lobbies = {}
local AdminPlayers = {}

-- Events
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName()
    
    -- Load player data from database
    LoadPlayerData(playerId, identifier, playerName)
    
    -- Auto-open menu if enabled
    if Config.AutoOpenMenuAfterSpawn then
        Citizen.SetTimeout(5000, function() -- Wait 5 seconds for character to fully load
            TriggerClientEvent('kk-core:openMainMenu', playerId)
        end)
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local identifier = GetPlayerIdentifier(playerId, 0)
    if Players[identifier] then
        -- Save player data before removing
        SavePlayerData(identifier, Players[identifier])
        
        -- Remove from any lobbies or zones
        RemovePlayerFromAllActivities(identifier)
        
        -- Clean up
        Players[identifier] = nil
        AdminPlayers[playerId] = nil
    end
end)

-- Load player data from database
function LoadPlayerData(playerId, identifier, playerName)
    MySQL.Async.fetchAll('SELECT * FROM kk_player_stats WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        local playerData = KK.CreatePlayerData(identifier, playerName)
        
        if result[1] then
            local dbData = result[1]
            playerData.stats.headshot.kills = dbData.headshot_kills
            playerData.stats.headshot.deaths = dbData.headshot_deaths
            playerData.stats.bodyshot.kills = dbData.bodyshot_kills
            playerData.stats.bodyshot.deaths = dbData.bodyshot_deaths
            playerData.stats.ffa.kills = dbData.ffa_kills
            playerData.stats.ffa.deaths = dbData.ffa_deaths
            playerData.stats.custom.kills = dbData.custom_kills
            playerData.stats.custom.deaths = dbData.custom_deaths
            playerData.stats.helifight.kills = dbData.helifight_kills
            playerData.stats.helifight.deaths = dbData.helifight_deaths
            playerData.stats.gangwar.kills = dbData.gangwar_kills
            playerData.stats.gangwar.deaths = dbData.gangwar_deaths
            playerData.stats.totalPlaytime = dbData.total_playtime
        else
            -- Create new player record
            MySQL.Async.execute('INSERT INTO kk_player_stats (identifier, player_name) VALUES (@identifier, @player_name)', {
                ['@identifier'] = identifier,
                ['@player_name'] = playerName
            })
        end
        
        -- Load user preferences
        MySQL.Async.fetchAll('SELECT * FROM kk_user_preferences WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(prefResult)
            if prefResult[1] then
                local prefs = prefResult[1]
                playerData.preferences.autoOpenMenu = prefs.auto_open_menu == 1
                playerData.preferences.preferredWeaponMode = prefs.preferred_weapon_mode
                playerData.preferences.uiColorTheme = prefs.ui_color_theme
                playerData.preferences.soundEnabled = prefs.sound_enabled == 1
                playerData.preferences.notificationsEnabled = prefs.notifications_enabled == 1
            else
                -- Create default preferences
                MySQL.Async.execute('INSERT INTO kk_user_preferences (identifier) VALUES (@identifier)', {
                    ['@identifier'] = identifier
                })
            end
            
            Players[identifier] = playerData
            TriggerClientEvent('kk-core:playerDataLoaded', playerId, playerData)
        end)
    end)
end

-- Save player data to database
function SavePlayerData(identifier, playerData)
    if not Players[identifier] then return end
    
    local stats = playerData.stats
    MySQL.Async.execute('UPDATE kk_player_stats SET headshot_kills = @hk, headshot_deaths = @hd, bodyshot_kills = @bk, bodyshot_deaths = @bd, ffa_kills = @fk, ffa_deaths = @fd, custom_kills = @ck, custom_deaths = @cd, helifight_kills = @hlk, helifight_deaths = @hld, gangwar_kills = @gk, gangwar_deaths = @gd, total_playtime = @tp WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@hk'] = stats.headshot.kills,
        ['@hd'] = stats.headshot.deaths,
        ['@bk'] = stats.bodyshot.kills,
        ['@bd'] = stats.bodyshot.deaths,
        ['@fk'] = stats.ffa.kills,
        ['@fd'] = stats.ffa.deaths,
        ['@ck'] = stats.custom.kills,
        ['@cd'] = stats.custom.deaths,
        ['@hlk'] = stats.helifight.kills,
        ['@hld'] = stats.helifight.deaths,
        ['@gk'] = stats.gangwar.kills,
        ['@gd'] = stats.gangwar.deaths,
        ['@tp'] = stats.totalPlaytime
    })
    
    local prefs = playerData.preferences
    MySQL.Async.execute('UPDATE kk_user_preferences SET auto_open_menu = @aom, preferred_weapon_mode = @pwm, ui_color_theme = @uct, sound_enabled = @se, notifications_enabled = @ne WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@aom'] = prefs.autoOpenMenu and 1 or 0,
        ['@pwm'] = prefs.preferredWeaponMode,
        ['@uct'] = prefs.uiColorTheme,
        ['@se'] = prefs.soundEnabled and 1 or 0,
        ['@ne'] = prefs.notificationsEnabled and 1 or 0
    })
end

-- Load zones from database
function LoadZones()
    MySQL.Async.fetchAll('SELECT * FROM kk_zones WHERE is_active = 1', {}, function(result)
        for _, zone in pairs(result) do
            local coords = vector3(zone.x, zone.y, zone.z)
            local zoneData = KK.CreateZoneData(zone.id, zone.name, zone.type, coords, zone.radius, zone.color, zone.max_players)
            Zones[zone.id] = zoneData
        end
        
        -- Notify all clients about zones
        TriggerClientEvent('kk-core:zonesLoaded', -1, Zones)
        print('[KiezKrieg] Loaded ' .. #result .. ' zones')
    end)
end

-- Remove player from all activities
function RemovePlayerFromAllActivities(identifier)
    local playerData = Players[identifier]
    if not playerData then return end
    
    -- Remove from current zone
    if playerData.currentZone then
        local zone = Zones[playerData.currentZone]
        if zone then
            for i, playerId in ipairs(zone.currentPlayers) do
                if playerId == identifier then
                    table.remove(zone.currentPlayers, i)
                    break
                end
            end
        end
    end
    
    -- Remove from current lobby
    if playerData.currentLobby then
        local lobby = Lobbies[playerData.currentLobby]
        if lobby then
            for i, playerId in ipairs(lobby.currentPlayers) do
                if playerId == identifier then
                    table.remove(lobby.currentPlayers, i)
                    break
                end
            end
            
            -- Remove from team
            if playerData.team then
                for i, playerId in ipairs(lobby.teams[playerData.team]) do
                    if playerId == identifier then
                        table.remove(lobby.teams[playerData.team], i)
                        break
                    end
                end
            end
        end
    end
end

-- Server Events
RegisterServerEvent('kk-core:requestPlayerData')
AddEventHandler('kk-core:requestPlayerData', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if Players[identifier] then
        TriggerClientEvent('kk-core:receivePlayerData', source, Players[identifier])
    end
end)

RegisterServerEvent('kk-core:updatePlayerStats')
AddEventHandler('kk-core:updatePlayerStats', function(mode, type, amount)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if Players[identifier] and Players[identifier].stats[mode] and Players[identifier].stats[mode][type] then
        Players[identifier].stats[mode][type] = Players[identifier].stats[mode][type] + (amount or 1)
        
        -- Save to database every 5 kills/deaths for performance
        if Players[identifier].stats[mode][type] % 5 == 0 then
            SavePlayerData(identifier, Players[identifier])
        end
        
        TriggerClientEvent('kk-core:statsUpdated', source, Players[identifier].stats)
    end
end)

RegisterServerEvent('kk-core:savePlayerPreferences')
AddEventHandler('kk-core:savePlayerPreferences', function(preferences)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if Players[identifier] then
        Players[identifier].preferences = preferences
        SavePlayerData(identifier, Players[identifier])
    end
end)

-- Initialize server
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Wait for ESX to load
    LoadZones()
    print('[KiezKrieg] Core server initialized')
end)

-- Save all player data every 5 minutes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutes
        for identifier, playerData in pairs(Players) do
            SavePlayerData(identifier, playerData)
        end
        print('[KiezKrieg] Auto-saved all player data')
    end
end)

-- Export functions for other resources
exports('GetPlayerData', function(identifier)
    return Players[identifier]
end)

exports('GetZones', function()
    return Zones
end)

exports('GetLobbies', function()
    return Lobbies
end)