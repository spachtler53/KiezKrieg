-- KiezKrieg UI Server
-- This file provides server-side UI management functions

-- Export functions for other resources to use
exports('ShowNotificationToPlayer', function(playerId, message, notificationType)
    TriggerClientEvent('kk-ui:showNotification', playerId, message, notificationType or 'info')
end)

exports('OpenMenuForPlayer', function(playerId, playerData, zones, config)
    TriggerClientEvent('kk-ui:openMenu', playerId, playerData, zones, config)
end)

exports('CloseMenuForPlayer', function(playerId)
    TriggerClientEvent('kk-ui:closeMenu', playerId)
end)

exports('UpdatePlayerDataUI', function(playerId, playerData)
    TriggerClientEvent('kk-ui:updatePlayerData', playerId, playerData)
end)

exports('UpdateZonesUI', function(playerId, zones)
    TriggerClientEvent('kk-ui:updateZones', playerId, zones)
end)

exports('UpdateLobbiesUI', function(playerId, lobbies)
    TriggerClientEvent('kk-ui:updateLobbies', playerId, lobbies)
end)

-- Utility function to show notifications to all players
function ShowNotificationToAll(message, notificationType)
    TriggerClientEvent('kk-ui:showNotification', -1, message, notificationType or 'info')
end

-- Utility function to show notifications to players in a specific mode
function ShowNotificationToMode(mode, message, notificationType)
    -- This would need to be implemented based on how players are tracked per mode
    -- For now, we'll just broadcast to all
    ShowNotificationToAll(message, notificationType)
end

exports('ShowNotificationToAll', ShowNotificationToAll)
exports('ShowNotificationToMode', ShowNotificationToMode)