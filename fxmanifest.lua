
fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Abdulkadir Aktas'
description 'Native Battle Pass system for RedM with Qadr_ui'
version '1.2.1'

ui_page 'client/html/dist/index.html'

files {
    'client/html/dist/index.html',
    'client/html/dist/assets/*.js',
    'client/html/dist/assets/*.css',
    'client/html/dist/assets/*.png',
    'client/html/dist/locales/en/*.json',
}
shared_script {
    "shared/conf.lua",
    "locales/*.lua",
    "shared/localization.lua",
}

client_script {
    "client/*.lua",
}

server_script {
    '@oxmysql/lib/MySQL.lua', -- oxmysql kütüphanesi
    "server/server.lua",
}

lua54 'yes'
    