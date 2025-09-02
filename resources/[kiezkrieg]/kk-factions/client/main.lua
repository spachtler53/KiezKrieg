-- KiezKrieg Faction System Client
local PlayerFaction = nil
local AllFactions = {}
local PendingInvite = nil

-- Event handlers
RegisterNetEvent('kk-factions:receiveFactionData')
AddEventHandler('kk-factions:receiveFactionData', function(playerFaction, allFactions)
    PlayerFaction = playerFaction
    AllFactions = allFactions
    
    -- Update UI if needed
    SendNUIMessage({
        type = 'updateFactionData',
        playerFaction = playerFaction,
        allFactions = allFactions
    })
end)

RegisterNetEvent('kk-factions:receiveInvite')
AddEventHandler('kk-factions:receiveInvite', function(faction, inviterName)
    PendingInvite = {
        faction = faction,
        inviterName = inviterName,
        timestamp = GetGameTimer()
    }
    
    -- Show invite notification
    exports['kk-ui']:ShowNotification('Faction invite from ' .. inviterName, 'info')
    
    -- Show invite UI
    SendNUIMessage({
        type = 'showFactionInvite',
        faction = faction,
        inviterName = inviterName
    })
end)

RegisterNetEvent('kk-factions:factionJoined')
AddEventHandler('kk-factions:factionJoined', function(faction)
    PlayerFaction = faction
    exports['kk-ui']:ShowNotification('Joined faction: ' .. faction.label, 'success')
    
    -- Update UI
    SendNUIMessage({
        type = 'factionJoined',
        faction = faction
    })
end)

RegisterNetEvent('kk-factions:factionLeft')
AddEventHandler('kk-factions:factionLeft', function()
    PlayerFaction = nil
    exports['kk-ui']:ShowNotification('Left faction', 'info')
    
    -- Update UI
    SendNUIMessage({
        type = 'factionLeft'
    })
end)

-- Commands
RegisterCommand('faction', function(source, args, rawCommand)
    if args[1] == 'invite' then
        local targetId = tonumber(args[2])
        if targetId then
            TriggerServerEvent('kk-factions:invitePlayer', targetId)
        else
            exports['kk-ui']:ShowNotification('Usage: /faction invite [player_id]', 'error')
        end
    elseif args[1] == 'leave' then
        TriggerServerEvent('kk-factions:leaveFaction')
    elseif args[1] == 'accept' then
        if PendingInvite then
            TriggerServerEvent('kk-factions:respondToInvite', true)
            PendingInvite = nil
        else
            exports['kk-ui']:ShowNotification('No pending faction invite', 'error')
        end
    elseif args[1] == 'decline' then
        if PendingInvite then
            TriggerServerEvent('kk-factions:respondToInvite', false)
            PendingInvite = nil
        else
            exports['kk-ui']:ShowNotification('No pending faction invite', 'error')
        end
    elseif args[1] == 'info' then
        ShowFactionInfo()
    else
        exports['kk-ui']:ShowNotification('Usage: /faction [invite|leave|accept|decline|info]', 'info')
    end
end, false)

-- Show faction info
function ShowFactionInfo()
    if PlayerFaction then
        local memberCount = 0
        for _ in pairs(PlayerFaction.members) do
            memberCount = memberCount + 1
        end
        
        local message = string.format(
            'Faction: %s\nMembers: %d/%d\nRank: %s',
            PlayerFaction.label,
            memberCount,
            PlayerFaction.maxMembers,
            PlayerFaction.members[GetPlayerIdentifier(PlayerId(), 0)] and PlayerFaction.members[GetPlayerIdentifier(PlayerId(), 0)].rank or 'Unknown'
        )
        
        exports['kk-ui']:ShowNotification(message, 'info')
    else
        exports['kk-ui']:ShowNotification('You are not in a faction', 'info')
    end
end

-- Auto-decline expired invites
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute
        
        if PendingInvite then
            local currentTime = GetGameTimer()
            if currentTime - PendingInvite.timestamp > 300000 then -- 5 minutes
                PendingInvite = nil
                exports['kk-ui']:ShowNotification('Faction invite expired', 'warning')
            end
        end
    end
end)

-- Request faction data on resource start
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait for ESX to load
    TriggerServerEvent('kk-factions:getFactionData')
end)

-- Export functions
exports('GetPlayerFaction', function()
    return PlayerFaction
end)

exports('GetAllFactions', function()
    return AllFactions
end)

exports('HasPendingInvite', function()
    return PendingInvite ~= nil
end)