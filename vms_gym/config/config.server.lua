-- =====================================================================
--  vms_gym  |  config.server.lua  –  Server-side configuration
-- =====================================================================

--  This file is loaded as a server_script. Adjust the settings below
--  to match your server's economy / framework setup.
-- =====================================================================

-- ── Framework job / account mappings ─────────────────────────────────

-- The job name assigned to newly hired employees (grade 0).
-- Matches the `ownerJob` field inside each gym entry in Config.Gyms.
-- Nothing to change here unless you rename jobs.

-- ── Money accounts ────────────────────────────────────────────────────
--  ESX  : "cash" / "bank"
--  QB   : "cash" / "bank"
Config.MoneyAccount = "cash"   -- Default account used for shop purchases

-- ── Built-in company balance ──────────────────────────────────────────
-- Already configured in config.management.lua (Config.UseBuildInCompanyBalance).
-- If you set that to false, configure esx_society / qb-banking below.

-- esx_society event names (only relevant when UseBuildInCompanyBalance = false)
Config.ESXSocietyEvents = {
    ['check']    = 'esx_society:checkSocietyBalance',
    ['withdraw'] = 'esx_society:withdrawMoney',
    ['deposit']  = 'esx_society:depositMoney',
}

-- ── Protein booster settings ──────────────────────────────────────────
--  Multiplier applied to the respective stat gains while the boost is active.
--  Duration is in milliseconds.
Config.ProteinBoosters = {
    ['protein'] = {
        event      = 'vms_gym:runStrengthBooster',
        multiplier = 1.5,
        duration   = 300000,   -- 5 minutes
    },
    ['runbooster'] = {
        event      = 'vms_gym:runConditionBooster',
        multiplier = 1.5,
        duration   = 300000,   -- 5 minutes
    },
}

-- ── Announcement history limit ────────────────────────────────────────
--  Maximum number of announcements stored per gym.
Config.MaxAnnouncements = 20

-- ── Employee distance check ───────────────────────────────────────────
--  Maximum distance (game units) allowed between the manager and the
--  player being hired.
Config.HireMaxDistance = 10.0
