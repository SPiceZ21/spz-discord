fx_version 'cerulean'
game 'gta5'

name 'spz-discord'
description 'SPiceZ-Core — Discord embeds: live races, results/history, leaderboard'
version '1.0.0'
author 'SPiceZ-Core'

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/discord.lua',
    'server/feeds.lua',
}

dependencies {
    'spz-core',
    'spz-races',
    'oxmysql',
}
