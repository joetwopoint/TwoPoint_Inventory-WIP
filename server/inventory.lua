-- kq_link / server/inventory.lua
ItemDefs = ItemDefs or {}
Inventories = Inventories or {}

local function getIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("license:") == 1 then return id end end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do if id:find("fivem:") == 1 then return id end end
    return GetPlayerIdentifier(src, 0) or ("src:"..tostring(src))
end

local function calcWeight(items)
    local w = 0.0
    for item, count in pairs(items or {}) do
        local def = ItemDefs[item]
        if def and def.weight then w = w + (def.weight * count) end
    end
    return w
end

function LoadItemDefs()
    ItemDefs = {}
    local rows = DB.fetchAll([[SELECT item,label,COALESCE(weight,0) weight, COALESCE(max_stack,2147483647) max_stack FROM kqde_itemdefs]], {})
    for _, r in ipairs(rows or {}) do
        ItemDefs[r.item] = { label = r.label or r.item, weight = tonumber(r.weight) or 0.0, max_stack = tonumber(r.max_stack) or 2147483647 }
    end
    print(("^2[kq_link]^7 Loaded %d itemdefs."):format((rows and #rows) or 0))
end

local function loadInventory(identifier)
    local rows = DB.fetchAll([[SELECT item,amount FROM kqde_inventories WHERE identifier = ?]], { identifier })
    local items, unique = {}, 0
    for _, r in ipairs(rows or {}) do
        local amt = math.floor(tonumber(r.amount) or 0)
        if amt > 0 then items[r.item] = amt; unique = unique + 1 end
    end
    Inventories[identifier] = { items = items, weight = calcWeight(items), unique = unique, loaded = true }
    return Inventories[identifier]
end

local function getInv(idOrSrc)
    local identifier = type(idOrSrc)=="number" and getIdentifier(idOrSrc) or idOrSrc
    local inv = Inventories[identifier]
    if not inv or not inv.loaded then inv = loadInventory(identifier) end
    return identifier, inv
end

local function hasItemDef(item)
    if not Config.RequireWhitelist then return true end
    return ItemDefs[item] ~= nil
end

local function canHold(inv, item, addAmount)
    if not hasItemDef(item) then return false, "not whitelisted" end
    addAmount = math.floor(tonumber(addAmount) or 0)
    if addAmount <= 0 then return false, "invalid amount" end
    if inv.items[item] == nil then
        if Config.MaxUniqueItems and Config.MaxUniqueItems > 0 and inv.unique >= Config.MaxUniqueItems then
            return false, "too many unique"
        end
    end
    local cur = inv.items[item] or 0
    local max_stack = (ItemDefs[item] and ItemDefs[item].max_stack) or 2147483647
    if cur + addAmount > max_stack then return false, "stack limit" end
    if Config.MaxWeight and Config.MaxWeight > 0 then
        local addW = ((ItemDefs[item] and ItemDefs[item].weight) or 0.0) * addAmount
        if (inv.weight + addW) > Config.MaxWeight then return false, "too heavy" end
    end
    return true
end

local function saveRow(identifier, item, amt)
    if amt > 0 then
        DB.execute([[
            INSERT INTO kqde_inventories (identifier,item,amount) VALUES (?,?,?)
            ON DUPLICATE KEY UPDATE amount = VALUES(amount)
        ]], { identifier, item, amt })
    else
        DB.execute([[DELETE FROM kqde_inventories WHERE identifier = ? AND item = ?]], { identifier, item })
    end
end

function Inv_AddItem(src, item, amount, meta)
    local identifier, inv = getInv(src)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "invalid amount" end
    if Config.MaxGiveAmountPerCall and amount > Config.MaxGiveAmountPerCall then amount = Config.MaxGiveAmountPerCall end
    local ok, why = canHold(inv, item, amount)
    if not ok then return false, why end
    local cur = inv.items[item] or 0
    local newAmount = cur + amount
    inv.items[item] = newAmount
    if cur == 0 then inv.unique = (inv.unique or 0) + 1 end
    inv.weight = calcWeight(inv.items)
    saveRow(identifier, item, newAmount)
    return true
end

function Inv_AddItemToFit(src, item, amount, meta)
    local added = 0
    amount = math.floor(tonumber(amount) or 0)
    while amount > 0 do
        local ok = Inv_AddItem(src, item, 1, meta)
        if not ok then break end
        added = added + 1
        amount = amount - 1
        if added >= (Config.MaxGiveAmountPerCall or 100000) then break end
    end
    return added
end

function Inv_RemoveItem(src, item, amount)
    local identifier, inv = getInv(src)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "invalid amount" end
    local cur = inv.items[item] or 0
    if cur < amount then return false, "not enough" end
    local newAmount = cur - amount
    if newAmount <= 0 then inv.items[item] = nil; inv.unique = math.max((inv.unique or 1) - 1, 0) else inv.items[item] = newAmount end
    inv.weight = calcWeight(inv.items)
    saveRow(identifier, item, newAmount)
    return true
end

function Inv_GetCount(src, item)
    local _, inv = getInv(src)
    return inv.items[item] or 0
end

function Inv_GetData(src, item)
    local _, inv = getInv(src)
    local count = inv.items[item] or 0
    local def = ItemDefs[item] or {label=item, weight=0.0, max_stack=2147483647}
    return { count = count, label = def.label, weight = def.weight, max_stack = def.max_stack }
end

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        LoadItemDefs()
    end
end)
