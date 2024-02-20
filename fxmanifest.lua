fx_version 'cerulean'
game 'gta5'
author 'Reyghita Hafizh Firmanda'
version '1.3.4'

client_scripts {
    'bridge/framework/**/client.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/framework/**/server.lua',
    'server/main.lua',
    'server/police_impound.lua',
    'server/dbformat.lua',
    'server/storage.lua',
    'server/version.lua',
    'server/command.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/shared.lua',
    'shared/config.lua'
}

files {
    'modules/utils.lua',
    'modules/zone.lua',
    'modules/deformation.lua',

    'data/customname.lua',
    'data/garage.lua',

    'locales/*.json',
}

ox_lib "locale"

dependencies {
    'ox_lib'
}

lua54 'yes'
