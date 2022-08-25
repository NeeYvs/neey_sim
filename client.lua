ESX = nil
local PlayerData = {}

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) 
			ESX = obj 
		end)
		Citizen.Wait(250)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

local GUI                     = {}
GUI.Time                      = 0
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local currentSkin 			  = nil

AddEventHandler('neey_sim:hasEnteredMarker', function(zone)
	if zone == 'simMenu' then
		CurrentAction     = 'sim_menu'
		CurrentActionMsg  = Config.Open
		CurrentActionData = {}
	end
end)

AddEventHandler('neey_sim:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

CreateThread(function()
	while true do
		Citizen.Wait(5)

		local coords, sleep = GetEntityCoords(PlayerPedId()), true

		if (#(coords - Config.Coords) < 20) then
			sleep = false
			ESX.DrawMarker(Config.Coords)
		end
		
		if sleep then
			Citizen.Wait(500)
		end
	end
end)

-- Enter / Exit marker events
CreateThread(function()
	while true do
		Citizen.Wait(100)

		local coords, sleep = GetEntityCoords(PlayerPedId()), true
		local isInMarker  = false
		local currentZone = nil

		if (#(coords - Config.Coords) < 2) then
			sleep = false
			isInMarker  = true
			currentZone = 'simMenu'
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker = true
			LastZone                = currentZone
			TriggerEvent('neey_sim:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('neey_sim:hasExitedMarker', LastZone)
		end
		if sleep then
			Citizen.Wait(500)
		end
	end
end)

CreateThread(function()
	while true do
		Citizen.Wait(3)

		if CurrentAction ~= nil then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, Keys['E']) and (GetGameTimer() - GUI.Time) > 300 then
				if CurrentAction == 'sim_menu' then
					OpenSimMenu()
				end

				CurrentAction = nil
				GUI.Time      = GetGameTimer()
			end
		else
			Citizen.Wait(500)
		end
	end
end)

simData = function()
	ESX.UI.Menu.CloseAll()
	ESX.TriggerServerCallback('neey_sim:getSims', function(sims)
		local elements = {
		}
		
		if sims ~= nil then
			for k, v in pairs(sims) do
				table.insert(elements, {label = sims[k].phone_number, value = sims[k].phone_number})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'zsim_menu',{
			title    = Config.Manage.Name,
			align    = 'left',
			elements = elements
		}, function(data, menu)	
			if data.current.value then
				local elements2 = {
					{label = Config.Manage.GetSim, value = 'simz'},
				}
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'zsim2_menu',{
					title    = Config.Manage.Name,
					align    = 'left',
					elements = elements2
				}, function(data2, menu2)	
					TriggerServerEvent('neey_sim:check', data.current.value)
				end, function(data2, menu2)
					menu2.close()
				end)
			end
		end, function(data, menu)
		 	menu.close()
		end)
	end)
end

OpenSimMenu = function()
	local elements = {
		{label = Config.Items.Sim .. ' - $' .. Config.Item.Cost.Sim , value = 'sim'},
		{label = Config.Items.Phone .. ' - $' .. Config.Item.Cost.Phone, value = 'phone'},
		{label = Config.Manage.Sims, value = 'msim'}
	}
		
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sim_menu',{
		title    = Config.Name,
		align    = 'left',
		elements = elements
	}, function(data, menu)	
		if data.current.value == 'sim' then
			TriggerServerEvent('neey_sim:buy', 'sim')
		end

		if data.current.value == 'phone' then
			TriggerServerEvent('neey_sim:buy', 'phone')
		end

		if data.current.value == 'msim' then
			simData()
		end
		menu.close()
	end, function(data, menu)
		menu.close()
	end)	
end

sim = function(data, slot)
    TriggerServerEvent('updatePhone:neey', data.slot)
end
