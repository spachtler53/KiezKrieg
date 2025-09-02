fx_version 'cerulean'
game 'gta5'

name 'kk-ui'
description 'KiezKrieg User Interface'
author 'KiezKrieg Team'
version '1.0.0'

ui_page 'html/index.html'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*.png',
    'html/assets/*.jpg'
}

dependencies {
    'kk-core'
}

lua54 'yes'