print("Unr3al Meth by 1OSaft")
local invstate = GetResourceState('ox_inventory')
if (invstate == 'started' and Config.Debug) then
	print("ox_inventory detected")
end

if (Config.StartProduction.Item.Enabled) then
	ESX.RegisterUsableItem(Config.StartProduction.Item.ItemName, function(source)
		local xPlayer = ESX.GetPlayerFromId(source)
		if (Config.StartProduction.Item.ConsumeOnStart) then
			xPlayer.removeInventoryItem(Config.StartProduction.Item.ItemName, 1)
		end
		TriggerClientEvent('esx_methcar:checkstart', xPlayer.source)
	end)
end

RegisterServerEvent('esx_methcar:start')
AddEventHandler('esx_methcar:start', function(type)
	local methType = type
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local pos = GetEntityCoords(GetPlayerPed(src))
	Player(src).state:set('methType', type)
	if Config.Debug then print("Methtype: "..type) end

	if Config.LogType == 'discord' then
		DiscordLogs("start", "Started Cooking", "green", {
			{name = "Player Informations", value = " ", inline = false},
			{name = "ID", value = tostring(src), inline = true},
			{name = "Name", value = tostring(xPlayer.name), inline = true},
			{name = "Identifier", value = tostring(xPlayer.identifier), inline = true},
			{name = "Cords", value = " ", inline = false},
			{name = "X", value = tostring(pos.x), inline = true},
			{name = "Y", value = tostring(pos.y), inline = true},
			{name = "Z", value = tostring(pos.z), inline = true},
		})
	elseif Config.LogType == 'ox_lib' then
		lib.logger(xPlayer.identifier, 'Started Cooking Meth', 'Started Cooking at: '..tostring(pos))
	elseif Config.LogType == 'disabled' then
	else
		print("MISSING LOG TYPE")
	end

	if Config.Debug then print("Trying to remove Players Items") end

	if invstate == 'started' then

		local Acetone = exports.ox_inventory:GetItemCount(xPlayer.source, Config.Items[methType].Item1.ItemName)
		local Lithium = exports.ox_inventory:GetItemCount(xPlayer.source, Config.Items[methType].Item2.ItemName)
		local Methlab = exports.ox_inventory:GetItemCount(xPlayer.source, Config.Items.Methlab)

		if Acetone >= Config.Items[methType].Item1.Count and Lithium >= Config.Items[methType].Item2.Count and Methlab >= 1 then
			exports.ox_inventory:RemoveItem(xPlayer.source, Config.Items[methType].Item1.ItemName, Config.Items[methType].Item1.Count)
			exports.ox_inventory:RemoveItem(xPlayer.source, Config.Items[methType].Item2.ItemName, Config.Items[methType].Item2.Count)
			TriggerClientEvent('esx_methcar:startprod', src)
			if Config.Debug then print("Removed Starting Items") end
		else
			TriggerClientEvent('esx_methcar:notify', src, Config.Noti.error, Locales[Config.Locale]['Not_Supplies'])
		end
	else
		local Acetone = xPlayer.getInventoryItem(Config.Items[methType].Item1.ItemName).count
		local Lithium = xPlayer.getInventoryItem(Config.Items[methType].Item2.ItemName).count
		local Methlab = xPlayer.getInventoryItem(Config.Items.Methlab).count

		if Acetone >= Config.Items[methType].Item1.Count and Lithium >= Config.Items[methType].Item2.Count and Methlab >= 1 then
				TriggerClientEvent('esx_methcar:startprod', src)
				xPlayer.removeInventoryItem(Config.Items[methType].Item1.ItemName, Config.Items[methType].Item1.Count)
				xPlayer.removeInventoryItem(Config.Items[methType].Item2.ItemName, Config.Items[methType].Item2.Count)
				if Config.Debug then print("Removed Starting Items") end
		else
			TriggerClientEvent('esx_methcar:notify', src, Config.Noti.error, Locales[Config.Locale]['Not_Supplies'])
		end
	end
end)

RegisterServerEvent('esx_methcar:stopf')
AddEventHandler('esx_methcar:stopf', function(id)
	local src = source
	local xPlayers = ESX.GetExtendedPlayers()

	for k, xPlayer in pairs(xPlayers) do
		TriggerClientEvent('esx_methcar:stopfreeze', xPlayer.source, id)
	end
end)

RegisterServerEvent('esx_methcar:make')
AddEventHandler('esx_methcar:make', function(posx,posy,posz)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	
	if xPlayer.getInventoryItem('methlab').count >= 1 then
		local xPlayers = ESX.GetExtendedPlayers()

		for k, xPlayer in pairs(xPlayers) do
			TriggerClientEvent('esx_methcar:smoke', xPlayer.source, posx, posy, posz, 'a')
		end
	else
		TriggerClientEvent('esx_methcar:stop', src)
	end
end)

RegisterServerEvent('esx_methcar:finish')
AddEventHandler('esx_methcar:finish', function(qualtiy)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if Config.Debug then print('Base Quality: '.. qualtiy) end
	print(Player(src).state.methType)
	local rnd = math.random(Config.Items[Player(src).state.methType].Meth.Chance.Min, Config.Items[Player(src).state.methType].Meth.Chance.Max)
	local Amount = math.floor(qualtiy / 2) + rnd
	if Config.Debug then print('Base Amount: '.. Amount) end
	local MethAmount = Amount

	if invstate == 'started' and not Config.Inventory.ForceAdd then
		
		AmountPlayerCanCarry = exports.ox_inventory:CanCarryAmount(xPlayer.source, Config.Items[Player(source).state.methType].Meth.ItemName)
		if (AmountPlayerCanCarry <= 0) then
			AmountPlayerCanCarry = 0
		end
		if Config.Debug then print('Space for Meth: '.. AmountPlayerCanCarry) end

		if Config.Inventory.oxSplit then
			if Amount <= AmountPlayerCanCarry then
				MethAmount = Amount
				exports.ox_inventory:AddItem(xPlayer.source, Config.Items[Player(source).state.methType].Meth.ItemName, Amount)
			else
				MethAmount = AmountPlayerCanCarry
				exports.ox_inventory:AddItem(xPlayer.source, Config.Items[Player(source).state.methType].Meth.ItemName, MethAmount)
			end
		end
	elseif invstate == 'started' and Config.Inventory.ForceAdd then
		MethAmount = Amount
		exports.ox_inventory:AddItem(xPlayer.source, Config.Items[Player(source).state.methType].Meth.ItemName, MethAmount)
	else
		if Config.Inventory.ForceAdd then
			MethAmount = Amount
			xPlayer.addInventoryItem(Config.Items[Player(source).state.methType].Meth.ItemName, MethAmount)
		elseif xPlayer.canCarryItem(Config.Items[Player(source).state.methType].Meth.ItemName, MethAmount) then
			xPlayer.addInventoryItem(Config.Items[Player(source).state.methType].Meth.ItemName, MethAmount)
		end
	end

	if Config.Debug then print('Amount added: '.. MethAmount) end
	local pos = GetEntityCoords(GetPlayerPed(src))

	if Config.LogType == 'discord' then
		DiscordLogs("finish", "Finished Cooking", "green", {

			{name = "Player Informations", value = " ", inline = false},
			{name = "ID", value = tostring(src), inline = true},
			{name = "Name", value = tostring(xPlayer.name), inline = true},
			{name = "Identifier", value = tostring(xPlayer.identifier), inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Meth", value = " ", inline = false},
			{name = "Amount", value = tostring(MethAmount), inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Cords", value = " ", inline = false},
			{name = "X", value = tostring(pos.x), inline = true},
			{name = "Y", value = tostring(pos.y), inline = true},
			{name = "Z", value = tostring(pos.z), inline = true},
		})
	elseif Config.LogType == 'ox_lib' then
		lib.logger(xPlayer.identifier, 'Finished Cooking Meth', 'Meth Player Got: '..MethAmount)
	elseif Config.LogType == 'disabled' then
	else
		print("MISSING LOG TYPE")
	end
end)

RegisterServerEvent('esx_methcar:blow')
AddEventHandler('esx_methcar:blow', function(posx, posy, posz)
	local src = source
	local xPlayers = ESX.GetExtendedPlayers()
	local xPlayer = ESX.GetPlayerFromId(src)

	for k, xPlayer in pairs(xPlayers) do
		TriggerClientEvent('esx_methcar:blowup', xPlayer.source,posx, posy, posz)
	end

	if Config.Inventory.Type == 'ox_inventory' then
		local Methlab = exports.ox_inventory:GetItemCount(xPlayer.source, Config.Items[Player(source).state.methType].Meth.ItemNamelab)
	else
		xPlayer.removeInventoryItem(Config.Items[Player(source).state.methType].Meth.ItemNamelab, 1)
	end

	if Config.LogType == 'discord' then
		DiscordLogs("explosion", "Explosion", "red", {
			{name = "Player Informations", value = " ", inline = false},
			{name = "ID", value = src, inline = true},
			{name = "Name", value = xPlayer.name, inline = true},
			{name = "Identifier", value = xPlayer.identifier, inline = true},
			{name = " ", value = " ", inline = false},
			{name = "Cords", value = " ", inline = false},
			{name = "X", value = tostring(posx), inline = true},
			{name = "Y", value = tostring(posy), inline = true},
			{name = "Z", value = tostring(posz), inline = true},
		})
	elseif Config.LogType == 'ox_lib' then
		lib.logger(xPlayer.identifier, 'Meth Explosion', 'A Meth Van Exploded at: '..tostring(pos))
	elseif Config.LogType == 'disabled' then
	else
		print("MISSING LOG TYPE")
	end
end)

ESX.RegisterServerCallback('esx_methcar:getcops', function(source, cb)
	cb(ESX.GetExtendedPlayers('job', Config.Police))
end)

if Config.LogType == 'discord' then
	function DiscordLogs(name, title, color, fields)
		local webHook = Config.DiscordLogs.Webhooks[name]
		if not webHook == 'WEEBHOCKED' then
			local embedData = {{
				['title'] = title,
				['color'] = Config.DiscordLogs.Colors[color],
				['footer'] = {
					['text'] = "| Unr3al Meth | " .. os.date(),
					['icon_url'] = "https://cdn.discordapp.com/attachments/1091344078924435456/1091458999020425349/OSaft-Logo.png"
				},
				['fields'] = fields,
				['author'] = {
					['name'] = "Meth Car",
					['icon_url'] = "https://cdn.discordapp.com/attachments/1091344078924435456/1091458999020425349/OSaft-Logo.png"
				}
			}}
			PerformHttpRequest(webHook, nil, 'POST', json.encode({
				embeds = embedData
			}), {
				['Content-Type'] = 'application/json'
			})
		end
	end
end
