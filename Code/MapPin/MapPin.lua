local env = select(2, ...)
local Config = env.Config
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local Navigation_DataProvider = env.modules:Await("@\\Navigation\\DataProvider")
local MapPin = env.modules:New("@\\MapPin")
local HBD = LibStub("HereBeDragons-2.0")

local SetSuperTrackedUserWaypoint = C_SuperTrack.SetSuperTrackedUserWaypoint
local IsSuperTrackingAnything = C_SuperTrack.IsSuperTrackingAnything
local ClearAllSuperTracked = C_SuperTrack.ClearAllSuperTracked
local GetHighestPrioritySuperTrackingType = C_SuperTrack.GetHighestPrioritySuperTrackingType
local IsSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint
local CanSetUserWaypointOnMap = C_Map.CanSetUserWaypointOnMap
local GetUserWaypoint = C_Map.GetUserWaypoint
local SetUserWaypoint = C_Map.SetUserWaypoint
local ClearUserWaypoint = C_Map.ClearUserWaypoint
local HasUserWaypoint = C_Map.HasUserWaypoint
local GetWorldPosFromMapPos = C_Map.GetWorldPosFromMapPos
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetMapInfo = C_Map.GetMapInfo
local CreateFrame = CreateFrame
local CreateVector2D = CreateVector2D
local tostring = tostring
local tonumber = tonumber
local type = type
local pairs = pairs
local abs = math.abs
local format = string.format



local MapPinUtil = {}
do
    MapPinUtil.USER_WAYPOINT_TOLERANCE = 0.0005
    MapPinUtil.USER_NAVIGATION_VALIDATION_DELAY = 0.15

    MapPinUtil.SessionData = {
        userNavigation   = nil,
        pathStepWaypoint = nil,
        pins             = nil,
        pinSequence      = 0
    }
    MapPinUtil.PendingUserNavigationValidation = {
        mapID       = nil,
        x           = nil,
        y           = nil,
        sourcePinID = nil
    }
    MapPinUtil.SuppressNextUserNavigationClear = false

    MapPinUtil.UserNavigationValidationTimer = LazyTimer.New()
    MapPinUtil.UserNavigationValidationTimer:SetAction(function()
        MapPinUtil.ClearPendingUserNavigationValidation()
        MapPinUtil.ValidateUserNavigationState(false)
    end)

    local LocaleUsesDecimalPoint = tonumber("1.1") ~= nil
    local InvalidDecimalPattern = "(%d)" .. (LocaleUsesDecimalPoint and "," or ".") .. "(%d)"
    local ValidDecimalReplacement = "%1" .. (LocaleUsesDecimalPoint and "." or ",") .. "%2"
    local ParseTokens = {}
    local ParseCommands = {}
    local WayCommandPattern = "/way%s+"


    function MapPinUtil.NormalizePinData(pinData)
        if not pinData then return nil end

        if type(pinData.x) == "number" and pinData.x > 1 and pinData.x <= 100 then pinData.x = pinData.x / 100 end
        if type(pinData.y) == "number" and pinData.y > 1 and pinData.y <= 100 then pinData.y = pinData.y / 100 end
        if pinData.iconType == nil and pinData.iconTexture then pinData.iconType = "TEXTURE" end
        if pinData.fromWUI == nil then pinData.fromWUI = true end

        return pinData
    end

    function MapPinUtil.NormalizeSessionData(sessionData)
        sessionData = sessionData or MapPinUtil.SessionData
        sessionData.pinSequence = sessionData.pinSequence or 0
        sessionData.userNavigation = MapPinUtil.NormalizePinData(sessionData.userNavigation)
        sessionData.pathStepWaypoint = MapPinUtil.NormalizePinData(sessionData.pathStepWaypoint)

        if not sessionData.userNavigation and sessionData.temporaryWaypoint then
            sessionData.userNavigation = MapPinUtil.NormalizePinData(sessionData.temporaryWaypoint)
        end
        sessionData.temporaryWaypoint = nil

        if sessionData.pins then
            local maxSequence = sessionData.pinSequence

            for _, pinInfo in pairs(sessionData.pins) do
                MapPinUtil.NormalizePinData(pinInfo)

                if pinInfo.sequence and pinInfo.sequence > maxSequence then
                    maxSequence = pinInfo.sequence
                end
            end

            for _, pinInfo in pairs(sessionData.pins) do
                if not pinInfo.sequence or pinInfo.sequence <= 0 then
                    maxSequence = maxSequence + 1
                    pinInfo.sequence = maxSequence
                end
            end

            sessionData.pinSequence = maxSequence
        end

        return sessionData
    end

    function MapPinUtil.SaveSessionData()
        MapPinUtil.NormalizeSessionData(MapPinUtil.SessionData)
        Config.DBLocal:SetVariable("mapPinSessionData", MapPinUtil.SessionData)
    end

    function MapPinUtil.GetSessionData()
        local savedSessionData = Config.DBLocal:GetVariable("mapPinSessionData")

        if savedSessionData then
            MapPinUtil.SessionData = MapPinUtil.NormalizeSessionData(savedSessionData)
        else
            MapPinUtil.SessionData = MapPinUtil.NormalizeSessionData(MapPinUtil.SessionData)
        end

        return MapPinUtil.SessionData
    end

    function MapPinUtil.GetNextPinSequence()
        local sessionData = MapPinUtil.GetSessionData()
        sessionData.pinSequence = (sessionData.pinSequence or 0) + 1
        return sessionData.pinSequence
    end

    function MapPinUtil.GeneratePinID()
        local nextSequence = (MapPinUtil.GetSessionData().pinSequence or 0) + 1
        return format("%d", nextSequence)
    end

    function MapPinUtil.CreatePinData(options)
        return {
            name             = options.name,
            mapID            = options.mapID,
            x                = options.x,
            y                = options.y,
            fromWUI          = options.fromWUI,
            flags            = options.flags,
            iconTexture      = options.iconTexture,
            r                = options.r,
            g                = options.g,
            b                = options.b,
            requestRecolor   = options.requestRecolor,
            iconType         = options.iconType,
            sourcePinID      = options.sourcePinID,
            sequence         = options.sequence,
            stripCoordinates = options.stripCoordinates,
            superTracked     = options.superTracked,
            pathStepWaypoint = options.pathStepWaypoint
        }
    end

    function MapPinUtil.MergePinOptions(target, source)
        target = target or {}
        source = source or {}

        local optionKeys = {
            "name",
            "mapID",
            "x",
            "y",
            "fromWUI",
            "flags",
            "iconTexture",
            "r",
            "g",
            "b",
            "requestRecolor",
            "iconType",
            "sourcePinID",
            "sequence",
            "stripCoordinates",
            "superTracked",
            "pathStepWaypoint",
            "id",
            "suppressAudio",
            "suppressPathfinding",
            "syncNativeWaypoint",
            "coordinatesAreNormalized"
        }

        for _, key in ipairs(optionKeys) do
            local value = source[key]
            if value ~= nil then
                target[key] = value
            end
        end

        return target
    end

    function MapPinUtil.CreateVisualPinOptions(options)
        return {
            flags            = options.flags,
            iconTexture      = options.iconTexture,
            r                = options.r,
            g                = options.g,
            b                = options.b,
            requestRecolor   = options.requestRecolor,
            iconType         = options.iconType,
            stripCoordinates = options.stripCoordinates
        }
    end

    function MapPinUtil.TokenizeWayCommand(inputMessage)
        wipe(ParseTokens)

        if type(inputMessage) ~= "string" then
            return ParseTokens
        end

        inputMessage = inputMessage:gsub("^%s*/way%s*", "")
        inputMessage = inputMessage:gsub("(%d)[%.,] (%d)", "%1 %2")
        inputMessage = inputMessage:gsub(InvalidDecimalPattern, ValidDecimalReplacement)
        inputMessage:gsub("%S+", function(token)
            ParseTokens[#ParseTokens + 1] = token
        end)

        return ParseTokens
    end

    function MapPinUtil.ExtractWayCommands(inputMessage)
        wipe(ParseCommands)

        if type(inputMessage) ~= "string" then
            return ParseCommands
        end

        local lowerMessage = inputMessage:lower()
        local commandStart = lowerMessage:find(WayCommandPattern)

        if not commandStart then
            if inputMessage:match("%S") then
                ParseCommands[#ParseCommands + 1] = inputMessage
            end

            return ParseCommands
        end

        while commandStart do
            local nextCommandStart = lowerMessage:find(WayCommandPattern, commandStart + 1)
            local commandText = nextCommandStart and inputMessage:sub(commandStart, nextCommandStart - 1) or inputMessage:sub(commandStart)

            if commandText:match("%S") then
                ParseCommands[#ParseCommands + 1] = commandText
            end

            commandStart = nextCommandStart
        end

        return ParseCommands
    end

    function MapPinUtil.CreateFallbackPinChoice(fallbackID, fallbackPin, pinID, pinInfo)
        if fallbackPin == nil then
            return pinID, pinInfo
        end

        local fallbackSequence = fallbackPin.sequence or math.huge
        local pinSequence = pinInfo.sequence or math.huge
        if pinSequence < fallbackSequence then
            return pinID, pinInfo
        end

        return fallbackID, fallbackPin
    end

    function MapPinUtil.PlayUserNavigationAudio()
        local soundID = env.Enum.Sound.NewUserNavigation

        if Config.DBGlobal:GetVariable("AudioCustom") then
            if tonumber(soundID) then
                soundID = Config.DBGlobal:GetVariable("AudioCustomNewUserNavigation")
            end
        end

        Sound.PlaySound("Main", soundID)
    end

    function MapPinUtil.ResolveMapPosition(mapID, x, y)
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
                        return parentMapID, parentNormalizedX, parentNormalizedY
                    end
                end
            end
            return
        end

        return mapID, x, y
    end

    function MapPinUtil.CreateMapPoint(mapID, x, y)
        local pos = CreateVector2D(x / 100, y / 100)
        local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)
        return pos, mapPoint
    end

    function MapPinUtil.CreateResolvedMapPoint(mapID, x, y)
        if not mapID or not x or not y then return end

        mapID, x, y = MapPinUtil.ResolveMapPosition(mapID, x, y)
        if not mapID or not CanSetUserWaypointOnMap(mapID) then return end

        local pos, mapPoint = MapPinUtil.CreateMapPoint(mapID, x, y)
        return mapID, pos, mapPoint
    end

    function MapPinUtil.DoesWaypointMatch(mapID, x, y, expectedMapID, expectedX, expectedY)
        if mapID == nil or x == nil or y == nil then return false end
        if expectedMapID == nil or expectedX == nil or expectedY == nil then return false end

        return tostring(mapID) == tostring(expectedMapID) and abs(x - expectedX) < MapPinUtil.USER_WAYPOINT_TOLERANCE and abs(y - expectedY) < MapPinUtil.USER_WAYPOINT_TOLERANCE
    end

    function MapPinUtil.GetCurrentWaypointState()
        if not HasUserWaypoint() then return nil end

        local waypoint = GetUserWaypoint()
        if not waypoint or not waypoint.position then return nil end

        return waypoint, waypoint.uiMapID, waypoint.position.x, waypoint.position.y
    end

    function MapPinUtil.IsCurrentWaypoint(mapID, x, y)
        local _, currentMapID, currentX, currentY = MapPinUtil.GetCurrentWaypointState()
        return MapPinUtil.DoesWaypointMatch(currentMapID, currentX, currentY, mapID, x, y)
    end

    function MapPinUtil.ClearPendingUserNavigationValidation()
        MapPinUtil.PendingUserNavigationValidation.mapID = nil
        MapPinUtil.PendingUserNavigationValidation.x = nil
        MapPinUtil.PendingUserNavigationValidation.y = nil
        MapPinUtil.PendingUserNavigationValidation.sourcePinID = nil
        MapPinUtil.UserNavigationValidationTimer:Stop()
    end

    function MapPinUtil.SchedulePendingUserNavigationValidation()
        if MapPinUtil.PendingUserNavigationValidation.mapID == nil then return false end

        MapPinUtil.UserNavigationValidationTimer:Stop()
        MapPinUtil.UserNavigationValidationTimer:Start(MapPinUtil.USER_NAVIGATION_VALIDATION_DELAY)

        return true
    end

    function MapPinUtil.SetPendingUserNavigationValidation(userNavigation)
        if not userNavigation or userNavigation.mapID == nil or userNavigation.x == nil or userNavigation.y == nil then
            MapPinUtil.ClearPendingUserNavigationValidation()
            return
        end

        MapPinUtil.PendingUserNavigationValidation.mapID = userNavigation.mapID
        MapPinUtil.PendingUserNavigationValidation.x = userNavigation.x
        MapPinUtil.PendingUserNavigationValidation.y = userNavigation.y
        MapPinUtil.PendingUserNavigationValidation.sourcePinID = userNavigation.sourcePinID

        MapPinUtil.SchedulePendingUserNavigationValidation()
    end

    function MapPinUtil.NormalizeWaypointInput(x, y, coordinatesAreNormalized)
        if coordinatesAreNormalized == true and abs(x) <= 1 and abs(y) <= 1 then return x * 100, y * 100 end
        return x, y
    end

    function MapPinUtil.IsPathfindingEnabled()
        if not Config.DBGlobal or Config.DBGlobal:GetVariable("PathfindingEnabled") ~= true then return false end
        return Navigation_DataProvider:IsEnabled() == true
    end

    function MapPinUtil.ShouldSyncNativeWaypoint(options, defaultSyncWhenPathfindingInactive)
        if options.syncNativeWaypoint ~= nil then return options.syncNativeWaypoint == true end
        return defaultSyncWhenPathfindingInactive ~= false and not MapPinUtil.IsPathfindingEnabled()
    end

    function MapPinUtil.SetNativeUserWaypoint(mapPoint, superTracked)
        if not mapPoint then return false end

        CallbackRegistry.Trigger("Map.AutoTrackPlacedPin.SuppressNextUpdate")
        SetUserWaypoint(mapPoint)
        SetSuperTrackedUserWaypoint(superTracked == true)
        return true
    end

    function MapPinUtil.ClearNativeUserWaypoint(preserveUserNavigation)
        CallbackRegistry.Trigger("Map.AutoTrackPlacedPin.SuppressNextUpdate")
        if IsSuperTrackingUserWaypoint() then
            SetSuperTrackedUserWaypoint(false)
        end
        if HasUserWaypoint() then
            if preserveUserNavigation == true then
                MapPinUtil.SuppressNextUserNavigationClear = true
            end
            ClearUserWaypoint()
        end
    end

    function MapPinUtil.IsCurrentPinWaypoint(pinInfo)
        if not pinInfo then return false end
        return MapPinUtil.IsCurrentWaypoint(pinInfo.mapID, pinInfo.x, pinInfo.y)
    end

    function MapPinUtil.SetPathStepWaypoint(options)
        if not options.mapID or not options.x or not options.y then return end

        local sessionData = MapPinUtil.GetSessionData()
        sessionData.pathStepWaypoint = MapPinUtil.CreatePinData(MapPinUtil.MergePinOptions({
            name             = options.name or MapPin.GeneratePinName(options.mapID),
            mapID            = options.mapID,
            x                = options.x,
            y                = options.y,
            fromWUI          = options.fromWUI ~= false,
            pathStepWaypoint = true,
            superTracked     = options.superTracked == true
        }, MapPinUtil.CreateVisualPinOptions(options)))
        MapPinUtil.SaveSessionData()

        CallbackRegistry.Trigger("MapPin.PathStepWaypointChanged", sessionData.pathStepWaypoint)
        return sessionData.pathStepWaypoint
    end

    function MapPinUtil.ValidateTrackedUserWaypoint(allowDelay)
        if MapPin.IsUserNavigationTracked() then return end
        if allowDelay and MapPinUtil.SchedulePendingUserNavigationValidation() then return end

        MapPinUtil.ClearPendingUserNavigationValidation()
        MapPin.ClearUserNavigation(true)
    end

    function MapPinUtil.ValidateUserNavigationState(allowDelay)
        if MapPinUtil.IsPathfindingEnabled() then return end

        local trackType = GetHighestPrioritySuperTrackingType()
        if trackType == Enum.SuperTrackingType.UserWaypoint then
            MapPinUtil.ValidateTrackedUserWaypoint(allowDelay)
        elseif trackType ~= Enum.SuperTrackingType.UserWaypoint and not HasUserWaypoint() then
            MapPinUtil.ClearPendingUserNavigationValidation()
            MapPin.ClearUserNavigation(true)
        end
    end

    function MapPinUtil.IsMapPinEnhancedLoaded()
        return IsAddOnLoaded("MapPinEnhanced")
    end

    function MapPinUtil.IsCustomMapPinsEnabledInSettings()
        if not Config.DBGlobal then return true end
        return Config.DBGlobal:GetVariable("CustomMapPinsEnabled")
    end
end


function MapPin.GeneratePinName(mapID)
    if not mapID then return end

    local mapInfo = GetMapInfo(mapID)
    if mapInfo then return mapInfo.name end

    return MAP_PIN
end

function MapPin.IsMultiPinEnabled()
    return MapPinUtil.IsCustomMapPinsEnabledInSettings() and not MapPinUtil.IsMapPinEnhancedLoaded()
end

function MapPin.IsCustomMapPinsEnabled()
    return MapPinUtil.IsCustomMapPinsEnabledInSettings() and not MapPinUtil.IsMapPinEnhancedLoaded()
end

function MapPin.ClearDestination()
    if MapPin.GetUserNavigation() then
        MapPin.ClearUserNavigation(nil, true)
    end

    if MapPin.GetPathStepWaypoint() then
        MapPin.ClearPathStepWaypoint()
    end

    if IsSuperTrackingAnything() then
        ClearAllSuperTracked()
    end
end

function MapPin.ParseWayCommand(inputMessage, defaultMapID)
    local tokens = MapPinUtil.TokenizeWayCommand(inputMessage)
    if #tokens == 0 then return nil end

    local function ParseNum(index)
        return tokens[index] and tonumber(tokens[index]) or nil
    end

    local cmd = tokens[1]:lower()
    if cmd == "reset" or cmd == "clear" then
        return { command = "clear" }
    end

    local first = tokens[1]
    local count = #tokens
    local zoneMapID, coordX, coordY, labelName

    defaultMapID = defaultMapID or GetBestMapForUnit("player")

    if first:sub(1, 1) == "#" then
        zoneMapID = tonumber(first:sub(2))
        coordX, coordY = ParseNum(2), ParseNum(3)
        if count > 3 then
            labelName = table.concat(tokens, " ", 4)
        end
    elseif tonumber(first) then
        coordX, coordY = ParseNum(2), ParseNum(3)
        if coordY then
            zoneMapID, coordX, coordY = ParseNum(1), coordX, coordY
            if count > 3 then
                labelName = table.concat(tokens, " ", 4)
            end
        else
            zoneMapID, coordX, coordY = defaultMapID, ParseNum(1), coordX
            if count > 2 then
                labelName = table.concat(tokens, " ", 3)
            end
        end
    else
        for index = 1, count do
            if ParseNum(index) then
                coordX, coordY = ParseNum(index), ParseNum(index + 1)
                zoneMapID = defaultMapID

                if index > 1 then
                    labelName = table.concat(tokens, " ", 1, index - 1)
                end

                break
            end
        end
    end

    if not (zoneMapID and coordX and coordY) then return nil end

    return {
        name  = labelName,
        mapID = zoneMapID,
        x     = coordX,
        y     = coordY
    }
end

function MapPin.SetUserNavigation(options)
    if not options.mapID or not options.x or not options.y then return end
    if options.superTracked == nil then options.superTracked = true end

    local sessionData = MapPinUtil.GetSessionData()
    sessionData.userNavigation = MapPinUtil.CreatePinData(options)
    MapPinUtil.SaveSessionData()

    CallbackRegistry.Trigger("MapPin.SetUserNavigation", sessionData.userNavigation)
    CallbackRegistry.Trigger("MapPin.UserNavigationChanged", sessionData.userNavigation)
    return sessionData.userNavigation
end

function MapPin.ClearUserNavigation(preserveWaypoint, suppressAdvance)
    MapPinUtil.ClearPendingUserNavigationValidation()

    local sessionData = MapPinUtil.GetSessionData()
    local clearedUserNavigation = sessionData.userNavigation

    if clearedUserNavigation and not preserveWaypoint and (not MapPinUtil.IsPathfindingEnabled() or MapPinUtil.IsCurrentWaypoint(clearedUserNavigation.mapID, clearedUserNavigation.x, clearedUserNavigation.y)) then
        ClearUserWaypoint()
    end

    sessionData.userNavigation = nil
    MapPinUtil.SaveSessionData()

    if clearedUserNavigation then
        CallbackRegistry.Trigger("MapPin.UserNavigationCleared", clearedUserNavigation, preserveWaypoint, suppressAdvance)
    end
end

function MapPin.GetUserNavigation()
    return MapPinUtil.GetSessionData().userNavigation
end

function MapPin.IsCustomUserNavigation(userNavigation)
    if userNavigation == nil then
        userNavigation = MapPin.GetUserNavigation()
    end

    return userNavigation ~= nil and userNavigation.fromWUI ~= false
end

function MapPin.IsCustomUserNavigationTracked()
    return MapPin.IsUserNavigationTracked() and MapPin.IsCustomUserNavigation()
end

function MapPin.GetUserNavigationSourcePinID()
    if not MapPin.IsMultiPinEnabled() then return nil end

    local userNavigation = MapPin.GetUserNavigation()
    return userNavigation and userNavigation.sourcePinID or nil
end

function MapPin.CreateUserWaypointPoint(mapID, x, y, coordinatesAreNormalized)
    if not mapID or type(x) ~= "number" or type(y) ~= "number" then return end

    x, y = MapPinUtil.NormalizeWaypointInput(x, y, coordinatesAreNormalized)
    return MapPinUtil.CreateResolvedMapPoint(mapID, x, y)
end

function MapPin.SuppressNextUserNavigationValidation(userNavigation)
    MapPinUtil.SetPendingUserNavigationValidation(userNavigation or MapPin.GetUserNavigation())
end

function MapPin.NewTemporaryWaypoint(mapID, x, y, options)
    if type(mapID) == "table" then
        options = mapID
        mapID = options.mapID
        x = options.x
        y = options.y
    else
        options = options or {}
        options.mapID = mapID
        options.x = x
        options.y = y
    end

    mapID, x, y = options.mapID, options.x, options.y

    local pos, mapPoint
    mapID, pos, mapPoint = MapPin.CreateUserWaypointPoint(mapID, x, y, options.coordinatesAreNormalized)
    if not mapID or not pos or not mapPoint then return end

    local userNavigation = MapPin.SetUserNavigation(MapPinUtil.MergePinOptions({
        name         = options.name or MAP_PIN,
        mapID        = mapID,
        x            = pos.x,
        y            = pos.y,
        fromWUI      = options.fromWUI,
        superTracked = options.superTracked ~= false
    }, MapPinUtil.CreateVisualPinOptions(options)))

    MapPin.SuppressNextUserNavigationValidation(userNavigation)

    if MapPinUtil.ShouldSyncNativeWaypoint(options) then
        MapPinUtil.SetNativeUserWaypoint(mapPoint, userNavigation.superTracked)
    end

    CallbackRegistry.Trigger("MapPin.NewTemporaryWaypoint", userNavigation)
    return userNavigation
end

function MapPin.SetUserNavigationSuperTracked(superTracked, syncNativeWaypoint)
    local userNavigation = MapPin.GetUserNavigation()
    if not userNavigation then return end

    superTracked = superTracked == true
    if userNavigation.superTracked == superTracked then
        if syncNativeWaypoint == true and MapPinUtil.IsCurrentWaypoint(userNavigation.mapID, userNavigation.x, userNavigation.y) then
            SetSuperTrackedUserWaypoint(superTracked)
        end
        return userNavigation
    end

    userNavigation.superTracked = superTracked
    MapPinUtil.SaveSessionData()

    if syncNativeWaypoint == true and MapPinUtil.IsCurrentWaypoint(userNavigation.mapID, userNavigation.x, userNavigation.y) then
        SetSuperTrackedUserWaypoint(superTracked)
    end

    CallbackRegistry.Trigger("MapPin.UserNavigationChanged", userNavigation)
    return userNavigation
end

function MapPin.SyncUserNavigationSuperTracking(activePathfinding)
    if activePathfinding == true then return end

    local userNavigation = MapPin.GetUserNavigation()
    if not userNavigation then return end
    if not MapPinUtil.IsCurrentWaypoint(userNavigation.mapID, userNavigation.x, userNavigation.y) then return end

    return MapPin.SetUserNavigationSuperTracked(IsSuperTrackingUserWaypoint() == true, false)
end

function MapPin.SyncUserNavigationToNativeWaypoint()
    local userNavigation = MapPin.GetUserNavigation()
    if not userNavigation then return end

    local _, mapPoint = MapPinUtil.CreateMapPoint(userNavigation.mapID, userNavigation.x * 100, userNavigation.y * 100)
    return MapPinUtil.SetNativeUserWaypoint(mapPoint, userNavigation.superTracked == true)
end

function MapPin.NewPathStepWaypoint(options)
    local pos, mapPoint
    local mapID = options.mapID
    mapID, pos, mapPoint = MapPin.CreateUserWaypointPoint(mapID, options.x, options.y, options.coordinatesAreNormalized)
    if not mapID or not pos or not mapPoint then return end

    local pathStepWaypoint = MapPinUtil.SetPathStepWaypoint(MapPinUtil.MergePinOptions({
        name             = options.name or MapPin.GeneratePinName(mapID),
        mapID            = mapID,
        x                = pos.x,
        y                = pos.y,
        fromWUI          = options.fromWUI ~= false,
        superTracked     = options.superTracked ~= false,
        pathStepWaypoint = true
    }, MapPinUtil.CreateVisualPinOptions(options)))

    if not pathStepWaypoint then return end

    MapPinUtil.SetNativeUserWaypoint(mapPoint, pathStepWaypoint.superTracked == true)

    CallbackRegistry.Trigger("MapPin.NewPathStepWaypoint", pathStepWaypoint)

    return pathStepWaypoint
end

function MapPin.ClearPathStepWaypoint(preserveNativeDestination)
    local sessionData = MapPinUtil.GetSessionData()
    local clearedPathStepWaypoint = sessionData.pathStepWaypoint
    if not clearedPathStepWaypoint then return end

    local shouldRestoreNativeWaypoint = MapPinUtil.IsCurrentPinWaypoint(clearedPathStepWaypoint)

    sessionData.pathStepWaypoint = nil
    MapPinUtil.SaveSessionData()

    if shouldRestoreNativeWaypoint then
        if preserveNativeDestination == true or not MapPin.SyncUserNavigationToNativeWaypoint() then
            MapPinUtil.ClearNativeUserWaypoint(preserveNativeDestination == true)
        end
    end

    CallbackRegistry.Trigger("MapPin.PathStepWaypointCleared", clearedPathStepWaypoint)
    CallbackRegistry.Trigger("MapPin.PathStepWaypointChanged", nil)
    return clearedPathStepWaypoint
end

function MapPin.GetPathStepWaypoint()
    return MapPinUtil.GetSessionData().pathStepWaypoint
end

function MapPin.IsPathStepWaypointTracked()
    local pathStepWaypoint = MapPin.GetPathStepWaypoint()
    return GetHighestPrioritySuperTrackingType() == Enum.SuperTrackingType.UserWaypoint and MapPinUtil.IsCurrentPinWaypoint(pathStepWaypoint)
end

function MapPin.NewUserNavigation(options)
    local pos, mapPoint
    local mapID = options.mapID
    mapID, pos, mapPoint = MapPin.CreateUserWaypointPoint(mapID, options.x, options.y)
    if not mapID or not pos or not mapPoint then return end

    local userNavigation = MapPin.SetUserNavigation(MapPinUtil.MergePinOptions({
        name         = options.name or MapPin.GeneratePinName(mapID),
        mapID        = mapID,
        x            = pos.x,
        y            = pos.y,
        fromWUI      = options.fromWUI ~= false,
        sourcePinID  = options.sourcePinID,
        superTracked = options.superTracked ~= false
    }, MapPinUtil.CreateVisualPinOptions(options)))

    MapPin.SuppressNextUserNavigationValidation(userNavigation)

    local syncNativeWaypoint = options.syncNativeWaypoint
    if syncNativeWaypoint == nil then syncNativeWaypoint = true end

    if syncNativeWaypoint and not MapPinUtil.IsCurrentWaypoint(mapID, pos.x, pos.y) then
        CallbackRegistry.Trigger("Map.AutoTrackPlacedPin.SuppressNextUpdate")
        SetUserWaypoint(mapPoint)
    end

    if syncNativeWaypoint then
        SetSuperTrackedUserWaypoint(userNavigation.superTracked == true)
    end
    if options.suppressAudio ~= true then
        MapPinUtil.PlayUserNavigationAudio()
    end

    CallbackRegistry.Trigger("MapPin.NewUserNavigation", userNavigation, options)
    return userNavigation
end

function MapPin.NewUserNavigationFromPin(id, suppressAudio, options)
    local pinInfo = MapPin.GetPin(id)
    if not pinInfo then return end

    return MapPin.NewUserNavigation(MapPinUtil.MergePinOptions({
        name             = pinInfo.name,
        mapID            = pinInfo.mapID,
        x                = pinInfo.x * 100,
        y                = pinInfo.y * 100,
        flags            = pinInfo.flags,
        iconTexture      = pinInfo.iconTexture,
        r                = pinInfo.r,
        g                = pinInfo.g,
        b                = pinInfo.b,
        requestRecolor   = pinInfo.requestRecolor,
        iconType         = pinInfo.iconType,
        sourcePinID      = id,
        suppressAudio    = suppressAudio,
        stripCoordinates = pinInfo.stripCoordinates
    }, options))
end

function MapPin.IsUserNavigationTracked()
    local _, waypointMapID, waypointX, waypointY = MapPinUtil.GetCurrentWaypointState()
    local pinTracked = GetHighestPrioritySuperTrackingType() == Enum.SuperTrackingType.UserWaypoint
    local userNavigationInfo = MapPin.GetUserNavigation()
    if pinTracked and userNavigationInfo and MapPinUtil.DoesWaypointMatch(waypointMapID, waypointX, waypointY, userNavigationInfo.mapID, userNavigationInfo.x, userNavigationInfo.y) then
        if MapPinUtil.DoesWaypointMatch(waypointMapID, waypointX, waypointY,
                MapPinUtil.PendingUserNavigationValidation.mapID, MapPinUtil.PendingUserNavigationValidation.x, MapPinUtil.PendingUserNavigationValidation.y) then
            MapPinUtil.ClearPendingUserNavigationValidation()
        end

        return true
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

function MapPin.ValidateSuperTrackedPinDisplay(_, event)
    if MapPinUtil.IsPathfindingEnabled() then return end

    if event == "USER_WAYPOINT_UPDATED" then
        if IsSuperTrackingUserWaypoint() then
            MapPinUtil.ValidateTrackedUserWaypoint(true)
        elseif not HasUserWaypoint() then
            MapPinUtil.ClearPendingUserNavigationValidation()
        end
        return
    end

    MapPinUtil.ValidateUserNavigationState(true)
end

function MapPin.SetPin(options)
    if not options.id then return end
    if not MapPin.IsMultiPinEnabled() then return end

    local sessionData = MapPinUtil.GetSessionData()
    local existingPin = sessionData.pins and sessionData.pins[options.id] or nil
    local sequence = existingPin and existingPin.sequence or MapPinUtil.GetNextPinSequence()

    sessionData.pins = sessionData.pins or {}
    sessionData.pins[options.id] = MapPinUtil.CreatePinData(MapPinUtil.MergePinOptions({ sequence = sequence }, options))
    MapPinUtil.SaveSessionData()

    CallbackRegistry.Trigger("MapPin.PinsChanged", sessionData.pins, options.id, sessionData.pins[options.id])
    return sessionData.pins[options.id]
end

function MapPin.ClearPin(id)
    local sessionData = MapPinUtil.GetSessionData()
    local removedPin = sessionData.pins and sessionData.pins[id] or nil

    sessionData.pins = sessionData.pins or {}
    sessionData.pins[id] = nil
    MapPinUtil.SaveSessionData()

    if removedPin then
        CallbackRegistry.Trigger("MapPin.PinRemoved", id, removedPin)
        CallbackRegistry.Trigger("MapPin.PinsChanged", sessionData.pins, id)
    end
end

function MapPin.ClearAllPins()
    local sessionData = MapPinUtil.GetSessionData()
    if not sessionData.pins then return end

    sessionData.pins = nil
    MapPinUtil.SaveSessionData()

    CallbackRegistry.Trigger("MapPin.PinsClearedAll")
    CallbackRegistry.Trigger("MapPin.PinsChanged", nil)
end

function MapPin.GetPin(id)
    if not MapPin.IsMultiPinEnabled() then return end

    local pins = MapPinUtil.GetSessionData().pins
    if pins then return pins[id] end
end

function MapPin.GetAllPins()
    if not MapPin.IsMultiPinEnabled() then return nil end
    return MapPinUtil.GetSessionData().pins
end

function MapPin.GetClosestPin(excludedPinID)
    if not MapPin.IsMultiPinEnabled() then return end

    local pins = MapPinUtil.GetSessionData().pins
    if not pins then return end

    local playerX, playerY, playerMapID = HBD:GetPlayerZonePosition()
    local closestID, closestPin, closestDistance = nil, nil, nil
    local fallbackID, fallbackPin = nil, nil

    for pinID, pinInfo in pairs(pins) do
        if pinID ~= excludedPinID then
            fallbackID, fallbackPin = MapPinUtil.CreateFallbackPinChoice(fallbackID, fallbackPin, pinID, pinInfo)

            if playerMapID and playerX and playerY then
                local distance = HBD:GetZoneDistance(playerMapID, playerX, playerY, pinInfo.mapID, pinInfo.x, pinInfo.y)
                local pinSequence = pinInfo["sequence"] or math.huge
                local closestSequence = closestPin and closestPin["sequence"] or math.huge

                if distance and (closestDistance == nil or distance < closestDistance or (distance == closestDistance and pinSequence < closestSequence)) then
                    closestID = pinID
                    closestPin = pinInfo
                    closestDistance = distance
                end
            end
        end
    end

    return closestID or fallbackID, closestPin or fallbackPin, closestDistance
end

function MapPin.NewClosestUserNavigation(excludedPinID, suppressAudio)
    if not MapPin.IsMultiPinEnabled() then return nil end

    local pinID = MapPin.GetClosestPin(excludedPinID)
    if not pinID then return nil end

    return MapPin.NewUserNavigationFromPin(pinID, suppressAudio), pinID
end

function MapPin.NewGeneratedPin(options)
    if not MapPin.IsMultiPinEnabled() then return end

    local pinID = MapPinUtil.GeneratePinID()
    local pinInfo = MapPin.NewPin(MapPinUtil.MergePinOptions({ id = pinID }, options))

    return pinInfo, pinID
end

function MapPin.PasteWayCommands(text, options)
    if type(text) ~= "string" then return {}, {} end
    if type(options) ~= "table" then options = {} end

    local createdPins = {}
    local invalidCommands = {}
    local commands = MapPinUtil.ExtractWayCommands(text)
    local defaultMapID = options.defaultMapID or GetBestMapForUnit("player")
    local allowMultiPin = MapPin.IsMultiPinEnabled()
    local directNavigationCommand = nil
    local validCommandCount = 0

    if options.replaceExisting == true then
        MapPin.ClearAllPins()
    end

    for commandIndex, commandText in ipairs(commands) do
        if commandText:match("%S") then
            local parsedCommand = MapPin.ParseWayCommand(commandText, defaultMapID)
            if parsedCommand and parsedCommand.command == "clear" then
                MapPin.ClearAllPins()
                MapPin.ClearUserNavigation(nil, true)
            elseif parsedCommand then
                if allowMultiPin then
                    local pinInfo, pinID = MapPin.NewGeneratedPin(MapPinUtil.MergePinOptions({
                        name  = parsedCommand.name,
                        mapID = parsedCommand.mapID,
                        x     = parsedCommand.x,
                        y     = parsedCommand.y,
                        flags = options.flags
                    }, options))
                    if pinInfo then
                        createdPins[#createdPins + 1] = { id = pinID, pin = pinInfo, index = commandIndex, line = commandIndex }
                    else
                        invalidCommands[#invalidCommands + 1] = { index = commandIndex, text = commandText }
                    end
                else
                    validCommandCount = validCommandCount + 1
                    if directNavigationCommand == nil then
                        directNavigationCommand = parsedCommand
                    end
                end
            else
                invalidCommands[#invalidCommands + 1] = { index = commandIndex, text = commandText }
            end
        end
    end

    if allowMultiPin and #createdPins > 0 and options.activateClosest ~= false then
        MapPin.NewClosestUserNavigation(nil, options.suppressAudio == true)
    elseif not allowMultiPin and validCommandCount == 1 and options.activateClosest ~= false then
        MapPin.NewUserNavigation(MapPinUtil.MergePinOptions({
            name          = directNavigationCommand.name,
            mapID         = directNavigationCommand.mapID,
            x             = directNavigationCommand.x,
            y             = directNavigationCommand.y,
            flags         = options.flags,
            suppressAudio = options.suppressAudio == true
        }, options))
    end

    CallbackRegistry.Trigger("MapPin.PasteWayCommands", createdPins, invalidCommands)

    return createdPins, invalidCommands
end

function MapPin.NewPin(options)
    if not options.id then return end
    if not MapPin.IsMultiPinEnabled() then return end

    local pos = nil
    local mapID = options.mapID
    mapID, pos = MapPinUtil.CreateResolvedMapPoint(mapID, options.x, options.y)
    if not mapID or not pos then return end

    local pinInfo = MapPin.SetPin(MapPinUtil.MergePinOptions({
        id    = options.id,
        name  = options.name or MapPin.GeneratePinName(mapID),
        mapID = mapID,
        x     = pos.x,
        y     = pos.y
    }, MapPinUtil.CreateVisualPinOptions(options)))

    CallbackRegistry.Trigger("MapPin.NewPin", pinInfo, options.id)

    return pinInfo
end


do
    local ignoredRemovedPinID = nil
    local ignoredClearedSourcePinID = nil

    local function SetClosestUserNavigation(excludedPinID)
        if not MapPin.IsMultiPinEnabled() then return false end

        local _, nextPinID = MapPin.NewClosestUserNavigation(excludedPinID, true)
        if nextPinID then return true end

        ignoredClearedSourcePinID = excludedPinID
        MapPin.ClearUserNavigation(nil, true)
        return false
    end

    local function AdvanceFromPin(pinID)
        if not MapPin.IsMultiPinEnabled() or not pinID then return end

        ignoredRemovedPinID = pinID
        MapPin.ClearPin(pinID)
        SetClosestUserNavigation(pinID)
    end

    function MapPin.AdvanceFromActivePin()
        AdvanceFromPin(MapPin.GetUserNavigationSourcePinID())
    end

    CallbackRegistry.Add("MapPin.PinRemoved", function(_, pinID)
        if not MapPin.IsMultiPinEnabled() then return end
        if ignoredRemovedPinID == pinID then
            ignoredRemovedPinID = nil
            return
        end

        if pinID and pinID == MapPin.GetUserNavigationSourcePinID() then
            AdvanceFromPin(pinID)
        end
    end)

    CallbackRegistry.Add("MapPin.PinsClearedAll", function()
        if not MapPin.IsMultiPinEnabled() then return end

        local activePinID = MapPin.GetUserNavigationSourcePinID()
        if not activePinID then return end

        ignoredClearedSourcePinID = activePinID
        MapPin.ClearUserNavigation(nil, true)
    end)

    CallbackRegistry.Add("MapPin.UserNavigationCleared", function(_, clearedUserNavigation, preserveWaypoint, suppressAdvance)
        if not MapPin.IsMultiPinEnabled() or suppressAdvance == true then return end

        local sourcePinID = clearedUserNavigation and clearedUserNavigation.sourcePinID or nil
        if not sourcePinID then return end

        if ignoredClearedSourcePinID == sourcePinID then
            ignoredClearedSourcePinID = nil
            return
        end

        AdvanceFromPin(sourcePinID)
    end)
end

do --Automatically clear supertracking and navigation data when the user waypoint is removed
    local f = CreateFrame("Frame")
    f:RegisterEvent("USER_WAYPOINT_UPDATED")
    f:SetScript("OnEvent", function()
        local suppressUserNavigationClear = MapPinUtil.SuppressNextUserNavigationClear
        MapPinUtil.SuppressNextUserNavigationClear = false

        if not HasUserWaypoint() then
            if IsSuperTrackingUserWaypoint() then ClearAllSuperTracked() end
            if suppressUserNavigationClear then return end
            if MapPin.GetPathStepWaypoint() and MapPinUtil.IsPathfindingEnabled() then return end

            MapPin.ClearUserNavigation(true)
        end
    end)
end


local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "MapPinEnhanced" then
            CallbackRegistry.Trigger("MapPin.PinsChanged")
            CallbackRegistry.Trigger("MapPin.MapPinsStateChanged")
            CallbackRegistry.Trigger("Setting.Refresh")
        end
    else
        MapPin.ValidateSuperTrackedPinDisplay(self, event, ...)
    end
end

local EL = CreateFrame("Frame")
EL:RegisterEvent("USER_WAYPOINT_UPDATED")
EL:RegisterEvent("SUPER_TRACKING_CHANGED")
EL:RegisterEvent("ADDON_LOADED")
EL:SetScript("OnEvent", OnEvent)
CallbackRegistry.Add("MapPin.NewUserNavigation", MapPin.ValidateSuperTrackedPinDisplay)
SavedVariables.OnChange("WaypointDB_Global", "CustomMapPinsEnabled", function() CallbackRegistry.Trigger("MapPin.MapPinsStateChanged") end)
SavedVariables.OnChange("WaypointDB_Global", "PathfindingEnabled", function(enabled)
    if enabled == false and MapPin.GetUserNavigation() then
        MapPin.SyncUserNavigationToNativeWaypoint()
    end
end)

local function OnAddonLoad()
    MapPinUtil.GetSessionData()
    MapPin.GetUserNavigation()
    MapPin.GetPathStepWaypoint()
    CallbackRegistry.Trigger("MapPin.Ready")
end

CallbackRegistry.Add("Preload.AddonReady", OnAddonLoad)
