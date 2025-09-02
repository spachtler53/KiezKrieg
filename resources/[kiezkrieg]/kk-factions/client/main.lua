ESX = exports['es_extended']:getSharedObject()

-- Variables
local playerFaction = nil
local factionInvites = {}

-- Initialize
Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    
    -- Request player faction info
    TriggerServerEvent('kk-factions:requestFactionInfo')
end)

-- Events
RegisterNetEvent('kk-factions:factionInfoReceived')
AddEventHandler('kk-factions:factionInfoReceived', function(faction)
    playerFaction = faction
end)

RegisterNetEvent('kk-factions:factionInviteReceived')
AddEventHandler('kk-factions:factionInviteReceived', function(factionName, inviterId)
    table.insert(factionInvites, {
        factionName = factionName,
        inviterId = inviterId,
        timestamp = GetGameTimer()
    })
    
    ESX.ShowNotification('~b~Faction Invite: ~w~' .. factionName .. '\n~g~Press ~INPUT_CONTEXT~ to accept, ~INPUT_DETONATE~ to decline')
    
    -- Auto-remove invite after 30 seconds
    Citizen.SetTimeout(30000, function()
        for i, invite in ipairs(factionInvites) do
            if invite.factionName == factionName and invite.inviterId == inviterId then
                table.remove(factionInvites, i)
                break
            end
        end
    end)
end)

RegisterNetEvent('kk-factions:factionJoined')
AddEventHandler('kk-factions:factionJoined', function(faction)
    playerFaction = faction
    ESX.ShowNotification('~g~Joined faction: ~w~' .. faction.name)
end)

RegisterNetEvent('kk-factions:factionLeft')
AddEventHandler('kk-factions:factionLeft', function()
    playerFaction = nil
    ESX.ShowNotification('~r~Left faction')
end)

-- Handle faction invites
Citizen.CreateThread(function()
    while true do
        if #factionInvites > 0 then
            if IsControlJustPressed(0, 38) then -- E key - Accept
                local invite = factionInvites[1]
                TriggerServerEvent('kk-factions:acceptInvite', invite.factionName, invite.inviterId)
                table.remove(factionInvites, 1)
            elseif IsControlJustPressed(0, 47) then -- G key - Decline
                table.remove(factionInvites, 1)
                ESX.ShowNotification('~r~Faction invite declined')
            end
        end
        
        Citizen.Wait(0)
    end
end)

-- Commands
RegisterCommand('factionmenu', function()
    if playerFaction then
        OpenFactionMenu()
    else
        ESX.ShowNotification('~r~You are not in a faction')
    end
end, false)

RegisterCommand('faction', function(source, args)
    local action = args[1]
    
    if not action then
        ESX.ShowNotification('~b~/faction [create/invite/leave/info]')
        return
    end
    
    if action == 'create' then
        local factionName = table.concat(args, ' ', 2)
        if factionName and factionName ~= '' then
            TriggerServerEvent('kk-factions:createFaction', factionName)
        else
            ESX.ShowNotification('~r~/faction create [faction_name]')
        end
    elseif action == 'invite' then
        local playerId = tonumber(args[2])
        if playerId then
            TriggerServerEvent('kk-factions:invitePlayer', playerId)
        else
            ESX.ShowNotification('~r~/faction invite [player_id]')
        end
    elseif action == 'leave' then
        TriggerServerEvent('kk-factions:leaveFaction')
    elseif action == 'info' then
        if playerFaction then
            ShowFactionInfo()
        else
            ESX.ShowNotification('~r~You are not in a faction')
        end
    end
end, false)

-- Functions
function OpenFactionMenu()
    -- This would open a faction management UI
    ESX.ShowNotification('~b~Faction menu coming soon!')
end

function ShowFactionInfo()
    if playerFaction then
        local memberCount = #playerFaction.members
        ESX.ShowNotification(
            '~b~Faction: ~w~' .. playerFaction.name .. '\n' ..
            '~b~Members: ~w~' .. memberCount .. '/' .. Config.Factions.maxMembers .. '\n' ..
            '~b~Type: ~w~' .. playerFaction.faction_type
        )
    end
end

-- Export functions
exports('GetPlayerFaction', function()
    return playerFaction
end)

exports('IsInFaction', function()
    return playerFaction ~= nil
end)