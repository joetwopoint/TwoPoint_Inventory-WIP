
-- === Postal lookup (uses BigDaddy-PostalMap/dev/postals.json) ===
local _Postals = nil

local function _stripJsonComments(str)
    local out = {}
    for line in string.gmatch(str or "", "[^\r\n]+") do
        if not line:match("^%s*//") then table.insert(out, line) end
    end
    return table.concat(out, "\n")
end

local function _loadPostals()
    if _Postals ~= nil then return end
    local raw = LoadResourceFile('BigDaddy-PostalMap', 'dev/postals.json')
    if not raw then
        print("^1[kq_link]^7 Postal file not found in BigDaddy-PostalMap/dev/postals.json")
        _Postals = {}
        return
    end
    local clean = _stripJsonComments(raw)
    local ok, arr = pcall(function() return json.decode(clean) end)
    if not ok or type(arr) ~= "table" then
        print("^1[kq_link]^7 Failed to parse postals.json")
        _Postals = {}
        return
    end
    _Postals = arr
end

local function _nearestPostal(x, y)
    _loadPostals()
    local best, bestD = nil, 1e18
    for i=1, (#_Postals or 0) do
        local p = _Postals[i]
        local dx, dy = (x - (p.X or p.x or 0.0)), (y - (p.Y or p.y or 0.0))
        local d = dx*dx + dy*dy
        if d < bestD then
            bestD = d
            best = p
        end
    end
    return best and (best.code or best.postal or tostring(best.P or "")) or nil
end

-- === On-duty tracking via PoliceEMSActivity (eblips) ===
local _OnDutyLEO = {}  -- [src] = { tag = 'TPD'/'PCSO'/..., name = 'TPDPlayer' }
local _PostalHeatCooldown = {}  -- [postal] = lastAlertTick

AddEventHandler('eblips:add', function(info)
    -- info: { name = tag .. playerName, src = source, color = n }
    if type(info) == 'table' and info.src then
        local tag = nil
        if type(info.name) == 'string' then
            -- Extract leading non-space token (handles '👮 TPD' or 'TPD')
            local first = info.name:match('^([^%s]+)')
            if first then
                -- Remove emoji prefix if present (keeps last token)
                local t = first
                if t:find('%a') then tag = t:gsub('[^%a]', '') end
            end
        end
        _OnDutyLEO[tonumber(info.src)] = { tag = tag or 'UNK', name = tostring(info.name or '') }
    end
end)

AddEventHandler('eblips:remove', function(src)
    _OnDutyLEO[tonumber(src)] = nil
end)

AddEventHandler('playerDropped', function()
    _OnDutyLEO[source] = nil
end)


-- Helper: find nearest player to src within maxDist (server-side; OneSync)
local function _FindNearestPlayer(src, maxDist)
    local pedA = GetPlayerPed(src)
    if not pedA or pedA == 0 then return nil, -1.0 end
    local ax, ay, az = table.unpack(GetEntityCoords(pedA) or vector3(0.0, 0.0, 0.0))
    local nearest, nd = nil, 1e9
    for _, pid in ipairs(GetPlayers()) do
        local tid = tonumber(pid)
        if tid and tid ~= src and GetPlayerName(tid) then
            local pedB = GetPlayerPed(tid)
            if pedB and pedB ~= 0 then
                local bx, by, bz = table.unpack(GetEntityCoords(pedB) or vector3(0.0, 0.0, 0.0))
                local dx, dy, dz = ax - bx, ay - by, az - bz
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                if dist < nd then nearest, nd = tid, dist end
            end
        end
    end
    if maxDist and maxDist > 0 and nd > maxDist then return nil, nd end
    return nearest, nd
end

-- kq_link / server/link.lua

-- Inventory exports
exports("AddPlayerItem", function(player, item, amount, meta) return Inv_AddItem(player, item, amount, meta) end)
exports("AddPlayerItemToFit", function(player, item, amount, meta) return Inv_AddItemToFit(player, item, amount, meta) end)
exports("RemovePlayerItem", function(player, item, amount) return Inv_RemoveItem(player, item, amount) end)
exports("GetPlayerItemCount", function(player, item) return Inv_GetCount(player, item) end)
exports("GetPlayerItemData", function(player, item) return Inv_GetData(player, item) end)

-- Money: notifications only
local function fmtMoney(amount, account)
    local sign = amount >= 0 and "+" or "-"
    local abs = math.abs(amount)
    local tag = account or "cash"
    local cur = Config.MoneyCurrency or '$'
    return string.format("%s%s%d (%s)", sign, cur, abs, tag)
end

exports("AddPlayerMoney", function(player, account, amount)
    if Config.ShowMoneyNotifications then
        TriggerClientEvent("kq_link:notify", player, ("Money received: %s"):format(fmtMoney(tonumber(amount) or 0, account)), "success")
    end
    return true
end)

exports("RemovePlayerMoney", function(player, account, amount)
    if Config.ShowMoneyNotifications then
        TriggerClientEvent("kq_link:notify", player, ("Money removed: %s"):format(fmtMoney(-(tonumber(amount) or 0), account)), "warning")
    end
    return true
end)

-- Jobs stub
exports("GetPlayersWithJob", function(job)
    if Config.EnableJobs then return {} end
    return {}
end)

-- Usable items registry
local usable = {}
exports("RegisterUsableItem", function(item, cb) usable[item] = cb end)

RegisterNetEvent("kq_link:useItem", function(item)
    local src = source
    local cb = usable[item]
    if cb then cb(src, item) end
end)

-- Notify
exports("Notify", function(player, message, ntype)
    TriggerClientEvent("kq_link:notify", player, message or "", ntype or "info")
end)

-- === Shared sender + /inventory (client+server) ===
function _KQ_SendInventory(src, mode)
    local function getIdentifier(src)
        for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("license:") == 1 then return id end end
        for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("fivem:") == 1 then return id end end
        return GetPlayerIdentifier(src, 0) or ("src:"..tostring(src))
    end

    local id = getIdentifier(src)
    if not Inventories[id] or not Inventories[id].loaded then
        local rows = DB.fetchAll([[SELECT item,amount FROM kqde_inventories WHERE identifier = ?]], { id })
        local items = {}
        for _, r in ipairs(rows or {}) do
            local amt = math.floor(tonumber(r.amount) or 0)
            if amt > 0 then items[r.item] = amt end
        end
        Inventories[id] = { items = items, loaded = true }
    end

    local coll = {}
    for k,v in pairs(Inventories[id].items or {}) do
        local label = (ItemDefs[k] and ItemDefs[k].label) and ItemDefs[k].label or k
        table.insert(coll, {item=k, label=label, count=v})
    end

    mode = tostring(mode or ""):lower()
    if mode == 'count' then
        table.sort(coll, function(a,b) if a.count == b.count then return a.label:lower() < b.label:lower() end return a.count > b.count end)
    else
        table.sort(coll, function(a,b) return a.label:lower() < b.label:lower() end)
    end

    if GetResourceState('chat') == 'started' or GetResourceState('chat') == 'starting' then
        if #coll == 0 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', '(empty)' } })
        else
            TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', 'Items:' } })
            for _, row in ipairs(coll) do
                TriggerClientEvent('chat:addMessage', src, { args = { string.format('%s x%s', row.label or row.item, tostring(row.count or 0)) } })
            end
        end
    else
        TriggerClientEvent("kq_link:showInventory", src, coll)
    end
end

RegisterNetEvent("kqdei:requestInventory", function(mode)
    local src = source
    _KQ_SendInventory(src, mode)
end)

RegisterCommand("inventory", function(src, args, raw)
    if src == 0 then
        print("^1[kq_link]^7 /inventory is player-only")
        return
    end
    local mode = (args and (args[1] or args[0])) or ""
    _KQ_SendInventory(src, mode)
end, false)

-- === /give <playerId> <item> <amount> ===

-- Player-to-player give command (nearest-only)
-- Usage: /give <item> <amount>
RegisterCommand("give", function(src, args, raw)
    if src == 0 then
        print("^1[kq_link]^7 /give is player-only")
        return
    end
    local item = tostring(args and args[1] or ""):gsub("[^%w_%-]", "")
    local amount = math.floor(tonumber(args and args[2] or 0) or 0)
    if item == "" or amount < 1 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Usage', '/give <item> <amount>' } })
        return
    end

    local maxDist = Config.GiveMaxDistance or 1.25
    local targetId, dist = _FindNearestPlayer(src, maxDist)
    if not targetId then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', 'No player nearby.' } })
        return
    end
    if targetId == src then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', 'No valid nearby player.' } })
        return
    end

    local have = Inv_GetCount(src, item)
    if have < amount then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', ('You only have %d %s.'):format(have, item) } })
        return
    end

    local ok, why = Inv_CanHold(targetId, item, amount)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', ('Target cannot hold that: %s'):format(why or 'blocked') } })
        return
    end

    local addOk = Inv_AddItem(targetId, item, amount, nil)
    if not addOk then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', 'Failed to add to target.' } })
        return
    end
    local remOk = Inv_RemoveItem(src, item, amount)
    if not remOk then
        Inv_RemoveItem(targetId, item, amount)
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', 'Transfer failed (rollback done).' } })
        return
    end

    local label = (ItemDefs[item] and ItemDefs[item].label) or item
    TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', ('Gave %s x%d to %s'):format(label, amount, GetPlayerName(targetId)) } })
    TriggerClientEvent('chat:addMessage', targetId, { args = { 'Inventory', ('Received %s x%d from %s'):format(label, amount, GetPlayerName(src) or 'player') } })
end, false)
-- === /search <playerId> [count] (LEO tool) ===
-- Shows the target's inventory to the searching player (plain text).
-- Optional 'count' sorts by quantity desc.

-- LEO search (nearest-only)
-- Usage: /search [count]
RegisterCommand("search", function(src, args, raw)
    if src == 0 then
        print("^1[kq_link]^7 /search is player-only")
        return
    end
    if Config.Search and Config.Search.RequireAce then
        if not IsPlayerAceAllowed(src, Config.Search.Ace or 'kq_link.search') then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Error', 'You are not allowed to use /search.' } })
            return
        end
    end

    local mode = tostring(args and args[1] or ""):lower()
    local maxDist = (Config.Search and Config.Search.MaxDistance) or 1.25
    local targetId, dist = _FindNearestPlayer(src, maxDist)
    if not targetId then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'No player nearby.' } })
        return
    end
    if targetId == src then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Error', 'No valid nearby player.' } })
        return
    end

    local function getIdentifier(srcId)
        for _, id in ipairs(GetPlayerIdentifiers(srcId)) do if id:find("license:") == 1 then return id end end
        for _, id in ipairs(GetPlayerIdentifiers(srcId)) do if id:find("fivem:") == 1 then return id end end
        return GetPlayerIdentifier(srcId, 0) or ("src:"..tostring(srcId))
    end

    local id = getIdentifier(targetId)
    if not Inventories[id] or not Inventories[id].loaded then
        local rows = DB.fetchAll([[SELECT item,amount FROM kqde_inventories WHERE identifier = ?]], { id })
        local items = {}
        for _, r in ipairs(rows or {}) do
            local amt = math.floor(tonumber(r.amount) or 0)
            if amt > 0 then items[r.item] = amt end
        end
        Inventories[id] = { items = items, loaded = true }
    end

    local coll = {}
    for k,v in pairs(Inventories[id].items or {}) do
        local label = (ItemDefs[k] and ItemDefs[k].label) and ItemDefs[k].label or k
        table.insert(coll, {item=k, label=label, count=v})
    end

    if mode == 'count' then
        table.sort(coll, function(a,b) if a.count == b.count then return a.label:lower() < b.label:lower() end return a.count > b.count end)
    else
        table.sort(coll, function(a,b) return a.label:lower() < b.label:lower() end)
    end

    local targetName = GetPlayerName(targetId) or tostring(targetId)
    if #coll == 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Search', (targetName .. ' has nothing.') } })
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Search', (targetName .. ' has:') } })
        for _, row in ipairs(coll) do
            TriggerClientEvent('chat:addMessage', src, { args = { string.format('%s x%s', row.label or row.item, tostring(row.count or 0)) } })
        end
    end

    if not Config.Search or Config.Search.NotifyTarget ~= false then
        local msg = (Config.Search and Config.Search.TargetMessage) or 'You are being searched.'
        TriggerClientEvent('chat:addMessage', targetId, { args = { tostring(msg) } })
    end
end, false)




-- After search, ask target client to send weapons list
AddEventHandler("playerConnecting", function() end) -- no-op to keep pattern safe
-- Weapons reply from target client -> print to officer
RegisterNetEvent("kq_link:retWeapons", function(requester, list)
    local src = tonumber(requester)
    if not src or not GetPlayerName(src) then return end
    if not list or #list == 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'Weapons: (none)' } })
        return
    end
    TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'Weapons:' } })
    for _, w in ipairs(list) do
        local label = (w.label or w.item)
        local ammo = tonumber(w.ammo or 0) or 0
        TriggerClientEvent('chat:addMessage', src, { args = { string.format('%s (ammo: %d)', label, ammo) } })
    end
end)

-- === Wallet (SQL) ===
local function _identifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("license:") == 1 then return id end end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("fivem:") == 1 then return id end end
    return GetPlayerIdentifier(src, 0) or ("src:"..tostring(src))
end

local function _ensureWallet(id)
    DB.execute([[INSERT IGNORE INTO kqde_wallets (identifier, cash) VALUES (?, 0)]], { id })
end

local function _getCash(id)
    local val = DB.scalar([[SELECT cash FROM kqde_wallets WHERE identifier = ?]], { id })
    if val == nil then
        _ensureWallet(id)
        val = 0
    end
    return tonumber(val) or 0
end

local function _addCash(id, delta)
    _ensureWallet(id)
    DB.execute([[UPDATE kqde_wallets SET cash = cash + ? WHERE identifier = ?]], { delta, id })
    return _getCash(id)
end

local function _tryRemoveCash(id, amount)
    _ensureWallet(id)
    local cur = _getCash(id)
    if cur < amount then return false, cur end
    DB.execute([[UPDATE kqde_wallets SET cash = cash - ? WHERE identifier = ?]], { amount, id })
    return true, cur - amount
end

exports("GetPlayerMoney", function(player, account)
    local id = _identifier(player)
    return _getCash(id)
end)

exports("AddPlayerMoney", function(player, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end
    local id = _identifier(player)
    local newBal = _addCash(id, math.max(amount, 0))
    if Config.ShowMoneyNotifications then
        local cur = Config.MoneyCurrency or '$'
        TriggerClientEvent("kq_link:notify", player, ("Money received: +%s%d  (New balance: %s%d)"):format(cur, amount, cur, newBal), "success")
    end
    return true
end)

exports("RemovePlayerMoney", function(player, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local id = _identifier(player)
    local ok, newBal = _tryRemoveCash(id, amount)
    if not ok then
        if Config.ShowMoneyNotifications then
            local cur = Config.MoneyCurrency or '$'
            TriggerClientEvent("kq_link:notify", player, ("Not enough cash."):format(), "warning")
        end
        return false
    end
    if Config.ShowMoneyNotifications then
        local cur = Config.MoneyCurrency or '$'
        TriggerClientEvent("kq_link:notify", player, ("Money removed: -%s%d  (New balance: %s%d)"):format(cur, amount, cur, newBal), "warning")
    end
    return true
end)


-- /pay <amount> : pay nearest player (strict proximity)
RegisterCommand("pay", function(src, args, raw)
    if src == 0 then
        print("^1[kq_link]^7 /pay is player-only")
        return
    end
    local cfg = Config.Pay or {}
    local amount = math.floor(tonumber(args and args[1] or 0) or 0)
    if amount < (cfg.MinAmount or 1) or amount > (cfg.MaxAmount or 1000000) then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'Usage: /pay <amount>' } })
        return
    end

    local targetId, dist = _FindNearestPlayer(src, cfg.MaxDistance or 1.25)
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'No player nearby.' } })
        return
    end

    -- Funds check & transfer
    local sid = _identifier(src)
    local tid = _identifier(targetId)

    local ok, newBal = _tryRemoveCash(sid, amount)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'Insufficient funds.' } })
        return
    end
    _addCash(tid, amount)

    local cur = Config.MoneyCurrency or '$'
    if cfg.NotifyBoth ~= false then
        TriggerClientEvent('chat:addMessage', src,      { args = { 'Pay', ('Paid %s%d to %s  (New balance: %s%d)'):format(cur, amount, GetPlayerName(targetId), cur, newBal) } })
        TriggerClientEvent('chat:addMessage', targetId, { args = { 'Pay', ('Received %s%d from %s'):format(cur, amount, GetPlayerName(src) or 'player') } })
    end
end, false)


-- === Wallet flags (one-time gates) ===
local function _ensureFlagRow(id)
    DB.execute([[INSERT IGNORE INTO kqde_wallet_flags (identifier, setcash_used) VALUES (?, 0)]], { id })
end

local function _getSetcashUsed(id)
    _ensureFlagRow(id)
    local used = DB.scalar([[SELECT setcash_used FROM kqde_wallet_flags WHERE identifier = ?]], { id })
    return tonumber(used or 0) or 0
end

local function _markSetcashUsed(id)
    _ensureFlagRow(id)
    DB.execute([[UPDATE kqde_wallet_flags SET setcash_used = 1 WHERE identifier = ?]], { id })
end


-- /setcash <amount> : self-setup starting cash (gated by Config.SetCash)
RegisterCommand("setcash", function(src, args, raw)
    if src == 0 then
        print("^1[kq_link]^7 /setcash is player-only")
        return
    end
    local sc = Config.SetCash or {}
    if sc.Enable == false then
        TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', 'This command is disabled.' } })
        return
    end
    if sc.RequireAce and not IsPlayerAceAllowed(src, sc.Ace or 'kq_link.setcash') then
        TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', 'You are not allowed to use this command.' } })
        return
    end

    local amt = math.floor(tonumber(args and args[1] or 0) or 0)
    if amt < (sc.Min or 0) or amt > (sc.Max or 100000) then
        TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', ('Usage: /setcash <amount>  (min %d, max %d)'):format(sc.Min or 0, sc.Max or 100000) } })
        return
    end

    local id = _identifier(src)
    if (sc.OneTime ~= false) and _getSetcashUsed(id) == 1 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', 'You have already used /setcash.' } })
        return
    end

    local cur = _getCash(id)
    if (sc.RequireZeroBalance ~= false) and cur ~= 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', 'You can only use /setcash when your balance is 0.' } })
        return
    end

    -- Adjust balance to target amount
    local delta = amt - cur
    if delta > 0 then
        _addCash(id, delta)
    elseif delta < 0 then
        local ok = _tryRemoveCash(id, -delta)
        if not ok then
            TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', 'Unable to set the requested amount.' } })
            return
        end
    end

    _markSetcashUsed(id)
    local curSym = Config.MoneyCurrency or '$'
    TriggerClientEvent('chat:addMessage', src, { args = { 'SetCash', ('Balance set to %s%d.'):format(curSym, amt) } })
end, false)


-- === NPC selling (server) ===
local _sellCooldown = {}

RegisterNetEvent("kq_link:tryNpcSell", function()
    local src = source
    local now = GetGameTimer()
    local cfg = Config.Sell or {}
    if cfg.Enable == false then return end
    if _sellCooldown[src] and (now - _sellCooldown[src]) < (cfg.Cooldown or 3000) then
        return
    end
    _sellCooldown[src] = now

    -- Find first drug the player has (1 unit)
    local items = cfg.Items or {}
    local chosen = nil
    for _, itm in ipairs(items) do
        local c = Inv_GetCount(src, itm)
        if (c or 0) > 0 then chosen = itm break end
    end

    if not chosen then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', cfg.NoDrugsMessage or 'No drugs.' } })
        return
    end

    -- Random refusal
    if cfg.Refusal and cfg.Refusal.Enable ~= false then
        local chance = tonumber(cfg.Refusal.Chance or 0) or 0
        if chance > 0 then
            math.randomseed(now + src + 1337)
            if math.random() < chance then
                local msg = "Not interested."
                local list = cfg.Refusal.Messages or {}
                if #list > 0 then
                    msg = list[math.random(1, #list)] or msg
                end
                TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', msg } })
                return
            end
        end
    end

    -- Roll payout
    local minP, maxP = (cfg.PriceMin or 10), (cfg.PriceMax or 50)
    if cfg.Prices and cfg.Prices[chosen] and type(cfg.Prices[chosen])=='table' then
        local t = cfg.Prices[chosen]
        if #t >= 2 then
            minP, maxP = tonumber(t[0+1]) or minP, tonumber(t[0+2]) or maxP
        end
    end
    math.randomseed(now + src)
    local pay = math.random(math.max(1, minP), math.max(minP, maxP))

    -- Remove 1 item and add money
    local ok = Inv_RemoveItem(src, chosen, 1)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', 'Failed to remove item.' } })
        return
    end
    exports[GetCurrentResourceName()]:AddPlayerMoney(src, 'cash', pay)

    local label = (ItemDefs[chosen] and ItemDefs[chosen].label) or chosen
    TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', string.format(cfg.SoldMessage or 'Sold 1x %s for $%d.', label, pay) } })

    -- Random heat alert
    if cfg.Heat and cfg.Heat.Enable ~= false then
        local hchance = tonumber(cfg.Heat.Chance or 0) or 0
        if hchance > 0 then
            math.randomseed(now + src + 4242)
            if math.random() < hchance then
                -- Build street location (best effort)
                local ped = GetPlayerPed(src)
                local x,y,z = table.unpack(GetEntityCoords(ped) or vector3(0.0,0.0,0.0))
                local a,b = GetStreetNameAtCoord(x,y,z)
    local street = GetStreetNameFromHashKey(a or 0)
    local cross = (b and b ~= 0) and GetStreetNameFromHashKey(b) or nil
    if cross and cross ~= '' then street = (street or 'unknown location') .. ' & ' .. cross end
                local msg = (cfg.Heat.Message or "Possible hand-to-hand reported near %s."):format(street or "unknown location") .. (function() local pc = _nearestPostal(x,y); if pc then return (" (Postal %s)"):format(pc) else return "" end end)()

                -- Per-postal cooldown
                do
                    local pc = _nearestPostal(x,y)
                    local cool = (cfg.Heat.PostalCooldownMs or 0)
                    if pc and cool and cool > 0 then
                        local nowTick = GetGameTimer()
                        local last = _PostalHeatCooldown[pc] or 0
                        local diff = nowTick - last
                        if diff < cool then
                            -- within cooldown window: skip LEO alert, but notify seller
                            local rem = cool - diff
                            local mins = math.floor(rem / 60000)
                            local secs = math.floor((rem % 60000) / 1000)
                            local fmt = (cfg.Heat.SellerSuppressedMessage or "Area is hot — lay low for %d:%02d minutes.")
                            TriggerClientEvent('chat:addMessage', src, { args = { 'Heat', string.format(fmt, mins, secs) } })
                            return
                        end
                        _PostalHeatCooldown[pc] = nowTick
                    end
                end

                -- Notify on-duty LEOs that match allowed departments
                local allowed = {}
                for _, d in ipairs(cfg.Heat.Depts or {}) do allowed[d] = true end
                for id, info in pairs(_OnDutyLEO) do
                    if GetPlayerName(id) and info and info.tag then
                        local canon = tostring(info.tag):upper()
                        if allowed[canon] then
                            TriggerClientEvent('chat:addMessage', id, { args = { 'Dispatch', msg } })
                        end
                    end
                end
            end
        end
    end
end)


-- Quick check: does player have any sellable drugs?
RegisterNetEvent("kq_link:reqHasDrugs", function()
    local src = source
    local cfg = Config.Sell or {}
    local items = cfg.Items or {}
    local has = false
    for _, itm in ipairs(items) do
        if Inv_GetCount(src, itm) > 0 then has = true break end
    end
    TriggerClientEvent("kq_link:retHasDrugs", src, has)
end)

-- (lockers base code inserted earlier in the session)


-- Map locker by rounded coordinates (avoids duplicates). Create if missing.
local function _round(x, n) n = n or 2; local p = 10^n; return math.floor(x * p + 0.5) / p end
local function _findOrCreateLockerAt(x,y,z,h)
    local rx, ry, rz = _round(x,2), _round(y,2), _round(z,2)
    local row = DB.fetchAll("SELECT id FROM kqde_lockers WHERE ABS(x-?)<0.05 AND ABS(y-?)<0.05 AND ABS(z-?)<0.05 LIMIT 1", { rx, ry, rz })
    if row and row[1] and row[1].id then
        return row[1].id
    end
    DB.execute("INSERT INTO kqde_lockers(x,y,z,heading) VALUES(?,?,?,?)", { rx, ry, rz, h or 0.0 })
    local new = DB.scalar("SELECT LAST_INSERT_ID()")
    return tonumber(new)
end

RegisterNetEvent("kq_link:reqLockerContentsAt", function(x,y,z,h)
    local src = source
    local id = _findOrCreateLockerAt(x,y,z,h)
    if not id then return end
    -- distance guard
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    local dist = math.sqrt((pos.x - x)^2 + (pos.y - y)^2 + (pos.z - z)^2)
    if dist > ((Config.Lockers and Config.Lockers.MaxDistance) or 1.5) then return end
    local rows = DB.fetchAll("SELECT item, amount FROM kqde_locker_items WHERE locker_id = ?", { id })
    local items = {}
    for _, r in ipairs(rows or {}) do
        local amt = math.floor(tonumber(r.amount) or 0)
        if amt > 0 then items[r.item] = amt end
    end
    local cash = DB.scalar("SELECT cash FROM kqde_lockers WHERE id = ?", { id }) or 0
    TriggerClientEvent("kq_link:retLockerContents", src, items, tonumber(cash) or 0)
end)

-- Commands: /locker put <item> <amount>, /locker take <item> <amount> (nearest locker by coords)
local function _nearestLockerId(src)
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    local rows = DB.fetchAll("SELECT id,x,y,z FROM kqde_lockers", {})
    local best, bestD = nil, 9e9
    for _, r in ipairs(rows or {}) do
        local d = math.sqrt((pos.x - r.x)^2 + (pos.y - r.y)^2 + (pos.z - r.z)^2)
        if d < bestD then bestD, best = d, r end
    end
    if best and bestD <= ((Config.Lockers and Config.Lockers.MaxDistance) or 1.5) then
        return best.id, best.x, best.y, best.z
    end
    return nil
end

local function _isDrugItem(name)
    for _, itm in ipairs((Config.Sell and Config.Sell.Items) or {}) do
        if itm == name then return true end
    end
    return false
end

RegisterCommand("locker", function(src, args, raw)
    if src == 0 then print("^1[kq_link]^7 /locker is player-only") return end
    local sub = tostring(args[1] or ""):lower()
    local item = tostring(args[2] or "")
    local amount = math.floor(tonumber(args[3] or 0) or 0)
    local id = _nearestLockerId(src)
    if not id then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'No locker nearby.' } })
        return
    end
    local lockerId = id

    if sub == "put" then
        if item == "" or amount < 1 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker put <item> <amount>' } })
            return
        end
        if not _isDrugItem(item) then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Only drug items can be stored.' } })
            return
        end
        if Inv_GetCount(src, item) < amount then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'You do not have that many.' } })
            return
        end
        if not Inv_RemoveItem(src, item, amount) then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Failed to remove from inventory.' } })
            return
        end
        DB.execute([[INSERT INTO kqde_locker_items(locker_id,item,amount) VALUES(?,?,?)
                     ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)]], { lockerId, item, amount })
        local label = (ItemDefs[item] and ItemDefs[item].label) or item
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Stored %s x%d'):format(label, amount) } })

    elseif sub == "take" then
        if item == "" or amount < 1 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker take <item> <amount>' } })
            return
        end
        local row = DB.fetchAll("SELECT amount FROM kqde_locker_items WHERE locker_id=? AND item=? LIMIT 1", { lockerId, item })
        local have = (row and row[1] and tonumber(row[1].amount)) or 0
        if have < amount then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Locker does not have that many.' } })
            return
        end
        local ok, why = Inv_CanHold(src, item, amount)
        if not ok then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'You cannot hold that.' } })
            return
        end
        DB.execute("UPDATE kqde_locker_items SET amount = amount - ? WHERE locker_id=? AND item=?", { amount, lockerId, item })
        Inv_AddItem(src, item, amount, nil)
        local label = (ItemDefs[item] and ItemDefs[item].label) or item
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Took %s x%d'):format(label, amount) } })

    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker put <item> <amount>  |  /locker take <item> <amount>' } })
    end
end, false)


-- /locker putcash <amount>  |  /locker takecash <amount>
RegisterCommand("lockercash", function(src, args, raw)
    if src == 0 then print("^1[kq_link]^7 /lockercash is player-only") return end
    local sub = tostring(args[1] or ""):lower()
    local amount = math.floor(tonumber(args[2] or 0) or 0)
    if sub == "" or amount < 1 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /lockercash put <amount> | /lockercash take <amount>' } })
        return
    end

    local cfgCash = (Config.Lockers and Config.Lockers.Cash) or {}
    if cfgCash.Enable == false then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Cash storage is disabled.' } })
        return
    end
    if cfgCash.MaxPerTxn and amount > cfgCash.MaxPerTxn then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Max per transaction is %d.'):format(cfgCash.MaxPerTxn) } })
        return
    end

    local id = _nearestLockerId(src)
    if not id then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'No locker nearby.' } })
        return
    end
    local cur = DB.scalar("SELECT cash FROM kqde_lockers WHERE id = ?", { id }) or 0
    cur = tonumber(cur) or 0

    if sub == "put" then
        -- remove from wallet, add to locker
        local ok = exports[GetCurrentResourceName()]:RemovePlayerMoney(src, 'cash', amount)
        if not ok then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Insufficient funds.' } })
            return
        end
        if cfgCash.MaxPerLocker and (cur + amount) > cfgCash.MaxPerLocker then
            -- refund
            exports[GetCurrentResourceName()]:AddPlayerMoney(src, 'cash', amount)
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Locker cash limit reached.' } })
            return
        end
        DB.execute("UPDATE kqde_lockers SET cash = cash + ? WHERE id = ?", { amount, id })
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Stored $%d in locker.'):format(amount) } })
    elseif sub == "take" then
        if amount > cur then
            TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Not enough cash in locker.' } })
            return
        end
        DB.execute("UPDATE kqde_lockers SET cash = cash - ? WHERE id = ?", { amount, id })
        exports[GetCurrentResourceName()]:AddPlayerMoney(src, 'cash', amount)
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Took $%d from locker.'):format(amount) } })
    else
        TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /lockercash put <amount> | /lockercash take <amount>' } })
    end
end, false)
