fx_version 'cerulean'
game 'gta5'

name 'KiezKrieg Admin'
description 'KiezKrieg - Admin system with duty, teleport, and management functions'
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
    'kk-core'
}

lua54 'yes'