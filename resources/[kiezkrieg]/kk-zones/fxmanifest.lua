fx_version 'cerulean'
game 'gta5'

author 'KiezKrieg Development Team'
description 'KiezKrieg - Zone Management System'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

dependencies {
    'kk-core'
}