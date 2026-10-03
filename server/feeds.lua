-- server/feeds.lua — turns race lifecycle + DB into Discord embeds.

local CH = Config.Channels

local function raceInfo()
    local ok, info = pcall(function() return exports['spz-races']:GetRaceInfo() end)
    return ok and info or {}
end

local function pad(s, n)
    s = tostring(s or '')
    -- ASCII-only truncation ('..'), so monospace code-block columns stay aligned
    -- (a multibyte ellipsis throws the spacing off).
    if #s > n then return s:sub(1, n - 2) .. '..' end
    return s .. string.rep(' ', n - #s)
end

local function typeLabel(t)
    t = tostring(t or 'circuit')
    return t:sub(1, 1):upper() .. t:sub(2)
end

-- ── Leaderboard embed (queried straight from the DB) ─────────────────────────
function RefreshLeaderboard()
    if not CH.leaderboard or CH.leaderboard == '' then return end

    local rows = MySQL.query.await([[
        SELECT p.username AS name, p.rank AS rank_title, p.alltime_points AS points,
               p.i_rating AS irating, p.sr
        FROM players p
        WHERE p.banned = 0
        ORDER BY p.alltime_points DESC, p.sr DESC
        LIMIT ?]], { Config.LeaderboardTopN or 10 }) or {}

    local lines = { '#   Driver            Pts     iR    SR', '─────────────────────────────────────────' }
    if #rows == 0 then
        lines = { 'No races recorded yet.' }
    else
        for i, r in ipairs(rows) do
            lines[#lines + 1] = ('%-3d %s %-7d %-5d %.2f'):format(
                i, pad(r.name, 16), math.floor(r.points or 0), math.floor(r.irating or 0), (r.sr or 0) + 0.0)
        end
    end

    local embed = Discord_BaseEmbed('🏆  ' .. Config.Brand.name .. ' — Leaderboard')
    embed.description = '```' .. table.concat(lines, '\n') .. '```'
    embed.thumbnail = { url = Config.Brand.icon }
    Discord_Upsert('leaderboard', CH.leaderboard, embed)
end

-- ── Live race embed ──────────────────────────────────────────────────────────
local liveStandings = nil   -- latest SPZ:standings payload
local liveActive    = false

local function buildLiveEmbed(final)
    local info = raceInfo()
    local order = liveStandings or {}
    local leadLap = order[1] and order[1].lap or 1

    local title = (final and '🏁  Race Finished — ' or '🟢  LIVE — ') .. (info.track or 'Race')
    local embed = Discord_BaseEmbed(title, final and Config.Brand.green or Config.Brand.color)

    local head = ('%s  •  Lap %s%s  •  %d racers'):format(
        typeLabel(info.type), tostring(leadLap),
        info.laps and ('/' .. info.laps) or '', #order)

    local lines = { 'P   Driver            Gap' }
    for i, e in ipairs(order) do
        if i > 12 then lines[#lines + 1] = ('…and %d more'):format(#order - 12); break end
        local gap = e.finished and 'FIN' or (e.gap or '—')
        lines[#lines + 1] = ('%-3d %s %s'):format(e.position or i, pad(e.name, 16), gap)
    end

    embed.description = head .. '\n```' .. table.concat(lines, '\n') .. '```'
    return embed
end

local function updateLive(final)
    if not CH.live or CH.live == '' then return end
    if not liveStandings then return end
    Discord_Upsert('live', CH.live, buildLiveEmbed(final))
end

-- Throttled live updater — one edit per Config.LiveUpdateSeconds while racing.
CreateThread(function()
    while true do
        Wait((Config.LiveUpdateSeconds or 15) * 1000)
        if liveActive then updateLive(false) end
    end
end)

AddEventHandler('SPZ:standings', function(payload)
    if type(payload) == 'table' then liveStandings = payload end
end)

-- ── Results embed (per race → history channel) ───────────────────────────────
local MEDAL = { '🥇', '🥈', '🥉' }

-- Recent races, newest first. Kept in KVP so a restart doesn't blank the
-- single results message. Each entry is the already-rendered text block.
local RECENT_KVP = 'spzdc:recentResults'
local recent = json.decode(GetResourceKvpString(RECENT_KVP) or '[]') or {}

local function postResults(results)
    if not CH.results or CH.results == '' then return end
    if not results then return end

    local embed = Discord_BaseEmbed('🏁  Race Result — ' .. (results.track or 'Race'), Config.Brand.green)

    local sub = ('%s • %s laps • %d finishers'):format(
        typeLabel(results.type), tostring(results.laps or 1), #(results.finishers or {}))

    local body = {}
    for i, f in ipairs(results.finishers or {}) do
        local medal = MEDAL[i] or ('`P' .. (f.position or i) .. '`')
        local crew = f.crew_tag and (' ' .. f.crew_tag) or ''
        body[#body + 1] = ('%s **%s**%s  ·  %s'):format(
            medal, f.name or 'Racer', crew, Discord_FmtTime(f.finish_time))
    end
    if #(results.dnf or {}) > 0 then
        local names = {}
        for _, d in ipairs(results.dnf) do names[#names + 1] = d.name or 'Racer' end
        body[#body + 1] = '\n**DNF:** ' .. table.concat(names, ', ')
    end
    if #body == 0 then body = { 'No finishers.' } end

    embed.description = sub .. '\n\n' .. table.concat(body, '\n')

    -- Fastest lap highlight (circuit)
    local fl, fln
    for _, f in ipairs(results.finishers or {}) do
        if f.best_lap and f.best_lap > 0 and (not fl or f.best_lap < fl) then fl, fln = f.best_lap, f.name end
    end
    if fl then
        embed.fields = { { name = '⚡ Fastest Lap', value = ('%s — %s'):format(fln, Discord_FmtTime(fl)), inline = true } }
    end

    if Config.ResultsMode == 'post' then
        return Discord_Post(CH.results, embed)
    end

    -- 'edit': one message showing the last N races.
    local block = ('**%s** — <t:%d:R>\n%s'):format(embed.title:gsub('^🏁%s+Race Result — ', ''), os.time(), embed.description)
    if embed.fields then block = block .. '\n⚡ ' .. embed.fields[1].value end
    table.insert(recent, 1, block)
    while #recent > (Config.ResultsKeep or 5) do table.remove(recent) end
    SetResourceKvpString(RECENT_KVP, json.encode(recent))

    local out = Discord_BaseEmbed('🏁  ' .. Config.Brand.name .. ' — Recent Results', Config.Brand.green)
    local desc = table.concat(recent, '\n\n━━━━━━━━━━\n\n')
    if #desc > 4000 then desc = desc:sub(1, 3990) .. '\n…' end   -- Discord's 4096 cap
    out.description = desc
    Discord_Upsert('results', CH.results, out)
end

-- ── Lifecycle wiring ─────────────────────────────────────────────────────────
AddStateBagChangeHandler('raceState', 'global', function(_, _, value)
    if value == 'LIVE' then
        liveActive = true
        liveStandings = nil
        -- Reuse the same live message across races — edit it, never repost.
        SetTimeout(3000, function() updateLive(false) end)
    elseif value == 'IDLE' or value == 'ENDED' or value == 'CLEANUP' then
        if liveActive then
            liveActive = false
            updateLive(true)             -- finalize the live message
        end
    end
end)

AddEventHandler('SPZ:raceEnd', function(results)
    postResults(results)
    RefreshLeaderboard()
end)

-- Periodic leaderboard refresh + one on boot.
CreateThread(function()
    Wait(5000)
    RefreshLeaderboard()
    local mins = Config.LeaderboardRefreshMinutes or 0
    if mins > 0 then
        while true do
            Wait(mins * 60000)
            RefreshLeaderboard()
        end
    end
end)

-- Admin helpers.
RegisterCommand('dc_leaderboard', function(src)
    if src == 0 or IsPlayerAceAllowed(src, 'spz.admin') then RefreshLeaderboard() end
end, false)
