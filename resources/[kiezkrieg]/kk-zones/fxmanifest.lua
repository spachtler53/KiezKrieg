fx_version 'cerulean'
game 'gta5'

name 'kk-zones'
description 'KiezKrieg Zone Management System'
author 'KiezKrieg Team'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'shared/config.lua',
    'shared/functions.lua'
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
    'oxmysql',
    'kk-core',
    'kk-ui'
}

lua54 'yes'