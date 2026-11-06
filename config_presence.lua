-- config_presence.lua — Discord Rich Presence (was spz-rpc). Client side.
--
-- Create an app at https://discord.com/developers/applications, upload the art
-- under Rich Presence → Art Assets, and put its Application ID below, or in
-- server.cfg:  setr spz_discord_appid "123..."  (the convar wins).
-- Empty = no rich presence.

Presence = {
    AppId      = '',
    ServerName = 'SPiceZ Racing',
    ServerUrl  = '',          -- "Join Server" button (cfx.re/join/xxxx); '' = no button

    -- Discord ignores updates faster than ~15 s.
    UpdateIntervalMs = 15000,

    -- Art asset names, as uploaded in the Discord app.
    Assets = {
        logo     = 'spz_logo',       -- default / small badge
        freeroam = 'spz_freeroam',
        queue    = 'spz_queue',
        polling  = 'spz_polling',
        staging  = 'spz_staging',    -- on the grid
        racing   = 'spz_racing',
        dnf      = 'spz_dnf',        -- small badge after a DNF
    },

    -- Race class → label and small badge asset.
    Classes = {
        [0] = { label = 'Class C', asset = 'spz_class_c' },
        [1] = { label = 'Class B', asset = 'spz_class_b' },
        [2] = { label = 'Class A', asset = 'spz_class_a' },
        [3] = { label = 'Class S', asset = 'spz_class_s' },
    },
}
