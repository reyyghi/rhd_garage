fx_version 'cerulean'
game 'gta5'
author 'Reyghita Hafizh Firmanda'
version '1.3.4'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'bridge/houses/*.lua',
    'bridge/framework/*.lua'
}

client_scripts {
    'bridge/radialmenu/*.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/police_impound.lua',
    'server/dbformat.lua',
    'server/storage.lua',
    'server/vehicle.lua',
    'server/version.lua',
    'server/command.lua',
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
