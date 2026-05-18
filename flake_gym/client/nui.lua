local L0_1, L1_1, L2_1
L0_1 = RegisterNUICallback
L1_1 = "loaded"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "loaded"
  L4_2 = Config
  L4_2 = L4_2.Language
  L3_2.lang = L4_2
  L4_2 = Config
  L4_2 = L4_2.StatisticsMenu
  L3_2.statisticsmenu = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseBuildInCompanyBalance
  L3_2.useBuildInBalance = L4_2
  L4_2 = Config
  L4_2 = L4_2.RemoveBalanceFromMenu
  L3_2.removeBalanceFromMenu = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseVMSCityHall
  L3_2.useCityHall = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseCityHallResumes
  L3_2.useCityHallResumes = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseCityHallTaxes
  L3_2.useCityHallTaxes = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseCityHallIncludedTaxes
  L3_2.useCityHallIncludedTaxes = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseVMSCityHall
  if L4_2 then
    L4_2 = Config
    L4_2 = L4_2.UseCityHallTaxes
    if L4_2 then
      L4_2 = exports
      L5_2 = Config
      L5_2 = L5_2.VMSCityHallResource
      L4_2 = L4_2[L5_2]
      L5_2 = L4_2
      L4_2 = L4_2.TaxBusinessAllowMakeDelayedDeclarations
      L4_2 = L4_2(L5_2)
      if L4_2 then
        goto lbl_46
      end
    end
  end
  L4_2 = nil
  ::lbl_46::
  L3_2.taxBusinessAllowMakeDelayedDeclarations = L4_2
  L4_2 = Config
  L4_2 = L4_2.UseVMSCityHall
  if L4_2 then
    L4_2 = Config
    L4_2 = L4_2.UseCityHallTaxes
    if L4_2 then
      L4_2 = exports
      L5_2 = Config
      L5_2 = L5_2.VMSCityHallResource
      L4_2 = L4_2[L5_2]
      L5_2 = L4_2
      L4_2 = L4_2.TaxBusinessPercentagePerMonthForDelay
      L4_2 = L4_2(L5_2)
      if L4_2 then
        goto lbl_64
      end
    end
  end
  L4_2 = nil
  ::lbl_64::
  L3_2.taxBusinessPercentagePerMonthForDelay = L4_2
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "notifyStatus"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = tonumber
  L3_2 = A0_2.status
  L2_2 = L2_2(L3_2)
  disabledNotifySkillInfo = L2_2
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "closeStatisticsMenu"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "closeStatisticsMenu"
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "closePurchaseMenu"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  currentShop = nil
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "closePurchaseMenu"
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "buyProtein"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = buyProtein
  L3_2 = A0_2.name
  L2_2(L3_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "buyMembership"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = buyMembership
  L3_2 = A0_2.days
  L4_2 = A0_2.hours
  L2_2(L3_2, L4_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "closeMenu"
function L2_1(A0_2, A1_2)
  local L2_2
  L2_2 = closeManagementMenu
  L2_2()
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "closeManagementMenu"
function L2_1(A0_2, A1_2)
  local L2_2
  L2_2 = closeManagementMenu
  L2_2()
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "sendAnnouncement"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.text
  if L2_2 then
    L2_2 = TriggerServerEvent
    L3_2 = "flake_gym:sendAnnouncement"
    L4_2 = currentGymManagement
    L5_2 = A0_2.text
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "getClosestPlayers"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = CL
  L2_2 = L2_2.GetClosestPlayers
  L2_2 = L2_2()
  L3_2 = {}
  if not L2_2 then
    L4_2 = Config
    L4_2 = L4_2.Notification
    L5_2 = TRANSLATE
    L6_2 = "notify.employees:no_players_around"
    L5_2 = L5_2(L6_2)
    L6_2 = 3000
    L7_2 = "error"
    L4_2(L5_2, L6_2, L7_2)
    return
  end
  L4_2 = pairs
  L5_2 = L2_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = #L3_2
    L10_2 = L10_2 + 1
    L11_2 = GetPlayerServerId
    L12_2 = L9_2
    L11_2 = L11_2(L12_2)
    L3_2[L10_2] = L11_2
  end
  L4_2 = SendNUIMessage
  L5_2 = {}
  L5_2.action = "updateManagementMenu"
  L5_2.players = L3_2
  L4_2(L5_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "hireEmployee"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:hireAnEmployee"
  L4_2 = currentGymManagement
  L5_2 = A0_2.playerId
  L2_2(L3_2, L4_2, L5_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "bonusEmployee"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:bonusEmployee"
  L4_2 = currentGymManagement
  L5_2 = A0_2.identifier
  L6_2 = A0_2.bonusMoney
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "changeGradeEmployee"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:changeGradeEmployee"
  L4_2 = currentGymManagement
  L5_2 = A0_2.identifier
  L6_2 = A0_2.grade
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "fireEmployee"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:fireEmployee"
  L4_2 = currentGymManagement
  L5_2 = A0_2.identifier
  L2_2(L3_2, L4_2, L5_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "withdraw"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = tonumber
  L3_2 = A0_2.money
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = tonumber
    L3_2 = A0_2.money
    L2_2 = L2_2(L3_2)
    if L2_2 >= 1 then
      L2_2 = Config
      L2_2 = L2_2.UseBuildInCompanyBalance
      if not L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = Config
        L3_2 = L3_2.ESXSocietyEvents
        L3_2 = L3_2.withdraw
        L4_2 = Config
        L4_2 = L4_2.Gyms
        L5_2 = currentGymManagement
        L4_2 = L4_2[L5_2]
        L4_2 = L4_2.ownerJob
        L5_2 = tonumber
        L6_2 = A0_2.money
        L5_2, L6_2 = L5_2(L6_2)
        L2_2(L3_2, L4_2, L5_2, L6_2)
      else
        L2_2 = TriggerServerEvent
        L3_2 = "flake_gym:withdraw"
        L4_2 = currentGymManagement
        L5_2 = tonumber
        L6_2 = A0_2.money
        L5_2, L6_2 = L5_2(L6_2)
        L2_2(L3_2, L4_2, L5_2, L6_2)
      end
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "deposit"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = currentGymManagement
  if not L2_2 then
    return
  end
  L2_2 = tonumber
  L3_2 = A0_2.money
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = tonumber
    L3_2 = A0_2.money
    L2_2 = L2_2(L3_2)
    if L2_2 >= 1 then
      L2_2 = Config
      L2_2 = L2_2.UseBuildInCompanyBalance
      if not L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = Config
        L3_2 = L3_2.ESXSocietyEvents
        L3_2 = L3_2.deposit
        L4_2 = Config
        L4_2 = L4_2.Gyms
        L5_2 = currentGymManagement
        L4_2 = L4_2[L5_2]
        L4_2 = L4_2.ownerJob
        L5_2 = tonumber
        L6_2 = A0_2.money
        L5_2, L6_2 = L5_2(L6_2)
        L2_2(L3_2, L4_2, L5_2, L6_2)
      else
        L2_2 = TriggerServerEvent
        L3_2 = "flake_gym:deposit"
        L4_2 = currentGymManagement
        L5_2 = tonumber
        L6_2 = A0_2.money
        L5_2, L6_2 = L5_2(L6_2)
        L2_2(L3_2, L4_2, L5_2, L6_2)
      end
    end
  end
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "getClosestPlayersForMembership"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = CL
  L2_2 = L2_2.GetClosestPlayers
  L2_2 = L2_2()
  L3_2 = {}
  L4_2 = pairs
  L5_2 = L2_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    if L9_2 then
      L10_2 = #L3_2
      L10_2 = L10_2 + 1
      L11_2 = GetPlayerServerId
      L12_2 = L9_2
      L11_2 = L11_2(L12_2)
      L3_2[L10_2] = L11_2
    end
  end
  L4_2 = A1_2
  L5_2 = L3_2
  L4_2(L5_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "sellMembership"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = currentGymManagement
  if not L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L2_2 = currentGymManagement
  L1_2 = L1_2[L2_2]
  L2_2 = L1_2.requiredMembership
  if not L2_2 then
    return
  end
  L2_2 = L1_2.allowSellMembership
  if not L2_2 then
    return
  end
  L2_2 = nil
  L3_2 = pairs
  L4_2 = L1_2.memberships
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.days
    L10_2 = A0_2.days
    if L9_2 == L10_2 then
      L9_2 = L8_2.hours
      L10_2 = A0_2.hours
      if L9_2 == L10_2 then
        L2_2 = L8_2
        break
      end
    end
  end
  if not L2_2 then
    return
  end
  L3_2 = TriggerServerEvent
  L4_2 = "flake_gym:sv:sellMembership"
  L5_2 = A0_2.playerId
  L6_2 = currentGymManagement
  L7_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "sellProtein"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = currentGymManagement
  if not L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L2_2 = currentGymManagement
  L1_2 = L1_2[L2_2]
  L2_2 = L1_2.allowSellProteins
  if not L2_2 then
    return
  end
  L2_2 = L1_2.proteins
  if not L2_2 then
    return
  end
  L2_2 = L1_2.proteins
  L3_2 = A0_2.name
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:sv:sellProtein"
  L4_2 = A0_2.playerId
  L5_2 = currentGymManagement
  L6_2 = L1_2.proteins
  L7_2 = A0_2.name
  L6_2 = L6_2[L7_2]
  L7_2 = A0_2.count
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNUICallback
L1_1 = "bill"
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.action
  if "pay" == L2_2 then
    L2_2 = TriggerServerEvent
    L3_2 = "flake_gym:sv:payBill"
    L4_2 = "pay"
    L5_2 = A0_2.type
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = TriggerServerEvent
    L3_2 = "flake_gym:sv:payBill"
    L4_2 = "cancel"
    L2_2(L3_2, L4_2)
    L2_2 = SetNuiFocus
    L3_2 = false
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = SendNUIMessage
    L3_2 = {}
    L3_2.action = "closeReceipt"
    L2_2(L3_2)
    L2_2 = {}
    billCache = L2_2
  end
end
L0_1(L1_1, L2_1)
