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
Config.UseMarkers = false
Config.Use3DText = false
Config.UseHelpNotify = true

---@field UseTarget: If you use a target, markers for gym activities will not be displayed - the marker will remain for the boss menu
Config.UseTarget = true
Config.TargetResource = 'ox_target' -- 'ox_target' / 'qb-target'

---@field EnableMemberships: If you use in any gym the required membership, run it then it will work correctly reading memberships
Config.EnableMemberships = true

-- @EnableStrenghtModifier: In the config.client.lua file, you can modify the player's hitting power with certain power stats.
-- !!! IF YOUR ANTI-CHEAT BANS FOR STRENGHT MODIFICATION YOU NEED TO SET THIS OPTION TO FALSE OR MAKE A CHANGE IN THE ANTI-CHEAT !!!
Config.EnableStrenghtModifier = true

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
Config.UseProgressbar = false
Config.Progressbar = function(actionName, time)
    exports['progressbar']:Progress({
        name = actionName,
        label = Config.Translate[Config.Language]["progressbar."..actionName],
        duration = time,
        canCancel = false,
        controlDisables = {
            disableMouse = false,
            disableMovement = true,
            disableCarMovement = true,
            disableCombat = true,
        }
    })
end

-- @UseSkillbar: If you want to use a skill-bar for the exercises you are doing, you can do so below.
Config.UseSkillbar = true
Config.Skillbar = function(actionName, cb)
    local finished = lib.skillCheck({'easy', 'easy', 'medium'})
    cb(finished)
end

Config.StatisticCommand = 'mystats'
Config.StatisticKey = ''
Config.StatisticDescription = 'Open statistics menu'

Config.StatisticsMenu = {
    ['strenght'] = true,
    ['condition'] = true,
    ['shooting'] = true,
    ['driving'] = true,
    ['flying'] = true,
}

Config.Blip = { -- https://docs.fivem.net/docs/game-references/blips/
    ["Sprite"] = 311,
    ["Scale"] = 0.6,
    ["Color"] = 46,
    ["Display"] = 4
}

Config.Keys = { -- https://docs.fivem.net/docs/game-references/controls/
    enter = 38, -- E
    train = 22, -- SPACE
    stop = 73-- X
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
Config.RefreshTimeAddStats = 25000 -- 25 seconds
Config.AddStatsValues = {
    -- Condition:
    ['Running'] = {1, 2},
    ['Swimming'] = {3, 5},
    ['Cycling'] = {minimumSpeed = 15, value = {2, 3}},
    
    -- Shooting:
    ['Shooting'] = {1, 2},

    -- Driving:
    ['Driving'] = {minimumSpeed = 140, value = {2, 5}},

    -- Flying:
    ['Flying'] = {minimumSpeed = 180, value = {2, 5}},
}


-- @RefreshTimeRemoveStats: 
Config.RefreshTimeRemoveStats = 120000 -- 120 seconds
Config.RemoveStatsValues = {
    -- Condition:
    ['RemoveCondition'] = 1,

    -- Strength:
    ['RemoveStrength'] = 1,
}

Config.Gyms = {
    ['Gym_2'] = {
        blipEnabled = true,
        blipCoords = vector(-515.5850, -606.7998, 34.7129),
        blipName = 'Gym',
        
        business = false,
        ownerJob = 'gym2',
        society_name = "society_gym2", -- Used only with Config.UseBuildInCompanyBalance = false
        grades_access = {'recruit', 'employee', 'manager', 'boss'}, -- nil for every user with job, string: 'name', table: {'name', 'name2'}
        manager_grades = 'manager', -- string: 'name', table: {'name', 'name2'}
        boss_grades = 'boss', -- string: 'name', table: {'name', 'name2'}
        cityhall_grades = { -- Grades for sections from vms_cityhall
            ['resumes'] = {'manager', 'boss'}, -- string: 'name', table: {'name', 'name2'}
            ['taxes'] = {'manager', 'boss'}, -- string: 'name', table: {'name', 'name2'}
        },
        
        bossMenu = {
            coords = vector3(-1255.9, -354.08, 36.96),
            targetCoords = vector4(-1255.9, -354.08, 35.96, 25.15),
            targetSize = vec(2.2, 2.2, 3.0),
        },
        
        jobGradesToSet = {
            {grade = 0, label = 'Recruit'},
            {grade = 1, label = 'Employee'},
            {grade = 2, label = 'Manager', needToBeBoss = true}, -- needToBeBoss means that only the boss can give this grade, the manager will not be able to do so
            {grade = 3, label = 'Boss', needToBeBoss = true}, -- needToBeBoss means that only the boss can give this grade, the manager will not be able to do so
        },
        
        shopMenu = {
            coords = vector3(-515.5846, -606.7642, 34.7129),
            targetCoords = vector4(-515.61, -606.1, 34.71, 0.00),
            targetSize = vec(1.0, 1.0, 3.0),
        },

        allowBuyMembership = true,
        allowSellMembership = false,
        requiredMembership = 'pump_and_run', -- false or name of membership like: 'pump_and_run'
        memberships = {
            {days = 1, price = 100},
            {days = 7, price = 150},
            {days = 14, price = 200},
            {days = 24, price = 250},
            {days = 31, price = 500},
        },

        allowBuyProteins = true,
        allowSellProteins = true,
        proteins = {
            ['protein'] = {
                tax = 'gym.proteins',
                name = 'protein',
                label = 'Protein',
                description = 'Proteins that will help you gain mass faster and strengthen your physical shape.',
                icon = 'protein.png',
                price = 350
            },
            ['runbooster'] = {
                tax = 'gym.proteins',
                name = 'runbooster',
                label = 'Run-Booster',
                description = 'Run-Booster, a supplement that will significantly make running easier and improve your endurance.',
                icon = 'runbooster.png',
                price = 300
            },
        },

        points = {
            {
                name = 'pull-up',
                activityCoord = vector4(-537.0850, -603.8719, 36.8545-2, 91.2995),
                position = vec(-537.0850, -603.8719, 36.8545),
                removeStamina = 6,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'pull-up',
                activityCoord = vector4(-537.0741, -605.7084, 36.8802-2, 95.6533),
                position = vec(-537.0741, -605.7084, 36.8802),
                removeStamina = 6,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'pull-up',
                activityCoord = vector4(-537.0743, -607.5715, 36.8722-2, 92.4739),
                position = vec(-537.0743, -607.5715, 36.8722),
                removeStamina = 6,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {1, 3} it will be 0.1, 0.3
            },
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-532.8023, -603.4438, 36.2919-0.55, 91.3331),
                position = vec(-532.8023, -603.4438, 36.2919),
                removeStamina = 8,
                addSkill = {skill = "strenght", value = {1, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-532.6644, -605.8417, 36.2920-0.55, 90.3740),
                position = vec(-532.6644, -605.8417, 36.2920),
                removeStamina = 8,
                addSkill = {skill = "strenght", value = {1, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'bench',
                prop = {name = 'prop_barbell_60kg', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-532.7592, -608.0145, 36.2919-0.55, 90.3740),
                position = vec(-532.7592, -608.0145, 36.2919),
                removeStamina = 8,
                addSkill = {skill = "strenght", value = {1, 4}}, -- this value is divided by 10 - this means that setting {2, 4} it will be 0.2, 0.4
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-534.9423, -607.3892, 40.1996-1, 182.0083),
                position = vector3(-534.9423, -607.3892, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-537.6168, -607.3892, 40.1996-1, 183.5930),
                position = vector3(-537.6168, -607.3892, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-540.5125, -607.3837, 40.1996-1, 186.5716),
                position = vector3(-540.5125, -607.3837, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-543.6721, -607.3891, 40.1996-1, 184.7756),
                position = vector3(-543.6721, -607.3891, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-546.8997, -607.3857, 40.1996-1, 181.3731),
                position = vector3(-546.8997, -607.3857, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-549.9438, -607.3835, 40.1996-1, 185.2654),
                position = vector3(-549.9438, -607.3835, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'treadmill',
                activityCoord = vector4(-552.8941, -607.3835, 40.1996-1, 182.3920),
                position = vector3(-552.8941, -607.3835, 40.1996),
                removeStamina = 1,
                addSkill = {skill = "condition", value = {2, 3}}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            
            {
                name = 'push-up',
                activityCoord = vector4(-580.3384, -596.5856, 35.8650-1, 4.9204),
                position = vector3(-580.3384, -596.5856, 35.8650),
                removeStamina = 3,
                addSkill = {skill = "strenght", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'push-up',
                activityCoord = vector4(-578.2952, -596.4528, 35.8650-1, 5.4149),
                position = vector3(-578.2952, -596.4528, 35.8650),
                removeStamina = 3,
                addSkill = {skill = "strenght", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'push-up',
                activityCoord = vector4(-576.1843, -596.4922, 35.8648-1, 0.2806),
                position = vector3(-576.1843, -596.4922, 35.8648),
                removeStamina = 3,
                addSkill = {skill = "strenght", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'push-up',
                activityCoord = vector4(-574.0815, -596.5644, 35.8650-1, 0.1550),
                position = vector3(-574.0815, -596.5644, 35.8650),
                removeStamina = 3,
                addSkill = {skill = "strenght", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'push-up',
                activityCoord = vector4(-572.1156, -596.5752, 35.8650-1, 359.6526),
                position = vector3(-572.1156, -596.5752, 35.8650),
                removeStamina = 3,
                addSkill = {skill = "strenght", value = 1}, -- this value is divided by 10 - this means that setting 1 it will be 0.1
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-560.8442, -604.4099, 35.8897-1, 95.4095),
                position = vector3(-560.8442, -604.4099, 35.8897),
                removeStamina = 7,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-563.2338, -604.4705, 35.8898-1, 92.7732),
                position = vector3(-563.2338, -604.4705, 35.8898),
                removeStamina = 7,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-565.9276, -604.5054, 35.8898-1, 87.0783),
                position = vector3(-565.9276, -604.5054, 35.8898),
                removeStamina = 7,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
            {
                name = 'barbell',
                prop = {name = 'prop_curl_bar_01', attachBone = 28422, placement = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0}},
                activityCoord = vector4(-568.3654, -604.3425, 35.8898-1, 89.5801),
                position = vector3(-568.3654, -604.3425, 35.8898),
                removeStamina = 7,
                addSkill = {skill = "strenght", value = {1, 3}}, -- this value is divided by 10 - this means that setting {2, 3} it will be 0.2, 0.3
            },
        },
    },
}