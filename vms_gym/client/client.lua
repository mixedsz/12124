-- ============================================================
--  vms_gym  |  client.lua  (deobfuscated)
-- ============================================================

-- ── Globals ──────────────────────────────────────────────────
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

-- Active training state
local currentGymId    = nil  -- gymId currently training at
local currentPtIndex  = nil  -- index into gym.points
local currentPoint    = nil  -- the point config table
local currentProp1    = nil  -- attached prop entity 1
local currentProp2    = nil  -- attached prop entity 2
local currentStamina  = nil  -- stamina snapshot when training started

-- Membership cache
local myMembershipRaw = {}  -- raw array from server
local membershipMap   = {}  -- name → expiry timestamp

-- ── Framework bootstrap ───────────────────────────────────────
if Config.Core == "ESX" then
    ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
end

-- ── onResourceStart ───────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Core == "ESX" then
        while not ESX do Citizen.Wait(200) end
        if ESX.IsPlayerLoaded() then
            PlayerData = ESX.GetPlayerData()
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent("vms_gym:sv:restartPlayer")
        end
    elseif Config.Core == "QB-Core" then
        while not QBCore do Citizen.Wait(200) end
        local pd = QBCore.Functions.GetPlayerData()
        if pd and pd.job then
            PlayerData = pd
            waitingForLoadAfterRestart = true
            Citizen.Wait(2500)
            TriggerServerEvent("vms_gym:sv:restartPlayer")
        end
    end
end)

-- ── Player loaded ─────────────────────────────────────────────
RegisterNetEvent(Config.PlayerLoaded)
AddEventHandler(Config.PlayerLoaded, function(data)
    if Config.Core == "ESX" then
        PlayerData = data
    elseif Config.Core == "QB-Core" then
        PlayerData = QBCore.Functions.GetPlayerData()
    end
    waitingForLoadAfterRestart = false
    TriggerServerEvent("vms_gym:fetchData")
end)

-- ── Job update ────────────────────────────────────────────────
RegisterNetEvent(Config.JobUpdated)
AddEventHandler(Config.JobUpdated, function(job)
    PlayerData.job = job
end)

-- ── CityHall resume status update ────────────────────────────
RegisterNetEvent("vms_cityhall:updatedStatusResume")
AddEventHandler("vms_cityhall:updatedStatusResume", function(jobName, allowed)
    if not Config.UseCityHallResumes then return end
    if not currentGymManagement then return end
    local gymCfg = Config.Gyms[currentGymManagement]
    if gymCfg and gymCfg.ownerJob == jobName then
        SendNUIMessage({ action = "updateManagementMenu", isResumesAllowed = allowed })
    end
end)

-- ── CityHall taxes update ─────────────────────────────────────
RegisterNetEvent("vms_cityhall:updatedBusinessTaxes")
AddEventHandler("vms_cityhall:updatedBusinessTaxes", function(jobName, taxes)
    if not Config.UseCityHallTaxes then return end
    if not currentGymManagement then return end
    local gymCfg = Config.Gyms[currentGymManagement]
    if gymCfg and gymCfg.ownerJob == jobName then
        SendNUIMessage({ action = "updateManagementMenu", taxes = taxes })
    end
end)

-- ── vms_gym:fetchedData ───────────────────────────────────────
RegisterNetEvent("vms_gym:fetchedData")
AddEventHandler("vms_gym:fetchedData", function(data)
    stores = data

    -- Apply CityHall tax calculations if enabled
    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        for gymId, gymCfg in pairs(Config.Gyms) do
            if gymCfg.memberships and next(gymCfg.memberships) then
                for _, membership in pairs(gymCfg.memberships) do
                    local total, tax, pct = exports[Config.VMSCityHallResource]:getTaxAmount(
                        membership.price, "gym.memberships"
                    )
                    membership.totalAmount   = total
                    membership.taxAmount     = tax
                    membership.taxPercentage = pct
                end
            end
            if gymCfg.proteins and next(gymCfg.proteins) then
                for _, protein in pairs(gymCfg.proteins) do
                    local taxKey = protein.tax or "gym.proteins"
                    local total, tax, pct = exports[Config.VMSCityHallResource]:getTaxAmount(
                        protein.price, taxKey
                    )
                    protein.totalAmount   = total
                    protein.taxAmount     = tax
                    protein.taxPercentage = pct
                end
            end
        end
    end

    waitingForLoadAfterRestart = false
end)

-- ── vms_gym:cl:getBill ────────────────────────────────────────
RegisterNetEvent("vms_gym:cl:getBill")
AddEventHandler("vms_gym:cl:getBill", function(_, membershipData, proteinsData, count)
    SetNuiFocus(true, true)
    if membershipData then
        SendNUIMessage({ action = "openReceipt", membershipData = membershipData })
    elseif proteinsData and count then
        SendNUIMessage({ action = "openReceipt", proteinsData = proteinsData, count = count })
    end
end)

-- ── vms_gym:cl:getBillFeedback ───────────────────────────────
RegisterNetEvent("vms_gym:cl:getBillFeedback")
AddEventHandler("vms_gym:cl:getBillFeedback", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeReceipt" })
    billCache = {}
end)

-- ── vms_gym:updateBusiness ────────────────────────────────────
RegisterNetEvent("vms_gym:updateBusiness")
AddEventHandler("vms_gym:updateBusiness", function(gymId, fullData, partialUpdate)
    if not stores[gymId] then return end

    local societyBalance = nil

    if partialUpdate then
        local sub = partialUpdate.sub
        if sub then
            if sub == "balance" then
                if not Config.UseBuildInCompanyBalance then
                    societyBalance = partialUpdate.value
                end
            elseif sub == "totalEarned" then
                if stores[gymId] and stores[gymId].data then
                    stores[gymId].data.totalEarned = partialUpdate.value
                end
            else
                if stores[gymId] and stores[gymId].data then
                    stores[gymId].data[sub] = partialUpdate.value
                end
            end
        else
            -- Array of updates
            for _, upd in pairs(partialUpdate) do
                if upd.sub == "balance" then
                    if not Config.UseBuildInCompanyBalance then
                        societyBalance = upd.value
                    end
                elseif upd.sub == "data" then
                    if stores[gymId] and stores[gymId].data then
                        stores[gymId].data[upd.sub] = upd.value
                    end
                else
                    if stores[gymId] and stores[gymId].data then
                        stores[gymId].data[upd.sub] = upd.value
                    end
                end
            end
        end
    else
        stores[gymId] = fullData
    end

    -- Update management menu if open for this gym
    if currentGymManagement == gymId then
        local sub = partialUpdate and partialUpdate.sub
        if sub == "employees" then
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
            if societyBalance then
                msg.societyBalance = tostring(societyBalance)
            end
            SendNUIMessage(msg)
        end
    end
end)

-- ── vms_gym:cl:getMemberships ─────────────────────────────────
RegisterNetEvent("vms_gym:cl:getMemberships")
AddEventHandler("vms_gym:cl:getMemberships", function(memberships)
    myMembershipRaw = memberships
    membershipMap   = {}
    for _, entry in pairs(memberships) do
        membershipMap[entry.name] = entry.time
    end

    -- Update purchase menu if shop is open
    if currentShop then
        local gymCfg = Config.Gyms[currentShop]
        if gymCfg and gymCfg.requiredMembership then
            SendNUIMessage({
                action       = "updatePurchaseMenu",
                type         = "membership",
                myMembership = membershipMap[gymCfg.requiredMembership],
            })
        end
    end
end)

-- ── vms_gym:cl:setTaken ───────────────────────────────────────
RegisterNetEvent("vms_gym:cl:setTaken")
AddEventHandler("vms_gym:cl:setTaken", function(gymId, pointIndex, taken)
    local gym = Config.Gyms[gymId]
    if not gym then return end
    local pt = gym.points[pointIndex]
    if not pt then return end
    pt.taken = taken
end)

-- ── vms_gym:cl:updateStatistic ───────────────────────────────
RegisterNetEvent("vms_gym:cl:updateStatistic")
AddEventHandler("vms_gym:cl:updateStatistic", function(stats)
    myStatistics = stats
    SendNUIMessage({ action = "updateStatisticsMenu", stats = myStatistics })
end)

-- ── vms_gym:runConditionBooster ───────────────────────────────
RegisterNetEvent("vms_gym:runConditionBooster")
AddEventHandler("vms_gym:runConditionBooster", function(multiplier, duration)
    if conditionBooster ~= 1.0 then return end
    if not multiplier or not duration then return end
    multiplier = tonumber(multiplier)
    duration   = tonumber(duration)
    if not multiplier or not duration then return end
    conditionBooster = multiplier
    Citizen.CreateThread(function()
        Citizen.Wait(duration)
        conditionBooster = 1.0
    end)
end)

-- ── vms_gym:runStrengthBooster ────────────────────────────────
RegisterNetEvent("vms_gym:runStrengthBooster")
AddEventHandler("vms_gym:runStrengthBooster", function(multiplier, duration)
    if strengthBooster ~= 1.0 then return end
    if not multiplier or not duration then return end
    multiplier = tonumber(multiplier)
    duration   = tonumber(duration)
    if not multiplier or not duration then return end
    strengthBooster = multiplier
    Citizen.CreateThread(function()
        Citizen.Wait(duration)
        strengthBooster = 1.0
    end)
end)

-- ── vms_gym:notification ─────────────────────────────────────
RegisterNetEvent("vms_gym:notification")
AddEventHandler("vms_gym:notification", function(title, message, time, icon, notifType, isSkillInfo)
    if isSkillInfo and disabledNotifySkillInfo == 1 then return end
    CL.Notification(title, message, time, icon, notifType)
end)

-- ── Statistics command ────────────────────────────────────────
if Config.StatisticCommand and Config.StatisticCommand ~= "" then
    RegisterCommand(Config.StatisticCommand, function()
        openStatisticsMenu()
    end)
    if Config.StatisticDescription and Config.StatisticKey and Config.StatisticKey ~= "" then
        RegisterKeyMapping(Config.StatisticCommand, Config.StatisticDescription, "keyboard", Config.StatisticKey)
    end
end

-- ── Helper: load anim dict ────────────────────────────────────
function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- ── Helper: request prop model ───────────────────────────────
function requestProp(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(100)
        RequestModel(model)
    end
end

-- ── Exported skill accessors ──────────────────────────────────
function addSkill(skillName, value)
    TriggerServerEvent("vms_gym:sv:addValue", skillName, value)
end
exports("addSkill", addSkill)

function getSkill(skillName)
    return myStatistics and myStatistics[skillName] or 0.0
end
exports("getSkill", getSkill)

function removeSkill(skillName, value)
    TriggerServerEvent("vms_gym:sv:removeValue", skillName, value)
end
exports("removeSkill", removeSkill)

function openStatisticsMenu()
    if waitingForLoadAfterRestart then return end
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openStatisticsMenu", stats = myStatistics })
end
exports("openStatisticsMenu", openStatisticsMenu)

-- ── Management menu ───────────────────────────────────────────
function openBossMenu(gymId)
    if waitingForLoadAfterRestart then return end
    local gymCfg = Config.Gyms[gymId]
    if not gymCfg then return end

    local function openWithEmployees(resumes, taxes)
        CL.GetEmployees(function(employees)
            currentGymManagement = gymId
            SendNUIMessage({
                action         = "openManagementMenu",
                storeData      = stores[gymId],
                storeCfg       = gymCfg,
                employees      = employees,
                employeesCount = #employees,
                isEmployee     = CL.IsEmployee(gymCfg.ownerJob),
                isManager      = CL.IsManager(gymCfg.ownerJob, gymId),
                isBoss         = CL.IsBoss(gymCfg.ownerJob, gymId),
                cityhallGrades = CL.IsAllowedCityhall(gymCfg.ownerJob, gymId),
                membershipsList = (gymCfg.requiredMembership and gymCfg.allowSellMembership and gymCfg.memberships) or nil,
                proteinsList    = (gymCfg.allowSellProteins and gymCfg.proteins) or nil,
                isResumesAllowed = Config.UseCityHallResumes and exports[Config.VMSCityHallResource]:isResumesAllowed(gymCfg.ownerJob) or false,
                resumes         = resumes,
                isTaxesAllowed  = Config.UseCityHallTaxes,
                taxes           = taxes,
            })
        end, gymCfg.ownerJob)
    end

    SetNuiFocus(true, true)

    if Config.UseVMSCityHall then
        if Config.Core == "ESX" then
            ESX.TriggerServerCallback("vms_cityhall:getBusinessData", function(resumes, taxes)
                openWithEmployees(resumes, taxes)
            end, Config.UseCityHallResumes, Config.UseCityHallTaxes)
        elseif Config.Core == "QB-Core" then
            QBCore.Functions.TriggerCallback("vms_cityhall:getBusinessData", function(resumes, taxes)
                openWithEmployees(resumes, taxes)
            end, Config.UseCityHallResumes, Config.UseCityHallTaxes)
        end
    else
        openWithEmployees(nil, nil)
    end

    if not Config.UseBuildInCompanyBalance then
        Citizen.Wait(300)
        TriggerServerEvent(Config.ESXSocietyEvents.check, gymCfg.ownerJob)
    end
end

function closeManagementMenu()
    SendNUIMessage({ action = "closeManagementMenu" })
    currentGymManagement = nil
    SetNuiFocus(false, false)
end

-- ── Purchase (shop) menu ──────────────────────────────────────
function openPurchaseMenu(gymId)
    if waitingForLoadAfterRestart then return end
    local gymCfg = Config.Gyms[gymId]
    if not gymCfg then return end

    local msg = { action = "openPurchaseMenu" }
    local hasContent = false

    if gymCfg.requiredMembership and gymCfg.allowBuyMembership then
        msg.useMemberships  = true
        msg.membershipsList = gymCfg.memberships
        msg.myMembership    = membershipMap[gymCfg.requiredMembership]
        hasContent = true
    end

    if gymCfg.allowBuyProteins then
        msg.useProteins  = true
        msg.proteinsList = gymCfg.proteins
        hasContent = true
    end

    if not hasContent then return end

    currentShop = gymId
    Citizen.Wait(100)
    SetNuiFocus(true, true)
    SendNUIMessage(msg)
end

function buyProtein(proteinName)
    if not proteinName then return end
    if not currentShop then return end
    local gymCfg = Config.Gyms[currentShop]
    if not gymCfg then return end
    if not gymCfg.proteins or not gymCfg.proteins[proteinName] then return end
    if not gymCfg.allowBuyProteins then return end
    TriggerServerEvent("vms_gym:sv:buyProtein", currentShop, proteinName)
end

function buyMembership(days, hours)
    if not days and not hours then return end
    if not currentShop then return end
    local gymCfg = Config.Gyms[currentShop]
    if not gymCfg then return end
    if not gymCfg.requiredMembership then return end
    if not gymCfg.allowBuyMembership then return end

    -- Find matching membership entry
    local found = nil
    for _, m in pairs(gymCfg.memberships) do
        if m.days == days and m.hours == hours then
            found = m
            break
        end
    end
    if not found then return end

    TriggerServerEvent("vms_gym:sv:acceptMembership", currentShop, gymCfg.requiredMembership, found)
end

-- ── Training action ───────────────────────────────────────────
function startAction(gymId, pointIndex, point)
    if currentPoint then return end  -- already training

    -- Membership check
    if Config.EnableMemberships then
        local gymCfg = Config.Gyms[gymId]
        if gymCfg and gymCfg.requiredMembership then
            local hasMembership = membershipMap[gymCfg.requiredMembership]
            if not hasMembership then
                -- Allow employees to bypass membership check
                if Config.AutoMembershipForEmployees then
                    if PlayerData.job and PlayerData.job.name == gymCfg.ownerJob then
                        -- allowed
                    else
                        CL.Notification(
                            TRANSLATE("notify.title.gym"),
                            TRANSLATE("no_membership"),
                            3500, "fa-solid fa-dumbbell", "error"
                        )
                        return
                    end
                else
                    CL.Notification(
                        TRANSLATE("notify.title.gym"),
                        TRANSLATE("no_membership"),
                        3500, "fa-solid fa-dumbbell", "error"
                    )
                    return
                end
            end
        end
    end

    if point.taken then
        CL.Notification(
            TRANSLATE("notify.title.gym"),
            TRANSLATE("place_taken"),
            3500, "fa-solid fa-dumbbell", "error"
        )
        return
    end

    currentGymId   = gymId
    currentPtIndex = pointIndex
    currentPoint   = point
    removeStrength = false

    local myPed = PlayerPedId()

    -- Set heading
    if point.activityCoord and point.activityCoord.w then
        SetEntityHeading(myPed, point.activityCoord.w)
    end

    -- Teleport to activity position
    if point.activityCoord and point.activityCoord.x then
        SetEntityCoords(myPed, vec(point.activityCoord.x, point.activityCoord.y, point.activityCoord.z))
    end

    FreezeEntityPosition(myPed, true)
    SetEntityCollision(myPed, false, false)

    -- Pre-load all anim dicts
    local anims = Config.Animations[point.name]
    for _, animData in pairs(anims) do
        loadAnimDict(animData[1])
    end

    TriggerServerEvent("vms_gym:sv:setTaken", currentGymId, currentPtIndex, true)

    SendNUIMessage({
        action  = "openHelpKeys",
        stamina = GetPlayerStamina(PlayerId()),
    })

    -- Enter animation
    if anims.enter then
        TaskPlayAnim(myPed, anims.enter[1], anims.enter[2], 8.0, -8.0, anims.enter[3], 0, 0.0, 0, 0, 0)
        Citizen.Wait(anims.enter[3])
    end

    -- Idle animation thread
    Citizen.CreateThread(function()
        TaskPlayAnim(myPed, anims.idle[1], anims.idle[2], 8.0, -8.0, anims.idle[3], 1, 0.0, 0, 0, 0)

        -- Attach prop 1
        if point.prop then
            requestProp(GetHashKey(point.prop.name))
            local propObj = CreateObject(GetHashKey(point.prop.name), GetEntityCoords(myPed), true, true, true)
            currentProp1  = propObj
            local boneIdx = GetPedBoneIndex(myPed, point.prop.attachBone)
            local pl      = point.prop.placement
            AttachEntityToEntity(propObj, myPed, boneIdx,
                pl[1]+0.0, pl[2]+0.0, pl[3]+0.0,
                pl[4]+0.0, pl[5]+0.0, pl[6]+0.0,
                true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(propObj)
        end

        -- Attach prop 2
        if point.prop2 then
            requestProp(GetHashKey(point.prop2.name))
            local propObj = CreateObject(GetHashKey(point.prop2.name), GetEntityCoords(myPed), true, true, true)
            currentProp2  = propObj
            local boneIdx = GetPedBoneIndex(myPed, point.prop2.attachBone)
            local pl      = point.prop2.placement
            AttachEntityToEntity(propObj, myPed, boneIdx,
                pl[1]+0.0, pl[2]+0.0, pl[3]+0.0,
                pl[4]+0.0, pl[5]+0.0, pl[6]+0.0,
                true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(propObj)
        end

        -- Main training loop
        while currentPoint do
            if IsControlJustPressed(0, Config.Keys.train) then
                currentStamina = GetPlayerStamina(PlayerId())

                -- Calculate stamina cost (condition affects how tiring it is)
                local condStat    = getSkill("condition")
                local staminaCost = condStat >= 10.0
                    and (point.removeStamina * 100 / condStat)
                    or  point.removeStamina

                if currentStamina > staminaCost then
                    -- Skillbar / progressbar check
                    local failed = false
                    if Config.UseSkillbar then
                        Config.Skillbar(point.name, function(ok)
                            failed = not ok
                        end)
                    end
                    if failed then goto continue end

                    -- Training animation
                    if Config.UseProgressbar then
                        Config.Progressbar(point.name, anims.training[3])
                    end

                    TaskPlayAnim(myPed, anims.training[1], anims.training[2],
                        8.0, -8.0, anims.training[3], 0, 0.0, 0, 0, 0)
                    Citizen.Wait(anims.training[3])

                    -- Return to idle
                    TaskPlayAnim(myPed, anims.idle[1], anims.idle[2], 8.0, -8.0, anims.idle[3], 1, 0.0, 0, 0, 0)

                    -- Deduct stamina
                    local newStamina = currentStamina - staminaCost
                    SetPlayerStamina(PlayerId(), newStamina)

                    -- Add skill
                    local addSkillCfg = point.addSkill
                    if addSkillCfg and addSkillCfg.skill and addSkillCfg.value then
                        local booster = addSkillCfg.skill == "strenght" and strengthBooster or conditionBooster
                        local gain
                        if type(addSkillCfg.value) == "number" then
                            gain = (addSkillCfg.value / 10.0) * booster
                        else
                            gain = (math.random(addSkillCfg.value[1], addSkillCfg.value[2]) / 10.0) * booster
                        end
                        addSkill(addSkillCfg.skill, gain)
                    end
                else
                    CL.Notification(
                        TRANSLATE("notify.title.gym"),
                        TRANSLATE("out_of_breath"),
                        3850, "fa-solid fa-dumbbell", "info"
                    )
                    Citizen.Wait(1000)
                end
                ::continue::
            end

            -- Stop key
            if IsControlJustPressed(0, Config.Keys.stop) then
                stopAction()
            end

            Citizen.Wait(1)
        end
    end)

    -- Stamina update thread
    Citizen.CreateThread(function()
        while currentPoint do
            SendNUIMessage({ action = "update", stamina = GetPlayerStamina(PlayerId()) })
            Citizen.Wait(800)
        end
    end)
end

function stopAction()
    if not currentPoint then return end

    local myPed  = PlayerPedId()
    local anims  = Config.Animations[currentPoint.name]

    -- Exit animation
    if anims.exit then
        TaskPlayAnim(myPed, anims.exit[1], anims.exit[2], 8.0, -8.0, anims.exit[3], 0, 0.0, 0, 0, 0)
        Citizen.Wait(anims.exit[3])
    else
        ClearPedTasks(myPed)
    end

    FreezeEntityPosition(myPed, false)
    SetEntityCollision(myPed, true, true)
    TriggerServerEvent("vms_gym:sv:setTaken", currentGymId, currentPtIndex, false)
    SendNUIMessage({ action = "closeHelpKeys" })

    if currentProp1 then DeleteObject(currentProp1); currentProp1 = nil end
    if currentProp2 then DeleteObject(currentProp2); currentProp2 = nil end

    removeStrength   = true
    currentPoint     = nil
    currentPtIndex   = nil
    currentGymId     = nil
    currentStamina   = nil
end

-- ── Passive stat threads ──────────────────────────────────────

-- Shooting skill
Citizen.CreateThread(function()
    local wait = 2000
    while Config.StatisticsMenu["shooting"] do
        Citizen.Wait(wait)
        local myPed = PlayerPedId()
        wait = 2000
        local status, weapon = GetCurrentPedWeapon(myPed, true)
        if status == 1 then
            local blacklist = {
                [GetHashKey("weapon_fireextinguisher")] = true,
                [GetHashKey("weapon_petrolcan")] = true,
                [GetHashKey("weapon_hazardcan")] = true,
                [GetHashKey("weapon_fertilizercan")] = true,
                [GetHashKey("weapon_grenade")] = true,
                [GetHashKey("weapon_bzgas")] = true,
                [GetHashKey("weapon_molotov")] = true,
                [GetHashKey("weapon_stickybomb")] = true,
                [GetHashKey("weapon_proxmine")] = true,
                [GetHashKey("weapon_snowball")] = true,
                [GetHashKey("weapon_pipebomb")] = true,
                [GetHashKey("weapon_ball")] = true,
                [GetHashKey("weapon_smokegrenade")] = true,
                [GetHashKey("weapon_flare")] = true,
                [GetHashKey("weapon_acidpackage")] = true,
                [GetHashKey("weapon_rpg")] = true,
                [GetHashKey("weapon_grenadelauncher")] = true,
                [GetHashKey("weapon_grenadelauncher_smoke")] = true,
                [GetHashKey("weapon_minigun")] = true,
                [GetHashKey("weapon_firework")] = true,
                [GetHashKey("weapon_railgun")] = true,
                [GetHashKey("weapon_hominglauncher")] = true,
                [GetHashKey("weapon_compactlauncher")] = true,
                [GetHashKey("weapon_rayminigun")] = true,
                [GetHashKey("weapon_emplauncher")] = true,
                [GetHashKey("weapon_railgunxm3")] = true,
            }
            if not blacklist[weapon] then
                wait = 10
                if IsPedShooting(myPed) then
                    if math.random(3) >= 2 then
                        local val = Config.AddStatsValues["Shooting"]
                        addSkill("shooting", type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0)
                    end
                    Citizen.Wait(math.random(6500, 10000))
                end
            end
        end
    end
end)

local speedUnit = Config.UnitOfSpeed == "kmh" and 3.6 or 2.236936

-- Condition / driving / flying skill + stat modifiers
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeAddStats)
        local myPed     = PlayerPedId()
        local myVehicle = GetVehiclePedIsUsing(myPed)
        removeCondition = true

        if IsPedRunning(myPed) and Config.StatisticsMenu["condition"] then
            local val = Config.AddStatsValues["Running"]
            addSkill("condition", (type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0) * conditionBooster)
            removeCondition = false
        elseif IsPedSwimmingUnderWater(myPed) and Config.StatisticsMenu["condition"] then
            local val = Config.AddStatsValues["Swimming"]
            addSkill("condition", (type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0) * conditionBooster)
            removeCondition = false
        elseif DoesEntityExist(myVehicle) then
            local isDriver = GetPedInVehicleSeat(myVehicle, -1) == myPed
            if isDriver then
                local speed        = GetEntitySpeed(myVehicle) * speedUnit
                local vehicleClass = GetVehicleClass(myVehicle)

                if vehicleClass == 13 and speed >= Config.AddStatsValues["Cycling"].minimumSpeed and Config.StatisticsMenu["condition"] then
                    local val = Config.AddStatsValues["Cycling"].value
                    addSkill("condition", (type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0) * conditionBooster)
                    removeCondition = false
                elseif (vehicleClass == 15 or vehicleClass == 16) and speed >= Config.AddStatsValues["Flying"].minimumSpeed and Config.StatisticsMenu["flying"] then
                    local val = Config.AddStatsValues["Flying"].value
                    addSkill("flying", type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0)
                elseif vehicleClass ~= 15 and vehicleClass ~= 16 and vehicleClass ~= 14 and speed >= Config.AddStatsValues["Driving"].minimumSpeed and Config.StatisticsMenu["driving"] then
                    local val = Config.AddStatsValues["Driving"].value
                    addSkill("driving", type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0)
                end
            end
        end

        -- Apply stat modifiers
        if myStatistics then
            if myStatistics["strenght"] and Config.EnableStrenghtModifier then
                local s = myStatistics["strenght"]
                if s >= 70.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 2.0)
                elseif s >= 50.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.5)
                elseif s >= 20.0 then
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.25)
                else
                    SetWeaponDamageModifier(GetHashKey("WEAPON_UNARMED"), 1.0)
                end
            end
            if myStatistics["condition"] then
                local c = myStatistics["condition"]
                if c >= 70.0 then
                    if Config.EnableRunSpeedModifier then SetRunSprintMultiplierForPlayer(PlayerId(), 1.49) end
                    if Config.EnableStaminaModifier  then StatSetInt(GetHashKey("MP0_STAMINA"), 60, true) end
                elseif c >= 50.0 then
                    if Config.EnableRunSpeedModifier then SetRunSprintMultiplierForPlayer(PlayerId(), 1.35) end
                    if Config.EnableStaminaModifier  then StatSetInt(GetHashKey("MP0_STAMINA"), 30, true) end
                elseif c >= 20.0 then
                    if Config.EnableRunSpeedModifier then SetRunSprintMultiplierForPlayer(PlayerId(), 1.1) end
                    if Config.EnableStaminaModifier  then StatSetInt(GetHashKey("MP0_STAMINA"), 15, true) end
                else
                    if Config.EnableRunSpeedModifier then SetRunSprintMultiplierForPlayer(PlayerId(), 1.0) end
                    if Config.EnableStaminaModifier  then StatSetInt(GetHashKey("MP0_STAMINA"), 0, true) end
                end
            end
        end
    end
end)

-- Passive stat removal (decay)
local removeCondition = true
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.RefreshTimeRemoveStats)
        if removeCondition and Config.StatisticsMenu["condition"] then
            local val = Config.RemoveStatsValues["RemoveCondition"]
            removeSkill("condition", type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0)
        end
        Citizen.Wait(3000)
        if removeStrength and Config.StatisticsMenu["strenght"] then
            local val = Config.RemoveStatsValues["RemoveStrength"]
            removeSkill("strenght", type(val) == "number" and val/10.0 or math.random(val[1], val[2])/10.0)
        end
    end
end)

-- Driving effects
Citizen.CreateThread(function()
    while Config.EnableSkillDrivingEffects and Config.StatisticsMenu["driving"] do
        local myVeh    = GetVehiclePedIsIn(PlayerPedId(), false)
        local isDriver = myVeh ~= 0 and GetPedInVehicleSeat(myVeh, -1) == PlayerPedId()
        if myVeh ~= 0 and isDriver and GetEntitySpeed(myVeh) * speedUnit > Config.SkillDrivingEffectMinimumSpeed then
            local skill = getSkill("driving")
            if skill < 20.0 then
                local bias = math.random(-1, 1) + 0.0
                SetVehicleSteerBias(myVeh, bias)
                SetVehicleReduceGrip(myVeh, true)
                Citizen.Wait(math.random(200, 450))
                SetVehicleSteerBias(myVeh, bias)
                SetVehicleReduceGrip(myVeh, false)
                Citizen.Wait(math.random(1750, 3000))
            elseif skill < 50.0 then
                SetVehicleSteerBias(myVeh, (math.random(-7, 7) + 0.0) / 10)
                if math.abs(GetVehicleSteeringAngle(myVeh)) > 30.0 then
                    SetVehicleReduceGrip(myVeh, true)
                    Citizen.Wait(math.random(200, 450))
                    SetVehicleReduceGrip(myVeh, false)
                end
                Citizen.Wait(math.random(1750, 4000))
            elseif skill < 70.0 then
                SetVehicleSteerBias(myVeh, (math.random(-5, 5) + 0.0) / 10)
                Citizen.Wait(math.random(2000, 6000))
            elseif skill < 80.0 then
                SetVehicleSteerBias(myVeh, (math.random(-2, 2) + 0.0) / 10)
                Citizen.Wait(math.random(5000, 8000))
            else
                Citizen.Wait(500)
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

-- ── World setup thread (blips, targets, markers) ──────────────
Citizen.CreateThread(function()
    Citizen.Wait(250)

    -- Create blips
    for gymId, gymCfg in pairs(Config.Gyms) do
        if gymCfg.blipCoords and gymCfg.blipEnabled then
            local blip = AddBlipForCoord(gymCfg.blipCoords)
            SetBlipSprite(blip,      Config.Blip.Sprite)
            SetBlipDisplay(blip,     Config.Blip.Display)
            SetBlipScale(blip,       Config.Blip.Scale)
            SetBlipColour(blip,      Config.Blip.Color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(gymCfg.blipName or "Gym")
            EndTextCommandSetBlipName(blip)
            gymCfg._createdBlip = blip
        end
    end

    -- Load ox_lib if needed
    if Config.UseTarget and Config.TargetResource == "ox_target" or Config.Menu == "ox_lib" then
        local code = LoadResourceFile("ox_lib", "init.lua")
        if code then
            local fn = assert(load(code, "@@ox_lib/init.lua"))
            fn()
        end
    end

    -- Register targets / activity points
    if Config.UseTarget then
        for gymId, gymCfg in pairs(Config.Gyms) do
            -- Boss menu target
            if gymCfg.business and gymCfg.ownerJob and gymCfg.bossMenu then
                CL.Target({
                    name   = "bossmenu-" .. gymId,
                    coords = gymCfg.bossMenu.targetCoords,
                    size   = gymCfg.bossMenu.targetSize,
                    job    = gymCfg.ownerJob,
                    label  = TRANSLATE("target.boss_menu"),
                    icon   = "fa-solid fa-dollar-sign",
                }, function()
                    openBossMenu(gymId)
                end)
            end

            -- Shop menu target
            local hasShop = (gymCfg.allowBuyMembership and gymCfg.requiredMembership) or gymCfg.allowBuyProteins
            if gymCfg.shopMenu and hasShop then
                CL.Target({
                    name   = "shopmenu-" .. gymId,
                    coords = gymCfg.shopMenu.targetCoords,
                    size   = gymCfg.shopMenu.targetSize,
                    label  = TRANSLATE("target.shop_menu"),
                    icon   = "fa-solid fa-dollar-sign",
                }, function()
                    openPurchaseMenu(gymId)
                end)
            end

            -- Activity point targets
            for ptIdx, pt in pairs(gymCfg.points) do
                CL.Target({
                    name   = pt.name .. "-" .. gymId .. "-" .. ptIdx,
                    coords = pt.activityCoord,
                    size   = pt.targetSize or vec(1.2, 1.2, 2.0),
                    label  = TRANSLATE("target." .. pt.name),
                    icon   = "fa-solid fa-dumbbell",
                }, function()
                    startAction(gymId, ptIdx, pt)
                end)
            end
        end
    end
end)

-- ── Proximity loop (non-target mode) ─────────────────────────
Citizen.CreateThread(function()
    local textUIShowing = false
    local textUIMsg     = false
    while true do
        if Config.UseTarget then
            Citizen.Wait(5000)
        else
            local sleeping   = true
            local myPed      = PlayerPedId()
            local myCoords   = GetEntityCoords(myPed)
            local newMsg     = false

            for gymId, gymCfg in pairs(Config.Gyms) do
                local distToGym = #(myCoords - gymCfg.blipCoords)
                if distToGym < 45.0 then
                    sleeping = false

                    -- Activity points
                    for ptIdx, pt in pairs(gymCfg.points) do
                        if not pt.taken then
                            local distToPt = #(myCoords - vec(pt.position.x, pt.position.y, pt.position.z))

                            if distToPt < Config.DistanceView then
                                -- Marker
                                if Config.UseMarkers then
                                    local m = Config.Markers.FreeSeat
                                    DrawMarker(m.id,
                                        pt.position.x, pt.position.y, pt.position.z,
                                        0, 0, 0,
                                        m.rotation and m.rotation[1] or 180.0,
                                        m.rotation and m.rotation[2] or 0.0,
                                        m.rotation and m.rotation[3] or 0.0,
                                        m.size.x, m.size.y, m.size.z,
                                        m.color[1], m.color[2], m.color[3], m.color[4],
                                        m.bobUpAndDown, false, m.rotate, false, false, false)
                                end

                                if Config.Use3DText then
                                    DrawText3D(pt.position.x, pt.position.y, pt.position.z,
                                        TRANSLATE("3dtext." .. pt.name))
                                end

                                if distToPt < Config.DistanceAccess then
                                    newMsg = TRANSLATE("textui." .. pt.name)

                                    if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                        ESX.ShowHelpNotification(TRANSLATE("help." .. pt.name))
                                    end

                                    if IsControlJustPressed(0, Config.Keys.enter) then
                                        startAction(gymId, ptIdx, pt)
                                        newMsg = false
                                    end
                                end
                            end
                        end
                    end

                    -- Boss menu
                    if gymCfg.business and gymCfg.bossMenu and gymCfg.bossMenu.coords then
                        local distBoss = #(myCoords - gymCfg.bossMenu.coords.xyz)
                        if distBoss < Config.DistanceView and PlayerData.job and CL.IsEmployee(gymCfg.ownerJob) then
                            sleeping = false
                            if Config.UseMarkers then
                                local m = Config.Markers.BossMenu
                                DrawMarker(m.id,
                                    gymCfg.bossMenu.coords.x, gymCfg.bossMenu.coords.y, gymCfg.bossMenu.coords.z,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    m.size.x, m.size.y, m.size.z,
                                    m.color[1], m.color[2], m.color[3], m.color[4],
                                    m.bobUpAndDown, false, m.rotate, false, false, false)
                            end
                            if Config.Use3DText then
                                DrawText3D(gymCfg.bossMenu.coords.x, gymCfg.bossMenu.coords.y, gymCfg.bossMenu.coords.z,
                                    TRANSLATE("3dtext.boss_menu"))
                            end
                            if distBoss < Config.DistanceAccess then
                                newMsg = TRANSLATE("textui.boss_menu")
                                if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                    ESX.ShowHelpNotification(TRANSLATE("help.boss_menu"))
                                end
                                if IsControlJustPressed(0, 38) then
                                    openBossMenu(gymId)
                                    newMsg = false
                                end
                            end
                        end
                    end

                    -- Shop menu
                    if gymCfg.shopMenu and gymCfg.shopMenu.coords then
                        local hasShop = (gymCfg.allowBuyMembership and gymCfg.requiredMembership) or gymCfg.allowBuyProteins
                        if hasShop then
                            local distShop = #(myCoords - gymCfg.shopMenu.coords.xyz)
                            if distShop < Config.DistanceView then
                                sleeping = false
                                if Config.UseMarkers then
                                    local m = Config.Markers.ShopMenu
                                    DrawMarker(m.id,
                                        gymCfg.shopMenu.coords.x, gymCfg.shopMenu.coords.y, gymCfg.shopMenu.coords.z,
                                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                        m.size.x, m.size.y, m.size.z,
                                        m.color[1], m.color[2], m.color[3], m.color[4],
                                        m.bobUpAndDown, false, m.rotate, false, false, false)
                                end
                                if Config.Use3DText then
                                    DrawText3D(gymCfg.shopMenu.coords.x, gymCfg.shopMenu.coords.y, gymCfg.shopMenu.coords.z,
                                        TRANSLATE("3dtext.shop_menu"))
                                end
                                if distShop < Config.DistanceAccess then
                                    newMsg = TRANSLATE("textui.shop_menu")
                                    if Config.Core == "ESX" and not CL.TextUI.Enabled and Config.UseHelpNotify then
                                        ESX.ShowHelpNotification(TRANSLATE("help.shop_menu"))
                                    end
                                    if IsControlJustPressed(0, 38) then
                                        openPurchaseMenu(gymId)
                                        newMsg = false
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- TextUI open/close
            if CL.TextUI.Enabled then
                if newMsg and not textUIShowing then
                    textUIShowing = true
                    CL.TextUI.Open(newMsg)
                elseif not newMsg and textUIShowing then
                    textUIShowing = false
                    CL.TextUI.Close()
                end
            end

            Citizen.Wait(sleeping and 2000 or 1)
        end
    end
end)

-- ── 3D text helper ────────────────────────────────────────────
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextDropShadow()
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
