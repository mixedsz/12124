RegisterNUICallback("loaded", function(data, cb)
    local taxAllowDelayed = nil
    local taxDelayPercentage = nil

    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        local cityHall = exports[Config.VMSCityHallResource]
        taxAllowDelayed = cityHall:TaxBusinessAllowMakeDelayedDeclarations()
        if not taxAllowDelayed then
            taxAllowDelayed = nil
        end
    end

    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        local cityHall = exports[Config.VMSCityHallResource]
        taxDelayPercentage = cityHall:TaxBusinessPercentagePerMonthForDelay()
        if not taxDelayPercentage then
            taxDelayPercentage = nil
        end
    end

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
        taxBusinessAllowMakeDelayedDeclarations = taxAllowDelayed,
        taxBusinessPercentagePerMonthForDelay = taxDelayPercentage,
    })
end)

RegisterNUICallback("notifyStatus", function(data, cb)
    disabledNotifySkillInfo = tonumber(data.status)
end)

RegisterNUICallback("closeStatisticsMenu", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeStatisticsMenu" })
end)

RegisterNUICallback("closePurchaseMenu", function(data, cb)
    currentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closePurchaseMenu" })
end)

RegisterNUICallback("buyProtein", function(data, cb)
    buyProtein(data.name)
end)

RegisterNUICallback("buyMembership", function(data, cb)
    buyMembership(data.days, data.hours)
end)

RegisterNUICallback("closeMenu", function(data, cb)
    closeManagementMenu()
end)

RegisterNUICallback("closeManagementMenu", function(data, cb)
    closeManagementMenu()
end)

RegisterNUICallback("sendAnnouncement", function(data, cb)
    if data.text then
        TriggerServerEvent("flake_gym:sendAnnouncement", currentGymManagement, data.text)
    end
end)

RegisterNUICallback("getClosestPlayers", function(data, cb)
    if not currentGymManagement then
        return
    end

    local closestPlayers = CL.GetClosestPlayers()
    local playerIds = {}

    if not closestPlayers then
        Config.Notification(TRANSLATE("notify.employees:no_players_around"), 3000, "error")
        return
    end

    for _, player in pairs(closestPlayers) do
        playerIds[#playerIds + 1] = GetPlayerServerId(player)
    end

    SendNUIMessage({
        action = "updateManagementMenu",
        players = playerIds,
    })
end)

RegisterNUICallback("hireEmployee", function(data, cb)
    if not currentGymManagement then
        return
    end
    TriggerServerEvent("flake_gym:hireAnEmployee", currentGymManagement, data.playerId)
end)

RegisterNUICallback("bonusEmployee", function(data, cb)
    if not currentGymManagement then
        return
    end
    TriggerServerEvent("flake_gym:bonusEmployee", currentGymManagement, data.identifier, data.bonusMoney)
end)

RegisterNUICallback("changeGradeEmployee", function(data, cb)
    if not currentGymManagement then
        return
    end
    TriggerServerEvent("flake_gym:changeGradeEmployee", currentGymManagement, data.identifier, data.grade)
end)

RegisterNUICallback("fireEmployee", function(data, cb)
    if not currentGymManagement then
        return
    end
    TriggerServerEvent("flake_gym:fireEmployee", currentGymManagement, data.identifier)
end)

RegisterNUICallback("withdraw", function(data, cb)
    if not currentGymManagement then
        return
    end

    local amount = tonumber(data.money)
    if amount and amount >= 1 then
        if not Config.UseBuildInCompanyBalance then
            TriggerServerEvent(Config.ESXSocietyEvents.withdraw, Config.Gyms[currentGymManagement].ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("flake_gym:withdraw", currentGymManagement, tonumber(data.money))
        end
    end
end)

RegisterNUICallback("deposit", function(data, cb)
    if not currentGymManagement then
        return
    end

    local amount = tonumber(data.money)
    if amount and amount >= 1 then
        if not Config.UseBuildInCompanyBalance then
            TriggerServerEvent(Config.ESXSocietyEvents.deposit, Config.Gyms[currentGymManagement].ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("flake_gym:deposit", currentGymManagement, tonumber(data.money))
        end
    end
end)

RegisterNUICallback("getClosestPlayersForMembership", function(data, cb)
    local closestPlayers = CL.GetClosestPlayers()
    local playerIds = {}

    for _, player in pairs(closestPlayers) do
        if player then
            playerIds[#playerIds + 1] = GetPlayerServerId(player)
        end
    end

    cb(playerIds)
end)

RegisterNUICallback("sellMembership", function(data)
    if not currentGymManagement then
        return
    end

    local gymConfig = Config.Gyms[currentGymManagement]

    if not gymConfig.requiredMembership then
        return
    end

    if not gymConfig.allowSellMembership then
        return
    end

    local matchedMembership = nil
    for _, membership in pairs(gymConfig.memberships) do
        if membership.days == data.days and membership.hours == data.hours then
            matchedMembership = membership
            break
        end
    end

    if not matchedMembership then
        return
    end

    TriggerServerEvent("flake_gym:sv:sellMembership", data.playerId, currentGymManagement, matchedMembership)
end)

RegisterNUICallback("sellProtein", function(data)
    if not currentGymManagement then
        return
    end

    local gymConfig = Config.Gyms[currentGymManagement]

    if not gymConfig.allowSellProteins then
        return
    end

    if not gymConfig.proteins then
        return
    end

    local protein = gymConfig.proteins[data.name]
    if not protein then
        return
    end

    TriggerServerEvent("flake_gym:sv:sellProtein", data.playerId, currentGymManagement, protein, data.count)
end)

RegisterNUICallback("bill", function(data, cb)
    if data.action == "pay" then
        TriggerServerEvent("flake_gym:sv:payBill", "pay", data.type)
    else
        TriggerServerEvent("flake_gym:sv:payBill", "cancel")
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeReceipt" })
        billCache = {}
    end
end)
