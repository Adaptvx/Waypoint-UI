local env = select(2, ...)
local L = env.L
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")
local Navigation_Shared = env.modules:Import("@\\Navigation\\Shared")
local Navigation_Mapzeroth = env.modules:New("@\\Navigation\\Mapzeroth")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local ipairs = ipairs
local pcall = pcall
local type = type
local tonumber = tonumber


local DIRECT_METHODS = {
    walk = true,
    fly  = true
}


local function CreateTarget(data)
    if type(data) ~= "table" then return nil end

    local mapID = tonumber(data.mapID)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    if not mapID or not x or not y then return nil end

    return {
        mapID = mapID,
        x     = x,
        y     = y
    }
end

local function CreatePath()
    return {
        metadata = {
            providerName = L["MAPZEROTH"]
        },
        steps    = {}
    }
end

local function GetStepNavigation(stepData)
    if DIRECT_METHODS[stepData.method] then return Navigation_Preload.Enum.NavigationMethod.Direct, "direct" end

    local source = stepData.source
    local itemID = type(source) == "table" and tonumber(source.itemID) or nil
    if itemID then return Navigation_Preload.Enum.NavigationMethod.Item, "item", itemID end

    return Navigation_Preload.Enum.NavigationMethod.Portal, "portal"
end

local function CreatePathStep(stepData, target, completionTarget)
    local method, navigationMethod, itemID = GetStepNavigation(stepData)
    local isDirect = method == Navigation_Preload.Enum.NavigationMethod.Direct

    return {
        name                  = stepData.text or stepData.name,
        mapID                 = target.mapID,
        normalizedX           = target.x,
        normalizedY           = target.y,
        method                = method,
        metadata              = {
            navigationMethod = navigationMethod,
            itemID           = itemID
        },
        autoAdvanceOnArrival  = isDirect,
        advanceOnMapChange    = not isDirect,
        transitionSourceMapID = not isDirect and target.mapID or nil,
        completionMapID       = completionTarget and completionTarget.mapID or nil,
        completionNormalizedX = completionTarget and completionTarget.x or nil,
        completionNormalizedY = completionTarget and completionTarget.y or nil
    }
end

local function BuildFallbackPath(mapID, x, y)
    local path = CreatePath()
    path.steps[1] = CreatePathStep({ method = "walk" }, { mapID = mapID, x = x, y = y })
    return path
end

local function BuildPath(mapID, x, y)
    local addon = _G.MapzerothAddon
    local destination = addon:PlaceAt(mapID, x, y, "WAYPOINT")
    if not destination then return nil end

    local plan = addon.Journey:PlanFromHere({
        nodeID = destination.id,
        dest   = destination
    })
    if type(plan) ~= "table" or type(plan.steps) ~= "table" then return nil end

    local path = CreatePath()
    local playerX, playerY, playerMapID = Navigation_Shared.GetPlayerPathPosition()
    local previousTarget = CreateTarget({ mapID = playerMapID, x = playerX, y = playerY })

    for _, stepData in ipairs(plan.steps) do
        if type(stepData) ~= "table" then return nil end

        if stepData.method ~= "equip" then
            local points = stepData.path
            if type(points) ~= "table" or #points == 0 then return nil end

            local destinationTarget = CreateTarget(points[#points])
            if not destinationTarget then return nil end

            if DIRECT_METHODS[stepData.method] then
                for pointIndex = #points > 1 and 2 or 1, #points do
                    local target = CreateTarget(points[pointIndex])
                    if not target then return nil end

                    path.steps[#path.steps + 1] = CreatePathStep(stepData, target)
                end
            else
                local sourceTarget = #points > 1 and CreateTarget(points[1]) or previousTarget or destinationTarget
                if not sourceTarget then return nil end

                path.steps[#path.steps + 1] = CreatePathStep(stepData, sourceTarget, destinationTarget)
            end

            previousTarget = destinationTarget
        end
    end

    local lastStep = path.steps[#path.steps]
    if not lastStep or lastStep.method ~= Navigation_Preload.Enum.NavigationMethod.Direct or lastStep.mapID ~= mapID or lastStep.normalizedX ~= x or lastStep.normalizedY ~= y then
        path.steps[#path.steps + 1] = CreatePathStep({ method = "walk" }, { mapID = mapID, x = x, y = y })
    end

    return path
end


function Navigation_Mapzeroth.IsAvailable()
    if IsAddOnLoaded("Mapzeroth") == false then return false end

    local addon = _G.MapzerothAddon
    return addon ~= nil and type(addon.PlaceAt) == "function" and addon.Journey ~= nil and type(addon.Journey.PlanFromHere) == "function"
end

function Navigation_Mapzeroth.PathBuilder(mapID, x, y)
    if Navigation_Mapzeroth.IsAvailable() == false then return nil end

    local success, path = pcall(BuildPath, mapID, x, y)
    return success and path or BuildFallbackPath(mapID, x, y)
end
