DB = {}

local usingOx = GetResourceState('oxmysql') == 'started'

if not usingOx then
  print('^3[TwoPoint_Inventory]^7 oxmysql not started; falling back to mysql-async if present.')
end

function DB.execute(q, p, cb)
  p = p or {}
  if usingOx then
    return MySQL.update.await(q, p)
  elseif MySQL and MySQL.Sync and MySQL.Sync.execute then
    return MySQL.Sync.execute(q, p)
  else
    print('^1[TwoPoint_Inventory]^7 No SQL adapter available.')
    return 0
  end
end

function DB.fetchAll(q, p)
  p = p or {}
  if usingOx then
    return MySQL.query.await(q, p) or {}
  elseif MySQL and MySQL.Sync and MySQL.Sync.fetchAll then
    return MySQL.Sync.fetchAll(q, p) or {}
  else
    return {}
  end
end

function DB.scalar(q, p)
  p = p or {}
  if usingOx then
    local r = MySQL.single.await(q, p)
    if type(r) == 'table' then
      local _,v = next(r); return v
    end
    return r
  elseif MySQL and MySQL.Sync and MySQL.Sync.fetchScalar then
    return MySQL.Sync.fetchScalar(q, p)
  else
    return nil
  end
end
