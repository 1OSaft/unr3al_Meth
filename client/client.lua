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
local started, displayed, pause, posLog, CurrentVehicleLog, carLog, LastCarLog, modelLog, modelNameLog, LastVehicleLog, smokeC, smoke = false, false, false, false, false, false, false, false, false, false, nil, nil
local smokecolour = ""

local PlayerState = LocalPlayer.state
PlayerState:set('Cooking', false)

function toggleCam(bool)
    if bool then
        local coords = GetEntityCoords(cache.ped)
        local x, y, z = coords.x + GetEntityForwardX(cache.ped) * 0.9, coords.y + GetEntityForwardY(cache.ped) * 0.9, coords.z + 0.92
        local rot = GetEntityRotation(cache.ped, 2)
        local camRotation = rot + vector3(0.0, 0.0, 175.0)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRotation, 70.0)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 1000, 1, 1)
    else
        if cam then
            RenderScriptCams(false, true, 0, true, false)
            DestroyCam(cam, false)
            cam = nil
        end
    end
end
--Soon to be implemented
function playerAnim(dict,clip)
	local player = PlayerPedId()
	lib.requestAnimDict(dict, 500)
	TaskPlayAnim(player, dict, clip, 1.0, 1.0, -1, 8, -1, true, true, true)
	RemoveAnimDict(dict)
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

RegisterNetEvent('esx_methcar:stop')
AddEventHandler('esx_methcar:stop', function()
	PlayerState:set('Cooking', false)
	if (Config.Cam) then
		toggleCam(false)
	end
	DisplayHelpText(Locales[Config.Locale]['Production_Stoped'])
	FreezeEntityPosition(LastCar, false)
	FreezeEntityPosition(CurrentVehicle, false)
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
		Wait(1500)
		local success = lib.skillCheck(Config.SkillCheck.StartingProd.Difficulty, Config.SkillCheck.StartingProd.Key)

		if success then
			TriggerEvent('esx_methcar:production')
			PlayerState:set('Cooking', true)
			lib.hideTextUI()

			if Config.Debug then print('Started Meth production') end
			
			notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
			if (Config.Cam) then
				toggleCam(true)
			end
		else
			lib.hideTextUI()

			notifications(Config.Noti.error, Locales[Config.Locale]['Failed_Start'], Config.Noti.time)
			Wait(1000)
			local pos = GetEntityCoords(PlayerPedId())
			TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)

			if Config.Debug then print('Failed start Skillcheck, blowing up') end
		end
	else
		PlayerState:set('Cooking', true)
		lib.hideTextUI()
		displayed = false

		if Config.Debug then print('Started Meth production') end
		notifications(Config.Noti.success, Locales[Config.Locale]['Production_Started'], Config.Noti.time)
	end
end)

RegisterNetEvent('esx_methcar:blowup')
AddEventHandler('esx_methcar:blowup', function(posx, posy, posz)
	if (Config.Cam) then
		toggleCam(false)
	end
	Wait(1500)
	AddExplosion(posx, posy, posz + 2,23, 20.0, true, false, 1.0, true)
	SetVehicleEngineHealth(car, -4000)
	TriggerEvent('esx_methcar:stop')
	if not HasNamedPtfxAssetLoaded("core") then
		RequestNamedPtfxAsset("core")
		while not HasNamedPtfxAssetLoaded("core") do
			Wait(1)
		end
	end
	SetPtfxAssetNextCall("core")
	local fire = StartParticleFxLoopedAtCoord("ent_ray_heli_aprtmnt_l_fire", posx, posy, posz-0.8 , 0.0, 0.0, 0.0, 0.8, false, false, false, false)
	Wait(5000)

	StopParticleFxLooped(smokeC, 0)
	Wait(6000)

	StopParticleFxLooped(fire, 0)
	
end)

RegisterNetEvent('esx_methcar:smoke')
AddEventHandler('esx_methcar:smoke', function(posx, posy, posz, type)
	if type == 'a' then

		if not HasNamedPtfxAssetLoaded("core") then
			RequestNamedPtfxAsset("core")
			while not HasNamedPtfxAssetLoaded("core") do
				Wait(1)
			end
		end
		SetPtfxAssetNextCall("core")
        	if Config.SmokeColor == 'white' then
			smokecolour = "ent_amb_smoke_foundry_white"
		end
		if Config.SmokeColor == 'orange' then
			smokecolour = "exp_grd_flare"
		end
		if Config.SmokeColor == 'black' then
			smokecolour = "ent_amb_smoke_foundry"
		end
    local smoke = StartParticleFxLoopedAtCoord(smokecolour, posx, posy, posz + 2.7, 0.0, 0.0, 0.0, 2.0, false, false, false, false)

		SetParticleFxLoopedAlpha(smoke, 0.8)
		SetParticleFxLoopedColour(smoke, 0.0, 0.0, 0.0, 0)
		Wait(20000)
		StopParticleFxLooped(smoke, 0)
	else
		StopParticleFxLooped(smoke, 0)
	end
end)

RegisterNetEvent('esx_methcar:drugged')
AddEventHandler('esx_methcar:drugged', function()
	SetTimecycleModifier("drug_drive_blend01")
	SetPedMotionBlur(PlayerPedId(), true)

	SetPedMovementClipset(PlayerPedId(), "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
	SetPedIsDrunk(PlayerPedId(), true)

	Wait(Config.DrugEffectLengh)
	ClearTimecycleModifier()
end)

if (Config.Debug) then
	RegisterCommand('meth', function()
		ClearTimecycleModifier()
	end, false)
end

RegisterNetEvent('esx_methcar:checkstart')
AddEventHandler('esx_methcar:checkstart', function()
	print("PlayerState.Cooking: "..tostring(PlayerState.Cooking))
	if (PlayerState.Cooking == false) then
		playerPed = PlayerPedId()
		if IsPedInAnyVehicle(playerPed, false) then
			car = GetVehiclePedIsIn(playerPed, false)
			CurrentVehicle = GetVehiclePedIsUsing(PlayerPedId())
			local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(CurrentVehicle))
			if modelName == 'JOURNEY' and car then
				if GetPedInVehicleSeat(car, -1) == playerPed then
					ESX.TriggerServerCallback('esx_methcar:getcops', function(data)
						print(data)
						Cops = data
						if #Cops >= Config.PoliceCount then
							if Config.Debug then print("Trying to start propduction") end
							if IsVehicleSeatFree(CurrentVehicle, 3) then
								if (Config.Items.EnableDifferentMethTypes) then
									input = lib.inputDialog('Meth', {
										{type = 'select', label = 'Select meth recipe', description = 'Some input description', required = true, options = {{label = 'Easy', value = 'Easy'}, {label = 'Medium', value = 'Medium'}, {label = 'Hard', value = 'Hard'}}},
									})
									if Config.Debug then print("Meth type: "..input[1]) end
									TriggerServerEvent('esx_methcar:start', input[1])
								else
									TriggerServerEvent('esx_methcar:start', "Easy")
								end
								PlayerState:set('Progress', 0)
								PlayerState:set('Quality', 0)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Seat_Occupied'], Config.Noti.time)
							end
						else
							notifications(Config.Noti.error, Locales[Config.Locale]['Not_Enough_Cops'], Config.Noti.time)
						end
					end)
				end
			end
		end
	end
end)

if (Config.StartProduction.Key.Enabled) then
	ESX.RegisterInput("MethProduction", "Meth Production", "keyboard", Config.StartProduction.Key.StartKey, function()
		TriggerEvent('esx_methcar:checkstart')
	end)
end

RegisterNetEvent('esx_methcar:production')
AddEventHandler('esx_methcar:production', function()
	PlayerState:set('Cooking', true)
	local pos = GetEntityCoords(PlayerPedId())
	--playerPed = PlayerPedId()
	--LastCar = GetVehiclePedIsUsing(playerPed)

	while (PlayerState.Cooking) do
		Wait(10)
		if IsPedInAnyVehicle(playerPed, false) then
			TriggerServerEvent('esx_methcar:make', pos.x,pos.y,pos.z)
			if (not PlayerState.Paused) then
				PlayerState:set('Quality', PlayerState.Quality + 1)
				PlayerState:set('Progress', PlayerState.Progress + math.random(1,2))
				notifications(Config.Noti.info, Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2'], Config.Noti.time)
			end
		else
			TriggerEvent('esx_methcar:stop')
		end

		if (PlayerState.Progress < 95) then
			Wait(Config.PauseTime)
			if (not PlayerState.Paused and IsPedInAnyVehicle(playerPed, false)) then
				local Percent = math.random(Config.Progress.Min, Config.Progress.Max)
				PlayerState:set('Progress', PlayerState.Progress + Percent)
				notifications(Config.Noti.info, Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2'], Config.Noti.time)

				MiniGamePercentage = math.random(1, Config.ChangeMiniGame)
				if Config.Debug then print("Minigame Chance: "..MiniGamePercentage) end
				PlayerState:set('MenuOpen', false)
				--Wait(Config.PauseTime)
			end
			if (not PlayerState.Paused and PlayerState.Progress > 10 and MiniGamePercentage == 1) then
				PlayerState:set('Paused', true)

				local MiniGame = math.random(1,8)
				--TriggerEvent('esx_methcar:Context'..MiniGame)
				if (MiniGame == 1) then
					TriggerEvent('esx_methcar:Context1')
				elseif (MiniGame == 2) then
					TriggerEvent('esx_methcar:Context2')
				elseif (MiniGame == 3) then
					TriggerEvent('esx_methcar:Context3')
				elseif (MiniGame == 4) then
					TriggerEvent('esx_methcar:Context4')
				elseif (MiniGame == 5) then
					TriggerEvent('esx_methcar:Context5')
				elseif (MiniGame == 6) then
					TriggerEvent('esx_methcar:Context6')
				elseif (MiniGame == 7) then
					TriggerEvent('esx_methcar:Context7')
				elseif (MiniGame == 8) then
					TriggerEvent('esx_methcar:Context8')
				end
			end
		else
			TriggerEvent('esx_methcar:stop')
			PlayerState:set('Progress', 100)
			notifications(Config.Noti.success, Locales[Config.Locale]['Production_Finish'], Config.Noti.time)
			if Config.Debug then print('Quality: '..PlayerState.Quality) end
			TriggerServerEvent('esx_methcar:finish', PlayerState.Quality)
			FreezeEntityPosition(LastCar, false)
		end
	end
end)

RegisterNetEvent('esx_methcar:Context1')
AddEventHandler('esx_methcar:Context1', function()
	lib.registerContext({
		id = 'Event_01',
		title = Locales[Config.Locale]['Question_01'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title =  Locales[Config.Locale]['Question_01_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					local pos = GetEntityCoords(PlayerPedId())
					if not Questions.DisableAll and Questions.Question_01.Enabled then
						if Questions.Question_01.DifficultyAnswer_1 == 0 then
							PlayerState:set('Paused', false)
						elseif Questions.Question_01.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								PlayerState:set('Paused', false)
							else
								TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
							end
						elseif Questions.Question_01.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								PlayerState:set('Paused', false)
							else
								TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
							end
						end
					else
						PlayerState:set('Paused', false)
					end
					PlayerState:set('Quality', PlayerState.Quality - 3)
				end,
				icon = 'tape'
			},
			{
				title = Locales[Config.Locale]['Question_01_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					local pos = GetEntityCoords(PlayerPedId())
					notifications(Config.Noti.error, Locales[Config.Locale]['Question_01_Fail'], Config.Noti.time)
					TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
					SetVehicleEngineHealth(CurrentVehicle, 0.0)

					PlayerState:set('Quality', 0)
					PlayerState:set('Cooking', false)
					displayed = false
					ApplyDamageToPed(PlayerPedId(), 90, false)
					if Config.Debug then print('Stopped making Drugs') end
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_01_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					local pos = GetEntityCoords(PlayerPedId())
					if not Questions.DisableAll and Questions.Question_01.Enabled then
						if Questions.Question_01.DifficultyAnswer_3 == 0 then
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality + 5)
						elseif Questions.Question_01.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 5)
								PlayerState:set('Paused', false)
							else
								TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
							end
						elseif Questions.Question_01.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_01_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 5)
								PlayerState:set('Paused', false)
							else
								TriggerServerEvent('esx_methcar:blow', pos.x, pos.y, pos.z)
							end
						end
					else
						PlayerState:set('Quality', PlayerState.Quality + 5)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'wrench'
			},
		},
	})
	lib.showContext('Event_01')
end)

RegisterNetEvent('esx_methcar:Context2')
AddEventHandler('esx_methcar:Context2', function()
	lib.registerContext({
		id = 'Event_02',
		title = Locales[Config.Locale]['Question_02'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_02_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_02.Enabled then
						if Questions.Question_02.DifficultyAnswer_1 == 0 then
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality - 1)
						elseif Questions.Question_02.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 1)
								PlayerState:set('Paused', false)
							else
								TriggerEvent('esx_methcar:drugged')
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_02.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_02_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 1)
								PlayerState:set('Paused', false)
							else
								TriggerEvent('esx_methcar:drugged')
								PlayerState:set('Paused', false)
							end
						end
					else
						TriggerEvent('esx_methcar:drugged')
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'window-maximize'
			},
			{
				title = Locales[Config.Locale]['Question_02_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_02_Answer_2_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
					TriggerEvent('esx_methcar:drugged')
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_02_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_02.Enabled then
						if Questions.Question_02.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
							SetPedPropIndex(playerPed, 1, 26, 7, true)
							PlayerState:set('Paused', false)
						elseif Questions.Question_02.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
								SetPedPropIndex(playerPed, 1, 26, 7, true)
								PlayerState:set('Paused', false)
							else
								TriggerEvent('esx_methcar:drugged')
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_02.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
								SetPedPropIndex(playerPed, 1, 26, 7, true)
								PlayerState:set('Paused', false)
							else
								TriggerEvent('esx_methcar:drugged')
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.succes, Locales[Config.Locale]['Question_02_Answer_3_1'], Config.Noti.time)
						SetPedPropIndex(playerPed, 1, 26, 7, true)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'mask-ventilator'
			},
		},
	})
	lib.showContext('Event_02')
end)

RegisterNetEvent('esx_methcar:Context3')
AddEventHandler('esx_methcar:Context3', function()
	lib.registerContext({
		id = 'Event_03',
		title = Locales[Config.Locale]['Question_03'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_03_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideMenu(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_1_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
				end,
				icon = 'burn'
			},
			{
				title = Locales[Config.Locale]['Question_03_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_03.Enabled then
						if Questions.Question_03.DifficultyAnswer_2 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
							PlayerState:set('Quality', PlayerState.Quality + 5)
							PlayerState:set('Paused', false)
						elseif Questions.Question_03.DifficultyAnswer_2 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 5)
								PlayerState:set('Paused', false)
							else
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_03.DifficultyAnswer_2 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 5)
								PlayerState:set('Paused', false)
							else
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_03_Answer_2_1'], Config.Noti.time)
						PlayerState:set('Quality', PlayerState.Quality + 5)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'temperature-full'
			},
			{
				title = Locales[Config.Locale]['Question_03_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_03.Enabled then
						if Questions.Question_03.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality - 4)
						elseif Questions.Question_03.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 4)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 4)
							end
						elseif Questions.Question_03.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 4)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 4)
							end
						end
					else
						notifications(Config.Noti.error, Locales[Config.Locale]['Question_03_Answer_3_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
						PlayerState:set('Quality', PlayerState.Quality - 4)
					end
				end,
				icon = 'temperature-quarter'
			},
		},
	})
	lib.showContext('Event_03')
end)

RegisterNetEvent('esx_methcar:Context4')
AddEventHandler('esx_methcar:Context4', function()
	lib.registerContext({
		id = 'Event_04',
		title = Locales[Config.Locale]['Question_04'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_04_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideMenu(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
					PlayerState:set('Quality', PlayerState.Quality - 3)
					PlayerState:set('Paused', false)
				end,
				icon = 'circle-pause'
			},
			{
				title = Locales[Config.Locale]['Question_04_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_04.Enabled then
						if Questions.Question_04.DifficultyAnswer_2 == 0 then
							notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality - 1)
						elseif Questions.Question_04.DifficultyAnswer_2 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 3)
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_04.DifficultyAnswer_2 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 3)
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.error, Locales[Config.Locale]['Question_04_Answer_2_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
						PlayerState:set('Quality', PlayerState.Quality - 1)
					end
				end,
				icon = 'syringe'
			},
			{
				title = Locales[Config.Locale]['Question_04_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideMenu(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_04.Enabled then
						if Questions.Question_04.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality + 3)
						elseif Questions.Question_04.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 3)
							else
								notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 3)
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_04.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 3)
							else
								notifications(Config.Noti.error,Locales[Config.Locale]['Question_04_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 3)
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_04_Answer_3_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
						PlayerState:set('Quality', PlayerState.Quality + 3)
					end
				end,
				icon = 'car-battery'
			},
		},
	})
	lib.showContext('Event_04')
end)

RegisterNetEvent('esx_methcar:Context5')
AddEventHandler('esx_methcar:Context5', function()
	lib.registerContext({
		id = 'Event_05',
		title = Locales[Config.Locale]['Question_05'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_05_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_05.Enabled then
						if Questions.Question_05.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
							PlayerState:set('Quality', PlayerState.Quality + 4)
							PlayerState:set('Paused', false)
						elseif Questions.Question_05.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 4)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_05.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 4)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_1_2'], Config.Noti.time)
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_05_Answer_1_1'], Config.Noti.time)
						PlayerState:set('Quality', PlayerState.Quality + 4)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'bottle-droplet'
			},
			{
				title = Locales[Config.Locale]['Question_05_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
										
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.info, Locales[Config.Locale]['Question_05_Answer_2_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
				end,
				icon = 'trash'
			},
			{
				title = Locales[Config.Locale]['Question_05_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
										
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_05_Answer_3_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
				end,
				icon = 'bottle-droplet'
			},
		},
	})
	lib.showContext('Event_05')
end)

RegisterNetEvent('esx_methcar:Context6')
AddEventHandler('esx_methcar:Context6', function()
	lib.registerContext({
		id = 'Event_06',
		title = Locales[Config.Locale]['Question_06'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_06_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_3 == 0 then
							notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
						elseif Questions.Question_06.DifficultyAnswer_3 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 2)
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_06.DifficultyAnswer_3 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.error, Locales[Config.Locale]['Question_06_Answer_1_2'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality - 2)
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.error, CLocales[Config.Locale]['Question_06_Answer_1_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'spray-can'
			},
			{
				title = Locales[Config.Locale]['Question_06_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
					
					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality + 3)
						elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 3)
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_2'], Config.Noti.time)
								PlayerState:set('Paused', false)
							end
						elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 3)
							else
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_2'], Config.Noti.time)
								PlayerState:set('Paused', false)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_06_Answer_2_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
						PlayerState:set('Quality', PlayerState.Quality + 3)
					end	
				end,
				icon = 'wrench'
			},
			{
				title = Locales[Config.Locale]['Question_06_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_06.Enabled then
						if Questions.Question_06.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
							PlayerState:set('Paused', false)
							PlayerState:set('Quality', PlayerState.Quality - 1)
						elseif Questions.Question_06.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							else
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							end
						elseif Questions.Question_06.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							else
								notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality - 1)
							end
						end
					else
						notifications(Config.Noti.info, Locales[Config.Locale]['Question_06_Answer_3_1'], Config.Noti.time)
						PlayerState:set('Paused', false)
						PlayerState:set('Quality', PlayerState.Quality - 1)
					end
				end,
				icon = 'wrench'
			},
		},
	})
	lib.showContext('Event_06')
end)

RegisterNetEvent('esx_methcar:Context7')
AddEventHandler('esx_methcar:Context7', function()
	lib.registerContext({
		id = 'Event_07',
		title = Locales[Config.Locale]['Question_07'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_07_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end
					
					lib.hideContext(true)
					Wait(20)
					
					notifications(Config.Noti.success, Locales[Config.Locale]['Question_07_Answer_1_1'], Config.Noti.time)
					PlayerState:set('Quality', PlayerState.Quality + 1)
					PlayerState:set('Paused', false)
				end,
				icon = 'face-grimace'
			},
			{
				title = Locales[Config.Locale]['Question_07_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end
										
					lib.hideContext(true)
					Wait(20)
					
					notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_2_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
					PlayerState:set('Quality', PlayerState.Quality - 2)
				end,
				icon = 'tree'
			},
			{
				title = Locales[Config.Locale]['Question_07_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
															
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_07_Answer_3_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
					PlayerState:set('Quality', PlayerState.Quality - 1)
				end,
				icon = 'chair'
			},
		},
	})
	lib.showContext('Event_07')
end)

RegisterNetEvent('esx_methcar:Context8')
AddEventHandler('esx_methcar:Context8', function()
	lib.registerContext({
		id = 'Event_08',
		title = Locales[Config.Locale]['Question_08'],
		onExit = function()
			Wait(20)
			TriggerEvent('esx_methcar:stop')
		end,
		options = {
			{title = Locales[Config.Locale]['Choose_Option'], icon = 'question', description = Locales[Config.Locale]['Update1'] .. PlayerState.Progress .. Locales[Config.Locale]['Update2']},
			{
				title = Locales[Config.Locale]['Question_08_Answer_1'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 1') end

					lib.hideContext(true)
					Wait(20)

					local Questions = Config.SkillCheck.Questions

					if not Questions.DisableAll and Questions.Question_08.Enabled then
						if Questions.Question_08.DifficultyAnswer_1 == 0 then
							notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
							PlayerState:set('Quality', PlayerState.Quality + 1)
							PlayerState:set('Paused', false)
						elseif Questions.Question_08.DifficultyAnswer_1 == 1 then
							local success = lib.skillCheck(Questions.Difficulty_1.Difficulty, Questions.Difficulty_1.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 1)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 1)
							end
						elseif Questions.Question_08.DifficultyAnswer_1 == 2 then
							local success = lib.skillCheck(Questions.Difficulty_2.Difficulty, Questions.Difficulty_2.Key)
							if success then
								notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
								PlayerState:set('Quality', PlayerState.Quality + 1)
								PlayerState:set('Paused', false)
							else
								notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
								PlayerState:set('Paused', false)
								PlayerState:set('Quality', PlayerState.Quality + 1)
							end
						end
					else
						notifications(Config.Noti.success, Locales[Config.Locale]['Question_08_Answer_1_1'], Config.Noti.time)
						PlayerState:set('Quality', PlayerState.Quality + 1)
						PlayerState:set('Paused', false)
					end
				end,
				icon = 'wine-glass-empty'
			},
			{
				title = Locales[Config.Locale]['Question_08_Answer_2'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 2') end

					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.sucess, Locales[Config.Locale]['Question_08_Answer_2_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
					PlayerState:set('Quality', PlayerState.Quality + 1)
					
				end,
				icon = 'flask'
			},
			{
				title = Locales[Config.Locale]['Question_08_Answer_3'],
				onSelect = function(args)
					if Config.Debug then print('Pressed 3') end
					
					lib.hideContext(true)
					Wait(20)

					notifications(Config.Noti.error, Locales[Config.Locale]['Question_08_Answer_3_1'], Config.Noti.time)
					PlayerState:set('Paused', false)
					PlayerState:set('Quality', PlayerState.Quality - 1)
				end,
				icon = 'wine-glass-empty'
			},
		},
	})
	lib.showContext('Event_08')
end)
