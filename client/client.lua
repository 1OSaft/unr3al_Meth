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

local CurrentVehicle, LastCar
local progress, quality = 0, 0
local started, displayed, pause, posLog, CurrentVehicleLog, carLog, LastCarLog, modelLog, modelNameLog, LastVehicleLog = false, false, false, false, false, false, false, false, false, false

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

RegisterNetEvent('esx_methcar:stop')
AddEventHandler('esx_methcar:stop', function()
	DisplayHelpText(Locales[Config.Locale]['Production_Stoped'])
	FreezeEntityPosition(LastCar, false)
	Citizen.Wait(10000)
		StopParticleFxLooped(smokeC, 0)
end)

RegisterNetEvent('esx_methcar:stopfreeze')
AddEventHandler('esx_methcar:stopfreeze', function(id)
	FreezeEntityPosition(id, false)
end)

RegisterNetEvent('esx_methcar:notify')
AddEventHandler('esx_methcar:notify', function(notitype, message)
	notifications(notitype, message, Config.Noti.time)
end)

RegisterNetEvent('esx_methcar:startprod')
AddEventHandler('esx_methcar:startprod', function()
	if Config.Debug then print("Starting Skillcheck") end
	FreezeEntityPosition(CurrentVehicle,true)

	SetPedIntoVehicle(PlayerPedId(), CurrentVehicle, 3)
	SetVehicleDoorOpen(CurrentVehicle, 2)

	if Config.SkillCheck.StartingProd.Enabled then
		Citizen.Wait(1500)
		local success = lib.skillCheck(Config.SkillCheck.StartingProd.Difficulty, Config.SkillCheck.StartingProd.Key)

		if success then
			started = true
			lib.hideTextUI()

			if Config.Debug then print('Started Meth production') end
			
			notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
		else
			lib.hideTextUI()

			notifications(Config.Noti.error, Locales[Config.Locale]['Failed_Start'], Config.Noti.time)
			Citizen.Wait(1000)
			local pos = GetEntityCoords(PlayerPedId())
			TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)

			if Config.Debug then print('Failed start Skillcheck, blowing up') end
		end
	else
		started = true
		lib.hideTextUI()
		displayed = false

		if Config.Debug then print('Started Meth production') end
		notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
	end
end)

RegisterNetEvent('esx_methcar:blowup')
AddEventHandler('esx_methcar:blowup', function(posx, posy, posz)
	AddExplosion(posx, posy, posz + 2,23, 20.0, true, false, 1.0, true)
	SetVehicleEngineHealth(car, -4000)
	TriggerEvent('esx_methcar:stop')
	if not HasNamedPtfxAssetLoaded("core") then
		RequestNamedPtfxAsset("core")
		while not HasNamedPtfxAssetLoaded("core") do
			Citizen.Wait(1)
		end
	end
	SetPtfxAssetNextCall("core")
	local fire = StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", posx, posy, posz-0.8 , 0.0, 0.0, 0.0, 0.8, false, false, false, false)
	Citizen.Wait(5000)

	StopParticleFxLooped(smokeC, 0)
	Citizen.Wait(6000)

	StopParticleFxLooped(fire, 0)
	
end)

RegisterNetEvent('esx_methcar:smoke')
AddEventHandler('esx_methcar:smoke', function(posx, posy, posz, bool)

	if bool == 'a' then

		if not HasNamedPtfxAssetLoaded("core") then
			RequestNamedPtfxAsset("core")
			while not HasNamedPtfxAssetLoaded("core") do
				Citizen.Wait(1)
			end
		end
		SetPtfxAssetNextCall("core")
		if Config.SmokeColor == 'white' then
			smokeC = StartParticleFxLoopedAtCoord("ent_amb_smoke_foundry_white", posx, posy, posz + 2.7, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
		end
		if Config.SmokeColor == 'orange' then
			smokeC = StartParticleFxLoopedAtCoord("exp_grd_flare", posx, posy, posz + 1.5, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
		end
		if Config.SmokeColor == 'black' then
			smokeC = StartParticleFxLoopedAtCoord("ent_amb_smoke_foundry ", posx, posy, posz + 2.7, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
		end
		SetParticleFxLoopedAlpha(smokeC, 0.8)

		SetParticleFxLoopedColour(smokeC, 0.0, 0.0, 0.0, 0)
		Citizen.Wait(22000)

		StopParticleFxLooped(smokeC, 0)
	else

		StopParticleFxLooped(smokeC, 0)
	end

end)

RegisterNetEvent('esx_methcar:drugged')
AddEventHandler('esx_methcar:drugged', function()
	SetTimecycleModifier("drug_drive_blend01")
	SetPedMotionBlur(PlayerPedId(), true)

	SetPedMovementClipset(PlayerPedId(), "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
	SetPedIsDrunk(PlayerPedId(), true)

	Citizen.Wait(Config.DrugEffectLengh)
	ClearTimecycleModifier()
end)

ESX.RegisterInput("MethProduction", "Meth Production", "keyboard", Config.StartKey, function()
	playerPed = playerPedId()

	if IsPedInAnyVehicle(playerPed) then
		car = GetVehiclePedIsIn(playerPed, false)
		CurrentVehicle = GetVehiclePedIsUsing(PlayerPedId())
		local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(CurrentVehicle))
		if modelName == 'JOURNEY' and car then
			if GetPedInVehicleSeat(car, -1) == playerPed then

			end
		end

	end
end)


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		playerPed = PlayerPedId()
		if Config.Debug and not playerPedLog then
			playerPedLog = ESX.SetTimeout(5000, function()
				print("Ped: "..playerPed)
				local playerPedLog = false
			end)
		end
		local pos = GetEntityCoords(PlayerPedId())
        if Config.Debug and not posLog then
            posLog = ESX.SetTimeout(5000, function()
                print("Pos: "..pos)
                posLog = false
            end)
        end

		if IsPedInAnyVehicle(playerPed) then

			CurrentVehicle = GetVehiclePedIsUsing(PlayerPedId())
			if Config.Debug and not CurrentVehicleLog then
				CurrentVehicleLog = ESX.SetTimeout(5000, function()
					print("CurrentVehicle: "..CurrentVehicle)
					CurrentVehicleLog = false
				end)
			end

			car = GetVehiclePedIsIn(playerPed, false)
			if Config.Debug and not carLog then
				carLog = ESX.SetTimeout(5000, function()
					print("Car: "..car)
					carLog = false
				end)
			end

			LastCar = GetVehiclePedIsUsing(playerPed)
			if Config.Debug and not LastCarLog then
				LastCarLog = ESX.SetTimeout(5000, function()
					print("Last Car: "..LastCar)
					LastCarLog = false
				end)
			end

			local model = GetEntityModel(CurrentVehicle)
			if Config.Debug and not modelLog then
				modelLog = ESX.SetTimeout(5000, function()
					print("Model: "..model)
					modelLog = false
				end)
			end
			local modelName = GetDisplayNameFromVehicleModel(model)
			if Config.Debug and modelNameLog then
				modelNameLog = ESX.SetTimeout(5000, function()
					print("Modelname: "..modelName)
					modelNameLog = false
				end)
			end

			if modelName == 'JOURNEY' and car then
				
				if GetPedInVehicleSeat(car, -1) == playerPed then
					if started == false then
						if displayed == false then
							if Config.Debug then print("Showing TextUI") end
							lib.showTextUI("["..Config.StartKey.."] " ..Locales[Config.Locale]['Help_Text'])
							
							displayed = true
						end
					end
					if IsControlJustPressed(0, Keys[Config.StartKey]) then
						ESX.TriggerServerCallback('esx_methcar:getcops', function(data)
						   print(data)
						   Cops = data

						   if #Cops >= Config.PoliceCount then
								if Config.Debug then print("Trying to start propduction") end
								if pos.y >= 100 then
									if IsVehicleSeatFree(CurrentVehicle, 3) then
										TriggerServerEvent('esx_methcar:start')	
										progress = 0
										pause = false
										quality = 0
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Seat_Occupied'], Config.Noti.time)
									end
								else
									notifications(Config.Noti.error, Locales[Config.Locale]['Near_City'], Config.Noti.time)
								end
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Not_Enough_Cops'], Config.Noti.time)
							end
						end)
					end
				end
			end
		else
			if started then
				started = false
				displayed = false
				TriggerEvent('esx_methcar:stop')
				if Config.Debug then print('Stopped making drugs') end
				FreezeEntityPosition(LastCar,false)
			end
		end
		
		if started == true then
			
			lib.registerContext({
				id = 'Event_01',
				title = Locales[Config.Locale]['Question_01'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title =  Locales[Config.Locale]['Question_01_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
						  	quality = quality - 3
						  	lib.hideContext(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_01.Enabled then
								if Questions.Question_01.DifficultyAnswer_1 == 0 then
									pause = false
								elseif Questions.Question_01.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										pause = false
									else
										TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
									end
								elseif Questions.Question_01.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										pause = false
									else
										TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
									end
								end
							else
								pause = false
							end
						end,
						icon = 'tape'
					},
					{
						title = Locales[Config.Locale]['Question_01_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							local pos = GetEntityCoords(PlayerPedId())
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
							TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
							SetVehicleEngineHealth(CurrentVehicle, 0.0)
							quality = 0
							started = false
							displayed = false
							ApplyDamageToPed(PlayerPedId(), 10, false)
							if Config.Debug then print('Stopped making Drugs') end
							lib.hideContext(true)
						end,
						icon = 'circle-pause'
					},
					{
						title = Locales[Config.Locale]['Question_01_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							lib.hideContext(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_01.Enabled then
								if Questions.Question_01.DifficultyAnswer_3 == 0 then
									pause = false
									quality = quality + 5
								elseif Questions.Question_01.DifficultyAnswer_3 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
										quality = quality + 5
                                        pause = false
									else
										TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
									end
								elseif Questions.Question_01.DifficultyAnswer_3 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
										quality = quality + 5
                                        pause = false
									else
										TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
									end
								end
							else
								quality = quality + 5
								pause = false
							end
						end,
						icon = 'wrench'
					},
				},
			})
			
			lib.registerContext({
				id = 'Event_02',
				title = Locales[Config.Locale]['Question_02'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_02_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_02.Enabled then
								if Questions.Question_02.DifficultyAnswer_1 == 0 then
									pause = false
									quality = quality - 1
								elseif Questions.Question_02.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										quality = quality - 1
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
										pause = false
									else
										TriggerEvent('esx_methcar:drugged')
										pause = false
									end
								elseif Questions.Question_02.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										quality = quality - 1
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
										pause = false
									else
										TriggerEvent('esx_methcar:drugged')
										pause = false
									end
								end
							else
								TriggerEvent('esx_methcar:drugged')
								pause = false
							end
						end,
						icon = 'window-maximize'
					},
					{
						title = Locales[Config.Locale]['Question_02_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_02_Answer_2_1'], Config.Noti.time)
							pause = false
							TriggerEvent('esx_methcar:drugged')
							lib.hideMenu(true)
						end,
						icon = 'circle-pause'
					},
					{
						title = Locales[Config.Locale]['Question_02_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_02.Enabled then
								if Questions.Question_02.DifficultyAnswer_3 == 0 then
									notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
									SetPedPropIndex(playerPed, 1, 26, 7, true)
									pause = false
								elseif Questions.Question_02.DifficultyAnswer_3 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
										SetPedPropIndex(playerPed, 1, 26, 7, true)
										pause = false
									else
										TriggerEvent('esx_methcar:drugged')
										pause = false
									end
								elseif Questions.Question_02.DifficultyAnswer_3 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
										SetPedPropIndex(playerPed, 1, 26, 7, true)
										pause = false
									else
										TriggerEvent('esx_methcar:drugged')
										pause = false
									end
								end
							else
								notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
								SetPedPropIndex(playerPed, 1, 26, 7, true)
								pause = false
							end
						end,
						icon = 'mask-ventilator'
					},
				},
			})

			lib.registerContext({
				id = 'Event_03',
				title = Locales[Config.Locale]['Question_03'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_03_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							lib.hideMenu(true)
							Citizen.Wait(20)
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_1_1'], Config.Noti.time)
							pause = false
						end,
						icon = 'burn'
					},
					{
						title = Locales[Config.Locale]['Question_03_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_03.Enabled then
								if Questions.Question_03.DifficultyAnswer_2 == 0 then
									notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
									quality = quality + 5
									pause = false
								elseif Questions.Question_03.DifficultyAnswer_2 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
										quality = quality + 5
										pause = false
									else
										pause = false
									end
								elseif Questions.Question_03.DifficultyAnswer_2 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
										quality = quality + 5
										pause = false
									else
										pause = false
									end
								end
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
								quality = quality + 5
								pause = false
							end
						end,
						icon = 'temperature-full'
					},
					{
						title = Locales[Config.Locale]['Question_03_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_03.Enabled then
								if Questions.Question_03.DifficultyAnswer_3 == 0 then
									notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
									pause = false
									quality = quality -4
								elseif Questions.Question_03.DifficultyAnswer_3 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality -4
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality -4
									end
								elseif Questions.Question_03.DifficultyAnswer_3 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality -4
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality -4
									end
								end
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								pause = false
								quality = quality -4
							end
						end,
						icon = 'temperature-quarter'
					},
				},
			})

			lib.registerContext({
				id = 'Event_04',
				title = Locales[Config.Locale]['Question_04'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_04_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
							quality = quality - 3
							pause = false
						  	lib.hideMenu(true)
						end,
						icon = 'circle-pause'
					},
					{
						title = Locales[Config.Locale]['Question_04_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_04.Enabled then
								if Questions.Question_04.DifficultyAnswer_2 == 0 then
									notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
									pause = false
									quality = quality - 1
								elseif Questions.Question_04.DifficultyAnswer_2 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
										quality = quality - 3
										pause = false
									end
								elseif Questions.Question_04.DifficultyAnswer_2 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
										quality = quality - 3
										pause = false
									end
								end
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								pause = false
								quality = quality - 1
							end
						end,
						icon = 'syringe'
					},
					{
						title = Locales[Config.Locale]['Question_04_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_04.Enabled then
								if Questions.Question_04.DifficultyAnswer_3 == 0 then
									notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
									pause = false
									quality = quality + 3
								elseif Questions.Question_04.DifficultyAnswer_3 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality + 3
									else
										notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
										quality = quality - 3
										pause = false
									end
								elseif Questions.Question_04.DifficultyAnswer_3 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality + 3
									else
										notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
										quality = quality - 3
										pause = false
									end
								end
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
								pause = false
								quality = quality + 3
							end
						end,
						icon = 'car-battery'
					},
				},
			})

			lib.registerContext({
				id = 'Event_05',
				title = Locales[Config.Locale]['Question_05'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_05_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_05.Enabled then
								if Questions.Question_05.DifficultyAnswer_1 == 0 then
									notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
									quality = quality + 4
									pause = false
								elseif Questions.Question_05.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
										quality = quality + 4
										pause = false
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
										pause = false
									end
								elseif Questions.Question_05.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
										quality = quality + 4
										pause = false
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
										pause = false
									end
								end
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
								quality = quality + 4
								pause = false
							end
						end,
						icon = 'bottle-droplet'
					},
					{
						title = Locales[Config.Locale]['Question_05_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							notifications(Config.Noti.info, Locales[Config.Locale]['Question_05_Answer_2_1'], Config.Noti.time)
							pause = false
							lib.hideMenu(true)
						end,
						icon = 'trash'
					},
					{
						title = Locales[Config.Locale]['Question_05_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_3_1'], Config.Noti.time)
							pause = false
							lib.hideMenu(true)
						end,
						icon = 'bottle-droplet'
					},
				},
			})

			lib.registerContext({
				id = 'Event_06',
				title = Locales[Config.Locale]['Question_06'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_06_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_06.Enabled then
								if Questions.Question_06.DifficultyAnswer_3 == 0 then
									notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
									pause = false
								elseif Questions.Question_06.DifficultyAnswer_3 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
										pause = false
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
										quality = quality - 2
										pause = false
									end
								elseif Questions.Question_06.DifficultyAnswer_3 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
										pause = false
									else
										notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
										quality = quality - 2
										pause = false
									end
								end
							else
								notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
								pause = false
							end
						end,
						icon = 'spray-can'
					},
					{
						title = Locales[Config.Locale]['Question_06_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_06.Enabled then
								if Questions.Question_06.DifficultyAnswer_1 == 0 then
									notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
									pause = false
									quality = quality + 3
								elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality + 3
									else
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_2'], Config.Noti.time)
										pause = false
									end
								elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality + 3
									else
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_2'], Config.Noti.time)
										pause = false
									end
								end
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
								pause = false
								quality = quality + 3
							end	
						end,
						icon = 'wrench'
					},
					{
						title = Locales[Config.Locale]['Question_06_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_06.Enabled then
								if Questions.Question_06.DifficultyAnswer_1 == 0 then
									notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
									pause = false
									quality = quality - 1
								elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									else
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									end
								elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									else
										notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
										pause = false
										quality = quality - 1
									end
								end
							else
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								pause = false
								quality = quality - 1
							end
						end,
						icon = 'wrench'
					},
				},
			})

			lib.registerContext({
				id = 'Event_07',
				title = Locales[Config.Locale]['Question_07'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_07_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_07_Answer_1_1'], Config.Noti.time)
							quality = quality + 1
							pause = false
						  lib.hideMenu(true)
						end,
						icon = 'face-grimace'
					},
					{
						title = Locales[Config.Locale]['Question_07_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_2_1'], Config.Noti.time)
							pause = false
							quality = quality - 2
							lib.hideMenu(true)
						end,
						icon = 'tree'
					},
					{
						title = Locales[Config.Locale]['Question_07_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_3_1'], Config.Noti.time)
							pause = false
							quality = quality - 1
							lib.hideMenu(true)
						end,
						icon = 'chair'
					},
				},
			})

			lib.registerContext({
				id = 'Event_08',
				title = Locales[Config.Locale]['Question_08'],
				onExit = function()
					Citizen.Wait(20)
					TriggerEvent('esx_methcar:stop')
				end,
				options = {
					{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2']},
					{
						title = Locales[Config.Locale]['Question_08_Answer_1'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 1') end
							lib.hideMenu(true)

							Citizen.Wait(20)
							local Questions = Config.SkillCheck.Questions

							if not Questions.DisableAll and Questions.Question_08.Enabled then
								if Questions.Question_08.DifficultyAnswer_1 == 0 then
									notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
									quality = quality + 1
									pause = false
								elseif Questions.Question_08.DifficultyAnswer_1 == 1 then
									local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
										quality = quality + 1
										pause = false
									else
										notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality + 1
									end
								elseif Questions.Question_08.DifficultyAnswer_1 == 2 then
									local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
									if success then
										notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
										quality = quality + 1
										pause = false
									else
										notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
										pause = false
										quality = quality + 1
									end
								end
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
								quality = quality + 1
								pause = false
							end
						end,
						icon = 'wine-glass-empty'
					},
					{
						title = Locales[Config.Locale]['Question_08_Answer_2'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 2') end
							lib.hideMenu(true)

							notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
							pause = false
							quality = quality + 1
							
						end,
						icon = 'flask'
					},
					{
						title = Locales[Config.Locale]['Question_08_Answer_3'],
						onSelect = function(args)
							if Config.Debug then print('Pressed 3') end
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_08_Answer_3_1'], Config.Noti.time)
							pause = false
							quality = quality - 1
							lib.hideMenu(true)
						end,
						icon = 'wine-glass-empty'
					},
				},
			})

			if progress < 96 then
				Citizen.Wait(Config.PauseTime)
				if not pause and IsPedInAnyVehicle(playerPed) then
					local percent = math.random(Config.Progress.Min, Config.Progress.Max)
					progress = progress +  percent
					notifications(Config.Noti.info, Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2'], Config.Noti.time)

					MiniGamePercentage = math.random(1, Config.ChangeMiniGame)
					if Config.Debug then print(MiniGamePercentage) end
					MenuOpen = false
					Citizen.Wait(Config.PauseTime) 
				end
			

				if progress > 10 and MiniGamePercentage == 1 and not MenuOpen then
					MenuOpen = true
					pause = true

					local Minigame = math.random(1, 8)

					lib.showContext('Event_0'..Minigame)

				end
				if IsPedInAnyVehicle(playerPed) then
					TriggerServerEvent('esx_methcar:make', pos.x,pos.y,pos.z)
					if pause == false then
						quality = quality + 1
						progress = progress +  math.random(1, 2)
						notifications(Config.Noti.info, Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2'], Config.Noti.time)
					end
				else
					TriggerEvent('esx_methcar:stop')
				end
			else
				TriggerEvent('esx_methcar:stop')
				progress = 100
				notifications(Config.Noti.info, Locales[Config.Locale]['Update1'] .. progress .. Locales[Config.Locale]['Update2'], Config.Noti.time)
				notifications(Config.Noti.success, Locales[Config.Locale]['Production_Finish'], Config.Noti.time)
				TriggerServerEvent('esx_methcar:finish', quality)
				FreezeEntityPosition(LastCar, false)
			end	
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
			if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then
				local LastVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
				if Config.Debug and not LastVehicleLog then
					LastVehicleLog = ESX.SetTimeout(50, function()
						print("Last Vehicle: "..LastVehicle)
						LastVehicleLog = false
					end)
				end
				if LastVehicle == 35842 and lib.isTextUIOpen() then
					ResetPedLastVehicle(PlayerPedId())
					lib.hideTextUI()
					started = false
					displayed = false
					TriggerEvent('esx_methcar:stop')
				else
					if started then
						lib.hideTextUI()
						started = false
						displayed = false
						TriggerEvent('esx_methcar:stop')
						if Config.Debug then print('Stopped Making drugs') end
					end		
				end
			else
			end
	end
end)