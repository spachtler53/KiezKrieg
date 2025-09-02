ESX = exports['es_extended']:getSharedObject()

-- Variables
local playersOnDuty = {}

-- Check admin permissions
function IsPlayerAdmin(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    for _, group in pairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    return false
end

-- Admin Commands Registration
for command, data in pairs(Config.Commands) do
    RegisterCommand(data.name, function(source, args, rawCommand)
        if not IsPlayerAdmin(source) then
            TriggerClientEvent('esx:showNotification', source, '~r~Access denied')
            return
        end
        
        HandleAdminCommand(source, data.name, args)
    end, false)
end

-- Handle admin commands
function HandleAdminCommand(source, command, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if command == 'aduty' then
        ToggleAdminDuty(source)
    elseif command == 'goto' then
        local targetId = tonumber(args[1])
        if targetId then
            TeleportToPlayer(source, targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Usage: /goto [player_id]')
        end
    elseif command == 'bring' then
        local targetId = tonumber(args[1])
        if targetId then
            BringPlayer(source, targetId)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Usage: /bring [player_id]')
        end
    elseif command == 'createfaction' then
        local factionName = table.concat(args, ' ')
        if factionName and factionName ~= '' then
            CreateFaction(source, factionName)
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Usage: /createfaction [faction_name]')
        end
    end
end

-- Admin Events
RegisterServerEvent('kk-admin:toggleDuty')
AddEventHandler('kk-admin:toggleDuty', function()
    ToggleAdminDuty(source)
end)

RegisterServerEvent('kk-admin:gotoPlayer')
AddEventHandler('kk-admin:gotoPlayer', function(targetId)
    if IsPlayerAdmin(source) then
        TeleportToPlayer(source, targetId)
    end
end)

RegisterServerEvent('kk-admin:bringPlayer')
AddEventHandler('kk-admin:bringPlayer', function(targetId)
    if IsPlayerAdmin(source) then
        BringPlayer(source, targetId)
    end
end)

-- Admin Functions
function ToggleAdminDuty(playerId)
    if not IsPlayerAdmin(playerId) then return end
    
    playersOnDuty[playerId] = not playersOnDuty[playerId]
    TriggerClientEvent('kk-admin:dutyToggled', playerId, playersOnDuty[playerId])
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if playersOnDuty[playerId] then
        print('[KK-Admin] ' .. xPlayer.getName() .. ' went on admin duty')
    else
        print('[KK-Admin] ' .. xPlayer.getName() .. ' went off admin duty')
    end
end

function TeleportToPlayer(adminId, targetId)
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', adminId, '~r~Player not found')
        return
    end
    
    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('kk-admin:teleportToPlayer', adminId, targetCoords)
end

function BringPlayer(adminId, targetId)
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
        TriggerClientEvent('esx:showNotification', adminId, '~r~Player not found')
        return
    end
    
    local adminPed = GetPlayerPed(adminId)
    local adminCoords = GetEntityCoords(adminPed)
    
    TriggerClientEvent('kk-admin:playerBrought', targetId, adminCoords)
    TriggerClientEvent('esx:showNotification', adminId, '~g~Player brought to you')
end

function CreateFaction(adminId, factionName)
    local xPlayer = ESX.GetPlayerFromId(adminId)
    if not xPlayer then return end
    
    -- Check if faction name already exists
    MySQL.query('SELECT id FROM kk_factions WHERE name = ?', {
        factionName
    }, function(result)
        if result[1] then
            TriggerClientEvent('esx:showNotification', adminId, '~r~Faction name already exists')
            return
        end
        
        -- Create new faction
        MySQL.insert('INSERT INTO kk_factions (name, leader, members) VALUES (?, ?, ?)', {
            factionName,
            xPlayer.identifier,
            json.encode({xPlayer.identifier})
        }, function(insertId)
            if insertId then
                TriggerClientEvent('esx:showNotification', adminId, '~g~Faction "' .. factionName .. '" created successfully')
                print('[KK-Admin] ' .. xPlayer.getName() .. ' created faction: ' .. factionName)
            else
                TriggerClientEvent('esx:showNotification', adminId, '~r~Failed to create faction')
            end
        end)
    end)
end

-- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local source = source
    playersOnDuty[source] = nil
end)

-- Export functions
exports('IsPlayerAdmin', IsPlayerAdmin)
exports('IsPlayerOnDuty', function(playerId)
    return playersOnDuty[playerId] or false
end)
exports('GetAdminsOnDuty', function()
    return playersOnDuty
end)