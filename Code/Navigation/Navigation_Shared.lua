local env = select(2, ...)
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")
local Navigation_Shared = env.modules:New("@\\Navigation\\Shared")
local HBD = LibStub("HereBeDragons-2.0")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local GetAddOnEnableState = C_AddOns.GetAddOnEnableState
local LoadAddOn = C_AddOns.LoadAddOn
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetMapInfo = C_Map.GetMapInfo
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local UnitName = UnitName
local tonumber = tonumber
local math_abs = math.abs
local type = type


local PATH_STEP_COMPLETION_DISTANCE = 55


function Navigation_Shared.IsPathProviderAddonEnabled(addonName)
    if not addonName then return true end
    if IsAddOnLoaded(addonName) then return true end

    local playerName = UnitName and UnitName("player") or nil
    local enableState = playerName and GetAddOnEnableState(playerName, addonName) or nil

    return type(enableState) ~= "number" or enableState > 0
end

function Navigation_Shared.EnsurePathProviderAddonLoaded(addonName)
    if not addonName then return true end
    if IsAddOnLoaded(addonName) then return true end
    if not LoadAddOn then return false end

    local success, isLoaded = pcall(LoadAddOn, addonName)
    if success and isLoaded == true then return true end

    return IsAddOnLoaded(addonName) == true
end

function Navigation_Shared.IsDirectPathStep(step)
    return step and step.method == Navigation_Preload.Enum.NavigationMethod.Direct
end

function Navigation_Shared.GetStepDistance(playerMapID, playerX, playerY, mapID, normalizedX, normalizedY)
    if not playerMapID or not playerX or not playerY or not mapID or not normalizedX or not normalizedY then return nil end
    return HBD:GetZoneDistance(playerMapID, playerX, playerY, mapID, normalizedX, normalizedY)
end

function Navigation_Shared.GetPlayerPathPosition()
    local playerX, playerY, playerMapID = HBD:GetPlayerZonePosition()
    playerMapID = playerMapID or GetBestMapForUnit("player")

    if playerMapID and (not playerX or not playerY) then
        local playerPosition = GetPlayerMapPosition(playerMapID, "player")
        if playerPosition then
            playerX = playerPosition.x
            playerY = playerPosition.y
        end
    end

    return playerX, playerY, playerMapID
end

function Navigation_Shared.GetStepCompletionPosition(step)
    if not step then return nil, nil, nil end
    return step.completionMapID or step.mapID, step.completionNormalizedX or step.normalizedX, step.completionNormalizedY or step.normalizedY
end

function Navigation_Shared.IsParentZoneMap(mapID, parentMapID)
    local mapInfo = GetMapInfo(mapID)
    local currentParentMapID = mapInfo and mapInfo.parentMapID or nil

    while currentParentMapID and currentParentMapID ~= 0 do
        if currentParentMapID == parentMapID then
            return true
        end

        mapInfo = GetMapInfo(currentParentMapID)
        currentParentMapID = mapInfo and mapInfo.parentMapID or nil
    end

    return false
end

function Navigation_Shared.DoMapsMatch(expectedMapID, playerMapID)
    if not expectedMapID or not playerMapID then return false end
    return expectedMapID == playerMapID or Navigation_Shared.IsParentZoneMap(expectedMapID, playerMapID) or Navigation_Shared.IsParentZoneMap(playerMapID, expectedMapID)
end

function Navigation_Shared.ShouldAdvancePathStepOnMapChange(step, previousPlayerMapID, playerMapID)
    if not step or step.advanceOnMapChange ~= true then return false end
    if not previousPlayerMapID or not playerMapID or previousPlayerMapID == playerMapID then return false end

    local transitionSourceMapID = step.transitionSourceMapID
    local completionMapID = Navigation_Shared.GetStepCompletionPosition(step)

    if transitionSourceMapID and not Navigation_Shared.DoMapsMatch(transitionSourceMapID, previousPlayerMapID) then return false end
    if completionMapID and not Navigation_Shared.DoMapsMatch(completionMapID, playerMapID) then return false end

    return true
end

function Navigation_Shared.AreNumbersEquivalent(a, b)
    if a == b then return true end
    if not a or not b then return false end
    return math_abs(a - b) <= 0.00001
end

function Navigation_Shared.ArePathStepMetadataEquivalent(a, b)
    if a == b then return true end
    if not a or not b then return false end
    return a.navigationMethod == b.navigationMethod and tonumber(a.itemID) == tonumber(b.itemID)
end

function Navigation_Shared.ArePathStepsEquivalent(a, b)
    if not a or not b then return false end
    if a == b then return true end

    local aCompletionMapID, aCompletionX, aCompletionY = Navigation_Shared.GetStepCompletionPosition(a)
    local bCompletionMapID, bCompletionX, bCompletionY = Navigation_Shared.GetStepCompletionPosition(b)

    return a.method == b.method
        and a.name == b.name
        and a.mapID == b.mapID
        and Navigation_Shared.AreNumbersEquivalent(a.normalizedX, b.normalizedX)
        and Navigation_Shared.AreNumbersEquivalent(a.normalizedY, b.normalizedY)
        and aCompletionMapID == bCompletionMapID
        and Navigation_Shared.AreNumbersEquivalent(aCompletionX, bCompletionX)
        and Navigation_Shared.AreNumbersEquivalent(aCompletionY, bCompletionY)
        and Navigation_Shared.ArePathStepMetadataEquivalent(a.metadata, b.metadata)
end

function Navigation_Shared.ShouldAdvancePathStep(step, previousPlayerMapID, playerMapID, playerX, playerY)
    if not step or not playerMapID then return false end
    if Navigation_Shared.ShouldAdvancePathStepOnMapChange(step, previousPlayerMapID, playerMapID) then return true end
    if not playerX or not playerY then return false end

    if step.autoAdvanceOnArrival ~= false then
        if not step.mapID or not step.normalizedX or not step.normalizedY then return false end

        local distance = Navigation_Shared.GetStepDistance(playerMapID, playerX, playerY, step.mapID, step.normalizedX, step.normalizedY)
        return distance and distance <= PATH_STEP_COMPLETION_DISTANCE
    end

    local completionMapID, completionNormalizedX, completionNormalizedY = Navigation_Shared.GetStepCompletionPosition(step)
    local completionDistance = Navigation_Shared.GetStepDistance(playerMapID, playerX, playerY, completionMapID, completionNormalizedX, completionNormalizedY)
    return completionDistance and completionDistance <= PATH_STEP_COMPLETION_DISTANCE
end
