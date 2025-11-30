local env                       = select(2, ...)
local Config                    = env.Config

local IsSuperTrackingAnything   = C_SuperTrack.IsSuperTrackingAnything
local IsInInstance              = IsInInstance
local CreateFrame               = CreateFrame
local ipairs                    = ipairs

local SavedVariables            = env.WPM:Import("wpm_modules/saved-variables")
local CallbackRegistry          = env.WPM:Import("wpm_modules/callback-registry")
local WaypointCache             = env.WPM:Import("@/Waypoint/Cache")
local WaypointDataProvider      = env.WPM:Import("@/Waypoint/DataProvider")
local WaypointEnum              = env.WPM:Import("@/Waypoint/Enum")
local WaypointDirector          = env.WPM:New("@/Waypoint/Director")

WaypointDirector.isActive       = false
WaypointDirector.navigationMode = WaypointEnum.NavigationMode.Hidden -- Enum.NavigationMode.Waypoint | Enum.NavigationMode.Pinpoint | Enum.NavigationMode.Navigator



-- Event Listener
--------------------------------

--[[
    Callback Events:
        Waypoint.SlowUpdate
        Waypoint.SecondUpdate

        Waypoint.ContextUpdate
        Waypoint.SuperTrackingChanged
        Waypoint.ActiveChanged
        Waypoint.NavigationModeChanged
        Waypoint.DistanceReady
]]

local Events = CreateFrame("Frame")

do
    local EVENTS_TO_REGISTER = {
        "QUEST_POI_UPDATE",
        "QUEST_LOG_UPDATE",
        "ZONE_CHANGED_NEW_AREA",
        "ZONE_CHANGED",
        "QUEST_ACCEPTED",
        "QUEST_COMPLETE",
        "QUEST_DETAIL",
        "QUEST_FINISHED",
        "SUPER_TRACKING_CHANGED",
        "SUPER_TRACKING_PATH_UPDATED",
        "PLAYER_STARTED_MOVING",
        "PLAYER_STOPPED_MOVING",
        "PLAYER_IS_GLIDING_CHANGED"
    }
    local isMoving = false



    -- Timers
    --------------------------------

    local slowUpdateTimer = nil
    local clampUpdateTimer = nil
    local secondUpdateTimer = nil


    local function onSlowUpdate()
        WaypointDataProvider:AttemptToAcquireNavFrame()
        WaypointDataProvider:CacheState()

        if not isMoving then
            if WaypointCache:Get("state") ~= WaypointEnum.State.InvalidRange then
                WaypointDataProvider:CacheRealtime()
            end
        end

        CallbackRegistry:Trigger("Waypoint.SlowUpdate")
    end

    local function onSecondUpdate()
        CallbackRegistry:Trigger("Waypoint.SecondUpdate")
    end

    local function startTimers()
        if slowUpdateTimer then slowUpdateTimer:Cancel() end
        if secondUpdateTimer then secondUpdateTimer:Cancel() end

        slowUpdateTimer = C_Timer.NewTicker(.1, onSlowUpdate)
        secondUpdateTimer = C_Timer.NewTicker(1, onSecondUpdate)

        onSlowUpdate()
        onSecondUpdate()
    end

    local function stopTimers()
        if slowUpdateTimer then slowUpdateTimer:Cancel() end
        if clampUpdateTimer then clampUpdateTimer:Cancel() end
        if secondUpdateTimer then secondUpdateTimer:Cancel() end
    end



    -- When Moving Updater
    --------------------------------

    local moveUpdater = CreateFrame("Frame")
    moveUpdater:SetScript("OnUpdate", function()
        WaypointDataProvider:CacheRealtime()
    end)

    function moveUpdater:Enable()
        isMoving = true
        self:Show()
    end

    function moveUpdater:Disable()
        isMoving = false
        self:Hide()
    end

    moveUpdater:Disable()




    -- Event Handlers
    --------------------------------

    local function onPlayerMove(isMoveStart)
        if isMoveStart then
            moveUpdater:Enable()
            CallbackRegistry:Trigger("Waypoint.PlayerStartedMoving")
        else
            moveUpdater:Disable()
            CallbackRegistry:Trigger("Waypoint.PlayerStoppedMoving")
        end
    end

    local function onContextChange()
        WaypointDataProvider:AttemptToAcquireNavFrame()
        WaypointDataProvider:CacheRealtime()
        WaypointDataProvider:CacheSuperTrackingInfo()
        WaypointDataProvider:CacheQuestInfo()
        WaypointDataProvider:CacheTrackingType()
        WaypointDataProvider:CacheState()

        CallbackRegistry:Trigger("Waypoint.ContextUpdate")
    end

    local function onSuperTrackingChange()
        CallbackRegistry:Trigger("Waypoint.SuperTrackingChanged")
        WaypointDirector:AwaitDistance()
    end

    CallbackRegistry:Add("MapPin.NewUserNavigation", onSuperTrackingChange)




    -- Distance Await
    --------------------------------

    local distanceAwait = CreateFrame("Frame")
    distanceAwait:Hide()
    distanceAwait.runtimeDelay = .075 -- Wait before checking for distance. C_Navigation.GetDistance doesn't update immediately after `SUPER_TRACKING_CHANGED`
    distanceAwait.timeoutDelay = 3
    distanceAwait.timeWhenShown = nil

    distanceAwait:SetScript("OnShow", function(self)
        self.timeWhenShown = GetTime()
    end)

    distanceAwait:SetScript("OnUpdate", function(self)
        if not WaypointDirector.isActive then return end
        if GetTime() - self.timeWhenShown < self.runtimeDelay then return end
        if GetTime() - self.timeWhenShown > self.timeoutDelay then
            distanceAwait:Hide()
            return
        end

        -- Check if distance information is available
        local distance = C_Navigation.GetDistance()
        if distance == nil or distance <= 0 then return end

        -- Refresh cache information
        onContextChange()

        distanceAwait:Hide()
        CallbackRegistry:Trigger("Waypoint.DistanceReady")

    end)

    CallbackRegistry:Add("Waypoint.DistanceReady", onContextChange)
    CallbackRegistry:Add("WaypointDataProvider.NavFrameObtained", function()
        if not distanceAwait:IsShown() then
            distanceAwait:Show()
        end
    end)


    function WaypointDirector:AwaitDistance()
        self.timeWhenShown = GetTime()
        distanceAwait:Show()
    end

    function WaypointDirector:CancelDistanceAwait()
        distanceAwait:Hide()
    end





    -- Hook Events
    --------------------------------

    local function onEvent(self, event, ...)
        -- Context
        if event == "QUEST_POI_UPDATE" or
            event == "QUEST_LOG_UPDATE" or
            event == "ZONE_CHANGED_NEW_AREA" or
            event == "ZONE_CHANGED" or
            event == "QUEST_ACCEPTED" or
            event == "QUEST_COMPLETE" or
            event == "QUEST_DETAIL" or
            event == "QUEST_FINISHED" then
            -- event == "SUPER_TRACKING_PATH_UPDATED" -- temporarily disabled
            WaypointDirector:AwaitDistance()



            -- Move
        elseif event == "PLAYER_STARTED_MOVING" or
            (event == "PLAYER_IS_GLIDING_CHANGED" and ... == true) then
            onPlayerMove(true)
        elseif event == "PLAYER_STOPPED_MOVING" or
            (event == "PLAYER_IS_GLIDING_CHANGED" and ... == false) then
            onPlayerMove(false)
        end


        -- Super Tracking
        if event == "SUPER_TRACKING_CHANGED" then
            onSuperTrackingChange()
        end
    end

    Events:SetScript("OnEvent", onEvent)





    -- Enable/Disable
    --------------------------------

    function Events:Enable()
        for _, event in ipairs(EVENTS_TO_REGISTER) do
            Events:RegisterEvent(event)
        end

        startTimers()
        WaypointDirector:AwaitDistance()
    end

    function Events:Disable()
        Events:UnregisterAllEvents()
        moveUpdater:Hide()

        stopTimers()
    end





    -- Navigation Mode
    --------------------------------

    local lastNavigationMode = nil
    local valueChecklistBeforeUpdating = { hasDistanceInfo = false, hasClampInfo = false }


    local function reset()
        WaypointDirector.navigationMode = WaypointEnum.NavigationMode.Hidden
        lastNavigationMode = WaypointEnum.NavigationMode.Hidden
        WaypointDirector:HideAllFrames()

        valueChecklistBeforeUpdating.hasDistanceInfo = false
        valueChecklistBeforeUpdating.hasClampInfo = false

        WaypointCache:Clear()
        -- WaypointDirector:CancelDistanceAwait()
    end

    CallbackRegistry:Add("Waypoint.SuperTrackingChanged", reset)
    CallbackRegistry:Add("Waypoint.ActiveChanged", reset)


    local function isValueChecklistFulfilled()
        local hasDistanceInfo = valueChecklistBeforeUpdating.hasDistanceInfo
        local hasClampInfo = valueChecklistBeforeUpdating.hasClampInfo

        return hasDistanceInfo and hasClampInfo
    end

    local function resolveNavigationMode()
        local Setting_WaypointType = Config.DBGlobal:GetVariable("WaypointSystemType")

        local state = WaypointCache:Get("state")
        local isClamped = WaypointCache:Get("clamped")

        if state == WaypointEnum.State.Invalid or state == WaypointEnum.State.InvalidRange then
            return WaypointEnum.NavigationMode.Hidden
        elseif isClamped then
            return WaypointEnum.NavigationMode.Navigator
        elseif state == WaypointEnum.State.Proximity or state == WaypointEnum.State.QuestProximity then
            if Setting_WaypointType == WaypointEnum.WaypointSystemType.Pinpoint or Setting_WaypointType == WaypointEnum.WaypointSystemType.All then
                return WaypointEnum.NavigationMode.Pinpoint
            else
                return WaypointEnum.NavigationMode.Waypoint
            end
        else
            if Setting_WaypointType == WaypointEnum.WaypointSystemType.Waypoint or Setting_WaypointType == WaypointEnum.WaypointSystemType.All then
                return WaypointEnum.NavigationMode.Waypoint
            else
                return WaypointEnum.NavigationMode.Pinpoint
            end
        end
    end

    local function hasNavigationModeChanged(mode)
        local hasChanged = mode ~= lastNavigationMode
        local isHidden = mode == WaypointEnum.NavigationMode.Hidden -- Force update when mode is hidden as without this, visibility issues sometimes occur while changing super track target inside quest blob

        return hasChanged or isHidden
    end

    local function triggerAppropriateTransitionCallback(mode)
        if lastNavigationMode == WaypointEnum.NavigationMode.Waypoint and mode == WaypointEnum.NavigationMode.Pinpoint then
            -- Waypoint > Pinpoint
            CallbackRegistry:Trigger("WaypointAnimation.WaypointToPinpoint")
        elseif lastNavigationMode == WaypointEnum.NavigationMode.Pinpoint and mode == WaypointEnum.NavigationMode.Waypoint then
            -- Pinpoint > Waypoint

            CallbackRegistry:Trigger("WaypointAnimation.PinpointToWaypoint")
        elseif lastNavigationMode == WaypointEnum.NavigationMode.Hidden and mode ~= WaypointEnum.NavigationMode.Hidden then
            -- Hidden > (Waypoint/Pinpoint/Navigator)
            CallbackRegistry:Trigger("WaypointAnimation.New")
        end
    end

    local function updateNavigationMode()
        if not isValueChecklistFulfilled() then return end
        local mode = resolveNavigationMode()

        if hasNavigationModeChanged(mode) then
            triggerAppropriateTransitionCallback(mode)
            WaypointDirector:SetNavigationMode(mode)

            lastNavigationMode = mode
        end
    end

    CallbackRegistry:Add("WaypointDataProvider.StateChanged", function()
        if not WaypointDirector.isActive then return end
        updateNavigationMode()
    end)

    CallbackRegistry:Add("WaypointDataProvider.ClampChanged", function()
        if not WaypointDirector.isActive then return end
        valueChecklistBeforeUpdating.hasClampInfo = true
        updateNavigationMode()
    end)

    CallbackRegistry:Add("Waypoint.DistanceReady", function()
        if not WaypointDirector.isActive then return end
        valueChecklistBeforeUpdating.hasDistanceInfo = true
        updateNavigationMode()
    end)

    SavedVariables.OnChange("WaypointDB_Global", "WaypointSystemType", updateNavigationMode)
    SavedVariables.OnChange("WaypointDB_Global", "DistanceThresholdHidden", updateNavigationMode)
end



-- Enable/Disable
--------------------------------

local INSTANCE_ALLOW_LIST = {
    [2352] = true, -- Founder's Point
    [2351] = true -- Razorwind Shores
}

local function shouldSetActive()
    local mapID                      = C_Map.GetBestMapForUnit("player")
    local force                      = false
    local isInInstance, instanceType = IsInInstance()

    if mapID and INSTANCE_ALLOW_LIST[mapID] then
        force = true
    end

    local shouldShow = IsSuperTrackingAnything() and (force or (not isInInstance and instanceType == "none"))
    return shouldShow
end

function WaypointDirector:UpdateActive()
    local active = shouldSetActive()

    if active ~= WaypointDirector.isActive then
        WaypointDirector.isActive = active
        if active then
            Events:Enable()
        else
            Events:Disable()
            WaypointDirector:SetNavigationMode(WaypointEnum.NavigationMode.Hidden)
        end

        CallbackRegistry:Trigger("Waypoint.ActiveChanged", active)
    end
end



-- Navigation Mode
--------------------------------

function WaypointDirector:GetNavigationMode()
    return WaypointDirector.navigationMode
end

function WaypointDirector:SetNavigationMode(mode)
    WaypointDirector.navigationMode = mode
    CallbackRegistry:Trigger("Waypoint.NavigationModeChanged", mode)
end

function WaypointDirector:HideAllFrames()
    CallbackRegistry:Trigger("Waypoint.HideAllFrames")
end




-- Setup
--------------------------------

local function OnAddonLoad()
    WaypointDirector:UpdateActive()
    WaypointDirector:AwaitDistance()

    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(self, event, ...)
        WaypointDirector:UpdateActive()
    end)
    f:RegisterEvent("SUPER_TRACKING_CHANGED")
    f:RegisterEvent("ZONE_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
end

CallbackRegistry:Add("Preload.AddonReady", OnAddonLoad)
