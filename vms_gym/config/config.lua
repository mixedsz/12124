Config = {}

------------------------------ █▀ █▀▄ ▄▀▄ █▄ ▄█ ██▀ █   █ ▄▀▄ █▀▄ █▄▀ ------------------------------
------------------------------ █▀ █▀▄ █▀█ █ ▀ █ █▄▄ ▀▄▀▄▀ ▀▄▀ █▀▄ █ █ ------------------------------
local frameworkAutoFind = function()
    if GetResourceState('es_extended') ~= 'missing' then
        return "ESX"
    elseif GetResourceState('qb-core') ~= 'missing' then
        return "QB-Core"
    end
end

Config.Core = frameworkAutoFind()
Config.CoreExport = function()
    if Config.Core == "ESX" then
        return exports['es_extended']:getSharedObject()
    elseif Config.Core == "QB-Core" then
        return exports['qb-core']:GetCoreObject()
    end
end


---@field AutoExecuteQuery: Will automatically add the 'statistics' column to your ESX: `users` / QB-Core: `players` table if it doesn't already exist.
Config.AutoExecuteQuery = true

---@field PlayerLoaded string: ESX: "esx:playerLoaded" / QB-Core: "QBCore:Client:OnPlayerLoaded"
Config.PlayerLoaded = Config.Core == "ESX" and "esx:playerLoaded" or "QBCore:Client:OnPlayerLoaded"  

---@field PlayerLoadedServer: ESX: "esx:playerLoaded" / QB-Core: "QBCore:Server:OnPlayerLoaded"
Config.PlayerLoadedServer = Config.Core == "ESX" and "esx:playerLoaded" or "QBCore:Server:OnPlayerLoaded"

---@field PlayerLogoutServer: ESX: "esx:playerDropped" / QB-Core: "QBCore:Server:OnPlayerUnload"
Config.PlayerLogoutServer = Config.Core == "ESX" and "esx:playerDropped" or "QBCore:Server:OnPlayerUnload"

---@field JobUpdated string: ESX: "esx:setJob" / QB-Core: "QBCore:Client:OnJobUpdate"
Config.JobUpdated = Config.Core == "ESX" and "esx:setJob" or "QBCore:Client:OnJobUpdate"


---@field SavingTimeout: Every how long the player's statistics will be saved to the database - recommended 10 or 15 minutes
Config.SavingTimeout = 60 * 10 * 1000 -- 10 minutes

Config.Menu = 'ox_lib' -- 'esx_menu_default' / 'esx_context' / 'qb-menu' / 'ox_lib'
Config.ESXMenuDefault_Align = 'right'

Config.SendNotificationWhenSkillIncrase = true
Config.SendNotificationWhenSkillDecrease = true

Config.DistanceView = 2.25
Config.DistanceAccess = 0.7
Config.UseMarkers = true
Config.Use3DText = false
Config.UseHelpNotify = true

---@field UseTarget: If you use a target, markers for gym activities will not be displayed - the marker will remain for the boss menu
Config.UseTarget = true
Config.TargetResource = 'ox_target' -- 'ox_target' / 'qb-target'

---@field EnableMemberships: If you use in any gym the required membership, run it then it will work correctly reading memberships
Config.EnableMemberships = true

-- @EnableStrengthModifier: In the config.client.lua file, you can modify the player's hitting power with certain power stats.
-- !!! IF YOUR ANTI-CHEAT BANS FOR strength MODIFICATION YOU NEED TO SET THIS OPTION TO FALSE OR MAKE A CHANGE IN THE ANTI-CHEAT !!!
Config.EnableStrengthModifier = true

-- @EnableRunSpeedModifier: In the config.client.lua file, you can modify the player's running speed with certain condition stats.
-- !!! IF YOUR ANTI-CHEAT BANS FOR RUN MODIFICATION YOU NEED TO SET THIS OPTION TO FALSE OR MAKE A CHANGE IN THE ANTI-CHEAT !!!
Config.EnableRunSpeedModifier = false

-- @EnableStaminaModifier: In the config.client.lua file, you can modify the player's stamina level with certain condition stats.
Config.EnableStaminaModifier = true


-- @EnableSkillDrivingEffects: With low driving skill your vehicle will run into slides more often or through lack of skill will randomly turn, the higher the level the less or no effect it has
Config.EnableSkillDrivingEffects = false
Config.SkillDrivingEffectMinimumSpeed = 30.0

-- @UnitOfSpeed: Customize your speed unit if you intend to use Config.EnableSkillDrivingEffects
Config.UnitOfSpeed = 'mph' -- 'kmh' or 'mph'


-- @AutoMembershipForEmployees: Every gym employee will have a gym membership with no requirement to buy one
Config.AutoMembershipForEmployees = true


-- @UseProgressbar: If you want to use a progress-bar for the exercises you are doing, you can do so below.
Config.UseProgressbar = true
Config.Progressbar = function(actionName, time)
    lib.progressBar({
        duration = time,
        label = Config.Translate[Config.Language]["progressbar."..actionName],
        useWhileDead = false,
        canCancel = false
    })
end

-- @UseSkillbar: If you want to use a skill-bar for the exercises you are doing, you can do so below.
Config.UseSkillbar = false
Config.Skillbar = function(actionName, cb)
    local finished = exports["tgiann-skillbar"]:taskBar(3000)
    cb(finished)
end

Config.StatisticCommand = 'statistics'
Config.StatisticKey = 'I'
Config.StatisticDescription = 'Open statistics menu'

Config.StatisticsMenu = {
    ['strength'] = true,
    ['condition'] = true,
    ['shooting'] = true,
    ['driving'] = true,
    ['flying'] = true,
}

Config.Blip = { -- https://docs.fivem.net/docs/game-references/blips/
    ["Sprite"] = 311,
    ["Scale"] = 0.85,
    ["Color"] = 46,
    ["Display"] = 4
}

Config.Keys = { -- https://docs.fivem.net/docs/game-references/controls/
    enter = 38, -- E
    train = 22, -- SPACE
    stop = 49-- F
}

Config.Markers = {
	['BossMenu'] = {
		id = 29,
		color = {95, 255, 95, 125},
		size = vec(0.33, 0.33, 0.33),
		bobUpAndDown = false,
		rotate = true
	},
	['ShopMenu'] = {
		id = 29,
		color = {180, 255, 95, 125},
		size = vec(0.33, 0.33, 0.33),
		bobUpAndDown = false,
		rotate = true
	},
	['FreeSeat'] = {
		id = 20,
        color = {59, 227, 137, 125},
        rotation = {180.0, 0.0, 0.0},
		size = vec(0.15, 0.15, 0.15),
		bobUpAndDown = false,
		rotate = true
	},
}

Config.Animations = {
    ['pull-up'] = {
        enter = {'amb@prop_human_muscle_chin_ups@male@enter', 'enter', 1800},
        idle = {'amb@prop_human_muscle_chin_ups@male@idle_a', 'idle_a', -1},
        training = {'amb@prop_human_muscle_chin_ups@male@base', 'base', 2900},
        exit = {'amb@prop_human_muscle_chin_ups@male@exit', 'exit', 2000},
    },
    ['nekoyoga6'] = {
        enter   = {'misslamar1leadinout', 'yoga_02_idle_b', 2500},
        idle    = {'misslamar1leadinout', 'yoga_02_idle_b', -1},
        exit    = {'misslamar1leadinout', 'yoga_02_idle_b', 2000},
    },
    ['bench'] = {
        enter = {'amb@prop_human_seat_muscle_bench_press@enter', 'enter', 0},
        idle = {'amb@prop_human_seat_muscle_bench_press@base', 'base', -1},
        training = {'amb@prop_human_seat_muscle_bench_press@idle_a', 'idle_a', 2350},
        exit = {'amb@prop_human_seat_muscle_bench_press@exit', 'exit', 2500},
    },
    ['barbell'] = {
        idle = {'amb@world_human_muscle_free_weights@male@barbell@idle_a', 'idle_a', -1},
        training = {'amb@world_human_muscle_free_weights@male@barbell@base', 'base', 4500},
    },
    ['push-up'] = {
        enter = {'amb@world_human_push_ups@male@enter', 'enter', 3500},
        idle = {'amb@world_human_push_ups@male@idle_a', 'idle_a', -1},
        training = {'amb@world_human_push_ups@male@base', 'base', 1100},
        exit = {'amb@world_human_push_ups@male@exit', 'exit', 4050},
    },
    ['dumbbells'] = {
        idle = {'amb@world_human_muscle_free_weights@male@barbell@idle_a', 'idle_a', -1},
        training = {'amb@world_human_muscle_free_weights@male@barbell@base', 'base', 4500},
    },
    ['treadmill'] = {
        idle = {'move_m@hurry@c', 'walk', -1},
        training = {'move_m@brave@a', 'run', 4000},
    },
}

-- @RefreshTimeAddStats: Time every how much the statistic will add up for different activities e.g. swimming, running etc.
Config.RefreshTimeAddStats = 10000 -- 10 seconds
Config.AddStatsValues = {
    -- Condition:
    ['Running'] = 3,
    ['Swimming'] = {5, 8},
    ['Cycling'] = {minimumSpeed = 15, value = {6, 8}},
    
    -- Shooting:
    ['Shooting'] = {1, 2},

    -- Driving:
    ['Driving'] = {minimumSpeed = 140, value = {2, 7}},

    -- Flying:
    ['Flying'] = {minimumSpeed = 180, value = {5, 10}},
}

-- @RefreshTimeRemoveStats: 
Config.RefreshTimeRemoveStats = 900000 -- Every 15 minutes
Config.RemoveStatsValues = {
    -- Condition:
    ['RemoveCondition'] = 1,

    -- Strength:
    ['RemoveStrength'] = 1,
}

Config.Gyms = {
    ['dcfitness'] = {
        blipEnabled = true,
        blipCoords = vector3(-515.63, -606.84, 34.71), -- don't remove it, set it in the center of the gym
        blipName = 'Dc Fitness',

        business = false,
        ownerJob = 'gym1',
        society_name = "society_gym", -- Used only with Config.UseBuildInCompanyBalance = false
        grades_access = {'recruit', 'employee', 'manager', 'boss'}, -- nil for every user with job, string: 'name', table: {'name', 'name2'}
        manager_grades = 'manager', -- string: 'name', table: {'name', 'name2'}
        boss_grades = 'boss', -- string: 'name', table: {'name', 'name2'}
        cityhall_grades = { -- Grades for sections from vms_cityhall
            ['resumes'] = {'manager', 'boss'}, -- string: 'name', table: {'name', 'name2'}
            ['taxes'] = {'manager', 'boss'}, -- string: 'name', table: {'name', 'name2'}
        },
        
        bossMenu = {
            coords = vector3(-1195.61, -1577.55, 4.61),
            targetCoords = vector4(-1194.97, -1577.09, 4.61, 307.0),
            targetSize = vec(1.85, 0.65, 3.0),
        },

        jobGradesToSet = {
            {grade = 0, label = 'Recruit'},
            {grade = 1, label = 'Employee'},
            {grade = 2, label = 'Manager', needToBeBoss = true}, -- needToBeBoss means that only the boss can give this grade, the manager will not be able to do so
            {grade = 3, label = 'Boss', needToBeBoss = true}, -- needToBeBoss means that only the boss can give this grade, the manager will not be able to do so
        },

        shopMenu = {
            coords = vector3(-515.53, -606.77, 34.71),
            targetCoords = vector4(-515.53, -606.77, 34.71, 3),
            targetSize = vec(1.95, 0.65, 3.0),
        },

        allowBuyMembership = true,
        allowSellMembership = false,
        requiredMembership = 'dcfitness', -- false or name of membership like: 'plaza_gym'
        memberships = {
            {hours = 2, price = 100},
            {hours = 12, price = 500},
            {days = 1, price = 1000},
            {days = 7, price = 5500},
            {days = 14, price = 10000},
            {days = 24, price = 20000},
            {days = 31, price = 25000},
        },

        allowBuyProteins = false,
        allowSellProteins = false,
        proteins = {
            ['protein'] = {
                tax = 'gym.proteins',
                name = 'protein',
                label = 'Protein',
                description = 'Proteins that will help you gain mass faster and strengthen your physical shape.',
                icon = 'protein.png',
                price = 250
            },
        },

        points = {
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-533.70, -607.66, 34.23, 86),
                position = vec(-640.6677, 324.5625, 82.8824),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 8,
                addSkill = {skill = "strength", value = {2, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-533.71, -605.52, 34.23, 93),
                position = vec(-640.6677, 324.5625, 82.8824),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 8,
                addSkill = {skill = "strength", value = {2, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-533.75, -603.27, 34.23, 91),
                position = vec(-640.6677, 324.5625, 82.8824),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 8,
                addSkill = {skill = "strength", value = {2, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'pull-up',
                activityCoord = vector4(-536.95, -607.57, 34.83, 93),
                position = vec(-640.2808, 316.2317, 82.4629),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 6,
                addSkill = {skill = "strength", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'pull-up',
                activityCoord = vector4(-536.92, -605.66, 34.83, 91),
                position = vec(-640.2808, 316.2317, 82.4629),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 6,
                addSkill = {skill = "strength", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'pull-up',
                activityCoord = vector4(-536.90, -603.95, 34.83, 91),
                position = vec(-640.2808, 316.2317, 82.4629),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 6,
                addSkill = {skill = "strength", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-566.97, -607.03, 34.70, 352),
                position = vector3(-637.5334, 329.7747, 82.4630),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 7,
                addSkill = {skill = "strength", value = {2, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-571.64, -607.02, 34.83, 350),
                position = vector3(-637.5334, 329.7747, 82.4630),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 7,
                addSkill = {skill = "strength", value = {2, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-567.03, -603.83, 34.83, 175),
                position = vector3(-637.5334, 329.7747, 82.4630),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 7,
                addSkill = {skill = "strength", value = {2, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-571.59, -603.81, 34.83, 182),
                position = vector3(-637.5334, 329.7747, 82.4630),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 7,
                addSkill = {skill = "strength", value = {2, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'push-up',
                activityCoord = vector4(-643.2650, 325.7464, 81.4622, 87.0534),
                position = vector3(-643.2650, 325.7464, 82.4622),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 3,
                addSkill = {skill = "strength", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'dumbbells',
                prop = {name = 'prop_barbell_01', attachBone = 28422, placement = {-0.24, 0.0, -0.03, 0.0, -50.0, 0.0}},
                prop2 = {name = 'prop_barbell_01', attachBone = 60309, placement = {0.05, 0.0, 0.0, 0.0, -90.0, 120.0}},
                activityCoord = vector4(-550.30, -606.78, 34.83, 68),
                position = vector3(-550.58, -608.03, 35.83),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 4,
                addSkill = {skill = "strength", value = {1, 2}}, -- this value is divided by 10 - this means that setting {1, 2} it will be 0.1, 0.2
            },
            {
                name = 'dumbbells',
                prop = {name = 'prop_barbell_01', attachBone = 28422, placement = {-0.24, 0.0, -0.03, 0.0, -50.0, 0.0}},
                prop2 = {name = 'prop_barbell_01', attachBone = 60309, placement = {0.05, 0.0, 0.0, 0.0, -90.0, 120.0}},
                activityCoord = vector4(-551.54, -603.85, 34.83, 250),
                position = vector3(-551.54, -603.85, 35.83),
                targetSize = vec3(2.0, 2.0, 4.3),
                removeStamina = 4,
                addSkill = {skill = "strength", value = {1, 2}}, -- this value is divided by 10 - this means that setting {1, 2} it will be 0.1, 0.2
            },
            {
                name = 'nekoyoga6',
                activityCoord = vector4(-576.78, -594.17, 34.85, 181),
                position = vector3(-576.77, -594.18, 35.85),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-534.90, -607.79, 39.20, 181),
                position = vector3(-534.90, -607.79, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-538.05, -607.99, 39.20, 184),
                position = vector3(-538.05, -607.99, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-540.99, -607.93, 39.20, 178),
                position = vector3(-540.99, -607.93, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-544.33, -608.03, 39.20, 173),
                position = vector3(-544.33, -608.03, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-547.71, -607.93, 39.20, 180),
                position = vector3(-547.71, -607.93, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-550.46, -607.97, 39.20, 182),
                position = vector3(-550.46, -607.97, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-553.66, -608.09, 39.20, 181),
                position = vector3(-553.66, -608.09, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-556.89, -607.82, 39.20, 175),
                position = vector3(-556.89, -607.82, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-560.14, -608.13, 39.20, 177),
                position = vector3(-560.14, -608.13, 40.20),
                targetSize = vec3(1.2, 2.0, 4.3),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {4, 5}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
        },
    },
}