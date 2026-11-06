-- server/logs.lua — the log feed (was spz-log).
--
-- Any resource posts a log embed to a category's channel:
--   exports['spz-discord']:Log(category, title, message, type, fields, src, thumbnail)
--   exports['spz-discord']:Info / Success / Warning / Error(category, title, message, fields, src, thumbnail)
-- Through the bot (same token as the feeds) when the category has a channel id,
-- else through the category's webhook. Every log is also appended to logs.txt.

local L = Config.Logs

-- ── Player block ─────────────────────────────────────────────────────────────
local function playerInfo(src)
    local function id(kind) return GetPlayerIdentifierByType(src, kind) or '—' end
    local lines = {
        ('**Name:** %s'):format(GetPlayerName(src) or '?'),
        ('**License:** %s'):format(id('license')),
        ('**Discord:** %s'):format(id('discord')),
        ('**Steam:** %s'):format(id('steam')),
    }
    if L.ShowIp then lines[#lines + 1] = ('**IP:** %s'):format(id('ip')) end
    return table.concat(lines, '\n')
end

-- ── Local file (appended, never re-read) ─────────────────────────────────────
local logPath = GetResourcePath(GetCurrentResourceName()) .. '/logs.txt'

local function writeFile(category, title, message)
    if not L.File then return end
    local f = io.open(logPath, 'a')
    if not f then return end
    f:write(('[%s] [%s] %s: %s\n'):format(os.date('%Y-%m-%d %H:%M:%S'), tostring(category):upper(),
        tostring(title), tostring(message):gsub('\n', ' ')))
    f:close()
end

-- ── Delivery ─────────────────────────────────────────────────────────────────
local function cut(s, n)
    s = tostring(s or '')
    return #s > n and (s:sub(1, n - 3) .. '...') or s
end

local function postWebhook(url, embed)
    PerformHttpRequest(url, function(status)
        if status < 200 or status >= 300 then
            print(('^3[spz-discord] log webhook failed HTTP %s^7'):format(tostring(status)))
        end
    end, 'POST', json.encode({ username = L.Name, avatar_url = Config.Brand.icon, embeds = { embed } }),
        { ['Content-Type'] = 'application/json' })
end

local function send(category, title, message, kind, fields, src, thumbnail)
    category = category or 'default'
    writeFile(category, title, message)

    -- Copy the caller's fields; never mutate their table.
    local out = {}
    for i, f in ipairs(fields or {}) do
        if i > 24 then break end
        out[#out + 1] = { name = cut(f.name, 256), value = cut(f.value, 1024), inline = f.inline }
    end
    if src and src > 0 then
        out[#out + 1] = { name = 'Player', value = playerInfo(src), inline = false }
    end

    local embed = {
        title       = cut(title, 256),
        description = cut(message, 4096),
        color       = L.Colors[kind or 'info'] or L.Colors.info,
        fields      = out,
        footer      = { text = Config.Brand.footer .. ' • ' .. category, icon_url = Config.Brand.icon },
        timestamp   = os.date('!%Y-%m-%dT%H:%M:%S') .. 'Z',
    }
    local thumb = thumbnail or L.Thumbnails[category]
    if thumb and thumb ~= '' then embed.thumbnail = { url = thumb } end   -- "" is rejected by Discord

    local channel = L.Channels[category]
    if not channel or channel == '' then channel = L.Channels.default end
    if channel and channel ~= '' and GetConvar('spz_discord_token', '') ~= '' then
        return Discord_Post(channel, embed)
    end

    local webhook = L.Webhooks[category]
    if not webhook or webhook == '' then webhook = L.Webhooks.default end
    if webhook and webhook ~= '' then return postWebhook(webhook, embed) end
end

-- ── Exports ──────────────────────────────────────────────────────────────────
exports('Log', function(category, title, message, kind, fields, src, thumbnail)
    send(category, title, message, kind, fields, src, thumbnail)
end)
for name, kind in pairs({ Info = 'info', Success = 'success', Warning = 'warning', Error = 'error' }) do
    exports(name, function(category, title, message, fields, src, thumbnail)
        send(category, title, message, kind, fields, src, thumbnail)
    end)
end

-- A category's raw webhook URL (spz-races overtake clips upload a screenshot
-- straight to it with screenshot-basic, which cannot post through the bot).
exports('GetWebhook', function(category)
    local w = L.Webhooks[category]
    if not w or w == '' then w = L.Webhooks.default end
    return w
end)

-- ── Client bridge ────────────────────────────────────────────────────────────
-- Any client can fire this, so it is limited: only the categories listed in
-- Config.Logs.ClientCategories, one log per player per ClientCooldownMs, and
-- the title marks it as client-sent so it cannot pass for a server log.
local lastClient = {}
local clientOk = {}
for _, c in ipairs(L.ClientCategories or {}) do clientOk[c] = true end

RegisterNetEvent('spz-discord:log', function(category, title, message, kind, fields)
    local src = source
    if not clientOk[category] then return end
    local now = GetGameTimer()
    if lastClient[src] and now - lastClient[src] < (L.ClientCooldownMs or 5000) then return end
    lastClient[src] = now
    send(category, '[client] ' .. tostring(title), message, kind, type(fields) == 'table' and fields or nil, src)
end)
AddEventHandler('playerDropped', function() lastClient[source] = nil end)

RegisterCommand('testlog', function(source)
    if source ~= 0 then return end
    send('system', 'Log test', 'Test log from the server console.', 'success',
        { { name = 'Status', value = 'Working', inline = true } })
    print('^2[spz-discord] test log sent^7')
end, true)
