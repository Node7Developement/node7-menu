fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'NODE7 DEVELOPMENT STUDIOS'
description 'NODE7 premium RedM menu API for NODE7 resources'
version '1.0.6'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/app.css',
    'html/css/*.png',
    'html/js/mustache.min.js',
    'html/js/app.js',
    'html/fonts/*.ttf'
}

dependency 'node7-core'
