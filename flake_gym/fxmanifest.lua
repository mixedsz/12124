fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'flake'
description 'flake_gym'
version '2.0.1'

shared_scripts {
    'config/config.lua',
    'config/config.management.lua',
    'config/config.translation.lua',
}

client_scripts {
    'client/*.lua',
    'config/config.client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
    'config/config.server.lua',
}

ui_page 'html/index.html'

files {
    'html/*.*',
    'html/**/*.*',
    'config/*.json'
}

escrow_ignore {
    'config/*.lua',
    'server/version_check.lua'
}

dependency '/assetpacks'
