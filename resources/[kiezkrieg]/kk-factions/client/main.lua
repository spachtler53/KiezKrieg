-- KiezKrieg Factions Client
local ESX = exports["es_extended"]:getSharedObject()
local playerFaction = nil
local isMenuOpen = false

-- Initialize
Citizen.CreateThread(function()
    Wait(1000)
    -- Request faction data when player loads
    TriggerServerEvent('kk-factions:requestPlayerFaction')
end)

-- Faction menu event from core
RegisterNetEvent('kk-factions:openMenu')
AddEventHandler('kk-factions:openMenu', function()
    if isMenuOpen then return end
    openFactionMenu()
end)

-- Player faction update
RegisterNetEvent('kk-factions:updatePlayerFaction')
AddEventHandler('kk-factions:updatePlayerFaction', function(faction)
    playerFaction = faction
    
    if faction then
        ESX.ShowNotification('~g~Faction: ~w~[' .. faction.tag .. '] ' .. faction.name)
        ESX.ShowNotification('~b~Rank: ~w~' .. faction.rank)
    end
end)

-- Faction menu
function openFactionMenu()
    isMenuOpen = true
    
    local elements = {}
    
    if playerFaction then
        -- Player is in a faction
        table.insert(elements, {label = '📊 Faction Info', value = 'info'})
        table.insert(elements, {label = '👥 Member List', value = 'members'})
        
        if hasFactionPermission('invite') then
            table.insert(elements, {label = '➕ Invite Player', value = 'invite'})
        end
        
        if hasFactionPermission('kick') then
            table.insert(elements, {label = '➖ Kick Member', value = 'kick'})
        end
        
        if hasFactionPermission('promote') then
            table.insert(elements, {label = '⬆️ Promote Member', value = 'promote'})
            table.insert(elements, {label = '⬇️ Demote Member', value = 'demote'})
        end
        
        if hasFactionPermission('edit') then
            table.insert(elements, {label = '⚙️ Edit Faction', value = 'edit'})
        end
        
        if hasFactionPermission('disband') then
            table.insert(elements, {label = '🗑️ Disband Faction', value = 'disband'})
        end
        
        table.insert(elements, {label = '🚪 Leave Faction', value = 'leave'})
    else
        -- Player is not in a faction
        table.insert(elements, {label = '🆕 Create Faction', value = 'create'})
        table.insert(elements, {label = '🔍 Browse Factions', value = 'browse'})
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'faction_menu', {
        title = 'Faction Management',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local action = data.current.value
        
        if action == 'info' then
            showFactionInfo()
        elseif action == 'members' then
            showMemberList()
        elseif action == 'invite' then
            invitePlayer()
        elseif action == 'kick' then
            kickMember()
        elseif action == 'promote' then
            promoteMember()
        elseif action == 'demote' then
            demoteMember()
        elseif action == 'edit' then
            editFaction()
        elseif action == 'disband' then
            disbandFaction()
        elseif action == 'leave' then
            leaveFaction()
        elseif action == 'create' then
            createFaction()
        elseif action == 'browse' then
            browseFactions()
        end
    end, function(data, menu)
        menu.close()
        isMenuOpen = false
    end)
end

-- Faction info display
function showFactionInfo()
    if not playerFaction then return end
    
    local elements = {
        {label = '📛 Name: ' .. playerFaction.name, value = nil},
        {label = '🏷️ Tag: [' .. playerFaction.tag .. ']', value = nil},
        {label = '👑 Leader: ' .. (playerFaction.leader_name or 'Unknown'), value = nil},
        {label = '👥 Members: ' .. (playerFaction.member_count or 0) .. '/' .. playerFaction.max_members, value = nil},
        {label = '📝 Description: ' .. (playerFaction.description or 'No description'), value = nil},
        {label = '📅 Created: ' .. (playerFaction.created_at or 'Unknown'), value = nil}
    }
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'faction_info', {
        title = 'Faction Information',
        align = 'top-left',
        elements = elements
    }, function(data, menu) end, function(data, menu)
        menu.close()
        openFactionMenu()
    end)
end

-- Member list
function showMemberList()
    TriggerServerEvent('kk-factions:requestMemberList')
end

RegisterNetEvent('kk-factions:receiveMemberList')
AddEventHandler('kk-factions:receiveMemberList', function(members)
    local elements = {}
    
    for _, member in ipairs(members) do
        local status = member.is_online and '🟢' or '🔴'
        table.insert(elements, {
            label = status .. ' ' .. member.name .. ' (' .. member.rank .. ')',
            value = member.identifier
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'member_list', {
        title = 'Faction Members',
        align = 'top-left',
        elements = elements
    }, function(data, menu) end, function(data, menu)
        menu.close()
        openFactionMenu()
    end)
end)

-- Invite player
function invitePlayer()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'invite_player', {
        title = 'Enter player ID to invite'
    }, function(data, menu)
        local playerId = tonumber(data.value)
        
        if playerId then
            TriggerServerEvent('kk-factions:invitePlayer', playerId)
            menu.close()
            openFactionMenu()
        else
            ESX.ShowNotification('~r~Invalid player ID')
        end
    end, function(data, menu)
        menu.close()
        openFactionMenu()
    end)
end

-- Create faction
function createFaction()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'faction_name', {
        title = 'Enter faction name (3-30 characters)'
    }, function(data, menu)
        local name = data.value
        
        if not name or string.len(name) < 3 or string.len(name) > 30 then
            ESX.ShowNotification('~r~Invalid faction name length')
            return
        end
        
        menu.close()
        
        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'faction_tag', {
            title = 'Enter faction tag (2-6 characters)'
        }, function(data2, menu2)
            local tag = data2.value
            
            if not tag or string.len(tag) < 2 or string.len(tag) > 6 then
                ESX.ShowNotification('~r~Invalid faction tag length')
                return
            end
            
            menu2.close()
            
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'faction_description', {
                title = 'Enter faction description (optional)'
            }, function(data3, menu3)
                local description = data3.value or ''
                
                TriggerServerEvent('kk-factions:createFaction', {
                    name = name,
                    tag = tag,
                    description = description
                })
                
                menu3.close()
                isMenuOpen = false
                
            end, function(data3, menu3)
                menu3.close()
                isMenuOpen = false
            end)
            
        end, function(data2, menu2)
            menu2.close()
            isMenuOpen = false
        end)
        
    end, function(data, menu)
        menu.close()
        isMenuOpen = false
    end)
end

-- Browse factions
function browseFactions()
    TriggerServerEvent('kk-factions:requestPublicFactions')
end

RegisterNetEvent('kk-factions:receivePublicFactions')
AddEventHandler('kk-factions:receivePublicFactions', function(factions)
    local elements = {}
    
    for _, faction in ipairs(factions) do
        table.insert(elements, {
            label = '[' .. faction.tag .. '] ' .. faction.name .. ' (' .. faction.member_count .. '/' .. faction.max_members .. ')',
            value = faction.id
        })
    end
    
    if #elements == 0 then
        table.insert(elements, {label = 'No public factions available', value = nil})
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'browse_factions', {
        title = 'Public Factions',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value then
            -- Show option to request invitation
            ESX.ShowNotification('~y~Contact faction members to request an invitation')
        end
    end, function(data, menu)
        menu.close()
        openFactionMenu()
    end)
end)

-- Leave faction confirmation
function leaveFaction()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'leave_confirm', {
        title = 'Are you sure you want to leave your faction?',
        align = 'top-left',
        elements = {
            {label = '✅ Yes, leave faction', value = 'yes'},
            {label = '❌ No, stay in faction', value = 'no'}
        }
    }, function(data, menu)
        if data.current.value == 'yes' then
            TriggerServerEvent('kk-factions:leaveFaction')
        end
        menu.close()
        isMenuOpen = false
    end, function(data, menu)
        menu.close()
        openFactionMenu()
    end)
end

-- Faction invitation received
RegisterNetEvent('kk-factions:receiveInvitation')
AddEventHandler('kk-factions:receiveInvitation', function(factionName, factionTag, inviterName)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'faction_invitation', {
        title = 'Faction Invitation',
        align = 'top-left',
        elements = {
            {label = '📛 Faction: [' .. factionTag .. '] ' .. factionName, value = nil},
            {label = '👤 Invited by: ' .. inviterName, value = nil},
            {label = '✅ Accept Invitation', value = 'accept'},
            {label = '❌ Decline Invitation', value = 'decline'}
        }
    }, function(data, menu)
        if data.current.value == 'accept' then
            TriggerServerEvent('kk-factions:acceptInvitation')
            ESX.ShowNotification('~g~Invitation accepted!')
        elseif data.current.value == 'decline' then
            TriggerServerEvent('kk-factions:declineInvitation')
            ESX.ShowNotification('~r~Invitation declined')
        end
        menu.close()
    end, function(data, menu)
        TriggerServerEvent('kk-factions:declineInvitation')
        menu.close()
    end)
end)

-- Helper functions
function hasFactionPermission(permission)
    if not playerFaction or not playerFaction.rank_level then
        return false
    end
    
    for _, rank in ipairs(KiezKrieg.Factions.Ranks) do
        if rank.level == playerFaction.rank_level then
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

-- Export functions
exports('getPlayerFaction', function()
    return playerFaction
end)

exports('isInFaction', function()
    return playerFaction ~= nil
end)

exports('hasFactionPermission', hasFactionPermission)