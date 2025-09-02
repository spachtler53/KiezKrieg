fx_version 'cerulean'
game 'gta5'

name 'kk-admin'
description 'KiezKrieg Admin System'
author 'KiezKrieg Team'
version '1.0.0'

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