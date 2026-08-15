-- server/discord.lua — Discord REST helpers + embed builders + message-id store.

local API = 'https://discord.com/api/v10'

local function token()
    return GetConvar('spz_discord_token', '')
end

local function headers()
    return {
        ['Authorization'] = 'Bot ' .. token(),
        ['Content-Type']  = 'application/json',
    }
end

-- ── Message id persistence (so we EDIT the same message, not spam new ones) ────
-- Keyed per channel so a re-used channel keeps separate leaderboard/live ids.
-- A memory cache backs the KVP so concurrent updates don't each read a stale
-- "no id yet" before the first POST's callback has persisted the new id.
local idCache = {}   -- [kind:channel] = message id
local function kvpKey(kind, channel) return ('spzdc:%s:%s'):format(kind, channel) end

local function getMsgId(kind, channel)
    local k = kvpKey(kind, channel)
    if idCache[k] ~= nil then return idCache[k] or nil end
    local v = GetResourceKvpString(k)
    v = (v ~= nil and v ~= '') and v or nil
    idCache[k] = v or false   -- cache the miss too (false) so we don't re-read
    return v
end
local function setMsgId(kind, channel, id)
    local k = kvpKey(kind, channel)
    idCache[k] = id or false
    if id then SetResourceKvpString(k, id)
    else DeleteResourceKvp(k) end
end

-- ── Low-level REST ─────────────────────────────────────────────────────────────
local function post(channel, embed, cb)
    PerformHttpRequest(API .. '/channels/' .. channel .. '/messages',
        function(status, body)
            local id
            if status == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data then id = data.id end
            elseif status ~= 200 then
                print(('^3[spz-discord] post failed ch=%s HTTP %s^7'):format(channel, tostring(status)))
            end
            if cb then cb(id) end
        end, 'POST', json.encode({ embeds = { embed } }), headers())
end

local function patch(channel, msgId, embed, cb)
    PerformHttpRequest(API .. '/channels/' .. channel .. '/messages/' .. msgId,
        function(status, body)
            if status == 404 then
                -- message was deleted in Discord → forget it, caller re-posts
                if cb then cb(false) end
            elseif status == 200 then
                if cb then cb(true) end
            else
                print(('^3[spz-discord] edit failed ch=%s HTTP %s^7'):format(channel, tostring(status)))
                if cb then cb(true) end   -- keep id; likely transient/rate-limit
            end
        end, 'PATCH', json.encode({ embeds = { embed } }), headers())
end

-- Public: post-or-edit a persistent embed (leaderboard / live).
-- kind = "leaderboard" | "live". Reuses the stored message id when present.
local inflight = {}   -- [kind:channel] = true while a create is round-tripping
function Discord_Upsert(kind, channel, embed)
    if not channel or channel == '' or token() == '' then return end
    local lock = kind .. ':' .. channel
    local id = getMsgId(kind, channel)
    if id then
        patch(channel, id, embed, function(ok)
            if not ok then
                -- Stored message is gone → create a fresh one (guarded).
                if inflight[lock] then return end
                inflight[lock] = true
                setMsgId(kind, channel, nil)
                post(channel, embed, function(newId)
                    inflight[lock] = nil
                    setMsgId(kind, channel, newId)
                end)
            end
        end)
    else
        -- No message yet — only ONE create may be in flight, or concurrent
        -- updates would each post a new message.
        if inflight[lock] then return end
        inflight[lock] = true
        post(channel, embed, function(newId)
            inflight[lock] = nil
            setMsgId(kind, channel, newId)
        end)
    end
end

-- Public: post a fresh, standalone embed (results / history). Never edited.
function Discord_Post(channel, embed)
    if not channel or channel == '' or token() == '' then return end
    post(channel, embed)
end

-- Public: forget a stored id (e.g. clear the live message after a race ends).
function Discord_Clear(kind, channel)
    if channel and channel ~= '' then setMsgId(kind, channel, nil) end
end

-- ── Embed helpers ──────────────────────────────────────────────────────────────
local FLAG_BASE = 127397   -- 'A' regional indicator - 'A' ascii
function Discord_Flag(nation)
    if not Config.ShowFlags or type(nation) ~= 'string' or #nation ~= 2 then return '' end
    local a, b = nation:upper():byte(1, 2)
    if not a or not b then return '' end
    return utf8.char(FLAG_BASE + a) .. utf8.char(FLAG_BASE + b) .. ' '
end

function Discord_BaseEmbed(title, color)
    return {
        title = title,
        color = color or Config.Brand.color,
        footer = { text = Config.Brand.footer, icon_url = Config.Brand.icon },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S') .. 'Z',
    }
end

-- mm:ss.mmm from milliseconds
function Discord_FmtTime(ms)
    if not ms or ms <= 0 then return '—' end
    local s = ms / 1000
    local m = math.floor(s / 60)
    return ('%d:%06.3f'):format(m, s - m * 60)
end
