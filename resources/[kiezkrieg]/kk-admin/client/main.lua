-- KiezKrieg Admin Client
local IsOnDuty = false
local ShowNametags = false
local AdminVehicles = {}
local IsAdminMenuOpen = false

-- Initialize admin client
Citizen.CreateThread(function()
    -- Wait for ESX to be ready
    while not ESX.GetPlayerData().job do
        Citizen.Wait(10)
    end
    
    -- Register F3 key mapping for admin menu
    RegisterKeyMapping('kk_admin_menu', 'Open Admin Menu', 'keyboard', 'F3')
    RegisterCommand('kk_admin_menu', function()
        print('[KiezKrieg] F3 pressed - checking admin permissions')
        OpenAdminMenu()
    end, false)
    
    print('[KiezKrieg] Admin client initialized')
end)

-- Admin menu functions
function OpenAdminMenu()
    if IsAdminMenuOpen then 
        print('[KiezKrieg] Admin menu already open')
        return 
    end
    
    -- Check if player has admin permissions by triggering server check
    TriggerServerEvent('kk-admin:checkPermissions')
end

function ShowAdminMenu()
    if IsAdminMenuOpen then return end
    
    print('[KiezKrieg] Opening admin menu')
    IsAdminMenuOpen = true
    
    -- Show admin menu as a simple notification-based menu
    exports['kk-ui']:ShowNotification('=== ADMIN MENU ===', 'info')
    exports['kk-ui']:ShowNotification('F3 - Toggle this menu', 'info')
    exports['kk-ui']:ShowNotification('/aduty - Toggle admin duty', 'info')
    exports['kk-ui']:ShowNotification('/goto [id] - Teleport to player', 'info')
    exports['kk-ui']:ShowNotification('/tpm - Teleport to marker', 'info')
    exports['kk-ui']:ShowNotification('/bring [id] - Bring player', 'info')
    exports['kk-ui']:ShowNotification('/vehicle [name] - Spawn vehicle', 'info')
    exports['kk-ui']:ShowNotification('/dv - Delete vehicle', 'info')
    exports['kk-ui']:ShowNotification('/nametags - Toggle nametags', 'info')
    exports['kk-ui']:ShowNotification('Status: ' .. (IsOnDuty and 'ON DUTY' or 'OFF DUTY'), IsOnDuty and 'success' or 'warning')
    
    -- Auto-close the menu after a few seconds
    Citizen.SetTimeout(5000, function()
        CloseAdminMenu()
    end)
end

function CloseAdminMenu()
    if not IsAdminMenuOpen then return end
    
    print('[KiezKrieg] Closing admin menu')
    IsAdminMenuOpen = false
end

-- Server response handlers
RegisterNetEvent('kk-admin:permissionGranted')
AddEventHandler('kk-admin:permissionGranted', function()
    ShowAdminMenu()
end)

RegisterNetEvent('kk-admin:permissionDenied')
AddEventHandler('kk-admin:permissionDenied', function()
    exports['kk-ui']:ShowNotification('You do not have admin permissions', 'error')
end)

-- Event handlers
RegisterNetEvent('kk-admin:setDutyStatus')
AddEventHandler('kk-admin:setDutyStatus', function(status)
    IsOnDuty = status
    print('[KiezKrieg] Admin duty status changed to: ' .. (status and 'ON' or 'OFF'))
    
    if status then
        StartAdminFeatures()
        exports['kk-ui']:ShowNotification('Admin duty: ON', 'success')
    else
        StopAdminFeatures()
        exports['kk-ui']:ShowNotification('Admin duty: OFF', 'info')
    end
end)

RegisterNetEvent('kk-admin:teleportToCoords')
AddEventHandler('kk-admin:teleportToCoords', function(coords)
    local playerPed = PlayerPedId()
    
    -- Fade out
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    
    -- Teleport
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    
    -- Fade in
    Citizen.Wait(100)
    DoScreenFadeIn(500)
    
    exports['kk-ui']:ShowNotification('Teleported', 'success')
end)

RegisterNetEvent('kk-admin:teleportToMarker')
AddEventHandler('kk-admin:teleportToMarker', function()
    local waypoint = GetFirstBlipInfoId(8)
    
    if DoesBlipExist(waypoint) then
        local coords = GetBlipCoords(waypoint)
        local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
        
        if found then
            coords = vector3(coords.x, coords.y, z)
        else
            coords = vector3(coords.x, coords.y, coords.z)
        end
        
        TriggerEvent('kk-admin:teleportToCoords', coords)
    else
        exports['kk-ui']:ShowNotification('No waypoint set', 'error')
    end
end)

RegisterNetEvent('kk-admin:spawnVehicle')
AddEventHandler('kk-admin:spawnVehicle', function(vehicleName)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Get vehicle hash
    local vehicleHash = GetHashKey(vehicleName)
    
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        exports['kk-ui']:ShowNotification('Invalid vehicle model', 'error')
        return
    end
    
    -- Request model
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Citizen.Wait(1)
    end
    
    -- Delete previous admin vehicle if exists
    if IsPedInAnyVehicle(playerPed, false) then
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        if IsAdminVehicle(currentVehicle) then
            DeleteVehicle(currentVehicle)
            RemoveAdminVehicle(currentVehicle)
        end
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(vehicleHash, coords.x + 2.0, coords.y + 2.0, coords.z, heading, true, false)
    
    if DoesEntityExist(vehicle) then
        -- Set vehicle properties
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleNumberPlateText(vehicle, 'ADMIN')
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDirtLevel(vehicle, 0.0)
        
        -- Add to admin vehicles list
        table.insert(AdminVehicles, vehicle)
        
        -- Put player in vehicle
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        
        exports['kk-ui']:ShowNotification('Vehicle spawned: ' .. vehicleName, 'success')
    else
        exports['kk-ui']:ShowNotification('Failed to spawn vehicle', 'error')
    end
    
    -- Clean up model
    SetModelAsNoLongerNeeded(vehicleHash)
end)

RegisterNetEvent('kk-admin:deleteVehicle')
AddEventHandler('kk-admin:deleteVehicle', function()
    local playerPed = PlayerPedId()
    
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        DeleteVehicle(vehicle)
        RemoveAdminVehicle(vehicle)
        exports['kk-ui']:ShowNotification('Vehicle deleted', 'success')
    else
        -- Delete nearby vehicles
        local coords = GetEntityCoords(playerPed)
        local vehicles = GetVehiclesInArea(coords, 5.0)
        
        if #vehicles > 0 then
            for _, vehicle in ipairs(vehicles) do
                DeleteVehicle(vehicle)
                RemoveAdminVehicle(vehicle)
            end
            exports['kk-ui']:ShowNotification('Deleted ' .. #vehicles .. ' nearby vehicles', 'success')
        else
            exports['kk-ui']:ShowNotification('No vehicles nearby', 'error')
        end
    end
end)

RegisterNetEvent('kk-admin:toggleNametags')
AddEventHandler('kk-admin:toggleNametags', function()
    ShowNametags = not ShowNametags
    
    if ShowNametags then
        exports['kk-ui']:ShowNotification('Nametags enabled', 'success')
        StartNametags()
    else
        exports['kk-ui']:ShowNotification('Nametags disabled', 'info')
    end
end)

-- Start admin features
function StartAdminFeatures()
    -- Admin mode indicator
    Citizen.CreateThread(function()
        while IsOnDuty do
            Citizen.Wait(0)
            
            -- Draw admin indicator
            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 107, 107, 255)
            SetTextEntry('STRING')
            AddTextComponentString('ADMIN ON DUTY')
            DrawText(0.01, 0.01)
            
            -- God mode for admins
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, true)
            
            -- Unlimited stamina
            RestorePlayerStamina(PlayerId(), 1.0)
        end
        
        -- Disable god mode when off duty
        local playerPed = PlayerPedId()
        SetEntityInvincible(playerPed, false)
    end)
end

-- Stop admin features
function StopAdminFeatures()
    ShowNametags = false
    
    -- Clean up admin vehicles
    for _, vehicle in ipairs(AdminVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteVehicle(vehicle)
        end
    end
    AdminVehicles = {}
end

-- Start nametags
function StartNametags()
    Citizen.CreateThread(function()
        while ShowNametags do
            Citizen.Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local targetPed = GetPlayerPed(player)
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(playerCoords - targetCoords)
                    
                    if distance <= 50.0 then
                        local playerId = GetPlayerServerId(player)
                        local playerName = GetPlayerName(player)
                        
                        -- Draw nametag
                        local x, y = GetScreenCoordFromWorldCoord(targetCoords.x, targetCoords.y, targetCoords.z + 1.0)
                        
                        SetTextFont(4)
                        SetTextProportional(0)
                        SetTextScale(0.35, 0.35)
                        SetTextColour(255, 255, 255, 255)
                        SetTextCentre(true)
                        SetTextEntry('STRING')
                        AddTextComponentString('[' .. playerId .. '] ' .. playerName)
                        DrawText(x, y)
                        
                        -- Health bar
                        local health = GetEntityHealth(targetPed)
                        local maxHealth = GetEntityMaxHealth(targetPed)
                        local healthPercent = health / maxHealth
                        
                        -- Background
                        DrawRect(x, y + 0.03, 0.06, 0.008, 0, 0, 0, 150)
                        -- Health bar
                        DrawRect(x - 0.03 + (0.06 * healthPercent / 2), y + 0.03, 0.06 * healthPercent, 0.006, 255, 107, 107, 255)
                    end
                end
            end
        end
    end)
end

-- Utility functions
function IsAdminVehicle(vehicle)
    for i, adminVehicle in ipairs(AdminVehicles) do
        if adminVehicle == vehicle then
            return true, i
        end
    end
    return false, nil
end

function RemoveAdminVehicle(vehicle)
    local isAdmin, index = IsAdminVehicle(vehicle)
    if isAdmin then
        table.remove(AdminVehicles, index)
    end
end

function GetVehiclesInArea(coords, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success
    
    repeat
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance <= radius then
            table.insert(vehicles, vehicle)
        end
        
        success, vehicle = FindNextVehicle(handle)
    until not success
    
    EndFindVehicle(handle)
    return vehicles
end

-- Export functions
exports('IsOnDuty', function()
    return IsOnDuty
end)

exports('GetAdminVehicles', function()
    return AdminVehicles
end)