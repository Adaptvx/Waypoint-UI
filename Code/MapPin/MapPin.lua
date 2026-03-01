local env = select(2, ...)
local Config = env.Config
local Sound = env.WPM:Import("wpm_modules\\sound")
local CallbackRegistry = env.WPM:Import("wpm_modules\\callback-registry")
local MapPin = env.WPM:New("@\\MapPin")

local SetSuperTrackedUserWaypoint = C_SuperTrack.SetSuperTrackedUserWaypoint
local IsSuperTrackingAnything = C_SuperTrack.IsSuperTrackingAnything
local ClearAllSuperTracked = C_SuperTrack.ClearAllSuperTracked
local GetHighestPrioritySuperTrackingType = C_SuperTrack.GetHighestPrioritySuperTrackingType
local IsSuperTrackingMapPin = C_SuperTrack.IsSuperTrackingMapPin
local CanSetUserWaypointOnMap = C_Map.CanSetUserWaypointOnMap
local GetUserWaypoint = C_Map.GetUserWaypoint
local SetUserWaypoint = C_Map.SetUserWaypoint
local ClearUserWaypoint = C_Map.ClearUserWaypoint
local HasUserWaypoint = C_Map.HasUserWaypoint
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetMapInfo = C_Map.GetMapInfo
local GetWorldPosFromMapPos = C_Map.GetWorldPosFromMapPos
local CreateFrame = CreateFrame
local CreateVector2D = CreateVector2D
local tostring = tostring
local format = string.format
local pairs = pairs
local WorldMapFrame = WorldMapFrame


do --World Map Util
    function MapPin.ForceWorldMapRefresh()
        WorldMapFrame:SetMapID(GetBestMapForUnit("player"))
        WorldMapFrame:RefreshAll()
    end
end

local SessionData = {
    name  = nil,
    mapID = nil,
    x     = nil,
    y     = nil,
    flags = nil
}

local MUTED_FLAG_MAP = {
    ["TomTom_Waypoint"]       = true,
    ["Dugis_Waypoint"]        = true,
    ["RareScanner_Waypoint"]  = true,
    ["SilverDragon_Waypoint"] = true
}

local function PlayUserNavigationAudio()
    local Setting_CustomAudio = Config.DBGlobal:GetVariable("AudioCustom")
    local soundID = env.Enum.Sound.NewUserNavigation

    if Setting_CustomAudio then
        if tonumber(soundID) then
            soundID = Config.DBGlobal:GetVariable("AudioCustomNewUserNavigation")
        end
    end

    Sound.PlaySound("Main", soundID)
end

function MapPin.ClearUserNavigation(preserveWaypoint)
    if MapPin.GetUserNavigation() and not preserveWaypoint then
        ClearUserWaypoint()
    end
    MapPin.SetUserNavigation(nil, nil, nil, nil, nil)
end

function MapPin.ClearDestination()
    if MapPin.IsUserNavigationTracked() then
        MapPin.ClearUserNavigation()
    end

    if IsSuperTrackingAnything() then
        ClearAllSuperTracked()
    end
end

function MapPin.SetUserNavigation(name, mapID, x, y, flags)
    SessionData.name = name
    SessionData.mapID = mapID
    SessionData.x = x
    SessionData.y = y
    SessionData.flags = flags
    Config.DBLocal:SetVariable("slashWayCache", SessionData)
end

function MapPin.GetUserNavigation()
    local savedWay = Config.DBLocal:GetVariable("slashWayCache")

    if savedWay then
        SessionData.name = savedWay.name
        SessionData.mapID = savedWay.mapID
        SessionData.x = savedWay.x
        SessionData.y = savedWay.y
        SessionData.flags = savedWay.flags
    end

    return SessionData
end

function MapPin.NewUserNavigation(name, mapID, x, y, flags)
    if not mapID or not x or not y then return end

    if x > 100 or y > 100 or x < 0 or y < 0 then
        local mapInfo = GetMapInfo(mapID)
        if mapInfo and mapInfo.parentMapID and mapInfo.parentMapID ~= 0 then
            local parentMapID = mapInfo.parentMapID
            if not CanSetUserWaypointOnMap(parentMapID) then return end
            local _, childOrigin = GetWorldPosFromMapPos(mapID, CreateVector2D(0, 0))
            local _, childRightEdge = GetWorldPosFromMapPos(mapID, CreateVector2D(1, 0))
            local _, childBottomEdge = GetWorldPosFromMapPos(mapID, CreateVector2D(0, 1))
            local _, parentOrigin = GetWorldPosFromMapPos(parentMapID, CreateVector2D(0, 0))
            local _, parentRightEdge = GetWorldPosFromMapPos(parentMapID, CreateVector2D(1, 0))
            local _, parentBottomEdge = GetWorldPosFromMapPos(parentMapID, CreateVector2D(0, 1))
            if childOrigin and childRightEdge and childBottomEdge and parentOrigin and parentRightEdge and parentBottomEdge then
                local normalizedX, normalizedY = x / 100, y / 100
                local worldX = childOrigin.x + normalizedX * (childRightEdge.x - childOrigin.x) + normalizedY * (childBottomEdge.x - childOrigin.x)
                local worldY = childOrigin.y + normalizedX * (childRightEdge.y - childOrigin.y) + normalizedY * (childBottomEdge.y - childOrigin.y)
                local offsetX, offsetY = worldX - parentOrigin.x, worldY - parentOrigin.y
                local parentBasisXx, parentBasisYx = parentRightEdge.x - parentOrigin.x, parentBottomEdge.x - parentOrigin.x
                local parentBasisXy, parentBasisYy = parentRightEdge.y - parentOrigin.y, parentBottomEdge.y - parentOrigin.y
                local determinant = parentBasisXx * parentBasisYy - parentBasisYx * parentBasisXy
                if determinant ~= 0 then
                    local parentNormalizedX = (offsetX * parentBasisYy - offsetY * parentBasisYx) / determinant * 100
                    local parentNormalizedY = (offsetY * parentBasisXx - offsetX * parentBasisXy) / determinant * 100
                    return MapPin.NewUserNavigation(name, parentMapID, parentNormalizedX, parentNormalizedY, flags)
                end
            end
        end
        return
    end

    if not CanSetUserWaypointOnMap(mapID) then return end

    local pos = CreateVector2D(x / 100, y / 100)
    local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)

    MapPin.SetUserNavigation(name, mapID, pos.x, pos.y, flags)
    SetUserWaypoint(mapPoint)
    SetSuperTrackedUserWaypoint(true)

    CallbackRegistry.Trigger("MapPin.NewUserNavigation")

    PlayUserNavigationAudio()
end

function MapPin.IsUserNavigationTracked()
    if HasUserWaypoint() then
        local wp = GetUserWaypoint()
        local pinTracked = GetHighestPrioritySuperTrackingType() == Enum.SuperTrackingType.UserWaypoint
        local userNavigationInfo = MapPin.GetUserNavigation()
        if pinTracked and userNavigationInfo and userNavigationInfo.mapID and userNavigationInfo.x and userNavigationInfo.y then
            local mapIDMatch = tostring(wp.uiMapID) == tostring(userNavigationInfo.mapID)
            local xMatch = format("%0.1f", wp.position.x * 100) == format("%0.1f", userNavigationInfo.x * 100)
            local yMatch = format("%0.1f", wp.position.y * 100) == format("%0.1f", userNavigationInfo.y * 100)
            return mapIDMatch and xMatch and yMatch
        end
    end
    return false
end

function MapPin.IsUserNavigationFlagged(flag)
    local currentUserNavigationInfo = MapPin.GetUserNavigation()
    if currentUserNavigationInfo and currentUserNavigationInfo.flags == flag then
        return true
    end
    return false
end

function MapPin.ToggleSuperTrackedPinDisplay(shown)
    for pin in WorldMapFrame:EnumeratePinsByTemplate("WaypointLocationPinTemplate") do
        pin:SetAlpha(shown and 1 or 0)
        pin:EnableMouse(shown)
    end
end

function MapPin.ValidateSuperTrackedPinDisplay(_, event)
    if event == "USER_WAYPOINT_UPDATED" then
        if (C_SuperTrack.GetHighestPrioritySuperTrackingType() == Enum.SuperTrackingType.UserWaypoint) and not MapPin.IsUserNavigationTracked() then -- Clear stale navigation only when the super-tracked target is a UserWaypoint
            MapPin.ClearUserNavigation(true)
        end
    end

    for flag, _ in pairs(MUTED_FLAG_MAP) do
        if MapPin.IsUserNavigationTracked() and MapPin.IsUserNavigationFlagged(flag) then
            MapPin.ToggleSuperTrackedPinDisplay(false)
            return
        end
    end
    MapPin.ToggleSuperTrackedPinDisplay(true)
end

do --Automatically clear supertracking when the user waypoint is removed
    local f = CreateFrame("Frame")
    f:RegisterEvent("USER_WAYPOINT_UPDATED")
    f:SetScript("OnEvent", function()
        if not HasUserWaypoint() and IsSuperTrackingMapPin() then
            ClearAllSuperTracked()
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("USER_WAYPOINT_UPDATED")
f:RegisterEvent("SUPER_TRACKING_CHANGED")
f:SetScript("OnEvent", MapPin.ValidateSuperTrackedPinDisplay)
CallbackRegistry.Add("MapPin.NewUserNavigation", MapPin.ValidateSuperTrackedPinDisplay)

local function OnAddonLoad()
    MapPin.GetUserNavigation()
    CallbackRegistry.Trigger("MapPin.Ready")
end

CallbackRegistry.Add("Preload.AddonReady", OnAddonLoad)
