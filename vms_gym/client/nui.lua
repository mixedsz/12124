-- ╔═╗ ╔╗╔╗ ╔╗╔══╗    ╔═══╗╔╗  ╔╗╔═══╗╔═╗ ╔╗╔════╗╔═══╗
-- ║║╚╗║║║║ ║║╚╣╠╝    ║╔══╝║╚╗╔╝║║╔══╝║║╚╗║║║╔╗╔╗║║╔═╗║
-- ║╔╗╚╝║║║ ║║ ║║     ║╚══╗╚╗║║╔╝║╚══╗║╔╗╚╝║╚╝║║╚╝║╚══╗
-- ║║╚╗║║║║ ║║ ║║     ║╔══╝ ║╚╝║ ║╔══╝║║╚╗║║  ║║  ╚══╗║
-- ║║ ║║║║╚═╝║╔╣╠╗    ║╚══╗ ╚╗╔╝ ║╚══╗║║ ║║║ ╔╝╚╗ ║╚═╝║
-- ╚╝ ╚═╝╚═══╝╚══╝    ╚═══╝  ╚╝  ╚═══╝╚╝ ╚═╝ ╚══╝ ╚═══╝

RegisterNUICallback('loaded', function(data, cb)
    SendNUIMessage({
        action = "loaded",
        lang = Config.Language,
        statisticsmenu = Config.StatisticsMenu,
        
        useBuildInBalance = Config.UseBuildInCompanyBalance,
        removeBalanceFromMenu = Config.RemoveBalanceFromMenu,
        
        useCityHall = Config.UseVMSCityHall,
        useCityHallResumes = Config.UseCityHallResumes,
        useCityHallTaxes = Config.UseCityHallTaxes,
        useCityHallIncludedTaxes = Config.UseCityHallIncludedTaxes,

        taxBusinessAllowMakeDelayedDeclarations = Config.UseVMSCityHall and Config.UseCityHallTaxes and exports[Config.VMSCityHallResource]:TaxBusinessAllowMakeDelayedDeclarations() or nil,
        taxBusinessPercentagePerMonthForDelay = Config.UseVMSCityHall and Config.UseCityHallTaxes and exports[Config.VMSCityHallResource]:TaxBusinessPercentagePerMonthForDelay() or nil,
    })
end)

RegisterNUICallback('notifyStatus', function(data, cb)
    disabledNotifySkillInfo = tonumber(data.status)
end)

RegisterNUICallback('closeStatisticsMenu', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closeStatisticsMenu'})
end)


RegisterNUICallback('closePurchaseMenu', function(data, cb)
    currentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closePurchaseMenu'})
end)

RegisterNUICallback('buyProtein', function(data, cb)
    buyProtein(data.name)
end)

RegisterNUICallback('buyMembership', function(data, cb)
    buyMembership(data.days, data.hours)
end)



RegisterNUICallback('closeMenu', function(data, cb)
    closeManagementMenu()
end)

RegisterNUICallback('closeManagementMenu', function(data, cb)
    closeManagementMenu()
end)

RegisterNUICallback('sendAnnouncement', function(data, cb)
    if data.text then
        TriggerServerEvent("vms_gym:sendAnnouncement", currentGymManagement, data.text)
    end
end)

RegisterNUICallback('getClosestPlayers', function(data, cb)
    if not currentGymManagement then
        return
    end
    local players = CL.GetClosestPlayers()
    local playerInArea = {}
    if not players then
        Config.Notification(TRANSLATE('notify.employees:no_players_around'), 3000, 'error')
        return
    end
    for k, v in pairs(players) do
        playerInArea[#playerInArea + 1] = GetPlayerServerId(v)
    end
    SendNUIMessage({
        action = "updateManagementMenu",
        players = playerInArea,
    })
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    if not currentGymManagement then return end
    TriggerServerEvent("vms_gym:hireAnEmployee", currentGymManagement, data.playerId)
end)

RegisterNUICallback('bonusEmployee', function(data, cb)
    if not currentGymManagement then return end
    TriggerServerEvent("vms_gym:bonusEmployee", currentGymManagement, data.identifier, data.bonusMoney)
end)

RegisterNUICallback('changeGradeEmployee', function(data, cb)
    if not currentGymManagement then return end
    TriggerServerEvent("vms_gym:changeGradeEmployee", currentGymManagement, data.identifier, data.grade)
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    if not currentGymManagement then return end
    TriggerServerEvent("vms_gym:fireEmployee", currentGymManagement, data.identifier)
end)

RegisterNUICallback('withdraw', function(data, cb)
    if not currentGymManagement then return end
    if tonumber(data.money) and tonumber(data.money) >= 1 then
        if not Config.UseBuildInCompanyBalance then
            TriggerServerEvent(Config.ESXSocietyEvents['withdraw'], Config.Gyms[currentGymManagement].ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("vms_gym:withdraw", currentGymManagement, tonumber(data.money))
        end
    end
end)

RegisterNUICallback('deposit', function(data, cb)
    if not currentGymManagement then return end
    if tonumber(data.money) and tonumber(data.money) >= 1 then
        if not Config.UseBuildInCompanyBalance then
            TriggerServerEvent(Config.ESXSocietyEvents['deposit'], Config.Gyms[currentGymManagement].ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("vms_gym:deposit", currentGymManagement, tonumber(data.money))
        end
    end
end)

RegisterNUICallback('getClosestPlayersForMembership', function(data, cb)
    local players = CL.GetClosestPlayers()
    local playerInArea = {}
    for k, v in pairs(players) do
        if v then
            playerInArea[#playerInArea + 1] = GetPlayerServerId(v)
        end
    end

    cb(playerInArea)
end)

RegisterNUICallback("sellMembership", function(data)
    if not currentGymManagement then return end

    local gymData = Config.Gyms[currentGymManagement];

    if not gymData.requiredMembership then
        return
    end

    if not gymData.allowSellMembership then
        return
    end

    local membershipData = nil
    for k, v in pairs(gymData.memberships) do
        if v.days == data.days and v.hours == data.hours then
            membershipData = v
            break
        end
    end

    if not membershipData then
        return
    end

    TriggerServerEvent("vms_gym:sv:sellMembership", data.playerId, currentGymManagement, membershipData)
end)

RegisterNUICallback("sellProtein", function(data)
    if not currentGymManagement then return end

    local gymData = Config.Gyms[currentGymManagement];

    if not gymData.allowSellProteins then
        return
    end

    if not gymData.proteins then
        return
    end

    if not gymData.proteins[data.name] then
        return
    end

    TriggerServerEvent("vms_gym:sv:sellProtein", data.playerId, currentGymManagement, gymData.proteins[data.name], data.count)
end)

RegisterNUICallback('bill', function(data, cb)
    if data.action == 'pay' then
        TriggerServerEvent("vms_gym:sv:payBill", 'pay', data.type)
    else
        TriggerServerEvent("vms_gym:sv:payBill", 'cancel')
        SetNuiFocus(false, false)
        SendNUIMessage({action = "closeReceipt"})
        billCache = {}
    end
end)
