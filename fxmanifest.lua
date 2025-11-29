fx_version 'cerulean'
game 'gta5'

name 'TwoPoint_Inventory'
author 'TwoPoint Development'
description 'Standalone SQL inventory + wallet + NPC selling + lockers for KQ Drug Empire (vMenu).'
version '1.0.0'

lua54 'yes'

client_scripts {
  'client/npc_sell.lua',
  'client/lockers.lua',
  'client/weapons.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db.lua',
  'server/link.lua'
}
