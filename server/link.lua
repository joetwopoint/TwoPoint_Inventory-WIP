local cfg = Config
local currency = Config.MoneyCurrency or '$'

-- === schema bootstrap ===
CreateThread(function()
  DB.execute([[
  CREATE TABLE IF NOT EXISTS kqde_items (
    identifier VARCHAR(64) NOT NULL,
    item VARCHAR(64) NOT NULL,
    amount BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(identifier,item)
  )]])
  DB.execute([[
  CREATE TABLE IF NOT EXISTS kqde_wallets (
    identifier VARCHAR(64) NOT NULL PRIMARY KEY,
    cash BIGINT NOT NULL DEFAULT 0
  )]])
  DB.execute([[
  CREATE TABLE IF NOT EXISTS kqde_wallet_flags (
    identifier VARCHAR(64) NOT NULL PRIMARY KEY,
    used_setcash TINYINT NOT NULL DEFAULT 0
  )]])
  DB.execute([[
  CREATE TABLE IF NOT EXISTS kqde_lockers (
    id INT NOT NULL AUTO_INCREMENT,
    x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, heading DOUBLE NOT NULL DEFAULT 0,
    cash BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(id)
  )]])
  DB.execute([[
  CREATE TABLE IF NOT EXISTS kqde_locker_items (
    locker_id INT NOT NULL,
    item VARCHAR(64) NOT NULL,
    amount BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY(locker_id,item)
  )]])
end)

-- === identifier helper ===
local function getIdent(src)
  local ids = GetPlayerIdentifiers(src)
  for _, id in ipairs(ids) do
    if id:find("license:") == 1 then return id end
  end
  return ids[1] or ('src:'..tostring(src))
end

-- === money exports ===
exports('GetPlayerMoney', function(src)
  local id = getIdent(src)
  local v = DB.scalar("SELECT cash FROM kqde_wallets WHERE identifier=?", { id }) or 0
  return tonumber(v) or 0
end)

exports('AddPlayerMoney', function(src, account, amount)
  local id = getIdent(src)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false end
  DB.execute([[INSERT INTO kqde_wallets(identifier,cash) VALUES(?,?)
               ON DUPLICATE KEY UPDATE cash=cash+VALUES(cash)]], { id, amount })
  return true
end)

exports('RemovePlayerMoney', function(src, account, amount)
  local id = getIdent(src)
  amount = math.floor(tonumber(amount) or 0)
  local cur = exports[GetCurrentResourceName()]:GetPlayerMoney(src)
  if amount <= 0 or cur < amount then return false end
  DB.execute("UPDATE kqde_wallets SET cash=cash-? WHERE identifier=?", { amount, id })
  return true
end)

-- === inventory exports ===
exports('Inv_GetCount', function(src, name)
  local id = getIdent(src)
  local r = DB.scalar("SELECT amount FROM kqde_items WHERE identifier=? AND item=?", { id, name }) or 0
  return tonumber(r) or 0
end)

exports('Inv_AddItem', function(src, name, amount, meta)
  local id = getIdent(src)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false end
  DB.execute([[INSERT INTO kqde_items(identifier,item,amount) VALUES(?,?,?)
               ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount)]], { id, name, amount })
  return true
end)

exports('Inv_RemoveItem', function(src, name, amount)
  local id = getIdent(src)
  local cur = exports[GetCurrentResourceName()]:Inv_GetCount(src, name)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 or cur < amount then return false end
  DB.execute("UPDATE kqde_items SET amount = amount - ? WHERE identifier=? AND item=?", { amount, id, name })
  return true
end)

exports('Inv_CanHold', function(src, name, amount) return true, "" end)

-- === /inventory ===
RegisterCommand("inventory", function(src)
  local id = getIdent(src)
  local rows = DB.fetchAll("SELECT item,amount FROM kqde_items WHERE identifier=?", { id })
  if not rows or #rows == 0 then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', 'Empty.' } })
    return
  end
  TriggerClientEvent('chat:addMessage', src, { args = { 'Inventory', 'Your items:' } })
  for _, r in ipairs(rows) do
    local name, amt = r.item, tonumber(r.amount) or 0
    local label = (ItemDefs[name] and ItemDefs[name].label) or name
    TriggerClientEvent('chat:addMessage', src, { args = { string.format('%s x%d', label, amt) } })
  end
end)

-- === nearest player helper ===
local function nearestPlayer(src, maxD)
  local players = GetPlayers()
  local psrc = src
  local ped = GetPlayerPed(psrc)
  local px,py,pz = table.unpack(GetEntityCoords(ped))
  local best, bestD = nil, 9999.0
  for _, s in ipairs(players) do
    s = tonumber(s)
    if s ~= psrc then
      local ped2 = GetPlayerPed(s)
      local x,y,z = table.unpack(GetEntityCoords(ped2))
      local d = #(vector3(px,py,pz) - vector3(x,y,z))
      if d < bestD then bestD, best = d, s end
    end
  end
  if best and bestD <= (maxD or 1.25) then return best end
  return nil
end

-- === /give <item> <amt> (nearest) ===
RegisterCommand("give", function(src, args)
  local item = tostring(args[0+1] or '')
  local amt = math.floor(tonumber(args[0+2] or 0) or 0)
  if item == '' or amt < 1 then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Give', 'Usage: /give <item> <amount>' } }); return
  end
  local tgt = nearestPlayer(src, 1.25)
  if not tgt then TriggerClientEvent('chat:addMessage', src, { args = { 'Give', 'No one nearby.' } }); return end
  if not exports[GetCurrentResourceName()]:Inv_RemoveItem(src, item, amt) then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Give', 'You do not have that many.' } }); return
  end
  exports[GetCurrentResourceName()]:Inv_AddItem(tgt, item, amt, nil)
  local label = (ItemDefs[item] and ItemDefs[item].label) or item
  TriggerClientEvent('chat:addMessage', src, { args = { 'Give', ('Gave %s x%d'):format(label, amt) } })
  TriggerClientEvent('chat:addMessage', tgt, { args = { 'Give', ('Received %s x%d'):format(label, amt) } })
end)

-- === /pay <amount> (nearest) ===
RegisterCommand("pay", function(src, args)
  local amt = math.floor(tonumber(args[0+1] or 0) or 0)
  if amt < (Config.Pay.MinAmount or 1) or amt > (Config.Pay.MaxAmount or 1000000) then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'Invalid amount.' } }); return
  end
  local tgt = nearestPlayer(src, Config.Pay.MaxDistance or 1.25)
  if not tgt then TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'No one nearby.' } }); return end
  if not exports[GetCurrentResourceName()]:RemovePlayerMoney(src, 'cash', amt) then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', 'Insufficient funds.' } }); return
  end
  exports[GetCurrentResourceName()]:AddPlayerMoney(tgt, 'cash', amt)
  if Config.Pay.NotifyBoth ~= false then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', ('Paid %s%d'):format(currency, amt) } })
    TriggerClientEvent('chat:addMessage', tgt, { args = { 'Pay', ('Received %s%d'):format(currency, amt) } })
  end
end)

-- === /setcash <amount> ===
RegisterCommand("setcash", function(src, args)
  if Config.SetCash.Enable == false then return end
  local amt = math.floor(tonumber(args[0+1] or 0) or 0)
  if amt < (Config.SetCash.Min or 0) or amt > (Config.SetCash.Max or 100000) then
    TriggerClientEvent('chat:addMessage', src, { args = { 'Cash', 'Amount out of range.' } }); return
  end
  local id = getIdent(src)
  if Config.SetCash.OneTime ~= false then
    local used = DB.scalar("SELECT used_setcash FROM kqde_wallet_flags WHERE identifier=?", { id }) or 0
    if tonumber(used) == 1 then TriggerClientEvent('chat:addMessage', src, { args = { 'Cash', 'You already used /setcash.' } }); return end
  end
  if Config.SetCash.RequireZeroBalance ~= false then
    local bal = exports[GetCurrentResourceName()]:GetPlayerMoney(src)
    if bal > 0 then TriggerClientEvent('chat:addMessage', src, { args = { 'Cash', 'You must have $0 to use /setcash.' } }); return end
  end
  DB.execute([[INSERT INTO kqde_wallets(identifier,cash) VALUES(?,?)
               ON DUPLICATE KEY UPDATE cash=VALUES(cash)]], { id, amt })
  DB.execute([[INSERT INTO kqde_wallet_flags(identifier,used_setcash) VALUES(?,1)
               ON DUPLICATE KEY UPDATE used_setcash=1]], { id })
  TriggerClientEvent('chat:addMessage', src, { args = { 'Cash', ('Set wallet to %s%d'):format(currency, amt) } })
end)

-- === /search (nearest) — items + basic weapon check ===
RegisterCommand("search", function(src)
  local tgt = nearestPlayer(src, 1.25)
  if not tgt then TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'No one nearby.' } }); return end
  -- items
  local id = getIdent(tgt)
  local rows = DB.fetchAll("SELECT item,amount FROM kqde_items WHERE identifier=?", { id })
  TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'Items found:' } })
  for _, r in ipairs(rows or {}) do
    local label = (ItemDefs[r.item] and ItemDefs[r.item].label) or r.item
    TriggerClientEvent('chat:addMessage', src, { args = { string.format('%s x%d', label, r.amount) } })
  end
  -- weapon ping to client (for full detail, client should check HasPedGotWeapon; omitted for brevity)
  TriggerClientEvent('chat:addMessage', src, { args = { 'Search', 'Weapons: (client-side check not shown in this condensed build)' } })
  TriggerClientEvent('chat:addMessage', tgt, { args = { 'Search', 'You are being searched (wdif).' } })
end)

-- === NPC selling / heat / postals ===
-- Postal loader
local _Postals
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
  if not raw then print('^1[TwoPoint_Inventory]^7 Postal JSON not found (BigDaddy-PostalMap).'); _Postals = {}; return end
  local clean = _stripJsonComments(raw)
  local ok, arr = pcall(function() return json.decode(clean) end)
  _Postals = ok and arr or {}
end
local function _nearestPostal(x,y)
  _loadPostals()
  local best, bestD = nil, 1e18
  for i=1,#_Postals do
    local p = _Postals[i]
    local dx,dy = x-(p.X or p.x or 0.0), y-(p.Y or p.y or 0.0)
    local d = dx*dx + dy*dy
    if d < bestD then bestD, best = d, p end
  end
  return best and (best.code or best.postal) or nil
end

-- Duty tracking (via PoliceEMSActivity EmergencyBlips events)
local _OnDutyLEO = {}
AddEventHandler('eblips:add', function(info)
  if type(info) == 'table' and info.src then
    local tag = nil
    if type(info.name) == 'string' then
      local first = info.name:match('^([^%s]+)')
      if first then tag = first:gsub('[^%a]','') end
    end
    _OnDutyLEO[tonumber(info.src)] = { tag = (tag or 'UNK'):upper(), name = tostring(info.name or '') }
  end
end)
AddEventHandler('eblips:remove', function(src) _OnDutyLEO[tonumber(src)] = nil end)
AddEventHandler('playerDropped', function() _OnDutyLEO[source] = nil end)

local _sellCooldown = {}
local _PostalHeatCooldown = {}

RegisterNetEvent("kq_link:reqHasDrugs", function()
  local src = source
  local items = Config.Sell.Items or {}
  local has = false
  for _, itm in ipairs(items) do if exports[GetCurrentResourceName()]:Inv_GetCount(src, itm) > 0 then has = true break end end
  TriggerClientEvent("kq_link:retHasDrugs", src, has)
end)

RegisterNetEvent("kq_link:tryNpcSell", function()
  local src = source
  local now = GetGameTimer()
  local sc = Config.Sell
  if sc.Enable == false then return end
  if _sellCooldown[src] and (now - _sellCooldown[src]) < (sc.Cooldown or 3000) then return end
  _sellCooldown[src] = now

  -- choose first available item
  local chosen
  for _, itm in ipairs(sc.Items or {}) do
    if exports[GetCurrentResourceName()]:Inv_GetCount(src, itm) > 0 then chosen = itm break end
  end
  if not chosen then TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', sc.NoDrugsMessage or 'No drugs.' } }); return end

  -- refusal
  if sc.Refusal and sc.Refusal.Enable ~= false then
    math.randomseed(now + src + 1337)
    local chance = tonumber(sc.Refusal.Chance or 0) or 0
    if chance > 0 and math.random() < chance then
      local msg = (sc.Refusal.Messages or {})[1] or "Not interested."
      TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', msg } }); return
    end
  end

  -- payout
  local minP, maxP = sc.PriceMin or 10, sc.PriceMax or 50
  if sc.Prices and sc.Prices[chosen] and #sc.Prices[chosen] >= 2 then
    minP, maxP = tonumber(sc.Prices[chosen][1]) or minP, tonumber(sc.Prices[chosen][2]) or maxP
  end
  math.randomseed(now + src + 4242)
  local pay = math.random(math.max(1,minP), math.max(minP,maxP))

  if not exports[GetCurrentResourceName()]:Inv_RemoveItem(src, chosen, 1) then return end
  exports[GetCurrentResourceName()]:AddPlayerMoney(src, 'cash', pay)
  local label = (ItemDefs[chosen] and ItemDefs[chosen].label) or chosen
  TriggerClientEvent('chat:addMessage', src, { args = { 'Sell', (sc.SoldMessage or 'Sold 1x %s for $%d.'):format(label, pay) } })

  -- heat
  if sc.Heat and sc.Heat.Enable ~= false then
    local hchance = tonumber(sc.Heat.Chance or 0) or 0
    math.randomseed(now + src + 777)
    if hchance > 0 and math.random() < hchance then
      local ped = GetPlayerPed(src)
      local x,y,z = table.unpack(GetEntityCoords(ped))
      local a,b = GetStreetNameAtCoord(x,y,z)
      local street = GetStreetNameFromHashKey(a or 0)
      local cross = (b and b ~= 0) and GetStreetNameFromHashKey(b) or nil
      if cross and cross ~= '' then street = (street or 'unknown location') .. ' & ' .. cross end
      local msg = (sc.Heat.Message or "Possible hand-to-hand reported near %s."):format(street or "unknown location")
      local pc = _nearestPostal(x,y); if pc then msg = msg .. (" (Postal %s)"):format(pc) end

      -- postal cooldown
      local cool = sc.Heat.PostalCooldownMs or 0
      if pc and cool > 0 then
        local last = _PostalHeatCooldown[pc] or 0
        if (now - last) < cool then
          local rem = cool - (now - last)
          local mins = math.floor(rem/60000); local secs = math.floor((rem%60000)/1000)
          local toast = sc.Heat.SellerSuppressedMessage or "Area is hot — lay low for %d:%02d minutes."
          TriggerClientEvent('chat:addMessage', src, { args = { 'Heat', string.format(toast, mins, secs) } })
          return
        end
        _PostalHeatCooldown[pc] = now
      end

      local allowed = {}; for _,d in ipairs(sc.Heat.Depts or {}) do allowed[d]=true end
      for id, info in pairs(_OnDutyLEO) do
        if GetPlayerName(id) and info and info.tag and allowed[info.tag] then
          TriggerClientEvent('chat:addMessage', id, { args = { 'Dispatch', msg } })
        end
      end
    end
  end
end)

-- === lockers: contents + item put/take + cash put/take (reuse SQL) ===
local function nearestLockerId(src, maxD)
  local ped = GetPlayerPed(src); local px,py,pz = table.unpack(GetEntityCoords(ped))
  local rows = DB.fetchAll("SELECT id,x,y,z FROM kqde_lockers", {})
  local best, bestD = nil, 9e9
  for _, r in ipairs(rows or {}) do
    local d = #(vector3(px,py,pz) - vector3(r.x,r.y,r.z))
    if d < bestD then bestD, best = d, r end
  end
  if best and bestD <= (Config.Lockers.MaxDistance or 1.5) then return best.id end
  return nil
end

RegisterNetEvent("kq_link:reqLockerContentsAt", function(x,y,z,h)
  local src = source
  local id = DB.scalar("SELECT id FROM kqde_lockers WHERE ABS(x-?)<0.05 AND ABS(y-?)<0.05 AND ABS(z-?)<0.05 LIMIT 1", { x, y, z })
  if not id then
    DB.execute("INSERT INTO kqde_lockers(x,y,z,heading) VALUES(?,?,?,?)", { x,y,z,h or 0.0 })
    id = DB.scalar("SELECT LAST_INSERT_ID()")
  end
  local rows = DB.fetchAll("SELECT item, amount FROM kqde_locker_items WHERE locker_id = ?", { id })
  local items = {}; for _,r in ipairs(rows or {}) do local amt=tonumber(r.amount) or 0; if amt>0 then items[r.item]=amt end end
  local cash = tonumber(DB.scalar("SELECT cash FROM kqde_lockers WHERE id=?", { id }) or 0) or 0
  TriggerClientEvent("kq_link:retLockerContents", src, items, cash)
end)

local function isDrugItem(n) for _,i in ipairs(Config.Sell.Items or {}) do if i==n then return true end end return false end

RegisterCommand("locker", function(src,args)
  local sub = tostring(args[0+1] or ""):lower()
  local item = tostring(args[0+2] or "")
  local amt = math.floor(tonumber(args[0+3] or 0) or 0)
  local id = nearestLockerId(src, Config.Lockers.MaxDistance or 1.5)
  if not id then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'No locker nearby.' } }); return end

  if sub == "put" then
    if item=="" or amt<1 then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker put <item> <amount>' } }); return end
    if not isDrugItem(item) then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Only drug items can be stored.' } }); return end
    if not exports[GetCurrentResourceName()]:Inv_RemoveItem(src, item, amt) then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'You do not have that many.' } }); return end
    DB.execute([[INSERT INTO kqde_locker_items(locker_id,item,amount) VALUES(?,?,?)
                 ON DUPLICATE KEY UPDATE amount=amount+VALUES(amount)]], { id, item, amt })
    local label = (ItemDefs[item] and ItemDefs[item].label) or item
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Stored %s x%d'):format(label, amt) } })
  elseif sub == "take" then
    if item=="" or amt<1 then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker take <item> <amount>' } }); return end
    local have = tonumber(DB.scalar("SELECT amount FROM kqde_locker_items WHERE locker_id=? AND item=?", { id, item }) or 0) or 0
    if have < amt then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Locker does not have that many.' } }); return end
    DB.execute("UPDATE kqde_locker_items SET amount=amount-? WHERE locker_id=? AND item=?", { amt, id, item })
    exports[GetCurrentResourceName()]:Inv_AddItem(src, item, amt, nil)
    local label = (ItemDefs[item] and ItemDefs[item].label) or item
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Took %s x%d'):format(label, amt) } })
  else
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /locker put <item> <amount>  |  /locker take <item> <amount>' } })
  end
end)

RegisterCommand("lockercash", function(src,args)
  local sub = tostring(args[0+1] or ""):lower()
  local amt = math.floor(tonumber(args[0+2] or 0) or 0)
  if amt < 1 then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /lockercash put|take <amount>' } }); return end
  local id = nearestLockerId(src, Config.Lockers.MaxDistance or 1.5)
  if not id then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'No locker nearby.' } }); return end
  local cur = tonumber(DB.scalar("SELECT cash FROM kqde_lockers WHERE id=?", { id }) or 0) or 0
  local cap = (Config.Lockers.Cash and Config.Lockers.Cash.MaxPerLocker) or 1000000
  local per = (Config.Lockers.Cash and Config.Lockers.Cash.MaxPerTxn) or 50000

  if sub == "put" then
    if amt > per then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Max per transaction is %d.'):format(per) } }); return end
    if not exports[GetCurrentResourceName()]:RemovePlayerMoney(src, 'cash', amt) then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Insufficient funds.' } }); return end
    if (cur + amt) > cap then exports[GetCurrentResourceName()]:AddPlayerMoney(src,'cash',amt); TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Locker cash limit reached.' } }); return end
    DB.execute("UPDATE kqde_lockers SET cash=cash+? WHERE id=?", { amt, id })
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Stored $%d in locker.'):format(amt) } })
  elseif sub == "take" then
    if amt > cur then TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Not enough cash in locker.' } }); return end
    DB.execute("UPDATE kqde_lockers SET cash=cash-? WHERE id=?", { amt, id })
    exports[GetCurrentResourceName()]:AddPlayerMoney(src,'cash',amt)
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', ('Took $%d from locker.'):format(amt) } })
  else
    TriggerClientEvent('chat:addMessage', src, { args = { 'Locker', 'Usage: /lockercash put|take <amount>' } })
  end
end)
