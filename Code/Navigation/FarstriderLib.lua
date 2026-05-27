local env = select(2, ...)
local L = env.L
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")
local Navigation_FarstriderLib = env.modules:New("@\\Navigation\\FarstriderLib")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local ipairs = ipairs
local tonumber = tonumber


local EDGE_TYPE = {
    Travel     = 1000,
    Flightpath = 1001,
    Portal     = 1002,
    Boat       = 1003,
    Zeppelin   = 1004,
    Item       = 1005,
    Spell      = 1006
}

local NON_DIRECT_EDGE_TYPES = {
    [EDGE_TYPE.Flightpath] = true,
    [EDGE_TYPE.Portal]     = true,
    [EDGE_TYPE.Boat]       = true,
    [EDGE_TYPE.Zeppelin]   = true,
    [EDGE_TYPE.Spell]      = true
}


local function CreateStepMetadata(navigationMethod, itemID)
    return {
        navigationMethod = navigationMethod,
        itemID           = itemID
    }
end

local function ShouldSkipOptimizedEdge(edges, index, virtualGoalKey)
    local edge = edges[index]
    if not edge then return true end
    if index == #edges or (edge.to and edge.to.key == virtualGoalKey) then return false end
    if edge.skipOptimized or edge.locaId == EDGE_TYPE.Travel then return true end

    local nextEdge = edges[index + 1]
    return edge.locaId == EDGE_TYPE.Flightpath and nextEdge and nextEdge.locaId == EDGE_TYPE.Flightpath
end

local function GetStepNavigation(edge)
    local actionOptions = edge and edge.actionOptions
    if type(actionOptions) == "table" then
        for _, actionOption in ipairs(actionOptions) do
            local itemID = type(actionOption) == "table" and actionOption.type == "item" and tonumber(actionOption.data) or nil
            if itemID then
                return Navigation_Preload.Enum.NavigationMethod.Item, CreateStepMetadata("item", itemID)
            end

            if type(actionOption) == "table" and actionOption.type == "item" then
                return Navigation_Preload.Enum.NavigationMethod.Item, CreateStepMetadata("item")
            end
        end

        return Navigation_Preload.Enum.NavigationMethod.Portal, CreateStepMetadata("portal")
    end

    if edge and NON_DIRECT_EDGE_TYPES[edge.locaId] then
        return Navigation_Preload.Enum.NavigationMethod.Portal, CreateStepMetadata("portal")
    end

    return Navigation_Preload.Enum.NavigationMethod.Direct, CreateStepMetadata("direct")
end

local function BuildPathStep(stepData, edge)
    local loc = type(stepData) == "table" and stepData.loc or nil
    local pos = loc and loc.pos or nil
    if not loc or not loc.mapId or not pos or type(edge) ~= "table" then return nil end

    local completionLoc = stepData.completionLoc
    local completionPos = completionLoc and completionLoc.pos or nil
    local method, metadata = GetStepNavigation(edge)

    return {
        name                  = stepData.loca,
        mapID                 = loc.mapId,
        normalizedX           = pos.x,
        normalizedY           = pos.y,
        method                = method,
        metadata              = metadata,
        autoAdvanceOnArrival  = method == Navigation_Preload.Enum.NavigationMethod.Direct,
        advanceOnMapChange    = method ~= Navigation_Preload.Enum.NavigationMethod.Direct,
        transitionSourceMapID = loc.mapId,
        completionMapID       = completionLoc and completionLoc.mapId or nil,
        completionNormalizedX = completionPos and completionPos.x or nil,
        completionNormalizedY = completionPos and completionPos.y or nil
    }
end


function Navigation_FarstriderLib.IsAvailable()
    return IsAddOnLoaded("FarstriderLib") and FarstriderLib_API and type(FarstriderLib_API.FindTrailTo) == "function"
end

function Navigation_FarstriderLib.PathBuilder(mapID, x, y)
    if Navigation_FarstriderLib.IsAvailable() == false then return nil end

    local optimizedPath, rawPath, edges = FarstriderLib_API.FindTrailTo(mapID, x, y, 0)
    if type(optimizedPath) ~= "table" or type(rawPath) ~= "table" or type(edges) ~= "table" then return nil end

    local path = {
        metadata = {
            providerName = L["FARSTRIDERLIB"]
        },
        steps    = {}
    }
    local steps = path.steps
    local virtualGoalKey = rawPath[#rawPath] and rawPath[#rawPath].key
    local optimizedIndex = 1

    for edgeIndex, edge in ipairs(edges) do
        if not ShouldSkipOptimizedEdge(edges, edgeIndex, virtualGoalKey) then
            local step = BuildPathStep(optimizedPath[optimizedIndex], edge)
            if step then
                steps[#steps + 1] = step
            end

            optimizedIndex = optimizedIndex + 1
        end
    end

    return path
end
