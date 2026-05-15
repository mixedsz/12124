-- ============================================================
--  vms_gym  |  nui.lua  (deobfuscated)
--  All NUI callbacks bridging the HTML UI → Lua
-- ============================================================

-- ── loaded ───────────────────────────────────────────────────
RegisterNUICallback("loaded", function(data, cb)
    local msg = {
        action                               = "loaded",
        lang                                 = Config.Language,
        statisticsmenu                       = Config.StatisticsMenu,
        useBuildInBalance                    = Config.UseBuildInCompanyBalance,
        removeBalanceFromMenu                = Config.RemoveBalanceFromMenu,
        useCityHall                          = Config.UseVMSCityHall,
        useCityHallResumes                   = Config.UseCityHallResumes,
        useCityHallTaxes                     = Config.UseCityHallTaxes,
        useCityHallIncludedTaxes             = Config.UseCityHallIncludedTaxes,
        taxBusinessAllowMakeDelayedDeclarations = nil,
        taxBusinessPercentagePerMonthForDelay   = nil,
    }

    if Config.UseVMSCityHall and Config.UseCityHallTaxes then
        local exp = exports[Config.VMSCityHallResource]
        msg.taxBusinessAllowMakeDelayedDeclarations = exp:TaxBusinessAllowMakeDelayedDeclarations() or nil
        msg.taxBusinessPercentagePerMonthForDelay   = exp:TaxBusinessPercentagePerMonthForDelay()   or nil
    end

    SendNUIMessage(msg)
    cb({})
end)

-- ── notifyStatus ─────────────────────────────────────────────
RegisterNUICallback("notifyStatus", function(data, cb)
    disabledNotifySkillInfo = tonumber(data.status)
    cb({})
end)

-- ── closeStatisticsMenu ───────────────────────────────────────
RegisterNUICallback("closeStatisticsMenu", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeStatisticsMenu" })
    cb({})
end)

-- ── closePurchaseMenu ─────────────────────────────────────────
RegisterNUICallback("closePurchaseMenu", function(data, cb)
    currentShop = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closePurchaseMenu" })
    cb({})
end)

-- ── buyProtein ────────────────────────────────────────────────
RegisterNUICallback("buyProtein", function(data, cb)
    buyProtein(data.name)
    cb({})
end)

-- ── buyMembership ─────────────────────────────────────────────
RegisterNUICallback("buyMembership", function(data, cb)
    buyMembership(data.days, data.hours)
    cb({})
end)

-- ── closeMenu / closeManagementMenu ──────────────────────────
RegisterNUICallback("closeMenu", function(data, cb)
    closeManagementMenu()
    cb({})
end)

RegisterNUICallback("closeManagementMenu", function(data, cb)
    closeManagementMenu()
    cb({})
end)

-- ── sendAnnouncement ──────────────────────────────────────────
RegisterNUICallback("sendAnnouncement", function(data, cb)
    if data.text and data.text ~= "" then
        TriggerServerEvent("vms_gym:sendAnnouncement", currentGymManagement, data.text)
    end
    cb({})
end)

-- ── getClosestPlayers ─────────────────────────────────────────
RegisterNUICallback("getClosestPlayers", function(data, cb)
    if not currentGymManagement then cb({}); return end

    local nearbyPeds = CL.GetClosestPlayers()
    if not nearbyPeds then
        Config.Notification(
            TRANSLATE("notify.employees:no_players_around"),
            3000, "error"
        )
        cb({}); return
    end

    local playerIds = {}
    for _, ped in pairs(nearbyPeds) do
        table.insert(playerIds, GetPlayerServerId(ped))
    end

    SendNUIMessage({ action = "updateManagementMenu", players = playerIds })
    cb({})
end)

-- ── hireEmployee ─────────────────────────────────────────────
RegisterNUICallback("hireEmployee", function(data, cb)
    if not currentGymManagement then cb({}); return end
    TriggerServerEvent("vms_gym:hireAnEmployee", currentGymManagement, data.playerId)
    cb({})
end)

-- ── bonusEmployee ─────────────────────────────────────────────
RegisterNUICallback("bonusEmployee", function(data, cb)
    if not currentGymManagement then cb({}); return end
    TriggerServerEvent("vms_gym:bonusEmployee", currentGymManagement, data.identifier, data.bonusMoney)
    cb({})
end)

-- ── changeGradeEmployee ───────────────────────────────────────
RegisterNUICallback("changeGradeEmployee", function(data, cb)
    if not currentGymManagement then cb({}); return end
    TriggerServerEvent("vms_gym:changeGradeEmployee", currentGymManagement, data.identifier, data.grade)
    cb({})
end)

-- ── fireEmployee ─────────────────────────────────────────────
RegisterNUICallback("fireEmployee", function(data, cb)
    if not currentGymManagement then cb({}); return end
    TriggerServerEvent("vms_gym:fireEmployee", currentGymManagement, data.identifier)
    cb({})
end)

-- ── withdraw ──────────────────────────────────────────────────
RegisterNUICallback("withdraw", function(data, cb)
    if not currentGymManagement then cb({}); return end
    local amount = tonumber(data.money)
    if not amount or amount < 1 then cb({}); return end

    if not Config.UseBuildInCompanyBalance then
        TriggerServerEvent(
            Config.ESXSocietyEvents.withdraw,
            Config.Gyms[currentGymManagement].ownerJob,
            amount
        )
    else
        TriggerServerEvent("vms_gym:withdraw", currentGymManagement, amount)
    end
    cb({})
end)

-- ── deposit ───────────────────────────────────────────────────
RegisterNUICallback("deposit", function(data, cb)
    if not currentGymManagement then cb({}); return end
    local amount = tonumber(data.money)
    if not amount or amount < 1 then cb({}); return end

    if not Config.UseBuildInCompanyBalance then
        TriggerServerEvent(
            Config.ESXSocietyEvents.deposit,
            Config.Gyms[currentGymManagement].ownerJob,
            amount
        )
    else
        TriggerServerEvent("vms_gym:deposit", currentGymManagement, amount)
    end
    cb({})
end)

-- ── getClosestPlayersForMembership ────────────────────────────
RegisterNUICallback("getClosestPlayersForMembership", function(data, cb)
    local nearbyPeds = CL.GetClosestPlayers()
    local playerIds  = {}
    if nearbyPeds then
        for _, ped in pairs(nearbyPeds) do
            if ped then
                table.insert(playerIds, GetPlayerServerId(ped))
            end
        end
    end
    cb(playerIds)
end)

-- ── sellMembership ────────────────────────────────────────────
RegisterNUICallback("sellMembership", function(data, cb)
    if not currentGymManagement then cb({}); return end

    local gymCfg = Config.Gyms[currentGymManagement]
    if not gymCfg then cb({}); return end
    if not gymCfg.requiredMembership then cb({}); return end
    if not gymCfg.allowSellMembership then cb({}); return end

    -- Find matching membership
    local found = nil
    for _, m in pairs(gymCfg.memberships) do
        if m.days == data.days and m.hours == data.hours then
            found = m; break
        end
    end
    if not found then cb({}); return end

    TriggerServerEvent("vms_gym:sv:sellMembership", data.playerId, currentGymManagement, found)
    cb({})
end)

-- ── sellProtein ───────────────────────────────────────────────
RegisterNUICallback("sellProtein", function(data, cb)
    if not currentGymManagement then cb({}); return end

    local gymCfg = Config.Gyms[currentGymManagement]
    if not gymCfg then cb({}); return end
    if not gymCfg.allowSellProteins then cb({}); return end
    if not gymCfg.proteins then cb({}); return end

    local protein = gymCfg.proteins[data.name]
    if not protein then cb({}); return end

    TriggerServerEvent("vms_gym:sv:sellProtein", data.playerId, currentGymManagement, protein, data.count)
    cb({})
end)

-- ── bill ─────────────────────────────────────────────────────
RegisterNUICallback("bill", function(data, cb)
    if data.action == "pay" then
        TriggerServerEvent("vms_gym:sv:payBill", "pay", data.type)
    else
        TriggerServerEvent("vms_gym:sv:payBill", "cancel")
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "closeReceipt" })
        billCache = {}
    end
    cb({})
end)
