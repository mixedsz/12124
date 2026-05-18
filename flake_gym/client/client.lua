local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1
waitingForLoadAfterRestart = false
currentGymManagement = nil
L0_1 = {}
stores = L0_1
L0_1 = {}
billCache = L0_1
L0_1 = {}
PlayerData = L0_1
disabledNotifySkillInfo = false
L0_1 = nil
L1_1 = nil
L2_1 = nil
L3_1 = nil
L4_1 = nil
myStatistics = nil
L5_1 = nil
L6_1 = {}
L7_1 = {}
conditionBooster = 1.0
strengthBooster = 1.0
removeStrength = true
currentShop = nil
L8_1 = Config
L8_1 = L8_1.Core
if "ESX" == L8_1 then
  L8_1 = Config
  L8_1 = L8_1.CoreExport
  L8_1 = L8_1()
  ESX = L8_1
else
  L8_1 = Config
  L8_1 = L8_1.Core
  if "QB-Core" == L8_1 then
    L8_1 = Config
    L8_1 = L8_1.CoreExport
    L8_1 = L8_1()
    QBCore = L8_1
  end
end
L8_1 = AddEventHandler
L9_1 = "onResourceStart"
function L10_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Core
  if "ESX" == L1_2 then
    while true do
      L1_2 = ESX
      if L1_2 then
        break
      end
      L1_2 = Citizen
      L1_2 = L1_2.Wait
      L2_2 = 200
      L1_2(L2_2)
    end
    L1_2 = ESX
    L1_2 = L1_2.IsPlayerLoaded
    L1_2 = L1_2()
    if L1_2 then
      L1_2 = ESX
      L1_2 = L1_2.GetPlayerData
      L1_2 = L1_2()
      PlayerData = L1_2
      waitingForLoadAfterRestart = true
      L1_2 = Citizen
      L1_2 = L1_2.Wait
      L2_2 = 2500
      L1_2(L2_2)
      L1_2 = TriggerServerEvent
      L2_2 = "flake_gym:sv:restartPlayer"
      L1_2(L2_2)
    end
  else
    L1_2 = Config
    L1_2 = L1_2.Core
    if "QB-Core" == L1_2 then
      while true do
        L1_2 = QBCore
        if L1_2 then
          break
        end
        L1_2 = Citizen
        L1_2 = L1_2.Wait
        L2_2 = 200
        L1_2(L2_2)
      end
      L1_2 = QBCore
      L1_2 = L1_2.Functions
      L1_2 = L1_2.GetPlayerData
      L1_2 = L1_2()
      if L1_2 then
        L1_2 = QBCore
        L1_2 = L1_2.Functions
        L1_2 = L1_2.GetPlayerData
        L1_2 = L1_2()
        L1_2 = L1_2.job
        if L1_2 then
          L1_2 = QBCore
          L1_2 = L1_2.Functions
          L1_2 = L1_2.GetPlayerData
          L1_2 = L1_2()
          PlayerData = L1_2
          waitingForLoadAfterRestart = true
          L1_2 = Citizen
          L1_2 = L1_2.Wait
          L2_2 = 2500
          L1_2(L2_2)
          L1_2 = TriggerServerEvent
          L2_2 = "flake_gym:sv:restartPlayer"
          L1_2(L2_2)
        end
      end
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = Config
L9_1 = L9_1.PlayerLoaded
L8_1(L9_1)
L8_1 = AddEventHandler
L9_1 = Config
L9_1 = L9_1.PlayerLoaded
function L10_1(A0_2)
  local L1_2, L2_2
  L1_2 = Config
  L1_2 = L1_2.Core
  L1_2 = A0_2 or L1_2
  if "ESX" ~= L1_2 or not A0_2 then
    L1_2 = Config
    L1_2 = L1_2.Core
    L1_2 = QBCore
    L1_2 = L1_2.Functions
    L1_2 = L1_2.GetPlayerData
    L1_2 = "QB-Core" == L1_2 and L1_2
  end
  PlayerData = L1_2
  waitingForLoadAfterRestart = true
  L1_2 = TriggerServerEvent
  L2_2 = "flake_gym:fetchData"
  L1_2(L2_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = Config
L9_1 = L9_1.JobUpdated
L8_1(L9_1)
L8_1 = AddEventHandler
L9_1 = Config
L9_1 = L9_1.JobUpdated
function L10_1(A0_2)
  local L1_2
  L1_2 = PlayerData
  L1_2.job = A0_2
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "vms_cityhall:updatedStatusResume"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Config
  L2_2 = L2_2.UseCityHallResumes
  if not L2_2 then
    return
  end
  L2_2 = currentGymManagement
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.Gyms
    L3_2 = currentGymManagement
    L2_2 = L2_2[L3_2]
    L2_2 = L2_2.ownerJob
    if L2_2 == A0_2 then
      L2_2 = SendNUIMessage
      L3_2 = {}
      L3_2.action = "updateManagementMenu"
      L3_2.isResumesAllowed = A1_2
      L2_2(L3_2)
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "vms_cityhall:updatedBusinessTaxes"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Config
  L2_2 = L2_2.UseCityHallTaxes
  if not L2_2 then
    return
  end
  L2_2 = currentGymManagement
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.Gyms
    L3_2 = currentGymManagement
    L2_2 = L2_2[L3_2]
    L2_2 = L2_2.ownerJob
    if L2_2 == A0_2 then
      L2_2 = SendNUIMessage
      L3_2 = {}
      L3_2.action = "updateManagementMenu"
      L3_2.taxes = A1_2
      L2_2(L3_2)
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:fetchedData"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  stores = A0_2
  L1_2 = Config
  L1_2 = L1_2.UseVMSCityHall
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.UseCityHallTaxes
    if L1_2 then
      L1_2 = pairs
      L2_2 = Config
      L2_2 = L2_2.Gyms
      L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
      for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
        L7_2 = L6_2.memberships
        if L7_2 then
          L7_2 = next
          L8_2 = L6_2.memberships
          L7_2 = L7_2(L8_2)
          if L7_2 then
            L7_2 = pairs
            L8_2 = L6_2.memberships
            L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
            for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
              L13_2 = exports
              L14_2 = Config
              L14_2 = L14_2.VMSCityHallResource
              L13_2 = L13_2[L14_2]
              L14_2 = L13_2
              L13_2 = L13_2.getTaxAmount
              L15_2 = L12_2.price
              L16_2 = "gym.memberships"
              L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2)
              L12_2.totalAmount = L13_2
              L12_2.taxAmount = L14_2
              L12_2.taxPercentage = L15_2
            end
          end
        end
        L7_2 = L6_2.proteins
        if L7_2 then
          L7_2 = next
          L8_2 = L6_2.proteins
          L7_2 = L7_2(L8_2)
          if L7_2 then
            L7_2 = pairs
            L8_2 = L6_2.proteins
            L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
            for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
              L13_2 = exports
              L14_2 = Config
              L14_2 = L14_2.VMSCityHallResource
              L13_2 = L13_2[L14_2]
              L14_2 = L13_2
              L13_2 = L13_2.getTaxAmount
              L15_2 = L12_2.price
              L16_2 = L6_2.tax
              if not L16_2 then
                L16_2 = "gym.proteins"
              end
              L13_2, L14_2, L15_2 = L13_2(L14_2, L15_2, L16_2)
              L12_2.totalAmount = L13_2
              L12_2.taxAmount = L14_2
              L12_2.taxPercentage = L15_2
            end
          end
        end
      end
    end
  end
  waitingForLoadAfterRestart = false
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:cl:getBill"
function L10_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2
  L4_2 = SetNuiFocus
  L5_2 = true
  L6_2 = true
  L4_2(L5_2, L6_2)
  if A1_2 then
    L4_2 = SendNUIMessage
    L5_2 = {}
    L5_2.action = "openReceipt"
    L5_2.membershipData = A1_2
    L4_2(L5_2)
  elseif A2_2 and A3_2 then
    L4_2 = SendNUIMessage
    L5_2 = {}
    L5_2.action = "openReceipt"
    L5_2.proteinsData = A2_2
    L5_2.count = A3_2
    L4_2(L5_2)
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:cl:getBillFeedback"
function L10_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "closeReceipt"
  L0_2(L1_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:updateBusiness"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = stores
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    return
  end
  L3_2 = 0
  if A2_2 then
    L4_2 = A2_2.sub
    if L4_2 then
      L4_2 = A2_2.sub
      if "balance" ~= L4_2 then
        L4_2 = A2_2.sub
        if "totalEarned" ~= L4_2 then
          goto lbl_34
        end
      end
      L4_2 = A2_2.sub
      if "balance" == L4_2 then
        L4_2 = Config
        L4_2 = L4_2.UseBuildInCompanyBalance
        if not L4_2 then
          L3_2 = A2_2.value
      end
      else
        L4_2 = stores
        L4_2 = L4_2[A0_2]
        L4_2 = L4_2.data
        L5_2 = A2_2.sub
        L6_2 = A2_2.value
        L4_2[L5_2] = L6_2
        goto lbl_74
      end
      ::lbl_34::
      L4_2 = stores
      L4_2 = L4_2[A0_2]
      L5_2 = A2_2.sub
      L6_2 = A2_2.value
      L4_2[L5_2] = L6_2
    else
      L4_2 = pairs
      L5_2 = A2_2
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
        L10_2 = L9_2.sub
        if "data" == L10_2 then
          L10_2 = stores
          L10_2 = L10_2[A0_2]
          L11_2 = L9_2.sub
          L12_2 = L9_2.value
          L10_2[L11_2] = L12_2
        else
          L10_2 = L9_2.sub
          if "balance" == L10_2 then
            L10_2 = Config
            L10_2 = L10_2.UseBuildInCompanyBalance
            if not L10_2 then
              L3_2 = L9_2.value
          end
          else
            L10_2 = stores
            L10_2 = L10_2[A0_2]
            L10_2 = L10_2.data
            L11_2 = L9_2.sub
            L12_2 = L9_2.value
            L10_2[L11_2] = L12_2
          end
        end
      end
    end
  else
    L4_2 = stores
    L4_2[A0_2] = A1_2
  end
  ::lbl_74::
  L4_2 = currentGymManagement
  if L4_2 then
    L4_2 = currentGymManagement
    if L4_2 == A0_2 then
      if A2_2 then
        L4_2 = A2_2.sub
        if L4_2 then
          L4_2 = A2_2.sub
          if "employees" == L4_2 then
            L4_2 = CL
            L4_2 = L4_2.GetEmployees
            function L5_2(A0_3)
              local L1_3, L2_3, L3_3, L4_3
              L1_3 = SendNUIMessage
              L2_3 = {}
              L2_3.action = "updateManagementMenu"
              L3_3 = stores
              L4_3 = currentGymManagement
              L3_3 = L3_3[L4_3]
              L2_3.storeData = L3_3
              L2_3.employees = A0_3
              L3_3 = #A0_3
              L2_3.employeesCount = L3_3
              L1_3(L2_3)
            end
            L6_2 = Config
            L6_2 = L6_2.Gyms
            L7_2 = currentGymManagement
            L6_2 = L6_2[L7_2]
            L6_2 = L6_2.ownerJob
            L4_2(L5_2, L6_2)
        end
      end
      else
        L4_2 = SendNUIMessage
        L5_2 = {}
        L5_2.action = "updateManagementMenu"
        L6_2 = stores
        L7_2 = currentGymManagement
        L6_2 = L6_2[L7_2]
        L5_2.storeData = L6_2
        L6_2 = Config
        L6_2 = L6_2.UseBuildInCompanyBalance
        if not L6_2 then
          L6_2 = tonumber
          L7_2 = L3_2
          L6_2 = L6_2(L7_2)
          if L6_2 then
            L6_2 = tostring
            L7_2 = L3_2
            L6_2 = L6_2(L7_2)
            if L6_2 then
              goto lbl_121
            end
          end
        end
        L6_2 = nil
        ::lbl_121::
        L5_2.societyBalance = L6_2
        L4_2(L5_2)
      end
    end
  end
end
L8_1(L9_1, L10_1)
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = waitingForLoadAfterRestart
  if L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L1_2 = L1_2[A0_2]
  L2_2 = Config
  L2_2 = L2_2.UseVMSCityHall
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.Core
    if "ESX" == L2_2 then
      L2_2 = ESX
      L2_2 = L2_2.TriggerServerCallback
      L3_2 = "vms_cityhall:getBusinessData"
      function L4_2(A0_3, A1_3)
        local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
        L2_3 = A0_3
        L3_3 = A1_3
        L4_3 = CL
        L4_3 = L4_3.GetEmployees
        function L5_3(A0_4)
          local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
          L1_4 = A0_2
          currentGymManagement = L1_4
          L1_4 = SendNUIMessage
          L2_4 = {}
          L2_4.action = "openManagementMenu"
          L3_4 = stores
          L4_4 = A0_2
          L3_4 = L3_4[L4_4]
          L2_4.storeData = L3_4
          L3_4 = Config
          L3_4 = L3_4.Gyms
          L4_4 = A0_2
          L3_4 = L3_4[L4_4]
          L2_4.storeCfg = L3_4
          L2_4.employees = A0_4
          L3_4 = #A0_4
          L2_4.employeesCount = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsEmployee
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L3_4 = L3_4(L4_4)
          L2_4.isEmployee = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsManager
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.isManager = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsBoss
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.isBoss = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsAllowedCityhall
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.cityhallGrades = L3_4
          L3_4 = L1_2.requiredMembership
          if L3_4 then
            L3_4 = L1_2.allowSellMembership
            if L3_4 then
              L3_4 = L1_2.memberships
              if L3_4 then
                goto lbl_68
              end
            end
          end
          L3_4 = nil
          ::lbl_68::
          L2_4.membershipsList = L3_4
          L3_4 = L1_2.allowSellProteins
          if L3_4 then
            L3_4 = L1_2.proteins
            if L3_4 then
              goto lbl_76
            end
          end
          L3_4 = nil
          ::lbl_76::
          L2_4.proteinsList = L3_4
          L3_4 = Config
          L3_4 = L3_4.UseCityHallResumes
          if L3_4 then
            L3_4 = exports
            L4_4 = Config
            L4_4 = L4_4.VMSCityHallResource
            L3_4 = L3_4[L4_4]
            L4_4 = L3_4
            L3_4 = L3_4.isResumesAllowed
            L5_4 = Config
            L5_4 = L5_4.Gyms
            L6_4 = A0_2
            L5_4 = L5_4[L6_4]
            L5_4 = L5_4.ownerJob
            L3_4 = L3_4(L4_4, L5_4)
            if L3_4 then
              goto lbl_95
            end
          end
          L3_4 = false
          ::lbl_95::
          L2_4.isResumesAllowed = L3_4
          L3_4 = L2_3
          L2_4.resumes = L3_4
          L3_4 = Config
          L3_4 = L3_4.UseCityHallTaxes
          L2_4.isTaxesAllowed = L3_4
          L3_4 = L3_3
          L2_4.taxes = L3_4
          L1_4(L2_4)
        end
        L6_3 = Config
        L6_3 = L6_3.Gyms
        L7_3 = A0_2
        L6_3 = L6_3[L7_3]
        L6_3 = L6_3.ownerJob
        L4_3(L5_3, L6_3)
      end
      L5_2 = Config
      L5_2 = L5_2.UseCityHallResumes
      L6_2 = Config
      L6_2 = L6_2.UseCityHallTaxes
      L2_2(L3_2, L4_2, L5_2, L6_2)
    else
      L2_2 = QBCore
      L2_2 = L2_2.Functions
      L2_2 = L2_2.TriggerCallback
      L3_2 = "vms_cityhall:getBusinessData"
      function L4_2(A0_3, A1_3)
        local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
        L2_3 = A0_3
        L3_3 = A1_3
        L4_3 = CL
        L4_3 = L4_3.GetEmployees
        function L5_3(A0_4)
          local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
          L1_4 = A0_2
          currentGymManagement = L1_4
          L1_4 = SendNUIMessage
          L2_4 = {}
          L2_4.action = "openManagementMenu"
          L3_4 = stores
          L4_4 = A0_2
          L3_4 = L3_4[L4_4]
          L2_4.storeData = L3_4
          L3_4 = Config
          L3_4 = L3_4.Gyms
          L4_4 = A0_2
          L3_4 = L3_4[L4_4]
          L2_4.storeCfg = L3_4
          L2_4.employees = A0_4
          L3_4 = #A0_4
          L2_4.employeesCount = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsEmployee
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L3_4 = L3_4(L4_4)
          L2_4.isEmployee = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsManager
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.isManager = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsBoss
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.isBoss = L3_4
          L3_4 = CL
          L3_4 = L3_4.IsAllowedCityhall
          L4_4 = Config
          L4_4 = L4_4.Gyms
          L5_4 = A0_2
          L4_4 = L4_4[L5_4]
          L4_4 = L4_4.ownerJob
          L5_4 = A0_2
          L3_4 = L3_4(L4_4, L5_4)
          L2_4.cityhallGrades = L3_4
          L3_4 = L1_2.requiredMembership
          if L3_4 then
            L3_4 = L1_2.allowSellMembership
            if L3_4 then
              L3_4 = L1_2.memberships
              if L3_4 then
                goto lbl_68
              end
            end
          end
          L3_4 = nil
          ::lbl_68::
          L2_4.membershipsList = L3_4
          L3_4 = L1_2.allowSellProteins
          if L3_4 then
            L3_4 = L1_2.proteins
            if L3_4 then
              goto lbl_76
            end
          end
          L3_4 = nil
          ::lbl_76::
          L2_4.proteinsList = L3_4
          L3_4 = Config
          L3_4 = L3_4.UseCityHallResumes
          if L3_4 then
            L3_4 = exports
            L4_4 = Config
            L4_4 = L4_4.VMSCityHallResource
            L3_4 = L3_4[L4_4]
            L4_4 = L3_4
            L3_4 = L3_4.isResumesAllowed
            L5_4 = Config
            L5_4 = L5_4.Gyms
            L6_4 = A0_2
            L5_4 = L5_4[L6_4]
            L5_4 = L5_4.ownerJob
            L3_4 = L3_4(L4_4, L5_4)
            if L3_4 then
              goto lbl_95
            end
          end
          L3_4 = false
          ::lbl_95::
          L2_4.isResumesAllowed = L3_4
          L3_4 = L2_3
          L2_4.resumes = L3_4
          L3_4 = Config
          L3_4 = L3_4.UseCityHallTaxes
          L2_4.isTaxesAllowed = L3_4
          L3_4 = L3_3
          L2_4.taxes = L3_4
          L1_4(L2_4)
        end
        L6_3 = Config
        L6_3 = L6_3.Gyms
        L7_3 = A0_2
        L6_3 = L6_3[L7_3]
        L6_3 = L6_3.ownerJob
        L4_3(L5_3, L6_3)
      end
      L5_2 = Config
      L5_2 = L5_2.UseCityHallResumes
      L6_2 = Config
      L6_2 = L6_2.UseCityHallTaxes
      L2_2(L3_2, L4_2, L5_2, L6_2)
    end
  else
    L2_2 = CL
    L2_2 = L2_2.GetEmployees
    function L3_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3
      L1_3 = A0_2
      currentGymManagement = L1_3
      L1_3 = SendNUIMessage
      L2_3 = {}
      L2_3.action = "openManagementMenu"
      L3_3 = stores
      L4_3 = A0_2
      L3_3 = L3_3[L4_3]
      L2_3.storeData = L3_3
      L3_3 = Config
      L3_3 = L3_3.Gyms
      L4_3 = A0_2
      L3_3 = L3_3[L4_3]
      L2_3.storeCfg = L3_3
      L2_3.employees = A0_3
      L3_3 = #A0_3
      L2_3.employeesCount = L3_3
      L3_3 = CL
      L3_3 = L3_3.IsEmployee
      L4_3 = Config
      L4_3 = L4_3.Gyms
      L5_3 = A0_2
      L4_3 = L4_3[L5_3]
      L4_3 = L4_3.ownerJob
      L3_3 = L3_3(L4_3)
      L2_3.isEmployee = L3_3
      L3_3 = CL
      L3_3 = L3_3.IsManager
      L4_3 = Config
      L4_3 = L4_3.Gyms
      L5_3 = A0_2
      L4_3 = L4_3[L5_3]
      L4_3 = L4_3.ownerJob
      L5_3 = A0_2
      L3_3 = L3_3(L4_3, L5_3)
      L2_3.isManager = L3_3
      L3_3 = CL
      L3_3 = L3_3.IsBoss
      L4_3 = Config
      L4_3 = L4_3.Gyms
      L5_3 = A0_2
      L4_3 = L4_3[L5_3]
      L4_3 = L4_3.ownerJob
      L5_3 = A0_2
      L3_3 = L3_3(L4_3, L5_3)
      L2_3.isBoss = L3_3
      L3_3 = L1_2.requiredMembership
      if L3_3 then
        L3_3 = L1_2.allowSellMembership
        if L3_3 then
          L3_3 = L1_2.memberships
          if L3_3 then
            goto lbl_58
          end
        end
      end
      L3_3 = nil
      ::lbl_58::
      L2_3.membershipsList = L3_3
      L3_3 = L1_2.allowSellProteins
      if L3_3 then
        L3_3 = L1_2.proteins
        if L3_3 then
          goto lbl_66
        end
      end
      L3_3 = nil
      ::lbl_66::
      L2_3.proteinsList = L3_3
      L1_3(L2_3)
    end
    L4_2 = Config
    L4_2 = L4_2.Gyms
    L4_2 = L4_2[A0_2]
    L4_2 = L4_2.ownerJob
    L2_2(L3_2, L4_2)
  end
  L2_2 = SetNuiFocus
  L3_2 = true
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = Config
  L2_2 = L2_2.UseBuildInCompanyBalance
  if not L2_2 then
    L2_2 = Citizen
    L2_2 = L2_2.Wait
    L3_2 = 300
    L2_2(L3_2)
    L2_2 = TriggerServerEvent
    L3_2 = Config
    L3_2 = L3_2.ESXSocietyEvents
    L3_2 = L3_2.check
    L4_2 = Config
    L4_2 = L4_2.Gyms
    L4_2 = L4_2[A0_2]
    L4_2 = L4_2.ownerJob
    L2_2(L3_2, L4_2)
  end
end
openBossMenu = L8_1
function L8_1()
  local L0_2, L1_2, L2_2
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "closeManagementMenu"
  L0_2(L1_2)
  currentBarberManagement = nil
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
end
closeManagementMenu = L8_1
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:cl:getMemberships"
L8_1(L9_1)
L8_1 = AddEventHandler
L9_1 = "flake_gym:cl:getMemberships"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L6_1 = A0_2
  L1_2 = {}
  L7_1 = L1_2
  L1_2 = pairs
  L2_2 = L6_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L8_2 = L6_2.name
    L7_2 = L7_1
    L9_2 = L6_2.time
    L7_2[L8_2] = L9_2
  end
  L1_2 = currentShop
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.Gyms
    L2_2 = currentShop
    L1_2 = L1_2[L2_2]
    L1_2 = L1_2.requiredMembership
    if L1_2 then
      L1_2 = SendNUIMessage
      L2_2 = {}
      L2_2.action = "updatePurchaseMenu"
      L2_2.type = "membership"
      L3_2 = Config
      L3_2 = L3_2.Gyms
      L4_2 = currentShop
      L3_2 = L3_2[L4_2]
      L4_2 = L3_2.requiredMembership
      L3_2 = L7_1
      L3_2 = L3_2[L4_2]
      L2_2.myMembership = L3_2
      L1_2(L2_2)
    end
  end
end
L8_1(L9_1, L10_1)
function L8_1(A0_2)
  local L1_2, L2_2
  while true do
    L1_2 = HasAnimDictLoaded
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      break
    end
    L1_2 = RequestAnimDict
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = Wait
    L2_2 = 5
    L1_2(L2_2)
  end
end
loadAnimDict = L8_1
function L8_1(A0_2)
  local L1_2, L2_2
  L1_2 = RequestModel
  L2_2 = A0_2
  L1_2(L2_2)
  while true do
    L1_2 = HasModelLoaded
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      break
    end
    L1_2 = Citizen
    L1_2 = L1_2.Wait
    L2_2 = 100
    L1_2(L2_2)
    L1_2 = RequestModel
    L2_2 = A0_2
    L1_2(L2_2)
  end
end
requestProp = L8_1
L8_1 = Citizen
L8_1 = L8_1.CreateThread
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L0_2 = Citizen
  L0_2 = L0_2.Wait
  L1_2 = 250
  L0_2(L1_2)
  L0_2 = pairs
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = L5_2.blipCoords
    if L6_2 then
      L6_2 = L5_2.blipEnabled
      if L6_2 then
        L6_2 = AddBlipForCoord
        L7_2 = L5_2.blipCoords
        L6_2 = L6_2(L7_2)
        L5_2._createdBlip = L6_2
        L6_2 = SetBlipSprite
        L7_2 = L5_2._createdBlip
        L8_2 = Config
        L8_2 = L8_2.Blip
        L8_2 = L8_2.Sprite
        L6_2(L7_2, L8_2)
        L6_2 = SetBlipDisplay
        L7_2 = L5_2._createdBlip
        L8_2 = Config
        L8_2 = L8_2.Blip
        L8_2 = L8_2.Display
        L6_2(L7_2, L8_2)
        L6_2 = SetBlipScale
        L7_2 = L5_2._createdBlip
        L8_2 = Config
        L8_2 = L8_2.Blip
        L8_2 = L8_2.Scale
        L6_2(L7_2, L8_2)
        L6_2 = SetBlipColour
        L7_2 = L5_2._createdBlip
        L8_2 = Config
        L8_2 = L8_2.Blip
        L8_2 = L8_2.Color
        L6_2(L7_2, L8_2)
        L6_2 = SetBlipAsShortRange
        L7_2 = L5_2._createdBlip
        L8_2 = true
        L6_2(L7_2, L8_2)
        L6_2 = BeginTextCommandSetBlipName
        L7_2 = "STRING"
        L6_2(L7_2)
        L6_2 = AddTextComponentString
        L7_2 = L5_2.blipName
        L6_2(L7_2)
        L6_2 = EndTextCommandSetBlipName
        L7_2 = L5_2._createdBlip
        L6_2(L7_2)
      end
    end
  end
  L0_2 = Config
  L0_2 = L0_2.UseTarget
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.TargetResource
    if "ox_target" == L0_2 then
      goto lbl_72
    end
  end
  L0_2 = Config
  L0_2 = L0_2.Menu
  ::lbl_72::
  if "ox_lib" == L0_2 then
    L0_2 = LoadResourceFile
    L1_2 = "ox_lib"
    L2_2 = "init.lua"
    L0_2 = L0_2(L1_2, L2_2)
    L1_2 = assert
    L2_2 = load
    L3_2 = L0_2
    L4_2 = "@@ox_lib/init.lua"
    L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L2_2(L3_2, L4_2)
    L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L2_2 = L1_2
    L2_2()
  end
  L0_2 = Config
  L0_2 = L0_2.UseTarget
  if L0_2 then
    L0_2 = pairs
    L1_2 = Config
    L1_2 = L1_2.Gyms
    L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
    for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
      L6_2 = L5_2.business
      if L6_2 then
        L6_2 = L5_2.ownerJob
        if L6_2 then
          L6_2 = L5_2.bossMenu
          if L6_2 then
            L6_2 = L5_2.bossMenu
            L7_2 = CL
            L7_2 = L7_2.Target
            L8_2 = {}
            L8_2.name = "bossmenu"
            L9_2 = L5_2.bossMenu
            L9_2 = L9_2.targetCoords
            L8_2.coords = L9_2
            L9_2 = L5_2.bossMenu
            L9_2 = L9_2.targetSize
            L8_2.size = L9_2
            L9_2 = L5_2.ownerJob
            L8_2.job = L9_2
            L9_2 = TRANSLATE
            L10_2 = "target.boss_menu"
            L9_2 = L9_2(L10_2)
            L8_2.label = L9_2
            L8_2.icon = "fa-solid fa-dollar-sign"
            function L9_2()
              local L0_3, L1_3
              L0_3 = openBossMenu
              L1_3 = L4_2
              L0_3(L1_3)
            end
            L7_2 = L7_2(L8_2, L9_2)
            L6_2.targetId = L7_2
          end
        end
      end
      L6_2 = L5_2.shopMenu
      if L6_2 then
        L6_2 = L5_2.allowBuyMembership
        if L6_2 then
          L6_2 = L5_2.requiredMembership
          if L6_2 then
            goto lbl_136
          end
        end
      end
      L6_2 = L5_2.allowBuyProteins
      ::lbl_136::
      if L6_2 then
        L6_2 = L5_2.shopMenu
        L7_2 = CL
        L7_2 = L7_2.Target
        L8_2 = {}
        L8_2.name = "shopmenu"
        L9_2 = L5_2.shopMenu
        L9_2 = L9_2.targetCoords
        L8_2.coords = L9_2
        L9_2 = L5_2.shopMenu
        L9_2 = L9_2.targetSize
        L8_2.size = L9_2
        L9_2 = TRANSLATE
        L10_2 = "target.shop_menu"
        L9_2 = L9_2(L10_2)
        L8_2.label = L9_2
        L8_2.icon = "fa-solid fa-dollar-sign"
        function L9_2()
          local L0_3, L1_3
          L0_3 = openPurchaseMenu
          L1_3 = L4_2
          L0_3(L1_3)
        end
        L7_2 = L7_2(L8_2, L9_2)
        L6_2.targetId = L7_2
      end
      L6_2 = pairs
      L7_2 = L5_2.points
      L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
      for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
        L12_2 = CL
        L12_2 = L12_2.Target
        L13_2 = {}
        L14_2 = L11_2.name
        L13_2.name = L14_2
        L14_2 = L11_2.activityCoord
        L13_2.coords = L14_2
        L14_2 = L11_2.targetSize
        L13_2.size = L14_2
        L14_2 = TRANSLATE
        L15_2 = "target."
        L16_2 = L11_2.name
        L15_2 = L15_2 .. L16_2
        L14_2 = L14_2(L15_2)
        L13_2.label = L14_2
        L13_2.icon = "fa-solid fa-dumbbell"
        function L14_2()
          local L0_3, L1_3, L2_3, L3_3
          L0_3 = startAction
          L1_3 = L4_2
          L2_3 = L10_2
          L3_3 = L11_2
          L0_3(L1_3, L2_3, L3_3)
        end
        L12_2 = L12_2(L13_2, L14_2)
        L11_2.targetId = L12_2
      end
    end
  end
end
L8_1(L9_1)
L8_1 = Citizen
L8_1 = L8_1.CreateThread
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2
  L0_2 = false
  L1_2 = false
  L2_2 = true
  while true do
    L3_2 = Config
    L3_2 = L3_2.UseTarget
    if L3_2 then
      break
    end
    L0_2 = false
    L2_2 = true
    L3_2 = PlayerPedId
    L3_2 = L3_2()
    L4_2 = GetEntityCoords
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L5_2 = pairs
    L6_2 = Config
    L6_2 = L6_2.Gyms
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
    for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
      L11_2 = L10_2.blipCoords
      L11_2 = L4_2 - L11_2
      L11_2 = #L11_2
      if L11_2 < 45.0 then
        L2_2 = false
        L12_2 = pairs
        L13_2 = L10_2.points
        L12_2, L13_2, L14_2, L15_2 = L12_2(L13_2)
        for L16_2, L17_2 in L12_2, L13_2, L14_2, L15_2 do
          L18_2 = L17_2.taken
          if not L18_2 then
            L18_2 = vec
            L19_2 = L17_2.position
            L19_2 = L19_2.x
            L20_2 = L17_2.position
            L20_2 = L20_2.y
            L21_2 = L17_2.position
            L21_2 = L21_2.z
            L18_2 = L18_2(L19_2, L20_2, L21_2)
            L18_2 = L4_2 - L18_2
            L18_2 = #L18_2
            L19_2 = Config
            L19_2 = L19_2.DistanceView
            if L18_2 < L19_2 then
              L19_2 = Config
              L19_2 = L19_2.UseMarkers
              if L19_2 then
                L19_2 = DrawMarker
                L20_2 = Config
                L20_2 = L20_2.Markers
                L20_2 = L20_2.FreeSeat
                L20_2 = L20_2.id
                L21_2 = vec
                L22_2 = L17_2.position
                L22_2 = L22_2.x
                L23_2 = L17_2.position
                L23_2 = L23_2.y
                L24_2 = L17_2.position
                L24_2 = L24_2.z
                L21_2 = L21_2(L22_2, L23_2, L24_2)
                L22_2 = 0
                L23_2 = 0
                L24_2 = 0
                L25_2 = Config
                L25_2 = L25_2.Markers
                L25_2 = L25_2.FreeSeat
                L25_2 = L25_2.rotation
                L25_2 = L25_2[1]
                L26_2 = Config
                L26_2 = L26_2.Markers
                L26_2 = L26_2.FreeSeat
                L26_2 = L26_2.rotation
                L26_2 = L26_2[2]
                L27_2 = Config
                L27_2 = L27_2.Markers
                L27_2 = L27_2.FreeSeat
                L27_2 = L27_2.rotation
                L27_2 = L27_2[3]
                L28_2 = Config
                L28_2 = L28_2.Markers
                L28_2 = L28_2.FreeSeat
                L28_2 = L28_2.size
                L29_2 = Config
                L29_2 = L29_2.Markers
                L29_2 = L29_2.FreeSeat
                L29_2 = L29_2.color
                L29_2 = L29_2[1]
                L30_2 = Config
                L30_2 = L30_2.Markers
                L30_2 = L30_2.FreeSeat
                L30_2 = L30_2.color
                L30_2 = L30_2[2]
                L31_2 = Config
                L31_2 = L31_2.Markers
                L31_2 = L31_2.FreeSeat
                L31_2 = L31_2.color
                L31_2 = L31_2[3]
                L32_2 = Config
                L32_2 = L32_2.Markers
                L32_2 = L32_2.FreeSeat
                L32_2 = L32_2.color
                L32_2 = L32_2[4]
                L33_2 = Config
                L33_2 = L33_2.Markers
                L33_2 = L33_2.FreeSeat
                L33_2 = L33_2.bobUpAndDown
                L34_2 = false
                L35_2 = false
                L36_2 = Config
                L36_2 = L36_2.Markers
                L36_2 = L36_2.FreeSeat
                L36_2 = L36_2.rotate
                L37_2 = false
                L38_2 = false
                L39_2 = false
                L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
              end
              L19_2 = Config
              L19_2 = L19_2.Use3DText
              if L19_2 then
                L19_2 = DrawText3D
                L20_2 = L17_2.position
                L20_2 = L20_2.x
                L21_2 = L17_2.position
                L21_2 = L21_2.y
                L22_2 = L17_2.position
                L22_2 = L22_2.z
                L23_2 = TRANSLATE
                L24_2 = "3dtext."
                L25_2 = L17_2.name
                L24_2 = L24_2 .. L25_2
                L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L23_2(L24_2)
                L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
              end
              L19_2 = 1.25
              if L18_2 < L19_2 then
                L19_2 = TRANSLATE
                L20_2 = "textui."
                L21_2 = L17_2.name
                L20_2 = L20_2 .. L21_2
                L19_2 = L19_2(L20_2)
                L0_2 = L19_2
                L19_2 = Config
                L19_2 = L19_2.Core
                if "ESX" == L19_2 then
                  L19_2 = CL
                  L19_2 = L19_2.TextUI
                  L19_2 = L19_2.Enabled
                  if not L19_2 then
                    L19_2 = Config
                    L19_2 = L19_2.UseHelpNotify
                    if L19_2 then
                      L19_2 = ESX
                      L19_2 = L19_2.ShowHelpNotification
                      L20_2 = TRANSLATE
                      L21_2 = "help."
                      L22_2 = L17_2.name
                      L21_2 = L21_2 .. L22_2
                      L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L20_2(L21_2)
                      L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
                    end
                  end
                end
                L19_2 = IsControlJustPressed
                L20_2 = 0
                L21_2 = Config
                L21_2 = L21_2.Keys
                L21_2 = L21_2.enter
                L19_2 = L19_2(L20_2, L21_2)
                if L19_2 then
                  L19_2 = startAction
                  L20_2 = L9_2
                  L21_2 = L16_2
                  L22_2 = L17_2
                  L19_2(L20_2, L21_2, L22_2)
                  L0_2 = false
                end
              end
            end
          end
        end
      end
      L12_2 = L10_2.business
      if L12_2 then
        L12_2 = L10_2.bossMenu
        if L12_2 then
          L12_2 = L10_2.bossMenu
          L12_2 = L12_2.coords
          if L12_2 then
            L12_2 = L10_2.bossMenu
            L12_2 = L12_2.coords
            L12_2 = L12_2.xyz
            L12_2 = L4_2 - L12_2
            L12_2 = #L12_2
            L13_2 = Config
            L13_2 = L13_2.DistanceView
            if L12_2 < L13_2 then
              L13_2 = PlayerData
              if L13_2 then
                L13_2 = PlayerData
                L13_2 = L13_2.job
                if L13_2 then
                  L13_2 = CL
                  L13_2 = L13_2.IsEmployee
                  L14_2 = L10_2.ownerJob
                  L13_2 = L13_2(L14_2)
                  if L13_2 then
                    L2_2 = false
                    L13_2 = Config
                    L13_2 = L13_2.UseMarkers
                    if L13_2 then
                      L13_2 = DrawMarker
                      L14_2 = Config
                      L14_2 = L14_2.Markers
                      L14_2 = L14_2.BossMenu
                      L14_2 = L14_2.id
                      L15_2 = L10_2.bossMenu
                      L15_2 = L15_2.coords
                      L15_2 = L15_2.xyz
                      L16_2 = 0.0
                      L17_2 = 0.0
                      L18_2 = 0.0
                      L19_2 = 0.0
                      L20_2 = 0.0
                      L21_2 = 0.0
                      L22_2 = Config
                      L22_2 = L22_2.Markers
                      L22_2 = L22_2.BossMenu
                      L22_2 = L22_2.size
                      L23_2 = Config
                      L23_2 = L23_2.Markers
                      L23_2 = L23_2.BossMenu
                      L23_2 = L23_2.color
                      L23_2 = L23_2[1]
                      L24_2 = Config
                      L24_2 = L24_2.Markers
                      L24_2 = L24_2.BossMenu
                      L24_2 = L24_2.color
                      L24_2 = L24_2[2]
                      L25_2 = Config
                      L25_2 = L25_2.Markers
                      L25_2 = L25_2.BossMenu
                      L25_2 = L25_2.color
                      L25_2 = L25_2[3]
                      L26_2 = Config
                      L26_2 = L26_2.Markers
                      L26_2 = L26_2.BossMenu
                      L26_2 = L26_2.color
                      L26_2 = L26_2[4]
                      L27_2 = Config
                      L27_2 = L27_2.Markers
                      L27_2 = L27_2.BossMenu
                      L27_2 = L27_2.bobUpAndDown
                      L28_2 = false
                      L29_2 = false
                      L30_2 = Config
                      L30_2 = L30_2.Markers
                      L30_2 = L30_2.BossMenu
                      L30_2 = L30_2.rotate
                      L31_2 = false
                      L32_2 = false
                      L33_2 = false
                      L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
                    end
                    L13_2 = Config
                    L13_2 = L13_2.Use3DText
                    if L13_2 then
                      L13_2 = DrawText3D
                      L14_2 = L10_2.bossMenu
                      L14_2 = L14_2.coords
                      L14_2 = L14_2.x
                      L15_2 = L10_2.bossMenu
                      L15_2 = L15_2.coords
                      L15_2 = L15_2.y
                      L16_2 = L10_2.bossMenu
                      L16_2 = L16_2.coords
                      L16_2 = L16_2.z
                      L17_2 = TRANSLATE
                      L18_2 = "3dtext.boss_menu"
                      L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L17_2(L18_2)
                      L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
                    end
                    L13_2 = Config
                    L13_2 = L13_2.DistanceAccess
                    if L12_2 < L13_2 then
                      L13_2 = TRANSLATE
                      L14_2 = "textui.boss_menu"
                      L13_2 = L13_2(L14_2)
                      L0_2 = L13_2
                      L13_2 = Config
                      L13_2 = L13_2.Core
                      if "ESX" == L13_2 then
                        L13_2 = CL
                        L13_2 = L13_2.TextUI
                        L13_2 = L13_2.Enabled
                        if not L13_2 then
                          L13_2 = Config
                          L13_2 = L13_2.UseHelpNotify
                          if L13_2 then
                            L13_2 = ESX
                            L13_2 = L13_2.ShowHelpNotification
                            L14_2 = TRANSLATE
                            L15_2 = "help.boss_menu"
                            L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L14_2(L15_2)
                            L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
                          end
                        end
                      end
                      L13_2 = IsControlJustPressed
                      L14_2 = 0
                      L15_2 = 38
                      L13_2 = L13_2(L14_2, L15_2)
                      if L13_2 then
                        L13_2 = openBossMenu
                        L14_2 = L9_2
                        L13_2(L14_2)
                        L0_2 = false
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      L12_2 = L10_2.shopMenu
      if L12_2 then
        L12_2 = L10_2.shopMenu
        L12_2 = L12_2.coords
        if L12_2 then
          L12_2 = L10_2.allowBuyMembership
          if not L12_2 then
            L12_2 = L10_2.allowBuyProteins
            if not L12_2 then
              goto lbl_466
            end
          end
          L12_2 = L10_2.shopMenu
          L12_2 = L12_2.coords
          L12_2 = L12_2.xyz
          L12_2 = L4_2 - L12_2
          L12_2 = #L12_2
          L13_2 = Config
          L13_2 = L13_2.DistanceView
          if L12_2 < L13_2 then
            L2_2 = false
            L13_2 = Config
            L13_2 = L13_2.UseMarkers
            if L13_2 then
              L13_2 = DrawMarker
              L14_2 = Config
              L14_2 = L14_2.Markers
              L14_2 = L14_2.ShopMenu
              L14_2 = L14_2.id
              L15_2 = L10_2.shopMenu
              L15_2 = L15_2.coords
              L15_2 = L15_2.xyz
              L16_2 = 0.0
              L17_2 = 0.0
              L18_2 = 0.0
              L19_2 = 0.0
              L20_2 = 0.0
              L21_2 = 0.0
              L22_2 = Config
              L22_2 = L22_2.Markers
              L22_2 = L22_2.ShopMenu
              L22_2 = L22_2.size
              L23_2 = Config
              L23_2 = L23_2.Markers
              L23_2 = L23_2.ShopMenu
              L23_2 = L23_2.color
              L23_2 = L23_2[1]
              L24_2 = Config
              L24_2 = L24_2.Markers
              L24_2 = L24_2.ShopMenu
              L24_2 = L24_2.color
              L24_2 = L24_2[2]
              L25_2 = Config
              L25_2 = L25_2.Markers
              L25_2 = L25_2.ShopMenu
              L25_2 = L25_2.color
              L25_2 = L25_2[3]
              L26_2 = Config
              L26_2 = L26_2.Markers
              L26_2 = L26_2.ShopMenu
              L26_2 = L26_2.color
              L26_2 = L26_2[4]
              L27_2 = Config
              L27_2 = L27_2.Markers
              L27_2 = L27_2.ShopMenu
              L27_2 = L27_2.bobUpAndDown
              L28_2 = false
              L29_2 = false
              L30_2 = Config
              L30_2 = L30_2.Markers
              L30_2 = L30_2.ShopMenu
              L30_2 = L30_2.rotate
              L31_2 = false
              L32_2 = false
              L33_2 = false
              L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2)
            end
            L13_2 = Config
            L13_2 = L13_2.Use3DText
            if L13_2 then
              L13_2 = DrawText3D
              L14_2 = L10_2.bossMenu
              L14_2 = L14_2.coords
              L14_2 = L14_2.x
              L15_2 = L10_2.bossMenu
              L15_2 = L15_2.coords
              L15_2 = L15_2.y
              L16_2 = L10_2.bossMenu
              L16_2 = L16_2.coords
              L16_2 = L16_2.z
              L17_2 = TRANSLATE
              L18_2 = "3dtext.shop_menu"
              L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L17_2(L18_2)
              L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
            end
            L13_2 = Config
            L13_2 = L13_2.DistanceAccess
            if L12_2 < L13_2 then
              L13_2 = TRANSLATE
              L14_2 = "textui.shop_menu"
              L13_2 = L13_2(L14_2)
              L0_2 = L13_2
              L13_2 = Config
              L13_2 = L13_2.Core
              if "ESX" == L13_2 then
                L13_2 = CL
                L13_2 = L13_2.TextUI
                L13_2 = L13_2.Enabled
                if not L13_2 then
                  L13_2 = Config
                  L13_2 = L13_2.UseHelpNotify
                  if L13_2 then
                    L13_2 = ESX
                    L13_2 = L13_2.ShowHelpNotification
                    L14_2 = TRANSLATE
                    L15_2 = "help.shop_menu"
                    L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2 = L14_2(L15_2)
                    L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2)
                  end
                end
              end
              L13_2 = IsControlJustPressed
              L14_2 = 0
              L15_2 = 38
              L13_2 = L13_2(L14_2, L15_2)
              if L13_2 then
                L13_2 = openPurchaseMenu
                L14_2 = L9_2
                L13_2(L14_2)
                L0_2 = false
              end
            end
          end
        end
      end
      ::lbl_466::
    end
    L5_2 = CL
    L5_2 = L5_2.TextUI
    L5_2 = L5_2.Enabled
    if L5_2 then
      if L0_2 and not L1_2 then
        L1_2 = true
        L5_2 = CL
        L5_2 = L5_2.TextUI
        L5_2 = L5_2.Open
        L6_2 = L0_2
        L5_2(L6_2)
      elseif not L0_2 and L1_2 then
        L1_2 = false
        L5_2 = CL
        L5_2 = L5_2.TextUI
        L5_2 = L5_2.Close
        L5_2()
      end
    end
    L5_2 = Citizen
    L5_2 = L5_2.Wait
    if L2_2 then
      L6_2 = 2000
      if L6_2 then
        goto lbl_502
      end
    end
    L6_2 = 1
    ::lbl_502::
    L5_2(L6_2)
  end
end
L8_1(L9_1)
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = waitingForLoadAfterRestart
  if L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = {}
  L2_2.action = "openPurchaseMenu"
  L3_2 = L1_2.requiredMembership
  if L3_2 then
    L3_2 = L1_2.allowBuyMembership
    if L3_2 then
      L2_2.useMemberships = true
      L3_2 = L1_2.memberships
      L2_2.membershipsList = L3_2
      L4_2 = L1_2.requiredMembership
      L3_2 = L7_1
      L3_2 = L3_2[L4_2]
      L2_2.myMembership = L3_2
    end
  end
  L3_2 = L1_2.allowBuyProteins
  if L3_2 then
    L2_2.useProteins = true
    L3_2 = L1_2.proteins
    L2_2.proteinsList = L3_2
  end
  L3_2 = L1_2.allowBuyMembership
  if not L3_2 then
    L3_2 = L1_2.allowBuyProteins
    if not L3_2 then
      goto lbl_51
    end
  end
  currentShop = A0_2
  L3_2 = Citizen
  L3_2 = L3_2.Wait
  L4_2 = 100
  L3_2(L4_2)
  L3_2 = SetNuiFocus
  L4_2 = true
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = SendNUIMessage
  L4_2 = L2_2
  L3_2(L4_2)
  ::lbl_51::
end
openPurchaseMenu = L8_1
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if not A0_2 then
    return
  end
  L1_2 = currentShop
  if not L1_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Gyms
  L2_2 = currentShop
  L1_2 = L1_2[L2_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.proteins
  if not L2_2 then
    return
  end
  L2_2 = L1_2.allowBuyProteins
  if not L2_2 then
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:sv:buyProtein"
  L4_2 = currentShop
  L5_2 = A0_2
  L2_2(L3_2, L4_2, L5_2)
end
buyProtein = L8_1
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 and not A1_2 then
    return
  end
  L2_2 = currentShop
  if not L2_2 then
    return
  end
  L2_2 = Config
  L2_2 = L2_2.Gyms
  L3_2 = currentShop
  L2_2 = L2_2[L3_2]
  if not L2_2 then
    return
  end
  L3_2 = L2_2.requiredMembership
  if not L3_2 then
    return
  end
  L3_2 = L2_2.allowBuyMembership
  if not L3_2 then
    return
  end
  L3_2 = nil
  L4_2 = pairs
  L5_2 = L2_2.memberships
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L9_2.days
    if L10_2 == A0_2 then
      L10_2 = L9_2.hours
      if L10_2 == A1_2 then
        L3_2 = L9_2
        break
      end
    end
  end
  L4_2 = TriggerServerEvent
  L5_2 = "flake_gym:sv:acceptMembership"
  L6_2 = currentShop
  L7_2 = L2_2.requiredMembership
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
buyMembership = L8_1
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = L1_1
  if L3_2 then
    return
  end
  L3_2 = Config
  L3_2 = L3_2.EnableMemberships
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Gyms
    L3_2 = L3_2[A0_2]
    L3_2 = L3_2.requiredMembership
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Gyms
      L3_2 = L3_2[A0_2]
      L4_2 = L3_2.requiredMembership
      L3_2 = L7_1
      L3_2 = L3_2[L4_2]
      if not L3_2 then
        L3_2 = Config
        L3_2 = L3_2.AutoMembershipForEmployees
        if L3_2 then
          L3_2 = PlayerData
          L3_2 = L3_2.job
          L3_2 = L3_2.name
          L4_2 = Config
          L4_2 = L4_2.Gyms
          L4_2 = L4_2[A0_2]
          L4_2 = L4_2.ownerJob
          if L3_2 == L4_2 then
            goto lbl_51
        end
        else
          L3_2 = CL
          L3_2 = L3_2.Notification
          L4_2 = TRANSLATE
          L5_2 = "notify.title.gym"
          L4_2 = L4_2(L5_2)
          L5_2 = TRANSLATE
          L6_2 = "no_membership"
          L5_2 = L5_2(L6_2)
          L6_2 = 3500
          L7_2 = "fa-solid fa-dumbbell"
          L8_2 = "error"
          return L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
        end
      end
    end
  end
  ::lbl_51::
  L3_2 = A2_2.taken
  if L3_2 then
    L3_2 = CL
    L3_2 = L3_2.Notification
    L4_2 = TRANSLATE
    L5_2 = "notify.title.gym"
    L4_2 = L4_2(L5_2)
    L5_2 = TRANSLATE
    L6_2 = "place_taken"
    L5_2 = L5_2(L6_2)
    L6_2 = 3500
    L7_2 = "fa-solid fa-dumbbell"
    L8_2 = "error"
    return L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  end
  L0_1 = A0_2
  L1_1 = A1_2
  L2_1 = A2_2
  removeStrength = false
  L3_2 = A2_2.activityCoord
  L3_2 = L3_2.w
  if L3_2 then
    L3_2 = SetEntityHeading
    L4_2 = PlayerPedId
    L4_2 = L4_2()
    L5_2 = L2_1.activityCoord
    L5_2 = L5_2.w
    L3_2(L4_2, L5_2)
  end
  L3_2 = A2_2.activityCoord
  L3_2 = L3_2.x
  if L3_2 then
    L3_2 = A2_2.activityCoord
    L3_2 = L3_2.y
    if L3_2 then
      L3_2 = A2_2.activityCoord
      L3_2 = L3_2.z
      if L3_2 then
        L3_2 = SetEntityCoords
        L4_2 = PlayerPedId
        L4_2 = L4_2()
        L5_2 = vec
        L6_2 = A2_2.activityCoord
        L6_2 = L6_2.x
        L7_2 = A2_2.activityCoord
        L7_2 = L7_2.y
        L8_2 = A2_2.activityCoord
        L8_2 = L8_2.z
        L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L5_2(L6_2, L7_2, L8_2)
        L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      end
    end
  end
  L3_2 = FreezeEntityPosition
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = SetEntityCollision
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = false
  L6_2 = false
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = pairs
  L4_2 = Config
  L4_2 = L4_2.Animations
  L5_2 = A2_2.name
  L4_2 = L4_2[L5_2]
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = loadAnimDict
    L10_2 = L8_2[1]
    L9_2(L10_2)
  end
  L3_2 = TriggerServerEvent
  L4_2 = "flake_gym:sv:setTaken"
  L5_2 = L0_1
  L6_2 = L1_1
  L7_2 = true
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = SendNUIMessage
  L4_2 = {}
  L4_2.action = "openHelpKeys"
  L5_2 = GetPlayerStamina
  L6_2 = PlayerId
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2()
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L4_2.stamina = L5_2
  L3_2(L4_2)
  L3_2 = Config
  L3_2 = L3_2.Animations
  L4_2 = A2_2.name
  L3_2 = L3_2[L4_2]
  L3_2 = L3_2.enter
  if L3_2 then
    L3_2 = TaskPlayAnim
    L4_2 = PlayerPedId
    L4_2 = L4_2()
    L5_2 = Config
    L5_2 = L5_2.Animations
    L6_2 = A2_2.name
    L5_2 = L5_2[L6_2]
    L5_2 = L5_2.enter
    L5_2 = L5_2[1]
    L6_2 = Config
    L6_2 = L6_2.Animations
    L7_2 = A2_2.name
    L6_2 = L6_2[L7_2]
    L6_2 = L6_2.enter
    L6_2 = L6_2[2]
    L7_2 = 8.0
    L8_2 = -8.0
    L9_2 = Config
    L9_2 = L9_2.Animations
    L10_2 = A2_2.name
    L9_2 = L9_2[L10_2]
    L9_2 = L9_2.enter
    L9_2 = L9_2[3]
    L10_2 = 0
    L11_2 = 0.0
    L12_2 = 0
    L13_2 = 0
    L14_2 = 0
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
    L3_2 = Citizen
    L3_2 = L3_2.Wait
    L4_2 = Config
    L4_2 = L4_2.Animations
    L5_2 = A2_2.name
    L4_2 = L4_2[L5_2]
    L4_2 = L4_2.enter
    L4_2 = L4_2[3]
    L3_2(L4_2)
  end
  L3_2 = Citizen
  L3_2 = L3_2.CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3
    L0_3 = TaskPlayAnim
    L1_3 = PlayerPedId
    L1_3 = L1_3()
    L2_3 = Config
    L2_3 = L2_3.Animations
    L3_3 = L2_1.name
    L2_3 = L2_3[L3_3]
    L2_3 = L2_3.idle
    L2_3 = L2_3[1]
    L3_3 = Config
    L3_3 = L3_3.Animations
    L4_3 = L2_1.name
    L3_3 = L3_3[L4_3]
    L3_3 = L3_3.idle
    L3_3 = L3_3[2]
    L4_3 = 8.0
    L5_3 = -8.0
    L6_3 = Config
    L6_3 = L6_3.Animations
    L7_3 = L2_1.name
    L6_3 = L6_3[L7_3]
    L6_3 = L6_3.idle
    L6_3 = L6_3[3]
    L7_3 = 1
    L8_3 = 0.0
    L9_3 = 0
    L10_3 = 0
    L11_3 = 0
    L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
    L0_3 = L2_1.prop
    if L0_3 then
      L0_3 = requestProp
      L1_3 = GetHashKey
      L2_3 = L2_1.prop
      L2_3 = L2_3.name
      L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L1_3(L2_3)
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L0_3 = GetEntityCoords
      L1_3 = PlayerPedId
      L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L1_3()
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L1_3 = CreateObject
      L2_3 = GetHashKey
      L3_3 = L2_1.prop
      L3_3 = L3_3.name
      L2_3 = L2_3(L3_3)
      L3_3 = L0_3
      L4_3 = true
      L5_3 = true
      L6_3 = true
      L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
      L3_1 = L1_3
      L1_3 = AttachEntityToEntity
      L2_3 = L3_1
      L3_3 = PlayerPedId
      L3_3 = L3_3()
      L4_3 = GetPedBoneIndex
      L5_3 = PlayerPedId
      L5_3 = L5_3()
      L6_3 = L2_1.prop
      L6_3 = L6_3.attachBone
      L4_3 = L4_3(L5_3, L6_3)
      L5_3 = L2_1.prop
      L5_3 = L5_3.placement
      L5_3 = L5_3[1]
      L5_3 = L5_3 + 0.0
      L6_3 = L2_1.prop
      L6_3 = L6_3.placement
      L6_3 = L6_3[2]
      L6_3 = L6_3 + 0.0
      L7_3 = L2_1.prop
      L7_3 = L7_3.placement
      L7_3 = L7_3[3]
      L7_3 = L7_3 + 0.0
      L8_3 = L2_1.prop
      L8_3 = L8_3.placement
      L8_3 = L8_3[4]
      L8_3 = L8_3 + 0.0
      L9_3 = L2_1.prop
      L9_3 = L9_3.placement
      L9_3 = L9_3[5]
      L9_3 = L9_3 + 0.0
      L10_3 = L2_1.prop
      L10_3 = L10_3.placement
      L10_3 = L10_3[6]
      L10_3 = L10_3 + 0.0
      L11_3 = true
      L12_3 = true
      L13_3 = false
      L14_3 = false
      L15_3 = 1
      L16_3 = true
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L1_3 = SetModelAsNoLongerNeeded
      L2_3 = L3_1
      L1_3(L2_3)
    end
    L0_3 = L2_1.prop2
    if L0_3 then
      L0_3 = requestProp
      L1_3 = GetHashKey
      L2_3 = L2_1.prop2
      L2_3 = L2_3.name
      L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L1_3(L2_3)
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L0_3 = GetEntityCoords
      L1_3 = PlayerPedId
      L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L1_3()
      L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L1_3 = CreateObject
      L2_3 = GetHashKey
      L3_3 = L2_1.prop2
      L3_3 = L3_3.name
      L2_3 = L2_3(L3_3)
      L3_3 = L0_3
      L4_3 = true
      L5_3 = true
      L6_3 = true
      L1_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
      L4_1 = L1_3
      L1_3 = AttachEntityToEntity
      L2_3 = L4_1
      L3_3 = PlayerPedId
      L3_3 = L3_3()
      L4_3 = GetPedBoneIndex
      L5_3 = PlayerPedId
      L5_3 = L5_3()
      L6_3 = L2_1.prop2
      L6_3 = L6_3.attachBone
      L4_3 = L4_3(L5_3, L6_3)
      L5_3 = L2_1.prop2
      L5_3 = L5_3.placement
      L5_3 = L5_3[1]
      L5_3 = L5_3 + 0.0
      L6_3 = L2_1.prop2
      L6_3 = L6_3.placement
      L6_3 = L6_3[2]
      L6_3 = L6_3 + 0.0
      L7_3 = L2_1.prop2
      L7_3 = L7_3.placement
      L7_3 = L7_3[3]
      L7_3 = L7_3 + 0.0
      L8_3 = L2_1.prop2
      L8_3 = L8_3.placement
      L8_3 = L8_3[4]
      L8_3 = L8_3 + 0.0
      L9_3 = L2_1.prop2
      L9_3 = L9_3.placement
      L9_3 = L9_3[5]
      L9_3 = L9_3 + 0.0
      L10_3 = L2_1.prop2
      L10_3 = L10_3.placement
      L10_3 = L10_3[6]
      L10_3 = L10_3 + 0.0
      L11_3 = true
      L12_3 = true
      L13_3 = false
      L14_3 = false
      L15_3 = 1
      L16_3 = true
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      L1_3 = SetModelAsNoLongerNeeded
      L2_3 = L4_1
      L1_3(L2_3)
    end
    while true do
      L0_3 = L2_1
      if not L0_3 then
        break
      end
      L0_3 = IsControlJustPressed
      L1_3 = 0
      L2_3 = Config
      L2_3 = L2_3.Keys
      L2_3 = L2_3.train
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L0_3 = GetPlayerStamina
        L1_3 = PlayerId
        L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L1_3()
        L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
        L5_1 = L0_3
        L0_3 = false
        L1_3 = L5_1
        L2_3 = getSkill
        L3_3 = "condition"
        L2_3 = L2_3(L3_3)
        if L2_3 >= 10.0 then
          L2_3 = L2_1.removeStamina
          L2_3 = L2_3 * 100
          L3_3 = getSkill
          L4_3 = "condition"
          L3_3 = L3_3(L4_3)
          L2_3 = L2_3 / L3_3
          if L2_3 then
            goto lbl_222
          end
        end
        L2_3 = getSkill
        L3_3 = "condition"
        L2_3 = L2_3(L3_3)
        L2_3 = L2_1.removeStamina
        L2_3 = L2_3 < 10.0 and L2_3
        ::lbl_222::
        if L1_3 > L2_3 then
          L1_3 = Config
          L1_3 = L1_3.UseSkillbar
          if L1_3 then
            L1_3 = Config
            L1_3 = L1_3.Skillbar
            L2_3 = L2_1.name
            function L3_3(A0_4)
              local L1_4
              L1_4 = false
              L0_3 = L1_4
              if not A0_4 then
                L1_4 = true
                L0_3 = L1_4
              end
            end
            L1_3(L2_3, L3_3)
          end
          if L0_3 then
            goto lbl_427
          end
          L1_3 = Config
          L1_3 = L1_3.UseProgressbar
          if L1_3 then
            L1_3 = Config
            L1_3 = L1_3.Progressbar
            L2_3 = L2_1.name
            L3_3 = Config
            L3_3 = L3_3.Animations
            L4_3 = L2_1.name
            L3_3 = L3_3[L4_3]
            L3_3 = L3_3.training
            L3_3 = L3_3[3]
            L1_3(L2_3, L3_3)
          end
          L1_3 = TaskPlayAnim
          L2_3 = PlayerPedId
          L2_3 = L2_3()
          L3_3 = Config
          L3_3 = L3_3.Animations
          L4_3 = L2_1.name
          L3_3 = L3_3[L4_3]
          L3_3 = L3_3.training
          L3_3 = L3_3[1]
          L4_3 = Config
          L4_3 = L4_3.Animations
          L5_3 = L2_1.name
          L4_3 = L4_3[L5_3]
          L4_3 = L4_3.training
          L4_3 = L4_3[2]
          L5_3 = 8.0
          L6_3 = -8.0
          L7_3 = Config
          L7_3 = L7_3.Animations
          L8_3 = L2_1.name
          L7_3 = L7_3[L8_3]
          L7_3 = L7_3.training
          L7_3 = L7_3[3]
          L8_3 = 0
          L9_3 = 0.0
          L10_3 = 0
          L11_3 = 0
          L12_3 = 0
          L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
          L1_3 = Citizen
          L1_3 = L1_3.Wait
          L2_3 = Config
          L2_3 = L2_3.Animations
          L3_3 = L2_1.name
          L2_3 = L2_3[L3_3]
          L2_3 = L2_3.training
          L2_3 = L2_3[3]
          L1_3(L2_3)
          L1_3 = TaskPlayAnim
          L2_3 = PlayerPedId
          L2_3 = L2_3()
          L3_3 = Config
          L3_3 = L3_3.Animations
          L4_3 = L2_1.name
          L3_3 = L3_3[L4_3]
          L3_3 = L3_3.idle
          L3_3 = L3_3[1]
          L4_3 = Config
          L4_3 = L4_3.Animations
          L5_3 = L2_1.name
          L4_3 = L4_3[L5_3]
          L4_3 = L4_3.idle
          L4_3 = L4_3[2]
          L5_3 = 8.0
          L6_3 = -8.0
          L7_3 = Config
          L7_3 = L7_3.Animations
          L8_3 = L2_1.name
          L7_3 = L7_3[L8_3]
          L7_3 = L7_3.idle
          L7_3 = L7_3[3]
          L8_3 = 1
          L9_3 = 0.0
          L10_3 = 0
          L11_3 = 0
          L12_3 = 0
          L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
          L1_3 = SetPlayerStamina
          L2_3 = PlayerId
          L2_3 = L2_3()
          L3_3 = L5_1
          L4_3 = getSkill
          L5_3 = "condition"
          L4_3 = L4_3(L5_3)
          if L4_3 >= 10.0 then
            L4_3 = L2_1.removeStamina
            L4_3 = L4_3 * 100
            L5_3 = getSkill
            L6_3 = "condition"
            L5_3 = L5_3(L6_3)
            L4_3 = L4_3 / L5_3
            if L4_3 then
              goto lbl_346
            end
          end
          L4_3 = getSkill
          L5_3 = "condition"
          L4_3 = L4_3(L5_3)
          L4_3 = L2_1.removeStamina
          L4_3 = L4_3 < 10.0 and L4_3
          ::lbl_346::
          L3_3 = L3_3 - L4_3
          L1_3(L2_3, L3_3)
          L1_3 = L2_1.addSkill
          if not L1_3 then
            goto lbl_427
          end
          L1_3 = L2_1.addSkill
          L1_3 = L1_3.skill
          if not L1_3 then
            goto lbl_427
          end
          L1_3 = L2_1.addSkill
          L1_3 = L1_3.value
          if not L1_3 then
            goto lbl_427
          end
          L1_3 = type
          L2_3 = L2_1.addSkill
          L2_3 = L2_3.value
          L1_3 = L1_3(L2_3)
          if "number" == L1_3 then
            L1_3 = addSkill
            L2_3 = L2_1.addSkill
            L2_3 = L2_3.skill
            L3_3 = L2_1.addSkill
            L3_3 = L3_3.value
            L3_3 = L3_3 / 10
            L4_3 = L2_1.addSkill
            L4_3 = L4_3.skill
            if "strenght" == L4_3 then
              L4_3 = strengthBooster
              if L4_3 then
                goto lbl_381
              end
            end
            L4_3 = conditionBooster
            ::lbl_381::
            L3_3 = L3_3 * L4_3
            L1_3(L2_3, L3_3)
          else
            L1_3 = addSkill
            L2_3 = L2_1.addSkill
            L2_3 = L2_3.skill
            L3_3 = math
            L3_3 = L3_3.random
            L4_3 = L2_1.addSkill
            L4_3 = L4_3.value
            L4_3 = L4_3[1]
            L5_3 = L2_1.addSkill
            L5_3 = L5_3.value
            L5_3 = L5_3[2]
            L3_3 = L3_3(L4_3, L5_3)
            L3_3 = L3_3 / 10
            L4_3 = L2_1.addSkill
            L4_3 = L4_3.skill
            if "strenght" == L4_3 then
              L4_3 = strengthBooster
              if L4_3 then
                goto lbl_407
              end
            end
            L4_3 = conditionBooster
            ::lbl_407::
            L3_3 = L3_3 * L4_3
            L1_3(L2_3, L3_3)
          end
        else
          L1_3 = CL
          L1_3 = L1_3.Notification
          L2_3 = TRANSLATE
          L3_3 = "notify.title.gym"
          L2_3 = L2_3(L3_3)
          L3_3 = TRANSLATE
          L4_3 = "out_of_breath"
          L3_3 = L3_3(L4_3)
          L4_3 = 3850
          L5_3 = "fa-solid fa-dumbbell"
          L6_3 = "info"
          L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
          L1_3 = Citizen
          L1_3 = L1_3.Wait
          L2_3 = 1000
          L1_3(L2_3)
        end
        ::lbl_427::
      end
      L0_3 = IsControlJustPressed
      L1_3 = 0
      L2_3 = Config
      L2_3 = L2_3.Keys
      L2_3 = L2_3.stop
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L0_3 = stopAction
        L0_3()
      end
      L0_3 = Citizen
      L0_3 = L0_3.Wait
      L1_3 = 1
      L0_3(L1_3)
    end
  end
  L3_2(L4_2)
  L3_2 = Citizen
  L3_2 = L3_2.CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3
    while true do
      L0_3 = L2_1
      if not L0_3 then
        break
      end
      L0_3 = SendNUIMessage
      L1_3 = {}
      L1_3.action = "update"
      L2_3 = GetPlayerStamina
      L3_3 = PlayerId
      L3_3 = L3_3()
      L2_3 = L2_3(L3_3)
      L1_3.stamina = L2_3
      L0_3(L1_3)
      L0_3 = Citizen
      L0_3 = L0_3.Wait
      L1_3 = 800
      L0_3(L1_3)
    end
  end
  L3_2(L4_2)
end
startAction = L8_1
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = Config
  L0_2 = L0_2.Animations
  L1_2 = L2_1.name
  L0_2 = L0_2[L1_2]
  L0_2 = L0_2.exit
  if L0_2 then
    L0_2 = TaskPlayAnim
    L1_2 = PlayerPedId
    L1_2 = L1_2()
    L2_2 = Config
    L2_2 = L2_2.Animations
    L3_2 = L2_1.name
    L2_2 = L2_2[L3_2]
    L2_2 = L2_2.exit
    L2_2 = L2_2[1]
    L3_2 = Config
    L3_2 = L3_2.Animations
    L4_2 = L2_1.name
    L3_2 = L3_2[L4_2]
    L3_2 = L3_2.exit
    L3_2 = L3_2[2]
    L4_2 = 8.0
    L5_2 = -8.0
    L6_2 = Config
    L6_2 = L6_2.Animations
    L7_2 = L2_1.name
    L6_2 = L6_2[L7_2]
    L6_2 = L6_2.exit
    L6_2 = L6_2[3]
    L7_2 = 0
    L8_2 = 0.0
    L9_2 = 0
    L10_2 = 0
    L11_2 = 0
    L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    L0_2 = Citizen
    L0_2 = L0_2.Wait
    L1_2 = Config
    L1_2 = L1_2.Animations
    L2_2 = L2_1.name
    L1_2 = L1_2[L2_2]
    L1_2 = L1_2.exit
    L1_2 = L1_2[3]
    L0_2(L1_2)
  else
    L0_2 = ClearPedTasks
    L1_2 = PlayerPedId
    L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L1_2()
    L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  L0_2 = FreezeEntityPosition
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SetEntityCollision
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = true
  L3_2 = true
  L0_2(L1_2, L2_2, L3_2)
  L0_2 = TriggerServerEvent
  L1_2 = "flake_gym:sv:setTaken"
  L2_2 = L0_1
  L3_2 = L1_1
  L4_2 = false
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "closeHelpKeys"
  L0_2(L1_2)
  L0_2 = L3_1
  if L0_2 then
    L0_2 = DeleteObject
    L1_2 = L3_1
    L0_2(L1_2)
  end
  L0_2 = L4_1
  if L0_2 then
    L0_2 = DeleteObject
    L1_2 = L4_1
    L0_2(L1_2)
  end
  removeStrength = true
  L0_2 = nil
  L1_2 = nil
  L2_2 = nil
  L2_1 = L2_2
  L1_1 = L1_2
  L0_1 = L0_2
  L0_2 = nil
  L3_1 = L0_2
  L0_2 = nil
  L4_1 = L0_2
end
stopAction = L8_1
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:sv:addValue"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
end
addSkill = L8_1
L8_1 = exports
L9_1 = "addSkill"
L10_1 = addSkill
L8_1(L9_1, L10_1)
function getSkillValue(skillName)
    if myStatistics == nil then return 0.0 end
    return myStatistics[skillName] or 0.0
end
getSkill = getSkillValue
L8_1 = exports
L9_1 = "getSkill"
L10_1 = getSkill
L8_1(L9_1, L10_1)
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerServerEvent
  L3_2 = "flake_gym:sv:removeValue"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
end
removeSkill = L8_1
L8_1 = exports
L9_1 = "removeSkill"
L10_1 = removeSkill
L8_1(L9_1, L10_1)
function L8_1()
  local L0_2, L1_2, L2_2
  L0_2 = waitingForLoadAfterRestart
  if L0_2 then
    return
  end
  L0_2 = SetNuiFocus
  L1_2 = true
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "openStatisticsMenu"
  L2_2 = myStatistics
  L1_2.stats = L2_2
  L0_2(L1_2)
end
openStatisticsMenu = L8_1
L8_1 = exports
L9_1 = "openStatisticsMenu"
L10_1 = openStatisticsMenu
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:cl:setTaken"
function L10_1(A0_2, A1_2, A2_2)
  local L3_2
  L3_2 = Config
  L3_2 = L3_2.Gyms
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.points
  L3_2 = L3_2[A1_2]
  L3_2.taken = A2_2
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:cl:updateStatistic"
function L10_1(A0_2)
  local L1_2, L2_2, L3_2
  myStatistics = A0_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "updateStatisticsMenu"
  L3_2 = myStatistics
  L2_2.stats = L3_2
  L1_2(L2_2)
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:runConditionBooster"
L8_1(L9_1)
L8_1 = AddEventHandler
L9_1 = "flake_gym:runConditionBooster"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = conditionBooster
  if 1.0 == L2_2 and A0_2 then
    L2_2 = tonumber
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 and A1_2 then
      L2_2 = tonumber
      L3_2 = A1_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        conditionBooster = A0_2
        L2_2 = Citizen
        L2_2 = L2_2.CreateThread
        function L3_2()
          local L0_3, L1_3
          L0_3 = Citizen
          L0_3 = L0_3.Wait
          L1_3 = A1_2
          L0_3(L1_3)
          conditionBooster = 1.0
        end
        L2_2(L3_2)
      end
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:runStrengthBooster"
L8_1(L9_1)
L8_1 = AddEventHandler
L9_1 = "flake_gym:runStrengthBooster"
function L10_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = strengthBooster
  if 1.0 == L2_2 and A0_2 then
    L2_2 = tonumber
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 and A1_2 then
      L2_2 = tonumber
      L3_2 = A1_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        strengthBooster = A0_2
        L2_2 = Citizen
        L2_2 = L2_2.CreateThread
        function L3_2()
          local L0_3, L1_3
          L0_3 = Citizen
          L0_3 = L0_3.Wait
          L1_3 = A1_2
          L0_3(L1_3)
          strengthBooster = 1.0
        end
        L2_2(L3_2)
      end
    end
  end
end
L8_1(L9_1, L10_1)
L8_1 = RegisterNetEvent
L9_1 = "flake_gym:notification"
function L10_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A5_2 then
    L6_2 = disabledNotifySkillInfo
    if 1 == L6_2 then
      return
    end
  end
  L6_2 = CL
  L6_2 = L6_2.Notification
  L7_2 = A0_2
  L8_2 = A1_2
  L9_2 = A2_2
  L10_2 = A3_2
  L11_2 = A4_2
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
end
L8_1(L9_1, L10_1)
L8_1 = Config
L8_1 = L8_1.StatisticCommand
if L8_1 then
  L8_1 = Config
  L8_1 = L8_1.StatisticCommand
  if "" ~= L8_1 then
    L8_1 = RegisterCommand
    L9_1 = Config
    L9_1 = L9_1.StatisticCommand
    function L10_1()
      local L0_2, L1_2
      L0_2 = openStatisticsMenu
      L0_2()
    end
    L8_1(L9_1, L10_1)
    L8_1 = Config
    L8_1 = L8_1.StatisticDescription
    if L8_1 then
      L8_1 = Config
      L8_1 = L8_1.StatisticKey
      if L8_1 then
        L8_1 = Config
        L8_1 = L8_1.StatisticKey
        if "" ~= L8_1 then
          L8_1 = RegisterKeyMapping
          L9_1 = Config
          L9_1 = L9_1.StatisticCommand
          L10_1 = Config
          L10_1 = L10_1.StatisticDescription
          L11_1 = "keyboard"
          L12_1 = Config
          L12_1 = L12_1.StatisticKey
          L8_1(L9_1, L10_1, L11_1, L12_1)
        end
      end
    end
  end
end
