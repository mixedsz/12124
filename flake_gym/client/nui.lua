-- ============================================================
--  flake_gym  –  nui.lua  (NUI callbacks, deobfuscated)
-- ============================================================

-- ============================================================
--  Loaded: send initial config values to the NUI
-- ============================================================
RegisterNUICallback("loaded", function(data, cb)
    local msg = {
        action                   = "loaded",
        lang                     = Config.Language,
        statisticsmenu           = Config.StatisticsMenu,
        useBuildInBalance        = Config.UseBuildInCompanyBalance,
        removeBalanceFromMenu    = Config.RemoveBalanceFromMenu,
        useCityHall              = Config.UseVMSCityHall,
        useCityHallResumes       = Config.UseCityHallResumes,
        useCityHallTaxes         = Config.UseCityHallTaxes,
        useCityHallIncludedTaxes = Config.UseCityHallIncludedTaxes,
        taxBusinessAllowMakeDelayedDeclarations = nil,
        taxBusinessPercentagePerMonthForDelay   = nil,
    }

    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        local resource = exports[Config.VMSCityHallResource]
        local allowDelay = resource:TaxBusinessAllowMakeDelayedDeclarations()
        if allowDelay then
            msg.taxBusinessAllowMakeDelayedDeclarations = allowDelay
        end
        local pctDelay = resource:TaxBusinessPercentagePerMonthForDelay()
        if pctDelay then
            msg.taxBusinessPercentagePerMonthForDelay = pctDelay
        end
    end

    SendNUIMessage(msg)
    if cb then cb({}) end
end)

-- ============================================================
--  Notification status (enabled/disabled skill notifications)
-- ============================================================
RegisterNUICallback("notifyStatus", function(data, cb)
    disabledNotifySkillInfo = tonumber(data.status)
    if cb then cb({}) end
end)

-- ============================================================
--  Close menus
-- ============================================================
RegisterNUICallback("closeStatisticsMenu", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({action = "closeStatisticsMenu"})
    if cb then cb({}) end
end)

RegisterNUICallback("closePurchaseMenu", function(data, cb)
    currentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({action = "closePurchaseMenu"})
    if cb then cb({}) end
end)

RegisterNUICallback("closeMenu", function(data, cb)
    closeManagementMenu()
    if cb then cb({}) end
end)

RegisterNUICallback("closeManagementMenu", function(data, cb)
    closeManagementMenu()
    if cb then cb({}) end
end)

-- ============================================================
--  Purchase callbacks
-- ============================================================
RegisterNUICallback("buyProtein", function(data, cb)
    buyProtein(data.name)
    if cb then cb({}) end
end)

RegisterNUICallback("buyMembership", function(data, cb)
    buyMembership(data.days, data.hours)
    if cb then cb({}) end
end)

-- ============================================================
--  Bill / receipt callbacks
-- ============================================================
RegisterNUICallback("bill", function(data, cb)
    if data.action == "pay" then
        TriggerServerEvent("flake_gym:sv:payBill", "pay", data.type)
    else
        TriggerServerEvent("flake_gym:sv:payBill", "cancel")
        SetNuiFocus(false, false)
        SendNUIMessage({action = "closeReceipt"})
        billCache = {}
    end
    if cb then cb({}) end
end)

-- ============================================================
--  Management menu callbacks
-- ============================================================
RegisterNUICallback("sendAnnouncement", function(data, cb)
    if data.text then
        TriggerServerEvent("flake_gym:sendAnnouncement", currentGymManagement, data.text)
    end
    if cb then cb({}) end
end)

RegisterNUICallback("getClosestPlayers", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end

    local players = CL.GetClosestPlayers()
    if not players then
        Config.Notification(
            TRANSLATE("notify.employees:no_players_around"),
            3000,
            "error")
        if cb then cb({}) end
        return
    end

    local playerIds = {}
    for _, ped in pairs(players) do
        playerIds[#playerIds + 1] = GetPlayerServerId(ped)
    end

    SendNUIMessage({action = "updateManagementMenu", players = playerIds})
    if cb then cb({}) end
end)

RegisterNUICallback("hireEmployee", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    TriggerServerEvent("flake_gym:hireAnEmployee", currentGymManagement, data.playerId)
    if cb then cb({}) end
end)

RegisterNUICallback("bonusEmployee", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    TriggerServerEvent("flake_gym:bonusEmployee", currentGymManagement, data.identifier, data.bonusMoney)
    if cb then cb({}) end
end)

RegisterNUICallback("changeGradeEmployee", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    TriggerServerEvent("flake_gym:changeGradeEmployee", currentGymManagement, data.identifier, data.grade)
    if cb then cb({}) end
end)

RegisterNUICallback("fireEmployee", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    TriggerServerEvent("flake_gym:fireEmployee", currentGymManagement, data.identifier)
    if cb then cb({}) end
end)

RegisterNUICallback("withdraw", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    local amount = tonumber(data.money)
    if amount and amount >= 1 then
        if not Config.UseBuildInCompanyBalance then
            local ownerJob = Config.Gyms[currentGymManagement].ownerJob
            TriggerServerEvent(Config.ESXSocietyEvents.withdraw, ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("flake_gym:withdraw", currentGymManagement, tonumber(data.money))
        end
    end
    if cb then cb({}) end
end)

RegisterNUICallback("deposit", function(data, cb)
    if not currentGymManagement then
        if cb then cb({}) end
        return
    end
    local amount = tonumber(data.money)
    if amount and amount >= 1 then
        if not Config.UseBuildInCompanyBalance then
            local ownerJob = Config.Gyms[currentGymManagement].ownerJob
            TriggerServerEvent(Config.ESXSocietyEvents.deposit, ownerJob, tonumber(data.money))
        else
            TriggerServerEvent("flake_gym:deposit", currentGymManagement, tonumber(data.money))
        end
    end
    if cb then cb({}) end
end)

-- ============================================================
--  Sell membership / protein (employee → nearby player)
-- ============================================================
RegisterNUICallback("getClosestPlayersForMembership", function(data, cb)
    local players   = CL.GetClosestPlayers()
    local playerIds = {}

    for _, ped in pairs(players or {}) do
        if ped then
            playerIds[#playerIds + 1] = GetPlayerServerId(ped)
        end
    end

    if cb then cb(playerIds) end
end)

RegisterNUICallback("sellMembership", function(data)
    if not currentGymManagement then return end

    local gymConfig = Config.Gyms[currentGymManagement]
    if not gymConfig then return end
    if not gymConfig.requiredMembership then return end
    if not gymConfig.allowSellMembership then return end
    if not gymConfig.memberships then return end

    local selectedMembership = nil
    for _, mem in pairs(gymConfig.memberships) do
        if mem.days == data.days and mem.hours == data.hours then
            selectedMembership = mem
            break
        end
    end

    if not selectedMembership then return end

    TriggerServerEvent("flake_gym:sv:sellMembership",
        data.playerId,
        currentGymManagement,
        selectedMembership)
end)

RegisterNUICallback("sellProtein", function(data)
    if not currentGymManagement then return end

    local gymConfig = Config.Gyms[currentGymManagement]
    if not gymConfig then return end
    if not gymConfig.allowSellProteins then return end
    if not gymConfig.proteins then return end

    local proteinData = gymConfig.proteins[data.name]
    if not proteinData then return end

    TriggerServerEvent("flake_gym:sv:sellProtein",
        data.playerId,
        currentGymManagement,
        proteinData,
        data.count)
end)
