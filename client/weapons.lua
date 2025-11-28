-- kq_link / client/weapons.lua
-- Enumerate weapons for /search to also list weapons (vMenu replacements + addon names).

local BASE_WEAPONS = {
  -- Melee / utility
  "WEAPON_KNIFE","WEAPON_BAT","WEAPON_CROWBAR","WEAPON_FLASHLIGHT","WEAPON_NIGHTSTICK",
  -- Pistols
  "WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL","WEAPON_PISTOL50","WEAPON_SNSPISTOL","WEAPON_HEAVYPISTOL","WEAPON_VINTAGEPISTOL",
  -- SMG
  "WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG","WEAPON_MINISMG","WEAPON_MG","WEAPON_COMBATMG",
  -- Shotguns
  "WEAPON_PUMPSHOTGUN","WEAPON_SAWNOFFSHOTGUN","WEAPON_ASSAULTSHOTGUN","WEAPON_BULLPUPSHOTGUN","WEAPON_HEAVYSHOTGUN",
  -- Rifles
  "WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_ADVANCEDRIFLE","WEAPON_SPECIALCARBINE","WEAPON_BULLPUPRIFLE","WEAPON_COMPACTRIFLE",
  -- Snipers
  "WEAPON_SNIPERRIFLE","WEAPON_HEAVYSNIPER","WEAPON_MARKSMANRIFLE",
  -- Less lethal / utility
  "WEAPON_STUNGUN"
}

local function normalizeLabel(name)
  if not name then return "Weapon" end
  local pretty = name:gsub("WEAPON_", ""):gsub("_", " "):lower()
  return pretty:gsub("^%l", string.upper)
end

local function collectWeapons()
  local ped = PlayerPedId()
  local out = {}

  -- merge base + addon list from config
  local list = {}
  for _, n in ipairs(BASE_WEAPONS) do list[#list+1] = n end
  local extra = (Config and Config.WeaponDetect and Config.WeaponDetect.AddonNames) or {}
  for _, n in ipairs(extra) do list[#list+1] = n end

  for _, name in ipairs(list) do
    local hash = GetHashKey(name)
    if HasPedGotWeapon(ped, hash, false) then
      local ammo = 0
      if name ~= "WEAPON_KNIFE" and name ~= "WEAPON_BAT" and name ~= "WEAPON_CROWBAR" and name ~= "WEAPON_FLASHLIGHT" and name ~= "WEAPON_NIGHTSTICK" then
        ammo = GetAmmoInPedWeapon(ped, hash) or 0
      end
      local label = (Config and Config.WeaponDetect and Config.WeaponDetect.Labels and Config.WeaponDetect.Labels[name]) or normalizeLabel(name)
      out[#out+1] = { label = label, item = name, ammo = ammo }
    end
  end
  return out
end

RegisterNetEvent("kq_link:reqWeapons", function(requesterId)
  local list = collectWeapons()
  TriggerServerEvent("kq_link:retWeapons", requesterId, list)
end)
