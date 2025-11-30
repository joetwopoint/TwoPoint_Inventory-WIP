fx_version 'cerulean'
game 'gta5'

-- make config available on both sides
shared_scripts {
  'config.lua'
}

client_scripts {
  'client/npc_sell.lua',
  'client/lockers.lua',
  'client/weapons.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config.lua',         -- keep this before db/link (extra-safe ordering)
  'server/db.lua',
  'server/link.lua'
}

lua54 'yes'