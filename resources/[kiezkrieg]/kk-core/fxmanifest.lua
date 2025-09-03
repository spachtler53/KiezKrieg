fx_version 'cerulean'
game 'gta5'

name 'kk-core'
description 'KiezKrieg Core Framework'
author 'KiezKrieg Team'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
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
    'es_extended',
    'oxmysql'
}

lua54 'yes'