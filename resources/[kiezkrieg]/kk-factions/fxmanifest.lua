fx_version 'cerulean'
game 'gta5'

name 'KiezKrieg Factions'
description 'KiezKrieg - Faction system for gangwar and team management'
author 'KiezKrieg Team'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'kk-core',
    'kk-ui'
}

lua54 'yes'