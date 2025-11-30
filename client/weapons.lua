\
-- TwoPoint_Inventory weapons enumerator (client)
-- Uses HAS_PED_GOT_WEAPON: https://docs.fivem.net/natives/?_0x8DECB02F88F428BC

local WeaponList = {
    `WEAPON_PISTOL`,
    `WEAPON_COMBATPISTOL`,
    `WEAPON_APPISTOL`,
    `WEAPON_PISTOL50`,
    `WEAPON_SNSPISTOL`,
    `WEAPON_HEAVYPISTOL`,
    `WEAPON_VINTAGEPISTOL`,
    `WEAPON_MICROSMG`,
    `WEAPON_SMG`,
    `WEAPON_ASSAULTSMG`,
    `WEAPON_MINISMG`,
    `WEAPON_MACHINEPISTOL`,
    `WEAPON_PUMPSHOTGUN`,
    `WEAPON_SAWNOFFSHOTGUN`,
    `WEAPON_BULLPUPSHOTGUN`,
    `WEAPON_ASSAULTRIFLE`,
    `WEAPON_CARBINERIFLE`,
    `WEAPON_ADVANCEDRIFLE`,
    `WEAPON_SPECIALCARBINE`,
    `WEAPON_BULLPUPRIFLE`,
    `WEAPON_COMPACTRIFLE`,
    `WEAPON_MG`,
    `WEAPON_COMBATMG`,
    `WEAPON_SNIPERRIFLE`,
    `WEAPON_HEAVYSNIPER`,
    `WEAPON_MARKSMANRIFLE`,
    `WEAPON_STUNGUN`,
    `WEAPON_TASER`,
    `WEAPON_BZGAS`,
    `WEAPON_FLASHLIGHT`,
    `WEAPON_NIGHTSTICK`,
    `WEAPON_FIREEXTINGUISHER`
}

local Label = {}
for _, key in ipairs(WeaponList) do Label[key] = tostring(key) end
Label[GetHashKey('WEAPON_PISTOL')] = 'Pistol'
Label[GetHashKey('WEAPON_COMBATPISTOL')] = 'Combat Pistol'
Label[GetHashKey('WEAPON_APPISTOL')] = 'AP Pistol'
Label[GetHashKey('WEAPON_PISTOL50')] = 'Pistol .50'
Label[GetHashKey('WEAPON_SNSPISTOL')] = 'SNS Pistol'
Label[GetHashKey('WEAPON_HEAVYPISTOL')] = 'Heavy Pistol'
Label[GetHashKey('WEAPON_VINTAGEPISTOL')] = 'Vintage Pistol'
Label[GetHashKey('WEAPON_MICROSMG')] = 'Micro SMG'
Label[GetHashKey('WEAPON_SMG')] = 'SMG'
Label[GetHashKey('WEAPON_ASSAULTSMG')] = 'Assault SMG'
Label[GetHashKey('WEAPON_MINISMG')] = 'Mini SMG'
Label[GetHashKey('WEAPON_MACHINEPISTOL')] = 'Machine Pistol'
Label[GetHashKey('WEAPON_PUMPSHOTGUN')] = 'Pump Shotgun'
Label[GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = 'Sawed-off Shotgun'
Label[GetHashKey('WEAPON_BULLPUPSHOTGUN')] = 'Bullpup Shotgun'
Label[GetHashKey('WEAPON_ASSAULTRIFLE')] = 'Assault Rifle'
Label[GetHashKey('WEAPON_CARBINERIFLE')] = 'Carbine Rifle'
Label[GetHashKey('WEAPON_ADVANCEDRIFLE')] = 'Advanced Rifle'
Label[GetHashKey('WEAPON_SPECIALCARBINE')] = 'Special Carbine'
Label[GetHashKey('WEAPON_BULLPUPRIFLE')] = 'Bullpup Rifle'
Label[GetHashKey('WEAPON_COMPACTRIFLE')] = 'Compact Rifle'
Label[GetHashKey('WEAPON_MG')] = 'MG'
Label[GetHashKey('WEAPON_COMBATMG')] = 'Combat MG'
Label[GetHashKey('WEAPON_SNIPERRIFLE')] = 'Sniper Rifle'
Label[GetHashKey('WEAPON_HEAVYSNIPER')] = 'Heavy Sniper'
Label[GetHashKey('WEAPON_MARKSMANRIFLE')] = 'Marksman Rifle'
Label[GetHashKey('WEAPON_STUNGUN')] = 'Taser'
Label[GetHashKey('WEAPON_TASER')] = 'Taser'
Label[GetHashKey('WEAPON_BZGAS')] = 'BZ Gas'
Label[GetHashKey('WEAPON_FLASHLIGHT')] = 'Flashlight'
Label[GetHashKey('WEAPON_NIGHTSTICK')] = 'Nightstick'
Label[GetHashKey('WEAPON_FIREEXTINGUISHER')] = 'Fire Extinguisher'

RegisterNetEvent('TwoPoint_Inventory:reqWeapons', function()
    local ped = PlayerPedId()
    local have = {}
    for _, hash in ipairs(WeaponList) do
        if HasPedGotWeapon(ped, hash, false) then
            table.insert(have, Label[hash] or tostring(hash))
        end
    end
    TriggerServerEvent('TwoPoint_Inventory:retWeapons', have)
end)
