-- ██╗   ██╗███╗   ███╗███████╗     ██████╗ ██╗   ██╗███╗   ███╗    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
-- ██║   ██║████╗ ████║██╔════╝    ██╔════╝ ╚██╗ ██╔╝████╗ ████║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
-- ██║   ██║██╔████╔██║███████╗    ██║  ███╗ ╚████╔╝ ██╔████╔██║    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
-- ╚██╗ ██╔╝██║╚██╔╝██║╚════██║    ██║   ██║  ╚██╔╝  ██║╚██╔╝██║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
--  ╚████╔╝ ██║ ╚═╝ ██║███████║    ╚██████╔╝   ██║   ██║ ╚═╝ ██║    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
--   ╚═══╝  ╚═╝     ╚═╝╚══════╝     ╚═════╝    ╚═╝   ╚═╝     ╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝

-- ─────────────────────────────────────────────────────────────
--  FRAMEWORK BOOTSTRAP
-- ─────────────────────────────────────────────────────────────

if Config.Core == "ESX" then
    ESX = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
end

-- ─────────────────────────────────────────────────────────────
--  SV HELPER TABLE  (can be overridden in config/config.server.lua)
-- ─────────────────────────────────────────────────────────────

SV = {}

SV.GetPlayer = function(source)
    if Config.Core == "ESX" then
        return ESX.GetPlayerFromId(source)
    elseif Config.Core == "QB-Core" then
        return QBCore.Functions.GetPlayer(source)
    end
end

SV.GetIdentifier = function(source)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then return xPlayer.identifier end
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then return Player.PlayerData.citizenid end
    end
    return nil
end

SV.GetPlayerJob = function(source)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then return xPlayer.job end
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then return Player.PlayerData.job end
    end
    return nil
end

SV.GetPlayerName = function(source)
    return GetPlayerName(source)
end

SV.GetPlayerByIdentifier = function(identifier)
    if Config.Core == "ESX" then
        return ESX.GetPlayerFromIdentifier(identifier)
    elseif Config.Core == "QB-Core" then
        return QBCore.Functions.GetPlayerByCitizenId(identifier)
    end
    return nil
end

SV.GetSourceFromPlayer = function(player)
    if Config.Core == "ESX" then
        return player.source
    elseif Config.Core == "QB-Core" then
        return player.PlayerData.source
    end
    return nil
end

SV.HasMoney = function(source, moneyType, amount)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = moneyType == 'cash' and 'money' or 'bank'
        return xPlayer.getAccount(account).money >= amount
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local mtype = moneyType == 'cash' and 'cash' or 'bank'
        return (Player.PlayerData.money[mtype] or 0) >= amount
    end
    return false
end

SV.RemoveMoney = function(source, moneyType, amount, reason)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = moneyType == 'cash' and 'money' or 'bank'
        xPlayer.removeAccountMoney(account, amount)
        return true
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local mtype = moneyType == 'cash' and 'cash' or 'bank'
        Player.Functions.RemoveMoney(mtype, amount, reason or 'vms_gym')
        return true
    end
    return false
end

SV.AddMoney = function(source, moneyType, amount, reason)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local account = moneyType == 'cash' and 'money' or 'bank'
        xPlayer.addAccountMoney(account, amount)
        return true
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local mtype = moneyType == 'cash' and 'cash' or 'bank'
        Player.Functions.AddMoney(mtype, amount, reason or 'vms_gym')
        return true
    end
    return false
end

SV.AddItem = function(source, itemName, count)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.addInventoryItem(itemName, count)
        return true
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        Player.Functions.AddItem(itemName, count)
        if QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[itemName] then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add', count)
        end
        return true
    end
    return false
end

SV.SetJob = function(source, jobName, grade)
    if Config.Core == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        xPlayer.setJob(jobName, grade)
        return true
    elseif Config.Core == "QB-Core" then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        Player.Functions.SetJob(jobName, grade)
        return true
    end
    return false
end

SV.Notification = function(source, title, message, time, icon, notifType, isSkillInfo)
    TriggerClientEvent('vms_gym:notification', source, title, message, time or 3500, icon or 'fa-solid fa-dumbbell', notifType or 'info', isSkillInfo)
end

-- DB table/column names per framework
SV.TableName       = Config.Core == "ESX" and "users"      or "players"
SV.IdentifierCol   = Config.Core == "ESX" and "identifier" or "citizenid"

-- ─────────────────────────────────────────────────────────────
--  SERVER STATE
-- ─────────────────────────────────────────────────────────────

local playersData  = {}   -- [source] = {identifier, statistics, memberships}
local gymStores    = {}   -- [gymId]  = {data={balance,totalEarned}, announcements={}}
local billsPending = {}   -- [buyerSource] = {sellerId, gymId, type, ...}

local defaultStats = {
    strenght  = 0.0,
    condition = 0.0,
    shooting  = 0.0,
    driving   = 0.0,
    flying    = 0.0,
}

-- ─────────────────────────────────────────────────────────────
--  DATABASE HELPERS
-- ─────────────────────────────────────────────────────────────

local function setupDatabase()
    -- Add statistics column to users/players if missing
    if Config.AutoExecuteQuery then
        MySQL.query(string.format(
            "ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `statistics` TEXT DEFAULT NULL",
            SV.TableName
        ))
    end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `gym_memberships` (
            `id`         INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60)  NOT NULL,
            `membership` VARCHAR(60)  NOT NULL DEFAULT '',
            `time`       BIGINT       NOT NULL,
            UNIQUE KEY `uk_ident_member` (`identifier`,`membership`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    -- Guard: if the table pre-existed with different schema (e.g. a `name` column
    -- instead of `membership`), add the missing column so INSERTs don't fail.
    MySQL.query("ALTER TABLE `gym_memberships` ADD COLUMN IF NOT EXISTS `membership` VARCHAR(60) NOT NULL DEFAULT ''")

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `gym_stores` (
            `store_id`      VARCHAR(60) NOT NULL PRIMARY KEY,
            `balance`       INT         NOT NULL DEFAULT 0,
            `total_earned`  INT         NOT NULL DEFAULT 0,
            `announcements` MEDIUMTEXT
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function loadGymStores()
    MySQL.query('SELECT * FROM `gym_stores`', {}, function(rows)
        if rows then
            for _, row in ipairs(rows) do
                if gymStores[row.store_id] then
                    gymStores[row.store_id].data.balance     = row.balance      or 0
                    gymStores[row.store_id].data.totalEarned = row.total_earned or 0
                    if row.announcements then
                        local ok, decoded = pcall(json.decode, row.announcements)
                        if ok and type(decoded) == 'table' then
                            gymStores[row.store_id].announcements = decoded
                        end
                    end
                end
            end
        end
        -- Ensure every gym has a row in the table
        for gymId in pairs(gymStores) do
            MySQL.query(
                'INSERT IGNORE INTO `gym_stores` (`store_id`,`balance`,`total_earned`) VALUES (?,?,?)',
                {gymId, 0, 0}
            )
        end
    end)
end

local function saveGymStore(gymId)
    if not gymStores[gymId] then return end
    local s = gymStores[gymId]
    MySQL.update(
        'UPDATE `gym_stores` SET `balance`=?,`total_earned`=?,`announcements`=? WHERE `store_id`=?',
        {s.data.balance, s.data.totalEarned, json.encode(s.announcements), gymId}
    )
end

local function loadPlayerStats(identifier, cb)
    MySQL.query(
        string.format('SELECT `statistics` FROM `%s` WHERE `%s`=?', SV.TableName, SV.IdentifierCol),
        {identifier},
        function(rows)
            local stats = {}
            for k, v in pairs(defaultStats) do stats[k] = v end
            if rows and rows[1] and rows[1].statistics then
                local ok, decoded = pcall(json.decode, rows[1].statistics)
                if ok and type(decoded) == 'table' then
                    for k, v in pairs(decoded) do
                        if defaultStats[k] ~= nil then stats[k] = tonumber(v) or 0.0 end
                    end
                end
            end
            cb(stats)
        end
    )
end

local function savePlayerStats(source)
    local data = playersData[source]
    if not data then return end
    MySQL.update(
        string.format('UPDATE `%s` SET `statistics`=? WHERE `%s`=?', SV.TableName, SV.IdentifierCol),
        {json.encode(data.statistics), data.identifier}
    )
end

local function loadPlayerMemberships(identifier, cb)
    local now = os.time()
    MySQL.query(
        'SELECT `membership`,`time` FROM `gym_memberships` WHERE `identifier`=? AND `time`>?',
        {identifier, now},
        function(rows)
            local memberships = {}
            if rows then
                for _, row in ipairs(rows) do
                    memberships[#memberships + 1] = {name = row.membership, time = row.time}
                end
            end
            cb(memberships)
        end
    )
end

local function persistMembership(identifier, membershipName, expiryTime, cb)
    MySQL.query(
        [[INSERT INTO `gym_memberships` (`identifier`,`membership`,`time`)
          VALUES (?,?,?)
          ON DUPLICATE KEY UPDATE `time`=VALUES(`time`)
        ]],
        {identifier, membershipName, expiryTime},
        function() if cb then cb() end end
    )
end

-- ─────────────────────────────────────────────────────────────
--  PLAYER INIT / CLEANUP
-- ─────────────────────────────────────────────────────────────

local function initPlayer(source, identifier)
    loadPlayerStats(identifier, function(stats)
        loadPlayerMemberships(identifier, function(memberships)
            playersData[source] = {
                identifier  = identifier,
                statistics  = stats,
                memberships = memberships,
            }
            TriggerClientEvent('vms_gym:cl:updateStatistic', source, stats)
            TriggerClientEvent('vms_gym:cl:getMemberships',  source, memberships)
        end)
    end)
end

local function cleanupPlayer(source)
    if playersData[source] then
        savePlayerStats(source)
        playersData[source] = nil
    end
    billsPending[source] = nil
end

-- ─────────────────────────────────────────────────────────────
--  RESOURCE / FRAMEWORK EVENTS
-- ─────────────────────────────────────────────────────────────

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Initialise in-memory store table for every gym that has an ownerJob
    for gymId, gymData in pairs(Config.Gyms) do
        if gymData.ownerJob then
            gymStores[gymId] = {
                data          = {balance = 0, totalEarned = 0},
                announcements = {},
            }
        end
    end
    Citizen.Wait(500)
    setupDatabase()
    Citizen.Wait(1500)
    loadGymStores()
end)

-- ESX Legacy: esx:playerLoaded fires with (playerId, xPlayer, isNew, skin)
-- The first argument is the numeric source ID, not the xPlayer object.
-- QB-Core: QBCore:Server:OnPlayerLoaded fires with no arguments; use source.
RegisterNetEvent(Config.PlayerLoadedServer)
AddEventHandler(Config.PlayerLoadedServer, function(player)
    local source = source
    local identifier
    if Config.Core == "ESX" then
        -- player arg may be numeric source (ESX Legacy) or xPlayer table — handle both
        local xPlayer = type(player) == 'table' and player or ESX.GetPlayerFromId(source)
        if xPlayer then identifier = xPlayer.identifier end
    elseif Config.Core == "QB-Core" then
        local P = QBCore.Functions.GetPlayer(source)
        if P then identifier = P.PlayerData.citizenid end
    end
    if not identifier then return end
    Citizen.Wait(500)
    initPlayer(source, identifier)
end)

RegisterNetEvent(Config.PlayerLogoutServer)
AddEventHandler(Config.PlayerLogoutServer, function()
    cleanupPlayer(source)
end)

AddEventHandler('playerDropped', function()
    cleanupPlayer(source)
end)

-- ─────────────────────────────────────────────────────────────
--  RESOURCE RESTART — re-fetch all data for already-loaded players
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:restartPlayer')
AddEventHandler('vms_gym:sv:restartPlayer', function()
    local source = source
    local identifier = SV.GetIdentifier(source)
    if not identifier then return end
    initPlayer(source, identifier)
end)

-- Send all gym store data to requesting client
RegisterNetEvent('vms_gym:fetchData')
AddEventHandler('vms_gym:fetchData', function()
    TriggerClientEvent('vms_gym:fetchedData', source, gymStores)
end)

-- ─────────────────────────────────────────────────────────────
--  GYM POINT TAKEN STATE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:setTaken')
AddEventHandler('vms_gym:sv:setTaken', function(gymId, pointId, boolean)
    local source = source
    if not Config.Gyms[gymId] then return end
    if not Config.Gyms[gymId].points[pointId] then return end
    -- Validate: only the player who owns the session can release it
    Config.Gyms[gymId].points[pointId].taken = boolean
    TriggerClientEvent('vms_gym:cl:setTaken', -1, gymId, pointId, boolean)
end)

-- ─────────────────────────────────────────────────────────────
--  STATISTICS — ADD / REMOVE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:addValue')
AddEventHandler('vms_gym:sv:addValue', function(skillName, value)
    local source = source
    if not playersData[source] then return end
    if defaultStats[skillName] == nil then return end       -- reject unknown stat names
    value = tonumber(value)
    if not value or value <= 0 then return end

    local stats = playersData[source].statistics
    stats[skillName] = math.min(100.0, (stats[skillName] or 0.0) + value)

    if Config.SendNotificationWhenSkillIncrase then
        local titleKey = 'notify.title.' .. skillName
        local msgKey   = 'increase_'     .. skillName
        local title    = Config.Translate[Config.Language] and Config.Translate[Config.Language][titleKey] or titleKey
        local msg      = Config.Translate[Config.Language] and Config.Translate[Config.Language][msgKey]   or msgKey
        if msg then
            SV.Notification(source, title, string.format(msg, string.format("%.1f", value)), 3500, 'fa-solid fa-dumbbell', 'success', true)
        end
    end

    TriggerClientEvent('vms_gym:cl:updateStatistic', source, stats)
end)

RegisterNetEvent('vms_gym:sv:removeValue')
AddEventHandler('vms_gym:sv:removeValue', function(skillName, value)
    local source = source
    if not playersData[source] then return end
    if defaultStats[skillName] == nil then return end
    value = tonumber(value)
    if not value or value <= 0 then return end

    local stats = playersData[source].statistics
    stats[skillName] = math.max(0.0, (stats[skillName] or 0.0) - value)

    if Config.SendNotificationWhenSkillDecrease then
        local titleKey = 'notify.title.' .. skillName
        local msgKey   = 'decrease_'     .. skillName
        local title    = Config.Translate[Config.Language] and Config.Translate[Config.Language][titleKey] or titleKey
        local msg      = Config.Translate[Config.Language] and Config.Translate[Config.Language][msgKey]   or msgKey
        if msg then
            SV.Notification(source, title, string.format(msg, string.format("%.1f", value)), 3500, 'fa-solid fa-dumbbell', 'info', true)
        end
    end

    TriggerClientEvent('vms_gym:cl:updateStatistic', source, stats)
end)

-- ─────────────────────────────────────────────────────────────
--  ANNOUNCEMENTS
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sendAnnouncement')
AddEventHandler('vms_gym:sendAnnouncement', function(gymId, text)
    local source = source
    if not Config.Gyms[gymId] then return end
    if not gymStores[gymId]   then return end
    if not text or text == '' then return end

    local job = SV.GetPlayerJob(source)
    if not job or job.name ~= Config.Gyms[gymId].ownerJob then return end

    local announcement = {
        name    = SV.GetPlayerName(source) or 'Unknown',
        message = text,
    }
    table.insert(gymStores[gymId].announcements, announcement)
    -- Keep only the last 20 announcements
    while #gymStores[gymId].announcements > 20 do
        table.remove(gymStores[gymId].announcements, 1)
    end
    saveGymStore(gymId)
    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'announcements', value = gymStores[gymId].announcements})
end)

-- ─────────────────────────────────────────────────────────────
--  EMPLOYEE MANAGEMENT  (hire / grade / bonus / fire)
-- ─────────────────────────────────────────────────────────────

local function isManagerOrBoss(source, gymId)
    local gymCfg = Config.Gyms[gymId]
    if not gymCfg then return false, false end
    local job = SV.GetPlayerJob(source)
    if not job or job.name ~= gymCfg.ownerJob then return false, false end

    local function gradeMatch(grades, gradeName)
        if type(grades) == 'table' then
            for _, g in ipairs(grades) do if g == gradeName then return true end end
            return false
        end
        return gradeName == grades
    end

    local gradeName
    if Config.Core == "ESX" then
        gradeName = job.grade_name
    elseif Config.Core == "QB-Core" then
        gradeName = job.grade and job.grade.name
    end

    local isBoss    = gradeName and gradeMatch(gymCfg.boss_grades,    gradeName) or false
    local isMgr     = gradeName and gradeMatch(gymCfg.manager_grades, gradeName) or false
    return isMgr or isBoss, isBoss
end

RegisterNetEvent('vms_gym:hireAnEmployee')
AddEventHandler('vms_gym:hireAnEmployee', function(gymId, targetSource)
    local source = source
    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    targetSource = tonumber(targetSource)
    if not targetSource or not GetPlayerName(targetSource) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    local dist = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(targetSource)))
    if dist > 10.0 then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_too_far_away'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    local targetJob = SV.GetPlayerJob(targetSource)
    if not targetJob then return end

    if targetJob.name == Config.Gyms[gymId].ownerJob then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_already_employed'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    if Config.RequiredJobToBeHired and Config.RequiredJobToBeHired ~= '' then
        if targetJob.name ~= Config.RequiredJobToBeHired then
            SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:must_be_unemployed'), 3500, 'fa-solid fa-dumbbell', 'error')
            return
        end
    end

    SV.SetJob(targetSource, Config.Gyms[gymId].ownerJob, 0)
    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:you_employee_hired'), 3500, 'fa-solid fa-dumbbell', 'success')
    -- Tell all clients with the management menu open to refresh the employee list
    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'employees', value = true})
end)

RegisterNetEvent('vms_gym:bonusEmployee')
AddEventHandler('vms_gym:bonusEmployee', function(gymId, targetIdentifier, bonusMoney)
    local source = source
    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    bonusMoney = tonumber(bonusMoney)
    if not bonusMoney or bonusMoney < 1 then return end

    if not SV.HasMoney(source, 'cash', bonusMoney) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.balance:you_dont_have_that_money'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    local targetPlayer = SV.GetPlayerByIdentifier(targetIdentifier)
    if not targetPlayer then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end
    local targetSource = SV.GetSourceFromPlayer(targetPlayer)
    if not targetSource then return end

    SV.RemoveMoney(source,       'cash', bonusMoney, 'gym-bonus-given')
    SV.AddMoney(targetSource,    'cash', bonusMoney, 'gym-bonus-received')

    SV.Notification(source,       TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:awarded_bonus',  bonusMoney), 3500, 'fa-solid fa-dumbbell', 'success')
    SV.Notification(targetSource, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:received_bonus', bonusMoney), 3500, 'fa-solid fa-dumbbell', 'success')
end)

RegisterNetEvent('vms_gym:changeGradeEmployee')
AddEventHandler('vms_gym:changeGradeEmployee', function(gymId, targetIdentifier, gradeData)
    local source = source
    local canManage, isBoss = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    if not gradeData or gradeData.grade == nil then return end

    -- Verify the grade exists in config and check needToBeBoss
    local gradeFound = nil
    for _, g in ipairs(Config.Gyms[gymId].jobGradesToSet or {}) do
        if g.grade == gradeData.grade then gradeFound = g; break end
    end
    if not gradeFound then return end

    if gradeFound.needToBeBoss and not isBoss then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    local targetPlayer = SV.GetPlayerByIdentifier(targetIdentifier)
    if not targetPlayer then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end
    local targetSource = SV.GetSourceFromPlayer(targetPlayer)
    if not targetSource then return end

    SV.SetJob(targetSource, Config.Gyms[gymId].ownerJob, gradeFound.grade)
    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'employees', value = true})
end)

RegisterNetEvent('vms_gym:fireEmployee')
AddEventHandler('vms_gym:fireEmployee', function(gymId, targetIdentifier)
    local source = source
    local canManage, isBoss = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    local targetPlayer = SV.GetPlayerByIdentifier(targetIdentifier)
    if not targetPlayer then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end
    local targetSource = SV.GetSourceFromPlayer(targetPlayer)
    if not targetSource then return end

    local targetJob = SV.GetPlayerJob(targetSource)
    if not targetJob or targetJob.name ~= Config.Gyms[gymId].ownerJob then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_not_employed'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    SV.SetJob(targetSource, 'unemployed', 0)
    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'employees', value = true})
end)

-- ─────────────────────────────────────────────────────────────
--  COMPANY BALANCE — WITHDRAW / DEPOSIT  (built-in only)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:withdraw')
AddEventHandler('vms_gym:withdraw', function(gymId, amount)
    local source = source
    if not Config.UseBuildInCompanyBalance then return end
    if not gymStores[gymId] then return end

    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount < 1 then return end

    if gymStores[gymId].data.balance < amount then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.balance:store_dont_have_that_money'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    gymStores[gymId].data.balance = gymStores[gymId].data.balance - amount
    SV.AddMoney(source, 'cash', amount, 'gym-withdraw')
    saveGymStore(gymId)

    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'balance', value = gymStores[gymId].data.balance})
    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.balance:withdraw', amount), 3500, 'fa-solid fa-dumbbell', 'success')
end)

RegisterNetEvent('vms_gym:deposit')
AddEventHandler('vms_gym:deposit', function(gymId, amount)
    local source = source
    if not Config.UseBuildInCompanyBalance then return end
    if not gymStores[gymId] then return end

    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount < 1 then return end

    if not SV.HasMoney(source, 'cash', amount) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.balance:you_dont_have_that_money'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    SV.RemoveMoney(source, 'cash', amount, 'gym-deposit')
    gymStores[gymId].data.balance = gymStores[gymId].data.balance + amount
    saveGymStore(gymId)

    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {sub = 'balance', value = gymStores[gymId].data.balance})
    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.balance:deposit', amount), 3500, 'fa-solid fa-dumbbell', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  MEMBERSHIP HELPERS
-- ─────────────────────────────────────────────────────────────

local function calcExpiryTime(membershipData)
    local t = os.time()
    if membershipData.days  then t = t + (membershipData.days  * 86400) end
    if membershipData.hours then t = t + (membershipData.hours * 3600)  end
    return t
end

local function applyMembershipToPlayer(source, membershipName, expiryTime, cb)
    local identifier = SV.GetIdentifier(source)
    if not identifier then if cb then cb() end return end
    persistMembership(identifier, membershipName, expiryTime, function()
        if playersData[source] then
            -- Replace existing entry for this membership name
            for i = #playersData[source].memberships, 1, -1 do
                if playersData[source].memberships[i].name == membershipName then
                    table.remove(playersData[source].memberships, i)
                end
            end
            table.insert(playersData[source].memberships, {name = membershipName, time = expiryTime})
            TriggerClientEvent('vms_gym:cl:getMemberships', source, playersData[source].memberships)
        end
        if cb then cb() end
    end)
end

local function addToGymRevenue(gymId, amount)
    if not Config.UseBuildInCompanyBalance then return end
    if not gymStores[gymId] then return end
    local societyShare = math.floor(amount * (Config.BillMoneyToSocietyPercent / 100))
    gymStores[gymId].data.balance     = gymStores[gymId].data.balance + societyShare
    gymStores[gymId].data.totalEarned = gymStores[gymId].data.totalEarned + amount
    saveGymStore(gymId)
    TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {
        {sub = 'balance',     value = gymStores[gymId].data.balance},
        {sub = 'totalEarned', value = gymStores[gymId].data.totalEarned},
    })
end

-- ─────────────────────────────────────────────────────────────
--  DIRECT PURCHASE — player buys membership at shop NPC
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:acceptMembership')
AddEventHandler('vms_gym:sv:acceptMembership', function(gymId, membershipName, membershipData)
    local source = source
    if not Config.Gyms[gymId]   then return end
    if not membershipData        then return end

    local price = membershipData.totalAmount or membershipData.price
    if not price or price < 1   then return end

    -- Try cash first, then bank
    local payType = SV.HasMoney(source, 'cash', price) and 'cash' or 'bank'
    if not SV.HasMoney(source, payType, price) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.nomoney'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    SV.RemoveMoney(source, payType, price, 'gym-membership-buy')
    addToGymRevenue(gymId, price)

    local expiryTime = calcExpiryTime(membershipData)
    applyMembershipToPlayer(source, membershipName, expiryTime)

    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('bought_membership'), 3500, 'fa-solid fa-dumbbell', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  DIRECT PURCHASE — player buys protein at shop NPC
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:buyProtein')
AddEventHandler('vms_gym:sv:buyProtein', function(gymId, proteinName)
    local source = source
    if not Config.Gyms[gymId]                          then return end
    if not Config.Gyms[gymId].proteins                 then return end
    local proteinData = Config.Gyms[gymId].proteins[proteinName]
    if not proteinData                                 then return end

    local price = proteinData.totalAmount or proteinData.price
    if not price or price < 1 then return end

    local payType = SV.HasMoney(source, 'cash', price) and 'cash' or 'bank'
    if not SV.HasMoney(source, payType, price) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.nomoney'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    SV.RemoveMoney(source, payType, price, 'gym-protein-buy')
    SV.AddItem(source, proteinData.name, 1)
    addToGymRevenue(gymId, price)

    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('bought_proteins', proteinData.label, 1), 3500, 'fa-solid fa-dumbbell', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  EMPLOYEE SELL — send bill to another player for membership
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:sellMembership')
AddEventHandler('vms_gym:sv:sellMembership', function(targetSource, gymId, membershipData)
    local source = source
    if not Config.Gyms[gymId] then return end
    if not membershipData      then return end

    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    targetSource = tonumber(targetSource)
    if not targetSource or not GetPlayerName(targetSource) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    billsPending[targetSource] = {
        sellerId       = source,
        gymId          = gymId,
        type           = 'membership',
        membershipData = membershipData,
        membershipName = Config.Gyms[gymId].requiredMembership,
    }

    TriggerClientEvent('vms_gym:cl:getBill', targetSource, gymId, membershipData, nil, nil)
    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_sent_bill'), 3500, 'fa-solid fa-dumbbell', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  EMPLOYEE SELL — send bill to another player for proteins
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:sellProtein')
AddEventHandler('vms_gym:sv:sellProtein', function(targetSource, gymId, proteinData, count)
    local source = source
    if not Config.Gyms[gymId] then return end
    if not proteinData         then return end

    local canManage, _ = isManagerOrBoss(source, gymId)
    if not canManage then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_are_not_owner'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    targetSource = tonumber(targetSource)
    if not targetSource or not GetPlayerName(targetSource) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.employees:player_is_offline'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    count = math.max(1, tonumber(count) or 1)

    billsPending[targetSource] = {
        sellerId     = source,
        gymId        = gymId,
        type         = 'protein',
        proteinsData = proteinData,
        count        = count,
    }

    TriggerClientEvent('vms_gym:cl:getBill', targetSource, gymId, nil, proteinData, count)
    SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.you_sent_bill'), 3500, 'fa-solid fa-dumbbell', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  BILL PAYMENT  (pay / cancel)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('vms_gym:sv:payBill')
AddEventHandler('vms_gym:sv:payBill', function(action, paymentType)
    local source = source
    local bill   = billsPending[source]

    if action == 'cancel' then
        if bill and bill.sellerId and GetPlayerName(bill.sellerId) then
            SV.Notification(bill.sellerId, TRANSLATE('notify.title.gym'), TRANSLATE('customer_did_not_buy'), 3500, 'fa-solid fa-dumbbell', 'error')
        end
        billsPending[source] = nil
        return
    end

    if action ~= 'pay' or not bill then return end

    local gymId = bill.gymId
    if not Config.Gyms[gymId] then
        billsPending[source] = nil
        return
    end

    -- Determine total charge
    local totalPrice = 0
    if bill.type == 'membership' then
        totalPrice = bill.membershipData.totalAmount or bill.membershipData.price or 0
    elseif bill.type == 'protein' then
        local unitPrice = bill.proteinsData.totalAmount or bill.proteinsData.price or 0
        totalPrice = unitPrice * (bill.count or 1)
    end

    if totalPrice < 1 then
        billsPending[source] = nil
        TriggerClientEvent('vms_gym:cl:getBillFeedback', source)
        return
    end

    -- paymentType arrives as 'cash' or 'bank' from the NUI
    local moneyType = (paymentType == 'bank') and 'bank' or 'cash'
    if not SV.HasMoney(source, moneyType, totalPrice) then
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('notify.nomoney'), 3500, 'fa-solid fa-dumbbell', 'error')
        return
    end

    SV.RemoveMoney(source, moneyType, totalPrice, 'gym-bill-payment')

    -- Split: society % and seller %
    local societyShare = math.floor(totalPrice * ((Config.BillMoneyToSocietyPercent or 80)  / 100))
    local sellerShare  = math.floor(totalPrice * ((Config.BillMoneyToSellerPercent  or 20)  / 100))

    -- Add society share to gym balance
    if Config.UseBuildInCompanyBalance and gymStores[gymId] then
        gymStores[gymId].data.balance     = gymStores[gymId].data.balance + societyShare
        gymStores[gymId].data.totalEarned = gymStores[gymId].data.totalEarned + totalPrice
        saveGymStore(gymId)
        TriggerClientEvent('vms_gym:updateBusiness', -1, gymId, nil, {
            {sub = 'balance',     value = gymStores[gymId].data.balance},
            {sub = 'totalEarned', value = gymStores[gymId].data.totalEarned},
        })
    end

    -- Pay seller commission
    if sellerShare > 0 and bill.sellerId and GetPlayerName(bill.sellerId) then
        SV.AddMoney(bill.sellerId, 'cash', sellerShare, 'gym-commission')
    end

    -- Fulfil the purchase
    if bill.type == 'membership' then
        local expiryTime = calcExpiryTime(bill.membershipData)
        applyMembershipToPlayer(source, bill.membershipName, expiryTime)
        SV.Notification(source, TRANSLATE('notify.title.gym'), TRANSLATE('bought_membership'), 3500, 'fa-solid fa-dumbbell', 'success')
        if bill.sellerId and GetPlayerName(bill.sellerId) then
            SV.Notification(bill.sellerId, TRANSLATE('notify.title.gym'), TRANSLATE('selled_membership'), 3500, 'fa-solid fa-dumbbell', 'success')
        end

    elseif bill.type == 'protein' then
        SV.AddItem(source, bill.proteinsData.name, bill.count)
        SV.Notification(source,    TRANSLATE('notify.title.gym'), TRANSLATE('bought_proteins', bill.proteinsData.label, bill.count), 3500, 'fa-solid fa-dumbbell', 'success')
        if bill.sellerId and GetPlayerName(bill.sellerId) then
            SV.Notification(bill.sellerId, TRANSLATE('notify.title.gym'), TRANSLATE('sold_proteins', bill.proteinsData.label, bill.count), 3500, 'fa-solid fa-dumbbell', 'success')
        end
    end

    billsPending[source] = nil
    TriggerClientEvent('vms_gym:cl:getBillFeedback', source)
end)

-- ─────────────────────────────────────────────────────────────
--  PERIODIC TASKS
-- ─────────────────────────────────────────────────────────────

-- Save all online player statistics on a timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.SavingTimeout)
        for src, data in pairs(playersData) do
            if data and data.identifier and data.statistics then
                savePlayerStats(src)
            end
        end
    end
end)

-- Purge expired memberships from DB once per hour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3600000)
        MySQL.query('DELETE FROM `gym_memberships` WHERE `time` <= ?', {os.time()})
    end
end)
