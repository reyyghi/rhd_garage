fx_version 'cerulean'
game 'gta5'
version '1.3.4'
author 'Reyghita Hafizh Firmanda'
description 'Garage system for ESX & QBCore made by RHD Team'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
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
    'server/storage.lua',
    'server/vehicle.lua',
    'server/version.lua',
    'server/command.lua',
}

files {
    'modules/zone.lua',
    'modules/deformation.lua',
    'modules/spawnpoint.lua',
    'modules/pedcreator.lua',
    'data/customname.lua',
    'data/pedlist.lua',
    'data/garage.lua',
    'locales/*.json',
}

ox_lib "locale"

dependencies {
    'ox_lib'
}

lua54 'yes'
