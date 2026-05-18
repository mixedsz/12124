-- ============================================================
--  flake_gym  –  server.lua
-- ============================================================

local ESX, QBCore

-- ============================================================
--  Framework initialisation
-- ============================================================
if Config.Core == "ESX" then
    ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
end

-- ============================================================
--  In-memory stores (balance, totalEarned, announcements …)
-- ============================================================
local stores = {}  -- [gymId] = { data = { balance, totalEarned, announcements } }

-- In-memory player statistics  [src] = { strenght, condition, … }
local playerStats = {}

-- Pending bills waiting for player confirmation
local billCache = {}  -- [src] = { action, type, gymId, itemData, count, sellerId }

-- ============================================================
--  Helpers
-- ============================================================
local function getIdentifier(src)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getIdentifier()
    elseif Config.Core == "QB-Core" then
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    end
end

local function getESXPlayer(src)  return ESX.GetPlayerFromId(src)   end
local function getQBPlayer(src)   return QBCore.Functions.GetPlayer(src) end

local function addMoney(src, amount, account)
    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if not xP then return end
        if account == "bank" then xP.addAccountMoney('bank', amount)
        else                       xP.addMoney(amount) end
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if not p then return end
        p.Functions.AddMoney(account == "bank" and "bank" or "cash", amount)
    end
end

local function removeMoney(src, amount, account)
    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if not xP then return false end
        if account == "bank" then
            if xP.getAccount('bank').money < amount then return false end
            xP.removeAccountMoney('bank', amount)
        else
            if xP.getMoney() < amount then return false end
            xP.removeMoney(amount)
        end
        return true
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if not p then return false end
        local balance = account == "bank"
            and p.PlayerData.money.bank
            or  p.PlayerData.money.cash
        if balance < amount then return false end
        p.Functions.RemoveMoney(account == "bank" and "bank" or "cash", amount)
        return true
    end
    return false
end

local function getMoney(src, account)
    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if not xP then return 0 end
        if account == "bank" then return xP.getAccount('bank').money
        else                       return xP.getMoney() end
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if not p then return 0 end
        return account == "bank" and p.PlayerData.money.bank or p.PlayerData.money.cash
    end
    return 0
end

local function addItem(src, itemName, count)
    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if xP then xP.addInventoryItem(itemName, count or 1) end
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if p then p.Functions.AddItem(itemName, count or 1, false, {}) end
    end
end

local function sendNotification(src, title, message, duration, icon, ntype)
    TriggerClientEvent("flake_gym:notification", src, title, message, duration, icon, ntype, false)
end

local function sendSkillNotification(src, title, message, duration, icon, ntype)
    TriggerClientEvent("flake_gym:notification", src, title, message, duration, icon, ntype, true)
end

local function translate(key)
    local lang = Config.Translate[Config.Language] or Config.Translate["EN"]
    if not lang then return key end
    -- navigate dot-separated key
    local parts = {}
    for part in key:gmatch("[^.]+") do parts[#parts+1] = part end
    local val = lang
    for _, p in ipairs(parts) do
        if type(val) ~= "table" then return key end
        val = val[p]
    end
    return type(val) == "string" and val or key
end

-- ============================================================
--  Database helpers (oxmysql / mysql-async compatible)
-- ============================================================
local function dbExecute(query, params, cb)
    if MySQL and MySQL.Async and MySQL.Async.execute then
        MySQL.Async.execute(query, params, cb)
    elseif MySQL and MySQL.query then
        MySQL.query(query, params, cb)
    end
end

local function dbFetchAll(query, params, cb)
    if MySQL and MySQL.Async and MySQL.Async.fetchAll then
        MySQL.Async.fetchAll(query, params, cb)
    elseif MySQL and MySQL.query then
        MySQL.query(query, params, cb)
    end
end

local function dbFetchScalar(query, params, cb)
    if MySQL and MySQL.Async and MySQL.Async.fetchScalar then
        MySQL.Async.fetchScalar(query, params, cb)
    elseif MySQL and MySQL.scalar then
        MySQL.scalar(query, params, cb)
    end
end

-- ============================================================
--  Database initialisation
-- ============================================================
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if not Config.AutoExecuteQuery then return end

    -- Gym business data table
    dbExecute([[
        CREATE TABLE IF NOT EXISTS `flake_gym_data` (
            `id`           INT AUTO_INCREMENT PRIMARY KEY,
            `gym_id`       VARCHAR(64)  NOT NULL UNIQUE,
            `balance`      INT          NOT NULL DEFAULT 0,
            `total_earned` INT          NOT NULL DEFAULT 0,
            `announcements` LONGTEXT    NOT NULL DEFAULT '[]'
        )
    ]], {})

    -- Memberships table
    dbExecute([[
        CREATE TABLE IF NOT EXISTS `flake_gym_memberships` (
            `id`              INT AUTO_INCREMENT PRIMARY KEY,
            `identifier`      VARCHAR(64) NOT NULL,
            `membership_name` VARCHAR(64) NOT NULL,
            `expire_time`     BIGINT      NOT NULL,
            UNIQUE KEY `uniq_mem` (`identifier`, `membership_name`)
        )
    ]], {})

    -- Statistics column in ESX users / QB-Core players table
    local statsTable = Config.Core == "ESX" and "users" or "players"
    dbExecute(('ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `statistics` LONGTEXT DEFAULT NULL'):format(statsTable), {})

    -- Load gym data from DB after a short delay to let the DB be ready
    Citizen.Wait(1000)
    loadAllGymData()
end)

-- ============================================================
--  Load gym data from DB
-- ============================================================
function loadAllGymData()
    -- Initialise defaults for every configured gym
    for gymId in pairs(Config.Gyms) do
        stores[gymId] = {
            data = {
                balance       = 0,
                totalEarned   = 0,
                announcements = {},
            }
        }
    end

    -- Load persisted data
    dbFetchAll('SELECT * FROM `flake_gym_data`', {}, function(rows)
        if not rows then return end
        for _, row in ipairs(rows) do
            if stores[row.gym_id] then
                stores[row.gym_id].data.balance     = row.balance     or 0
                stores[row.gym_id].data.totalEarned = row.total_earned or 0
                if row.announcements then
                    stores[row.gym_id].data.announcements = json.decode(row.announcements) or {}
                end
            end
        end
    end)
end

-- ============================================================
--  Save gym data to DB
-- ============================================================
local function saveGymData(gymId)
    local d = stores[gymId] and stores[gymId].data
    if not d then return end
    dbExecute([[
        INSERT INTO `flake_gym_data` (`gym_id`, `balance`, `total_earned`, `announcements`)
        VALUES (@gymId, @balance, @totalEarned, @announcements)
        ON DUPLICATE KEY UPDATE
            `balance`       = @balance,
            `total_earned`  = @totalEarned,
            `announcements` = @announcements
    ]], {
        ['@gymId']         = gymId,
        ['@balance']       = d.balance,
        ['@totalEarned']   = d.totalEarned,
        ['@announcements'] = json.encode(d.announcements),
    })
end

-- ============================================================
--  Broadcast gym store update to all online employees
-- ============================================================
local function broadcastBusinessUpdate(gymId, changeInfo)
    for _, src in ipairs(GetPlayers()) do
        local id = tonumber(src)
        TriggerClientEvent("flake_gym:updateBusiness", id, gymId, stores[gymId], changeInfo)
    end
end

-- ============================================================
--  Player statistics  –  load from DB
-- ============================================================
local function loadPlayerStats(src)
    local identifier = getIdentifier(src)
    if not identifier then return end

    local statsCol   = Config.Core == "ESX" and "statistics" or "statistics"
    local idCol      = Config.Core == "ESX" and "identifier" or "citizenid"
    local tableName  = Config.Core == "ESX" and "users"      or "players"

    dbFetchScalar(
        ('SELECT `%s` FROM `%s` WHERE `%s` = @id LIMIT 1'):format(statsCol, tableName, idCol),
        {['@id'] = identifier},
        function(result)
            local stats = {strenght = 0.0, condition = 0.0, shooting = 0.0, driving = 0.0, flying = 0.0}
            if result then
                local decoded = json.decode(result)
                if decoded then stats = decoded end
            end
            playerStats[src] = stats
            TriggerClientEvent("flake_gym:cl:updateStatistic", src, stats)
        end)
end

-- ============================================================
--  Player statistics  –  save to DB
-- ============================================================
local function savePlayerStats(src)
    local identifier = getIdentifier(src)
    if not identifier or not playerStats[src] then return end

    local statsCol  = "statistics"
    local idCol     = Config.Core == "ESX" and "identifier" or "citizenid"
    local tableName = Config.Core == "ESX" and "users"       or "players"

    dbExecute(
        ('UPDATE `%s` SET `%s` = @stats WHERE `%s` = @id'):format(tableName, statsCol, idCol),
        {
            ['@stats'] = json.encode(playerStats[src]),
            ['@id']    = identifier,
        })
end

-- ============================================================
--  Periodic statistics save
-- ============================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SavingTimeout)
        for _, src in ipairs(GetPlayers()) do
            local id = tonumber(src)
            if playerStats[id] then
                savePlayerStats(id)
            end
        end
    end
end)

-- ============================================================
--  Player memberships  –  fetch from DB
-- ============================================================
local function loadPlayerMemberships(src)
    local identifier = getIdentifier(src)
    if not identifier then return end

    local now = os.time()
    dbFetchAll(
        'SELECT `membership_name`, `expire_time` FROM `flake_gym_memberships` WHERE `identifier` = @id AND `expire_time` > @now',
        {['@id'] = identifier, ['@now'] = now},
        function(rows)
            local memberships = {}
            if rows then
                for _, row in ipairs(rows) do
                    memberships[#memberships + 1] = {
                        name = row.membership_name,
                        time = row.expire_time,
                    }
                end
            end
            TriggerClientEvent("flake_gym:cl:getMemberships", src, memberships)
        end)
end

-- ============================================================
--  Player loaded  –  send all data
-- ============================================================
local function onPlayerLoaded(src)
    TriggerClientEvent("flake_gym:fetchedData", src, stores)
    loadPlayerStats(src)
    loadPlayerMemberships(src)
end

AddEventHandler(Config.PlayerLoadedServer, function(player)
    local src = type(player) == "number" and player or source
    Citizen.Wait(500)
    onPlayerLoaded(src)
end)

-- ============================================================
--  flake_gym:fetchData  –  client asks server for its data
-- ============================================================
RegisterNetEvent("flake_gym:fetchData")
AddEventHandler("flake_gym:fetchData", function()
    local src = source
    onPlayerLoaded(src)
end)

-- ============================================================
--  flake_gym:sv:restartPlayer  –  resource restarted, player already in
-- ============================================================
RegisterNetEvent("flake_gym:sv:restartPlayer")
AddEventHandler("flake_gym:sv:restartPlayer", function()
    local src = source
    onPlayerLoaded(src)
end)

-- ============================================================
--  Player drop  –  save data and clean up
-- ============================================================
AddEventHandler(Config.PlayerLogoutServer, function(playerId)
    local src = type(playerId) == "number" and playerId or source
    if playerStats[src] then
        savePlayerStats(src)
        playerStats[src] = nil
    end
    billCache[src] = nil
end)

-- ============================================================
--  Exercise spot taken/free  (broadcast to all clients)
-- ============================================================
RegisterNetEvent("flake_gym:sv:setTaken")
AddEventHandler("flake_gym:sv:setTaken", function(gymId, pointIdx, taken)
    TriggerClientEvent("flake_gym:cl:setTaken", -1, gymId, pointIdx, taken)
end)

-- ============================================================
--  Add skill value
-- ============================================================
RegisterNetEvent("flake_gym:sv:addValue")
AddEventHandler("flake_gym:sv:addValue", function(skillName, value)
    local src = source
    if not playerStats[src] then playerStats[src] = {strenght=0.0, condition=0.0, shooting=0.0, driving=0.0, flying=0.0} end

    local stats = playerStats[src]
    local current = stats[skillName] or 0.0
    local newVal  = math.min(100.0, current + value)
    stats[skillName] = newVal

    TriggerClientEvent("flake_gym:cl:updateStatistic", src, stats)

    if Config.SendNotificationWhenSkillIncrase and value > 0 then
        sendSkillNotification(src,
            translate("notify.title.gym"),
            translate("notify.skill_increase." .. skillName) or (skillName .. " +" .. string.format("%.1f", value)),
            3000,
            "fa-solid fa-dumbbell",
            "success")
    end
end)

-- ============================================================
--  Remove skill value
-- ============================================================
RegisterNetEvent("flake_gym:sv:removeValue")
AddEventHandler("flake_gym:sv:removeValue", function(skillName, value)
    local src = source
    if not playerStats[src] then return end

    local stats   = playerStats[src]
    local current = stats[skillName] or 0.0
    local newVal  = math.max(0.0, current - value)
    stats[skillName] = newVal

    TriggerClientEvent("flake_gym:cl:updateStatistic", src, stats)

    if Config.SendNotificationWhenSkillDecrease and value > 0 then
        sendSkillNotification(src,
            translate("notify.title.gym"),
            translate("notify.skill_decrease." .. skillName) or (skillName .. " -" .. string.format("%.1f", value)),
            3000,
            "fa-solid fa-dumbbell",
            "error")
    end
end)

-- ============================================================
--  Buy protein  (player → shop)
-- ============================================================
RegisterNetEvent("flake_gym:sv:buyProtein")
AddEventHandler("flake_gym:sv:buyProtein", function(gymId, itemName)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end
    if not gymConfig.allowBuyProteins then return end

    local proteinData = gymConfig.proteins and gymConfig.proteins[itemName]
    if not proteinData then return end

    -- Cache bill and show receipt
    billCache[src] = {
        action    = "buyProtein",
        gymId     = gymId,
        itemData  = proteinData,
        count     = 1,
    }

    TriggerClientEvent("flake_gym:cl:getBill", src, src, nil, proteinData, 1)
end)

-- ============================================================
--  Accept membership  (player → shop)
-- ============================================================
RegisterNetEvent("flake_gym:sv:acceptMembership")
AddEventHandler("flake_gym:sv:acceptMembership", function(gymId, membershipName, membershipData)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end
    if not gymConfig.requiredMembership then return end
    if not gymConfig.allowBuyMembership then return end
    if not membershipData then return end

    -- Cache bill and show receipt
    billCache[src] = {
        action         = "buyMembership",
        gymId          = gymId,
        membershipName = membershipName,
        itemData       = membershipData,
    }

    TriggerClientEvent("flake_gym:cl:getBill", src, src, membershipData, nil, nil)
end)

-- ============================================================
--  Pay bill  (cash or bank)
-- ============================================================
RegisterNetEvent("flake_gym:sv:payBill")
AddEventHandler("flake_gym:sv:payBill", function(action, paymentType)
    local src   = source
    local bill  = billCache[src]

    if action == "cancel" then
        billCache[src] = nil
        return
    end

    if not bill then return end

    local gymConfig = Config.Gyms[bill.gymId]
    if not gymConfig then billCache[src] = nil; return end

    -- Determine price (tax-inclusive totalAmount if available, else price)
    local price
    if bill.action == "buyMembership" then
        price = bill.itemData.totalAmount or bill.itemData.price
    elseif bill.action == "buyProtein" then
        price = (bill.itemData.totalAmount or bill.itemData.price) * (bill.count or 1)
    elseif bill.action == "sellMembership" then
        price = bill.itemData.totalAmount or bill.itemData.price
    elseif bill.action == "sellProtein" then
        price = (bill.itemData.totalAmount or bill.itemData.price) * (bill.count or 1)
    else
        price = bill.itemData and (bill.itemData.price or 0) or 0
    end

    price = math.floor(price)

    -- Determine target source (might be a different player for sell operations)
    local targetSrc  = bill.buyerSrc or src
    local sellerSrc  = bill.sellerSrc

    -- Charge the buyer
    local success = removeMoney(targetSrc, price, paymentType or "cash")
    if not success then
        sendNotification(targetSrc,
            translate("notify.title.gym"),
            translate("notify.not_enough_money") or "Not enough money.",
            3500, "fa-solid fa-dollar-sign", "error")
        billCache[src] = nil
        return
    end

    -- Handle what was purchased
    if bill.action == "buyMembership" or bill.action == "sellMembership" then
        local identifier = getIdentifier(targetSrc)
        if identifier then
            -- Calculate expire time
            local daysSeconds  = (bill.itemData.days  or 0) * 86400
            local hoursSeconds = (bill.itemData.hours or 0) * 3600
            local expireTime   = os.time() + daysSeconds + hoursSeconds

            dbExecute([[
                INSERT INTO `flake_gym_memberships` (`identifier`, `membership_name`, `expire_time`)
                VALUES (@id, @name, @expire)
                ON DUPLICATE KEY UPDATE
                    `expire_time` = IF(`expire_time` > @now,
                        `expire_time` + @duration,
                        @expire)
            ]], {
                ['@id']       = identifier,
                ['@name']     = bill.membershipName,
                ['@expire']   = expireTime,
                ['@now']      = os.time(),
                ['@duration'] = daysSeconds + hoursSeconds,
            })

            loadPlayerMemberships(targetSrc)

            sendNotification(targetSrc,
                translate("notify.title.gym"),
                translate("notify.membership_bought") or "Membership purchased!",
                3500, "fa-solid fa-dumbbell", "success")
        end

    elseif bill.action == "buyProtein" or bill.action == "sellProtein" then
        addItem(targetSrc, bill.itemData.name, bill.count or 1)

        sendNotification(targetSrc,
            translate("notify.title.gym"),
            translate("notify.protein_bought") or "Item purchased!",
            3500, "fa-solid fa-dumbbell", "success")
    end

    -- Credit gym balance
    local gymId = bill.gymId
    if stores[gymId] then
        local earned    = math.floor(price * (Config.BillMoneyToSocietyPercent / 100))
        local sellerCut = math.floor(price * (Config.BillMoneyToSellerPercent  / 100))

        stores[gymId].data.balance     = (stores[gymId].data.balance     or 0) + earned
        stores[gymId].data.totalEarned = (stores[gymId].data.totalEarned or 0) + earned

        saveGymData(gymId)
        broadcastBusinessUpdate(gymId, {sub = "balance", value = stores[gymId].data.balance})

        -- Pay seller commission
        if sellerSrc and sellerSrc ~= targetSrc and sellerCut > 0 then
            addMoney(sellerSrc, sellerCut, "cash")
            sendNotification(sellerSrc,
                translate("notify.title.gym"),
                translate("notify.sale_commission") or ("Commission: $" .. sellerCut),
                3500, "fa-solid fa-dumbbell", "success")
        end
    end

    billCache[src] = nil
    TriggerClientEvent("flake_gym:cl:getBillFeedback", src)
    if targetSrc ~= src then
        TriggerClientEvent("flake_gym:cl:getBillFeedback", targetSrc)
    end
end)

-- ============================================================
--  Sell membership (employee → nearby player)
-- ============================================================
RegisterNetEvent("flake_gym:sv:sellMembership")
AddEventHandler("flake_gym:sv:sellMembership", function(targetPlayerId, gymId, membershipData)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end
    if not gymConfig.requiredMembership  then return end
    if not gymConfig.allowSellMembership then return end
    if not membershipData then return end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then return end

    -- Store bill under the seller's id so they can confirm; buyer is targetSrc
    billCache[src] = {
        action         = "sellMembership",
        gymId          = gymId,
        membershipName = gymConfig.requiredMembership,
        itemData       = membershipData,
        buyerSrc       = targetSrc,
        sellerSrc      = src,
    }

    TriggerClientEvent("flake_gym:cl:getBill", targetSrc, src, membershipData, nil, nil)
end)

-- ============================================================
--  Sell protein (employee → nearby player)
-- ============================================================
RegisterNetEvent("flake_gym:sv:sellProtein")
AddEventHandler("flake_gym:sv:sellProtein", function(targetPlayerId, gymId, proteinData, count)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end
    if not gymConfig.allowSellProteins then return end
    if not proteinData then return end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then return end

    billCache[src] = {
        action    = "sellProtein",
        gymId     = gymId,
        itemData  = proteinData,
        count     = tonumber(count) or 1,
        buyerSrc  = targetSrc,
        sellerSrc = src,
    }

    TriggerClientEvent("flake_gym:cl:getBill", targetSrc, src, nil, proteinData, count)
end)

-- ============================================================
--  Announcement
-- ============================================================
RegisterNetEvent("flake_gym:sendAnnouncement")
AddEventHandler("flake_gym:sendAnnouncement", function(gymId, text)
    local src = source
    if not gymId or not text or text == "" then return end
    if not stores[gymId] then return end

    -- Permission: employee or above
    local gymConfig = Config.Gyms[gymId]
    if gymConfig then
        -- (Just check the job server-side for ESX/QB)
    end

    local announcement = {
        text = text,
        time = os.time(),
    }

    local announcements = stores[gymId].data.announcements or {}
    table.insert(announcements, 1, announcement)
    -- Keep only the last 25
    while #announcements > 25 do table.remove(announcements) end
    stores[gymId].data.announcements = announcements

    saveGymData(gymId)
    broadcastBusinessUpdate(gymId, {sub = "announcements", value = announcements})
end)

-- ============================================================
--  Hire employee
-- ============================================================
RegisterNetEvent("flake_gym:hireAnEmployee")
AddEventHandler("flake_gym:hireAnEmployee", function(gymId, targetPlayerId)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then return end

    -- Check that source is manager or boss
    if not (isSrcManager(src, gymId) or isSrcBoss(src, gymId)) then return end

    -- Check target is unemployed (or Config.RequiredJobToBeHired)
    if Config.Core == "ESX" then
        local xTarget = getESXPlayer(targetSrc)
        if not xTarget then return end
        if Config.RequiredJobToBeHired and xTarget.job.name ~= Config.RequiredJobToBeHired then
            sendNotification(src,
                translate("notify.title.gym"),
                translate("notify.employees.not_unemployed") or "Player is already employed.",
                3500, "fa-solid fa-user", "error")
            return
        end
        xTarget.setJob(gymConfig.ownerJob, 0)
    elseif Config.Core == "QB-Core" then
        local qbTarget = getQBPlayer(targetSrc)
        if not qbTarget then return end
        qbTarget.Functions.SetJob(gymConfig.ownerJob, 0)
    end

    broadcastBusinessUpdate(gymId, {sub = "employees"})

    sendNotification(src,
        translate("notify.title.gym"),
        translate("notify.employees.hired") or "Employee hired.",
        3500, "fa-solid fa-user", "success")
    sendNotification(targetSrc,
        translate("notify.title.gym"),
        translate("notify.employees.you_are_hired") or "You have been hired!",
        3500, "fa-solid fa-user", "success")
end)

-- ============================================================
--  Bonus employee
-- ============================================================
RegisterNetEvent("flake_gym:bonusEmployee")
AddEventHandler("flake_gym:bonusEmployee", function(gymId, targetIdentifier, bonusAmount)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    local amount = tonumber(bonusAmount)
    if not amount or amount < 1 then return end

    -- Deduct from gym balance
    if stores[gymId].data.balance < amount then
        sendNotification(src,
            translate("notify.title.gym"),
            translate("notify.not_enough_balance") or "Not enough gym balance.",
            3500, "fa-solid fa-dollar-sign", "error")
        return
    end

    stores[gymId].data.balance = stores[gymId].data.balance - amount
    saveGymData(gymId)

    -- Find target player and pay them
    for _, playerSrc in ipairs(GetPlayers()) do
        local id = tonumber(playerSrc)
        if getIdentifier(id) == targetIdentifier then
            addMoney(id, amount, "cash")
            sendNotification(id,
                translate("notify.title.gym"),
                (translate("notify.employees.bonus_received") or "Bonus received: $") .. amount,
                3500, "fa-solid fa-dollar-sign", "success")
            break
        end
    end

    broadcastBusinessUpdate(gymId, {sub = "balance", value = stores[gymId].data.balance})

    sendNotification(src,
        translate("notify.title.gym"),
        translate("notify.employees.bonus_sent") or "Bonus sent.",
        3500, "fa-solid fa-dollar-sign", "success")
end)

-- ============================================================
--  Change employee grade
-- ============================================================
RegisterNetEvent("flake_gym:changeGradeEmployee")
AddEventHandler("flake_gym:changeGradeEmployee", function(gymId, targetIdentifier, gradeData)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    local grade = gradeData and gradeData.grade

    -- needToBeBoss check
    if gradeData and gradeData.needToBeBoss and not isSrcBoss(src, gymId) then
        sendNotification(src,
            translate("notify.title.gym"),
            translate("notify.employees.no_permission") or "No permission.",
            3500, "fa-solid fa-user", "error")
        return
    end

    -- Find the target player and set their grade
    for _, playerSrc in ipairs(GetPlayers()) do
        local id = tonumber(playerSrc)
        if getIdentifier(id) == targetIdentifier then
            if Config.Core == "ESX" then
                local xTarget = getESXPlayer(id)
                if xTarget then xTarget.setJob(gymConfig.ownerJob, grade) end
            elseif Config.Core == "QB-Core" then
                local qbTarget = getQBPlayer(id)
                if qbTarget then qbTarget.Functions.SetJob(gymConfig.ownerJob, grade) end
            end
            break
        end
    end

    broadcastBusinessUpdate(gymId, {sub = "employees"})
end)

-- ============================================================
--  Fire employee
-- ============================================================
RegisterNetEvent("flake_gym:fireEmployee")
AddEventHandler("flake_gym:fireEmployee", function(gymId, targetIdentifier)
    local src       = source
    local gymConfig = Config.Gyms[gymId]
    if not gymConfig then return end

    if not (isSrcManager(src, gymId) or isSrcBoss(src, gymId)) then return end

    for _, playerSrc in ipairs(GetPlayers()) do
        local id = tonumber(playerSrc)
        if getIdentifier(id) == targetIdentifier then
            if Config.Core == "ESX" then
                local xTarget = getESXPlayer(id)
                if xTarget then xTarget.setJob('unemployed', 0) end
            elseif Config.Core == "QB-Core" then
                local qbTarget = getQBPlayer(id)
                if qbTarget then qbTarget.Functions.SetJob('unemployed', 0) end
            end
            sendNotification(id,
                translate("notify.title.gym"),
                translate("notify.employees.you_are_fired") or "You have been fired.",
                3500, "fa-solid fa-user", "error")
            break
        end
    end

    broadcastBusinessUpdate(gymId, {sub = "employees"})
    sendNotification(src,
        translate("notify.title.gym"),
        translate("notify.employees.fired") or "Employee fired.",
        3500, "fa-solid fa-user", "success")
end)

-- ============================================================
--  Withdraw from built-in company balance
-- ============================================================
RegisterNetEvent("flake_gym:withdraw")
AddEventHandler("flake_gym:withdraw", function(gymId, amount)
    local src  = source
    amount = tonumber(amount)
    if not amount or amount < 1 then return end
    if not stores[gymId] then return end

    if stores[gymId].data.balance < amount then
        sendNotification(src,
            translate("notify.title.gym"),
            translate("notify.not_enough_balance") or "Not enough balance.",
            3500, "fa-solid fa-dollar-sign", "error")
        return
    end

    stores[gymId].data.balance = stores[gymId].data.balance - amount
    addMoney(src, amount, "cash")
    saveGymData(gymId)

    broadcastBusinessUpdate(gymId, {sub = "balance", value = stores[gymId].data.balance})

    sendNotification(src,
        translate("notify.title.gym"),
        translate("notify.withdraw_success") or ("Withdrawn: $" .. amount),
        3500, "fa-solid fa-dollar-sign", "success")
end)

-- ============================================================
--  Deposit to built-in company balance
-- ============================================================
RegisterNetEvent("flake_gym:deposit")
AddEventHandler("flake_gym:deposit", function(gymId, amount)
    local src  = source
    amount = tonumber(amount)
    if not amount or amount < 1 then return end
    if not stores[gymId] then return end

    local success = removeMoney(src, amount, "cash")
    if not success then
        sendNotification(src,
            translate("notify.title.gym"),
            translate("notify.not_enough_money") or "Not enough money.",
            3500, "fa-solid fa-dollar-sign", "error")
        return
    end

    stores[gymId].data.balance = (stores[gymId].data.balance or 0) + amount
    saveGymData(gymId)

    broadcastBusinessUpdate(gymId, {sub = "balance", value = stores[gymId].data.balance})

    sendNotification(src,
        translate("notify.title.gym"),
        translate("notify.deposit_success") or ("Deposited: $" .. amount),
        3500, "fa-solid fa-dollar-sign", "success")
end)

-- ============================================================
--  Permission helper functions (server-side job checks)
-- ============================================================
function isSrcManager(src, gymId)
    local gymCfg = Config.Gyms[gymId]
    if not gymCfg then return false end
    local managerGrades = gymCfg.manager_grades

    local function checkGrade(jobName, gradeName)
        if type(managerGrades) == "table" then
            for _, g in ipairs(managerGrades) do
                if gradeName == g then return true end
            end
            return false
        end
        return gradeName == managerGrades
    end

    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if not xP then return false end
        return xP.job.name == gymCfg.ownerJob and checkGrade(gymCfg.ownerJob, xP.job.grade_name)
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if not p then return false end
        return p.PlayerData.job.name == gymCfg.ownerJob and checkGrade(gymCfg.ownerJob, p.PlayerData.job.grade.name)
    end
    return false
end

function isSrcBoss(src, gymId)
    local gymCfg = Config.Gyms[gymId]
    if not gymCfg then return false end
    local bossGrades = gymCfg.boss_grades

    local function checkGrade(gradeName)
        if type(bossGrades) == "table" then
            for _, g in ipairs(bossGrades) do
                if gradeName == g then return true end
            end
            return false
        end
        return gradeName == bossGrades
    end

    if Config.Core == "ESX" then
        local xP = getESXPlayer(src)
        if not xP then return false end
        return xP.job.name == gymCfg.ownerJob and checkGrade(xP.job.grade_name)
    elseif Config.Core == "QB-Core" then
        local p = getQBPlayer(src)
        if not p then return false end
        return p.PlayerData.job.name == gymCfg.ownerJob and checkGrade(p.PlayerData.job.grade.name)
    end
    return false
end
