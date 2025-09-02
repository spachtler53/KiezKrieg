-- KiezKrieg Faction Configuration
KiezKrieg.Factions = {}

-- Faction ranks and permissions
KiezKrieg.Factions.Ranks = {
    {name = 'Leader', level = 4, permissions = {'invite', 'kick', 'promote', 'demote', 'disband', 'edit'}},
    {name = 'Officer', level = 3, permissions = {'invite', 'kick', 'promote'}},
    {name = 'Veteran', level = 2, permissions = {'invite'}},
    {name = 'Member', level = 1, permissions = {}}
}

-- Default faction colors
KiezKrieg.Factions.Colors = {
    '#FF0000', -- Red
    '#00FF00', -- Green
    '#0000FF', -- Blue
    '#FFFF00', -- Yellow
    '#FF00FF', -- Magenta
    '#00FFFF', -- Cyan
    '#FFA500', -- Orange
    '#800080', -- Purple
    '#008000', -- Dark Green
    '#000080'  -- Dark Blue
}

-- Faction creation settings
KiezKrieg.Factions.Settings = {
    MIN_NAME_LENGTH = 3,
    MAX_NAME_LENGTH = 30,
    MIN_TAG_LENGTH = 2,
    MAX_TAG_LENGTH = 6,
    DEFAULT_MAX_MEMBERS = 50,
    CREATION_COST = 50000 -- ESX money required to create faction
}