-- ============================================================
--  vms_gym  |  version_check.lua
-- ============================================================
--  Simple startup banner – no external HTTP calls required.
-- ============================================================

local RESOURCE_VERSION = "2.0.1"

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    print(string.format(
        "^2[vms_gym]^7 Version ^3%s^7 started successfully. Framework: ^3%s^7",
        RESOURCE_VERSION,
        Config.Core or "Unknown"
    ))
end)
