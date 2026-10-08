-- config.lua — spz-discord
-- Posts live races, results and a standing leaderboard to Discord via the bot
-- token (set spz_discord_token "..."). Uses the Discord REST API only — no
-- gateway/websocket, so nothing extra to host.

Config = {}

-- The bot must be a member of your guild with "Send Messages" + "Embed Links"
-- permission in each channel below. Put a channel ID in each feed you want.
-- Set the SAME id in all three to funnel everything into one channel, or leave
-- a field empty ("") to disable that feed.
Config.Channels = {
    leaderboard = "",   -- persistent leaderboard embed (edited in place)
    live        = "",   -- ongoing race, updated live then finalized
    results     = "",   -- recent race results (see ResultsMode)
}

-- Results feed: "edit" keeps ONE message listing the last ResultsKeep races
-- (edited after every race); "post" sends a new message per race (history log).
Config.ResultsMode = "edit"
Config.ResultsKeep = 5

-- Footer tag per persistent message. Used to find the bot's existing message
-- again if its stored id is lost, so it's edited instead of re-posted.
Config.KindTags = { leaderboard = "Leaderboard", live = "Live", results = "Results" }

-- Live-race embed: how often (seconds) to edit the running order. Keep >= 10 to
-- stay well under Discord's per-route rate limits.
Config.LiveUpdateSeconds = 15

-- Auto-refresh the leaderboard embed on this interval (minutes). It also
-- refreshes immediately after every race. Set 0 to only refresh on race end.
Config.LeaderboardRefreshMinutes = 10
Config.LeaderboardTopN = 10

-- Cosmetics
Config.Brand = {
    name   = "SPiceZ Racing",
    color  = 0xFF6200,             -- accent (orange)
    green  = 0x22C55E,
    red    = 0xEF4444,
    icon   = "https://raw.githubusercontent.com/SPiceZ21/spz-txrecipe/main/Logo.png",
    footer = "SPiceZ-Core",
}

-- ── Guild (whitelist + admin mode) ──────────────────────────────────────────
-- The bot (same token) must be IN this guild. `setr`/`set spz_discord_guild "id"`
-- in server.cfg overrides `id` here. Role ids: Discord → Server Settings →
-- Roles → right-click → Copy Role ID (needs Developer Mode on).
Config.Guild = {
    id = "",
    cacheSeconds = 60,      -- how long a member's roles are reused before re-asking Discord
}

-- Only guild members holding one of these roles may connect.
-- Leave `roles` empty to admit ANY guild member.
Config.Whitelist = {
    enabled  = false,       -- turn on once Guild.id (and roles) are filled in
    roles    = {            -- e.g. "123456789012345678"
    },
    -- Discord down / misconfigured: false = refuse joins, true = let everyone in.
    failOpen = false,
    -- Always admitted, even if Discord is unreachable. Full identifier strings.
    bypass   = {
    },
    messages = {
        noDiscord   = "Link Discord to FiveM (open Discord before FiveM) to join this server.",
        notInGuild  = "Join our Discord server to play here.",
        noRole      = "You need the whitelist role in our Discord to join.",
        unavailable = "Whitelist check is unavailable right now — try again in a minute.",
    },
}

-- Discord role → ACE group. Holding the role makes you ELIGIBLE; /adminmode
-- switches the groups on and off. group.admin carries spz.admin etc. (server.cfg).
Config.AdminMode = {
    command    = "adminmode",   -- /adminmode, /adminmode on, /adminmode off
    autoOnJoin = false,         -- true = eligible staff join already in admin mode
    roles = {
        -- ["123456789012345678"] = "group.admin",
        -- ["234567890123456789"] = "group.moderator",
    },
}
