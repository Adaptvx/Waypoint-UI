local env            = select(2, ...)
local L              = env.L

local MapPin         = env.WPM:Import("@/MapPin")
local Support        = env.WPM:Import("@/Support")
local Support_TomTom = env.WPM:New("@/Support/TomTom")


-- Shared
--------------------------------

local TomTomWaypointInfo = {
    name  = nil,
    mapID = nil,
    x     = nil,
    y     = nil
}
local function handleAccept()
    Support_TomTom.PlaceWaypointAtSession()
end


local REPLACE_PROMPT_INFO = {
    text         = L["TomTom - ReplacePrompt"],
    options      = {
        {
            text     = L["TomTom - ReplacePrompt - Yes"],
            callback = handleAccept
        },
        {
            text     = L["TomTom - ReplacePrompt - No"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}


-- Helpers
--------------------------------

function Support_TomTom.PlaceWaypointAtSession()
    MapPin.NewUserNavigation(TomTomWaypointInfo.name, TomTomWaypointInfo.mapID, TomTomWaypointInfo.x, TomTomWaypointInfo.y, "TomTom_Waypoint")
    Support_TomTom.UpdateSuperTrackPinVisibility()
end

function Support_TomTom.IsUserNavigationTomTomWaypoint()
    local currentUserNavigationInfo = MapPin.GetUserNavigation()
    if MapPin.IsUserNavigation() and currentUserNavigationInfo and currentUserNavigationInfo.flags == "TomTom_Waypoint" then
        return true
    end
    return false
end

function Support_TomTom.UpdateSuperTrackPinVisibility()
    if MapPin.IsUserNavigation() and Support_TomTom.IsUserNavigationTomTomWaypoint() then
        MapPin.ToggleSuperTrackedPinDisplay(false)
    else
        MapPin.ToggleSuperTrackedPinDisplay(true)
    end
end

local function OnSetCrazyArrow(_, uid, _, title)
    TomTomWaypointInfo.name = title
    TomTomWaypointInfo.mapID = uid[1]
    TomTomWaypointInfo.x = uid[2] * 100
    TomTomWaypointInfo.y = uid[3] * 100

    -- skip prompt if we're already tracking another TomTom waypoint
    if not C_SuperTrack.IsSuperTrackingAnything() or (Support_TomTom.IsUserNavigationTomTomWaypoint()) then
        Support_TomTom.PlaceWaypointAtSession()
        return
    else
        WUISharedPrompt:Open(REPLACE_PROMPT_INFO, title)
    end
end

local function OnClearCrazyArrow(_, remove)
    MapPin.ClearUserNavigation()
end


-- Events
--------------------------------

local Events = CreateFrame("Frame")
Events:RegisterEvent("USER_WAYPOINT_UPDATED")
Events:SetScript("OnEvent", Support_TomTom.UpdateSuperTrackPinVisibility)


-- Setup
--------------------------------

local function OnAddonLoad()
    hooksecurefunc(TomTom, "SetCrazyArrow", OnSetCrazyArrow)
    hooksecurefunc(TomTom, "ClearCrazyArrowPoint", OnClearCrazyArrow)

    local UnloadEvent = CreateFrame("Frame")
    UnloadEvent:RegisterEvent("ADDONS_UNLOADING")
    UnloadEvent:SetScript("OnEvent", function()
        if Support_TomTom.IsUserNavigationTomTomWaypoint() then
            MapPin.ClearUserNavigation()
        end
    end)
end
Support.Add("TomTom", OnAddonLoad)
