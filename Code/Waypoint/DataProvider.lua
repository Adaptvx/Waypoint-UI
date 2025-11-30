local env                                 = select(2, ...)
local Config                              = env.Config

local GetQuestLogCompletionText           = GetQuestLogCompletionText
local GetBestMapForUnit                   = C_Map.GetBestMapForUnit
local GetNavigationFrame                  = C_Navigation.GetFrame
local GetDistance                         = C_Navigation.GetDistance
local IsSuperTrackingAnything             = C_SuperTrack.IsSuperTrackingAnything
local GetHighestPrioritySuperTrackingType = C_SuperTrack.GetHighestPrioritySuperTrackingType
local GetSuperTrackedQuestID              = C_SuperTrack.GetSuperTrackedQuestID
local GetSuperTrackedMapPin               = C_SuperTrack.GetSuperTrackedMapPin
local GetSuperTrackedContent              = C_SuperTrack.GetSuperTrackedContent
local GetQuestClassification              = C_QuestInfoSystem.GetQuestClassification
local IsComplete                          = C_QuestLog.IsComplete
local GetQuestObjectives                  = C_QuestLog.GetQuestObjectives
local GetQuestInfoByQuestID               = C_TaskQuest.GetQuestInfoByQuestID
local GetAreaPOIInfo                      = C_AreaPoiInfo.GetAreaPOIInfo
local GetSuperTrackedItemName             = C_SuperTrack.GetSuperTrackedItemName
local GetNextWaypointForMap               = C_SuperTrack.GetNextWaypointForMap
local GetTitleForQuestID                  = C_QuestLog.GetTitleForQuestID
local IsInsideQuestBlob                   = C_Minimap.IsInsideQuestBlob

local Path                                = env.WPM:Import("wpm_modules/path")
local MapPin                              = env.WPM:Import("@/MapPin")
local LocalUtil                           = env.WPM:Import("@/LocalUtil")
local CallbackRegistry                    = env.WPM:Import("wpm_modules/callback-registry")
local WaypointContextIcon                 = env.WPM:Import("@/Waypoint/ContextIcon")
local WaypointDefine                      = env.WPM:Import("@/Waypoint/Define")
local WaypointEnum                        = env.WPM:Import("@/Waypoint/Enum")
local WaypointCache                       = env.WPM:Import("@/Waypoint/Cache")
local WaypointDataProvider                = env.WPM:New("@/Waypoint/DataProvider")





-- Helpers
--------------------------------

local CLAMP_THRESHOLD = .125

local function getCompletionText(questID)
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if not questLogIndex then return nil end

    C_QuestLog.SetSelectedQuest(questID)
    local questCompletionText = GetQuestLogCompletionText()

    return questCompletionText
end

local function getObjectiveInfo(objectives)
    --[[
        https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetQuestObjectives
        Blizzard objective table:
            [1] = {
                text:string	                        The text displayed in the quest log and the quest tracker
                type:string	                        "monster", "item", etc.
                finished:boolean	                true if the objective has been completed
                numFulfilled:number	                number of partial objectives fulfilled
                numRequired:number	                number of partial objectives required
                objectiveType:QuestObjectiveType?
            }
    ]]

    if not objectives then return nil end

    local obj = WaypointDefine.ObjectiveInfo{ objectives = objectives }
    obj.isMultiObjective = (#objectives > 1)

    return obj
end

local function getTrackingType()
    local trackingType = nil
    local questID      = WaypointCache:Get("questID")
    local pinType      = WaypointCache:Get("pinType")

    if questID then
        local questClassification = GetQuestClassification(questID)
        local questComplete = IsComplete(questID)

        if questComplete then
            if questClassification == Enum.QuestClassification.Recurring then
                trackingType = WaypointEnum.TrackingType.QuestCompleteRecurring
            elseif questClassification == Enum.QuestClassification.Important then
                trackingType = WaypointEnum.TrackingType.QuestCompleteImportant
            else
                trackingType = WaypointEnum.TrackingType.QuestComplete
            end
        else
            trackingType = WaypointEnum.TrackingType.QuestIncomplete
        end
    else
        if pinType == Enum.SuperTrackingType.Corpse then
            trackingType = WaypointEnum.TrackingType.Corpse
        else
            trackingType = WaypointEnum.TrackingType.Other
        end
    end

    return trackingType
end

local function getRedirectInfo()
    local mapID = GetBestMapForUnit("player")

    if mapID then
        local waypointX, waypointY, waypointText = GetNextWaypointForMap(mapID)
        return WaypointDefine.RedirectInfo{ valid = (waypointText ~= nil), x = waypointX, y = waypointY, text = waypointText }
    else
        return WaypointDefine.RedirectInfo{ valid = false, x = nil, y = nil, text = nil }
    end
end

local function getState()
    local Setting_DistanceThresholdPinpoint = Config.DBGlobal:GetVariable("DistanceThresholdPinpoint")
    local Setting_DistanceThresholdHidden   = Config.DBGlobal:GetVariable("DistanceThresholdHidden")
    local Setting_PinpointAllowInQuestArea  = Config.DBGlobal:GetVariable("PinpointAllowInQuestArea")
    



    local state              = nil
    local distance           = WaypointCache:Get("distance") or 9999
    local isInAreaPOI        = (WaypointCache:Get("questID") and IsInsideQuestBlob(WaypointCache:Get("questID")))
    local isQuest            = WaypointCache:Get("questID")
    local isValid            = WaypointCache:Get("valid")
    local isQuestTypeDefault = (WaypointCache:Get("icon") == "3308452")
    local isRangeProximity   = (distance < Setting_DistanceThresholdPinpoint)
    local isRangeValid       = (distance > Setting_DistanceThresholdHidden)




    if (isInAreaPOI and not Setting_PinpointAllowInQuestArea) or not isRangeValid or not isValid then
        if isInAreaPOI then
            state = WaypointEnum.State.InvalidRange
        elseif not isRangeValid then
            state = WaypointEnum.State.InvalidRange
        else
            state = WaypointEnum.State.Invalid
        end
    elseif isRangeProximity then
        state = (isQuest and isQuestTypeDefault) and WaypointEnum.State.QuestProximity or WaypointEnum.State.Proximity
    else
        state = (isQuest and isQuestTypeDefault) and WaypointEnum.State.QuestArea or WaypointEnum.State.Area
    end



    return state, state ~= WaypointCache:Get("state")
end

local function isClamped()
    local navFrame = WaypointCache:Get("navFrame")
    if not navFrame then return end


    local resultMinDistance = LocalUtil:GetFrameDistanceFromScreenEdge(navFrame)
    local clamped = (resultMinDistance < CLAMP_THRESHOLD)
    local clampChanged = WaypointCache:Get("clamped") ~= clamped

    
    return clamped, clampChanged
end

do -- Context Icon
    local PATH_CONTEXT_ICON = Path.Root .. "/Art/ContextIcon/"
    local RedirectContextIcon = WaypointDefine.ContextIconTexture{ type = "TEXTURE", path = PATH_CONTEXT_ICON .. "Redirect.png", requestRecolor = true }

    function WaypointDataProvider:GetContextIconTextureForQuest(questID)
        local inlineIcon, texturePath = WaypointContextIcon:GetContextIcon(questID)
        return texturePath and WaypointDefine.ContextIconTexture{ type = "TEXTURE", path = texturePath } or nil
    end

    function WaypointDataProvider:GetContextIconTextureForOtherPinType()
        local contextIconTexture = WaypointDefine.ContextIconTexture{}
        local pinType = WaypointCache:Get("pinType")
        local poiType = WaypointCache:Get("poiType")
        local poiInfo = WaypointCache:Get("poiInfo")
        local isUserNavigation = MapPin.IsUserNavigation()

        if not pinType then return nil end

        -- Corpse
        if pinType == Enum.SuperTrackingType.Corpse then
            contextIconTexture.type = "ATLAS"
            contextIconTexture.path = "poi-torghast"

            -- Taxi
        elseif poiType == Enum.SuperTrackingMapPinType.TaxiNode then
            contextIconTexture.type = "ATLAS"
            contextIconTexture.path = "Crosshair_Taxi_128"

            -- POI
        elseif poiInfo and poiInfo.atlasName then
            contextIconTexture.type = "ATLAS"
            contextIconTexture.path = poiInfo.atlasName

            -- User Navigation
        elseif isUserNavigation then
            contextIconTexture.type = "TEXTURE"
            contextIconTexture.path = PATH_CONTEXT_ICON .. "Navigation.png"
            contextIconTexture.requestRecolor = true

            -- User Waypoint
        elseif pinType == Enum.SuperTrackingType.UserWaypoint then
            contextIconTexture.type = "TEXTURE"
            contextIconTexture.path = PATH_CONTEXT_ICON .. "MapPin.png"
            contextIconTexture.requestRecolor = true

            -- Dig Site
        elseif poiType == Enum.SuperTrackingMapPinType.DigSite then
            contextIconTexture.type = "ATLAS"
            contextIconTexture.path = "ArchBlob"

            -- Quest Offer
        elseif poiType == Enum.SuperTrackingMapPinType.QuestOffer then
            contextIconTexture.type = "TEXTURE"
            contextIconTexture.path = PATH_CONTEXT_ICON .. "QuestAvailable.png"

            -- Default
        else
            contextIconTexture.type = "TEXTURE"
            contextIconTexture.path = PATH_CONTEXT_ICON .. "MapPin.png"
            contextIconTexture.requestRecolor = true
        end

        return contextIconTexture
    end

    function WaypointDataProvider:GetContextIconTextureForRedirect()
        return RedirectContextIcon
    end
end




-- Cache
--------------------------------

function WaypointDataProvider:AttemptToAcquireNavFrame()
    local navFrame = GetNavigationFrame()
    local currentNavFrame = WaypointCache:Get("navFrame")

    if navFrame ~= nil and navFrame ~= currentNavFrame then
        WaypointCache:Set("navFrame", navFrame)
        CallbackRegistry:Trigger("WaypointDataProvider.NavFrameObtained")
    end
end

function WaypointDataProvider:CacheSuperTrackingInfo()
    local valid                      = IsSuperTrackingAnything()
    local pinType                    = GetHighestPrioritySuperTrackingType()
    local icon                       = tostring(SuperTrackedFrame.Icon:GetTexture())
    local trackableType, trackableID = GetSuperTrackedContent() -- Appearance / Mount / Achievement
    local poiType, poiID             = GetSuperTrackedMapPin()  -- AreaPOI / Quest Offer/ TaxiNode / DigSite
    local poiInfo                    = poiID and GetAreaPOIInfo(nil, poiID)
    local pinName, pinDescription    = GetSuperTrackedItemName()
    local redirectInfo               = getRedirectInfo()
    local redirectContextIcon        = WaypointDataProvider:GetContextIconTextureForRedirect()

    local isUserNavigation           = MapPin.IsUserNavigation()
    if isUserNavigation then
        local userNavigationInfo = MapPin.GetUserNavigation()
        local x = string.format("X: %.1f", userNavigationInfo.x * 100)
        local y = string.format("Y: %.1f", userNavigationInfo.y * 100)

        pinName = userNavigationInfo.name
        pinDescription = x .. ", " .. y
    end



    WaypointCache:Set("valid", valid)
    WaypointCache:Set("pinType", pinType)
    WaypointCache:Set("icon", icon)
    WaypointCache:Set("trackableType", trackableType)
    WaypointCache:Set("trackableID", trackableID)
    WaypointCache:Set("poiType", poiType)
    WaypointCache:Set("poiID", poiID)
    WaypointCache:Set("poiInfo", poiInfo)
    WaypointCache:Set("pinName", pinName)
    WaypointCache:Set("pinDescription", pinDescription)
    WaypointCache:Set("redirectInfo", redirectInfo)
    WaypointCache:Set("redirectContextIcon", redirectContextIcon)

    local pinContextIcon = WaypointDataProvider:GetContextIconTextureForOtherPinType() -- Requires cached info
    WaypointCache:Set("pinContextIcon", pinContextIcon)



    CallbackRegistry:Trigger("WaypointDataProvider.CacheSuperTrackingInfo")
end

function WaypointDataProvider:CacheQuestInfo()
    local questID             = GetSuperTrackedQuestID()
    local questClassification = questID and GetQuestClassification(questID)
    local questComplete       = questID and IsComplete(questID)
    local questIsWorldQuest   = questID and (GetQuestInfoByQuestID(questID) ~= nil)
    local questObjectiveInfo  = questID and getObjectiveInfo(GetQuestObjectives(questID)) or nil
    local questName           = questID and GetTitleForQuestID(questID)
    local questContextIcon    = questID and WaypointDataProvider:GetContextIconTextureForQuest(questID)
    local questCompletionText = questID and getCompletionText(questID) or nil



    WaypointCache:Set("questID", questID)
    WaypointCache:Set("questClassification", questClassification)
    WaypointCache:Set("questContextIcon", questContextIcon)
    WaypointCache:Set("questComplete", questComplete)
    WaypointCache:Set("questIsWorldQuest", questIsWorldQuest)
    WaypointCache:Set("questObjectiveInfo", questObjectiveInfo)
    WaypointCache:Set("questContextIcon", questContextIcon)
    WaypointCache:Set("questName", questName)
    WaypointCache:Set("questCompletionText", questCompletionText)



    CallbackRegistry:Trigger("WaypointDataProvider.CacheQuestInfo")
end

-- Must be called after CacheQuestInfo, CacheSuperTrackingInfo.
function WaypointDataProvider:CacheTrackingType()
    local trackingType = getTrackingType() -- WaypointEnum.TrackingType
    WaypointCache:Set("trackingType", trackingType)
end

function WaypointDataProvider:CacheState()
    local state, stateChanged = getState()
    WaypointCache:Set("state", state)

    if stateChanged then CallbackRegistry:Trigger("WaypointDataProvider.StateChanged") end
    CallbackRegistry:Trigger("WaypointDataProvider.CacheState")
end

function WaypointDataProvider:CacheRealtime()
    local clamped, clampChanged = isClamped()
    local distance = GetDistance()
    WaypointCache:Set("distance", distance)
    WaypointCache:Set("clamped", clamped)

    if clampChanged then CallbackRegistry:Trigger("WaypointDataProvider.ClampChanged") end
    CallbackRegistry:Trigger("WaypointDataProvider.CacheRealtime")
end
