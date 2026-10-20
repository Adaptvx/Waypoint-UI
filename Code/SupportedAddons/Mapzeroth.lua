local env = select(2, ...)
local L = env.L
local Config = env.Config
local Path = env.modules:Import("packages\\path")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local MapPin = env.modules:Import("@\\MapPin")
local Navigation_DataProvider = env.modules:Import("@\\Navigation\\DataProvider")
local SupportedAddons = env.modules:Import("@\\SupportedAddons")
local SupportedAddons_Mapzeroth = env.modules:New("@\\SupportedAddons\\Mapzeroth")
local function IsModuleEnabled() return Config.DBGlobal:GetVariable("MapzerothSupportEnabled") == true end

local Mapzeroth = nil
local MapzerothWaypointInfo = { plan = nil, step = nil, index = nil, name = nil, mapID = nil, x = nil, y = nil }


local function HandleAccept()
    SupportedAddons_Mapzeroth.PlaceWaypointAtSession()
end

local REPLACE_PROMPT_INFO = {
    text         = L["MAPZEROTH_REPLACEPROMPT"],
    options      = {
        {
            text     = L["REPLACE"],
            callback = HandleAccept
        },
        {
            text     = L["CANCEL"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}


local function ResetWaypointInfo()
    wipe(MapzerothWaypointInfo)

    if MapPin.IsUserNavigationFlagged("Mapzeroth_Waypoint") then
        MapPin.ClearUserNavigation()
    end
end

local function GetStepTarget(model)
    local step = model.step
    local points = step.path
    local useSource = model.kind == "portal" or step.method == "transition" or step.method == "equip" or (model.kind == "flight" and model.phase ~= "flying") or (model.kind == "transport" and model.phase ~= "underway")
    local target = nil

    if type(points) == "table" and #points > 0 then
        target = points[useSource and 1 or #points]
    end

    if not target then
        target = Mapzeroth.World:GetNode(useSource and step.fromID or step.nodeID)
    end
    if type(target) ~= "table" then return nil end

    local mapID = tonumber(target.mapID)
    local x = tonumber(target.x)
    local y = tonumber(target.y)
    if not mapID or not x or not y then return nil end

    return mapID, x * 100, y * 100
end

function SupportedAddons_Mapzeroth.PlaceWaypointAtSession()
    if not IsModuleEnabled() or not Mapzeroth then return end
    if not MapzerothWaypointInfo.mapID or not MapzerothWaypointInfo.x or not MapzerothWaypointInfo.y then return end

    local model = Mapzeroth.Navigation:Model()
    if not model or model.finished or model.offRoute or model.step ~= MapzerothWaypointInfo.step or model.index ~= MapzerothWaypointInfo.index then return end
    if Mapzeroth.Navigation:CurrentPlan() ~= MapzerothWaypointInfo.plan then return end

    if Navigation_DataProvider:HasPath() then
        Navigation_DataProvider:ClearSessionData({ preserveNativeDestination = true })
    end

    MapPin.NewUserNavigation({
        name                = MapzerothWaypointInfo.name,
        mapID               = MapzerothWaypointInfo.mapID,
        x                   = MapzerothWaypointInfo.x,
        y                   = MapzerothWaypointInfo.y,
        flags               = "Mapzeroth_Waypoint",
        iconTexture         = Path.Root .. "\\Art\\Icons\\TomTomArrow",
        requestRecolor      = true,
        suppressAudio       = MapPin.IsUserNavigationFlagged("Mapzeroth_Waypoint"),
        suppressPathfinding = true
    })
end

local function RefreshSessionWaypoint()
    local model = Mapzeroth and Mapzeroth.Navigation:Model()
    if not IsModuleEnabled() or not model or model.finished or model.offRoute or not model.step then
        ResetWaypointInfo()
        return
    end

    local mapID, x, y = GetStepTarget(model)
    if not mapID then
        ResetWaypointInfo()
        return
    end

    local plan = Mapzeroth.Navigation:CurrentPlan()
    local name = model.step.text or model.step.name or model.destination or L["MAPZEROTH"]
    local waypointChanged = MapzerothWaypointInfo.plan ~= plan or MapzerothWaypointInfo.step ~= model.step or MapzerothWaypointInfo.index ~= model.index or MapzerothWaypointInfo.mapID ~= mapID or MapzerothWaypointInfo.x ~= x or MapzerothWaypointInfo.y ~= y
    local nameChanged = MapzerothWaypointInfo.name ~= name

    MapzerothWaypointInfo.plan = plan
    MapzerothWaypointInfo.step = model.step
    MapzerothWaypointInfo.index = model.index
    MapzerothWaypointInfo.name = name
    MapzerothWaypointInfo.mapID = mapID
    MapzerothWaypointInfo.x = x
    MapzerothWaypointInfo.y = y

    if not waypointChanged then
        if nameChanged and MapPin.IsUserNavigationFlagged("Mapzeroth_Waypoint") then
            local currentWaypoint = MapPin.GetUserNavigation()
            currentWaypoint.name = name
            MapPin.SetUserNavigation(currentWaypoint)
            CallbackRegistry.Trigger("MapPin.NewUserNavigation", currentWaypoint, { suppressPathfinding = true })
        end
        return
    end

    if Config.DBGlobal:GetVariable("MapzerothAutoReplaceWaypoint") == true or not C_SuperTrack.IsSuperTrackingAnything() or MapPin.IsUserNavigationFlagged("Mapzeroth_Waypoint") then
        SupportedAddons_Mapzeroth.PlaceWaypointAtSession()
    else
        WUISharedPrompt:Open(REPLACE_PROMPT_INFO, name)
    end
end

local function OnAddonLoad()
    Mapzeroth = _G.MapzerothAddon
    local navigation = Mapzeroth and Mapzeroth.Navigation
    if not navigation or type(navigation.Model) ~= "function" or type(navigation.CurrentPlan) ~= "function" then return end
    if type(navigation.Start) ~= "function" or type(navigation.Update) ~= "function" or type(navigation.Stop) ~= "function" then return end
    if not Mapzeroth.World or type(Mapzeroth.World.GetNode) ~= "function" then return end

    hooksecurefunc(navigation, "Start", RefreshSessionWaypoint)
    hooksecurefunc(navigation, "Update", RefreshSessionWaypoint)
    hooksecurefunc(navigation, "Stop", ResetWaypointInfo)

    SavedVariables.OnChange("WaypointDB_Global", "MapzerothSupportEnabled", RefreshSessionWaypoint)
    SavedVariables.OnChange("WaypointDB_Global", "MapzerothAutoReplaceWaypoint", function(enabled)
        if enabled == true then SupportedAddons_Mapzeroth.PlaceWaypointAtSession() end
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDONS_UNLOADING")
    f:SetScript("OnEvent", ResetWaypointInfo)

    RefreshSessionWaypoint()
end

SupportedAddons.Add("Mapzeroth", OnAddonLoad)
