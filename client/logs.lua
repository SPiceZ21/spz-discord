-- client/logs.lua — client side of the log feed (see server/logs.lua).
-- exports['spz-discord']:Log(category, title, message, type, fields)
-- Only the categories in Config.Logs.ClientCategories are accepted, rate-limited.

exports('Log', function(category, title, message, kind, fields)
    TriggerServerEvent('spz-discord:log', category, title, message, kind, fields)
end)
for name, kind in pairs({ Info = 'info', Success = 'success', Warning = 'warning', Error = 'error' }) do
    exports(name, function(category, title, message, fields)
        TriggerServerEvent('spz-discord:log', category, title, message, kind, fields)
    end)
end
