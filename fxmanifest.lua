fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author '1OSaft'
description 'Reworked Methcar from Kuzkay'
version '2.0.4'

dependencies {'es_extended', 'ox_lib'}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'client_config.lua',
    'locales/*.lua',
}
client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/*.lua',
    'logs/config.log.lua'
}
