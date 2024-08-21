fx_version 'cerulean'
game 'gta5'

shared_scripts {
	'@ox_lib/init.lua',
	-- 'bridge/**/**/*.js'
}

client_scripts {
	'build/client/**/*.js'
}

server_scripts {
	'build/server/**/*.js'
}
files {
	'shared/config.lua',
}

lua54 'yes'