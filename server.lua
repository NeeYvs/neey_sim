ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local vehicleKeys = {}
RegisterServerEvent("neey_keys:useKeys")
AddEventHandler("neey_keys:useKeys", function(data)
	local slot = exports.ox_inventory:GetSlot(source, data)
	TriggerClientEvent('neey_keys:useKey', source, slot.metadata.type)
end)

RegisterServerEvent("neey_keys:addKey")
AddEventHandler("neey_keys:addKey", function(plate, data)
	if data == nil then
		if not vehicleKeys[plate] then
			vehicleKeys[plate] = true
			TriggerClientEvent('neey_keys:updateKeys', -1, plate)
			local plateup = string.upper(plate)
			local cos1 = string.gsub(plateup, "%s+", "")
			exports.ox_inventory:AddItem(source, 'carkey', 1, cos1)
		else
			if vehicleKeys[plate] ~= nil then
				vehicleKeys[plate] = true
				TriggerClientEvent('neey_keys:updateKeys', -1, plate)
				local plateup = string.upper(plate)
				local cos1 = string.gsub(plateup, "%s+", "")
				exports.ox_inventory:AddItem(source, 'carkey', 1, cos1)
			end
		end
	else
		vehicleKeys[plate] = true
	end
end)

ESX.RegisterServerCallback('neey_keys:getKeys', function(source, cb, plate)
	if plate ~= nil then
		local plateup = string.upper(plate)
		local cos1 = string.gsub(plateup, "%s+", "")
		if exports.ox_inventory:Search(source, 'count', 'carkey', cos1) > 0 then
			cb(true)
		else
			cb(false)
		end
	end
end)


RegisterNetEvent('neey_keys:removeKey')
AddEventHandler('neey_keys:removeKey', function(plate)
    local plateup = string.upper(plate)
    local cos1 = string.gsub(plateup, "%s+", "")
    exports.ox_inventory:RemoveItem(source, 'carkey', 1, cos1)
    local found = false
    local id = nil
    for k, v in pairs(ESX.GetPlayers()) do
        if exports.ox_inventory:Search(v, 'count', 'carkey', plate) > 0 then
            found = true
            id = v
            break
        end
    end
    
    if found then
        exports.ox_inventory:RemoveItem(id, 'sim', 1, metadata)
    end
    vehicleKeys[plate] = false
end)