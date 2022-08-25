fx_version 'adamant'
game 'gta5'

server_scripts {
  'config.lua',
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}

client_scripts {
  'config.lua',
  'client.lua'
}

exports {
  'sim'
}