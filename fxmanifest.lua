fx_version 'cerulean'
game 'gta5'

name 'spz-discord'
description 'SPiceZ-Core — Discord: race embeds, guild-role whitelist, role-based admin mode'
version '1.2.0'
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
}

dependencies {
    'spz-core',
    'spz-races',
    'oxmysql',
}
