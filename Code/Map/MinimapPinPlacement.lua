local env = select(2, ...)
local Config = env.Config
local Utils_General = env.modules:Import("packages\\utils\\general")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local MapPin = env.modules:Import("@\\MapPin")
local Navigation_DataProvider = env.modules:Import("@\\Navigation\\DataProvider")
local HBD = LibStub("HereBeDragons-2.0")
local function IsModuleEnabled() return Config.DBGlobal and Config.DBGlobal:GetVariable("MinimapPinPlacementEnabled") == true and MapPin.IsCustomMapPinsEnabled() end

local GetViewRadius = C_Minimap.GetViewRadius
local IsRotateMinimapIgnored = C_Minimap.IsRotateMinimapIgnored
local GetCVar = GetCVar
local GetPlayerFacing = GetPlayerFacing
local GetMinimapShape = GetMinimapShape
local IsControlKeyDown = IsControlKeyDown
local SetCursor = SetCursor
local ResetCursor = ResetCursor
local CreateFrame = CreateFrame
local PlaySound = PlaySound
local tonumber = tonumber
local abs = math.abs
local cos = math.cos
local sin = math.sin


local MINIMAP_RADIUS_INDOOR = { [0] = 150, 120, 90, 60, 40, 25 }
local MINIMAP_RADIUS_OUTDOOR = { [0] = 700 / 3, 200, 500 / 3, 400 / 3, 100, 200 / 3 }
local HasPlacementCursor = false
local IsMinimapHovered = false


local function GetMapPositionAtCursor(minimap)
    local mapID = HBD:GetPlayerZone()
    local playerX, playerY, instanceID = HBD:GetPlayerWorldPosition()
    if not mapID or not playerX or not playerY then return end

    local centerX, centerY = minimap:GetCenter()
    if not centerX or not centerY then return end

    local scale = minimap:GetEffectiveScale()
    local offsetX, offsetY = Utils_General.GetMouseDelta(centerX * scale, centerY * scale)
    offsetX = offsetX / (minimap:GetWidth() * scale * 0.5)
    offsetY = offsetY / (minimap:GetHeight() * scale * 0.5)
    if abs(offsetX) > 1 or abs(offsetY) > 1 then return end

    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    if minimapShape == "ROUND" and offsetX * offsetX + offsetY * offsetY > 1 then return end

    local radius = GetViewRadius and GetViewRadius()
    if not radius then
        local zoom = minimap:GetZoom()
        local isOutdoor = tonumber(GetCVar("minimapZoom")) == zoom
        radius = (isOutdoor and MINIMAP_RADIUS_OUTDOOR or MINIMAP_RADIUS_INDOOR)[zoom]
    end
    if not radius or radius <= 0 then return end

    offsetX, offsetY = offsetX * radius, offsetY * radius
    if GetCVar("rotateMinimap") == "1" and not (IsRotateMinimapIgnored and IsRotateMinimapIgnored()) then
        local facing = GetPlayerFacing()
        if not facing then return end

        local mapCos, mapSin = cos(facing), sin(facing)
        offsetX, offsetY = offsetX * mapCos + offsetY * mapSin, offsetY * mapCos - offsetX * mapSin
    end

    local x, y = HBD:GetZoneCoordinatesFromWorldInstance(playerX - offsetX, playerY - offsetY, instanceID, mapID, true)
    if not x or not y then return end

    return mapID, x * 100, y * 100
end

local function ResetPlacementCursor()
    if not HasPlacementCursor then return end

    HasPlacementCursor = false
    ResetCursor()
end

local function UpdatePlacementCursor()
    if IsMinimapHovered and IsControlKeyDown() and IsModuleEnabled() then
        SetCursor("MAP_PIN_CURSOR")
        HasPlacementCursor = true
    else
        ResetPlacementCursor()
    end
end

local function OnMinimapEnter()
    IsMinimapHovered = true
    UpdatePlacementCursor()
end

local function OnMinimapLeave()
    IsMinimapHovered = false
    ResetPlacementCursor()
end

local function OnMinimapClick(minimap, button)
    if button ~= "LeftButton" or not IsControlKeyDown() then return false end
    if not IsModuleEnabled() then return false end

    local mapID, x, y = GetMapPositionAtCursor(minimap)
    if not mapID then return false end

    local isPathfindingEnabled = Config.DBGlobal:GetVariable("PathfindingEnabled") == true and Navigation_DataProvider:IsEnabled()
    local userNavigation = MapPin.NewTemporaryWaypoint({
        mapID              = mapID,
        x                  = x,
        y                  = y,
        superTracked       = isPathfindingEnabled or Config.DBGlobal:GetVariable("AutoTrackPlacedPinEnabled") == true,
        syncNativeWaypoint = true
    })
    if not userNavigation then return false end

    PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CONTROL_CLICK)
    return true
end

local Minimap_OnMouseUp = Minimap:GetScript("OnMouseUp")
Minimap:SetScript("OnMouseUp", function(self, button, ...)
    if OnMinimapClick(self, button) then return end
    if Minimap_OnMouseUp then Minimap_OnMouseUp(self, button, ...) end
end)

Minimap:EnableMouseMotion(true)
Minimap:HookScript("OnEnter", OnMinimapEnter)
Minimap:HookScript("OnLeave", OnMinimapLeave)
Minimap:HookScript("OnHide", OnMinimapLeave)

local f = CreateFrame("Frame")
f:RegisterEvent("MODIFIER_STATE_CHANGED")
f:SetScript("OnEvent", UpdatePlacementCursor)

SavedVariables.OnChange("WaypointDB_Global", "MinimapPinPlacementEnabled", UpdatePlacementCursor)
CallbackRegistry.Add("MapPin.MapPinsStateChanged", UpdatePlacementCursor)
CallbackRegistry.Add("Preload.DatabaseReady", UpdatePlacementCursor)
