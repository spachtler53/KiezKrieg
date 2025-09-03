-- KiezKrieg Admin Server
ESX = exports['es_extended']:getSharedObject()

-- Admin variables
local AdminPlayers = {}
local AdminVehicles = {}

-- Check if player has admin permissions
function IsPlayerAdmin(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local playerGroup = xPlayer.getGroup()
    for _, group in ipairs(Config.Admin.groups) do
        if playerGroup == group then
            return true
        end
    end
    return false
end

-- Admin duty system
RegisterCommand('aduty', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(source, 0)
    
    if AdminPlayers[identifier] then
        -- Go off duty
        AdminPlayers[identifier] = nil
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You are now off admin duty', 'info')
        TriggerClientEvent('kk-admin:setDutyStatus', source, false)
    else
        -- Go on duty
        AdminPlayers[identifier] = {
            playerId = source,
            identifier = identifier,
            onDutyTime = GetGameTimer()
        }
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You are now on admin duty', 'success')
        TriggerClientEvent('kk-admin:setDutyStatus', source, true)
    end
end, false)

-- Teleport to player
RegisterCommand('goto', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Usage: /goto [player_id]', 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player not found', 'error')
        return
    end
    
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    TriggerClientEvent('kk-admin:teleportToCoords', source, targetCoords)
    exports['kk-ui']:ShowNotificationToPlayer(source, 'Teleported to player ' .. targetId, 'success')
end, false)

-- Teleport to marker
RegisterCommand('tpm', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    TriggerClientEvent('kk-admin:teleportToMarker', source)
end, false)

-- Bring player
RegisterCommand('bring', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Usage: /bring [player_id]', 'error')
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player not found', 'error')
        return
    end
    
    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('kk-admin:teleportToCoords', targetId, adminCoords)
    exports['kk-ui']:ShowNotificationToPlayer(source, 'Brought player ' .. targetId, 'success')
    exports['kk-ui']:ShowNotificationToPlayer(targetId, 'You have been teleported by an admin', 'info')
end, false)

-- Spawn vehicle
RegisterCommand('vehicle', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local vehicleName = args[1]
    if not vehicleName then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Usage: /vehicle [vehicle_name]', 'error')
        return
    end
    
    TriggerClientEvent('kk-admin:spawnVehicle', source, vehicleName)
end, false)

-- Delete vehicle
RegisterCommand('dv', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    TriggerClientEvent('kk-admin:deleteVehicle', source)
end, false)

-- Toggle nametags
RegisterCommand('nametags', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    TriggerClientEvent('kk-admin:toggleNametags', source)
end, false)

-- Faction management
RegisterCommand('createfaction', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local factionName = args[1]
    local factionLabel = table.concat(args, ' ', 2)
    
    if not factionName or not factionLabel then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Usage: /createfaction [name] [label]', 'error')
        return
    end
    
    local identifier = GetPlayerIdentifier(source, 0)
    CreateFaction(source, factionName, factionLabel, identifier)
end, false)

RegisterCommand('deletefaction', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You do not have permission to use this command', 'error')
        return
    end
    
    local factionName = args[1]
    if not factionName then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Usage: /deletefaction [name]', 'error')
        return
    end
    
    DeleteFaction(source, factionName)
end, false)

-- Faction creation
function CreateFaction(adminId, name, label, leaderIdentifier)
    MySQL.Async.fetchAll('SELECT * FROM kk_factions WHERE name = @name', {
        ['@name'] = name
    }, function(result)
        if result[1] then
            exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Faction already exists', 'error')
            return
        end
        
        MySQL.Async.execute('INSERT INTO kk_factions (name, label, leader_identifier) VALUES (@name, @label, @leader)', {
            ['@name'] = name,
            ['@label'] = label,
            ['@leader'] = leaderIdentifier
        }, function(insertId)
            if insertId then
                -- Add leader as member
                MySQL.Async.execute('INSERT INTO kk_faction_members (faction_id, identifier, rank) VALUES (@faction_id, @identifier, @rank)', {
                    ['@faction_id'] = insertId,
                    ['@identifier'] = leaderIdentifier,
                    ['@rank'] = 'leader'
                })
                
                exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Faction "' .. label .. '" created successfully', 'success')
                
                -- Notify faction system
                TriggerEvent('kk-factions:factionCreated', insertId, name, label, leaderIdentifier)
            else
                exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Failed to create faction', 'error')
            end
        end)
    end)
end

-- Faction deletion
function DeleteFaction(adminId, name)
    MySQL.Async.fetchAll('SELECT * FROM kk_factions WHERE name = @name', {
        ['@name'] = name
    }, function(result)
        if not result[1] then
            exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Faction not found', 'error')
            return
        end
        
        local factionId = result[1].id
        
        MySQL.Async.execute('DELETE FROM kk_factions WHERE id = @id', {
            ['@id'] = factionId
        }, function(affectedRows)
            if affectedRows > 0 then
                exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Faction deleted successfully', 'success')
                
                -- Notify faction system
                TriggerEvent('kk-factions:factionDeleted', factionId, name)
            else
                exports['kk-ui']:ShowNotificationToPlayer(adminId, 'Failed to delete faction', 'error')
            end
        end)
    end)
end

-- Get online admins
RegisterServerEvent('kk-admin:getOnlineAdmins')
AddEventHandler('kk-admin:getOnlineAdmins', function()
    local source = source
    local onlineAdmins = {}
    
    for identifier, adminData in pairs(AdminPlayers) do
        local xPlayer = ESX.GetPlayerFromId(adminData.playerId)
        if xPlayer then
            table.insert(onlineAdmins, {
                identifier = identifier,
                playerId = adminData.playerId,
                playerName = xPlayer.getName(),
                onDutyTime = adminData.onDutyTime
            })
        end
    end
    
    TriggerClientEvent('kk-admin:receiveOnlineAdmins', source, onlineAdmins)
end)

-- Player disconnect handler
AddEventHandler('esx:playerDropped', function(playerId, reason)
    local identifier = GetPlayerIdentifier(playerId, 0)
    if AdminPlayers[identifier] then
        AdminPlayers[identifier] = nil
    end
    
    -- Clean up admin vehicles
    if AdminVehicles[playerId] then
        for _, vehicle in ipairs(AdminVehicles[playerId]) do
            DeleteEntity(vehicle)
        end
        AdminVehicles[playerId] = nil
    end
end)

-- Export functions
exports('IsPlayerAdmin', IsPlayerAdmin)
exports('IsPlayerOnDuty', function(playerId)
    local identifier = GetPlayerIdentifier(playerId, 0)
    return AdminPlayers[identifier] ~= nil
end)

exports('GetOnlineDutyAdmins', function()
    return AdminPlayers
end)

-- Admin menu permission check
RegisterServerEvent('kk-admin:checkPermissions')
AddEventHandler('kk-admin:checkPermissions', function()
    local source = source
    
    if IsPlayerAdmin(source) then
        TriggerClientEvent('kk-admin:permissionGranted', source)
    else
        TriggerClientEvent('kk-admin:permissionDenied', source)
    end
end)