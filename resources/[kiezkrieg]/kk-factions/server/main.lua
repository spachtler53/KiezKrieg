ESX = exports['es_extended']:getSharedObject()

-- Variables
local playerFactions = {}

-- Events
RegisterServerEvent('kk-factions:requestFactionInfo')
AddEventHandler('kk-factions:requestFactionInfo', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    GetPlayerFaction(xPlayer.identifier, function(faction)
        TriggerClientEvent('kk-factions:factionInfoReceived', source, faction)
    end)
end)

RegisterServerEvent('kk-factions:createFaction')
AddEventHandler('kk-factions:createFaction', function(factionName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Validate faction name
    if string.len(factionName) < Config.Factions.minNameLength or string.len(factionName) > Config.Factions.maxNameLength then
        TriggerClientEvent('esx:showNotification', source, '~r~Faction name must be between ' .. Config.Factions.minNameLength .. ' and ' .. Config.Factions.maxNameLength .. ' characters')
        return
    end
    
    -- Check if player is already in a faction
    GetPlayerFaction(xPlayer.identifier, function(existingFaction)
        if existingFaction then
            TriggerClientEvent('esx:showNotification', source, '~r~You are already in a faction')
            return
        end
        
        -- Check if faction name already exists
        MySQL.query('SELECT id FROM kk_factions WHERE name = ?', {factionName}, function(result)
            if result[1] then
                TriggerClientEvent('esx:showNotification', source, '~r~Faction name already exists')
                return
            end
            
            -- Create faction
            MySQL.insert('INSERT INTO kk_factions (name, leader, members, faction_type) VALUES (?, ?, ?, ?)', {
                factionName,
                xPlayer.identifier,
                json.encode({
                    [xPlayer.identifier] = {
                        name = xPlayer.getName(),
                        rank = 5, -- Leader
                        joined = os.time()
                    }
                }),
                'private'
            }, function(insertId)
                if insertId then
                    local faction = {
                        id = insertId,
                        name = factionName,
                        leader = xPlayer.identifier,
                        faction_type = 'private',
                        members = {
                            [xPlayer.identifier] = {
                                name = xPlayer.getName(),
                                rank = 5,
                                joined = os.time()
                            }
                        }
                    }
                    
                    playerFactions[source] = faction
                    TriggerClientEvent('kk-factions:factionJoined', source, faction)
                    print('[KK-Factions] ' .. xPlayer.getName() .. ' created faction: ' .. factionName)
                else
                    TriggerClientEvent('esx:showNotification', source, '~r~Failed to create faction')
                end
            end)
        end)
    end)
end)

RegisterServerEvent('kk-factions:invitePlayer')
AddEventHandler('kk-factions:invitePlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer or not xTarget then
        TriggerClientEvent('esx:showNotification', source, '~r~Player not found')
        return
    end
    
    -- Check if inviter is in a faction and has permission
    GetPlayerFaction(xPlayer.identifier, function(faction)
        if not faction then
            TriggerClientEvent('esx:showNotification', source, '~r~You are not in a faction')
            return
        end
        
        local member = faction.members[xPlayer.identifier]
        if not member or member.rank < 2 then -- Need at least Veteran rank
            TriggerClientEvent('esx:showNotification', source, '~r~You do not have permission to invite players')
            return
        end
        
        -- Check if target is already in a faction
        GetPlayerFaction(xTarget.identifier, function(targetFaction)
            if targetFaction then
                TriggerClientEvent('esx:showNotification', source, '~r~Player is already in a faction')
                return
            end
            
            -- Send invite
            TriggerClientEvent('kk-factions:factionInviteReceived', targetId, faction.name, source)
            TriggerClientEvent('esx:showNotification', source, '~g~Invite sent to ' .. xTarget.getName())
        end)
    end)
end)

RegisterServerEvent('kk-factions:acceptInvite')
AddEventHandler('kk-factions:acceptInvite', function(factionName, inviterId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xInviter = ESX.GetPlayerFromId(inviterId)
    
    if not xPlayer or not xInviter then return end
    
    -- Check if player is already in a faction
    GetPlayerFaction(xPlayer.identifier, function(existingFaction)
        if existingFaction then
            TriggerClientEvent('esx:showNotification', source, '~r~You are already in a faction')
            return
        end
        
        -- Get faction info
        MySQL.query('SELECT * FROM kk_factions WHERE name = ?', {factionName}, function(result)
            if not result[1] then
                TriggerClientEvent('esx:showNotification', source, '~r~Faction not found')
                return
            end
            
            local factionData = result[1]
            local members = json.decode(factionData.members) or {}
            
            -- Check if faction is full
            local memberCount = 0
            for _ in pairs(members) do memberCount = memberCount + 1 end
            
            if memberCount >= Config.Factions.maxMembers then
                TriggerClientEvent('esx:showNotification', source, '~r~Faction is full')
                return
            end
            
            -- Add player to faction
            members[xPlayer.identifier] = {
                name = xPlayer.getName(),
                rank = 1, -- Member
                joined = os.time()
            }
            
            MySQL.update('UPDATE kk_factions SET members = ? WHERE id = ?', {
                json.encode(members),
                factionData.id
            }, function(affectedRows)
                if affectedRows > 0 then
                    local faction = {
                        id = factionData.id,
                        name = factionData.name,
                        leader = factionData.leader,
                        faction_type = factionData.faction_type,
                        members = members
                    }
                    
                    playerFactions[source] = faction
                    TriggerClientEvent('kk-factions:factionJoined', source, faction)
                    TriggerClientEvent('esx:showNotification', inviterId, '~g~' .. xPlayer.getName() .. ' joined your faction')
                else
                    TriggerClientEvent('esx:showNotification', source, '~r~Failed to join faction')
                end
            end)
        end)
    end)
end)

RegisterServerEvent('kk-factions:leaveFaction')
AddEventHandler('kk-factions:leaveFaction', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    GetPlayerFaction(xPlayer.identifier, function(faction)
        if not faction then
            TriggerClientEvent('esx:showNotification', source, '~r~You are not in a faction')
            return
        end
        
        -- Remove player from faction
        faction.members[xPlayer.identifier] = nil
        
        MySQL.update('UPDATE kk_factions SET members = ? WHERE id = ?', {
            json.encode(faction.members),
            faction.id
        }, function(affectedRows)
            if affectedRows > 0 then
                playerFactions[source] = nil
                TriggerClientEvent('kk-factions:factionLeft', source)
            end
        end)
    end)
end)

-- Functions
function GetPlayerFaction(identifier, callback)
    MySQL.query('SELECT * FROM kk_factions WHERE JSON_CONTAINS_PATH(members, "one", ?)', {
        '$.' .. identifier
    }, function(result)
        if result[1] then
            local faction = result[1]
            faction.members = json.decode(faction.members) or {}
            callback(faction)
        else
            callback(nil)
        end
    end)
end

-- Player disconnect cleanup
AddEventHandler('playerDropped', function(reason)
    local source = source
    playerFactions[source] = nil
end)

-- Export functions
exports('GetPlayerFaction', GetPlayerFaction)
exports('GetAllFactions', function(callback)
    MySQL.query('SELECT * FROM kk_factions', {}, callback)
end)