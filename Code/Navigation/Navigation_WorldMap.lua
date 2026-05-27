local env = select(2, ...)
local Config = env.Config
local Path = env.modules:Import("packages\\path")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local MapPin = env.modules:Import("@\\MapPin")
local MapPinFrame = env.modules:Import("@\\MapPinFrame")
local Waypoint_DataProvider = env.modules:Import("@\\Waypoint\\DataProvider")
local Navigation_Shared = env.modules:Import("@\\Navigation\\Shared")
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")
local Navigation_DataProvider = env.modules:Await("@\\Navigation\\DataProvider")
local Navigation_WorldMap = env.modules:New("@\\Navigation\\WorldMap")

local SetSuperTrackedMapPin = C_SuperTrack.SetSuperTrackedMapPin
local SetSuperTrackedContent = C_SuperTrack.SetSuperTrackedContent
local SetSuperTrackedQuestID = C_SuperTrack.SetSuperTrackedQuestID
local SetSuperTrackedVignette = C_SuperTrack.SetSuperTrackedVignette
local SetSuperTrackedUserWaypoint = C_SuperTrack.SetSuperTrackedUserWaypoint
local ClearAllSuperTracked = C_SuperTrack.ClearAllSuperTracked
local GetSuperTrackedQuestID = C_SuperTrack.GetSuperTrackedQuestID
local GetSuperTrackedMapPin = C_SuperTrack.GetSuperTrackedMapPin
local GetSuperTrackedContent = C_SuperTrack.GetSuperTrackedContent
local GetSuperTrackedVignette = C_SuperTrack.GetSuperTrackedVignette
local GetSuperTrackedItemName = C_SuperTrack.GetSuperTrackedItemName
local GetNextWaypointForMap = C_SuperTrack.GetNextWaypointForMap
local IsSuperTrackingAnything = C_SuperTrack.IsSuperTrackingAnything
local IsSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint
local SetUserWaypoint = C_Map.SetUserWaypoint
local GetUserWaypoint = C_Map.GetUserWaypoint
local ClearUserWaypoint = C_Map.ClearUserWaypoint
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local HasUserWaypoint = C_Map.HasUserWaypoint
local GetTitleForQuestID = C_QuestLog.GetTitleForQuestID
local wipe = wipe


local SUPER_TRACK_WAYPOINT_PIN_TEMPLATE = "SuperTrackWaypointPinTemplate"
local USER_WAYPOINT_PIN_TEMPLATE = "WaypointLocationPinTemplate"
local QUEST_PIN_TEMPLATE = "QuestPinTemplate"
local WORLD_QUEST_PIN_TEMPLATE = "WorldMap_WorldQuestPinTemplate"

local Snapshot = {}
local SearchMapPinType = nil
local SearchMapPinTypeID = nil
local SearchResultPin = nil
local BlockPathfindingOwner = nil

local BlockPathfindingTimer = LazyTimer.New()
BlockPathfindingTimer:SetAction(function()
    if BlockPathfindingOwner then
        BlockPathfindingOwner.blockPathfinding = false
        BlockPathfindingOwner = nil
    end
end)


local WorldMapUtil = {}
do
    function WorldMapUtil.FindSuperTrackedMapPin_OnPin(pin)
        if SearchResultPin or not pin.GetSuperTrackData or not pin:IsShown() then return end

        local pinType, pinTypeID = pin:GetSuperTrackData()
        if pinType == SearchMapPinType and pinTypeID == SearchMapPinTypeID then
            SearchResultPin = pin
        end
    end

    function WorldMapUtil.CopySnapshot(source)
        wipe(Snapshot)
        if not source then return end

        Snapshot.name = source.name
        Snapshot.questID = source.questID
        Snapshot.normalizedX = source.normalizedX
        Snapshot.normalizedY = source.normalizedY
        Snapshot.mapID = source.mapID
        Snapshot.fromWUI = source.fromWUI
        Snapshot.pinTemplate = source.pinTemplate
        Snapshot.metadata = source.metadata
        Snapshot.iconTexture = source.iconTexture
        Snapshot.userNavigation = source.userNavigation
    end

    function WorldMapUtil.IsCurrentWaypoint(mapID, x, y)
        if not mapID or not x or not y or not HasUserWaypoint() then return false end

        local waypoint = GetUserWaypoint()
        if not waypoint or not waypoint.position or waypoint.uiMapID ~= mapID then return false end

        return math.abs(waypoint.position.x - x) < 0.0005 and math.abs(waypoint.position.y - y) < 0.0005
    end

    function WorldMapUtil.RestoreUserWaypoint(target, superTrack)
        local userNavigation = target.userNavigation
        local sourcePinID = userNavigation and userNavigation.sourcePinID or nil
        if sourcePinID and MapPin.IsMultiPinEnabled() then
            local restoredNavigation = MapPin.NewUserNavigationFromPin(sourcePinID, true, { suppressPathfinding = true })
            if not restoredNavigation then return false end

            MapPin.SetUserNavigationSuperTracked(superTrack == true, false)
            if superTrack ~= true then
                SetSuperTrackedUserWaypoint(false)
            end
            return true
        end

        if userNavigation then
            local restoredNavigation = MapPin.SetUserNavigationSuperTracked(superTrack == true, false)
            if restoredNavigation and superTrack == true then
                MapPin.SyncUserNavigationToNativeWaypoint()
            elseif restoredNavigation then
                SetSuperTrackedUserWaypoint(false)
            end
            return restoredNavigation ~= nil
        end

        local mapID = (userNavigation and userNavigation.mapID) or target.mapID
        local x = (userNavigation and userNavigation.x) or target.normalizedX
        local y = (userNavigation and userNavigation.y) or target.normalizedY
        local resolvedMapID, pos, mapPoint = MapPin.CreateUserWaypointPoint(mapID, x, y, true)
        if not resolvedMapID or not pos or not mapPoint then return false end

        local restoredNavigation = MapPin.SetUserNavigation({
            name             = (userNavigation and userNavigation.name) or target.name,
            mapID            = resolvedMapID,
            x                = pos.x,
            y                = pos.y,
            fromWUI          = not userNavigation or userNavigation.fromWUI ~= false,
            flags            = userNavigation and userNavigation.flags,
            iconTexture      = (userNavigation and userNavigation.iconTexture) or target.iconTexture,
            iconType         = userNavigation and userNavigation.iconType,
            r                = userNavigation and userNavigation.r,
            g                = userNavigation and userNavigation.g,
            b                = userNavigation and userNavigation.b,
            requestRecolor   = userNavigation and userNavigation.requestRecolor,
            stripCoordinates = userNavigation and userNavigation.stripCoordinates
        })
        MapPin.SuppressNextUserNavigationValidation(restoredNavigation)

        if not WorldMapUtil.IsCurrentWaypoint(resolvedMapID, pos.x, pos.y) then
            CallbackRegistry.Trigger("Map.AutoTrackPlacedPin.SuppressNextUpdate")
            SetUserWaypoint(mapPoint)
        end

        SetSuperTrackedUserWaypoint(superTrack == true)
        return true
    end

    function WorldMapUtil.IsPathfindingEnabled()
        if not Config.DBGlobal or Config.DBGlobal:GetVariable("PathfindingEnabled") ~= true then return false end
        return Navigation_DataProvider:IsEnabled() == true
    end

    function WorldMapUtil.DestinationPin_OnClick(self, button)
        local owner = self.__wuiNavigationDestinationOwner
        if button == "LeftButton" and owner and owner.HasPath and owner:HasPath() and Navigation_WorldMap:SearchForDestinationPin() == self then
            if IsControlKeyDown() then return end
            Navigation_WorldMap:AbortPathfindingFromDestinationPin(owner)
        end
    end

    function WorldMapUtil.SuppressOwnerNativeWaypointSuperTracking(owner)
        if not owner then return end

        if owner.SuppressNativeWaypointSuperTrackingChanged then
            owner:SuppressNativeWaypointSuperTrackingChanged()
        elseif owner.SuppressSuperTrackingChanged then
            owner:SuppressSuperTrackingChanged()
        end
    end
end


function Navigation_WorldMap:GetSuperTrackedMetadata()
    local metadata = {}

    local mapPinType, mapPinTypeID = GetSuperTrackedMapPin()
    if mapPinType then
        metadata.pinType = Navigation_Preload.Enum.SuperTrackedPinType.MapPin
        metadata.type = mapPinType
        metadata.typeID = mapPinTypeID
        return metadata
    end

    local trackableType, trackableID = GetSuperTrackedContent()
    if trackableType then
        metadata.pinType = Navigation_Preload.Enum.SuperTrackedPinType.Content
        metadata.trackableType = trackableType
        metadata.trackableID = trackableID
        return metadata
    end

    local questID = GetSuperTrackedQuestID()
    if questID then
        metadata.pinType = Navigation_Preload.Enum.SuperTrackedPinType.Quest
        metadata.questID = questID
        return metadata
    end

    local vignetteGUID = GetSuperTrackedVignette()
    if vignetteGUID then
        metadata.pinType = Navigation_Preload.Enum.SuperTrackedPinType.Vignette
        metadata.vignetteGUID = vignetteGUID
        return metadata
    end

    if HasUserWaypoint() and IsSuperTrackingUserWaypoint() then
        metadata.pinType = Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint
    end

    return metadata
end

function Navigation_WorldMap:GetSuperTrackedQuestID()
    local questID = GetSuperTrackedQuestID()
    return questID ~= 0 and questID or nil
end

function Navigation_WorldMap:FindShownPinByTemplate(pinTemplate, predicate)
    for pin in WorldMapFrame:EnumeratePinsByTemplate(pinTemplate) do
        if pin:IsShown() and (not predicate or predicate(pin)) then
            return pin
        end
    end
end

function Navigation_WorldMap:FindSuperTrackedUserWaypointPin()
    return IsSuperTrackingUserWaypoint() and self:FindShownPinByTemplate(USER_WAYPOINT_PIN_TEMPLATE) or nil
end

function Navigation_WorldMap:FindSuperTrackedQuestPin(questID)
    return questID and self:FindShownPinByTemplate(QUEST_PIN_TEMPLATE, function(pin) return pin:GetQuestID() == questID end) or nil
end

function Navigation_WorldMap:FindSuperTrackedWorldQuestPin(questID)
    return questID and self:FindShownPinByTemplate(WORLD_QUEST_PIN_TEMPLATE, function(pin) return pin:GetQuestID() == questID end) or nil
end

function Navigation_WorldMap:FindSuperTrackedMapPin(mapPinType, mapPinTypeID)
    if mapPinType == nil or mapPinTypeID == nil then return nil end

    SearchMapPinType = mapPinType
    SearchMapPinTypeID = mapPinTypeID
    SearchResultPin = nil

    WorldMapFrame:ExecuteOnAllPins(WorldMapUtil.FindSuperTrackedMapPin_OnPin)

    local pin = SearchResultPin

    SearchMapPinType = nil
    SearchMapPinTypeID = nil
    SearchResultPin = nil

    if pin then
        return pin, mapPinType, mapPinTypeID
    end
end

function Navigation_WorldMap:FindSuperTrackWaypoint()
    return self:FindShownPinByTemplate(SUPER_TRACK_WAYPOINT_PIN_TEMPLATE)
end

function Navigation_WorldMap:FindSuperTrackedPin(metadata)
    metadata = metadata or self:GetSuperTrackedMetadata()

    if metadata and metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint and IsSuperTrackingUserWaypoint() then
        local pin = self:FindSuperTrackedUserWaypointPin()
        if pin then
            return pin
        end
    end

    if metadata and metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.Quest then
        local pin = self:FindSuperTrackedQuestPin(metadata.questID) or self:FindSuperTrackedWorldQuestPin(metadata.questID)
        if pin then
            return pin
        end
    elseif metadata and metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.MapPin then
        return self:FindSuperTrackedMapPin(metadata.type, metadata.typeID)
    end

    local questID = self:GetSuperTrackedQuestID()
    local pin = self:FindSuperTrackedQuestPin(questID) or self:FindSuperTrackedWorldQuestPin(questID)
    if pin then
        return pin
    end

    local mapPinType, mapPinTypeID = GetSuperTrackedMapPin()
    pin = self:FindSuperTrackedMapPin(mapPinType, mapPinTypeID)
    if pin then
        return pin
    end

    if IsSuperTrackingUserWaypoint() then
        return self:FindSuperTrackedUserWaypointPin()
    end
end

function Navigation_WorldMap:GetSuperTrackedPin(metadata)
    return self:FindSuperTrackedPin(metadata)
end

function Navigation_WorldMap:GetPinQuestID(pin)
    if not pin then return nil end

    local questID = pin.GetQuestID and pin:GetQuestID() or pin.questID
    return questID ~= 0 and questID or nil
end

function Navigation_WorldMap:GetUserWaypointPinName()
    local userNavigation = MapPin.GetUserNavigation()
    if MapPin.IsCustomUserNavigation(userNavigation) and userNavigation.name and userNavigation.name ~= MAP_PIN then
        return userNavigation.name
    end
end

function Navigation_WorldMap:GetPinName(pin, questID)
    if not pin then return nil end

    local pinName = pin.name or pin.questName
    if pinName then return pinName end

    if pin.pinTemplate == USER_WAYPOINT_PIN_TEMPLATE then return self:GetUserWaypointPinName() end

    return questID and GetTitleForQuestID(questID) or nil
end

function Navigation_WorldMap:GetPinContextIcon(pin, questID)
    if questID then return Waypoint_DataProvider.GetContextIconTextureForQuest(questID) end
    return pin and pin.Texture and pin.Texture:GetAtlas() or nil
end

function Navigation_WorldMap:GetPinMapPosition(pin)
    if not pin then return nil, nil, nil end

    if pin.GetResolvedMapLocation then
        return pin:GetResolvedMapLocation(pin:GetResolvedPinInfo())
    end

    local mapID = pin.lastOwningMapID
    local normalizedX = pin.normalizedX
    local normalizedY = pin.normalizedY

    if (not normalizedX or not normalizedY) and pin.GetPosition then
        normalizedX, normalizedY = pin:GetPosition()
    end

    if not mapID and pin.GetMap then
        local map = pin:GetMap()
        if map and map.GetMapID then
            mapID = map:GetMapID()
        elseif map then
            mapID = map.mapID
        end
    end

    return mapID, normalizedX, normalizedY
end

function Navigation_WorldMap:GetVisibleMapSuperTrackedPosition()
    local mapID = WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or nil
    local normalizedX, normalizedY = nil, nil

    if mapID then
        normalizedX, normalizedY = GetNextWaypointForMap(mapID)
        if normalizedX and normalizedY then
            return mapID, normalizedX, normalizedY
        end
    end

    mapID = GetBestMapForUnit("player")
    if not mapID then return nil, nil, nil end

    normalizedX, normalizedY = GetNextWaypointForMap(mapID)
    if normalizedX and normalizedY then return mapID, normalizedX, normalizedY end

    return nil, nil, nil
end

function Navigation_WorldMap:GetUserWaypointDestinationState()
    local userNavigation = MapPin.GetUserNavigation()
    if not userNavigation then return nil end

    return {
        pin            = MapPinFrame:GetUserNavigationWorldPin(),
        name           = userNavigation.name or MAP_PIN,
        questID        = nil,
        normalizedX    = userNavigation.x,
        normalizedY    = userNavigation.y,
        mapID          = userNavigation.mapID,
        fromWUI        = userNavigation.fromWUI ~= false,
        pinTemplate    = USER_WAYPOINT_PIN_TEMPLATE,
        metadata       = { pinType = Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint },
        iconTexture    = userNavigation.iconTexture,
        userNavigation = userNavigation
    }
end

function Navigation_WorldMap:GetTrackedUserWaypointState(pin)
    local trackedUserNavigation = MapPin.IsUserNavigationTracked() and MapPin.GetUserNavigation() or nil
    local userNavigation = MapPin.IsCustomUserNavigation(trackedUserNavigation) and trackedUserNavigation or nil
    local waypoint = HasUserWaypoint() and GetUserWaypoint() or nil
    local mapID = waypoint and waypoint.uiMapID or nil
    local normalizedX = waypoint and waypoint.position.x or nil
    local normalizedY = waypoint and waypoint.position.y or nil
    local pinMapID, pinNormalizedX, pinNormalizedY = self:GetPinMapPosition(pin)

    mapID = mapID or pinMapID
    normalizedX = normalizedX or pinNormalizedX
    normalizedY = normalizedY or pinNormalizedY

    if trackedUserNavigation then
        mapID = mapID or trackedUserNavigation.mapID
        normalizedX = normalizedX or trackedUserNavigation.x
        normalizedY = normalizedY or trackedUserNavigation.y
    end

    return userNavigation, mapID, normalizedX, normalizedY
end

function Navigation_WorldMap:DoesUserNavigationMatchWaypoint(userNavigation, mapID, normalizedX, normalizedY)
    if not userNavigation or not MapPin.IsCustomUserNavigation(userNavigation) then return false end
    if not mapID then return false end
    if normalizedX == nil or normalizedY == nil then return false end

    return tostring(userNavigation.mapID) == tostring(mapID) and Navigation_Shared.AreNumbersEquivalent(userNavigation.x, normalizedX) and Navigation_Shared.AreNumbersEquivalent(userNavigation.y, normalizedY)
end

function Navigation_WorldMap:GetLiveUserWaypointDestinationState(snapshot)
    if not HasUserWaypoint() then return nil end

    local waypoint = GetUserWaypoint()
    if not waypoint or not waypoint.position then return nil end

    local mapID = waypoint.uiMapID
    local normalizedX = waypoint.position.x
    local normalizedY = waypoint.position.y
    local userNavigation = MapPin.GetUserNavigation()
    userNavigation = self:DoesUserNavigationMatchWaypoint(userNavigation, mapID, normalizedX, normalizedY) and userNavigation or nil

    return {
        pin            = nil,
        name           = (userNavigation and userNavigation.name) or MAP_PIN,
        questID        = nil,
        normalizedX    = normalizedX,
        normalizedY    = normalizedY,
        mapID          = mapID,
        fromWUI        = userNavigation ~= nil,
        pinTemplate    = USER_WAYPOINT_PIN_TEMPLATE,
        metadata       = snapshot and snapshot.metadata or { pinType = Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint },
        iconTexture    = userNavigation and userNavigation.iconTexture or nil,
        userNavigation = userNavigation
    }
end

function Navigation_WorldMap:IsUserWaypointSnapshot(snapshot)
    local metadata = snapshot and snapshot.metadata or nil
    return metadata and metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint
end

function Navigation_WorldMap:DoesUserWaypointMatchSnapshot(snapshot, userNavigation, mapID, normalizedX, normalizedY)
    if not self:IsUserWaypointSnapshot(snapshot) then return false end

    local savedUserNavigation = snapshot.userNavigation
    local savedSourcePinID = savedUserNavigation and savedUserNavigation.sourcePinID or nil
    local sourcePinID = userNavigation and userNavigation.sourcePinID or nil

    if savedSourcePinID and sourcePinID then return savedSourcePinID == sourcePinID end

    if not snapshot.mapID or not mapID then return false end
    if snapshot.normalizedX == nil or snapshot.normalizedY == nil then return false end
    if normalizedX == nil or normalizedY == nil then return false end

    return snapshot.mapID == mapID and Navigation_Shared.AreNumbersEquivalent(snapshot.normalizedX, normalizedX) and Navigation_Shared.AreNumbersEquivalent(snapshot.normalizedY, normalizedY)
end

function Navigation_WorldMap:DoesDestinationMetadataMatch(a, b)
    if a == b then return true end
    if not a or not b then return false end
    if a.pinType ~= b.pinType then return false end

    local pinType = a.pinType
    if pinType == Navigation_Preload.Enum.SuperTrackedPinType.MapPin then
        return a.type == b.type and a.typeID == b.typeID
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Content then
        return a.trackableType == b.trackableType and a.trackableID == b.trackableID
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Quest then
        return a.questID == b.questID
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Vignette then
        return a.vignetteGUID == b.vignetteGUID
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint then
        return true
    end

    return false
end

function Navigation_WorldMap:GetTrackedDestinationState(pin, metadata)
    local pinType = metadata and metadata.pinType or nil

    local questID = self:GetPinQuestID(pin)
    local name = self:GetPinName(pin, questID)
    local pinName = GetSuperTrackedItemName()
    local mapID, normalizedX, normalizedY = self:GetPinMapPosition(pin)
    local userNavigation = nil
    local fromWUI = nil

    if pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint then
        userNavigation, mapID, normalizedX, normalizedY = self:GetTrackedUserWaypointState(pin)
        fromWUI = userNavigation ~= nil
        name = (userNavigation and userNavigation.name) or pinName or MAP_PIN
    elseif not pin then
        mapID, normalizedX, normalizedY = self:GetVisibleMapSuperTrackedPosition()
    end

    if not mapID or normalizedX == nil or normalizedY == nil then return nil end

    return {
        pin            = pin,
        name           = name or pinName,
        questID        = questID,
        normalizedX    = normalizedX,
        normalizedY    = normalizedY,
        mapID          = mapID,
        fromWUI        = fromWUI,
        pinTemplate    = pin and pin.pinTemplate or (pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint and USER_WAYPOINT_PIN_TEMPLATE or nil),
        metadata       = metadata,
        iconTexture    = self:GetPinContextIcon(pin, questID) or (userNavigation and userNavigation.iconTexture or nil),
        userNavigation = userNavigation
    }
end

function Navigation_WorldMap:ApplyDestinationSnapshot(snapshot, destination)
    if not snapshot or not destination then return end

    snapshot.name = destination.name
    snapshot.questID = destination.questID
    snapshot.normalizedX = destination.normalizedX
    snapshot.normalizedY = destination.normalizedY
    snapshot.mapID = destination.mapID
    snapshot.fromWUI = destination.fromWUI
    snapshot.pinTemplate = destination.pinTemplate
    snapshot.metadata = destination.metadata
    snapshot.iconTexture = destination.iconTexture
    snapshot.userNavigation = destination.userNavigation
end

function Navigation_WorldMap:DoesTrackedDestinationMatchSnapshot(snapshot, destination)
    if not snapshot or not destination then return false end
    if not self:DoesDestinationMetadataMatch(snapshot.metadata, destination.metadata) then return false end

    if self:IsUserWaypointSnapshot(snapshot) then
        return self:DoesUserWaypointMatchSnapshot(snapshot, destination.userNavigation, destination.mapID, destination.normalizedX, destination.normalizedY)
    end

    return snapshot.name == destination.name and snapshot.questID == destination.questID and snapshot.pinTemplate == destination.pinTemplate
end

function Navigation_WorldMap:SetPinHighlight(pin, active)
    if not pin then return end

    if pin.SetSuperTracked then
        pin:SetSuperTracked(active)
    elseif pin.SetActive then
        pin:SetActive(active)
    elseif pin.ChangeSelected then
        pin:ChangeSelected(active)
    elseif pin.SetSelected then
        pin:SetSelected(active)
    elseif pin.SetHighlighted then
        pin:SetHighlighted(active)
    end
end

function Navigation_WorldMap:SetDestinationPinSnapshot(source)
    WorldMapUtil.CopySnapshot(source)
end

function Navigation_WorldMap:GetDestinationPinSnapshot()
    return Snapshot
end

function Navigation_WorldMap:CaptureDestinationPinSnapshot(owner, destination)
    if not destination then
        local metadata = self:GetSuperTrackedMetadata()
        local pin = self:FindSuperTrackedPin(metadata)
        destination = self:GetTrackedDestinationState(pin, metadata)
    end
    if not destination then return false end

    wipe(Snapshot)
    self:ApplyDestinationSnapshot(Snapshot, destination)
    self:HookDestinationPin(destination.pin, owner)

    return true
end

function Navigation_WorldMap:ClearDestinationPinSnapshot()
    local destinationPin = self:SearchForDestinationPin(Snapshot)

    self:SetPinHighlight(destinationPin, false)
    wipe(Snapshot)
end

function Navigation_WorldMap:SearchForDestinationPin(snapshot)
    snapshot = snapshot or Snapshot
    if snapshot and snapshot.userNavigation then
        local pin = MapPinFrame:GetUserNavigationWorldPin()
        return pin and pin:IsShown() and pin or nil
    end

    if snapshot and snapshot.pinTemplate then
        return self:FindShownPinByTemplate(snapshot.pinTemplate, function(pin)
            if pin.pinTemplate ~= snapshot.pinTemplate then return false end

            if self:IsUserWaypointSnapshot(snapshot) then
                local userNavigation, mapID, normalizedX, normalizedY = self:GetTrackedUserWaypointState(pin)
                return self:DoesUserWaypointMatchSnapshot(snapshot, userNavigation, mapID, normalizedX, normalizedY)
            end

            local questID = self:GetPinQuestID(pin)
            local name = self:GetPinName(pin, questID)
            return (snapshot.name and name == snapshot.name) or (snapshot.questID and questID == snapshot.questID)
        end)
    end
end

function Navigation_WorldMap:SuperTrackDestination(owner)
    local destinationPin = self:GetDestinationPinSnapshot()
    if not destinationPin then return end

    local metadata = destinationPin.metadata
    if not metadata then return end

    local pinType = metadata.pinType
    if not pinType then return end

    if pinType == Navigation_Preload.Enum.SuperTrackedPinType.MapPin then
        SetSuperTrackedMapPin(metadata.type, metadata.typeID)
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Content then
        SetSuperTrackedContent(metadata.trackableType, metadata.trackableID)
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Quest then
        SetSuperTrackedQuestID(metadata.questID)
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.Vignette then
        SetSuperTrackedVignette(metadata.vignetteGUID)
    elseif pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint then
        WorldMapUtil.SuppressOwnerNativeWaypointSuperTracking(owner)
        if not self:RestoreDestination(true) then
            SetSuperTrackedUserWaypoint(true)
        end
    end
end

function Navigation_WorldMap:ForceHighlightDestinationPin(hasPath)
    if not hasPath then return end

    local destinationPin = self:SearchForDestinationPin()
    if not destinationPin then return end

    self:SetPinHighlight(destinationPin, true)
end

function Navigation_WorldMap:ForceHideSuperTrackWaypoint()
    local pin = self:FindSuperTrackWaypoint()
    if not pin then return end

    local shouldShow = false
    pin:SetAlpha(shouldShow and 1 or 0)
    pin:EnableMouse(shouldShow)
end

function Navigation_WorldMap:RestoreDestination(superTrack, source)
    local target = source or Snapshot
    local metadata = target and target.metadata or nil
    if not metadata then return false end

    if self:IsUserWaypointSnapshot(target) then
        return WorldMapUtil.RestoreUserWaypoint(target, superTrack)
    elseif metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.MapPin then
        SetSuperTrackedMapPin(metadata.type, metadata.typeID)
    elseif metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.Content then
        SetSuperTrackedContent(metadata.trackableType, metadata.trackableID)
    elseif metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.Quest then
        SetSuperTrackedQuestID(metadata.questID)
    elseif metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.Vignette then
        SetSuperTrackedVignette(metadata.vignetteGUID)
    else
        return false
    end

    return true
end

function Navigation_WorldMap:UntrackDestination()
    if self:IsUserWaypointSnapshot(Snapshot) then
        MapPin.SetUserNavigationSuperTracked(false, false)
        SetSuperTrackedUserWaypoint(false)
        return
    end

    if IsSuperTrackingAnything() then
        ClearAllSuperTracked()
    end
end

function Navigation_WorldMap:HasDestinationChanged()
    if not Snapshot.metadata then return false end

    local metadata = self:GetSuperTrackedMetadata()
    if MapPin.IsPathStepWaypointTracked()
        and (not metadata or not metadata.pinType or metadata.pinType == Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint) then
        return false
    end

    local destination = self:GetTrackedDestinationState(self:FindSuperTrackedPin(metadata), metadata)
    if not destination then return false end

    return not self:DoesTrackedDestinationMatchSnapshot(Snapshot, destination)
end

function Navigation_WorldMap:IsSuperTrackingPathStepWaypoint()
    return MapPin.IsPathStepWaypointTracked()
end

function Navigation_WorldMap:AbortPathfindingFromDestinationPin(owner)
    if not owner then return end

    WorldMapUtil.SuppressOwnerNativeWaypointSuperTracking(owner)
    owner.blockPathfinding = true
    BlockPathfindingOwner = owner
    BlockPathfindingTimer:Start(0)

    self:RestoreDestination(false)
    self:ClearDestinationPinSnapshot()
    CallbackRegistry.Trigger("Navigation_DataProvider.ClearDestinationPinSnapshot")

    if owner.StopPathfinding then
        owner:StopPathfinding()
    end

    self:UntrackDestination()
end

function Navigation_WorldMap:ClearDestinationFromDestinationPin(owner)
    if not owner then return end

    WorldMapUtil.SuppressOwnerNativeWaypointSuperTracking(owner)
    owner.blockPathfinding = true
    BlockPathfindingOwner = owner
    BlockPathfindingTimer:Start(0)

    MapPin.ClearDestination()
    if owner.ClearSessionData then
        owner:ClearSessionData()
    end

    if HasUserWaypoint() then
        ClearUserWaypoint()
    end
end

function Navigation_WorldMap:HookDestinationPin(pin, owner)
    if not pin then return end

    pin.__wuiNavigationDestinationOwner = owner
    if not pin.__wuiNavigationInitialized then
        pin:HookScript("OnMouseUp", WorldMapUtil.DestinationPin_OnClick)
        pin.__wuiNavigationInitialized = true
    end
end

function Navigation_WorldMap:ShouldShowPathStepWaypoint()
    return MapPin.GetPathStepWaypoint() ~= nil
end

function Navigation_WorldMap.SetPathStepWaypoint(step)
    if not step then return end

    MapPin.NewPathStepWaypoint({
        name             = step.name,
        mapID            = step.mapID,
        x                = math.min(step.normalizedX * 100, 100),
        y                = math.min(step.normalizedY * 100, 100),
        iconTexture      = Path.Root .. "\\Art\\Icons\\Redirect",
        requestRecolor   = true,
        stripCoordinates = true,
        superTracked     = true
    })
end

function Navigation_WorldMap.ClearPathStepWaypoint(preserveNativeDestination)
    MapPin.ClearPathStepWaypoint(preserveNativeDestination)
end


local function OnCanvasClick(mapCanvas, button, cursorX, cursorY)
    if button == "LeftButton" and IsControlKeyDown() then
        if not WorldMapUtil.IsPathfindingEnabled() then return false end

        local mapID = mapCanvas:GetMapID()
        local x, y = mapCanvas:GetNormalizedCursorPosition()
        if not mapID or x == nil or y == nil then return false end

        return MapPin.NewTemporaryWaypoint({
            mapID                    = mapID,
            x                        = x,
            y                        = y,
            coordinatesAreNormalized = true,
            superTracked             = true,
            syncNativeWaypoint       = true
        }) ~= nil
    end

    return false
end

WorldMapFrame:AddCanvasClickHandler(OnCanvasClick, 100)
