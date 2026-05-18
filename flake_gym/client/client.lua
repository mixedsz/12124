-- ============================================================
--  flake_gym  –  client.lua  (deobfuscated)
-- ============================================================

waitingForLoadAfterRestart = false
currentGymManagement       = nil
stores                     = {}
billCache                  = {}
PlayerData                 = {}
disabledNotifySkillInfo    = false
myStatistics               = nil
conditionBooster           = 1.0
strengthBooster            = 1.0
removeStrength             = true
currentShop                = nil

-- Per-session activity state (module-level locals)
local currentActivityGymId    = nil   -- gymId of the active exercise
local currentActivityPointIdx = nil   -- index inside gym.points
local currentActivityPoint    = nil   -- reference to the config point table
local propHandle1             = nil   -- barbell / prop attached to ped
local propHandle2             = nil   -- optional second prop
local currentStamina          = nil
local gymMembershipsRaw       = {}    -- array returned by server: {{name, time}, ...}
local myMemberships           = {}    -- lookup: membershipName -> expireTime

-- ============================================================
--  Framework initialisation
-- ============================================================
if Config.Core == "ESX" then
    ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
end

-- ============================================================
--  Resource restart handler
-- ============================================================
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if Config.Core == "ESX" then
        while not ESX do Citizen.Wait(200) end
        if ESX.IsPlayerLoaded() then
            PlayerData = ESX.GetPlayerData()
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent("flake_gym:sv:restartPlayer")
        end
    elseif Config.Core == "QB-Core" then
        while not QBCore do Citizen.Wait(200) end
        local pd = QBCore.Functions.GetPlayerData()
        if pd and pd.job then
            PlayerData = pd
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent("flake_gym:sv:restartPlayer")
        end
    end
end)

-- ============================================================
--  Player loaded
-- ============================================================
RegisterNetEvent(Config.PlayerLoaded)
AddEventHandler(Config.PlayerLoaded, function(data)
    if Config.Core == "ESX" then
        PlayerData = data or ESX.GetPlayerData()
    elseif Config.Core == "QB-Core" then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
    waitingForLoadAfterRestart = true
    TriggerServerEvent("flake_gym:fetchData")
end)

-- ============================================================
--  Job updated
-- ============================================================
RegisterNetEvent(Config.JobUpdated)
AddEventHandler(Config.JobUpdated, function(job)
    PlayerData.job = job
end)

-- ============================================================
--  CityHall integrations
-- ============================================================
RegisterNetEvent("vms_cityhall:updatedStatusResume")
AddEventHandler("vms_cityhall:updatedStatusResume", function(jobName, isAllowed)
    if not Config.UseCityHallResumes then return end
    if not currentGymManagement then return end
    local gymJob = Config.Gyms[currentGymManagement].ownerJob
    if gymJob == jobName then
        SendNUIMessage({action = "updateManagementMenu", isResumesAllowed = isAllowed})
    end
end)

RegisterNetEvent("vms_cityhall:updatedBusinessTaxes")
AddEventHandler("vms_cityhall:updatedBusinessTaxes", function(jobName, taxes)
    if not Config.UseCityHallTaxes then return end
    if not currentGymManagement then return end
    local gymJob = Config.Gyms[currentGymManagement].ownerJob
    if gymJob == jobName then
        SendNUIMessage({action = "updateManagementMenu", taxes = taxes})
    end
end)

-- ============================================================
--  Server sends gym store data after player loads
-- ============================================================
RegisterNetEvent("flake_gym:fetchedData")
AddEventHandler("flake_gym:fetchedData", function(serverStores)
    stores = serverStores

    -- Enrich membership/protein prices with city-hall tax data if needed
    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        for _, gymConfig in pairs(Config.Gyms) do
            if gymConfig.memberships then
                for _, mem in pairs(gymConfig.memberships) do
                    local total, tax, pct = exports[Config.VMSCityHallResource]:getTaxAmount(mem.price, "gym.memberships")
                    mem.totalAmount   = total
                    mem.taxAmount     = tax
                    mem.taxPercentage = pct
                end
            end
            if gymConfig.proteins then
                for _, prot in pairs(gymConfig.proteins) do
                    local taxCategory = prot.tax or "gym.proteins"
                    local total, tax, pct = exports[Config.VMSCityHallResource]:getTaxAmount(prot.price, taxCategory)
                    prot.totalAmount   = total
                    prot.taxAmount     = tax
                    prot.taxPercentage = pct
                end
            end
        end
    end

    waitingForLoadAfterRestart = false
end)

-- ============================================================
--  Receipt / bill events from server
-- ============================================================
RegisterNetEvent("flake_gym:cl:getBill")
AddEventHandler("flake_gym:cl:getBill", function(_, membershipData, proteinsData, count)
    SetNuiFocus(true, true)
    if membershipData then
        SendNUIMessage({action = "openReceipt", membershipData = membershipData})
    elseif proteinsData and count then
        SendNUIMessage({action = "openReceipt", proteinsData = proteinsData, count = count})
    end
end)

RegisterNetEvent("flake_gym:cl:getBillFeedback")
AddEventHandler("flake_gym:cl:getBillFeedback", function()
    SetNuiFocus(false, false)
    SendNUIMessage({action = "closeReceipt"})
end)

-- ============================================================
--  Business data update (balance / employees / announcements)
-- ============================================================
RegisterNetEvent("flake_gym:updateBusiness")
AddEventHandler("flake_gym:updateBusiness", function(gymId, newData, changeInfo)
    if not stores[gymId] then return end

    local societyBalance = nil

    if changeInfo then
        if changeInfo.sub then
            -- single-field update
            local sub = changeInfo.sub
            if sub == "balance" then
                if not Config.UseBuildInCompanyBalance then
                    societyBalance = changeInfo.value
                end
            elseif sub == "totalEarned" then
                stores[gymId].data[sub] = changeInfo.value
            else
                stores[gymId][sub] = changeInfo.value
            end
        else
            -- batch update (array of {sub, value})
            for _, item in pairs(changeInfo) do
                if item.sub == "balance" then
                    if not Config.UseBuildInCompanyBalance then
                        societyBalance = item.value
                    end
                elseif item.sub == "data" then
                    stores[gymId].data = item.value
                else
                    stores[gymId].data[item.sub] = item.value
                end
            end
        end
    else
        stores[gymId] = newData
    end

    if currentGymManagement and currentGymManagement == gymId then
        if changeInfo and changeInfo.sub == "employees" then
            CL.GetEmployees(function(employees)
                SendNUIMessage({
                    action        = "updateManagementMenu",
                    storeData     = stores[gymId],
                    employees     = employees,
                    employeesCount = #employees,
                })
            end, Config.Gyms[gymId].ownerJob)
        else
            local msg = {
                action    = "updateManagementMenu",
                storeData = stores[gymId],
            }
            if societyBalance and tonumber(societyBalance) then
                msg.societyBalance = tostring(societyBalance)
            end
            SendNUIMessage(msg)
        end
    end
end)

-- ============================================================
--  Memberships received from server
-- ============================================================
RegisterNetEvent("flake_gym:cl:getMemberships")
AddEventHandler("flake_gym:cl:getMemberships", function(membershipsArray)
    gymMembershipsRaw = membershipsArray
    myMemberships     = {}
    for _, entry in pairs(gymMembershipsRaw) do
        myMemberships[entry.name] = entry.time
    end

    -- If a shop is currently open, refresh the membership display
    if currentShop then
        local shopCfg = Config.Gyms[currentShop]
        if shopCfg and shopCfg.requiredMembership then
            SendNUIMessage({
                action      = "updatePurchaseMenu",
                type        = "membership",
                myMembership = myMemberships[shopCfg.requiredMembership],
            })
        end
    end
end)

-- ============================================================
--  Statistic update from server
-- ============================================================
RegisterNetEvent("flake_gym:cl:updateStatistic")
AddEventHandler("flake_gym:cl:updateStatistic", function(stats)
    myStatistics = stats
    SendNUIMessage({action = "updateStatisticsMenu", stats = myStatistics})
end)

-- ============================================================
--  Mark exercise spot as taken / free  (broadcast from server)
-- ============================================================
RegisterNetEvent("flake_gym:cl:setTaken")
AddEventHandler("flake_gym:cl:setTaken", function(gymId, pointIdx, taken)
    Config.Gyms[gymId].points[pointIdx].taken = taken
end)

-- ============================================================
--  Booster items (protein / run-booster effects)
-- ============================================================
RegisterNetEvent("flake_gym:runConditionBooster")
AddEventHandler("flake_gym:runConditionBooster", function(multiplier, duration)
    if conditionBooster ~= 1.0 then return end
    if not tonumber(multiplier) or not tonumber(duration) then return end
    conditionBooster = multiplier
    Citizen.CreateThread(function()
        Citizen.Wait(duration)
        conditionBooster = 1.0
    end)
end)

RegisterNetEvent("flake_gym:runStrengthBooster")
AddEventHandler("flake_gym:runStrengthBooster", function(multiplier, duration)
    if strengthBooster ~= 1.0 then return end
    if not tonumber(multiplier) or not tonumber(duration) then return end
    strengthBooster = multiplier
    Citizen.CreateThread(function()
        Citizen.Wait(duration)
        strengthBooster = 1.0
    end)
end)

-- ============================================================
--  Generic notification event (from server)
-- ============================================================
RegisterNetEvent("flake_gym:notification")
AddEventHandler("flake_gym:notification", function(title, message, duration, icon, ntype, isSkillNotif)
    if isSkillNotif and disabledNotifySkillInfo == 1 then return end
    CL.Notification(title, message, duration, icon, ntype)
end)

-- ============================================================
--  Helper: load animation dictionary
-- ============================================================
function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- ============================================================
--  Helper: request / load prop model
-- ============================================================
function requestProp(modelHash)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
        RequestModel(modelHash)
    end
end

-- ============================================================
--  Open / close boss management menu
-- ============================================================
function openBossMenu(gymId)
    if waitingForLoadAfterRestart then return end

    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    local function launchMenu(employees)
        currentGymManagement = gymId

        local membershipsList = nil
        if gymConfig.requiredMembership and gymConfig.allowSellMembership and gymConfig.memberships then
            membershipsList = gymConfig.memberships
        end

        local proteinsList = nil
        if gymConfig.allowSellProteins and gymConfig.proteins then
            proteinsList = gymConfig.proteins
        end

        local isResumesAllowed = false
        if Config.UseCityHallResumes then
            isResumesAllowed = exports[Config.VMSCityHallResource]:isResumesAllowed(gymConfig.ownerJob) or false
        end

        local resumes, taxes = nil, nil
        local isTaxesAllowed = Config.UseCityHallTaxes

        local msg = {
            action          = "openManagementMenu",
            storeData       = stores[gymId],
            storeCfg        = gymConfig,
            employees       = employees,
            employeesCount  = #employees,
            isEmployee      = CL.IsEmployee(gymConfig.ownerJob),
            isManager       = CL.IsManager(gymConfig.ownerJob, gymId),
            isBoss          = CL.IsBoss(gymConfig.ownerJob, gymId),
            cityhallGrades  = CL.IsAllowedCityhall(gymConfig.ownerJob, gymId),
            membershipsList = membershipsList,
            proteinsList    = proteinsList,
            isResumesAllowed = isResumesAllowed,
            resumes         = resumes,
            isTaxesAllowed  = isTaxesAllowed,
            taxes           = taxes,
        }
        SendNUIMessage(msg)
    end

    if Config.UseVMSCityHall then
        local fetchCallback = function(resumesData, taxesData)
            CL.GetEmployees(function(employees)
                -- patch resumes / taxes into the message after employees arrive
                currentGymManagement = gymId

                local membershipsList = nil
                if gymConfig.requiredMembership and gymConfig.allowSellMembership and gymConfig.memberships then
                    membershipsList = gymConfig.memberships
                end
                local proteinsList = nil
                if gymConfig.allowSellProteins and gymConfig.proteins then
                    proteinsList = gymConfig.proteins
                end
                local isResumesAllowed = false
                if Config.UseCityHallResumes then
                    isResumesAllowed = exports[Config.VMSCityHallResource]:isResumesAllowed(gymConfig.ownerJob) or false
                end

                SendNUIMessage({
                    action          = "openManagementMenu",
                    storeData       = stores[gymId],
                    storeCfg        = gymConfig,
                    employees       = employees,
                    employeesCount  = #employees,
                    isEmployee      = CL.IsEmployee(gymConfig.ownerJob),
                    isManager       = CL.IsManager(gymConfig.ownerJob, gymId),
                    isBoss          = CL.IsBoss(gymConfig.ownerJob, gymId),
                    cityhallGrades  = CL.IsAllowedCityhall(gymConfig.ownerJob, gymId),
                    membershipsList = membershipsList,
                    proteinsList    = proteinsList,
                    isResumesAllowed = isResumesAllowed,
                    resumes         = resumesData,
                    isTaxesAllowed  = Config.UseCityHallTaxes,
                    taxes           = taxesData,
                })
            end, gymConfig.ownerJob)
        end

        if Config.Core == "ESX" then
            ESX.TriggerServerCallback("vms_cityhall:getBusinessData",
                fetchCallback,
                Config.UseCityHallResumes,
                Config.UseCityHallTaxes)
        else
            QBCore.Functions.TriggerCallback("vms_cityhall:getBusinessData",
                fetchCallback,
                Config.UseCityHallResumes,
                Config.UseCityHallTaxes)
        end
    else
        CL.GetEmployees(launchMenu, gymConfig.ownerJob)
    end

    SetNuiFocus(true, true)

    if not Config.UseBuildInCompanyBalance then
        Citizen.Wait(300)
        TriggerServerEvent(Config.ESXSocietyEvents.check, gymConfig.ownerJob)
    end
end

function closeManagementMenu()
    SendNUIMessage({action = "closeManagementMenu"})
    currentGymManagement = nil
    SetNuiFocus(false, false)
end

-- ============================================================
--  Open purchase menu (shop – memberships / proteins)
-- ============================================================
function openPurchaseMenu(gymId)
    if waitingForLoadAfterRestart then return end

    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    local msg = {action = "openPurchaseMenu"}

    if gymConfig.requiredMembership and gymConfig.allowBuyMembership then
        msg.useMemberships   = true
        msg.membershipsList  = gymConfig.memberships
        msg.myMembership     = myMemberships[gymConfig.requiredMembership]
    end

    if gymConfig.allowBuyProteins then
        msg.useProteins  = true
        msg.proteinsList = gymConfig.proteins
    end

    if not gymConfig.allowBuyMembership and not gymConfig.allowBuyProteins then return end

    currentShop = gymId
    Citizen.Wait(100)
    SetNuiFocus(true, true)
    SendNUIMessage(msg)
end

-- ============================================================
--  Buy protein (triggered from NUI callback)
-- ============================================================
function buyProtein(itemName)
    if not itemName or not currentShop then return end
    local gymConfig = Config.Gyms[currentShop]
    if not gymConfig then return end
    if not gymConfig.proteins or not gymConfig.allowBuyProteins then return end
    TriggerServerEvent("flake_gym:sv:buyProtein", currentShop, itemName)
end

-- ============================================================
--  Buy membership (triggered from NUI callback)
-- ============================================================
function buyMembership(days, hours)
    if not days and not hours then return end
    if not currentShop then return end

    local gymConfig = Config.Gyms[currentShop]
    if not gymConfig then return end
    if not gymConfig.requiredMembership then return end
    if not gymConfig.allowBuyMembership then return end

    -- Find the matching membership tier
    local selectedMembership = nil
    for _, mem in pairs(gymConfig.memberships) do
        if mem.days == days and mem.hours == hours then
            selectedMembership = mem
            break
        end
    end

    TriggerServerEvent("flake_gym:sv:acceptMembership",
        currentShop,
        gymConfig.requiredMembership,
        selectedMembership)
end

-- ============================================================
--  Skill functions (exported)
-- ============================================================
function addSkill(skillName, value)
    TriggerServerEvent("flake_gym:sv:addValue", skillName, value)
end
exports("addSkill", addSkill)

function getSkillValue(skillName)
    if myStatistics == nil then return 0.0 end
    return myStatistics[skillName] or 0.0
end
getSkill = getSkillValue
exports("getSkill", getSkill)

function removeSkill(skillName, value)
    TriggerServerEvent("flake_gym:sv:removeValue", skillName, value)
end
exports("removeSkill", removeSkill)

-- ============================================================
--  Open statistics menu (exported)
-- ============================================================
function openStatisticsMenu()
    if waitingForLoadAfterRestart then return end
    SetNuiFocus(true, true)
    SendNUIMessage({action = "openStatisticsMenu", stats = myStatistics})
end
exports("openStatisticsMenu", openStatisticsMenu)

-- ============================================================
--  /mystats command
-- ============================================================
if Config.StatisticCommand and Config.StatisticCommand ~= "" then
    RegisterCommand(Config.StatisticCommand, function()
        openStatisticsMenu()
    end)

    if Config.StatisticKey and Config.StatisticKey ~= "" then
        RegisterKeyMapping(
            Config.StatisticCommand,
            Config.StatisticDescription,
            "keyboard",
            Config.StatisticKey)
    end
end

-- ============================================================
--  startAction  –  teleport player to exercise position and
--                  begin the animation / interaction loop
-- ============================================================
function startAction(gymId, pointIdx, pointData)
    if waitingForLoadAfterRestart then return end

    -- Membership check
    if Config.EnableMemberships then
        local gymCfg = Config.Gyms[gymId]
        if gymCfg and gymCfg.requiredMembership then
            local hasMembership = myMemberships[gymCfg.requiredMembership]
            if not hasMembership then
                -- Employees bypass if AutoMembershipForEmployees is on
                local isEmployee = Config.AutoMembershipForEmployees
                    and PlayerData.job
                    and PlayerData.job.name == gymCfg.ownerJob
                if not isEmployee then
                    CL.Notification(
                        TRANSLATE("notify.title.gym"),
                        TRANSLATE("no_membership"),
                        3500,
                        "fa-solid fa-dumbbell",
                        "error")
                    return
                end
            end
        end
    end

    -- Spot must be free
    if pointData.taken then
        CL.Notification(
            TRANSLATE("notify.title.gym"),
            TRANSLATE("place_taken"),
            3500,
            "fa-solid fa-dumbbell",
            "error")
        return
    end

    -- Store activity state
    currentActivityGymId    = gymId
    currentActivityPointIdx = pointIdx
    currentActivityPoint    = pointData
    removeStrength          = false

    -- Face the right direction
    if pointData.activityCoord and pointData.activityCoord.w then
        SetEntityHeading(PlayerPedId(), pointData.activityCoord.w)
    end

    -- Teleport player to the activity spot
    local ac = pointData.activityCoord
    if ac and ac.x and ac.y and ac.z then
        SetEntityCoords(PlayerPedId(), vec(ac.x, ac.y, ac.z), false, false, false, false)
    end

    -- Freeze & remove collision so animations don't slide
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCollision(PlayerPedId(), false, false)

    -- Pre-load all animation dicts for this activity type
    local animSet = Config.Animations[pointData.name]
    for _, animData in pairs(animSet) do
        loadAnimDict(animData[1])
    end

    -- Mark spot as taken on the server (broadcasts to all clients)
    TriggerServerEvent("flake_gym:sv:setTaken", gymId, pointIdx, true)

    -- Show HUD with stamina
    SendNUIMessage({
        action  = "openHelpKeys",
        stamina = GetPlayerStamina(PlayerId()),
    })

    -- Play enter animation if it exists
    if animSet.enter then
        TaskPlayAnim(PlayerPedId(),
            animSet.enter[1], animSet.enter[2],
            8.0, -8.0, animSet.enter[3],
            0, 0.0, 0, 0, 0)
        Citizen.Wait(animSet.enter[3])
    end

    -- Spawn the activity thread (input loop + idle anim + props)
    Citizen.CreateThread(function()
        -- Play idle animation
        TaskPlayAnim(PlayerPedId(),
            animSet.idle[1], animSet.idle[2],
            8.0, -8.0, animSet.idle[3],
            1, 0.0, 0, 0, 0)

        -- Attach prop1
        if pointData.prop then
            requestProp(GetHashKey(pointData.prop.name))
            local pedCoords = GetEntityCoords(PlayerPedId())
            local obj = CreateObject(GetHashKey(pointData.prop.name), pedCoords, true, true, true)
            propHandle1 = obj
            local boneIdx = GetPedBoneIndex(PlayerPedId(), pointData.prop.attachBone)
            local p = pointData.prop.placement
            AttachEntityToEntity(obj, PlayerPedId(), boneIdx,
                p[1]+0.0, p[2]+0.0, p[3]+0.0,
                p[4]+0.0, p[5]+0.0, p[6]+0.0,
                true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(obj)
        end

        -- Attach prop2
        if pointData.prop2 then
            requestProp(GetHashKey(pointData.prop2.name))
            local pedCoords = GetEntityCoords(PlayerPedId())
            local obj2 = CreateObject(GetHashKey(pointData.prop2.name), pedCoords, true, true, true)
            propHandle2 = obj2
            local boneIdx2 = GetPedBoneIndex(PlayerPedId(), pointData.prop2.attachBone)
            local p2 = pointData.prop2.placement
            AttachEntityToEntity(obj2, PlayerPedId(), boneIdx2,
                p2[1]+0.0, p2[2]+0.0, p2[3]+0.0,
                p2[4]+0.0, p2[5]+0.0, p2[6]+0.0,
                true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(obj2)
        end

        -- Main exercise input loop
        while currentActivityPoint do
            -- SPACE = train
            if IsControlJustPressed(0, Config.Keys.train) then
                currentStamina = GetPlayerStamina(PlayerId())

                -- Calculate stamina cost based on condition skill
                local condSkill    = getSkill("condition")
                local staminaCost
                if condSkill >= 10.0 then
                    staminaCost = (pointData.removeStamina * 100) / condSkill
                else
                    staminaCost = pointData.removeStamina
                end

                if currentStamina > staminaCost then
                    -- Skill check
                    local failed = false
                    if Config.UseSkillbar then
                        Config.Skillbar(pointData.name, function(success)
                            failed = not success
                        end)
                    end

                    if not failed then
                        -- Progressbar (optional, non-blocking visual)
                        if Config.UseProgressbar then
                            Config.Progressbar(pointData.name, animSet.training[3])
                        end

                        -- Training animation
                        TaskPlayAnim(PlayerPedId(),
                            animSet.training[1], animSet.training[2],
                            8.0, -8.0, animSet.training[3],
                            0, 0.0, 0, 0, 0)
                        Citizen.Wait(animSet.training[3])

                        -- Return to idle
                        TaskPlayAnim(PlayerPedId(),
                            animSet.idle[1], animSet.idle[2],
                            8.0, -8.0, animSet.idle[3],
                            1, 0.0, 0, 0, 0)

                        -- Deduct stamina
                        SetPlayerStamina(PlayerId(), currentStamina - staminaCost)

                        -- Add skill
                        if pointData.addSkill and pointData.addSkill.skill and pointData.addSkill.value then
                            local skillName = pointData.addSkill.skill
                            local boost     = skillName == "strenght" and strengthBooster or conditionBooster
                            local gainedVal

                            if type(pointData.addSkill.value) == "number" then
                                gainedVal = (pointData.addSkill.value / 10) * boost
                            else
                                gainedVal = (math.random(pointData.addSkill.value[1], pointData.addSkill.value[2]) / 10) * boost
                            end

                            addSkill(skillName, gainedVal)
                        end
                    end
                else
                    -- Out of breath
                    CL.Notification(
                        TRANSLATE("notify.title.gym"),
                        TRANSLATE("out_of_breath"),
                        3850,
                        "fa-solid fa-dumbbell",
                        "info")
                    Citizen.Wait(1000)
                end
            end

            -- X = stop
            if IsControlJustPressed(0, Config.Keys.stop) then
                stopAction()
            end

            Citizen.Wait(1)
        end
    end)

    -- Stamina HUD update thread
    Citizen.CreateThread(function()
        while currentActivityPoint do
            SendNUIMessage({action = "update", stamina = GetPlayerStamina(PlayerId())})
            Citizen.Wait(800)
        end
    end)
end
startAction = startAction  -- expose globally

-- ============================================================
--  stopAction  –  end current exercise
-- ============================================================
function stopAction()
    local ped          = PlayerPedId()
    local activityName = currentActivityPoint and currentActivityPoint.name
    local exitAnim     = activityName
        and Config.Animations[activityName]
        and Config.Animations[activityName].exit

    if exitAnim then
        TaskPlayAnim(ped, exitAnim[1], exitAnim[2],
            8.0, -8.0, exitAnim[3], 0, 0.0, 0, 0, 0)
        Citizen.Wait(exitAnim[3])
    end

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    TriggerServerEvent("flake_gym:sv:setTaken", currentActivityGymId, currentActivityPointIdx, false)

    SendNUIMessage({action = "closeHelpKeys"})

    if propHandle1 then DeleteObject(propHandle1) end
    if propHandle2 then DeleteObject(propHandle2) end

    removeStrength          = true
    currentActivityPoint    = nil
    currentActivityPointIdx = nil
    currentActivityGymId    = nil
    propHandle1             = nil
    propHandle2             = nil
end

-- ============================================================
--  Passive stat gain / loss threads  (running, driving, etc.)
-- ============================================================
local speedUnit    = Config.UnitOfSpeed == 'kmh' and 3.6 or 2.236936
local removeCondition = true

Citizen.CreateThread(function()
    while Config.StatisticsMenu["shooting"] do
        local waiting = 2000
        Citizen.Wait(waiting)
        local ped    = PlayerPedId()
        local status, weapon = GetCurrentPedWeapon(ped, true)
        if status == 1 and not ({
            [GetHashKey("weapon_fireextinguisher")] = true,
            [GetHashKey("weapon_petrolcan")]        = true,
            [GetHashKey("weapon_hazardcan")]        = true,
            [GetHashKey("weapon_fertilizercan")]    = true,
            [GetHashKey("weapon_grenade")]          = true,
            [GetHashKey("weapon_bzgas")]            = true,
            [GetHashKey("weapon_molotov")]          = true,
            [GetHashKey("weapon_stickybomb")]       = true,
            [GetHashKey("weapon_proxmine")]         = true,
            [GetHashKey("weapon_snowball")]         = true,
            [GetHashKey("weapon_pipebomb")]         = true,
            [GetHashKey("weapon_ball")]             = true,
            [GetHashKey("weapon_smokegrenade")]     = true,
            [GetHashKey("weapon_flare")]            = true,
            [GetHashKey("weapon_rpg")]              = true,
            [GetHashKey("weapon_grenadelauncher")]  = true,
            [GetHashKey("weapon_minigun")]          = true,
            [GetHashKey("weapon_firework")]         = true,
        })[weapon] then
            Citizen.Wait(10)
            if IsPedShooting(ped) and math.random(3) >= 2 then
                local v = Config.AddStatsValues['Shooting']
                addSkill("shooting",
                    type(v) == "number" and v/10.0
                    or math.random(v[1], v[2])/10.0)
                Citizen.Wait(math.random(6500, 10000))
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeAddStats)
        local ped       = PlayerPedId()
        local vehicle   = GetVehiclePedIsUsing(ped)
        removeCondition = true

        if IsPedRunning(ped) and Config.StatisticsMenu['condition'] then
            local v = Config.AddStatsValues['Running']
            addSkill("condition",
                (type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0) * conditionBooster)
            removeCondition = false

        elseif IsPedSwimmingUnderWater(ped) and Config.StatisticsMenu['condition'] then
            local v = Config.AddStatsValues['Swimming']
            addSkill("condition",
                (type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0) * conditionBooster)
            removeCondition = false

        elseif DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped then
            local speed        = GetEntitySpeed(vehicle) * speedUnit
            local vehicleClass = GetVehicleClass(vehicle)

            if vehicleClass == 13 and speed >= Config.AddStatsValues['Cycling'].minimumSpeed
                and Config.StatisticsMenu['condition'] then
                local v = Config.AddStatsValues['Cycling'].value
                addSkill("condition",
                    (type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0) * conditionBooster)
                removeCondition = false

            elseif (vehicleClass == 15 or vehicleClass == 16)
                and speed >= Config.AddStatsValues['Flying'].minimumSpeed
                and Config.StatisticsMenu['flying'] then
                local v = Config.AddStatsValues['Flying'].value
                addSkill("flying",
                    type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0)

            elseif vehicleClass ~= 15 and vehicleClass ~= 16 and vehicleClass ~= 14
                and speed >= Config.AddStatsValues['Driving'].minimumSpeed
                and Config.StatisticsMenu['driving'] then
                local v = Config.AddStatsValues['Driving'].value
                addSkill("driving",
                    type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0)
            end
        end

        -- Apply strength modifier
        if myStatistics and myStatistics['strenght'] and Config.EnableStrenghtModifier then
            local s = myStatistics['strenght']
            if     s >= 70.0 then SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 2.0)
            elseif s >= 50.0 then SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.5)
            elseif s >= 20.0 then SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.25)
            else                   SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.0)
            end
        end

        -- Apply condition modifier
        if myStatistics and myStatistics['condition'] then
            local c = myStatistics['condition']
            if     c >= 70.0 then
                if Config.EnableRunSpeedModifier  then SetRunSprintMultiplierForPlayer(PlayerId(), 1.49) end
                if Config.EnableStaminaModifier   then StatSetInt(GetHashKey('MP0_STAMINA'), 60, true) end
            elseif c >= 50.0 then
                if Config.EnableRunSpeedModifier  then SetRunSprintMultiplierForPlayer(PlayerId(), 1.35) end
                if Config.EnableStaminaModifier   then StatSetInt(GetHashKey('MP0_STAMINA'), 30, true) end
            elseif c >= 20.0 then
                if Config.EnableRunSpeedModifier  then SetRunSprintMultiplierForPlayer(PlayerId(), 1.1) end
                if Config.EnableStaminaModifier   then StatSetInt(GetHashKey('MP0_STAMINA'), 15, true) end
            else
                if Config.EnableRunSpeedModifier  then SetRunSprintMultiplierForPlayer(PlayerId(), 1.0) end
                if Config.EnableStaminaModifier   then StatSetInt(GetHashKey('MP0_STAMINA'), 0, true) end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeRemoveStats)
        if removeCondition and Config.StatisticsMenu['condition'] and type(removeSkill) == 'function' then
            local v = Config.RemoveStatsValues['RemoveCondition']
            removeSkill("condition",
                type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0)
        end
        Citizen.Wait(3000)
        if removeStrength and Config.StatisticsMenu['strenght'] and type(removeSkill) == 'function' then
            local v = Config.RemoveStatsValues['RemoveStrength']
            removeSkill("strenght",
                type(v) == "number" and v/10.0 or math.random(v[1], v[2])/10.0)
        end
    end
end)

-- Driving skill effects
Citizen.CreateThread(function()
    while Config.EnableSkillDrivingEffects and Config.StatisticsMenu["driving"] do
        local veh      = GetVehiclePedIsIn(PlayerPedId(), false)
        local isDriver = GetPedInVehicleSeat(veh, -1) == PlayerPedId()

        if veh and isDriver and GetEntitySpeed(veh) * speedUnit > Config.SkillDrivingEffectMinimumSpeed then
            local ds = exports['flake_gym']:getSkill('driving')
            if ds < 20.0 then
                SetVehicleSteerBias(veh, math.random(-1, 1) + 0.0)
                SetVehicleReduceGrip(veh, true)
                Citizen.Wait(math.random(200, 450))
                SetVehicleReduceGrip(veh, false)
                Citizen.Wait(math.random(1750, 3000))
            elseif ds < 50.0 then
                local bias = (math.random(-7, 7) + 0.0) / 10
                SetVehicleSteerBias(veh, bias)
                if math.abs(GetVehicleSteeringAngle(veh)) > 30.0 then
                    SetVehicleReduceGrip(veh, true)
                    Citizen.Wait(math.random(200, 450))
                    SetVehicleReduceGrip(veh, false)
                end
                Citizen.Wait(math.random(1750, 4000))
            elseif ds < 70.0 then
                SetVehicleSteerBias(veh, (math.random(-5, 5) + 0.0) / 10)
                Citizen.Wait(math.random(2000, 6000))
            elseif ds < 80.0 then
                SetVehicleSteerBias(veh, (math.random(-2, 2) + 0.0) / 10)
                Citizen.Wait(math.random(5000, 8000))
            end
        end

        Citizen.Wait(500)
    end
end)

-- ============================================================
--  Initialise blips, targets, and proximity loop
-- ============================================================
Citizen.CreateThread(function()
    Citizen.Wait(250)

    -- Add map blips
    for _, gymConfig in pairs(Config.Gyms) do
        if gymConfig.blipCoords and gymConfig.blipEnabled then
            local blip = AddBlipForCoord(gymConfig.blipCoords)
            SetBlipSprite(blip, Config.Blip.Sprite)
            SetBlipDisplay(blip, Config.Blip.Display)
            SetBlipScale(blip, Config.Blip.Scale)
            SetBlipColour(blip, Config.Blip.Color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(gymConfig.blipName)
            EndTextCommandSetBlipName(blip)
            gymConfig._createdBlip = blip
        end
    end

    -- Load ox_lib if needed
    local useOxLib = (Config.UseTarget and Config.TargetResource == "ox_target") or Config.Menu == "ox_lib"
    if useOxLib then
        local code = LoadResourceFile("ox_lib", "init.lua")
        assert(load(code, "@@ox_lib/init.lua"))()
    end

    -- Register targets for each gym
    if Config.UseTarget then
        for gymId, gymConfig in pairs(Config.Gyms) do
            -- Boss menu target
            if gymConfig.business and gymConfig.ownerJob and gymConfig.bossMenu then
                CL.Target({
                    name   = "bossmenu",
                    coords = gymConfig.bossMenu.targetCoords,
                    size   = gymConfig.bossMenu.targetSize,
                    job    = gymConfig.ownerJob,
                    label  = TRANSLATE("target.boss_menu"),
                    icon   = "fa-solid fa-dollar-sign",
                }, function()
                    openBossMenu(gymId)
                end)
            end

            -- Shop menu target
            if gymConfig.shopMenu then
                local hasShop = (gymConfig.allowBuyMembership and gymConfig.requiredMembership)
                    or gymConfig.allowBuyProteins
                if hasShop then
                    CL.Target({
                        name   = "shopmenu",
                        coords = gymConfig.shopMenu.targetCoords,
                        size   = gymConfig.shopMenu.targetSize,
                        label  = TRANSLATE("target.shop_menu"),
                        icon   = "fa-solid fa-dollar-sign",
                    }, function()
                        openPurchaseMenu(gymId)
                    end)
                end
            end

            -- Exercise point targets
            for pointIdx, point in pairs(gymConfig.points) do
                CL.Target({
                    name   = point.name,
                    coords = point.activityCoord,
                    size   = point.targetSize,
                    label  = TRANSLATE("target." .. point.name),
                    icon   = "fa-solid fa-dumbbell",
                }, function()
                    startAction(gymId, pointIdx, point)
                end)
            end
        end
    end
end)

-- ============================================================
--  Proximity loop (no-target mode: markers, 3D text, key prompts)
-- ============================================================
Citizen.CreateThread(function()
    if Config.UseTarget then return end  -- skip if using target system

    local textUIShowing = false
    local textUIText    = nil

    while true do
        local sleeping  = true
        local showText  = nil
        local myPed     = PlayerPedId()
        local myCoords  = GetEntityCoords(myPed)

        for gymId, gymConfig in pairs(Config.Gyms) do
            local distToGym = #(myCoords - gymConfig.blipCoords)

            if distToGym < 45.0 then
                sleeping = false

                -- Exercise points
                for pointIdx, point in pairs(gymConfig.points) do
                    if not point.taken then
                        local distToPoint = #(myCoords - vec(point.position.x, point.position.y, point.position.z))

                        if distToPoint < Config.DistanceView then
                            if Config.UseMarkers then
                                local m = Config.Markers.FreeSeat
                                DrawMarker(m.id,
                                    vec(point.position.x, point.position.y, point.position.z),
                                    0, 0, 0,
                                    m.rotation[1], m.rotation[2], m.rotation[3],
                                    m.size,
                                    m.color[1], m.color[2], m.color[3], m.color[4],
                                    m.bobUpAndDown, false, false, m.rotate,
                                    false, false, false)
                            end

                            if Config.Use3DText then
                                DrawText3D(point.position.x, point.position.y, point.position.z,
                                    TRANSLATE("3dtext." .. point.name))
                            end

                            if distToPoint < 1.25 then
                                showText = TRANSLATE("textui." .. point.name)

                                if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                    ESX.ShowHelpNotification(TRANSLATE("help." .. point.name))
                                end

                                if IsControlJustPressed(0, Config.Keys.enter) then
                                    startAction(gymId, pointIdx, point)
                                    showText = nil
                                end
                            end
                        end
                    end
                end

                -- Boss menu
                if gymConfig.business and gymConfig.bossMenu and gymConfig.bossMenu.coords then
                    local distToBoss = #(myCoords - gymConfig.bossMenu.coords.xyz)

                    if distToBoss < Config.DistanceView and PlayerData and PlayerData.job then
                        if CL.IsEmployee(gymConfig.ownerJob) then
                            sleeping = false
                            if Config.UseMarkers then
                                local m = Config.Markers.BossMenu
                                DrawMarker(m.id, gymConfig.bossMenu.coords.xyz,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    m.size,
                                    m.color[1], m.color[2], m.color[3], m.color[4],
                                    m.bobUpAndDown, false, false, m.rotate,
                                    false, false, false)
                            end

                            if Config.Use3DText then
                                DrawText3D(gymConfig.bossMenu.coords.x, gymConfig.bossMenu.coords.y,
                                    gymConfig.bossMenu.coords.z, TRANSLATE("3dtext.boss_menu"))
                            end

                            if distToBoss < Config.DistanceAccess then
                                showText = TRANSLATE("textui.boss_menu")

                                if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                    ESX.ShowHelpNotification(TRANSLATE("help.boss_menu"))
                                end

                                if IsControlJustPressed(0, 38) then
                                    openBossMenu(gymId)
                                    showText = nil
                                end
                            end
                        end
                    end
                end

                -- Shop menu
                if gymConfig.shopMenu and gymConfig.shopMenu.coords then
                    local allowShop = gymConfig.allowBuyMembership or gymConfig.allowBuyProteins
                    if allowShop then
                        local distToShop = #(myCoords - gymConfig.shopMenu.coords.xyz)

                        if distToShop < Config.DistanceView then
                            sleeping = false
                            if Config.UseMarkers then
                                local m = Config.Markers.ShopMenu
                                DrawMarker(m.id, gymConfig.shopMenu.coords.xyz,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    m.size,
                                    m.color[1], m.color[2], m.color[3], m.color[4],
                                    m.bobUpAndDown, false, false, m.rotate,
                                    false, false, false)
                            end

                            if distToShop < Config.DistanceAccess then
                                showText = TRANSLATE("textui.shop_menu")

                                if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                    ESX.ShowHelpNotification(TRANSLATE("help.shop_menu"))
                                end

                                if IsControlJustPressed(0, 38) then
                                    openPurchaseMenu(gymId)
                                    showText = nil
                                end
                            end
                        end
                    end
                end
            end
        end

        -- TextUI open/close
        if CL.TextUI.Enabled then
            if showText and not textUIShowing then
                textUIShowing = true
                textUIText    = showText
                CL.TextUI.Open(showText)
            elseif not showText and textUIShowing then
                textUIShowing = false
                textUIText    = nil
                CL.TextUI.Close()
            end
        end

        Citizen.Wait(sleeping and 2000 or 1)
    end
end)
