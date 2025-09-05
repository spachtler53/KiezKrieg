local function showNotification(message)
    -- Replace this with the native FiveM notification method
    TriggerEvent('chat:addMessage', { args = { message } })
end

-- Example usage of the notification function
showNotification('Hello, world!')

-- Original content goes here...