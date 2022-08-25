ESX = nil

TriggerEvent(
    "esx:getSharedObject",
    function(obj)
        ESX = obj
    end
)

RegisterServerEvent('neey_sim:buy')
AddEventHandler('neey_sim:buy', function(item)
    local xPlayer = ESX.GetPlayerFromId(source)
    if item == 'phone' then
        if xPlayer.getMoney() >= Config.Item.Cost.Phone then
            xPlayer.removeMoney(Config.Item.Cost.Phone)
            xPlayer.addInventoryItem(Config.PhoneItem, 1)
            TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Phone.Buy)
        else
            if xPlayer.getAccount('bank').money >= Config.Item.Cost.Phone then
                xPlayer.removeAccountMoney('bank', Config.Item.Cost.Phone)
                xPlayer.addInventoryItem(Config.Item.Phone.Item, 1)
                TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Phone.BuyBank)
            else
                TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Phone.NoMoney)
            end
        end
    end

    if item == 'sim' then
        local number = GeneratePhoneNumber()
        local metadata = { sim = number, owner = xPlayer.identifier }
        if xPlayer.getMoney() >= Config.Item.Cost.Sim then
            xPlayer.removeMoney(Config.Item.Cost.Sim)
            TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Sim.Buy)
            exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
            end)
            MySQL.Sync.execute("INSERT INTO `sim` VALUES ('"..number.."', '"..xPlayer.identifier .."')")
        else
            if xPlayer.getAccount('bank').money >= Config.Item.Cost.Sim then
                xPlayer.removeAccountMoney('bank', Config.Item.Cost.Sim)
                exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
                end)
                MySQL.Sync.execute("INSERT INTO `sim` VALUES ('"..number.."', '"..xPlayer.identifier .."')")
                TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Sim.BuyBank)
            else
                TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Item.Sim.NoMoney)
            end
        end
    end
end)

function GeneratePhoneNumber()
    math.randomseed(math.random(1111111111, 9999999999))
    local id = tostring(math.random(111111, 999999))
    
    local function Generate(id)
        if ESX.Items[id] then
            return Generate(tostring(math.random(111111, 999999)))
        end
    end
    
    Generate(id)
    
    return id
end

ESX.RegisterServerCallback('neey_sim:getSims', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.Sync.fetchAll('SELECT * FROM `sim` WHERE `owner` = @identifier', {
        ['@identifier'] = xPlayer.identifier}
    )

    if #result > 0 then
        cb(result)
    else
        cb(nil)
    end
end)

exports('sim', function(data, slot)
    print(data, slot)
    for k, v in pairs(data) do
        print(k,v)
    end
end)


RegisterServerEvent('neey_sim:check')
AddEventHandler('neey_sim:check', function(num)
    local xPlayer = ESX.GetPlayerFromId(source)
    local metadata = { owner = xPlayer.identifier, sim = num }
    local found = false
    local found2 = nil
    local id = nil
    for k, v in pairs(ESX.GetPlayers()) do
        if exports.ox_inventory:Search(v, 'count', 'sim', metadata) > 0 then
            found = true
            id = v
            break
        end
    end
    
    if found then
        if id == xPlayer.source then
            TriggerClientEvent('esx:showNotification', xPlayer.source, Config.Manage.SimHave)
        else
            exports.ox_inventory:RemoveItem(id, 'sim', 1, metadata)
            exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
                print(success, reason)
            end)
        end
    else
        local text = '"sim":"'..num..'","owner":"'..xPlayer.identifier..'"'
        local result = MySQL.Sync.fetchAll("SELECT * FROM `users` WHERE `inventory` LIKE '%"..text.."%'", {
            ['@identifier'] = xPlayer.identifier}
        )

        if #result > 0 then
            local inv = json.decode(result[1].inventory)

            for k, v in pairs(inv) do
                if inv[k].metadata then
                    for k2, v2 in pairs(inv[k].metadata) do
                        if v2 == num then
                            found2 = k
                            break
                        end
                    end
                end
            end

            if found2 ~= nil then
                table.remove(inv, found2)
                json.encode(inv)
                MySQL.Sync.execute("UPDATE `users` SET `inventory` = '"..json.encode(inv).."' WHERE identifier = '"..xPlayer.identifier .."'")
                exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
                    print(success, reason)
                end)
            else
                exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
                    print(success, reason)
                end)
            end            
        else
            exports.ox_inventory:AddItem(xPlayer.source, 'sim', 1, metadata, nil, function(success, reason)
                print(success, reason)
            end)
        end
    end
end)
