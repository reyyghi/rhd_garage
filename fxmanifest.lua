fx_version 'cerulean'
game 'gta5'
version '1.4.2'
author 'Reyghita Hafizh Firmanda'
description 'Garage system for ESX & QB made by RHD Team'

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
    'modules/bridge/init.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/version.lua',
}

files {
	'web/build/index.html',
	'web/build/**/*',

    'config/*.lua',
    'modules/bridge/**/*.lua',
    'modules/core/*.lua',
    'modules/utils/*.lua',
}


dependencies {
    'ox_lib',
}

lua54 'yes'
