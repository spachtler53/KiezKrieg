fx_version 'cerulean'
game 'gta5'

name 'KiezKrieg UI'
description 'KiezKrieg - User Interface with modern blue-pink gradient design'
author 'KiezKrieg Team'
version '1.0.0'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*'
}

dependencies {
    'kk-core'
}

lua54 'yes'