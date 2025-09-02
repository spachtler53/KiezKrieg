-- KiezKrieg Admin Configuration
KiezKrieg.Admin = {}

-- Admin groups that have access to admin features
KiezKrieg.Admin.Groups = {
    'admin',
    'superadmin',
    'owner',
    'moderator'
}

-- Admin duty settings
KiezKrieg.Admin.Duty = {
    ENABLE_NOCLIP = true,
    ENABLE_GODMODE = true,
    ENABLE_INVISIBILITY = true,
    SHOW_ADMIN_TAG = true,
    TELEPORT_MARKERS = true
}

-- Vehicle spawn settings
KiezKrieg.Admin.Vehicles = {
    CLEANUP_ON_DUTY_OFF = true,
    MAX_SPAWNED_VEHICLES = 5,
    ALLOWED_VEHICLES = {
        -- Sports cars
        'adder', 'zentorno', 'osiris', 'entityxf', 'turismor',
        -- Super cars
        'banshee2', 'sultanrs', 'kuruma', 'insurgent2',
        -- Emergency
        'police', 'police2', 'sheriff', 'fbi', 'ambulance',
        -- Helicopters
        'buzzard', 'buzzard2', 'maverick', 'polmav',
        -- Boats
        'seashark', 'jetmax', 'marquis'
    }
}

-- Admin menu key binding
KiezKrieg.Admin.MenuKey = 137 -- F6

-- Teleport locations
KiezKrieg.Admin.TeleportLocations = {
    {name = 'Downtown FFA', coords = vector3(-1037.0, -2737.0, 20.2)},
    {name = 'Airport FFA', coords = vector3(-1336.0, -3044.0, 13.9)},
    {name = 'Industrial FFA', coords = vector3(715.0, -962.0, 30.4)},
    {name = 'Beach FFA', coords = vector3(-1212.0, -1607.0, 4.6)},
    {name = 'Hills FFA', coords = vector3(-2072.0, 3170.0, 32.8)},
    {name = 'LS Airport', coords = vector3(-1037.0, -2674.0, 20.2)},
    {name = 'Vinewood Sign', coords = vector3(763.0, 1274.0, 360.3)},
    {name = 'Mount Chiliad', coords = vector3(501.8, 5593.1, 797.9)},
    {name = 'Maze Bank Tower', coords = vector3(-75.0, -818.0, 326.2)},
    {name = 'Fort Zancudo', coords = vector3(-2267.0, 3123.0, 32.8)}
}