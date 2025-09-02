-- KiezKrieg Zone Management Client
local ESX = exports["es_extended"]:getSharedObject()
local activeZones = {}
local currentZone = nil
local zoneBlips = {}
local zoneMarkers = {}
local weaponsGiven = false

-- Zone data from core config
local zones = KiezKrieg.Config.Zones.FFA

-- Initialize zone system
Citizen.CreateThread(function()
    Wait(1000) -- Wait for ESX to load
    createZoneBlips()
    startZoneDetection()
    startZoneMarkers()
end)

-- Create blips for all zones
function createZoneBlips()
    for _, zone in pairs(zones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, 3) -- Light blue
        SetBlipAlpha(blip, 128)
        
        local markerBlip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(markerBlip, 84) -- Target sprite
        SetBlipDisplay(markerBlip, 4)
        SetBlipScale(markerBlip, 1.0)
        SetBlipColour(markerBlip, 3)
        SetBlipAsShortRange(markerBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(zone.name)
        EndTextCommandSetBlipName(markerBlip)
        
        zoneBlips[zone.id] = {radius = blip, marker = markerBlip}
    end
end

-- Zone detection loop
function startZoneDetection()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local inAnyZone = false
            
            for _, zone in pairs(zones) do
                local distance = #(playerCoords - zone.coords)
                
                if distance <= zone.radius then
                    inAnyZone = true
                    if not currentZone or currentZone.id ~= zone.id then
                        currentZone = zone
                        onEnterZone(zone)
                    end
                    break
                end
            end
            
            if not inAnyZone and currentZone then
                onExitZone(currentZone)
                currentZone = nil
            end
        end
    end)
end

-- Zone markers (3D circles)
function startZoneMarkers()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, zone in pairs(zones) do
                local distance = #(playerCoords - zone.coords)
                
                if distance <= 500.0 then -- Only show markers within 500m
                    -- Draw zone boundary circle
                    DrawMarker(
                        1, -- Circle marker
                        zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        zone.radius * 2.0, zone.radius * 2.0, 1.0,
                        zone.color.r, zone.color.g, zone.color.b, zone.color.a,
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Draw zone name
                    if distance <= zone.radius then
                        local onScreen, _x, _y = World3dToScreen2d(zone.coords.x, zone.coords.y, zone.coords.z + 10.0)
                        if onScreen then
                            SetTextScale(0.6, 0.6)
                            SetTextFont(4)
                            SetTextProportional(1)
                            SetTextColour(255, 255, 255, 255)
                            SetTextEntry("STRING")
                            SetTextCentre(true)
                            AddTextComponentString(zone.name)
                            DrawText(_x, _y)
                        end
                    end
                end
            end
        end
    end)
end

-- Enter zone event
function onEnterZone(zone)
    ESX.ShowNotification('~b~Entered: ~w~' .. zone.name)
    ESX.ShowNotification('~y~Press F2 to join the fight!')
    
    -- Get current player count in zone
    TriggerServerEvent('kk-zones:requestZoneInfo', zone.id)
end

-- Exit zone event
function onExitZone(zone)
    ESX.ShowNotification('~g~Left: ~w~' .. zone.name)
end

-- FFA Zone Events
RegisterNetEvent('kk-zones:enterFFA')
AddEventHandler('kk-zones:enterFFA', function(data)
    local zone = data.zone
    local mode = data.mode
    
    -- Teleport to spawn point
    local spawnPoint = getRandomSpawnPoint()
    SetEntityCoords(PlayerPedId(), spawnPoint.coords.x, spawnPoint.coords.y, spawnPoint.coords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), spawnPoint.heading)
    
    -- Give weapons based on mode
    giveFFAWeapons(mode)
    
    -- Set health and armor
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 100)
    
    -- Show zone info
    ESX.ShowNotification('~g~Joined FFA: ~w~' .. zone.name .. ' (~b~' .. mode .. '~w~)')
    ESX.ShowNotification('~y~Type /leave to exit the zone')
    
    weaponsGiven = true
end)

RegisterNetEvent('kk-zones:leaveFFA')
AddEventHandler('kk-zones:leaveFFA', function()
    -- Remove all weapons
    RemoveAllPedWeapons(PlayerPedId(), true)
    weaponsGiven = false
    
    -- Reset health and armor
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 0)
    
    ESX.ShowNotification('~r~Left FFA zone')
end)

-- Custom Lobby Events
RegisterNetEvent('kk-zones:enterLobby')
AddEventHandler('kk-zones:enterLobby', function(data)
    local lobby = data.lobby
    
    -- Teleport to lobby spawn
    local spawnPoint = getLobbySpawnPoint(lobby.map)
    SetEntityCoords(PlayerPedId(), spawnPoint.coords.x, spawnPoint.coords.y, spawnPoint.coords.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), spawnPoint.heading)
    
    -- Give standard lobby weapons
    giveLobbyWeapons()
    
    ESX.ShowNotification('~g~Joined Lobby: ~w~' .. lobby.name)
    ESX.ShowNotification('~y~Type /leave to exit the lobby')
end)

RegisterNetEvent('kk-zones:leaveLobby')
AddEventHandler('kk-zones:leaveLobby', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    ESX.ShowNotification('~r~Left lobby')
end)

-- Helifight Events
RegisterNetEvent('kk-zones:enterHelifight')
AddEventHandler('kk-zones:enterHelifight', function(data)
    -- Teleport to helipad
    local heliSpawn = vector3(-1145.0, -2864.0, 13.9)
    SetEntityCoords(PlayerPedId(), heliSpawn.x, heliSpawn.y, heliSpawn.z, false, false, false, true)
    
    -- Spawn helicopter
    spawnHelifightHeli()
    
    ESX.ShowNotification('~g~Joined Helifight!')
    ESX.ShowNotification('~y~Get in the helicopter and wait for other players')
end)

RegisterNetEvent('kk-zones:leaveHelifight')
AddEventHandler('kk-zones:leaveHelifight', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    ESX.ShowNotification('~r~Left Helifight')
end)

-- Zone info update
RegisterNetEvent('kk-zones:updateZoneInfo')
AddEventHandler('kk-zones:updateZoneInfo', function(zoneId, playerCount, maxPlayers)
    -- Update UI if needed
    -- This could be used to show real-time player counts
end)

-- Helper functions
function giveFFAWeapons(mode)
    RemoveAllPedWeapons(PlayerPedId(), true)
    
    if mode == 'headshot' then
        GiveWeaponToPed(PlayerPedId(), KiezKrieg.Config.Weapons.HEADSHOT_MODE.primary, 500, false, true)
    elseif mode == 'bodyshot' then
        GiveWeaponToPed(PlayerPedId(), KiezKrieg.Config.Weapons.BODYSHOT_MODE.primary, 500, false, true)
        GiveWeaponToPed(PlayerPedId(), KiezKrieg.Config.Weapons.BODYSHOT_MODE.secondary, 500, false, false)
    end
end

function giveLobbyWeapons()
    RemoveAllPedWeapons(PlayerPedId(), true)
    
    -- Give standard lobby weapons
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_SPECIALCARBINE"), 500, false, true)
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PISTOL"), 200, false, false)
    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_GRENADE"), 5, false, false)
end

function getRandomSpawnPoint()
    local spawnPoints = KiezKrieg.Config.SpawnPoints.FFA
    return spawnPoints[math.random(1, #spawnPoints)]
end

function getLobbySpawnPoint(mapName)
    -- Default spawn points for different maps
    local spawnPoints = {
        default = {coords = vector3(-1037.0, -2737.0, 20.2), heading = 180.0},
        airport = {coords = vector3(-1336.0, -3044.0, 13.9), heading = 90.0},
        downtown = {coords = vector3(715.0, -962.0, 30.4), heading = 0.0},
        industrial = {coords = vector3(-1212.0, -1607.0, 4.6), heading = 270.0}
    }
    
    return spawnPoints[mapName] or spawnPoints.default
end

function spawnHelifightHeli()
    local model = GetHashKey(KiezKrieg.Config.Vehicles.HELIFIGHT_VEHICLE)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local heliSpawn = vector3(-1145.0, -2864.0, 13.9)
    local vehicle = CreateVehicle(model, heliSpawn.x, heliSpawn.y, heliSpawn.z, 0.0, true, false)
    
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleOnGroundProperly(vehicle)
    
    SetModelAsNoLongerNeeded(model)
end

-- Prevent weapon pickup in zones
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if weaponsGiven then
            -- Disable weapon pickups
            local playerPed = PlayerPedId()
            if IsPedArmed(playerPed, 6) then
                DisableControlAction(0, 37, true) -- Disable weapon wheel
            end
        end
    end
end)

-- Export functions
exports('getCurrentZone', function()
    return currentZone
end)

exports('isInZone', function()
    return currentZone ~= nil
end)