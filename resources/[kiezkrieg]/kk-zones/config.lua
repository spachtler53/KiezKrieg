Config = {}

-- Zone marker settings
Config.ZoneMarkers = {
    type = 1, -- Cylinder
    size = vector3(200.0, 200.0, 50.0),
    bobUpAndDown = false,
    faceCamera = false,
    rotate = false,
    drawOnEnts = false
}

-- Blip settings for zones
Config.ZoneBlips = {
    sprite = 84, -- Combat zone icon
    color = 3,   -- Blue
    scale = 1.0,
    name = 'FFA Zone'
}