fx_version 'cerulean'
game 'gta5'

name 'spz-discord'
description 'SPiceZ-Core — Discord: race feeds, logs, rich presence, guild-role whitelist, role-based admin mode'
version '1.2.2'
author 'SPiceZ-Core'

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/discord.lua',
    'server/feeds.lua',
    'server/guild.lua',
    'server/whitelist.lua',
    'server/adminmode.lua',
    'server/logs.lua',
}

client_scripts {
    'config_presence.lua',
    'client/presence.lua',
    'client/logs.lua',
}

dependencies {
    'spz-core',
    'spz-races',
    'oxmysql',
}
