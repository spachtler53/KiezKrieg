fx_version 'cerulean'
game 'gta5'

author 'KiezKrieg Development Team'
description 'KiezKrieg - Faction System'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'es_extended',
    'kk-core',
    'kk-database'
}