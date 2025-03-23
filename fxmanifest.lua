
fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Abdulkadir Aktas'
description 'Native Battle Pass system for RedM with Qadr_ui'
version '1.0.0'

ui_page 'client/html/dist/index.html'

files {
    'client/html/dist/index.html',
    'client/html/dist/assets/*.js',
    'client/html/dist/assets/*.css',
    'client/html/dist/assets/*.png',
    'client/html/dist/locales/en/*.json',
    'client/html/dist/locales/tr/*.json',
}
shared_script {
    "shared/conf.lua",
    "lang/*.lua",
    "shared/dataview.lua",
    "shared/functions.lua",
}

client_script {
    "client/*.lua",
}

server_script {
    '@oxmysql/lib/MySQL.lua', -- oxmysql kütüphanesi
    "server/verification.lua",
    "server/server.lua",
}

escrow_ignore {
    "README.md",
    "shared/conf.lua",
    "lang/*.lua",
    "shared/dataview.lua",
}

lua54 'yes'
    