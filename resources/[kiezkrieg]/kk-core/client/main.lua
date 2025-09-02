ESX = exports['es_extended']:getSharedObject()

-- Variables
local currentGameMode = nil
local currentLobby = nil
local inGame = false
local playerStats = {
    ffa_headshot = { kills = 0, deaths = 0, assists = 0 },
    ffa_bodyshot = { kills = 0, deaths = 0, assists = 0 },
    custom_lobby = { kills = 0, deaths = 0, assists = 0 },
    helifight = { kills = 0, deaths = 0, assists = 0 },
    gangwar = { kills = 0, deaths = 0, assists = 0 }
}

-- Initialize
Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    -- Load player stats
    TriggerServerEvent('kk-core:requestPlayerStats')
    
    -- Register F2 key for main menu
    RegisterKeyMapping('kk_mainmenu', 'Open KiezKrieg Main Menu', 'keyboard', 'F2')
    RegisterCommand('kk_mainmenu', function()
        OpenMainMenu()
    end, false)
end)

-- ESX Events
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    -- Auto-open main menu after character selection
    Citizen.Wait(5000)
    OpenMainMenu()
end)

-- Main Menu Functions
function OpenMainMenu()
    if not inGame then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showMainMenu',
            stats = playerStats
        })
    end
end

function CloseMainMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideMainMenu'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinFFA', function(data, cb)
    local mode = data.mode -- 'headshot' or 'bodyshot'
    local zoneId = data.zoneId
    TriggerServerEvent('kk-core:joinFFA', mode, zoneId)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('createCustomLobby', function(data, cb)
    TriggerServerEvent('kk-core:createCustomLobby', data)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinCustomLobby', function(data, cb)
    TriggerServerEvent('kk-core:joinCustomLobby', data.lobbyId)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinHelifight', function(data, cb)
    TriggerServerEvent('kk-core:joinHelifight', data)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinGangwar', function(data, cb)
    TriggerServerEvent('kk-core:joinGangwar', data)
    CloseMainMenu()
    cb('ok')
end)

-- Server Events
RegisterNetEvent('kk-core:playerStatsReceived')
AddEventHandler('kk-core:playerStatsReceived', function(stats)
    playerStats = stats
end)

RegisterNetEvent('kk-core:joinedFFA')
AddEventHandler('kk-core:joinedFFA', function(mode, zoneData, routingBucket)
    currentGameMode = 'ffa_' .. mode
    inGame = true
    
    -- Set routing bucket for dimension separation
    SetPlayerRoutingBucket(PlayerId(), routingBucket)
    
    -- Teleport to spawn point
    local spawnPoint = zoneData.spawnPoints[math.random(1, #zoneData.spawnPoints)]
    SetEntityCoords(PlayerPedId(), spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), spawnPoint.w)
    
    -- Give weapons based on mode
    RemoveAllPedWeapons(PlayerPedId(), true)
    if mode == 'headshot' then
        GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GameModes.FFA.modes.headshot.weapon), Config.GameModes.FFA.modes.headshot.ammo, false, true)
    else
        GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GameModes.FFA.modes.bodyshot.primaryWeapon), Config.GameModes.FFA.modes.bodyshot.ammo, false, true)
        GiveWeaponToPed(PlayerPedId(), GetHashKey(Config.GameModes.FFA.modes.bodyshot.secondaryWeapon), Config.GameModes.FFA.modes.bodyshot.ammo, false, false)
    end
    
    -- Set health and armor
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    
    ESX.ShowNotification('Joined FFA ' .. mode .. ' mode!')
end)

RegisterNetEvent('kk-core:leftGame')
AddEventHandler('kk-core:leftGame', function()
    currentGameMode = nil
    inGame = false
    
    -- Return to main dimension
    SetPlayerRoutingBucket(PlayerId(), 0)
    
    -- Remove weapons
    RemoveAllPedWeapons(PlayerPedId(), true)
    
    -- Reset health
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 0)
    
    ESX.ShowNotification('Left game mode')
end)

RegisterNetEvent('kk-core:updateStats')
AddEventHandler('kk-core:updateStats', function(newStats)
    playerStats = newStats
end)

-- Death handling
RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    if inGame and currentGameMode then
        TriggerServerEvent('kk-core:playerDied', currentGameMode, data)
    end
end)

-- Kill handling
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local victimDied = args[4]
        
        if victimDied and victim == PlayerPedId() and attacker ~= PlayerPedId() and NetworkIsPlayerActive(NetworkGetPlayerIndexFromPed(attacker)) then
            local attackerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
            if inGame and currentGameMode then
                TriggerServerEvent('kk-core:playerKilled', currentGameMode, attackerServerId)
            end
        end
    end
end)

-- Command to leave current game
RegisterCommand('leavegame', function()
    if inGame then
        TriggerServerEvent('kk-core:leaveGame')
    end
end, false)

-- Export functions for other resources
exports('GetCurrentGameMode', function()
    return currentGameMode
end)

exports('IsInGame', function()
    return inGame
end)

exports('GetPlayerStats', function()
    return playerStats
end)

exports('GetConfig', function()
    return Config
end)