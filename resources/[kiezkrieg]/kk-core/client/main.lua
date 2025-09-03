-- KiezKrieg Core Client
ESX = exports['es_extended']:getSharedObject()

-- Client-side variables
local PlayerData = nil
local Zones = {}
local CurrentZone = nil
local CurrentMode = 'lobby'
local IsMenuOpen = false
local IsInGameMode = false

-- Initialize client
Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    -- Request player data from server
    TriggerServerEvent('kk-core:requestPlayerData')
    
    -- Register key mapping for main menu
    RegisterKeyMapping('kk_menu', 'Open KiezKrieg Menu', 'keyboard', 'F2')
    RegisterCommand('kk_menu', function()
        print('[KiezKrieg] F2 pressed - attempting to open main menu')
        if not IsMenuOpen then
            OpenMainMenu()
        else
            print('[KiezKrieg] Menu already open, closing instead')
            CloseMainMenu()
        end
    end, false)
    
    print('[KiezKrieg] Client initialized')
end)

-- Event handlers
RegisterNetEvent('kk-core:playerDataLoaded')
AddEventHandler('kk-core:playerDataLoaded', function(playerData)
    PlayerData = playerData
    print('[KiezKrieg] Player data loaded for: ' .. playerData.playerName)
end)

RegisterNetEvent('kk-core:receivePlayerData')
AddEventHandler('kk-core:receivePlayerData', function(playerData)
    PlayerData = playerData
end)

RegisterNetEvent('kk-core:zonesLoaded')
AddEventHandler('kk-core:zonesLoaded', function(zones)
    Zones = zones
    CreateZoneBlips()
    StartZoneCheck()
    print('[KiezKrieg] ' .. GetTableSize(zones) .. ' zones loaded')
end)

RegisterNetEvent('kk-core:openMainMenu')
AddEventHandler('kk-core:openMainMenu', function()
    OpenMainMenu()
end)

RegisterNetEvent('kk-core:statsUpdated')
AddEventHandler('kk-core:statsUpdated', function(stats)
    if PlayerData then
        PlayerData.stats = stats
    end
end)

-- Main menu functions
function OpenMainMenu()
    if IsMenuOpen then 
        print('[KiezKrieg] Menu already open, ignoring F2 press')
        return 
    end
    
    -- Debug: Check if required data is available
    if not PlayerData then
        print('[KiezKrieg] ERROR: PlayerData not loaded, requesting from server...')
        TriggerServerEvent('kk-core:requestPlayerData')
        ShowNotification('Loading player data, please try again in a moment...', 'info')
        return
    end
    
    if not Zones or next(Zones) == nil then
        print('[KiezKrieg] WARNING: No zones loaded, menu may not function properly')
        ShowNotification('Loading zones, menu may be limited...', 'warning')
    end
    
    if not Config then
        print('[KiezKrieg] ERROR: Config not available')
        ShowNotification('Configuration error, please try again', 'error')
        return
    end
    
    print('[KiezKrieg] Opening main menu - PlayerData: ' .. (PlayerData and 'OK' or 'MISSING') .. ', Zones: ' .. GetTableSize(Zones))
    
    IsMenuOpen = true
    SetNuiFocus(true, true)
    
    -- Send player data to UI
    SendNUIMessage({
        type = 'openMenu',
        playerData = PlayerData,
        zones = Zones,
        config = {
            gameModes = Config.GameModes,
            ui = Config.UI
        }
    })
    
    print('[KiezKrieg] Main menu NUI message sent')
end

function CloseMainMenu()
    if not IsMenuOpen then return end
    
    IsMenuOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        type = 'closeMenu'
    })
end

-- Zone management
function CreateZoneBlips()
    for zoneId, zone in pairs(Zones) do
        if zone.type == 'ffa' then
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, Config.Zones.blipSettings.sprite)
            SetBlipScale(blip, Config.Zones.blipSettings.scale)
            SetBlipColour(blip, GetBlipColorFromHex(zone.color))
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(zone.name)
            EndTextCommandSetBlipName(blip)
            
            zone.blip = blip
        end
    end
end

function StartZoneCheck()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000) -- Check every second
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local foundZone = nil
            
            for zoneId, zone in pairs(Zones) do
                if KK.IsPlayerInZone(playerCoords, zone.coords, zone.radius) then
                    foundZone = zoneId
                    break
                end
            end
            
            if foundZone ~= CurrentZone then
                if CurrentZone then
                    OnExitZone(CurrentZone)
                end
                
                if foundZone then
                    OnEnterZone(foundZone)
                end
                
                CurrentZone = foundZone
            end
        end
    end)
end

function OnEnterZone(zoneId)
    local zone = Zones[zoneId]
    if not zone then return end
    
    -- Show zone info
    ShowNotification('Entered ' .. zone.name, 'info')
    
    -- Draw zone marker
    StartZoneMarker(zone)
end

function OnExitZone(zoneId)
    local zone = Zones[zoneId]
    if not zone then return end
    
    ShowNotification('Left ' .. zone.name, 'info')
    StopZoneMarker()
end

function StartZoneMarker(zone)
    Citizen.CreateThread(function()
        local rgb = KK.HexToRGB(zone.color)
        
        while CurrentZone == zone.id do
            Citizen.Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = KK.GetDistance(playerCoords, zone.coords)
            
            if distance <= zone.radius + 50.0 then -- Draw marker when close
                DrawMarker(
                    1, -- Cylinder marker
                    zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    zone.radius * 2.0, zone.radius * 2.0, 3.0,
                    rgb.r, rgb.g, rgb.b, 100,
                    false, true, 2, false, nil, nil, false
                )
            end
        end
    end)
end

function StopZoneMarker()
    -- Marker stops automatically when CurrentZone changes
end

-- Game mode functions
function JoinFFA(zoneId, weaponMode)
    if not Zones[zoneId] then
        ShowNotification('Zone not found', 'error')
        return
    end
    
    TriggerServerEvent('kk-ffa:joinZone', zoneId, weaponMode)
    CloseMainMenu()
end

function JoinCustomLobby(lobbyId)
    TriggerServerEvent('kk-custom:joinLobby', lobbyId)
    CloseMainMenu()
end

function JoinHelifight()
    TriggerServerEvent('kk-helifight:joinQueue')
    CloseMainMenu()
end

function JoinGangwar()
    TriggerServerEvent('kk-gangwar:openMenu')
    CloseMainMenu()
end

-- UI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    CloseMainMenu()
    cb('ok')
end)

RegisterNUICallback('joinFFA', function(data, cb)
    JoinFFA(data.zoneId, data.weaponMode)
    cb('ok')
end)

RegisterNUICallback('joinCustomLobby', function(data, cb)
    JoinCustomLobby(data.lobbyId)
    cb('ok')
end)

RegisterNUICallback('joinHelifight', function(data, cb)
    JoinHelifight()
    cb('ok')
end)

RegisterNUICallback('joinGangwar', function(data, cb)
    JoinGangwar()
    cb('ok')
end)

RegisterNUICallback('createCustomLobby', function(data, cb)
    TriggerServerEvent('kk-custom:createLobby', data)
    cb('ok')
end)

RegisterNUICallback('updatePreferences', function(data, cb)
    if PlayerData then
        PlayerData.preferences = data
        TriggerServerEvent('kk-core:savePlayerPreferences', data)
    end
    cb('ok')
end)

-- Utility functions
function ShowNotification(message, type)
    if not PlayerData or not PlayerData.preferences.notificationsEnabled then return end
    
    SendNUIMessage({
        type = 'showNotification',
        message = message,
        notificationType = type or 'info'
    })
end

function GetBlipColorFromHex(hex)
    -- Convert hex colors to GTA blip colors (simplified)
    local colorMap = {
        ['#e74c3c'] = 1, -- Red
        ['#3498db'] = 3, -- Blue
        ['#f39c12'] = 5, -- Yellow
        ['#9b59b6'] = 7, -- Purple
        ['#27ae60'] = 2, -- Green
        ['#ff6b6b'] = 1  -- Red variant
    }
    
    return colorMap[hex] or 3 -- Default to blue
end

function GetTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Weapon and equipment management
function GiveWeaponsForMode(mode, weaponType)
    local playerPed = PlayerPedId()
    
    -- Remove all weapons first
    RemoveAllPedWeapons(playerPed, true)
    
    if mode == 'ffa' then
        local weapons = Config.GameModes.ffa.weapons[weaponType]
        if weapons then
            for _, weapon in ipairs(weapons) do
                GiveWeaponToPed(playerPed, GetHashKey(weapon), Config.GameModes.ffa.defaultAmmo, false, true)
            end
        end
    elseif mode == 'helifight' then
        -- Weapons given based on helicopter role
    end
    
    -- Give armor and health
    SetPedArmour(playerPed, 100)
    SetEntityHealth(playerPed, 200)
end

-- Export functions for other resources
exports('GetPlayerData', function()
    return PlayerData
end)

exports('GetCurrentZone', function()
    return CurrentZone
end)

exports('IsInGameMode', function()
    return IsInGameMode
end)

exports('OpenMainMenu', OpenMainMenu)
exports('CloseMainMenu', CloseMainMenu)
exports('ShowNotification', ShowNotification)