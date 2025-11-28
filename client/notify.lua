-- kq_link / client/notify.lua
RegisterNetEvent("kq_link:notify", function(msg, ntype)
    if not msg or msg == "" then return end
    -- Plain fallback via chat
    TriggerEvent('chat:addMessage', { args = { tostring(msg) } })
end)

-- /inventory client command -> server
RegisterCommand("inventory", function(_, args)
    local mode = (args and args[1]) or ""
    TriggerServerEvent("kqdei:requestInventory", tostring(mode))
end, false)

-- Render plain list (labels only)
RegisterNetEvent("kq_link:showInventory", function(list)
    if not list or #list == 0 then
        TriggerEvent('chat:addMessage', { args = { 'Inventory', '(empty)' } })
        return
    end
    TriggerEvent('chat:addMessage', { args = { 'Inventory', 'Items:' } })
    for _, row in ipairs(list) do
        local label = row.label or row.item or 'item'
        local count = tostring(row.count or 0)
        TriggerEvent('chat:addMessage', { args = { label .. ' x' .. count } })
    end
end)
