-- KiezKrieg Client-side Core
local ESX = exports["es_extended"]:getSharedObject()
local PlayerData = {}
local isMenuOpen = false
local currentGameMode = nil
local inZone = false

-- Initialize ESX
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    
    -- Trigger automatic character loading completion
    TriggerEvent('kk-core:characterLoaded')
    
    -- Wait a moment then open main menu automatically
    Wait(2000)
    openMainMenu()
end)

-- Character loaded event
RegisterNetEvent('kk-core:characterLoaded')
AddEventHandler('kk-core:characterLoaded', function()
    TriggerServerEvent('kk-core:playerReady')
    
    -- Load player statistics
    TriggerServerEvent('kk-core:loadPlayerStats')
end)

-- Main menu key binding
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, KiezKrieg.Config.UI.MENU_KEY) and not isMenuOpen then
            openMainMenu()
        end
    end
end)

-- Open main menu function
function openMainMenu()
    if not PlayerData or not PlayerData.identifier then
        ESX.ShowNotification('~r~Character not loaded yet!')
        return
    end
    
    isMenuOpen = true
    SetNuiFocus(true, true)
    
    -- Request player stats from server
    TriggerServerEvent('kk-core:getPlayerStats')
end

-- Close menu function
function closeMainMenu()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeMenu'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    closeMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinFFA', function(data, cb)
    local mode = data.mode -- 'headshot' or 'bodyshot'
    local zoneId = data.zoneId
    
    TriggerServerEvent('kk-core:joinFFA', mode, zoneId)
    closeMainMenu()
    cb('ok')
end)

RegisterNUICallback('createLobby', function(data, cb)
    TriggerServerEvent('kk-core:createLobby', data)
    closeMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinLobby', function(data, cb)
    TriggerServerEvent('kk-core:joinLobby', data.lobbyId, data.password)
    closeMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinHelifight', function(data, cb)
    TriggerServerEvent('kk-core:joinHelifight')
    closeMainMenu()
    cb('ok')
end)

RegisterNUICallback('openFactionMenu', function(data, cb)
    TriggerEvent('kk-factions:openMenu')
    closeMainMenu()
    cb('ok')
end)

-- Receive player stats from server
RegisterNetEvent('kk-core:receivePlayerStats')
AddEventHandler('kk-core:receivePlayerStats', function(stats)
    SendNUIMessage({
        type = 'openMenu',
        stats = stats,
        zones = KiezKrieg.Config.Zones.FFA
    })
end)

-- Game mode events
RegisterNetEvent('kk-core:setGameMode')
AddEventHandler('kk-core:setGameMode', function(gameMode, data)
    currentGameMode = gameMode
    
    if gameMode == KiezKrieg.GAME_MODES.FFA_HEADSHOT or gameMode == KiezKrieg.GAME_MODES.FFA_BODYSHOT then
        TriggerEvent('kk-zones:enterFFA', data)
    elseif gameMode == KiezKrieg.GAME_MODES.CUSTOM_LOBBY then
        TriggerEvent('kk-zones:enterLobby', data)
    elseif gameMode == KiezKrieg.GAME_MODES.HELIFIGHT then
        TriggerEvent('kk-zones:enterHelifight', data)
    end
end)

-- Leave game mode
RegisterNetEvent('kk-core:leaveGameMode')
AddEventHandler('kk-core:leaveGameMode', function()
    if currentGameMode then
        if currentGameMode == KiezKrieg.GAME_MODES.FFA_HEADSHOT or currentGameMode == KiezKrieg.GAME_MODES.FFA_BODYSHOT then
            TriggerEvent('kk-zones:leaveFFA')
        elseif currentGameMode == KiezKrieg.GAME_MODES.CUSTOM_LOBBY then
            TriggerEvent('kk-zones:leaveLobby')
        elseif currentGameMode == KiezKrieg.GAME_MODES.HELIFIGHT then
            TriggerEvent('kk-zones:leaveHelifight')
        end
        
        currentGameMode = nil
        
        -- Return to normal world
        SetEntityRoutingBucket(PlayerPedId(), 0)
    end
end)

-- Zone enter/exit detection
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if not currentGameMode then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local wasInZone = inZone
            inZone = false
            
            for _, zone in pairs(KiezKrieg.Config.Zones.FFA) do
                local distance = #(playerCoords - zone.coords)
                if distance <= zone.radius then
                    inZone = true
                    if not wasInZone then
                        ESX.ShowNotification('~b~Entering FFA Zone: ' .. zone.name)
                        ESX.ShowNotification('~y~Press F2 to join the fight!')
                    end
                    break
                end
            end
            
            if wasInZone and not inZone then
                ESX.ShowNotification('~g~Left FFA Zone')
            end
        end
    end
end)

-- Export functions
exports('isInGameMode', function()
    return currentGameMode ~= nil
end)

exports('getCurrentGameMode', function()
    return currentGameMode
end)

exports('openMainMenu', openMainMenu)
exports('closeMainMenu', closeMainMenu)