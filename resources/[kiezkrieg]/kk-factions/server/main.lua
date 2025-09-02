-- KiezKrieg Faction System Server
ESX = exports['es_extended']:getSharedObject()

-- Faction variables
local Factions = {}
local FactionMembers = {}
local FactionInvites = {}

-- Initialize faction system
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait for other resources
    LoadFactions()
    LoadFactionMembers()
    print('[KiezKrieg] Faction system initialized')
end)

-- Load factions from database
function LoadFactions()
    MySQL.Async.fetchAll('SELECT * FROM kk_factions', {}, function(result)
        for _, faction in pairs(result) do
            Factions[faction.id] = {
                id = faction.id,
                name = faction.name,
                label = faction.label,
                leaderIdentifier = faction.leader_identifier,
                color = faction.color,
                isOpenWorld = faction.is_open_world == 1,
                maxMembers = faction.max_members,
                createdAt = faction.created_at,
                members = {}
            }
        end
        print('[KiezKrieg] Loaded ' .. #result .. ' factions')
    end)
end

-- Load faction members
function LoadFactionMembers()
    MySQL.Async.fetchAll('SELECT * FROM kk_faction_members', {}, function(result)
        for _, member in pairs(result) do
            if Factions[member.faction_id] then
                Factions[member.faction_id].members[member.identifier] = {
                    identifier = member.identifier,
                    rank = member.rank,
                    joinedAt = member.joined_at
                }
                
                FactionMembers[member.identifier] = {
                    factionId = member.faction_id,
                    rank = member.rank
                }
            end
        end
        print('[KiezKrieg] Loaded faction members')
    end)
end

-- Server Events
RegisterServerEvent('kk-factions:getFactionData')
AddEventHandler('kk-factions:getFactionData', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    local playerFaction = nil
    if FactionMembers[identifier] then
        local factionId = FactionMembers[identifier].factionId
        playerFaction = Factions[factionId]
    end
    
    TriggerClientEvent('kk-factions:receiveFactionData', source, playerFaction, Factions)
end)

RegisterServerEvent('kk-factions:invitePlayer')
AddEventHandler('kk-factions:invitePlayer', function(targetPlayerId)
    local source = source
    local inviterIdentifier = GetPlayerIdentifier(source, 0)
    local targetIdentifier = GetPlayerIdentifier(targetPlayerId, 0)
    
    if not targetIdentifier then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player not found', 'error')
        return
    end
    
    -- Check if inviter is faction leader
    local inviterFaction = FactionMembers[inviterIdentifier]
    if not inviterFaction or Factions[inviterFaction.factionId].leaderIdentifier ~= inviterIdentifier then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Only faction leaders can invite players', 'error')
        return
    end
    
    -- Check if target is already in a faction
    if FactionMembers[targetIdentifier] then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player is already in a faction', 'error')
        return
    end
    
    -- Check if target already has a pending invite
    if FactionInvites[targetIdentifier] then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player already has a pending invite', 'error')
        return
    end
    
    local faction = Factions[inviterFaction.factionId]
    
    -- Check faction capacity
    local memberCount = 0
    for _ in pairs(faction.members) do
        memberCount = memberCount + 1
    end
    
    if memberCount >= faction.maxMembers then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Faction is full', 'error')
        return
    end
    
    -- Create invite
    FactionInvites[targetIdentifier] = {
        factionId = inviterFaction.factionId,
        inviterIdentifier = inviterIdentifier,
        timestamp = GetGameTimer()
    }
    
    -- Notify players
    local inviterName = GetPlayerName(source)
    local targetName = GetPlayerName(targetPlayerId)
    
    exports['kk-ui']:ShowNotificationToPlayer(source, 'Invited ' .. targetName .. ' to ' .. faction.label, 'success')
    exports['kk-ui']:ShowNotificationToPlayer(targetPlayerId, inviterName .. ' invited you to join ' .. faction.label, 'info')
    
    TriggerClientEvent('kk-factions:receiveInvite', targetPlayerId, faction, inviterName)
end)

RegisterServerEvent('kk-factions:respondToInvite')
AddEventHandler('kk-factions:respondToInvite', function(accept)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    local invite = FactionInvites[identifier]
    if not invite then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'No pending invite found', 'error')
        return
    end
    
    local faction = Factions[invite.factionId]
    if not faction then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Faction no longer exists', 'error')
        FactionInvites[identifier] = nil
        return
    end
    
    if accept then
        -- Join faction
        JoinFaction(source, identifier, invite.factionId)
        
        -- Notify faction leader
        for playerId = 0, GetNumPlayerIndices() - 1 do
            local playerSource = GetPlayerFromIndex(playerId)
            if playerSource and GetPlayerIdentifier(playerSource, 0) == invite.inviterIdentifier then
                local playerName = GetPlayerName(source)
                exports['kk-ui']:ShowNotificationToPlayer(playerSource, playerName .. ' joined the faction!', 'success')
                break
            end
        end
    else
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Faction invite declined', 'info')
    end
    
    -- Clean up invite
    FactionInvites[identifier] = nil
end)

RegisterServerEvent('kk-factions:leaveFaction')
AddEventHandler('kk-factions:leaveFaction', function()
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not FactionMembers[identifier] then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You are not in a faction', 'error')
        return
    end
    
    LeaveFaction(source, identifier)
end)

RegisterServerEvent('kk-factions:kickMember')
AddEventHandler('kk-factions:kickMember', function(targetIdentifier)
    local source = source
    local leaderIdentifier = GetPlayerIdentifier(source, 0)
    
    local leaderFaction = FactionMembers[leaderIdentifier]
    if not leaderFaction then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You are not in a faction', 'error')
        return
    end
    
    local faction = Factions[leaderFaction.factionId]
    if faction.leaderIdentifier ~= leaderIdentifier then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Only faction leaders can kick members', 'error')
        return
    end
    
    if targetIdentifier == leaderIdentifier then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'You cannot kick yourself', 'error')
        return
    end
    
    if not FactionMembers[targetIdentifier] or FactionMembers[targetIdentifier].factionId ~= leaderFaction.factionId then
        exports['kk-ui']:ShowNotificationToPlayer(source, 'Player is not in your faction', 'error')
        return
    end
    
    -- Find target player
    local targetPlayerId = nil
    for playerId = 0, GetNumPlayerIndices() - 1 do
        local playerSource = GetPlayerFromIndex(playerId)
        if playerSource and GetPlayerIdentifier(playerSource, 0) == targetIdentifier then
            targetPlayerId = playerSource
            break
        end
    end
    
    if targetPlayerId then
        LeaveFaction(targetPlayerId, targetIdentifier)
        exports['kk-ui']:ShowNotificationToPlayer(targetPlayerId, 'You have been kicked from the faction', 'error')
    else
        -- Player is offline, just remove from database
        MySQL.Async.execute('DELETE FROM kk_faction_members WHERE identifier = @identifier', {
            ['@identifier'] = targetIdentifier
        })
        
        -- Update in-memory data
        if Factions[leaderFaction.factionId].members[targetIdentifier] then
            Factions[leaderFaction.factionId].members[targetIdentifier] = nil
        end
        FactionMembers[targetIdentifier] = nil
    end
    
    exports['kk-ui']:ShowNotificationToPlayer(source, 'Member kicked from faction', 'success')
end)

-- Join faction function
function JoinFaction(playerId, identifier, factionId)
    local faction = Factions[factionId]
    if not faction then return end
    
    -- Add to database
    MySQL.Async.execute('INSERT INTO kk_faction_members (faction_id, identifier, rank) VALUES (@faction_id, @identifier, @rank)', {
        ['@faction_id'] = factionId,
        ['@identifier'] = identifier,
        ['@rank'] = 'member'
    })
    
    -- Update in-memory data
    faction.members[identifier] = {
        identifier = identifier,
        rank = 'member',
        joinedAt = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    FactionMembers[identifier] = {
        factionId = factionId,
        rank = 'member'
    }
    
    exports['kk-ui']:ShowNotificationToPlayer(playerId, 'Joined faction: ' .. faction.label, 'success')
    TriggerClientEvent('kk-factions:factionJoined', playerId, faction)
end

-- Leave faction function
function LeaveFaction(playerId, identifier)
    local memberData = FactionMembers[identifier]
    if not memberData then return end
    
    local faction = Factions[memberData.factionId]
    
    -- Remove from database
    MySQL.Async.execute('DELETE FROM kk_faction_members WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    
    -- Update in-memory data
    if faction and faction.members[identifier] then
        faction.members[identifier] = nil
    end
    FactionMembers[identifier] = nil
    
    exports['kk-ui']:ShowNotificationToPlayer(playerId, 'Left faction: ' .. (faction and faction.label or 'Unknown'), 'info')
    TriggerClientEvent('kk-factions:factionLeft', playerId)
end

-- Event handlers for admin faction management
RegisterServerEvent('kk-factions:factionCreated')
AddEventHandler('kk-factions:factionCreated', function(factionId, name, label, leaderIdentifier)
    -- Reload factions to include the new one
    LoadFactions()
end)

RegisterServerEvent('kk-factions:factionDeleted')
AddEventHandler('kk-factions:factionDeleted', function(factionId, name)
    -- Remove faction from memory
    if Factions[factionId] then
        -- Remove all members from memory
        for identifier, _ in pairs(Factions[factionId].members) do
            FactionMembers[identifier] = nil
        end
        
        Factions[factionId] = nil
    end
end)

-- Clean up expired invites
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute
        
        local currentTime = GetGameTimer()
        for identifier, invite in pairs(FactionInvites) do
            if currentTime - invite.timestamp > 300000 then -- 5 minutes
                FactionInvites[identifier] = nil
            end
        end
    end
end)

-- Player disconnect handler
AddEventHandler('esx:playerDropped', function(playerId, reason)
    local identifier = GetPlayerIdentifier(playerId, 0)
    if FactionInvites[identifier] then
        FactionInvites[identifier] = nil
    end
end)

-- Export functions
exports('GetPlayerFaction', function(identifier)
    if FactionMembers[identifier] then
        return Factions[FactionMembers[identifier].factionId]
    end
    return nil
end)

exports('GetAllFactions', function()
    return Factions
end)

exports('IsPlayerInFaction', function(identifier)
    return FactionMembers[identifier] ~= nil
end)