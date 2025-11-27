fx_version '1.0.4'
game 'gta5'
lua54 'yes'

name 'kq_link'
author 'TwoPoint Development'
description 'Standalone kq_link layer + SQL inventory for KuzQuality Drug Empire (vMenu). Money calls only show notifications.'
version '1.0.4'

shared_script 'config.lua'

server_scripts {
    'server/db.lua',
    'server/inventory.lua',
    'server/link.lua'
}

client_scripts {
    'client/notify.lua'
}

server_export 'AddPlayerItem'
server_export 'AddPlayerItemToFit'
server_export 'RemovePlayerItem'
server_export 'GetPlayerItemCount'
server_export 'GetPlayerItemData'
server_export 'AddPlayerMoney'
server_export 'RemovePlayerMoney'
server_export 'GetPlayersWithJob'
server_export 'RegisterUsableItem'
server_export 'Notify'
