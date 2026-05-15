fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author      'vames™️'
description 'vms_gym'
version     '2.0.1'

shared_scripts {
    'config/config.lua',
    'config/config.management.lua',
    'config/config.translation.lua',
}

client_scripts {
    'config/config.client.lua',
    'client/client.lua',
    'client/nui.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config/config.server.lua',
    'server/version_check.lua',
    'server/server.lua',
}

ui_page 'html/index.html'

files {
    'html/*.*',
    'html/**/*.*',
    'config/*.json',
}

escrow_ignore {
    'config/*.lua',
    'server/version_check.lua',
}

dependency '/assetpacks'
