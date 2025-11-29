local function draw3d(x,y,z, text)
  SetTextFont(0); SetTextProportional(1); SetTextScale(0.35,0.35)
  SetTextColour(255,255,255,220); SetTextCentre(true)
  SetDrawOrigin(x, y, z, 0)
  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(0.0, 0.0)
  ClearDrawOrigin()
end

local function findNearbyPropLocker(maxDist)
  local models = (Config.Lockers and Config.Lockers.Models) or {}
  if not models or #models == 0 then return nil end
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local handle, obj = FindFirstObject(), 0
  local found, bestDist, best = true, 9e9, nil
  repeat
    local ok, entity = FindNextObject(handle)
    found = ok
    if ok and DoesEntityExist(entity) then
      local mh = GetEntityModel(entity)
      for _, m in ipairs(models) do
        local h = type(m) == 'number' and m or GetHashKey(m)
        if mh == h then
          local o = GetEntityCoords(entity)
          local d = #(p - o)
          if d < (maxDist or 3.0) and d < bestDist then
            bestDist = d; best = { x=o.x, y=o.y, z=o.z, h=GetEntityHeading(entity) or 0.0 }
          end
        end
      end
    end
  until not found
  EndFindObject(handle)
  return best
end

local function findNearbyStaticLocker(maxDist)
  local list = (Config.Lockers and Config.Lockers.Static) or {}
  if not list or #list == 0 then return nil end
  local ped = PlayerPedId()
  local p = GetEntityCoords(ped)
  local best, bestDist = nil, 9e9
  for _, t in ipairs(list) do
    local x,y,z,h = t[1],t[2],t[3],t[4] or 0.0
    local d = #(p - vector3(x,y,z))
    if d < (maxDist or 3.0) and d < bestDist then bestDist = d; best = { x=x,y=y,z=z,h=h } end
  end
  return best
end

RegisterNetEvent("kq_link:retLockerContents", function(items, cash)
  cash = tonumber(cash or 0) or 0
  if (not items or next(items) == nil) and cash == 0 then
    TriggerEvent('chat:addMessage', { args = { 'Locker', 'Empty.' } })
    return
  end
  TriggerEvent('chat:addMessage', { args = { 'Locker', 'Contents:' } })
  if cash > 0 then TriggerEvent('chat:addMessage', { args = { ('Cash: $%d'):format(cash) } }) end
  for name, count in pairs(items or {}) do
    local label = (ItemDefs[name] and ItemDefs[name].label) or name
    TriggerEvent('chat:addMessage', { args = { string.format('%s x%d', label, count) } })
  end
end)

CreateThread(function()
  while true do
    Wait(0)
    if not (Config.Lockers and Config.Lockers.Enable ~= false) then Wait(1000) goto continue end
    local maxD = (Config.Lockers and Config.Lockers.MaxDistance) or 1.5
    local a = findNearbyPropLocker(maxD + 1.0)
    local b = findNearbyStaticLocker(maxD)
    local near = a or b
    if near then
      draw3d(near.x, near.y, near.z + 1.0, Config.Lockers.Prompt or 'Press ~INPUT_PICKUP~ to open locker')
      if IsControlJustPressed(0, 38) then
        TriggerServerEvent("kq_link:reqLockerContentsAt", near.x, near.y, near.z, near.h or 0.0)
      end
    else
      Wait(250)
    end
    ::continue::
  end
end)
