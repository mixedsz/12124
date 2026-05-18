waitingForLoadAfterRestart = false
currentGymManagement = nil
stores = {}
billCache = {}

PlayerData = {}

disabledNotifySkillInfo = false

local _gymId = nil
local _pointId = nil
local _pointTable = nil

local myProp = nil
local myProp2 = nil

myStatistics = nil
local myStamina = nil

local playerMemberships = {}
local ownedMemberships = {}

conditionBooster = 1.0
strengthBooster = 1.0

removeStrength = true

currentShop = nil

if Config.Core == "ESX" then
    ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if Config.Core == "ESX" then
        while not ESX do
            Citizen.Wait(200)
        end
        if ESX.IsPlayerLoaded() then
            PlayerData = ESX.GetPlayerData()
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent('vms_gym:sv:restartPlayer')
        end
    elseif Config.Core == "QB-Core" then
        while not QBCore do
            Citizen.Wait(200)
        end
        if QBCore.Functions.GetPlayerData() and QBCore.Functions.GetPlayerData().job then
            PlayerData = QBCore.Functions.GetPlayerData()
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent('vms_gym:sv:restartPlayer')
        end
    end
end)

RegisterNetEvent(Config.PlayerLoaded)
AddEventHandler(Config.PlayerLoaded, function(PLAYER_DATA)
    PlayerData = Config.Core == "ESX" and PLAYER_DATA or Config.Core == "QB-Core" and QBCore.Functions.GetPlayerData()
    waitingForLoadAfterRestart = true
	TriggerServerEvent("vms_gym:fetchData")
end)

RegisterNetEvent(Config.JobUpdated)
AddEventHandler(Config.JobUpdated, function(job)
    PlayerData.job = job
end) 

RegisterNetEvent("vms_cityhall:updatedStatusResume", function(jobName, val)
    if not Config.UseCityHallResumes then
        return
    end
    
    if currentGymManagement then
        if Config.Gyms[currentGymManagement].ownerJob == jobName then
            SendNUIMessage({
				action = "updateManagementMenu",
                isResumesAllowed = val
			})
        end
    end
end)

RegisterNetEvent("vms_cityhall:updatedBusinessTaxes", function(jobName, taxesList)
    if not Config.UseCityHallTaxes then
        return
    end
    
    if currentGymManagement then
        if Config.Gyms[currentGymManagement].ownerJob == jobName then
            SendNUIMessage({
				action = "updateManagementMenu",
                taxes = taxesList,
			})
        end
    end
end)

RegisterNetEvent("vms_gym:fetchedData", function(_stores)
	stores = _stores

    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        for _, v in pairs(Config.Gyms) do
            if v.memberships and next(v.memberships) then
                for name, data in pairs(v.memberships) do
                    local totalAmount, taxAmount, taxPercentage = exports[Config.VMSCityHallResource]:getTaxAmount(data.price, 'gym.memberships')
                    data.totalAmount = totalAmount
                    data.taxAmount = taxAmount
                    data.taxPercentage = taxPercentage
                end
            end

            if v.proteins and next(v.proteins) then
                for name, data in pairs(v.proteins) do
                    local totalAmount, taxAmount, taxPercentage = exports[Config.VMSCityHallResource]:getTaxAmount(data.price, v.tax or 'gym.proteins')
                    data.totalAmount = totalAmount
                    data.taxAmount = taxAmount
                    data.taxPercentage = taxPercentage
                end
            end
        end
    end

	waitingForLoadAfterRestart = false
end)

RegisterNetEvent('vms_gym:cl:getBill', function(gymId, membershipData, proteinsData, count)
    SetNuiFocus(true, true)
    if membershipData then
        SendNUIMessage({action = "openReceipt", membershipData = membershipData})
    elseif proteinsData and count then
        SendNUIMessage({action = "openReceipt", proteinsData = proteinsData, count = count})
    end    
end)

RegisterNetEvent('vms_gym:cl:getBillFeedback', function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "closeReceipt"})
end)

RegisterNetEvent("vms_gym:updateBusiness", function(_storeId, _storeData, specificValues)
    if not stores[_storeId] then return end;
    local societyBalance = 0
	if specificValues then
		if specificValues.sub then
			if specificValues.sub == 'balance' or specificValues.sub == 'totalEarned' then
                if specificValues.sub == 'balance' and not Config.UseBuildInCompanyBalance then
					societyBalance = specificValues.value
				else
					stores[_storeId].data[specificValues.sub] = specificValues.value
				end
			else
				stores[_storeId][specificValues.sub] = specificValues.value
			end
		else
			for k, v in pairs(specificValues) do
				if v.sub == "data" then
					stores[_storeId][v.sub] = v.value
				else
                    if v.sub == 'balance' and not Config.UseBuildInCompanyBalance then
						societyBalance = v.value
					else
                        stores[_storeId].data[v.sub] = v.value
                    end
				end
			end
		end
	else
		stores[_storeId] = _storeData
	end
	if currentGymManagement and currentGymManagement == _storeId then
		if specificValues and specificValues.sub and specificValues.sub == "employees" then
			CL.GetEmployees(function(employees)
				SendNUIMessage({
					action = "updateManagementMenu",
					storeData = stores[currentGymManagement],
					employees = employees,
					employeesCount = #employees,
				})
			end, Config.Gyms[currentGymManagement].ownerJob)
		else
			SendNUIMessage({
				action = "updateManagementMenu",
				storeData = stores[currentGymManagement],
                societyBalance = not Config.UseBuildInCompanyBalance and (tonumber(societyBalance) and tostring(societyBalance)) or nil
			})
		end
	end
end)

openBossMenu = function(gymPointId)
    if waitingForLoadAfterRestart then
        return
    end

    local gymData = Config.Gyms[gymPointId]

    if Config.UseVMSCityHall then
        if Config.Core == "ESX" then
            ESX.TriggerServerCallback('vms_cityhall:getBusinessData', function(resumesList, taxesList)
                local resumesList = resumesList;
                local taxesList = taxesList;
                CL.GetEmployees(function(employees)
                    currentGymManagement = gymPointId
                    SendNUIMessage({
                        action = "openManagementMenu",
                        storeData = stores[gymPointId],
                        storeCfg = Config.Gyms[gymPointId],
                        employees = employees,
                        employeesCount = #employees,
                        isEmployee = CL.IsEmployee(Config.Gyms[gymPointId].ownerJob),
                        isManager = CL.IsManager(Config.Gyms[gymPointId].ownerJob, gymPointId),
                        isBoss = CL.IsBoss(Config.Gyms[gymPointId].ownerJob, gymPointId),
    
                        cityhallGrades = CL.IsAllowedCityhall(Config.Gyms[gymPointId].ownerJob, gymPointId),

                        membershipsList = gymData.requiredMembership and gymData.allowSellMembership and gymData.memberships or nil,
                        proteinsList = gymData.allowSellProteins and gymData.proteins or nil,

                        isResumesAllowed = Config.UseCityHallResumes and exports[Config.VMSCityHallResource]:isResumesAllowed(Config.Gyms[gymPointId].ownerJob) or false,
                        resumes = resumesList,
    
                        isTaxesAllowed = Config.UseCityHallTaxes,
                        taxes = taxesList,
                        
                    })
                end, Config.Gyms[gymPointId].ownerJob)
            end, Config.UseCityHallResumes, Config.UseCityHallTaxes)
        else
            QBCore.Functions.TriggerCallback('vms_cityhall:getBusinessData', function(resumesList, taxesList)
                local resumesList = resumesList;
                local taxesList = taxesList;
                CL.GetEmployees(function(employees)
                    currentGymManagement = gymPointId
                    SendNUIMessage({
                        action = "openManagementMenu",
                        storeData = stores[gymPointId],
                        storeCfg = Config.Gyms[gymPointId],
                        employees = employees,
                        employeesCount = #employees,
                        isEmployee = CL.IsEmployee(Config.Gyms[gymPointId].ownerJob),
                        isManager = CL.IsManager(Config.Gyms[gymPointId].ownerJob, gymPointId),
                        isBoss = CL.IsBoss(Config.Gyms[gymPointId].ownerJob, gymPointId),
    
                        cityhallGrades = CL.IsAllowedCityhall(Config.Gyms[gymPointId].ownerJob, gymPointId),
                        
                        membershipsList = gymData.requiredMembership and gymData.allowSellMembership and gymData.memberships or nil,
                        proteinsList = gymData.allowSellProteins and gymData.proteins or nil,

                        isResumesAllowed = Config.UseCityHallResumes and exports[Config.VMSCityHallResource]:isResumesAllowed(Config.Gyms[gymPointId].ownerJob) or false,
                        resumes = resumesList,
    
                        isTaxesAllowed = Config.UseCityHallTaxes,
                        taxes = taxesList,
                        
                    })
                end, Config.Gyms[gymPointId].ownerJob)
            end, Config.UseCityHallResumes, Config.UseCityHallTaxes)
        end
    else
        CL.GetEmployees(function(employees)
            currentGymManagement = gymPointId
            SendNUIMessage({
                action = "openManagementMenu",
                storeData = stores[gymPointId],
                storeCfg = Config.Gyms[gymPointId],
                employees = employees,
                employeesCount = #employees,
                isEmployee = CL.IsEmployee(Config.Gyms[gymPointId].ownerJob),
                isManager = CL.IsManager(Config.Gyms[gymPointId].ownerJob, gymPointId),
                isBoss = CL.IsBoss(Config.Gyms[gymPointId].ownerJob, gymPointId),

                membershipsList = gymData.requiredMembership and gymData.allowSellMembership and gymData.memberships or nil,
                proteinsList = gymData.allowSellProteins and gymData.proteins or nil,
            })
        end, Config.Gyms[gymPointId].ownerJob)
    end
    
	SetNuiFocus(true, true)
    if not Config.UseBuildInCompanyBalance then
		Citizen.Wait(300)
		TriggerServerEvent(Config.ESXSocietyEvents['check'], Config.Gyms[gymPointId].ownerJob)
	end
end

closeManagementMenu = function()
	SendNUIMessage({action = "closeManagementMenu"})
    currentBarberManagement = nil
	SetNuiFocus(false, false)
end

RegisterNetEvent('vms_gym:cl:getMemberships')
AddEventHandler('vms_gym:cl:getMemberships', function(memberships)
	playerMemberships = memberships
    ownedMemberships = {}
    for k, v in pairs(playerMemberships) do
        ownedMemberships[v.name] = v.time
    end

    if currentShop and Config.Gyms[currentShop].requiredMembership then
        SendNUIMessage({
            action = 'updatePurchaseMenu',
            type = 'membership',
            myMembership = ownedMemberships[Config.Gyms[currentShop].requiredMembership]
        })
    end
end)

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

function requestProp(prop)
    RequestModel(prop)
    while not HasModelLoaded(prop) do
        Citizen.Wait(100)
        RequestModel(prop)
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(250)
    for k, v in pairs(Config.Gyms) do
        if v.blipCoords and v.blipEnabled then
            v._createdBlip = AddBlipForCoord(v.blipCoords)
            SetBlipSprite(v._createdBlip, Config.Blip['Sprite'])
            SetBlipDisplay(v._createdBlip, Config.Blip['Display'])
            SetBlipScale(v._createdBlip, Config.Blip['Scale'])
            SetBlipColour(v._createdBlip, Config.Blip['Color'])
            SetBlipAsShortRange(v._createdBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blipName)
            EndTextCommandSetBlipName(v._createdBlip)
        end
    end

    if Config.UseTarget and Config.TargetResource == "ox_target" or Config.Menu == "ox_lib" then
        local import = LoadResourceFile('ox_lib', 'init.lua')
        local chunk = assert(load(import, '@@ox_lib/init.lua'))
        chunk()
    end

    if Config.UseTarget then
        for k, v in pairs(Config.Gyms) do
            if v.business and v.ownerJob and v.bossMenu then
                v.bossMenu.targetId = CL.Target({
                    name = 'bossmenu',
                    coords = v.bossMenu.targetCoords,
                    size = v.bossMenu.targetSize,
                    job = v.ownerJob,
                    label = TRANSLATE('target.boss_menu'),
                    icon = 'fa-solid fa-dollar-sign'
                }, function()
                    openBossMenu(k)
                end)
            end

            if v.shopMenu and v.allowBuyMembership and v.requiredMembership or v.allowBuyProteins then
                v.shopMenu.targetId = CL.Target({
                    name = 'shopmenu',
                    coords = v.shopMenu.targetCoords,
                    size = v.shopMenu.targetSize,
                    label = TRANSLATE('target.shop_menu'),
                    icon = 'fa-solid fa-dollar-sign'
                }, function()
                    openPurchaseMenu(k)
                end)
            end
            
            for _k, _v in pairs(v.points) do
                _v.targetId = CL.Target({
                    name = _v.name,
                    coords = _v.activityCoord,
                    size = _v.targetSize,
                    label = TRANSLATE('target.'.._v.name),
                    icon = 'fa-solid fa-dumbbell'
                }, function()
                    startAction(k, _k, _v)
                end)
            end
            
        end
    end
end)

Citizen.CreateThread(function()
    local inRange = false
    local shown = false
    local sleep = true
    while not Config.UseTarget do
        inRange = false
        sleep = true
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        for k, v in pairs(Config.Gyms) do
            local distance = #(myCoords - v.blipCoords)
            if distance < 45.0 then
                sleep = false
                for _k, _v in pairs(v.points) do
                    if not _v.taken then
                        local _distance = #(myCoords - vec(_v.position.x, _v.position.y, _v.position.z))
                        if _distance < Config.DistanceView then
                            if Config.UseMarkers then
                                DrawMarker(Config.Markers['FreeSeat'].id, vec(_v.position.x, _v.position.y, _v.position.z), 0, 0, 0, Config.Markers['FreeSeat'].rotation[1], Config.Markers['FreeSeat'].rotation[2], Config.Markers['FreeSeat'].rotation[3], Config.Markers['FreeSeat'].size, Config.Markers['FreeSeat'].color[1], Config.Markers['FreeSeat'].color[2], Config.Markers['FreeSeat'].color[3], Config.Markers['FreeSeat'].color[4], Config.Markers['FreeSeat'].bobUpAndDown, false, false, Config.Markers['FreeSeat'].rotate, false, false, false)
                            end
                            if Config.Use3DText then
                                DrawText3D(_v.position.x, _v.position.y, _v.position.z, TRANSLATE('3dtext.'.._v.name))
                            end
                            if _distance < 1.25 then
                                inRange = TRANSLATE('textui.'.._v.name)
                                if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                    ESX.ShowHelpNotification(TRANSLATE('help.'.._v.name))
                                end
                                if IsControlJustPressed(0, Config.Keys['enter']) then
                                    startAction(k, _k, _v)
                                    inRange = false
                                end
                            end
                        end
                    end
                end
            end

            if v.business and v.bossMenu and v.bossMenu.coords then
                local distance = #(myCoords - v.bossMenu.coords.xyz)
                if distance < Config.DistanceView and PlayerData and PlayerData.job and CL.IsEmployee(v.ownerJob) then
                    sleep = false
                    if Config.UseMarkers then
                        DrawMarker(Config.Markers['BossMenu'].id, v.bossMenu.coords.xyz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Markers['BossMenu'].size, Config.Markers['BossMenu'].color[1], Config.Markers['BossMenu'].color[2], Config.Markers['BossMenu'].color[3], Config.Markers['BossMenu'].color[4], Config.Markers['BossMenu'].bobUpAndDown, false, false, Config.Markers['BossMenu'].rotate, false, false, false)
                    end
                    if Config.Use3DText then
                        DrawText3D(v.bossMenu.coords.x, v.bossMenu.coords.y, v.bossMenu.coords.z, TRANSLATE("3dtext.boss_menu"))
                    end
                    if distance < Config.DistanceAccess then
                        inRange = TRANSLATE("textui.boss_menu")
                        if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                            ESX.ShowHelpNotification(TRANSLATE("help.boss_menu"))
                        end
                        if IsControlJustPressed(0, 38) then
                            openBossMenu(k)
                            inRange = false
                        end
                    end
                end
            end

            
            if v.shopMenu and v.shopMenu.coords and (v.allowBuyMembership or v.allowBuyProteins) then
                local distance = #(myCoords - v.shopMenu.coords.xyz)
                if distance < Config.DistanceView then
                    sleep = false
                    if Config.UseMarkers then
                        DrawMarker(Config.Markers['ShopMenu'].id, v.shopMenu.coords.xyz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Markers['ShopMenu'].size, Config.Markers['ShopMenu'].color[1], Config.Markers['ShopMenu'].color[2], Config.Markers['ShopMenu'].color[3], Config.Markers['ShopMenu'].color[4], Config.Markers['ShopMenu'].bobUpAndDown, false, false, Config.Markers['ShopMenu'].rotate, false, false, false)
                    end
                    if Config.Use3DText then
                        DrawText3D(v.bossMenu.coords.x, v.bossMenu.coords.y, v.bossMenu.coords.z, TRANSLATE("3dtext.shop_menu"))
                    end
                    if distance < Config.DistanceAccess then
                        inRange = TRANSLATE("textui.shop_menu")
                        if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                            ESX.ShowHelpNotification(TRANSLATE("help.shop_menu"))
                        end
                        if IsControlJustPressed(0, 38) then
                            openPurchaseMenu(k)
                            inRange = false
                        end
                    end
                end
            end
        end
        if CL.TextUI.Enabled then
            if inRange and not shown then
                shown = true
                CL.TextUI.Open(inRange)
            elseif not inRange and shown then
                shown = false
                CL.TextUI.Close()
            end
        end
        Citizen.Wait(sleep and 2000 or 1)
    end
end)

function openPurchaseMenu(k)
    if waitingForLoadAfterRestart then
        return
    end

    local gymData = Config.Gyms[k]
    if not gymData then
        return
    end

    local nuiData = {
        action = 'openPurchaseMenu'
    }

    if gymData.requiredMembership and gymData.allowBuyMembership then
        nuiData.useMemberships = true
        nuiData.membershipsList = gymData.memberships
        nuiData.myMembership = ownedMemberships[gymData.requiredMembership]
    end

    if gymData.allowBuyProteins then
        nuiData.useProteins = true
        nuiData.proteinsList = gymData.proteins
    end

    if (gymData.allowBuyMembership or gymData.allowBuyProteins) then
        currentShop = k
        Citizen.Wait(100)
        SetNuiFocus(true, true)
        SendNUIMessage(nuiData)
    end

end

function buyProtein(name)
    if not name then return end
    if not currentShop then return end

    local gymData = Config.Gyms[currentShop]
    if not gymData then return end
    
    if not gymData.proteins then
        return
    end
    if not gymData.allowBuyProteins then
        return
    end

    TriggerServerEvent('vms_gym:sv:buyProtein', currentShop, name)

end

function buyMembership(days, hours)
    if not days and not hours then return end
    if not currentShop then return end

    local gymData = Config.Gyms[currentShop]
    if not gymData then return end
    
    if not gymData.requiredMembership then
        return
    end

    if not gymData.allowBuyMembership then
        return
    end

    local membershipData = nil
    for k, v in pairs(gymData.memberships) do
        if v.days == days and v.hours == hours  then
            membershipData = v
            break
        end
    end

    TriggerServerEvent('vms_gym:sv:acceptMembership', currentShop, gymData.requiredMembership, membershipData)
end

startAction = function(gymId, pointId, pointTable)
    if _pointId then
        return
    end    
    if Config.EnableMemberships and Config.Gyms[gymId].requiredMembership and not ownedMemberships[Config.Gyms[gymId].requiredMembership] then
        if Config.AutoMembershipForEmployees and PlayerData.job.name == Config.Gyms[gymId].ownerJob then
            goto jobAccess
        else
            return CL.Notification(TRANSLATE('notify.title.gym'), TRANSLATE('no_membership'), 3500, "fa-solid fa-dumbbell", 'error')
        end
    end
    ::jobAccess::
    if pointTable.taken then
        return CL.Notification(TRANSLATE('notify.title.gym'), TRANSLATE('place_taken'), 3500, "fa-solid fa-dumbbell", 'error')
    end
    _gymId = gymId
    _pointId = pointId
    _pointTable = pointTable
    removeStrength = false
    if pointTable.activityCoord.w then
        SetEntityHeading(PlayerPedId(), _pointTable.activityCoord.w)
    end
    if pointTable.activityCoord.x and pointTable.activityCoord.y and pointTable.activityCoord.z then
        SetEntityCoords(PlayerPedId(), vec(pointTable.activityCoord.x, pointTable.activityCoord.y, pointTable.activityCoord.z))
    end
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCollision(PlayerPedId(), false, false)
    for k, v in pairs(Config.Animations[pointTable.name]) do
        loadAnimDict(v[1])
    end
    TriggerServerEvent('vms_gym:sv:setTaken', _gymId, _pointId, true)
    SendNUIMessage({action = 'openHelpKeys', stamina = GetPlayerStamina(PlayerId())})
    if Config.Animations[pointTable.name].enter then
        TaskPlayAnim(PlayerPedId(), Config.Animations[pointTable.name].enter[1], Config.Animations[pointTable.name].enter[2], 8.0, -8.0, Config.Animations[pointTable.name].enter[3], 0, 0.0, 0, 0, 0)
        Citizen.Wait(Config.Animations[pointTable.name].enter[3])
    end
    Citizen.CreateThread(function()
        TaskPlayAnim(PlayerPedId(), Config.Animations[_pointTable.name].idle[1], Config.Animations[_pointTable.name].idle[2], 8.0, -8.0, Config.Animations[_pointTable.name].idle[3], 1, 0.0, 0, 0, 0)
        if _pointTable.prop then
            requestProp(GetHashKey(_pointTable.prop.name))
            local myCoords = GetEntityCoords(PlayerPedId())
            myProp = CreateObject(GetHashKey(_pointTable.prop.name), myCoords, true, true, true)
            AttachEntityToEntity(myProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), _pointTable.prop.attachBone), _pointTable.prop.placement[1] + 0.0, _pointTable.prop.placement[2] + 0.0, _pointTable.prop.placement[3] + 0.0, _pointTable.prop.placement[4] + 0.0, _pointTable.prop.placement[5] + 0.0, _pointTable.prop.placement[6] + 0.0, true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(myProp)
        end
        if _pointTable.prop2 then
            requestProp(GetHashKey(_pointTable.prop2.name))
            local myCoords = GetEntityCoords(PlayerPedId())
            myProp2 = CreateObject(GetHashKey(_pointTable.prop2.name), myCoords, true, true, true)
            AttachEntityToEntity(myProp2, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), _pointTable.prop2.attachBone), _pointTable.prop2.placement[1] + 0.0, _pointTable.prop2.placement[2] + 0.0, _pointTable.prop2.placement[3] + 0.0, _pointTable.prop2.placement[4] + 0.0, _pointTable.prop2.placement[5] + 0.0, _pointTable.prop2.placement[6] + 0.0, true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(myProp2)
        end
        while _pointTable do
            if IsControlJustPressed(0, Config.Keys['train']) then
                myStamina = GetPlayerStamina(PlayerId())
                local crashedSkillbar = false
                if myStamina > (getSkill('condition') >= 10.0 and ((_pointTable.removeStamina * 100) / getSkill('condition')) or getSkill('condition') < 10.0 and ((_pointTable.removeStamina*10.0))) then
                    if Config.UseSkillbar then
                        Config.Skillbar(_pointTable.name, function(isDone)
                            crashedSkillbar = false
                            if not isDone then
                                crashedSkillbar = true
                            end
                        end)
                    end
                    if not crashedSkillbar then
                        if Config.UseProgressbar then
                            Config.Progressbar(_pointTable.name, Config.Animations[_pointTable.name].training[3])
                            TriggerServerEvent('ak4y-battlepass:taskCountAdd:standart', 8, 1)
                        end
                        TaskPlayAnim(PlayerPedId(), Config.Animations[_pointTable.name].training[1], Config.Animations[_pointTable.name].training[2], 8.0, -8.0, Config.Animations[_pointTable.name].training[3], 0, 0.0, 0, 0, 0)
                        Citizen.Wait(Config.Animations[_pointTable.name].training[3])
                        TaskPlayAnim(PlayerPedId(), Config.Animations[_pointTable.name].idle[1], Config.Animations[_pointTable.name].idle[2], 8.0, -8.0, Config.Animations[_pointTable.name].idle[3], 1, 0.0, 0, 0, 0)
                        SetPlayerStamina(PlayerId(), myStamina - (getSkill('condition') >= 10.0 and ((_pointTable.removeStamina * 100) / getSkill('condition')) or getSkill('condition') < 10.0 and ((_pointTable.removeStamina*10.0))))
                        if _pointTable.addSkill and _pointTable.addSkill.skill and _pointTable.addSkill.value then
                            if type(_pointTable.addSkill.value) == 'number' then
                                addSkill(_pointTable.addSkill.skill, (_pointTable.addSkill.value/10) * ( _pointTable.addSkill.skill == "strenght" and strengthBooster or conditionBooster))
                            else
                                addSkill(_pointTable.addSkill.skill, (math.random(_pointTable.addSkill.value[1], _pointTable.addSkill.value[2])/10)* ( _pointTable.addSkill.skill == "strenght" and strengthBooster or conditionBooster))
                            end
                        end
                    end
                else
                    CL.Notification(TRANSLATE('notify.title.gym'), TRANSLATE('out_of_breath'), 3850, "fa-solid fa-dumbbell", 'info')
                    Citizen.Wait(1000)
                end
            end
            if IsControlJustPressed(0, Config.Keys['stop']) then
                stopAction()
            end
            Citizen.Wait(1)
        end
    end)
    Citizen.CreateThread(function()
        while _pointTable do
            SendNUIMessage({action = 'update', stamina = GetPlayerStamina(PlayerId())})
            Citizen.Wait(800)
        end
    end)
end

stopAction = function()
    -- Capture exit anim before clearing state so loops stop immediately
    local exitAnim = Config.Animations[_pointTable.name] and Config.Animations[_pointTable.name].exit

    -- Stop current animation and free the player instantly
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityCollision(PlayerPedId(), true, true)

    TriggerServerEvent('vms_gym:sv:setTaken', _gymId, _pointId, false)
    SendNUIMessage({action = 'closeHelpKeys'})

    if myProp then DeleteObject(myProp) end
    if myProp2 then DeleteObject(myProp2) end

    removeStrength = true
    _gymId, _pointId, _pointTable = nil, nil, nil
    myProp = nil
    myProp2 = nil

    -- Play exit animation as a non-blocking cosmetic after cleanup
    if exitAnim then
        TaskPlayAnim(PlayerPedId(), exitAnim[1], exitAnim[2], 8.0, -8.0, exitAnim[3], 0, 0.0, 0, 0, 0)
        Citizen.SetTimeout(exitAnim[3], function()
            ClearPedTasks(PlayerPedId())
        end)
    end
end

function addSkill(name, value)
    TriggerServerEvent('vms_gym:sv:addValue', name, value)
end;exports('addSkill', addSkill);

function getSkill(name)
    return myStatistics[name]
end;exports('getSkill', getSkill);

function removeSkill(name, value)
    TriggerServerEvent('vms_gym:sv:removeValue', name, value)
end;exports('removeSkill', removeSkill);

function openStatisticsMenu()
    if waitingForLoadAfterRestart then
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({action = 'openStatisticsMenu', stats = myStatistics})
end;exports('openStatisticsMenu', openStatisticsMenu);

RegisterNetEvent('vms_gym:cl:setTaken', function(gymId, pointId, boolean)
    Config.Gyms[gymId].points[pointId].taken = boolean
end)

RegisterNetEvent('vms_gym:cl:updateStatistic', function(statistics)
    myStatistics = statistics
    SendNUIMessage({action = 'updateStatisticsMenu', stats = myStatistics})
end)

RegisterNetEvent('vms_gym:runConditionBooster')
AddEventHandler('vms_gym:runConditionBooster', function(multiplier, time)
    if conditionBooster == 1.0 then
        if multiplier and tonumber(multiplier) and time and tonumber(time) then
            conditionBooster = multiplier
            Citizen.CreateThread(function()
                Citizen.Wait(time)
                conditionBooster = 1.0
            end)
        end
    end
end)

RegisterNetEvent('vms_gym:runStrengthBooster')
AddEventHandler('vms_gym:runStrengthBooster', function(multiplier, time)
    if strengthBooster == 1.0 then
        if multiplier and tonumber(multiplier) and time and tonumber(time) then
            strengthBooster = multiplier
            Citizen.CreateThread(function()
                Citizen.Wait(time)
                strengthBooster = 1.0
            end)
        end
    end
end)

RegisterNetEvent('vms_gym:notification', function(title, message, time, icon, type, isSkillInfo)
    if isSkillInfo and (disabledNotifySkillInfo == 1) then
        return
    end
    CL.Notification(title, message, time, icon, type)
end)

if Config.StatisticCommand and Config.StatisticCommand ~= '' then
    RegisterCommand(Config.StatisticCommand, function()
        openStatisticsMenu()
    end)
    if Config.StatisticDescription and Config.StatisticKey and Config.StatisticKey ~= '' then
        RegisterKeyMapping(Config.StatisticCommand, Config.StatisticDescription, 'keyboard', Config.StatisticKey)
    end
end