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

-- === HOTFIX: server-side /inventory & shared sender ===
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

    -- Prefer chat if available (plain white text)
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
        -- Fall back to client event if another UI listens
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
-- === END HOTFIX ===
