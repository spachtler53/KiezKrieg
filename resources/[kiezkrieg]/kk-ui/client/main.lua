-- KiezKrieg UI Client
RegisterNetEvent('kk-ui:openMenu')
AddEventHandler('kk-ui:openMenu', function(playerData, zones, config)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openMenu',
        playerData = playerData,
        zones = zones,
        config = config
    })
end)

RegisterNetEvent('kk-ui:closeMenu')
AddEventHandler('kk-ui:closeMenu', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeMenu'
    })
end)

RegisterNetEvent('kk-ui:showNotification')
AddEventHandler('kk-ui:showNotification', function(message, notificationType)
    SendNUIMessage({
        type = 'showNotification',
        message = message,
        notificationType = notificationType or 'info'
    })
end)

RegisterNetEvent('kk-ui:updatePlayerData')
AddEventHandler('kk-ui:updatePlayerData', function(playerData)
    SendNUIMessage({
        type = 'updatePlayerData',
        playerData = playerData
    })
end)

RegisterNetEvent('kk-ui:updateZones')
AddEventHandler('kk-ui:updateZones', function(zones)
    SendNUIMessage({
        type = 'updateZones',
        zones = zones
    })
end)

RegisterNetEvent('kk-ui:updateLobbies')
AddEventHandler('kk-ui:updateLobbies', function(lobbies)
    SendNUIMessage({
        type = 'updateLobbies',
        lobbies = lobbies
    })
end)

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('kk-core:menuClosed')
    cb('ok')
end)

RegisterNUICallback('joinFFA', function(data, cb)
    TriggerServerEvent('kk-ffa:joinZone', data.zoneId, data.weaponMode)
    cb('ok')
end)

RegisterNUICallback('joinCustomLobby', function(data, cb)
    TriggerServerEvent('kk-custom:joinLobby', data.lobbyId)
    cb('ok')
end)

RegisterNUICallback('joinHelifight', function(data, cb)
    TriggerServerEvent('kk-helifight:joinQueue')
    cb('ok')
end)

RegisterNUICallback('joinGangwar', function(data, cb)
    TriggerServerEvent('kk-gangwar:openMenu')
    cb('ok')
end)

RegisterNUICallback('createCustomLobby', function(data, cb)
    TriggerServerEvent('kk-custom:createLobby', data)
    cb('ok')
end)

RegisterNUICallback('updatePreferences', function(data, cb)
    TriggerServerEvent('kk-core:savePlayerPreferences', data)
    cb('ok')
end)

-- Export functions
exports('OpenMenu', function(playerData, zones, config)
    TriggerEvent('kk-ui:openMenu', playerData, zones, config)
end)

exports('CloseMenu', function()
    TriggerEvent('kk-ui:closeMenu')
end)

exports('ShowNotification', function(message, notificationType)
    TriggerEvent('kk-ui:showNotification', message, notificationType)
end)