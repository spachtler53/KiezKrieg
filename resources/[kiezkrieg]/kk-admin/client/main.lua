-- KiezKrieg Admin Client
local ESX = exports["es_extended"]:getSharedObject()
local isAdminDuty = false
local adminMenuOpen = false
local spawnedVehicles = {}
local noclipEnabled = false
local noclipSpeed = 1.0
local nametagsVisible = true

-- Admin duty status
RegisterNetEvent('kk-admin:updateDutyStatus')
AddEventHandler('kk-admin:updateDutyStatus', function(dutyStatus)
    isAdminDuty = dutyStatus
    
    if isAdminDuty then
        ESX.ShowNotification('~g~Admin Duty: ~w~ON')
        
        -- Enable admin features
        if KiezKrieg.Admin.Duty.ENABLE_GODMODE then
            SetEntityInvincible(PlayerPedId(), true)
        end
        
        if KiezKrieg.Admin.Duty.ENABLE_INVISIBILITY then
            -- Can be toggled later
        end
        
    else
        ESX.ShowNotification('~r~Admin Duty: ~w~OFF')
        
        -- Disable admin features
        SetEntityInvincible(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, 0)
        
        if noclipEnabled then
            toggleNoclip()
        end
        
        -- Clean up spawned vehicles
        if KiezKrieg.Admin.Vehicles.CLEANUP_ON_DUTY_OFF then
            cleanupSpawnedVehicles()
        end
    end
end)

-- Admin menu key binding
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if IsControlJustPressed(0, KiezKrieg.Admin.MenuKey) and isAdminDuty and not adminMenuOpen then
            openAdminMenu()
        end
        
        -- Noclip controls
        if noclipEnabled then
            handleNoclip()
        end
    end
end)

-- Admin menu
function openAdminMenu()
    if not isAdminDuty then
        ESX.ShowNotification('~r~You must be on admin duty!')
        return
    end
    
    adminMenuOpen = true
    
    local elements = {
        {label = '👤 Player Management', value = 'players'},
        {label = '🚗 Vehicle Spawn', value = 'vehicles'},
        {label = '📍 Teleport Menu', value = 'teleport'},
        {label = '✈️ Noclip: ' .. (noclipEnabled and '~g~ON' or '~r~OFF'), value = 'noclip'},
        {label = '👻 Invisibility', value = 'invisibility'},
        {label = '🏷️ Nametags: ' .. (nametagsVisible and '~g~ON' or '~r~OFF'), value = 'nametags'},
        {label = '🏭 Faction Management', value = 'factions'},
        {label = '🗺️ Zone Management', value = 'zones'},
        {label = '📊 Server Stats', value = 'stats'}
    }
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'admin_menu', {
        title = 'Admin Menu',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value
        
        if action == 'players' then
            openPlayerMenu()
        elseif action == 'vehicles' then
            openVehicleMenu()
        elseif action == 'teleport' then
            openTeleportMenu()
        elseif action == 'noclip' then
            toggleNoclip()
            menu.close()
            openAdminMenu()
        elseif action == 'invisibility' then
            toggleInvisibility()
        elseif action == 'nametags' then
            toggleNametags()
            menu.close()
            openAdminMenu()
        elseif action == 'factions' then
            openFactionManagement()
        elseif action == 'zones' then
            openZoneManagement()
        elseif action == 'stats' then
            showServerStats()
        end
    end, function(data, menu)
        menu.close()
        adminMenuOpen = false
    end)
end

-- Player management menu
function openPlayerMenu()
    TriggerServerEvent('kk-admin:requestPlayerList')
end

RegisterNetEvent('kk-admin:receivePlayerList')
AddEventHandler('kk-admin:receivePlayerList', function(players)
    local elements = {}
    
    for _, player in ipairs(players) do
        table.insert(elements, {
            label = string.format('[%d] %s', player.id, player.name),
            value = player.id
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_list', {
        title = 'Player Management',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        openPlayerActions(data.current.value)
    end, function(data, menu)
        menu.close()
        openAdminMenu()
    end)
end)

-- Player actions menu
function openPlayerActions(playerId)
    local elements = {
        {label = '📍 Goto Player', value = 'goto'},
        {label = '📍 Bring Player', value = 'bring'},
        {label = '🚗 Give Vehicle', value = 'vehicle'},
        {label = '💰 Give Money', value = 'money'},
        {label = '❤️ Heal Player', value = 'heal'},
        {label = '⚰️ Kill Player', value = 'kill'},
        {label = '❄️ Freeze Player', value = 'freeze'},
        {label = '👻 Spectate Player', value = 'spectate'},
        {label = '⚠️ Kick Player', value = 'kick'},
        {label = '🚫 Ban Player', value = 'ban'}
    }
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_actions', {
        title = 'Player Actions - ID: ' .. playerId,
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value
        
        if action == 'goto' then
            TriggerServerEvent('kk-admin:gotoPlayer', playerId)
        elseif action == 'bring' then
            TriggerServerEvent('kk-admin:bringPlayer', playerId)
        elseif action == 'heal' then
            TriggerServerEvent('kk-admin:healPlayer', playerId)
        elseif action == 'kill' then
            TriggerServerEvent('kk-admin:killPlayer', playerId)
        elseif action == 'kick' then
            kickPlayer(playerId)
        elseif action == 'money' then
            givePlayerMoney(playerId)
        elseif action == 'vehicle' then
            givePlayerVehicle(playerId)
        end
        
        menu.close()
    end, function(data, menu)
        menu.close()
        openPlayerMenu()
    end)
end

-- Vehicle spawn menu
function openVehicleMenu()
    local elements = {}
    
    for _, vehicle in ipairs(KiezKrieg.Admin.Vehicles.ALLOWED_VEHICLES) do
        table.insert(elements, {
            label = vehicle:upper(),
            value = vehicle
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawn', {
        title = 'Vehicle Spawn',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        spawnVehicle(data.current.value)
        menu.close()
    end, function(data, menu)
        menu.close()
        openAdminMenu()
    end)
end

-- Teleport menu
function openTeleportMenu()
    local elements = {}
    
    -- Add preset locations
    for _, location in ipairs(KiezKrieg.Admin.TeleportLocations) do
        table.insert(elements, {
            label = '📍 ' .. location.name,
            value = 'preset_' .. location.name
        })
    end
    
    -- Add custom options
    table.insert(elements, {label = '🎯 Teleport to Marker', value = 'marker'})
    table.insert(elements, {label = '📝 Teleport to Coordinates', value = 'coords'})
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'teleport_menu', {
        title = 'Teleport Menu',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local value = data.current.value
        
        if value == 'marker' then
            teleportToMarker()
        elseif value == 'coords' then
            teleportToCoords()
        elseif string.match(value, 'preset_') then
            local locationName = string.gsub(value, 'preset_', '')
            teleportToPreset(locationName)
        end
        
        menu.close()
    end, function(data, menu)
        menu.close()
        openAdminMenu()
    end)
end

-- Teleport functions
function teleportToMarker()
    local marker = GetFirstBlipInfoId(8) -- Waypoint blip
    
    if DoesBlipExist(marker) then
        local coords = GetBlipInfoIdCoord(marker)
        local ground, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        
        if ground then
            coords = vector3(coords.x, coords.y, groundZ + 1.0)
        else
            coords = vector3(coords.x, coords.y, coords.z)
        end
        
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
        ESX.ShowNotification('~g~Teleported to marker')
    else
        ESX.ShowNotification('~r~No marker set on map!')
    end
end

function teleportToPreset(locationName)
    for _, location in ipairs(KiezKrieg.Admin.TeleportLocations) do
        if location.name == locationName then
            SetEntityCoords(PlayerPedId(), location.coords.x, location.coords.y, location.coords.z, false, false, false, true)
            ESX.ShowNotification('~g~Teleported to ' .. location.name)
            break
        end
    end
end

-- Noclip function
function toggleNoclip()
    if not isAdminDuty then return end
    
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        ESX.ShowNotification('~g~Noclip: ~w~ON')
    else
        ESX.ShowNotification('~r~Noclip: ~w~OFF')
        local playerPed = PlayerPedId()
        FreezeEntityPosition(playerPed, false)
        SetEntityVisible(playerPed, true, 0)
        SetEntityCollision(playerPed, true, true)
    end
end

function handleNoclip()
    local playerPed = PlayerPedId()
    
    FreezeEntityPosition(playerPed, true)
    SetEntityVisible(playerPed, false, 0)
    SetEntityCollision(playerPed, false, false)
    
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Movement controls
    if IsControlPressed(0, 32) then -- W
        coords = coords + GetEntityForwardVector(playerPed) * noclipSpeed
    end
    if IsControlPressed(0, 33) then -- S
        coords = coords - GetEntityForwardVector(playerPed) * noclipSpeed
    end
    if IsControlPressed(0, 34) then -- A
        coords = coords - GetEntityRightVector(playerPed) * noclipSpeed
    end
    if IsControlPressed(0, 35) then -- D
        coords = coords + GetEntityRightVector(playerPed) * noclipSpeed
    end
    if IsControlPressed(0, 44) then -- Q (down)
        coords = coords - vector3(0, 0, noclipSpeed)
    end
    if IsControlPressed(0, 38) then -- E (up)
        coords = coords + vector3(0, 0, noclipSpeed)
    end
    
    -- Speed control
    if IsControlPressed(0, 21) then -- Shift (faster)
        noclipSpeed = 2.0
    else
        noclipSpeed = 1.0
    end
    
    SetEntityCoordsNoOffset(playerPed, coords.x, coords.y, coords.z, false, false, false)
end

-- Toggle invisibility
function toggleInvisibility()
    local playerPed = PlayerPedId()
    local isVisible = IsEntityVisible(playerPed)
    
    SetEntityVisible(playerPed, not isVisible, 0)
    
    if isVisible then
        ESX.ShowNotification('~g~Invisibility: ~w~ON')
    else
        ESX.ShowNotification('~r~Invisibility: ~w~OFF')
    end
end

-- Toggle nametags
function toggleNametags()
    nametagsVisible = not nametagsVisible
    -- This would typically interact with a nametag system
    ESX.ShowNotification('~y~Nametags: ' .. (nametagsVisible and '~g~ON' or '~r~OFF'))
end

-- Vehicle spawn function
function spawnVehicle(vehicleName)
    if #spawnedVehicles >= KiezKrieg.Admin.Vehicles.MAX_SPAWNED_VEHICLES then
        ESX.ShowNotification('~r~Maximum spawned vehicles reached!')
        return
    end
    
    local vehicleHash = GetHashKey(vehicleName)
    RequestModel(vehicleHash)
    
    while not HasModelLoaded(vehicleHash) do
        Wait(1)
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local vehicle = CreateVehicle(vehicleHash, coords.x + 3.0, coords.y, coords.z, heading, true, false)
    
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetModelAsNoLongerNeeded(vehicleHash)
    
    table.insert(spawnedVehicles, vehicle)
    
    ESX.ShowNotification('~g~Spawned: ~w~' .. vehicleName:upper())
end

-- Cleanup spawned vehicles
function cleanupSpawnedVehicles()
    for _, vehicle in ipairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteVehicle(vehicle)
        end
    end
    spawnedVehicles = {}
    ESX.ShowNotification('~y~Cleaned up spawned vehicles')
end

-- Admin command to toggle duty
RegisterCommand('aduty', function()
    TriggerServerEvent('kk-admin:toggleDuty')
end, false)

-- Help command
RegisterCommand('ahelp', function()
    if not isAdminDuty then
        ESX.ShowNotification('~r~You must be on admin duty!')
        return
    end
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 255},
        multiline = true,
        args = {"Admin Help", "Commands:\n/aduty - Toggle admin duty\n/goto [id] - Teleport to player\n/bring [id] - Bring player to you\n/tpm - Teleport to marker\nF6 - Open admin menu"}
    })
end, false)

-- Export functions
exports('isAdminDuty', function()
    return isAdminDuty
end)

exports('hasAdminPermission', function()
    return isAdminDuty
end)