-- ============================================================
--  vms_gym  |  server.lua  (restored from deobfuscated code)
-- ============================================================

local Core = nil

-- ── In-memory state ──────────────────────────────────────────
local playerStats   = {}   -- [identifier] = { strenght, condition, shooting, driving, flying }
local gymBusinesses = {}   -- [gymId]      = { balance, totalEarned, announcements = {} }
local pendingBills  = {}   -- [src]        = { sellerId, gymId, membershipData, proteinsData, count }

-- ── Bootstrap ─────────────────────────────────────────────────
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Core == "ESX" then
        while not Core do
            Core = exports["es_extended"]:getSharedObject()
            if not Core then Citizen.Wait(200) end
        end
    elseif Config.Core == "QB-Core" then
        while not Core do
            Core = exports["qb-core"]:GetCoreObject()
            if not Core then Citizen.Wait(200) end
        end
    end

    -- Auto-execute schema migrations
    if Config.AutoExecuteQuery then
        local statsCol = Config.Core == "ESX" and "users" or "players"
        MySQL.Async.execute([[
            ALTER TABLE ]] .. statsCol .. [[ ADD COLUMN IF NOT EXISTS `statistics` LONGTEXT DEFAULT NULL
        ]], {}, function() end)
    end

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gym_businesses` (
            `id`           INT AUTO_INCREMENT PRIMARY KEY,
            `gym`          VARCHAR(64) NOT NULL UNIQUE,
            `balance`      INT NOT NULL DEFAULT 0,
            `total_earned` INT NOT NULL DEFAULT 0,
            `announcements` LONGTEXT NOT NULL DEFAULT '[]'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function() end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `gym_memberships` (
            `id`         INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(64) NOT NULL,
            `gym`        VARCHAR(64) NOT NULL,
            `name`       VARCHAR(64) NOT NULL,
            `time`       BIGINT NOT NULL DEFAULT 0,
            UNIQUE KEY `uq_membership` (`identifier`, `gym`, `name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function() end)

    Citizen.Wait(1000)
    loadAllGymBusinesses()
end)

-- ── Helpers ──────────────────────────────────────────────────

function GetPlayerIdentifier(src)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    end
end

function GetPlayerName(src)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        return xPlayer and xPlayer.getName()
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        return player and (player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname)
    end
end

function GetPlayerByIdentifier(identifier)
    if Config.Core == "ESX" then
        return Core.GetPlayerFromIdentifier(identifier)
    elseif Config.Core == "QB-Core" then
        return Core.Functions.GetPlayerByCitizenId(identifier)
    end
end

function GetPlayerJob(src)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        return xPlayer and xPlayer.job
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        return player and player.PlayerData.job
    end
end

function GetPlayerMoney(src, account)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        if not xPlayer then return 0 end
        return account == "cash" and xPlayer.getMoney() or xPlayer.getAccount("bank").money
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        if not player then return 0 end
        return account == "cash" and player.PlayerData.money["cash"] or player.PlayerData.money["bank"]
    end
    return 0
end

function RemovePlayerMoney(src, account, amount)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        if not xPlayer then return false end
        if account == "cash" then
            xPlayer.removeMoney(amount)
        else
            xPlayer.removeAccountMoney("bank", amount)
        end
        return true
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        if not player then return false end
        return player.Functions.RemoveMoney(account, amount)
    end
    return false
end

function AddPlayerMoney(src, account, amount)
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        if not xPlayer then return end
        if account == "cash" then
            xPlayer.addMoney(amount)
        else
            xPlayer.addAccountMoney("bank", amount)
        end
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(src)
        if player then
            player.Functions.AddMoney(account, amount)
        end
    end
end

function NotifyPlayer(src, title, message, time, icon, notifType, isSkillInfo)
    TriggerClientEvent("vms_gym:notification", src, title, message, time or 3000, icon or "fa-solid fa-dumbbell", notifType or "info", isSkillInfo)
end

-- ── Gym business data ─────────────────────────────────────────

function loadAllGymBusinesses()
    MySQL.Async.fetchAll("SELECT * FROM `gym_businesses`", {}, function(rows)
        for gymId, _ in pairs(Config.Gyms) do
            gymBusinesses[gymId] = {
                data = {
                    balance      = 0,
                    totalEarned  = 0,
                    announcements = {},
                }
            }
        end

        if rows then
            for _, row in ipairs(rows) do
                if gymBusinesses[row.gym] then
                    gymBusinesses[row.gym].data.balance     = row.balance
                    gymBusinesses[row.gym].data.totalEarned = row.total_earned
                    local ok, announcements = pcall(json.decode, row.announcements)
                    gymBusinesses[row.gym].data.announcements = (ok and announcements) or {}
                end
            end
        end

        -- Ensure every gym has a DB row
        for gymId, _ in pairs(Config.Gyms) do
            MySQL.Async.execute(
                "INSERT IGNORE INTO `gym_businesses` (`gym`, `balance`, `total_earned`, `announcements`) VALUES (@gym, 0, 0, '[]')",
                { ["@gym"] = gymId },
                function() end
            )
        end
    end)
end

function saveGymBusiness(gymId)
    if not gymBusinesses[gymId] then return end
    local d = gymBusinesses[gymId].data
    MySQL.Async.execute(
        "UPDATE `gym_businesses` SET `balance` = @balance, `total_earned` = @total_earned, `announcements` = @announcements WHERE `gym` = @gym",
        {
            ["@gym"]           = gymId,
            ["@balance"]       = d.balance,
            ["@total_earned"]  = d.totalEarned,
            ["@announcements"] = json.encode(d.announcements),
        },
        function() end
    )
end

function broadcastBusinessUpdate(gymId, sub, value)
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent("vms_gym:updateBusiness", tonumber(playerId), gymId, nil, { sub = sub, value = value })
    end
end

function broadcastFullBusinessUpdate(gymId)
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent("vms_gym:updateBusiness", tonumber(playerId), gymId, gymBusinesses[gymId])
    end
end

-- ── Player statistics ─────────────────────────────────────────

function getDefaultStats()
    return { strenght = 0.0, condition = 0.0, shooting = 0.0, driving = 0.0, flying = 0.0 }
end

function loadPlayerStats(src, identifier, cb)
    local tableName = Config.Core == "ESX" and "users" or "players"
    local column    = Config.Core == "ESX" and "identifier" or "citizenid"
    MySQL.Async.fetchAll(
        "SELECT `statistics` FROM `" .. tableName .. "` WHERE `" .. column .. "` = @id LIMIT 1",
        { ["@id"] = identifier },
        function(rows)
            local stats = getDefaultStats()
            if rows and rows[1] and rows[1].statistics then
                local ok, decoded = pcall(json.decode, rows[1].statistics)
                if ok and decoded then
                    for k, v in pairs(decoded) do
                        if stats[k] ~= nil then
                            stats[k] = tonumber(v) or 0.0
                        end
                    end
                end
            end
            playerStats[identifier] = stats
            if cb then cb(stats) end
        end
    )
end

function savePlayerStats(identifier)
    if not playerStats[identifier] then return end
    local tableName = Config.Core == "ESX" and "users" or "players"
    local column    = Config.Core == "ESX" and "identifier" or "citizenid"
    MySQL.Async.execute(
        "UPDATE `" .. tableName .. "` SET `statistics` = @stats WHERE `" .. column .. "` = @id",
        {
            ["@stats"] = json.encode(playerStats[identifier]),
            ["@id"]    = identifier,
        },
        function() end
    )
end

-- Periodic save
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SavingTimeout)
        for identifier, _ in pairs(playerStats) do
            savePlayerStats(identifier)
        end
    end
end)

-- ── Player memberships ────────────────────────────────────────

function loadPlayerMemberships(identifier, cb)
    MySQL.Async.fetchAll(
        "SELECT `gym`, `name`, `time` FROM `gym_memberships` WHERE `identifier` = @id",
        { ["@id"] = identifier },
        function(rows)
            local memberships = {}
            local now = os.time()
            if rows then
                for _, row in ipairs(rows) do
                    if row.time > now then
                        table.insert(memberships, { name = row.name, gym = row.gym, time = row.time })
                    end
                end
            end
            if cb then cb(memberships) end
        end
    )
end

function addMembership(identifier, gymId, membershipName, days, hours)
    local now = os.time()
    local expiry = now + (days and (days * 86400) or 0) + (hours and (hours * 3600) or 0)
    MySQL.Async.execute(
        [[INSERT INTO `gym_memberships` (`identifier`, `gym`, `name`, `time`)
          VALUES (@id, @gym, @name, @time)
          ON DUPLICATE KEY UPDATE `time` = GREATEST(`time`, @time)]],
        {
            ["@id"]   = identifier,
            ["@gym"]  = gymId,
            ["@name"] = membershipName,
            ["@time"] = expiry,
        },
        function() end
    )
    return expiry
end

-- ── Player Load / Unload ──────────────────────────────────────

RegisterNetEvent(Config.PlayerLoadedServer)
AddEventHandler(Config.PlayerLoadedServer, function(player)
    local src = source
    local identifier
    if Config.Core == "ESX" then
        local xPlayer = Core.GetPlayerFromId(src)
        identifier = xPlayer and xPlayer.identifier
    elseif Config.Core == "QB-Core" then
        if type(player) == "table" then
            identifier = player.PlayerData and player.PlayerData.citizenid
        else
            local p = Core.Functions.GetPlayer(src)
            identifier = p and p.PlayerData.citizenid
        end
    end
    if not identifier then return end
    loadPlayerStats(src, identifier, function() end)
end)

RegisterNetEvent(Config.PlayerLogoutServer)
AddEventHandler(Config.PlayerLogoutServer, function(reason)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end
    savePlayerStats(identifier)
    playerStats[identifier] = nil
    pendingBills[src] = nil
end)

-- ── vms_gym:fetchData ─────────────────────────────────────────

RegisterNetEvent("vms_gym:fetchData")
AddEventHandler("vms_gym:fetchData", function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end

    -- Ensure stats loaded
    if not playerStats[identifier] then
        loadPlayerStats(src, identifier, function(stats)
            TriggerClientEvent("vms_gym:cl:updateStatistic", src, stats)
        end)
    else
        TriggerClientEvent("vms_gym:cl:updateStatistic", src, playerStats[identifier])
    end

    -- Send gym businesses
    TriggerClientEvent("vms_gym:fetchedData", src, gymBusinesses)

    -- Send memberships
    loadPlayerMemberships(identifier, function(memberships)
        TriggerClientEvent("vms_gym:cl:getMemberships", src, memberships)
    end)
end)

-- ── vms_gym:sv:restartPlayer ──────────────────────────────────

RegisterNetEvent("vms_gym:sv:restartPlayer")
AddEventHandler("vms_gym:sv:restartPlayer", function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end

    loadPlayerStats(src, identifier, function(stats)
        TriggerClientEvent("vms_gym:cl:updateStatistic", src, stats)
    end)

    TriggerClientEvent("vms_gym:fetchedData", src, gymBusinesses)

    loadPlayerMemberships(identifier, function(memberships)
        TriggerClientEvent("vms_gym:cl:getMemberships", src, memberships)
    end)
end)

-- ── vms_gym:sv:addValue ───────────────────────────────────────

RegisterNetEvent("vms_gym:sv:addValue")
AddEventHandler("vms_gym:sv:addValue", function(skillName, value)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end

    if not playerStats[identifier] then
        playerStats[identifier] = getDefaultStats()
    end

    if playerStats[identifier][skillName] == nil then return end

    local prev = playerStats[identifier][skillName]
    local new  = math.min(100.0, prev + value)
    playerStats[identifier][skillName] = new

    TriggerClientEvent("vms_gym:cl:updateStatistic", src, playerStats[identifier])

    if Config.SendNotificationWhenSkillIncrase then
        local diff = math.floor((new - prev) * 10) / 10
        if diff > 0 then
            local title = TRANSLATE("notify.title." .. skillName) or skillName
            local msg   = string.format(TRANSLATE("incrase_" .. skillName) or "+%s", diff)
            NotifyPlayer(src, title, msg, 3000, "fa-solid fa-dumbbell", "success", true)
        end
    end
end)

-- ── vms_gym:sv:removeValue ────────────────────────────────────

RegisterNetEvent("vms_gym:sv:removeValue")
AddEventHandler("vms_gym:sv:removeValue", function(skillName, value)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end

    if not playerStats[identifier] then
        playerStats[identifier] = getDefaultStats()
    end

    if playerStats[identifier][skillName] == nil then return end

    local prev = playerStats[identifier][skillName]
    local new  = math.max(0.0, prev - value)
    playerStats[identifier][skillName] = new

    TriggerClientEvent("vms_gym:cl:updateStatistic", src, playerStats[identifier])

    if Config.SendNotificationWhenSkillDecrease then
        local diff = math.floor((prev - new) * 10) / 10
        if diff > 0 then
            local title = TRANSLATE("notify.title." .. skillName) or skillName
            local msg   = string.format(TRANSLATE("decrease_" .. skillName) or "-%s", diff)
            NotifyPlayer(src, title, msg, 3000, "fa-solid fa-dumbbell", "info", true)
        end
    end
end)

-- ── vms_gym:sv:setTaken ───────────────────────────────────────

RegisterNetEvent("vms_gym:sv:setTaken")
AddEventHandler("vms_gym:sv:setTaken", function(gymId, pointIndex, taken)
    local src = source
    TriggerClientEvent("vms_gym:cl:setTaken", -1, gymId, pointIndex, taken)
end)

-- ── vms_gym:sendAnnouncement ──────────────────────────────────

RegisterNetEvent("vms_gym:sendAnnouncement")
AddEventHandler("vms_gym:sendAnnouncement", function(gymId, text)
    local src = source
    if not gymId or not text or text == "" then return end
    if not Config.Gyms[gymId] then return end

    -- Verify the player is an employee
    local job = GetPlayerJob(src)
    if not job then return end
    if job.name ~= Config.Gyms[gymId].ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local senderName = GetPlayerName(src) or "Unknown"
    if not gymBusinesses[gymId] then return end

    local announcement = { name = senderName, message = text }
    table.insert(gymBusinesses[gymId].data.announcements, announcement)

    -- Keep only last 20 announcements
    while #gymBusinesses[gymId].data.announcements > 20 do
        table.remove(gymBusinesses[gymId].data.announcements, 1)
    end

    saveGymBusiness(gymId)

    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent("vms_gym:updateBusiness", tonumber(playerId), gymId, nil, {
            sub   = "announcements",
            value = gymBusinesses[gymId].data.announcements,
        })
    end
end)

-- ── vms_gym:hireAnEmployee ────────────────────────────────────

RegisterNetEvent("vms_gym:hireAnEmployee")
AddEventHandler("vms_gym:hireAnEmployee", function(gymId, targetPlayerId)
    local src = source
    if not gymId or not targetPlayerId then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:player_is_offline"), 3000, nil, "error")
        return
    end

    -- Distance check
    local srcCoords    = GetEntityCoords(GetPlayerPed(src))
    local targetCoords = GetEntityCoords(GetPlayerPed(targetSrc))
    if #(srcCoords - targetCoords) > 10.0 then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:player_is_too_far_away"), 3000, nil, "error")
        return
    end

    local targetJob = GetPlayerJob(targetSrc)
    if not targetJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:player_is_offline"), 3000, nil, "error")
        return
    end

    if targetJob.name ~= Config.RequiredJobToBeHired then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:must_be_unemployed"), 3000, nil, "error")
        return
    end

    if Config.Core == "ESX" then
        local xTarget = Core.GetPlayerFromId(targetSrc)
        if xTarget then xTarget.setJob(gymCfg.ownerJob, 0) end
    elseif Config.Core == "QB-Core" then
        local player = Core.Functions.GetPlayer(targetSrc)
        if player then player.Functions.SetJob(gymCfg.ownerJob, 0) end
    end

    NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:you_employee_hired"), 3500, nil, "success")

    -- Refresh management menus
    TriggerClientEvent("vms_gym:updateBusiness", src, gymId, nil, { sub = "employees" })
end)

-- ── vms_gym:bonusEmployee ─────────────────────────────────────

RegisterNetEvent("vms_gym:bonusEmployee")
AddEventHandler("vms_gym:bonusEmployee", function(gymId, identifier, bonusMoney)
    local src = source
    if not gymId or not identifier or not bonusMoney then return end
    if not Config.Gyms[gymId] then return end

    bonusMoney = tonumber(bonusMoney)
    if not bonusMoney or bonusMoney < 1 then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    if Config.UseBuildInCompanyBalance then
        if not gymBusinesses[gymId] then return end
        if gymBusinesses[gymId].data.balance < bonusMoney then
            NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.balance:store_dont_have_that_money"), 3000, nil, "error")
            return
        end
        gymBusinesses[gymId].data.balance = gymBusinesses[gymId].data.balance - bonusMoney
        saveGymBusiness(gymId)
        broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)
    end

    local targetPlayer = GetPlayerByIdentifier(identifier)
    if targetPlayer then
        AddPlayerMoney(targetPlayer.source or targetPlayer, "cash", bonusMoney)
        NotifyPlayer(targetPlayer.source or targetPlayer, TRANSLATE("notify.title.gym"),
            string.format(TRANSLATE("notify.employees:received_bonus") or "Received a bonus of $%s", bonusMoney),
            3500, nil, "success")
    end

    NotifyPlayer(src, TRANSLATE("notify.title.gym"),
        string.format(TRANSLATE("notify.employees:awarded_bonus") or "You awarded a $%s bonus", bonusMoney),
        3500, nil, "success")
end)

-- ── vms_gym:changeGradeEmployee ───────────────────────────────

RegisterNetEvent("vms_gym:changeGradeEmployee")
AddEventHandler("vms_gym:changeGradeEmployee", function(gymId, identifier, grade)
    local src = source
    if not gymId or not identifier or not grade then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    -- Check if needToBeBoss requires boss role
    if grade.needToBeBoss then
        local isBoss = false
        local bossGrades = gymCfg.boss_grades
        if Config.Core == "ESX" then
            if type(bossGrades) == "table" then
                for _, g in ipairs(bossGrades) do
                    if srcJob.grade_name == g then isBoss = true break end
                end
            else
                isBoss = srcJob.grade_name == bossGrades
            end
        elseif Config.Core == "QB-Core" then
            if type(bossGrades) == "table" then
                for _, g in ipairs(bossGrades) do
                    if srcJob.grade and srcJob.grade.name == g then isBoss = true break end
                end
            else
                isBoss = srcJob.grade and srcJob.grade.name == bossGrades
            end
        end
        if not isBoss then
            NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
            return
        end
    end

    local targetPlayer = GetPlayerByIdentifier(identifier)
    if targetPlayer then
        local targetSrc = targetPlayer.source or targetPlayer
        if Config.Core == "ESX" then
            local xTarget = Core.GetPlayerFromId(targetSrc)
            if xTarget then xTarget.setJob(gymCfg.ownerJob, grade.grade) end
        elseif Config.Core == "QB-Core" then
            local player = Core.Functions.GetPlayer(targetSrc)
            if player then player.Functions.SetJob(gymCfg.ownerJob, grade.grade) end
        end
    end

    TriggerClientEvent("vms_gym:updateBusiness", src, gymId, nil, { sub = "employees" })
end)

-- ── vms_gym:fireEmployee ──────────────────────────────────────

RegisterNetEvent("vms_gym:fireEmployee")
AddEventHandler("vms_gym:fireEmployee", function(gymId, identifier)
    local src = source
    if not gymId or not identifier then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local targetPlayer = GetPlayerByIdentifier(identifier)
    if targetPlayer then
        local targetSrc = targetPlayer.source or targetPlayer
        if Config.Core == "ESX" then
            local xTarget = Core.GetPlayerFromId(targetSrc)
            if xTarget then xTarget.setJob("unemployed", 0) end
        elseif Config.Core == "QB-Core" then
            local player = Core.Functions.GetPlayer(targetSrc)
            if player then player.Functions.SetJob("unemployed", 0) end
        end
    end

    TriggerClientEvent("vms_gym:updateBusiness", src, gymId, nil, { sub = "employees" })
end)

-- ── vms_gym:withdraw ─────────────────────────────────────────

RegisterNetEvent("vms_gym:withdraw")
AddEventHandler("vms_gym:withdraw", function(gymId, amount)
    local src = source
    if not gymId or not amount then return end

    amount = tonumber(amount)
    if not amount or amount < 1 then return end
    if not Config.Gyms[gymId] then return end
    if not gymBusinesses[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    if gymBusinesses[gymId].data.balance < amount then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.balance:store_dont_have_that_money"), 3000, nil, "error")
        return
    end

    gymBusinesses[gymId].data.balance = gymBusinesses[gymId].data.balance - amount
    saveGymBusiness(gymId)
    AddPlayerMoney(src, "cash", amount)
    broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)

    NotifyPlayer(src, TRANSLATE("notify.title.gym"),
        string.format(TRANSLATE("notify.balance:withdraw") or "You withdrew $%s", amount),
        3500, nil, "success")
end)

-- ── vms_gym:deposit ──────────────────────────────────────────

RegisterNetEvent("vms_gym:deposit")
AddEventHandler("vms_gym:deposit", function(gymId, amount)
    local src = source
    if not gymId or not amount then return end

    amount = tonumber(amount)
    if not amount or amount < 1 then return end
    if not Config.Gyms[gymId] then return end
    if not gymBusinesses[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local playerCash = GetPlayerMoney(src, "cash")
    if playerCash < amount then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.balance:you_dont_have_that_money"), 3000, nil, "error")
        return
    end

    RemovePlayerMoney(src, "cash", amount)
    gymBusinesses[gymId].data.balance = gymBusinesses[gymId].data.balance + amount
    saveGymBusiness(gymId)
    broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)

    NotifyPlayer(src, TRANSLATE("notify.title.gym"),
        string.format(TRANSLATE("notify.balance:deposit") or "You deposited $%s", amount),
        3500, nil, "success")
end)

-- ── vms_gym:sv:buyProtein ─────────────────────────────────────

RegisterNetEvent("vms_gym:sv:buyProtein")
AddEventHandler("vms_gym:sv:buyProtein", function(gymId, proteinName)
    local src = source
    if not gymId or not proteinName then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    if not gymCfg.proteins or not gymCfg.proteins[proteinName] then return end
    if not gymCfg.allowBuyProteins then return end

    local protein  = gymCfg.proteins[proteinName]
    local price    = protein.price or 0
    local account  = "cash"

    if price > 0 then
        local playerMoney = GetPlayerMoney(src, account)
        if playerMoney < price then
            NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.nomoney"), 3000, nil, "error")
            return
        end
        RemovePlayerMoney(src, account, price)

        -- Add to gym earnings if built-in balance is enabled
        if Config.UseBuildInCompanyBalance and gymBusinesses[gymId] then
            gymBusinesses[gymId].data.balance     = gymBusinesses[gymId].data.balance + price
            gymBusinesses[gymId].data.totalEarned = gymBusinesses[gymId].data.totalEarned + price
            saveGymBusiness(gymId)
            broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)
            broadcastBusinessUpdate(gymId, "totalEarned", gymBusinesses[gymId].data.totalEarned)
        end
    end

    -- Apply protein booster effect
    if proteinName == "protein" then
        TriggerClientEvent("vms_gym:runStrengthBooster", src, 1.5, 300000) -- 1.5x for 5 min
    elseif proteinName == "runbooster" then
        TriggerClientEvent("vms_gym:runConditionBooster", src, 1.5, 300000)
    end

    NotifyPlayer(src, TRANSLATE("notify.title.gym"),
        string.format(TRANSLATE("bought_proteins") or "You bought %s %sx.", protein.label or proteinName, 1),
        3500, nil, "success")
end)

-- ── vms_gym:sv:acceptMembership ──────────────────────────────

RegisterNetEvent("vms_gym:sv:acceptMembership")
AddEventHandler("vms_gym:sv:acceptMembership", function(gymId, membershipName, membershipData)
    local src = source
    if not gymId or not membershipName or not membershipData then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    if not gymCfg.allowBuyMembership then return end
    if gymCfg.requiredMembership ~= membershipName then return end

    local price   = membershipData.price or 0
    local days    = membershipData.days or 0
    local hours   = membershipData.hours or 0
    local account = "cash"

    if price > 0 then
        local playerMoney = GetPlayerMoney(src, account)
        if playerMoney < price then
            NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.nomoney"), 3000, nil, "error")
            return
        end
        RemovePlayerMoney(src, account, price)

        if Config.UseBuildInCompanyBalance and gymBusinesses[gymId] then
            gymBusinesses[gymId].data.balance     = gymBusinesses[gymId].data.balance + price
            gymBusinesses[gymId].data.totalEarned = gymBusinesses[gymId].data.totalEarned + price
            saveGymBusiness(gymId)
            broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)
            broadcastBusinessUpdate(gymId, "totalEarned", gymBusinesses[gymId].data.totalEarned)
        end
    end

    local identifier = GetPlayerIdentifier(src)
    if not identifier then return end

    local expiry = addMembership(identifier, gymId, membershipName, days, hours)

    -- Send updated memberships to client
    loadPlayerMemberships(identifier, function(memberships)
        TriggerClientEvent("vms_gym:cl:getMemberships", src, memberships)
    end)

    NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("bought_membership"), 3500, nil, "success")
end)

-- ── vms_gym:sv:sellMembership ─────────────────────────────────

RegisterNetEvent("vms_gym:sv:sellMembership")
AddEventHandler("vms_gym:sv:sellMembership", function(targetPlayerId, gymId, membershipData)
    local src = source
    if not targetPlayerId or not gymId or not membershipData then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:player_is_offline"), 3000, nil, "error")
        return
    end

    -- Bill the target player; payment handled in sv:payBill
    pendingBills[targetSrc] = {
        sellerId       = src,
        gymId          = gymId,
        membershipData = membershipData,
    }

    TriggerClientEvent("vms_gym:cl:getBill", targetSrc, nil, membershipData, nil, nil)
    NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_sent_bill"), 3500, nil, "info")
end)

-- ── vms_gym:sv:sellProtein ────────────────────────────────────

RegisterNetEvent("vms_gym:sv:sellProtein")
AddEventHandler("vms_gym:sv:sellProtein", function(targetPlayerId, gymId, proteinData, count)
    local src = source
    if not targetPlayerId or not gymId or not proteinData then return end
    if not Config.Gyms[gymId] then return end

    local gymCfg = Config.Gyms[gymId]
    local srcJob = GetPlayerJob(src)
    if not srcJob or srcJob.name ~= gymCfg.ownerJob then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_are_not_owner"), 3000, nil, "error")
        return
    end

    local targetSrc = tonumber(targetPlayerId)
    if not GetPlayerName(targetSrc) then
        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.employees:player_is_offline"), 3000, nil, "error")
        return
    end

    count = tonumber(count) or 1

    pendingBills[targetSrc] = {
        sellerId     = src,
        gymId        = gymId,
        proteinsData = proteinData,
        count        = count,
    }

    TriggerClientEvent("vms_gym:cl:getBill", targetSrc, nil, nil, proteinData, count)
    NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.you_sent_bill"), 3500, nil, "info")
end)

-- ── vms_gym:sv:payBill ────────────────────────────────────────

RegisterNetEvent("vms_gym:sv:payBill")
AddEventHandler("vms_gym:sv:payBill", function(action, payType)
    local src = source
    local bill = pendingBills[src]
    if not bill then return end

    if action == "cancel" then
        pendingBills[src] = nil
        if bill.sellerId and GetPlayerName(bill.sellerId) then
            NotifyPlayer(bill.sellerId, TRANSLATE("notify.title.gym"), TRANSLATE("customer_did_not_buy"), 3000, nil, "error")
        end
        return
    end

    if action ~= "pay" then return end

    local gymId  = bill.gymId
    local gymCfg = Config.Gyms[gymId]

    -- ── Membership bill ──
    if bill.membershipData then
        local membershipData = bill.membershipData
        local price          = membershipData.price or 0
        local account        = payType == "bank" and "bank" or "cash"

        if price > 0 then
            local playerMoney = GetPlayerMoney(src, account)
            if playerMoney < price then
                NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.nomoney"), 3000, nil, "error")
                TriggerClientEvent("vms_gym:cl:getBillFeedback", src)
                pendingBills[src] = nil
                return
            end
            RemovePlayerMoney(src, account, price)

            -- Society split
            local societyPct = Config.BillMoneyToSocietyPercent or 100
            local sellerPct  = Config.BillMoneyToSellerPercent  or 0
            local societyAmt = math.floor(price * societyPct / 100)
            local sellerAmt  = price - societyAmt

            if Config.UseBuildInCompanyBalance and gymBusinesses[gymId] then
                gymBusinesses[gymId].data.balance     = gymBusinesses[gymId].data.balance + societyAmt
                gymBusinesses[gymId].data.totalEarned = gymBusinesses[gymId].data.totalEarned + societyAmt
                saveGymBusiness(gymId)
                broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)
                broadcastBusinessUpdate(gymId, "totalEarned", gymBusinesses[gymId].data.totalEarned)
            end

            if sellerAmt > 0 and bill.sellerId and GetPlayerName(bill.sellerId) then
                AddPlayerMoney(bill.sellerId, "cash", sellerAmt)
            end
        end

        -- Add membership to buyer
        local identifier = GetPlayerIdentifier(src)
        if identifier then
            addMembership(identifier, gymId, gymCfg.requiredMembership, membershipData.days, membershipData.hours)
            loadPlayerMemberships(identifier, function(memberships)
                TriggerClientEvent("vms_gym:cl:getMemberships", src, memberships)
            end)
        end

        NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("bought_membership"), 3500, nil, "success")
        if bill.sellerId and GetPlayerName(bill.sellerId) then
            NotifyPlayer(bill.sellerId, TRANSLATE("notify.title.gym"), TRANSLATE("selled_membership"), 3500, nil, "success")
        end

    -- ── Protein bill ──
    elseif bill.proteinsData then
        local proteinData = bill.proteinsData
        local count       = bill.count or 1
        local price       = (proteinData.price or 0) * count
        local account     = payType == "bank" and "bank" or "cash"

        if price > 0 then
            local playerMoney = GetPlayerMoney(src, account)
            if playerMoney < price then
                NotifyPlayer(src, TRANSLATE("notify.title.gym"), TRANSLATE("notify.nomoney"), 3000, nil, "error")
                TriggerClientEvent("vms_gym:cl:getBillFeedback", src)
                pendingBills[src] = nil
                return
            end
            RemovePlayerMoney(src, account, price)

            local societyPct = Config.BillMoneyToSocietyPercent or 100
            local sellerPct  = Config.BillMoneyToSellerPercent  or 0
            local societyAmt = math.floor(price * societyPct / 100)
            local sellerAmt  = price - societyAmt

            if Config.UseBuildInCompanyBalance and gymBusinesses[gymId] then
                gymBusinesses[gymId].data.balance     = gymBusinesses[gymId].data.balance + societyAmt
                gymBusinesses[gymId].data.totalEarned = gymBusinesses[gymId].data.totalEarned + societyAmt
                saveGymBusiness(gymId)
                broadcastBusinessUpdate(gymId, "balance", gymBusinesses[gymId].data.balance)
                broadcastBusinessUpdate(gymId, "totalEarned", gymBusinesses[gymId].data.totalEarned)
            end

            if sellerAmt > 0 and bill.sellerId and GetPlayerName(bill.sellerId) then
                AddPlayerMoney(bill.sellerId, "cash", sellerAmt)
            end
        end

        -- Apply booster to buyer
        local proteinName = proteinData.name
        for i = 1, count do
            if proteinName == "protein" then
                TriggerClientEvent("vms_gym:runStrengthBooster", src, 1.5, 300000)
            elseif proteinName == "runbooster" then
                TriggerClientEvent("vms_gym:runConditionBooster", src, 1.5, 300000)
            end
        end

        NotifyPlayer(src, TRANSLATE("notify.title.gym"),
            string.format(TRANSLATE("bought_proteins") or "You bought %s %sx.", proteinData.label or proteinName, count),
            3500, nil, "success")

        if bill.sellerId and GetPlayerName(bill.sellerId) then
            NotifyPlayer(bill.sellerId, TRANSLATE("notify.title.gym"),
                string.format(TRANSLATE("sold_proteins") or "You sold %s %sx.", proteinData.label or proteinName, count),
                3500, nil, "success")
        end
    end

    TriggerClientEvent("vms_gym:cl:getBillFeedback", src)
    pendingBills[src] = nil
end)

-- ── ESX Society balance check (built-in passthrough) ──────────

-- When UseBuildInCompanyBalance = false, esx_society handles things.
-- When true, we intercept the check event and respond with our balance.
if Config.UseBuildInCompanyBalance then
    RegisterNetEvent(Config.ESXSocietyEvents and Config.ESXSocietyEvents.check or "esx_society:checkSocietyBalance")
    AddEventHandler(Config.ESXSocietyEvents and Config.ESXSocietyEvents.check or "esx_society:checkSocietyBalance", function(ownerJob)
        local src = source
        for gymId, gymCfg in pairs(Config.Gyms) do
            if gymCfg.ownerJob == ownerJob then
                if gymBusinesses[gymId] then
                    TriggerClientEvent("vms_gym:updateBusiness", src, gymId, nil, {
                        sub   = "balance",
                        value = gymBusinesses[gymId].data.balance,
                    })
                end
                break
            end
        end
    end)
end
