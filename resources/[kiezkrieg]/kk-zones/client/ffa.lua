-- KiezKrieg FFA Client
local InFFA = false
local CurrentZone = nil
local CurrentWeaponMode = nil

-- Event handlers
RegisterNetEvent('kk-ffa:giveWeapons')
AddEventHandler('kk-ffa:giveWeapons', function(weaponMode)
    local playerPed = PlayerPedId()
    
    -- Remove all weapons first
    RemoveAllPedWeapons(playerPed, true)
    
    -- Give weapons based on mode
    if weaponMode == 'headshot' then
        GiveWeaponToPed(playerPed, GetHashKey('WEAPON_PISTOL'), 999, false, true)
    elseif weaponMode == 'bodyshot' then
        GiveWeaponToPed(playerPed, GetHashKey('WEAPON_SPECIALCARBINE'), 999, false, true)
        GiveWeaponToPed(playerPed, GetHashKey('WEAPON_ADVANCEDRIFLE'), 999, false, false)
    end
    
    -- Give armor and health
    SetPedArmour(playerPed, 100)
    SetEntityHealth(playerPed, 200)
    
    CurrentWeaponMode = weaponMode
    InFFA = true
    
    -- Start FFA features
    StartFFAMode()
end)

RegisterNetEvent('kk-ffa:removeWeapons')
AddEventHandler('kk-ffa:removeWeapons', function()
    local playerPed = PlayerPedId()
    RemoveAllPedWeapons(playerPed, true)
    SetPedArmour(playerPed, 0)
    SetEntityHealth(playerPed, 200)
    
    InFFA = false
    CurrentWeaponMode = nil
    CurrentZone = nil
    
    -- Stop FFA features
    StopFFAMode()
end)

RegisterNetEvent('kk-ffa:teleportToPosition')
AddEventHandler('kk-ffa:teleportToPosition', function(coords)
    local playerPed = PlayerPedId()
    
    -- Fade out
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    
    -- Teleport
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(playerPed, coords.h)
    
    -- Fade in
    Citizen.Wait(100)
    DoScreenFadeIn(500)
    
    -- Clear wanted level
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
end)

RegisterNetEvent('kk-ffa:teleportToLobby')
AddEventHandler('kk-ffa:teleportToLobby', function()
    local lobbySpawn = Config.SpawnPoints.lobby[1]
    TriggerEvent('kk-ffa:teleportToPosition', lobbySpawn)
end)

RegisterNetEvent('kk-ffa:respawned')
AddEventHandler('kk-ffa:respawned', function()
    local playerPed = PlayerPedId()
    
    -- Restore health and armor
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 100)
    
    -- Give weapons again
    if CurrentWeaponMode then
        Citizen.Wait(100)
        TriggerEvent('kk-ffa:giveWeapons', CurrentWeaponMode)
    end
    
    exports['kk-ui']:ShowNotification('Respawned!', 'info')
end)

-- Start FFA mode features
function StartFFAMode()
    Citizen.CreateThread(function()
        while InFFA do
            Citizen.Wait(0)
            
            -- Disable some game features during FFA
            DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL (Alt)
            DisableControlAction(0, 20, true) -- INPUT_MULTIPLAYER_INFO (Z)
            
            -- Check for player death
            local playerPed = PlayerPedId()
            if IsEntityDead(playerPed) then
                Citizen.Wait(2000)
                
                -- Find killer
                local killer = GetPedSourceOfDeath(playerPed)
                if killer and killer ~= playerPed then
                    local killerId = NetworkGetPlayerIndexFromPed(killer)
                    if killerId and killerId ~= -1 then
                        local killerServerId = GetPlayerServerId(killerId)
                        TriggerServerEvent('kk-ffa:playerKilled', killerServerId)
                    end
                end
                
                break
            end
        end
    end)
    
    -- Start health/armor regen
    StartHealthArmorRegen()
    
    -- Start minimap modifications for FFA
    StartFFAMinimap()
end

-- Stop FFA mode features
function StopFFAMode()
    -- Minimap will be reset automatically
    exports['kk-ui']:ShowNotification('Left FFA mode', 'info')
end

-- Health and armor regeneration
function StartHealthArmorRegen()
    Citizen.CreateThread(function()
        while InFFA do
            Citizen.Wait(5000) -- Regen every 5 seconds
            
            local playerPed = PlayerPedId()
            if not IsEntityDead(playerPed) then
                local currentHealth = GetEntityHealth(playerPed)
                local currentArmor = GetPedArmour(playerPed)
                
                -- Slow health regen
                if currentHealth < 200 and currentHealth > 0 then
                    local newHealth = math.min(200, currentHealth + 10)
                    SetEntityHealth(playerPed, newHealth)
                end
                
                -- Slower armor regen
                if currentArmor < 100 then
                    local newArmor = math.min(100, currentArmor + 5)
                    SetPedArmour(playerPed, newArmor)
                end
            end
        end
    end)
end

-- FFA minimap modifications
function StartFFAMinimap()
    Citizen.CreateThread(function()
        while InFFA do
            Citizen.Wait(0)
            
            -- Show players on minimap in FFA
            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local playerPed = GetPlayerPed(player)
                    local blip = GetBlipFromEntity(playerPed)
                    
                    if not DoesBlipExist(blip) then
                        blip = AddBlipForEntity(playerPed)
                        SetBlipSprite(blip, 1)
                        SetBlipColour(blip, 1) -- Red for enemies
                        SetBlipScale(blip, 0.8)
                        SetBlipAsShortRange(blip, true)
                    end
                end
            end
        end
        
        -- Clean up blips when leaving FFA
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local playerPed = GetPlayerPed(player)
                local blip = GetBlipFromEntity(playerPed)
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
        end
    end)
end

-- Commands
RegisterCommand('leaveffa', function()
    if InFFA then
        TriggerServerEvent('kk-ffa:leaveZone')
    else
        exports['kk-ui']:ShowNotification('You are not in FFA', 'error')
    end
end, false)

-- Key bindings
RegisterKeyMapping('leaveffa', 'Leave FFA Zone', 'keyboard', 'F3')

-- Export functions
exports('IsInFFA', function()
    return InFFA
end)

exports('GetCurrentWeaponMode', function()
    return CurrentWeaponMode
end)

exports('GetCurrentZone', function()
    return CurrentZone
end)