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
    results     = "",   -- one embed per finished race → doubles as history log
}

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

-- ISO alpha-2 → regional-indicator flag emoji for names (nil-safe).
Config.ShowFlags = true
