local zoneBlips = {}
local zoneMarkers = {}

-- Initialize zones
Citizen.CreateThread(function()
    -- Wait for core resource to load
    while not exports['kk-core'] do
        Citizen.Wait(100)
    end
    
    CreateZoneBlips()
    CreateZoneMarkers()
end)

-- Create blips for FFA zones
function CreateZoneBlips()
    -- Get zones from core config
    local coreConfig = exports['kk-core']:GetConfig()
    if not coreConfig or not coreConfig.FFAZones then return end
    
    for _, zone in pairs(coreConfig.FFAZones) do
        local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(blip, Config.ZoneBlips.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.ZoneBlips.scale)
        SetBlipColour(blip, Config.ZoneBlips.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(zone.name)
        EndTextCommandSetBlipName(blip)
        
        table.insert(zoneBlips, blip)
    end
end

-- Create visual markers for zones
function CreateZoneMarkers()
    Citizen.CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Get zones from core config
            local coreConfig = exports['kk-core']:GetConfig()
            if coreConfig and coreConfig.FFAZones then
                for _, zone in pairs(coreConfig.FFAZones) do
                    local distance = #(playerCoords - zone.coords)
                    
                    -- Only show marker if player is close enough
                    if distance < 500.0 then
                        -- Draw zone marker
                        DrawMarker(
                            Config.ZoneMarkers.type,
                            zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            zone.radius * 2, zone.radius * 2, Config.ZoneMarkers.size.z,
                            zone.color.r, zone.color.g, zone.color.b, zone.color.a,
                            Config.ZoneMarkers.bobUpAndDown,
                            Config.ZoneMarkers.faceCamera,
                            2,
                            Config.ZoneMarkers.rotate,
                            nil, nil,
                            Config.ZoneMarkers.drawOnEnts
                        )
                        
                        -- Draw zone boundary circle
                        if distance < zone.radius + 50.0 then
                            DrawMarker(
                                25, -- Ring marker
                                zone.coords.x, zone.coords.y, zone.coords.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                zone.radius * 2, zone.radius * 2, 1.0,
                                zone.color.r, zone.color.g, zone.color.b, 150,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                        
                        -- Show zone info when close
                        if distance < zone.radius then
                            SetTextComponentFormat('STRING')
                            AddTextComponentString('~b~' .. zone.name .. '~w~\nPress ~INPUT_CONTEXT~ to open menu')
                            SetFloatingHelpTextWorldPosition(1, zone.coords.x, zone.coords.y, zone.coords.z + 2.0)
                            SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
                            DisplayFloatingHelpText(1, zone.name)
                            
                            -- Check for interaction
                            if IsControlJustPressed(0, 38) then -- E key
                                TriggerEvent('kk-core:openMainMenu')
                            end
                        end
                    end
                end
            end
            
            Citizen.Wait(0)
        end
    end)
end

-- Clean up blips when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(zoneBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

-- Export functions
exports('GetZoneBlips', function()
    return zoneBlips
end)

exports('CreateCustomZoneBlip', function(coords, name, color)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.ZoneBlips.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.ZoneBlips.scale)
    SetBlipColour(blip, color or Config.ZoneBlips.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    
    return blip
end)