-- KiezKrieg Factions Server
local ESX = exports["es_extended"]:getSharedObject()

-- Player faction data
local PlayerFactions = {}
local PendingInvitations = {}

-- Initialize
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    loadPlayerFaction(playerId, xPlayer.identifier)
end)

-- Player disconnect cleanup
AddEventHandler('playerDropped', function()
    local src = source
    PlayerFactions[src] = nil
    PendingInvitations[src] = nil
end)

-- Request player faction
RegisterNetEvent('kk-factions:requestPlayerFaction')
AddEventHandler('kk-factions:requestPlayerFaction', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if xPlayer then
        loadPlayerFaction(src, xPlayer.identifier)
    end
end)

-- Create faction
RegisterNetEvent('kk-factions:createFaction')
AddEventHandler('kk-factions:createFaction', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    -- Check if player is already in a faction
    if PlayerFactions[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You are already in a faction!')
        return
    end
    
    -- Validate input
    if not data.name or string.len(data.name) < 3 or string.len(data.name) > 30 then
        TriggerClientEvent('esx:showNotification', src, '~r~Invalid faction name!')
        return
    end
    
    if not data.tag or string.len(data.tag) < 2 or string.len(data.tag) > 6 then
        TriggerClientEvent('esx:showNotification', src, '~r~Invalid faction tag!')
        return
    end
    
    -- Check if player has enough money
    if xPlayer.getMoney() < KiezKrieg.Factions.Settings.CREATION_COST then
        TriggerClientEvent('esx:showNotification', src, 
            '~r~You need $' .. KiezKrieg.Factions.Settings.CREATION_COST .. ' to create a faction!')
        return
    end
    
    -- Check if name/tag already exists
    MySQL.scalar('SELECT id FROM kk_factions WHERE name = ? OR tag = ?', {
        data.name, data.tag
    }, function(existing)
        if existing then
            TriggerClientEvent('esx:showNotification', src, '~r~Faction name or tag already exists!')
            return
        end
        
        -- Create faction
        MySQL.insert('INSERT INTO kk_factions (name, tag, description, leader_identifier, color) VALUES (?, ?, ?, ?, ?)', {
            data.name,
            data.tag,
            data.description or '',
            xPlayer.identifier,
            KiezKrieg.Factions.Colors[math.random(1, #KiezKrieg.Factions.Colors)]
        }, function(factionId)
            if factionId then
                -- Add creator as leader
                MySQL.insert('INSERT INTO kk_faction_members (faction_id, identifier, rank) VALUES (?, ?, ?)', {
                    factionId, xPlayer.identifier, 'Leader'
                }, function(memberId)
                    if memberId then
                        -- Remove money
                        xPlayer.removeMoney(KiezKrieg.Factions.Settings.CREATION_COST)
                        
                        -- Load faction for player
                        loadPlayerFaction(src, xPlayer.identifier)
                        
                        TriggerClientEvent('esx:showNotification', src, 
                            '~g~Faction created successfully! Welcome to [' .. data.tag .. '] ' .. data.name)
                        
                        -- Log creation
                        print(string.format("[KiezKrieg Factions] Player %s created faction '%s' [%s]", 
                            xPlayer.name, data.name, data.tag))
                    else
                        TriggerClientEvent('esx:showNotification', src, '~r~Failed to create faction membership!')
                    end
                end)
            else
                TriggerClientEvent('esx:showNotification', src, '~r~Failed to create faction!')
            end
        end)
    end)
end)

-- Invite player to faction
RegisterNetEvent('kk-factions:invitePlayer')
AddEventHandler('kk-factions:invitePlayer', function(targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer or not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Player not found!')
        return
    end
    
    -- Check if inviter is in faction and has permission
    if not PlayerFactions[src] or not hasFactionPermission(src, 'invite') then
        TriggerClientEvent('esx:showNotification', src, '~r~You don\'t have permission to invite players!')
        return
    end
    
    -- Check if target is already in a faction
    if PlayerFactions[targetId] then
        TriggerClientEvent('esx:showNotification', src, '~r~Player is already in a faction!')
        return
    end
    
    -- Check if target already has pending invitation
    if PendingInvitations[targetId] then
        TriggerClientEvent('esx:showNotification', src, '~r~Player already has a pending invitation!')
        return
    end
    
    -- Send invitation
    local faction = PlayerFactions[src]
    PendingInvitations[targetId] = {
        factionId = faction.id,
        inviterSrc = src,
        timestamp = os.time()
    }
    
    TriggerClientEvent('kk-factions:receiveInvitation', targetId, 
        faction.name, faction.tag, xPlayer.name)
    
    TriggerClientEvent('esx:showNotification', src, 
        '~g~Invitation sent to ' .. xTarget.name)
    
    TriggerClientEvent('esx:showNotification', targetId, 
        '~y~You received a faction invitation from ' .. xPlayer.name)
end)

-- Accept invitation
RegisterNetEvent('kk-factions:acceptInvitation')
AddEventHandler('kk-factions:acceptInvitation', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not PendingInvitations[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~No pending invitation!')
        return
    end
    
    local invitation = PendingInvitations[src]
    PendingInvitations[src] = nil
    
    -- Add to faction
    MySQL.insert('INSERT INTO kk_faction_members (faction_id, identifier, rank) VALUES (?, ?, ?)', {
        invitation.factionId, xPlayer.identifier, 'Member'
    }, function(memberId)
        if memberId then
            loadPlayerFaction(src, xPlayer.identifier)
            
            -- Notify inviter
            if invitation.inviterSrc and GetPlayerName(invitation.inviterSrc) then
                TriggerClientEvent('esx:showNotification', invitation.inviterSrc, 
                    '~g~' .. xPlayer.name .. ' joined your faction!')
            end
        else
            TriggerClientEvent('esx:showNotification', src, '~r~Failed to join faction!')
        end
    end)
end)

-- Decline invitation
RegisterNetEvent('kk-factions:declineInvitation')
AddEventHandler('kk-factions:declineInvitation', function()
    local src = source
    PendingInvitations[src] = nil
end)

-- Leave faction
RegisterNetEvent('kk-factions:leaveFaction')
AddEventHandler('kk-factions:leaveFaction', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or not PlayerFactions[src] then
        TriggerClientEvent('esx:showNotification', src, '~r~You are not in a faction!')
        return
    end
    
    local faction = PlayerFactions[src]
    
    -- Check if player is leader
    if faction.rank == 'Leader' then
        -- Check if there are other members
        MySQL.scalar('SELECT COUNT(*) FROM kk_faction_members WHERE faction_id = ?', {
            faction.id
        }, function(memberCount)
            if memberCount > 1 then
                TriggerClientEvent('esx:showNotification', src, 
                    '~r~You cannot leave as leader! Transfer leadership or disband the faction.')
                return
            else
                -- Disband faction if leader is the only member
                disbandFaction(faction.id, src)
            end
        end)
    else
        -- Remove member
        MySQL.update('DELETE FROM kk_faction_members WHERE faction_id = ? AND identifier = ?', {
            faction.id, xPlayer.identifier
        }, function(affectedRows)
            if affectedRows > 0 then
                PlayerFactions[src] = nil
                TriggerClientEvent('kk-factions:updatePlayerFaction', src, nil)
                TriggerClientEvent('esx:showNotification', src, '~r~You left the faction')
            end
        end)
    end
end)

-- Request member list
RegisterNetEvent('kk-factions:requestMemberList')
AddEventHandler('kk-factions:requestMemberList', function()
    local src = source
    
    if not PlayerFactions[src] then
        return
    end
    
    local factionId = PlayerFactions[src].id
    
    MySQL.query('SELECT fm.identifier, fm.rank, fm.joined_at FROM kk_faction_members fm WHERE fm.faction_id = ?', {
        factionId
    }, function(members)
        local memberList = {}
        
        for _, member in ipairs(members) do
            -- Get player name (simplified for now)
            local memberName = 'Unknown'
            local isOnline = false
            
            -- Check if player is online
            for _, playerId in ipairs(GetPlayers()) do
                local xPlayer = ESX.GetPlayerFromId(playerId)
                if xPlayer and xPlayer.identifier == member.identifier then
                    memberName = xPlayer.name
                    isOnline = true
                    break
                end
            end
            
            table.insert(memberList, {
                identifier = member.identifier,
                name = memberName,
                rank = member.rank,
                joined_at = member.joined_at,
                is_online = isOnline
            })
        end
        
        TriggerClientEvent('kk-factions:receiveMemberList', src, memberList)
    end)
end)

-- Request public factions
RegisterNetEvent('kk-factions:requestPublicFactions')
AddEventHandler('kk-factions:requestPublicFactions', function()
    local src = source
    
    MySQL.query([[
        SELECT f.id, f.name, f.tag, f.description, f.max_members,
               COUNT(fm.id) as member_count
        FROM kk_factions f
        LEFT JOIN kk_faction_members fm ON f.id = fm.faction_id
        WHERE f.is_private = 0
        GROUP BY f.id
        ORDER BY member_count DESC
        LIMIT 20
    ]], {}, function(factions)
        TriggerClientEvent('kk-factions:receivePublicFactions', src, factions)
    end)
end)

-- Helper functions
function loadPlayerFaction(src, identifier)
    MySQL.query([[
        SELECT f.*, fm.rank, 
               (SELECT COUNT(*) FROM kk_faction_members fm2 WHERE fm2.faction_id = f.id) as member_count,
               (SELECT name FROM users WHERE identifier = f.leader_identifier) as leader_name
        FROM kk_factions f
        JOIN kk_faction_members fm ON f.id = fm.faction_id
        WHERE fm.identifier = ?
    ]], {identifier}, function(result)
        if result and result[1] then
            local faction = result[1]
            
            -- Get rank level
            faction.rank_level = getRankLevel(faction.rank)
            
            PlayerFactions[src] = faction
            TriggerClientEvent('kk-factions:updatePlayerFaction', src, faction)
        else
            PlayerFactions[src] = nil
            TriggerClientEvent('kk-factions:updatePlayerFaction', src, nil)
        end
    end)
end

function hasFactionPermission(src, permission)
    if not PlayerFactions[src] then
        return false
    end
    
    local rankLevel = PlayerFactions[src].rank_level
    
    for _, rank in ipairs(KiezKrieg.Factions.Ranks) do
        if rank.level == rankLevel then
            for _, perm in ipairs(rank.permissions) do
                if perm == permission then
                    return true
                end
            end
            break
        end
    end
    
    return false
end

function getRankLevel(rankName)
    for _, rank in ipairs(KiezKrieg.Factions.Ranks) do
        if rank.name == rankName then
            return rank.level
        end
    end
    return 1 -- Default to member level
end

function disbandFaction(factionId, leaderSrc)
    -- Delete all members
    MySQL.update('DELETE FROM kk_faction_members WHERE faction_id = ?', {factionId})
    
    -- Delete faction
    MySQL.update('DELETE FROM kk_factions WHERE id = ?', {factionId}, function(affectedRows)
        if affectedRows > 0 then
            PlayerFactions[leaderSrc] = nil
            TriggerClientEvent('kk-factions:updatePlayerFaction', leaderSrc, nil)
            TriggerClientEvent('esx:showNotification', leaderSrc, '~r~Faction disbanded')
        end
    end)
end

-- Cleanup old invitations
Citizen.CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.time()
        for playerId, invitation in pairs(PendingInvitations) do
            if currentTime - invitation.timestamp > 300 then -- 5 minutes timeout
                PendingInvitations[playerId] = nil
            end
        end
    end
end)

-- Admin commands
ESX.RegisterCommand('createfaction', 'admin', function(xPlayer, args, showError)
    local src = xPlayer.source
    local name = args.name
    local tag = args.tag
    local targetId = tonumber(args.target)
    
    if not name or not tag or not targetId then
        TriggerClientEvent('esx:showNotification', src, 
            '~r~Usage: /createfaction [name] [tag] [target_id]')
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('esx:showNotification', src, '~r~Target player not found!')
        return
    end
    
    -- Create faction for target player
    MySQL.insert('INSERT INTO kk_factions (name, tag, leader_identifier, color) VALUES (?, ?, ?, ?)', {
        name, tag, xTarget.identifier,
        KiezKrieg.Factions.Colors[math.random(1, #KiezKrieg.Factions.Colors)]
    }, function(factionId)
        if factionId then
            MySQL.insert('INSERT INTO kk_faction_members (faction_id, identifier, rank) VALUES (?, ?, ?)', {
                factionId, xTarget.identifier, 'Leader'
            }, function(memberId)
                if memberId then
                    loadPlayerFaction(targetId, xTarget.identifier)
                    TriggerClientEvent('esx:showNotification', src, 
                        '~g~Created faction [' .. tag .. '] ' .. name .. ' for ' .. xTarget.name)
                    TriggerClientEvent('esx:showNotification', targetId, 
                        '~g~You were given leadership of faction [' .. tag .. '] ' .. name)
                end
            end)
        end
    end)
    
end, false, {
    help = 'Create faction for a player',
    validate = false,
    arguments = {
        {name = 'name', help = 'Faction name', type = 'string'},
        {name = 'tag', help = 'Faction tag', type = 'string'},
        {name = 'target', help = 'Target player ID', type = 'number'}
    }
})

-- Export functions
exports('getPlayerFaction', function(src)
    return PlayerFactions[src]
end)

exports('isPlayerInFaction', function(src)
    return PlayerFactions[src] ~= nil
end)

exports('hasFactionPermission', hasFactionPermission)