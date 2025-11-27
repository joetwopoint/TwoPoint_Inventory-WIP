-- kq_link / server/db.lua
DB = {}

local function usingOx()
    if Config.DB == 'oxmysql' then return true end
    if Config.DB == 'mysql-async' then return false end
    if MySQL and MySQL.query then return true end
    if GetResourceState('oxmysql') == 'started' or GetResourceState('oxmysql') == 'starting' then return true end
    return false
end

local function usingAsync()
    if Config.DB == 'mysql-async' then return true end
    if Config.DB == 'oxmysql' then return false end
    if MySQL and MySQL.Async and MySQL.Async.fetchAll then return true end
    if GetResourceState('mysql-async') == 'started' or GetResourceState('mysql-async') == 'starting' then return true end
    return false
end

local function _await(invoker)
    local p = promise.new()
    invoker(function(res) p:resolve(res) end)
    return Citizen.Await(p)
end

function DB.fetchAll(q, p) p = p or {}
    if usingOx() and MySQL and MySQL.query then
        return _await(function(cb) MySQL.query(q, p, cb) end)
    elseif usingAsync() and MySQL and MySQL.Async and MySQL.Async.fetchAll then
        return _await(function(cb) MySQL.Async.fetchAll(q, p, cb) end)
    else
        print("^1[kq_link]^7 No DB adapter found (install oxmysql or mysql-async).")
        return {}
    end
end

function DB.scalar(q, p) p = p or {}
    if usingOx() and MySQL and MySQL.scalar then
        return _await(function(cb) MySQL.scalar(q, p, cb) end)
    elseif usingAsync() and MySQL and MySQL.Async and MySQL.Async.fetchScalar then
        return _await(function(cb) MySQL.Async.fetchScalar(q, p, cb) end)
    else
        print("^1[kq_link]^7 No DB scalar available.")
        return nil
    end
end

function DB.execute(q, p) p = p or {}
    if usingOx() and MySQL and MySQL.update then
        return _await(function(cb) MySQL.update(q, p, cb) end)
    elseif usingAsync() and MySQL and MySQL.Async and MySQL.Async.execute then
        return _await(function(cb) MySQL.Async.execute(q, p, cb) end)
    else
        print("^1[kq_link]^7 No DB execute available.")
        return 0
    end
end
