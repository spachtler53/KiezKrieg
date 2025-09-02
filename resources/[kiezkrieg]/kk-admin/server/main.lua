-- KiezKrieg Admin Server
local ESX = exports["es_extended"]:getSharedObject()

-- Admin duty tracking
local AdminDuty = {}

-- Check if player is admin
function isPlayerAdmin(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    
    for _, group in ipairs(KiezKrieg.Admin.Groups) do
        if xPlayer.getGroup() == group then
            return true
        end
    end
    
    return false
end

-- Toggle admin duty
RegisterNetEvent('kk-admin:toggleDuty')
AddEventHandler('kk-admin:toggleDuty', function()
    local src = source
    
    if not isPlayerAdmin(src) then
        TriggerClientEvent('esx:showNotification', src, '~r~Access denied!')
        return
    end
    
    AdminDuty[src] = not AdminDuty[src]
    
    local xPlayer = ESX.GetPlayerFromId(src)
    TriggerClientEvent('kk-admin:updateDutyStatus', src, AdminDuty[src])
    
    -- Log admin action
    local action = AdminDuty[src] and 'went on duty' or 'went off duty'
    print(string.format("[KiezKrieg Admin] %s (%s) %s", xPlayer.name, xPlayer.identifier, action))
    
    -- Insert into admin logs if database is available
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, details) VALUES (?, ?, ?)', {
        xPlayer.identifier, 'duty_toggle', AdminDuty[src] and 'on' or 'off'
    })
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local src = source
    AdminDuty[src] = nil
end)

-- Request player list
RegisterNetEvent('kk-admin:requestPlayerList')
AddEventHandler('kk-admin:requestPlayerList', function()
    local src = source
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            table.insert(players, {
                id = playerId,
                name = xPlayer.name,
                identifier = xPlayer.identifier
            })
        end
    end
    
    TriggerClientEvent('kk-admin:receivePlayerList', src, players)
end)

-- Goto player
RegisterNetEvent('kk-admin:gotoPlayer')
AddEventHandler('kk-admin:gotoPlayer', function(targetId)
    local src = source
    
    if not AdminDuty[src] then return end
    
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    SetEntityCoords(GetPlayerPed(src), targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
    
    TriggerClientEvent('esx:showNotification', src, '~g~Teleported to ' .. xTarget.name)
    
    -- Log action
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, target_identifier, details) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, 'goto', xTarget.identifier, 'Teleported to player'
    })
end)

-- Bring player
RegisterNetEvent('kk-admin:bringPlayer')
AddEventHandler('kk-admin:bringPlayer', function(targetId)
    local src = source
    
    if not AdminDuty[src] then return end
    
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    local adminCoords = GetEntityCoords(GetPlayerPed(src))
    SetEntityCoords(GetPlayerPed(targetId), adminCoords.x + 1.0, adminCoords.y, adminCoords.z, false, false, false, true)
    
    TriggerClientEvent('esx:showNotification', src, '~g~Brought ' .. xTarget.name)
    TriggerClientEvent('esx:showNotification', targetId, '~y~You were teleported by an admin')
    
    -- Log action
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, target_identifier, details) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, 'bring', xTarget.identifier, 'Brought player to admin'
    })
end)

-- Heal player
RegisterNetEvent('kk-admin:healPlayer')
AddEventHandler('kk-admin:healPlayer', function(targetId)
    local src = source
    
    if not AdminDuty[src] then return end
    
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    TriggerClientEvent('esx_basicneeds:healPlayer', targetId)
    TriggerClientEvent('esx:showNotification', src, '~g~Healed ' .. xTarget.name)
    TriggerClientEvent('esx:showNotification', targetId, '~g~You were healed by an admin')
    
    -- Log action
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, target_identifier, details) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, 'heal', xTarget.identifier, 'Healed player'
    })
end)

-- Kill player
RegisterNetEvent('kk-admin:killPlayer')
AddEventHandler('kk-admin:killPlayer', function(targetId)
    local src = source
    
    if not AdminDuty[src] then return end
    
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    SetEntityHealth(GetPlayerPed(targetId), 0)
    
    TriggerClientEvent('esx:showNotification', src, '~r~Killed ' .. xTarget.name)
    TriggerClientEvent('esx:showNotification', targetId, '~r~You were killed by an admin')
    
    -- Log action
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, target_identifier, details) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, 'kill', xTarget.identifier, 'Killed player'
    })
end)

-- Admin commands
ESX.RegisterCommand('goto', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local targetId = tonumber(args.target)
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /goto [player_id]')
        return
    end
    
    TriggerEvent('kk-admin:gotoPlayer', targetId)
    
end, false, {
    help = 'Teleport to a player',
    validate = false,
    arguments = {
        {name = 'target', help = 'Target player ID', type = 'number'}
    }
})

ESX.RegisterCommand('bring', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local targetId = tonumber(args.target)
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /bring [player_id]')
        return
    end
    
    TriggerEvent('kk-admin:bringPlayer', targetId)
    
end, false, {
    help = 'Bring a player to you',
    validate = false,
    arguments = {
        {name = 'target', help = 'Target player ID', type = 'number'}
    }
})

ESX.RegisterCommand('tpm', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    TriggerClientEvent('kk-admin:teleportToMarker', src)
    
end, false, {help = 'Teleport to map marker'})

ESX.RegisterCommand('heal', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local targetId = tonumber(args.target) or src
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    TriggerEvent('kk-admin:healPlayer', targetId)
    
end, false, {
    help = 'Heal yourself or a player',
    validate = false,
    arguments = {
        {name = 'target', help = 'Target player ID (optional)', type = 'number'}
    }
})

ESX.RegisterCommand('kill', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local targetId = tonumber(args.target)
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    if not targetId then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /kill [player_id]')
        return
    end
    
    TriggerEvent('kk-admin:killPlayer', targetId)
    
end, false, {
    help = 'Kill a player',
    validate = false,
    arguments = {
        {name = 'target', help = 'Target player ID', type = 'number'}
    }
})

ESX.RegisterCommand('givemoney', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local targetId = tonumber(args.target)
    local amount = tonumber(args.amount)
    local moneyType = args.type or 'money'
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    if not targetId or not amount then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /givemoney [player_id] [amount] [type]')
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    if moneyType == 'money' then
        xTarget.addMoney(amount)
    elseif moneyType == 'bank' then
        xTarget.addAccountMoney('bank', amount)
    elseif moneyType == 'black_money' then
        xTarget.addAccountMoney('black_money', amount)
    else
        TriggerClientEvent('esx:showNotification', src, '~r~Invalid money type! Use: money, bank, black_money')
        return
    end
    
    TriggerClientEvent('esx:showNotification', src, 
        string.format('~g~Gave $%d %s to %s', amount, moneyType, xTarget.name))
    TriggerClientEvent('esx:showNotification', targetId, 
        string.format('~g~You received $%d %s from an admin', amount, moneyType))
    
    -- Log action
    MySQL.insert('INSERT INTO kk_admin_logs (admin_identifier, action, target_identifier, details) VALUES (?, ?, ?, ?)', {
        xPlayer.identifier, 'give_money', xTarget.identifier, 
        string.format('Gave $%d %s', amount, moneyType)
    })
    
end, false, {
    help = 'Give money to a player',
    validate = false,
    arguments = {
        {name = 'target', help = 'Target player ID', type = 'number'},
        {name = 'amount', help = 'Amount of money', type = 'number'},
        {name = 'type', help = 'Money type (money, bank, black_money)', type = 'string'}
    }
})

ESX.RegisterCommand('car', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local vehicleName = args.vehicle
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    if not vehicleName then
        TriggerClientEvent('esx:showNotification', src, '~r~Usage: /car [vehicle_name]')
        return
    end
    
    TriggerClientEvent('kk-admin:spawnVehicle', src, vehicleName)
    
end, false, {
    help = 'Spawn a vehicle',
    validate = false,
    arguments = {
        {name = 'vehicle', help = 'Vehicle spawn name', type = 'string'}
    }
})

ESX.RegisterCommand('dv', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    local playerPed = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        DeleteEntity(vehicle)
        TriggerClientEvent('esx:showNotification', src, '~g~Vehicle deleted')
    else
        TriggerClientEvent('esx:showNotification', src, '~r~You are not in a vehicle!')
    end
    
end, false, {help = 'Delete current vehicle'})

-- Get server stats
ESX.RegisterCommand('stats', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    
    if not AdminDuty[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You must be on admin duty!')
        return
    end
    
    local playerCount = #GetPlayers()
    local maxPlayers = GetConvarInt('sv_maxclients', 32)
    
    TriggerClientEvent('chat:addMessage', src, {
        color = {0, 255, 0},
        multiline = true,
        args = {"Server Stats", string.format("Players: %d/%d\nUptime: %s\nResource: KiezKrieg v1.0", 
            playerCount, maxPlayers, "Unknown")}
    })
    
end, false, {help = 'Show server statistics'})

-- Cleanup admin duty on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for src, _ in pairs(AdminDuty) do
            TriggerClientEvent('kk-admin:updateDutyStatus', src, false)
        end
    end
end)

-- Export functions
exports('isPlayerAdmin', isPlayerAdmin)
exports('isPlayerOnDuty', function(src)
    return AdminDuty[src] == true
end)

exports('getAdminDutyList', function()
    local dutyList = {}
    for src, onDuty in pairs(AdminDuty) do
        if onDuty then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                table.insert(dutyList, {
                    id = src,
                    name = xPlayer.name,
                    identifier = xPlayer.identifier
                })
            end
        end
    end
    return dutyList
end)