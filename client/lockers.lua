
-- kq_link / client/lockers.lua
-- Interact with: (a) known "safe" props near player, (b) coordinate-defined lockers from config.
local nearLocker = nil   -- { x,y,z,h, source='prop'|'static' }

local function canUse()
    return Config and Config.Lockers and Config.Lockers.Enable ~= false
end

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
                        bestDist = d
                        best = { x=o.x, y=o.y, z=o.z, h=GetEntityHeading(entity) or 0.0, source='prop' }
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
        if d < (maxDist or 3.0) and d < bestDist then
            bestDist = d
            best = { x=x, y=y, z=z, h=h, source='static' }
        end
    end
    return best
end

CreateThread(function()
    while true do
        Wait(0)
        if not canUse() then Wait(1000) goto continue end
        local maxD = (Config.Lockers and Config.Lockers.MaxDistance) or 1.5

        -- choose the closest between a prop-based locker and a static coordinate locker
        local a = findNearbyPropLocker(maxD + 1.0)  -- allow tiny slack
        local b = findNearbyStaticLocker(maxD)
        if a and b then
            local ped = PlayerPedId()
            local p = GetEntityCoords(ped)
            local da = #(p - vector3(a.x,a.y,a.z))
            local db = #(p - vector3(b.x,b.y,b.z))
            nearLocker = (da <= db) and a or b
        else
            nearLocker = a or b
        end

        if nearLocker and (Config.Lockers.ShowPrompt ~= false) then
            draw3d(nearLocker.x, nearLocker.y, nearLocker.z + 1.0, Config.Lockers.Prompt or 'Press ~INPUT_PICKUP~ to open locker')
            if IsControlJustPressed(0, 38) then -- E
                TriggerServerEvent("kq_link:reqLockerContentsAt", nearLocker.x, nearLocker.y, nearLocker.z, nearLocker.h or 0.0)
            end
        else
            Wait(250)
        end
        ::continue::
    end
end)
