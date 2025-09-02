ESX = exports['es_extended']:getSharedObject()

-- Variables
local isOnDuty = false
local showNametags = false
local adminMenu = false

-- Initialize
Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    -- Register admin menu key (F3)
    RegisterKeyMapping('kk_adminmenu', 'Open Admin Menu', 'keyboard', 'F3')
    RegisterCommand('kk_adminmenu', function()
        if IsPlayerAdmin() then
            ToggleAdminMenu()
        end
    end, false)
end)

-- Check if player has admin permissions
function IsPlayerAdmin()
    local xPlayer = ESX.GetPlayerData()
    if xPlayer and xPlayer.group then
        for _, group in pairs(Config.AdminGroups) do
            if xPlayer.group == group then
                return true
            end
        end
    end
    return false
end

-- Admin Menu Functions
function ToggleAdminMenu()
    adminMenu = not adminMenu
    if adminMenu then
        OpenAdminMenu()
    else
        CloseAdminMenu()
    end
end

function OpenAdminMenu()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showAdminMenu',
        isOnDuty = isOnDuty,
        showNametags = showNametags
    })
end

function CloseAdminMenu()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'hideAdminMenu'
    })
end

-- NUI Callbacks
RegisterNUICallback('closeAdminMenu', function(data, cb)
    CloseAdminMenu()
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(data, cb)
    TriggerServerEvent('kk-admin:toggleDuty')
    cb('ok')
end)

RegisterNUICallback('gotoPlayer', function(data, cb)
    TriggerServerEvent('kk-admin:gotoPlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('bringPlayer', function(data, cb)
    TriggerServerEvent('kk-admin:bringPlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    SpawnAdminVehicle(data.model)
    cb('ok')
end)

RegisterNUICallback('deleteVehicles', function(data, cb)
    DeleteNearbyVehicles()
    cb('ok')
end)

RegisterNUICallback('toggleNametags', function(data, cb)
    ToggleNametags()
    cb('ok')
end)

RegisterNUICallback('teleportToMarker', function(data, cb)
    TeleportToWaypoint()
    cb('ok')
end)

-- Server Events
RegisterNetEvent('kk-admin:dutyToggled')
AddEventHandler('kk-admin:dutyToggled', function(onDuty)
    isOnDuty = onDuty
    if isOnDuty then
        ESX.ShowNotification('~g~Admin duty activated')
    else
        ESX.ShowNotification('~r~Admin duty deactivated')
    end
end)

RegisterNetEvent('kk-admin:teleportToPlayer')
AddEventHandler('kk-admin:teleportToPlayer', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    ESX.ShowNotification('Teleported to player')
end)

RegisterNetEvent('kk-admin:playerBrought')
AddEventHandler('kk-admin:playerBrought', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    ESX.ShowNotification('You have been brought by an admin')
end)

-- Admin Commands
-- Teleport to waypoint
function TeleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    if DoesBlipExist(waypoint) then
        local coords = GetBlipCoords(waypoint)
        local ground, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
        
        if ground then
            coords = vector3(coords.x, coords.y, z)
        else
            coords = vector3(coords.x, coords.y, coords.z)
        end
        
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
        ESX.ShowNotification('Teleported to waypoint')
    else
        ESX.ShowNotification('~r~No waypoint set')
    end
end

-- Spawn vehicle
function SpawnAdminVehicle(model)
    local hash = GetHashKey(model)
    
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        ESX.ShowNotification('~r~Invalid vehicle model')
        return
    end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(100)
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local vehicle = CreateVehicle(hash, coords.x + 2, coords.y, coords.z, heading, true, false)
    
    if Config.VehicleSpawn.spawnInside then
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    end
    
    SetVehicleFuelLevel(vehicle, Config.VehicleSpawn.defaultFuel)
    SetModelAsNoLongerNeeded(hash)
    
    ESX.ShowNotification('Vehicle spawned: ' .. model)
end

-- Delete nearby vehicles
function DeleteNearbyVehicles()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicles = ESX.Game.GetVehiclesInArea(coords, 10.0)
    local count = 0
    
    for _, vehicle in pairs(vehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            count = count + 1
        end
    end
    
    ESX.ShowNotification('Deleted ' .. count .. ' vehicles')
end

-- Toggle nametags
function ToggleNametags()
    showNametags = not showNametags
    if showNametags then
        ESX.ShowNotification('~g~Nametags enabled')
    else
        ESX.ShowNotification('~r~Nametags disabled')
    end
end

-- Nametag display
Citizen.CreateThread(function()
    while true do
        if showNametags and isOnDuty then
            local players = GetActivePlayers()
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, player in pairs(players) do
                if player ~= PlayerId() then
                    local targetPed = GetPlayerPed(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance < Config.Nametags.distance then
                        local playerId = GetPlayerServerId(player)
                        local playerName = GetPlayerName(player)
                        local health = GetEntityHealth(targetPed)
                        local armor = GetPedArmour(targetPed)
                        
                        local text = playerName
                        if Config.Nametags.showId then
                            text = text .. ' [' .. playerId .. ']'
                        end
                        if Config.Nametags.showHealth then
                            text = text .. '\nHealth: ' .. health
                        end
                        if Config.Nametags.showArmor and armor > 0 then
                            text = text .. '\nArmor: ' .. armor
                        end
                        
                        local x, y, z = table.unpack(targetCoords)
                        ESX.Game.Utils.DrawText3D(vector3(x, y, z + 1.0), text, 0.4)
                    end
                end
            end
        end
        
        Citizen.Wait(0)
    end
end)