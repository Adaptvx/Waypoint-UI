local env = select(2, ...)
local L = env.L
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")
local Navigation_Mapzeroth = env.modules:New("@\\Navigation\\Mapzeroth")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local format = string.format
local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local type = type
local tonumber = tonumber


local DIRECT_METHODS = {
    walk = Navigation_Preload.Enum.NavigationMethod.Direct,
    fly  = Navigation_Preload.Enum.NavigationMethod.Direct
}


local function GetAddon()
    return _G.Mapzeroth
end

local function GetExternalNavigation()
    local addon = GetAddon()
    local externalNavigation = addon and addon.ExternalNavigation or nil
    if not externalNavigation then return nil end

    return externalNavigation,
        type(externalNavigation.BuildPath) == "function" and externalNavigation.BuildPath
        or type(externalNavigation.BuildRoute) == "function" and externalNavigation.BuildRoute
end

local function HasNativePathBuilder(addon)
    return addon
        and type(addon.GetAvailableTravelAbilities) == "function"
        and type(addon.GetPlayerLocation) == "function"
        and type(addon.BuildSyntheticEdges) == "function"
        and type(addon.FindPath) == "function"
        and type(addon.OptimizeConsecutiveMovement) == "function"
        and (type(addon.GetTravelNode) == "function"
            or (addon.TravelGraph and type(addon.TravelGraph.GetNodeByID) == "function"))
end

local function GetTravelNode(nodeID)
    local addon = GetAddon()
    if not addon or not nodeID then return nil end

    if type(addon.GetTravelNode) == "function" then
        return addon:GetTravelNode(nodeID)
    end

    local travelGraph = addon.TravelGraph
    if travelGraph and type(travelGraph.GetNodeByID) == "function" then
        return travelGraph:GetNodeByID(nodeID)
    end
end

local function CreateTarget(data, name)
    if type(data) ~= "table" then return nil end

    local mapID = tonumber(data.mapID)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    if not mapID or not x or not y then return nil end

    return {
        mapID = mapID,
        x     = x,
        y     = y,
        name  = name
    }
end

local function CreatePath(steps)
    return {
        metadata = {
            providerName = L["MAPZEROTH"]
        },
        steps    = steps or {}
    }
end

local function CreateStepMetadata(navigationMethod, itemID)
    return {
        navigationMethod = navigationMethod,
        itemID           = itemID
    }
end

local function BuildFallbackPath(mapID, x, y)
    return CreatePath({
        {
            mapID                = mapID,
            normalizedX          = x,
            normalizedY          = y,
            method               = Navigation_Preload.Enum.NavigationMethod.Direct,
            metadata             = CreateStepMetadata("direct"),
            autoAdvanceOnArrival = true,
            advanceOnMapChange   = false
        }
    })
end

local function FinalizePath(path, mapID, x, y)
    return #path.steps > 0 and path or BuildFallbackPath(mapID, x, y)
end

local function BuildSyntheticTargets(playerAbilities, waypoint)
    local syntheticTargets = {}
    local waypointTarget = CreateTarget(waypoint, waypoint and (waypoint.name or waypoint.locationName))
    if waypointTarget then
        syntheticTargets["_WAYPOINT_DESTINATION"] = waypointTarget
    end

    if type(playerAbilities) ~= "table" then return syntheticTargets end

    for _, ability in ipairs(playerAbilities) do
        if type(ability) == "table" and ability.isHearthstone == true then
            local hearthstone = ability.hearthstone
            local hearthstoneTarget = CreateTarget(hearthstone, hearthstone and (hearthstone.name or hearthstone.locationName))
            if hearthstoneTarget then
                syntheticTargets["_HEARTHSTONE_DESTINATION"] = hearthstoneTarget
            end
        end
    end

    return syntheticTargets
end

local function ResolveStepTarget(nodeID, syntheticTargets, playerLocation)
    if not nodeID then return nil end

    if syntheticTargets then
        local target = syntheticTargets[nodeID]
        if target then
            return target
        end
    end

    if nodeID == "_PLAYER_POSITION" then
        return CreateTarget(playerLocation)
    end

    local node = GetTravelNode(nodeID)
    return CreateTarget(node, node and (node.displayName or node.name))
end

local function GetStepAbilityName(stepData)
    local label = type(stepData) == "table" and (stepData.label or stepData.name) or nil
    if type(label) ~= "string" then return nil end

    return label:match("^Use (.+) to .+$") or label:match("^Use (.+)$")
end

local function FindAbilityItemID(abilities, abilityName)
    if type(abilities) ~= "table" or not abilityName then return nil end

    for _, ability in pairs(abilities) do
        local itemID = type(ability) == "table" and ability.name == abilityName and tonumber(ability.itemID) or nil
        if itemID then
            return itemID
        end
    end
end

local function ResolveStepItemID(stepData)
    if type(stepData) ~= "table" then return nil end

    local itemID = tonumber(stepData.itemID)
    if itemID then return itemID end

    local addon = GetAddon()
    local abilityName = addon and (stepData.abilityName or GetStepAbilityName(stepData)) or nil
    if not abilityName then return nil end

    if type(addon.GetAvailableTravelAbilities) == "function" then
        itemID = FindAbilityItemID(addon:GetAvailableTravelAbilities(), abilityName)
        if itemID then
            return itemID
        end
    end

    return FindAbilityItemID(addon.TravelItems, abilityName)
end

local function GetNavigationMethod(stepData, itemID)
    if itemID then
        return Navigation_Preload.Enum.NavigationMethod.Item, "item"
    end

    local method = type(stepData) == "table" and stepData.method or nil
    if DIRECT_METHODS[method] then
        return Navigation_Preload.Enum.NavigationMethod.Direct, "direct"
    end
    if method then
        return Navigation_Preload.Enum.NavigationMethod.Portal, "portal"
    end

    return Navigation_Preload.Enum.NavigationMethod.Direct, "direct"
end

local function CreatePathStep(name, target, method, metadata, autoAdvanceOnArrival, advanceOnMapChange, transitionSourceMapID, completionTarget)
    if not target then return nil end

    local step = {
        name                  = name,
        mapID                 = target.mapID,
        normalizedX           = target.x,
        normalizedY           = target.y,
        method                = method,
        metadata              = metadata,
        autoAdvanceOnArrival  = autoAdvanceOnArrival,
        advanceOnMapChange    = advanceOnMapChange,
        transitionSourceMapID = transitionSourceMapID
    }

    if completionTarget then
        step.completionMapID = completionTarget.mapID
        step.completionNormalizedX = completionTarget.x
        step.completionNormalizedY = completionTarget.y
    end

    return step
end

local function GetNativeStepName(stepData, sourceTarget, destinationTarget)
    if type(stepData) ~= "table" then return nil end

    local abilityName = stepData.abilityName
    local destinationName = stepData.destination or stepData.destinationName or destinationTarget and destinationTarget.name or nil
    if abilityName then
        return destinationName and format("Use %s to %s", abilityName, destinationName) or format("Use %s", abilityName)
    end

    return destinationName or sourceTarget and sourceTarget.name or nil
end

local function BuildExternalPathStep(stepData)
    if type(stepData) ~= "table" then return nil end

    local target = CreateTarget({
        mapID = stepData.mapID,
        x     = stepData.x,
        y     = stepData.y
    })
    if not target then return nil end

    local itemID = ResolveStepItemID(stepData)
    local method, navigationMethod = GetNavigationMethod(stepData, itemID)
    return CreatePathStep(
        stepData.label or stepData.name,
        target,
        method,
        CreateStepMetadata(navigationMethod, itemID),
        stepData.autoAdvanceOnArrival ~= false,
        stepData.advanceOnMapChange == true,
        tonumber(stepData.transitionSourceMapID) or nil,
        CreateTarget({
            mapID = stepData.completionMapID,
            x     = stepData.completionX or stepData.completionNormalizedX,
            y     = stepData.completionY or stepData.completionNormalizedY
        })
    )
end

local function BuildNativePathStep(stepData, playerLocation, syntheticTargets)
    if type(stepData) ~= "table" then return nil end

    local itemID = ResolveStepItemID(stepData)
    local method, navigationMethod = GetNavigationMethod(stepData, itemID)
    local destinationTarget = ResolveStepTarget(stepData.nodeID, syntheticTargets, playerLocation)
    local sourceTarget = ResolveStepTarget(stepData.fromNodeID, syntheticTargets, playerLocation)
    local target = method == Navigation_Preload.Enum.NavigationMethod.Direct and destinationTarget or sourceTarget or destinationTarget

    return CreatePathStep(
        GetNativeStepName(stepData, sourceTarget, destinationTarget),
        target,
        method,
        CreateStepMetadata(navigationMethod, itemID),
        method == Navigation_Preload.Enum.NavigationMethod.Direct,
        method ~= Navigation_Preload.Enum.NavigationMethod.Direct,
        sourceTarget and sourceTarget.mapID or nil,
        method ~= Navigation_Preload.Enum.NavigationMethod.Direct and destinationTarget or nil
    )
end

local function AppendPathSteps(path, steps, buildStep, ...)
    for _, stepData in ipairs(steps) do
        local step = buildStep(stepData, ...)
        if step then
            path.steps[#path.steps + 1] = step
        end
    end

    return path
end

local function BuildRawStep(nodeID, previousStepInfo, syntheticTargets, playerLocation, waypoint)
    local destinationTarget = ResolveStepTarget(nodeID, syntheticTargets, playerLocation)

    return {
        method          = previousStepInfo.method,
        abilityName     = previousStepInfo.abilityName,
        destinationName = previousStepInfo.destinationName,
        destination     = destinationTarget and destinationTarget.name or nil,
        itemID          = previousStepInfo.itemID,
        spellID         = previousStepInfo.spellID,
        nodeID          = nodeID,
        fromNodeID      = previousStepInfo.node,
        time            = previousStepInfo.cost,
        waypointData    = nodeID == "_WAYPOINT_DESTINATION" and waypoint or nil
    }
end

local function OptimizeRawSteps(addon, rawSteps)
    local optimized = type(addon.OptimizeConsecutiveMovement) == "function" and addon:OptimizeConsecutiveMovement(rawSteps) or nil
    return type(optimized) == "table" and optimized or rawSteps
end

local function BuildExternalPath(mapID, x, y)
    local externalNavigation, buildPath = GetExternalNavigation()
    if not buildPath then return nil end

    local success, externalPath = pcall(buildPath, externalNavigation, {
        mapID = mapID,
        x     = x,
        y     = y
    })
    if not success or type(externalPath) ~= "table" or type(externalPath.steps) ~= "table" then return nil end

    return FinalizePath(AppendPathSteps(CreatePath(), externalPath.steps, BuildExternalPathStep), mapID, x, y)
end

local function BuildNativePath(mapID, x, y)
    local addon = GetAddon()
    if not HasNativePathBuilder(addon) then return nil end

    local playerLocation = addon:GetPlayerLocation()
    local playerAbilities = addon:GetAvailableTravelAbilities()
    local waypoint = {
        mapID = mapID,
        x     = x,
        y     = y
    }
    local syntheticTargets = BuildSyntheticTargets(playerAbilities, waypoint)
    local syntheticEdges = addon:BuildSyntheticEdges(playerLocation, playerAbilities, waypoint)
    local pathNodes, _, previous = addon:FindPath("_PLAYER_POSITION", "_WAYPOINT_DESTINATION", playerAbilities, syntheticEdges)
    if type(pathNodes) ~= "table" or type(previous) ~= "table" then return nil end

    local rawSteps = {}
    for _, nodeID in ipairs(pathNodes) do
        local previousStepInfo = previous[nodeID]
        if previousStepInfo then
            rawSteps[#rawSteps + 1] = BuildRawStep(nodeID, previousStepInfo, syntheticTargets, playerLocation, waypoint)
        end
    end

    return FinalizePath(AppendPathSteps(CreatePath(), OptimizeRawSteps(addon, rawSteps), BuildNativePathStep, playerLocation, syntheticTargets), mapID, x, y)
end


function Navigation_Mapzeroth.IsAvailable()
    if IsAddOnLoaded("Mapzeroth") == false then return false end

    local externalNavigation, buildPath = GetExternalNavigation()
    if externalNavigation and buildPath then
        if type(externalNavigation.IsAvailable) ~= "function" then
            return true
        end

        local success, isAvailable = pcall(externalNavigation.IsAvailable, externalNavigation)
        if success and isAvailable == true then
            return true
        end
    end

    return HasNativePathBuilder(GetAddon())
end

function Navigation_Mapzeroth.PathBuilder(mapID, x, y)
    if Navigation_Mapzeroth.IsAvailable() == false then return nil end

    local externalPath = BuildExternalPath(mapID, x, y)
    if externalPath then
        return externalPath
    end

    local nativeOk, nativePath = pcall(BuildNativePath, mapID, x, y)
    return nativeOk and nativePath or BuildFallbackPath(mapID, x, y)
end
