-- Updated notification function
local function ShowNotification(message)
    -- Using native FiveM notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
end

-- Example of usage
ShowNotification('Your notification message here')

-- Rest of the ffa.lua content goes here...