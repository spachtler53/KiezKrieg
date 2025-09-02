Config = {}

-- Faction Settings
Config.Factions = {
    maxMembers = 50,
    maxFactions = 20,
    minNameLength = 3,
    maxNameLength = 30,
    allowPublicFactions = true
}

-- Faction Types
Config.FactionTypes = {
    public = {
        name = 'Public',
        description = 'Anyone can join',
        autoAccept = true
    },
    private = {
        name = 'Private',
        description = 'Invite only',
        autoAccept = false
    }
}

-- Faction Ranks
Config.FactionRanks = {
    [1] = { name = 'Member', permissions = {'view'} },
    [2] = { name = 'Veteran', permissions = {'view', 'invite'} },
    [3] = { name = 'Officer', permissions = {'view', 'invite', 'kick'} },
    [4] = { name = 'Co-Leader', permissions = {'view', 'invite', 'kick', 'promote', 'manage'} },
    [5] = { name = 'Leader', permissions = {'view', 'invite', 'kick', 'promote', 'manage', 'disband'} }
}

-- Territory Settings
Config.Territories = {
    enabled = true,
    maxTerritories = 5,
    captureTime = 300, -- 5 minutes
    defenseTime = 600  -- 10 minutes
}