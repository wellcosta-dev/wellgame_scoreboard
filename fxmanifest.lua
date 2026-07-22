fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'wellcosta-dev | Kostyál Árpád | wellcosta.dev'
description 'Wellcosta scoreboard — v4 layout port for QBCore / FiveM'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

dependency 'qb-core'
