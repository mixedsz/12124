CL = {}

CL.Notification = function(title, message, time, icon, type)
    if type == "success" then
        if GetResourceState("vms_notify") == 'started' then
            exports["vms_notify"]:Notification(title, message, time, "#27FF09", icon or 'fa-solid fa-dumbbell')
        else
            TriggerEvent('esx:showNotification', message)
            TriggerEvent('QBCore:Notify', message, 'success', time)
        end
    elseif type == "info" then
        if GetResourceState("vms_notify") == 'started' then
            exports["vms_notify"]:Notification(title, message, time, "#428AF5", icon or 'fa-solid fa-dumbbell')
        else
            TriggerEvent('esx:showNotification', message)
            TriggerEvent('QBCore:Notify', message, 'primary', time)
        end
    elseif type == "error" then
        if GetResourceState("vms_notify") == 'started' then
            exports["vms_notify"]:Notification(title, message, time, "#FF0909", icon or 'fa-solid fa-dumbbell')
        else
            TriggerEvent('esx:showNotification', message)
            TriggerEvent('QBCore:Notify', message, 'error', time)
        end
    end
end

CL.TextUI = {
    Enabled = false,
    Open = function(msg)
        if GetResourceState("interact") == 'started' then
            exports["interact"]:Open("E", msg) -- Here you can use your TextUI or use my free one - https://github.com/vames-dev/interact
        elseif GetResourceState("okokTextUI") == 'started' then
            exports['okokTextUI']:Open('[E] '..msg, 'darkgreen', 'right')
        else
            if Config.Core == "ESX" then
                ESX.TextUI(msg)
            else
                exports['qb-core']:DrawText(msg, 'right')
            end
        end
    end,
    Close = function()
        if GetResourceState("interact") == 'started' then
            exports["interact"]:Close() -- Here you can use your TextUI or use my free one - https://github.com/vames-dev/interact
        elseif GetResourceState("okokTextUI") == 'started' then
            exports['okokTextUI']:Close()
        else
            if Config.Core == "ESX" then
                ESX.HideUI()
            else
                exports['qb-core']:HideText()
            end
        end
    end,
}

local _targetZoneCount = 0
CL.Target = function(data, cb)
    if Config.TargetResource == 'ox_target' then
        _targetZoneCount = _targetZoneCount + 1
        exports["ox_target"]:addBoxZone({
            coords = vec(data.coords.x, data.coords.y, data.coords.z),
            size = data.size or vec(0.7, 0.7, 1.5),
            debug = false,
            useZ = true,
            rotation = data.coords.w or 0.0,
            options = {
                {
                    distance = 1.5,
                    name = 'gym-'..data.name..'-'..tostring(_targetZoneCount),
                    icon = data.icon,
                    label = data.label,
                    groups = data.job or nil,
                    onSelect = function()
                        cb()
                    end
                }
            }
        })
    elseif Config.TargetResource == 'qb-target' then
        local id = math.random(1000000,1000000000000)
        exports['qb-target']:AddBoxZone('gym-'..data.name..'-'..id, data.coords.xyz, data.size.x, data.size.y, {
            name = 'gym-'..data.name..'-'..id,
            heading = data.coords.w - 90.0 or 0.0,
            debugPoly = true,
            minZ = data.coords.z - (data.size.y),
            maxZ = data.coords.z + (data.size.y),
        }, {
            options = {
                {
                    num = 1,
                    icon = data.icon,
                    label = data.label,
                    job = data.job or nil,
                    action = function()
                        cb()
                    end,
                }
            },
            distance = 0.7,
        })
    else
        print("Configuration for " .. Config.TargetResource .. " doesn't exist, you have to adjust CL.Target for the target system...")
    end
end

CL.GetClosestPlayers = function()
    if Config.Core == "ESX" then
        local playerInArea = ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 5.0)
        return playerInArea
    elseif Config.Core == "QB-Core" then
        local playerInArea = QBCore.Functions.GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 5.0)
        return playerInArea
    end
end

CL.IsEmployee = function(jobName)
    if Config.Core == "ESX" then
        return PlayerData.job.name == jobName
    elseif Config.Core == "QB-Core" then
        return PlayerData.job.name == jobName
    end
end

CL.IsManager = function(jobName, gymId)
    local managerGrades = Config.Gyms[gymId].manager_grades
    
    if Config.Core == "ESX" then
        if PlayerData.job.name ~= jobName then
            return false
        end
        
        if type(managerGrades) == 'table' then
            for _, grade in ipairs(managerGrades) do
                if PlayerData.job.grade_name == grade then
                    return true
                end
            end
        else
            return PlayerData.job.grade_name == managerGrades
        end
    elseif Config.Core == "QB-Core" then
        if PlayerData.job.name ~= jobName then
            return false
        end

        if type(managerGrades) == 'table' then
            for _, grade in ipairs(managerGrades) do
                if PlayerData.job.grade.name == grade then
                    return true
                end
            end
        else
            return PlayerData.job.grade.name == managerGrades
        end
        
    end
end

CL.IsBoss = function(jobName, gymId)
    local bossGrades = Config.Gyms[gymId].boss_grades
    if Config.Core == "ESX" then
        if PlayerData.job.name ~= jobName then
            return false
        end

        if type(bossGrades) == 'table' then
            for _, grade in ipairs(bossGrades) do
                if PlayerData.job.grade_name == grade then
                    return true
                end
            end
        else
            return PlayerData.job.grade_name == bossGrades
        end
        
    elseif Config.Core == "QB-Core" then
        if PlayerData.job.name ~= jobName then
            return false
        end

        if type(bossGrades) == 'table' then
            for _, grade in ipairs(bossGrades) do
                if PlayerData.job.grade.name == grade then
                    return true
                end
            end
        else
            return PlayerData.job.grade.name == bossGrades
        end

    end
end

CL.IsAllowedCityhall = function(jobName, gymId)
    local allowed = {}
    local options = Config.Gyms[gymId].cityhall_grades
    if Config.Core == "ESX" then
        if PlayerData.job.name ~= jobName then
            return false
        end

        if options['resumes'] then
            if type(options['resumes']) == 'table' then
                for _, grade in ipairs(options['resumes']) do
                    if PlayerData.job.grade_name == grade then
                        allowed['resumes'] = true
                        break
                    end
                end
            else
                if PlayerData.job.grade_name == options['resumes'] then
                    allowed['resumes'] = true
                end
            end
        end

        if options['taxes'] then
            if type(options['taxes']) == 'table' then
                for _, grade in ipairs(options['taxes']) do
                    if PlayerData.job.grade_name == grade then
                        allowed['taxes'] = true
                        break
                    end
                end
            else
                if PlayerData.job.grade_name == options['taxes'] then
                    allowed['taxes'] = true
                end
            end
        end
        
    elseif Config.Core == "QB-Core" then
        if PlayerData.job.name ~= jobName then
            return false
        end

        if options['resumes'] then
            if type(options['resumes']) == 'table' then
                for _, grade in ipairs(options['resumes']) do
                    if PlayerData.job.grade.name == grade then
                        allowed['resumes'] = true
                        break
                    end
                end
            else
                if PlayerData.job.grade.name == options['resumes'] then
                    allowed['resumes'] = true
                end
            end
        end

        if options['taxes'] then
            if type(options['taxes']) == 'table' then
                for _, grade in ipairs(options['taxes']) do
                    if PlayerData.job.grade.name == grade then
                        allowed['taxes'] = true
                        break
                    end
                end
            else
                if PlayerData.job.grade.name == options['taxes'] then
                    allowed['taxes'] = true
                end
            end
        end
        
    end

    return allowed
end

CL.GetEmployees = function(cb, jobName)
    if Config.Core == "ESX" then
        ESX.TriggerServerCallback('esx_society:getEmployees', function(employees)
            cb(employees)
        end, jobName)

        -- local employees = lib.callback.await('esx_society:getEmployees', false, jobName) -- OX_LIB ESX_SOCIETY
        -- cb(employees)

    elseif Config.Core == "QB-Core" then
        QBCore.Functions.TriggerCallback('qb-bossmenu:server:GetEmployees', function(employees)
            cb(employees)
        end, jobName)
        
    end
end


local speedUnit = Config.UnitOfSpeed == 'kmh' and 3.6 or 2.236936

function DrawText3D(x, y, z, text) -- This is the function used when using Config.Use3DText
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextDropShadow()
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end



local removeCondition = true

local shootingBlacklistWeapons = {
    [`weapon_fireextinguisher`] = true,
    [`weapon_petrolcan`] = true,
    [`weapon_hazardcan`] = true,
    [`weapon_fertilizercan`] = true,
    [`weapon_grenade`] = true,
    [`weapon_bzgas`] = true,
    [`weapon_molotov`] = true,
    [`weapon_stickybomb`] = true,
    [`weapon_proxmine`] = true,
    [`weapon_snowball`] = true,
    [`weapon_pipebomb`] = true,
    [`weapon_ball`] = true,
    [`weapon_smokegrenade`] = true,
    [`weapon_flare`] = true,
    [`weapon_acidpackage`] = true,
    [`weapon_rpg`] = true,
    [`weapon_grenadelauncher`] = true,
    [`weapon_grenadelauncher_smoke`] = true,
    [`weapon_minigun`] = true,
    [`weapon_firework`] = true,
    [`weapon_railgun`] = true,
    [`weapon_hominglauncher`] = true,
    [`weapon_compactlauncher`] = true,
    [`weapon_rayminigun`] = true,
    [`weapon_emplauncher`] = true,
    [`weapon_railgunxm3`] = true,
}

Citizen.CreateThread(function()
    local waiting = 2000
    while Config.StatisticsMenu["shooting"] do
        Citizen.Wait(waiting)
        local myPed = PlayerPedId()
        waiting = 2000
        local status, weapon = GetCurrentPedWeapon(myPed, true)
        if status == 1 then
            if not shootingBlacklistWeapons[weapon] then
                waiting = 10
                if IsPedShooting(myPed) then
                    if math.random(3) >= 2 then
                        addSkill("shooting", type(Config.AddStatsValues['Shooting']) == "number" and Config.AddStatsValues['Shooting']/10.0 or math.random(Config.AddStatsValues['Shooting'][1], Config.AddStatsValues['Shooting'][2])/10.0)
                    end
                    Citizen.Wait(math.random(6500, 10000))
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeAddStats)
        local myPed = PlayerPedId()
        local myVehicle = GetVehiclePedIsUsing(myPed)
        removeCondition = true
        if IsPedRunning(myPed) and Config.StatisticsMenu['condition'] then
            addSkill("condition", type(Config.AddStatsValues['Running']) == "number" and (Config.AddStatsValues['Running']/10.0)*conditionBooster or (math.random(Config.AddStatsValues['Running'][1], Config.AddStatsValues['Running'][2])/10.0)*conditionBooster)
            removeCondition = false
        elseif IsPedSwimmingUnderWater(myPed) and Config.StatisticsMenu['condition'] then
            addSkill("condition", type(Config.AddStatsValues['Swimming']) == "number" and (Config.AddStatsValues['Swimming']/10.0)*conditionBooster or (math.random(Config.AddStatsValues['Swimming'][1], Config.AddStatsValues['Swimming'][2])/10.0)*conditionBooster)
            removeCondition = false
        elseif DoesEntityExist(myVehicle) then
            local isDriver = GetPedInVehicleSeat(myVehicle, -1) == PlayerPedId()
            if isDriver then
                local speed = GetEntitySpeed(myVehicle) * speedUnit
                local vehicleClass = GetVehicleClass(myVehicle)
                if vehicleClass == 13 and speed >= Config.AddStatsValues['Cycling'].minimumSpeed and Config.StatisticsMenu['condition'] then
                    addSkill("condition", type(Config.AddStatsValues['Cycling'].value) == "number" and (Config.AddStatsValues['Cycling'].value/10.0)*conditionBooster or (math.random(Config.AddStatsValues['Cycling'].value[1], Config.AddStatsValues['Cycling'].value[2])/10.0)*conditionBooster)
                    removeCondition = false
                elseif (vehicleClass == 15 or vehicleClass == 16) and speed >= Config.AddStatsValues['Flying'].minimumSpeed and Config.StatisticsMenu['flying'] then
                    addSkill("flying", type(Config.AddStatsValues['Flying'].value) == "number" and Config.AddStatsValues['Flying'].value/10.0 or math.random(Config.AddStatsValues['Flying'].value[1], Config.AddStatsValues['Flying'].value[2])/10.0)
                elseif (vehicleClass ~= 15 and vehicleClass ~= 16 and vehicleClass ~= 14) and speed >= Config.AddStatsValues['Driving'].minimumSpeed and Config.StatisticsMenu['driving'] then
                    addSkill("driving", type(Config.AddStatsValues['Driving'].value) == "number" and Config.AddStatsValues['Driving'].value/10.0 or math.random(Config.AddStatsValues['Driving'].value[1], Config.AddStatsValues['Driving'].value[2])/10.0)
                end
            end
        end
        if myStatistics then
            if myStatistics['strenght'] and Config.EnableStrenghtModifier then
                if myStatistics['strenght'] >= 70.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 2.0)
                elseif myStatistics['strenght'] >= 50.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.5)
                elseif myStatistics['strenght'] >= 20.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.25)
                else
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.0)
                end
            end
            if myStatistics['condition'] then
                if myStatistics['condition'] >= 70.0 then
                    if Config.EnableRunSpeedModifier then
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
                    end
                    if Config.EnableStaminaModifier then
                        StatSetInt(GetHashKey('MP0_STAMINA'), 60, true)
                    end
                elseif myStatistics['condition'] >= 50.0 then
                    if Config.EnableRunSpeedModifier then
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.35)
                    end
                    if Config.EnableStaminaModifier then
                        StatSetInt(GetHashKey('MP0_STAMINA'), 30, true)
                    end
                elseif myStatistics['condition'] >= 20.0 then
                    if Config.EnableRunSpeedModifier then
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.1)
                    end
                    if Config.EnableStaminaModifier then
                        StatSetInt(GetHashKey('MP0_STAMINA'), 15, true)
                    end
                else
                    if Config.EnableRunSpeedModifier then
                        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
                    end
                    if Config.EnableStaminaModifier then
                        StatSetInt(GetHashKey('MP0_STAMINA'), 0, true)
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeRemoveStats)
        if removeCondition and Config.StatisticsMenu['condition'] and type(removeSkill) == 'function' then
            removeSkill("condition", type(Config.RemoveStatsValues['RemoveCondition']) == "number" and Config.RemoveStatsValues['RemoveCondition']/10.0 or math.random(Config.RemoveStatsValues['RemoveCondition'][1], Config.RemoveStatsValues['RemoveCondition'][2])/10.0)
        end
        Citizen.Wait(3000)
        if removeStrength and Config.StatisticsMenu['strenght'] and type(removeSkill) == 'function' then
            removeSkill("strenght", type(Config.RemoveStatsValues['RemoveStrength']) == "number" and Config.RemoveStatsValues['RemoveStrength']/10.0 or math.random(Config.RemoveStatsValues['RemoveStrength'][1], Config.RemoveStatsValues['RemoveStrength'][2])/10.0)
        end
    end
end)

Citizen.CreateThread(function()
    local sleep = false
    while Config.EnableSkillDrivingEffects and Config.StatisticsMenu["driving"] do
        sleep = false
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        local isDriver = GetPedInVehicleSeat(myVeh, -1) == PlayerPedId()
        if myVeh and isDriver then
            if (GetEntitySpeed(myVeh)*speedUnit > Config.SkillDrivingEffectMinimumSpeed) then
                sleep = false
                local myDrivingSkill = exports['flake_gym']:getSkill('driving')
                if myDrivingSkill < 20.0 then
                    local biasRandom = (math.random(-1, 1) + 0.0)
                    SetVehicleSteerBias(myVeh, biasRandom)
                    SetVehicleReduceGrip(myVeh, true)
                    Citizen.Wait(math.random(200, 450))
                    SetVehicleSteerBias(myVeh, biasRandom)
                    SetVehicleReduceGrip(myVeh, false)
                    Citizen.Wait(math.random(1750, 3000))
                elseif myDrivingSkill >= 20.0 and myDrivingSkill < 50.0 then
                    local biasRandom = (math.random(-7, 7) + 0.0) / 10
                    SetVehicleSteerBias(myVeh, biasRandom)
                    if (GetVehicleSteeringAngle(myVeh) > 30.0) or (GetVehicleSteeringAngle(myVeh) < -30.0) then
                        SetVehicleReduceGrip(myVeh, true)
                        Citizen.Wait(math.random(200, 450))
                        SetVehicleReduceGrip(myVeh, false)
                    end
                    Citizen.Wait(math.random(1750, 4000))
                elseif myDrivingSkill >= 50.0 and myDrivingSkill < 70.0 then
                    local biasRandom = (math.random(-5, 5) + 0.0) / 10
                    SetVehicleSteerBias(myVeh, biasRandom)
                    Citizen.Wait(math.random(2000, 6000))
                elseif myDrivingSkill >= 70.0 and myDrivingSkill < 80.0 then
                    local biasRandom = (math.random(-2, 2) + 0.0) / 10
                    SetVehicleSteerBias(myVeh, biasRandom)
                    Citizen.Wait(math.random(5000, 8000))
                end
            end
        end
        Citizen.Wait(sleep and 1000 or 500)
    end
end)