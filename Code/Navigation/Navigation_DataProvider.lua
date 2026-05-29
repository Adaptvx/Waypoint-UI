local env = select(2, ...)
local L = env.L
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local Waypoint_Director = env.modules:Import("@\\Waypoint\\Director")
local Navigation_FarstriderLib = env.modules:Import("@\\Navigation\\FarstriderLib")
local Navigation_Mapzeroth = env.modules:Import("@\\Navigation\\Mapzeroth")
local Navigation_WorldMap = env.modules:Import("@\\Navigation\\WorldMap")
local Navigation_Shared = env.modules:Import("@\\Navigation\\Shared")
local Navigation_Preload = env.modules:Await("@\\Navigation\\Preload")
local MapPin = env.modules:Import("@\\MapPin")
local Navigation_DataProvider = env.modules:New("@\\Navigation\\DataProvider")

local ClearAllSuperTracked = C_SuperTrack.ClearAllSuperTracked
local IsSuperTrackingAnything = C_SuperTrack.IsSuperTrackingAnything
local IsSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint
local GetNextWaypointForMap = C_SuperTrack.GetNextWaypointForMap
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetTime = GetTime
local CreateFrame = CreateFrame
local ipairs = ipairs
local wipe = wipe


local PATH_RECALC_INTERVAL = 5
local PATH_RECALC_MOVEMENT_THRESHOLD = 10
local SUPER_TRACKING_SUPPRESSION_DELAY = 0.15
local PATH_STEP_TRANSITION_DELAY = 0.15


local DataProviderUtil = {}
do
    function DataProviderUtil.NormalizePathClearOptions(options)
        if type(options) == "table" then return options end

        local shouldPreserve = options == true
        return {
            preserveOverlay           = shouldPreserve,
            preserveNativeDestination = shouldPreserve
        }
    end

    function DataProviderUtil.ResetPathSession()
        wipe(Navigation_DataProvider.SessionData.Path)
    end

    function DataProviderUtil.PrepareOverlayStepDisplay()
        Navigation_DataProvider:SuppressNativeWaypointSuperTrackingChanged()
        Navigation_DataProvider:ClearPathStepWaypoints(true)
        if IsSuperTrackingAnything() then ClearAllSuperTracked() end
        Navigation_WorldMap:ForceHighlightDestinationPin(Navigation_DataProvider:HasPath())
    end

    function DataProviderUtil.HandleTrackedDestinationUpdate()
        local hasNewDestination = IsSuperTrackingAnything()

        if Navigation_DataProvider:HasPath() then
            if not hasNewDestination and Navigation_DataProvider:IsCurrentPathStepHandledByOverlay() then
                Navigation_DataProvider:EnsurePathRecalculationTicker()
                Navigation_DataProvider:ApplyMapHandling()
                Navigation_DataProvider:UpdateOverlay()
                return true
            end

            local destinationChanged = Navigation_DataProvider:HasDestinationChanged()
            if not hasNewDestination or destinationChanged then
                Navigation_DataProvider:ClearPathStepWaypoints(true)

                DataProviderUtil.OnDestinationCleared({ preserveNativeDestination = hasNewDestination })

                if hasNewDestination then
                    local hasNewPath = DataProviderUtil.OnDestinationSet()
                    if hasNewPath == false then
                        Navigation_DataProvider:UpdateOverlay()
                    end
                end
                return true
            end
            return false
        end

        if hasNewDestination then
            DataProviderUtil.OnDestinationSet()
            return true
        end
        return false
    end

    function DataProviderUtil.GetSuperTrackedUserNavigationDestination()
        local userNavigation = MapPin.GetUserNavigation()
        if not userNavigation or userNavigation.superTracked ~= true then return nil end

        return Navigation_WorldMap:GetUserWaypointDestinationState()
    end

    function DataProviderUtil.ActivateCurrentDestination()
        if IsSuperTrackingAnything() then return DataProviderUtil.HandleTrackedDestinationUpdate() end

        local destination = DataProviderUtil.GetSuperTrackedUserNavigationDestination()
        if destination then
            DataProviderUtil.OnDestinationSet(destination)
            return true
        end

        return false
    end

    function DataProviderUtil.ShouldIgnoreNativeWaypointSuperTrackingChanged()
        if Navigation_DataProvider.IgnoreNativeWaypointSuperTrackingChanged ~= true then return false end
        if Navigation_DataProvider:HasPath() then return false end

        local metadata = Navigation_WorldMap:GetSuperTrackedMetadata()
        if metadata and metadata.pinType and metadata.pinType ~= Navigation_Preload.Enum.SuperTrackedPinType.UserWaypoint then
            Navigation_DataProvider.IgnoreNativeWaypointSuperTrackingChanged = false
            return false
        end

        return true
    end

    function DataProviderUtil.HandleOverlayUserWaypointUpdate(destinationSnapshot)
        if not Navigation_DataProvider:HasPath() then return false end
        if not Navigation_DataProvider:IsCurrentPathStepHandledByOverlay() then return false end
        if not Navigation_WorldMap:IsUserWaypointSnapshot(destinationSnapshot) then return false end
        local destination = Navigation_WorldMap:GetLiveUserWaypointDestinationState(destinationSnapshot)
        if not destination then return false end

        if Navigation_WorldMap:DoesTrackedDestinationMatchSnapshot(destinationSnapshot, destination) then
            Navigation_DataProvider:EnsurePathRecalculationTicker()
            Navigation_DataProvider:ApplyMapHandling()
            Navigation_DataProvider:UpdateOverlay()
            return true
        end

        DataProviderUtil.OnDestinationCleared({
            preserveOverlay           = true,
            preserveNativeDestination = true
        })

        local hasNewPath = DataProviderUtil.OnDestinationSet(destination)
        if hasNewPath == false then Navigation_DataProvider:UpdateOverlay() end

        return true
    end

    function DataProviderUtil.SyncUserNavigationSuperTracking(destination)
        local userNavigation = MapPin.GetUserNavigation()
        if not userNavigation then return end

        local shouldSuperTrackUserNavigation = Navigation_WorldMap:IsUserWaypointSnapshot(destination) and destination.userNavigation ~= nil
        MapPin.SetUserNavigationSuperTracked(shouldSuperTrackUserNavigation, false)
    end

    function DataProviderUtil.OnDestinationSet(destination)
        if not Navigation_DataProvider:IsEnabled() then
            Navigation_DataProvider:ClearSessionData()
            return false
        end

        if Navigation_DataProvider:HasPath() then
            Navigation_DataProvider:ClearPathStepWaypoints(true)
        end

        if destination then
            Navigation_WorldMap:CaptureDestinationPinSnapshot(Navigation_DataProvider, destination)

            CallbackRegistry.Trigger("Navigation_DataProvider.CaptureDestinationPinSnapshot")
        elseif Navigation_DataProvider:CaptureDestinationPinSnapshot() ~= true then
            Navigation_DataProvider:ClearSessionData()
            return false
        end

        DataProviderUtil.SyncUserNavigationSuperTracking(Navigation_DataProvider:GetDestinationPinSnapshot())

        Navigation_DataProvider:StartPathfinding()

        CallbackRegistry.Trigger("Navigation_DataProvider.OnDestinationSet")

        return Navigation_DataProvider:HasPath()
    end

    function DataProviderUtil.OnDestinationCleared(options)
        Navigation_DataProvider:ClearSessionData(options)

        CallbackRegistry.Trigger("Navigation_DataProvider.OnDestinationCleared")
    end

    function DataProviderUtil.OnUserWaypointSet(_, _, options)
        if not Navigation_DataProvider:IsEnabled() then return end
        if options and options.suppressPathfinding == true then return end

        local destination = Navigation_WorldMap:GetUserWaypointDestinationState()
        if not destination then return end

        DataProviderUtil.OnDestinationSet(destination)
    end

    function DataProviderUtil.OnUserWaypointRemoved(_, _, _, suppressDestinationClear)
        if suppressDestinationClear == true then return end

        local destinationSnapshot = Navigation_DataProvider:GetDestinationPinSnapshot()
        if not Navigation_WorldMap:IsUserWaypointSnapshot(destinationSnapshot) or not destinationSnapshot.userNavigation then return end

        DataProviderUtil.OnDestinationCleared()
    end
end


Navigation_DataProvider.PathProviders = {
    [env.Enum.PathProvider.None]          = {
        name = L["NONE"]
    },
    [env.Enum.PathProvider.FarstriderLib] = {
        name        = L["FARSTRIDERLIB"],
        addonName   = "FarstriderLib",
        PathBuilder = Navigation_FarstriderLib.PathBuilder,
        IsAvailable = Navigation_FarstriderLib.IsAvailable
    },
    [env.Enum.PathProvider.Mapzeroth]     = {
        name        = L["MAPZEROTH"],
        addonName   = "Mapzeroth",
        PathBuilder = Navigation_Mapzeroth.PathBuilder,
        IsAvailable = Navigation_Mapzeroth.IsAvailable
    }
}
Navigation_DataProvider.PathProviderOrder = {
    env.Enum.PathProvider.None,
    env.Enum.PathProvider.FarstriderLib,
    env.Enum.PathProvider.Mapzeroth
}
Navigation_DataProvider.AvailablePathProviderIDs = nil
Navigation_DataProvider.AvailablePathProviderNames = nil
Navigation_DataProvider.SessionData = {
    Path = {
        currentStep            = nil,
        waypointStep           = nil,
        pathData               = nil,
        lastPlayerMapID        = nil,
        lastRecalculationTime  = nil,
        lastRecalculationMapID = nil,
        lastRecalculationX     = nil,
        lastRecalculationY     = nil
    }
}
Navigation_DataProvider.PathRecalculationTicker = nil
Navigation_DataProvider.SuperTrackingSuppressTimer = LazyTimer.New()
Navigation_DataProvider.SuperTrackingSuppressTimer:SetAction(function() Navigation_DataProvider.IgnoreNativeWaypointSuperTrackingChanged = false end)
Navigation_DataProvider.PathStepValidationTimer = LazyTimer.New()
Navigation_DataProvider.PathStepValidationTimer:SetAction(function() Navigation_DataProvider:ValidatePathStepArrival() end)
Navigation_DataProvider.MapApplyTimer = LazyTimer.New()
Navigation_DataProvider.MapApplyTimer:SetAction(function()
    if Navigation_DataProvider:HasPath() and not Navigation_DataProvider:IsLastStep() then
        Navigation_WorldMap:ForceHighlightDestinationPin(Navigation_DataProvider:HasPath())
        Navigation_WorldMap:ForceHideSuperTrackWaypoint()
    end
end)


function Navigation_DataProvider:InvalidateAvailablePathProviderCache()
    self.AvailablePathProviderIDs = nil
    self.AvailablePathProviderNames = nil
end

function Navigation_DataProvider:GetPathProvider(provider)
    return self.PathProviders[provider]
end

function Navigation_DataProvider:GetPathProviderName(provider)
    local pathProvider = self.PathProviders[provider]
    return pathProvider and pathProvider.name or L["NONE"]
end

function Navigation_DataProvider:IsPathProviderAvailable(provider, requireRuntimeAvailability)
    local shouldRequireRuntimeAvailability = requireRuntimeAvailability ~= false

    if provider == env.Enum.PathProvider.None then return true end

    local pathProvider = self:GetPathProvider(provider)
    if not pathProvider or not pathProvider.PathBuilder then return false end

    if pathProvider.addonName and IsAddOnLoaded(pathProvider.addonName) == false then
        if shouldRequireRuntimeAvailability then
            if Navigation_Shared.IsPathProviderAddonEnabled(pathProvider.addonName) == false then
                return false
            end

            if Navigation_Shared.EnsurePathProviderAddonLoaded(pathProvider.addonName) == false then
                return false
            end
        else
            return Navigation_Shared.IsPathProviderAddonEnabled(pathProvider.addonName)
        end
    end

    if shouldRequireRuntimeAvailability and pathProvider.IsAvailable then
        return pathProvider.IsAvailable() == true
    end

    return true
end

function Navigation_DataProvider:BuildAvailablePathProviderCache()
    if self.AvailablePathProviderIDs and self.AvailablePathProviderNames then return end

    local availablePathProviderIDs = {}
    local availablePathProviderNames = {}

    for _, provider in ipairs(self.PathProviderOrder) do
        if self:IsPathProviderAvailable(provider, false) then
            availablePathProviderIDs[#availablePathProviderIDs + 1] = provider
            availablePathProviderNames[#availablePathProviderNames + 1] = self:GetPathProviderName(provider)
        end
    end

    self.AvailablePathProviderIDs = availablePathProviderIDs
    self.AvailablePathProviderNames = availablePathProviderNames
end

function Navigation_DataProvider:GetAvailablePathProviderIDs()
    self:BuildAvailablePathProviderCache()
    return self.AvailablePathProviderIDs
end

function Navigation_DataProvider:GetAvailablePathProviderNames()
    self:BuildAvailablePathProviderCache()
    return self.AvailablePathProviderNames
end

function Navigation_DataProvider:GetAvailablePathProviderID(index)
    self:BuildAvailablePathProviderCache()
    return self.AvailablePathProviderIDs[index] or env.Enum.PathProvider.None
end

function Navigation_DataProvider:GetAvailablePathProviderVisibleIndex(provider)
    self:BuildAvailablePathProviderCache()

    for index, providerID in ipairs(self.AvailablePathProviderIDs) do
        if providerID == provider then
            return index
        end
    end

    return 1
end

function Navigation_DataProvider:IsEnabled()
    return self:HasPathBuilder() and Config.DBGlobal:GetVariable("PathfindingEnabled") == true
end

function Navigation_DataProvider:GetPathBuilder(provider)
    local providerID = provider or Config.DBGlobal:GetVariable("PathfindingProvider")
    local pathProvider = self:GetPathProvider(providerID)
    if not pathProvider or self:IsPathProviderAvailable(providerID) == false then return nil end
    return pathProvider.PathBuilder
end

function Navigation_DataProvider:HasPathBuilder(provider)
    return self:GetPathBuilder(provider) ~= nil
end

function Navigation_DataProvider:HasPath()
    return Navigation_DataProvider.SessionData.Path.pathData ~= nil
end

function Navigation_DataProvider:SuppressNativeWaypointSuperTrackingChanged()
    self.IgnoreNativeWaypointSuperTrackingChanged = true
    Navigation_DataProvider.SuperTrackingSuppressTimer:Stop()
    Navigation_DataProvider.SuperTrackingSuppressTimer.elapsed = 0
    Navigation_DataProvider.SuperTrackingSuppressTimer:Start(SUPER_TRACKING_SUPPRESSION_DELAY)
end

function Navigation_DataProvider:SuppressSuperTrackingChanged()
    self:SuppressNativeWaypointSuperTrackingChanged()
end

function Navigation_DataProvider:GetCurrentPathStep()
    local currentStep = Navigation_DataProvider.SessionData.Path.currentStep
    local pathData = Navigation_DataProvider.SessionData.Path.pathData
    if not currentStep or not pathData or not pathData.steps then return nil end
    return pathData.steps[currentStep]
end

function Navigation_DataProvider:ShouldShowOverlay(step)
    return step and step.method and step.method ~= Navigation_Preload.Enum.NavigationMethod.Direct
end

function Navigation_DataProvider:GetPathStepItemID(step)
    if not step or step.method ~= Navigation_Preload.Enum.NavigationMethod.Item or not step.metadata then return nil end
    return tonumber(step.metadata.itemID)
end

function Navigation_DataProvider:UpdateOverlay()
    local step = self:GetCurrentPathStep()
    local destinationPinSnapshot = self:GetDestinationPinSnapshot()
    if not self:ShouldShowOverlay(step) or not destinationPinSnapshot or not destinationPinSnapshot.name then
        WUINavigationOverlayFrame:FadeOut()
        return
    end

    WUINavigationOverlayFrame:ShowStep(step, destinationPinSnapshot)
end

function Navigation_DataProvider:BuildPathToDestination()
    local destinationPinSnapshot = self:GetDestinationPinSnapshot()
    local pathBuilder = self:GetPathBuilder()
    if not pathBuilder or not destinationPinSnapshot or not destinationPinSnapshot.mapID or not destinationPinSnapshot.normalizedX or not destinationPinSnapshot.normalizedY then return nil end

    return pathBuilder(destinationPinSnapshot.mapID, destinationPinSnapshot.normalizedX, destinationPinSnapshot.normalizedY)
end

function Navigation_DataProvider:StartPathRecalculationTicker()
    if Navigation_DataProvider.PathRecalculationTicker then
        Navigation_DataProvider.PathRecalculationTicker:Cancel()
    end

    Navigation_DataProvider.PathRecalculationTicker = C_Timer.NewTicker(PATH_RECALC_INTERVAL, function() Navigation_DataProvider:RecalculatePathIfNeeded() end)
end

function Navigation_DataProvider:EnsurePathRecalculationTicker()
    if not self:IsEnabled() then return self:StopPathRecalculationTicker() end
    if Navigation_DataProvider.PathRecalculationTicker or not self:HasPath() then return end

    self:StartPathRecalculationTicker()
end

function Navigation_DataProvider:StopPathRecalculationTicker()
    if not Navigation_DataProvider.PathRecalculationTicker then return end
    Navigation_DataProvider.PathRecalculationTicker:Cancel()
    Navigation_DataProvider.PathRecalculationTicker = nil
end

function Navigation_DataProvider:UpdatePathRecalculationState(playerMapID, playerX, playerY)
    Navigation_DataProvider.SessionData.Path.lastRecalculationTime = GetTime()
    Navigation_DataProvider.SessionData.Path.lastRecalculationMapID = playerMapID
    Navigation_DataProvider.SessionData.Path.lastRecalculationX = playerX
    Navigation_DataProvider.SessionData.Path.lastRecalculationY = playerY
end

function Navigation_DataProvider:AdvancePathToPlayerPosition(previousPlayerMapID, playerMapID, playerX, playerY)
    local pathData = Navigation_DataProvider.SessionData.Path.pathData
    if not pathData or not pathData.steps or not Navigation_DataProvider.SessionData.Path.currentStep then return end

    while Navigation_DataProvider.SessionData.Path.currentStep < #pathData.steps do
        local step = pathData.steps[Navigation_DataProvider.SessionData.Path.currentStep]
        if not Navigation_Shared.ShouldAdvancePathStep(step, previousPlayerMapID, playerMapID, playerX, playerY) then break end

        Navigation_DataProvider.SessionData.Path.currentStep = Navigation_DataProvider.SessionData.Path.currentStep + 1
        previousPlayerMapID = playerMapID
    end
end

function Navigation_DataProvider:SetPath(path, playerMapID, playerX, playerY, preserveMatchingActiveStep)
    local previousActiveStep = self:GetCurrentPathStep()
    local previousActiveStepIsLast = self:IsLastStep() == true
    local previousActiveStepCanBePreserved = self:IsCurrentPathStepHandledByOverlay() or self:IsSuperTrackingPathStepWaypoint() or (previousActiveStepIsLast and Navigation_Shared.IsDirectPathStep(previousActiveStep))
    local previousPlayerMapID = Navigation_DataProvider.SessionData.Path.lastPlayerMapID

    Navigation_DataProvider.SessionData.Path.currentStep = 1
    Navigation_DataProvider.SessionData.Path.pathData = path
    Navigation_DataProvider.SessionData.Path.lastPlayerMapID = playerMapID
    self:UpdatePathRecalculationState(playerMapID, playerX, playerY)

    if preserveMatchingActiveStep == true then
        self:AdvancePathToPlayerPosition(previousPlayerMapID, playerMapID, playerX, playerY)
    end

    local activeStep = self:GetCurrentPathStep()
    local activeStepIsLast = self:IsLastStep() == true
    local shouldPreserveActiveStep = preserveMatchingActiveStep == true
        and previousActiveStepCanBePreserved
        and previousActiveStepIsLast == activeStepIsLast
        and Navigation_Shared.ArePathStepsEquivalent(previousActiveStep, activeStep)

    if shouldPreserveActiveStep then
        Navigation_DataProvider.SessionData.Path.waypointStep = Navigation_DataProvider.SessionData.Path.currentStep
        self:UpdateOverlay()
    else
        Navigation_DataProvider.SessionData.Path.waypointStep = nil
        self:UpdatePathStepWaypoint()
    end

    self:ApplyMapHandling()
end

function Navigation_DataProvider:StartPathfinding()
    if not self:IsEnabled() or self.blockPathfinding == true then
        self:ClearSessionData()
        return
    end

    local path = self:BuildPathToDestination()
    if not path then
        self:ClearSessionData()
        return
    end

    local playerX, playerY, playerMapID = Navigation_Shared.GetPlayerPathPosition()
    self:SetPath(path, playerMapID, playerX, playerY)
    if not self:HasPath() then return end

    self:StartPathRecalculationTicker()

    CallbackRegistry.Trigger("Navigation_DataProvider.StartPathfinding", Navigation_DataProvider.SessionData.Path)
end

function Navigation_DataProvider:StopPathfinding(options)
    options = DataProviderUtil.NormalizePathClearOptions(options)
    local hadPath = self:HasPath()

    Navigation_DataProvider.PathStepValidationTimer:Stop()
    self:StopPathRecalculationTicker()
    if Navigation_DataProvider.MapApplyTimer then
        Navigation_DataProvider.MapApplyTimer:Stop()
    end
    DataProviderUtil.ResetPathSession()
    self:ClearPathStepWaypoints(options.preserveNativeDestination)
    if options.preserveOverlay ~= true then
        self:UpdateOverlay()
    end

    if hadPath then
        CallbackRegistry.Trigger("Navigation_DataProvider.StopPathfinding", options)
    end
end

function Navigation_DataProvider:IsLastStep()
    if self:HasPath() == false then return end
    local pathData = Navigation_DataProvider.SessionData.Path.pathData
    if not pathData or not pathData.steps then return end

    return Navigation_DataProvider.SessionData.Path.currentStep == #pathData.steps
end

function Navigation_DataProvider:UpdatePathStepWaypoint()
    local currentStep = Navigation_DataProvider.SessionData.Path.currentStep
    if not currentStep or currentStep == Navigation_DataProvider.SessionData.Path.waypointStep then return end

    local step = self:GetCurrentPathStep()
    if not step then
        self:UpdateOverlay()
        return
    end

    if self:IsLastStep() and Navigation_Shared.IsDirectPathStep(step) then
        Navigation_WorldMap:SuperTrackDestination(self)
        self:StopPathfinding()
        return
    end

    Navigation_DataProvider.SessionData.Path.waypointStep = currentStep
    if not Navigation_Shared.IsDirectPathStep(step) then
        DataProviderUtil.PrepareOverlayStepDisplay()
        self:UpdateOverlay()
        return
    end

    Navigation_WorldMap.SetPathStepWaypoint(step)
    self:UpdateOverlay()
end

function Navigation_DataProvider:ClearPathStepWaypoints(preserveNativeDestination)
    Navigation_WorldMap.ClearPathStepWaypoint(preserveNativeDestination)
end

function Navigation_DataProvider:ValidatePathStepArrival()
    if not self:IsEnabled() then
        self:ClearSessionData()
        return
    end
    if not self:HasPath() then return end

    local pathData = Navigation_DataProvider.SessionData.Path.pathData
    if not pathData or not pathData.steps or not Navigation_DataProvider.SessionData.Path.currentStep then return end

    local step = pathData.steps[Navigation_DataProvider.SessionData.Path.currentStep]
    if not step then return end

    local playerX, playerY, playerMapID = Navigation_Shared.GetPlayerPathPosition()
    if not playerMapID then return end

    local previousPlayerMapID = Navigation_DataProvider.SessionData.Path.lastPlayerMapID

    if Navigation_Shared.ShouldAdvancePathStep(step, previousPlayerMapID, playerMapID, playerX, playerY) then
        Navigation_DataProvider.SessionData.Path.lastPlayerMapID = playerMapID
        if Navigation_DataProvider.SessionData.Path.currentStep < #pathData.steps then
            Navigation_DataProvider.SessionData.Path.currentStep = Navigation_DataProvider.SessionData.Path.currentStep + 1
            self:UpdatePathStepWaypoint()
        elseif not Navigation_Shared.IsDirectPathStep(step) then
            Navigation_WorldMap:SuperTrackDestination(self)
            self:StopPathfinding()
        end

        return
    end

    if step.advanceOnMapChange ~= true or previousPlayerMapID == playerMapID then
        Navigation_DataProvider.SessionData.Path.lastPlayerMapID = playerMapID
    end
end

function Navigation_DataProvider:UpdateIgnoreState()
    if not self:IsEnabled() then
        Waypoint_Director.IgnoreSuperTrackedTarget(false)
        return
    end

    local mapID = GetBestMapForUnit("player")
    if not mapID then return end

    Waypoint_Director.IgnoreSuperTrackedTarget(GetNextWaypointForMap(mapID) ~= nil and self:HasPath() and not self:IsLastStep())
end

function Navigation_DataProvider:CaptureDestinationPinSnapshot()
    local captured = Navigation_WorldMap:CaptureDestinationPinSnapshot(self)
    if captured ~= true then return false end

    CallbackRegistry.Trigger("Navigation_DataProvider.CaptureDestinationPinSnapshot")
    return true
end

function Navigation_DataProvider:GetDestinationPinSnapshot()
    return Navigation_WorldMap:GetDestinationPinSnapshot()
end

function Navigation_DataProvider:ClearDestinationPinSnapshot()
    Navigation_WorldMap:ClearDestinationPinSnapshot()

    CallbackRegistry.Trigger("Navigation_DataProvider.ClearDestinationPinSnapshot")
end

function Navigation_DataProvider:ClearSessionData(options)
    options = DataProviderUtil.NormalizePathClearOptions(options)

    self:ClearDestinationPinSnapshot()
    self:StopPathfinding(options)

    CallbackRegistry.Trigger("Navigation_DataProvider.ClearSessionData", options)
end

function Navigation_DataProvider:AbortPathfindingFromPathStepWaypoint()
    Navigation_WorldMap:AbortPathfindingFromDestinationPin(Navigation_DataProvider)
end

function Navigation_DataProvider:SetUserWaypointDestination()
    if not self:IsEnabled() then return false end

    local destination = Navigation_WorldMap:GetUserWaypointDestinationState()
    if not destination then return false end

    return DataProviderUtil.OnDestinationSet(destination)
end

function Navigation_DataProvider:ApplyMapHandling()
    if not Navigation_DataProvider:IsEnabled() then
        if Navigation_DataProvider.MapApplyTimer then Navigation_DataProvider.MapApplyTimer:Stop() end
        return
    end
    Navigation_DataProvider.MapApplyTimer:Start(0)
end

function Navigation_DataProvider:HasDestinationChanged()
    return Navigation_WorldMap:HasDestinationChanged()
end

function Navigation_DataProvider:IsSuperTrackingPathStepWaypoint()
    return Navigation_WorldMap:IsSuperTrackingPathStepWaypoint()
end

function Navigation_DataProvider:IsCurrentPathStepHandledByOverlay()
    return self:ShouldShowOverlay(self:GetCurrentPathStep()) == true
end

function Navigation_DataProvider:RecalculatePathIfNeeded()
    if not self:HasPath() or not self:IsEnabled() then return end

    local lastRecalculationTime = Navigation_DataProvider.SessionData.Path.lastRecalculationTime
    local now = GetTime()
    if lastRecalculationTime and (now - lastRecalculationTime) < PATH_RECALC_INTERVAL then return end

    local playerX, playerY, playerMapID = Navigation_Shared.GetPlayerPathPosition()
    if not playerMapID then return end

    local lastMapID = Navigation_DataProvider.SessionData.Path.lastRecalculationMapID
    local lastX = Navigation_DataProvider.SessionData.Path.lastRecalculationX
    local lastY = Navigation_DataProvider.SessionData.Path.lastRecalculationY

    if playerX and playerY and (lastMapID == nil or (lastMapID == playerMapID and (not lastX or not lastY))) then
        self:UpdatePathRecalculationState(playerMapID, playerX, playerY)
        lastMapID = playerMapID
        lastX = playerX
        lastY = playerY
    end

    local shouldRecalculate = self:IsCurrentPathStepHandledByOverlay()
    if not shouldRecalculate then
        shouldRecalculate = lastMapID ~= playerMapID
        if not shouldRecalculate and playerX and playerY and lastX and lastY then
            local movedDistance = Navigation_Shared.GetStepDistance(playerMapID, playerX, playerY, playerMapID, lastX, lastY)
            shouldRecalculate = movedDistance and movedDistance >= PATH_RECALC_MOVEMENT_THRESHOLD
        end
    end

    if not shouldRecalculate then return end

    local path = self:BuildPathToDestination()
    if not path then return end

    self:SetPath(path, playerMapID, playerX, playerY, true)
end

function Navigation_DataProvider:QueuePathStepValidation()
    if not self:IsEnabled() then return Navigation_DataProvider.PathStepValidationTimer:Stop() end
    if not self:HasPath() then return end

    Navigation_DataProvider.PathStepValidationTimer:Start(PATH_STEP_TRANSITION_DELAY)
end


local EL = CreateFrame("Frame")
EL:RegisterEvent("SUPER_TRACKING_CHANGED")
EL:RegisterEvent("USER_WAYPOINT_UPDATED")
EL:RegisterEvent("NAVIGATION_DESTINATION_REACHED")
EL:RegisterEvent("ADDONS_UNLOADING")
EL:RegisterEvent("ADDON_LOADED")
EL:RegisterEvent("PLAYER_ENTERING_WORLD")
EL:RegisterEvent("ZONE_CHANGED")
EL:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EL:SetScript("OnEvent", function(self, event, ...)
    if event ~= "ADDONS_UNLOADING" and event ~= "ADDON_LOADED" and not Navigation_DataProvider:IsEnabled() then
        Navigation_DataProvider:ClearSessionData()
        return
    end

    if event == "NAVIGATION_DESTINATION_REACHED" then
        if Navigation_DataProvider:HasPath() then
            Navigation_WorldMap:SuperTrackDestination(Navigation_DataProvider)
        end
    end

    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "FarstriderLib" or addonName == "Mapzeroth" then
            Navigation_DataProvider:InvalidateAvailablePathProviderCache()
        end
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        Navigation_DataProvider:QueuePathStepValidation()
    end

    if event == "SUPER_TRACKING_CHANGED" then
        if DataProviderUtil.ShouldIgnoreNativeWaypointSuperTrackingChanged() then
            Navigation_DataProvider:ApplyMapHandling()
            return
        end

        DataProviderUtil.HandleTrackedDestinationUpdate()
    elseif event == "USER_WAYPOINT_UPDATED" then
        local destinationSnapshot = Navigation_DataProvider:GetDestinationPinSnapshot()

        if DataProviderUtil.HandleOverlayUserWaypointUpdate(destinationSnapshot) then
            return
        end

        if IsSuperTrackingUserWaypoint() or Navigation_WorldMap:IsUserWaypointSnapshot(destinationSnapshot) then
            DataProviderUtil.HandleTrackedDestinationUpdate()
        end
    elseif event == "ADDONS_UNLOADING" then
        Navigation_WorldMap:UntrackDestination()
        Navigation_DataProvider:ClearSessionData()
    end
end)

WorldMapFrame:RegisterCallback("WorldQuestsUpdate", Navigation_DataProvider.ApplyMapHandling)
EventRegistry:RegisterCallback("MapCanvas.MapSet", Navigation_DataProvider.ApplyMapHandling)
EventRegistry:RegisterCallback("WorldMapOnShow", Navigation_DataProvider.ApplyMapHandling)
EventRegistry:RegisterCallback("SuperTracking.OnChange", Navigation_DataProvider.ApplyMapHandling)
CallbackRegistry.Add("Waypoint.SlowUpdate", function()
    if not Navigation_DataProvider:IsEnabled() then return end
    Navigation_DataProvider:UpdateIgnoreState()
    Navigation_DataProvider:ValidatePathStepArrival()
end)
CallbackRegistry.Add("MapPin.NewTemporaryWaypoint", DataProviderUtil.OnUserWaypointSet)
CallbackRegistry.Add("MapPin.NewUserNavigation", DataProviderUtil.OnUserWaypointSet)
CallbackRegistry.Add("MapPin.UserNavigationCleared", DataProviderUtil.OnUserWaypointRemoved)


local function OnEnableChanged(enabled)
    if enabled then
        EL:Show()
        if Navigation_DataProvider:IsEnabled() then
            DataProviderUtil.ActivateCurrentDestination()
        end
    else
        EL:Hide()
        Navigation_DataProvider:ClearSessionData()
    end
end

local function OnPathProviderChanged(provider)
    if Navigation_DataProvider:HasPath() then
        Navigation_DataProvider:StopPathfinding()
        if provider ~= env.Enum.PathProvider.None then
            Navigation_DataProvider:StartPathfinding()
        end
        return
    end

    if provider ~= env.Enum.PathProvider.None and Navigation_DataProvider:IsEnabled() then
        DataProviderUtil.ActivateCurrentDestination()
    end
end

SavedVariables.OnChange("WaypointDB_Global", "PathfindingEnabled", OnEnableChanged)
SavedVariables.OnChange("WaypointDB_Global", "PathfindingProvider", OnPathProviderChanged)
