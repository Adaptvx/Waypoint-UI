local env                                 = select(2, ...)
local Config                              = env.Config

local SetSuperTrackedUserWaypoint         = C_SuperTrack.SetSuperTrackedUserWaypoint
local CreateFrame                         = CreateFrame

local LazyTimer                           = env.WPM:Import("wpm_modules\\lazy-timer")
local CallbackRegistry                    = env.WPM:Import("wpm_modules\\callback-registry")
local SavedVariables                      = env.WPM:Import("wpm_modules\\saved-variables")


-- Events
----------------------------------------------------------------------------------------------------

local DelayTimer = LazyTimer.New()
DelayTimer:SetAction(function()
    SetSuperTrackedUserWaypoint(true)
end)

local f = CreateFrame("Frame")
f:RegisterEvent("USER_WAYPOINT_UPDATED")
f:SetScript("OnEvent", function(_, event, ...)
    if event == "USER_WAYPOINT_UPDATED" then
        DelayTimer:Start(0)
    end
end)


-- Settings
----------------------------------------------------------------------------------------------------

local function UpdateToMatchSetting()
    local Setting_AutoTrackPlacedPinEnabled = Config.DBGlobal:GetVariable("AutoTrackPlacedPinEnabled")
    if Setting_AutoTrackPlacedPinEnabled then
        f:RegisterEvent("USER_WAYPOINT_UPDATED")
    else
        f:UnregisterEvent("USER_WAYPOINT_UPDATED")
    end
end

SavedVariables.OnChange("WaypointDB_Global", "AutoTrackPlacedPinEnabled", UpdateToMatchSetting)
CallbackRegistry.Add("Preload.DatabaseReady", UpdateToMatchSetting)

