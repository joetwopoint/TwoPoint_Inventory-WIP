
-- kq_link / client/npc_sell.lua
-- Has-drugs cache (server-confirmed)
local _hasDrugs = false
local _lastCheck = 0
RegisterNetEvent("kq_link:retHasDrugs", function(val)
    _hasDrugs = (val == true)
end)

local function requestHasDrugsThrottle()
    local now = GetGameTimer()
    if (now - _lastCheck) >= 1000 then
        _lastCheck = now
        TriggerServerEvent("kq_link:reqHasDrugs")
    end
end

local cd = 0
local function canSell()
    return Config and Config.Sell and Config.Sell.Enable ~= false
end

local function isUsablePed(ped)
    if not ped or ped == 0 then return false end
    if IsPedAPlayer(ped) then return false end
    if IsPedDeadOrDying(ped) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    if IsPedFleeing(ped) or IsPedRunning(ped) then return false end
    return true
end

local function nearbyPed(maxDist)
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    -- Sample nearby peds
    local handle, outPeds = FindFirstPed(), {}
    local success, entity = true, 0
    repeat
        success, entity = FindNextPed(handle)
        if success and isUsablePed(entity) then
            local pos = GetEntityCoords(entity)
            local dist = #(pcoords - pos)
            if dist <= maxDist then
                EndFindPed(handle)
                return entity, dist
            end
        end
    until not success
    EndFindPed(handle)
    return nil, -1.0
end

CreateThread(function()
    while true do
        Wait(0)
        if not canSell() then Wait(1000) goto continue end
        local cfg = Config.Sell
        local ped, dist = nearbyPed(cfg.MaxDistance or 1.5)
        if ped then requestHasDrugsThrottle() if _hasDrugs then -- Simple 3D text prompt
            local pcoords = GetEntityCoords(ped)
            local onScreen,_x,_y = World3dToScreen2d(pcoords.x, pcoords.y, pcoords.z + 1.0)
            if onScreen then
                SetTextFont(0); SetTextProportional(1); SetTextScale(0.35,0.35)
                SetTextColour(255,255,255,215); SetTextCentre(true)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(cfg.Prompt or "Press ~INPUT_PICKUP~ to sell")
                EndTextCommandDisplayText(_x, _y)
            end
            if (GetGameTimer() - cd) >= (cfg.Cooldown or 3000) then
                -- E key / INPUT_PICKUP or INPUT_CONTEXT. Default control index 38 (E).
                if IsControlJustPressed(0, cfg.KeyControl or 38) then
                    cd = GetGameTimer()
                    TriggerServerEvent("kq_link:tryNpcSell")
                end
            end
        else
            Wait(250)
        end
        ::continue::
    end
end)
