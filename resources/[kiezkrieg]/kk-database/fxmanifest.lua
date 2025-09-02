fx_version 'cerulean'
game 'gta5'

author 'KiezKrieg Development Team'
description 'KiezKrieg - Database Setup and Management'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'oxmysql'
}