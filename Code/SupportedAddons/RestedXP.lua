local env = select(2, ...)
local L = env.L
local Config = env.Config
local Path = env.modules:Import("packages\\path")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local MapPin = env.modules:Import("@\\MapPin")
local SupportedAddons = env.modules:Import("@\\SupportedAddons")
local SupportedAddons_RestedXP = env.modules:New("@\\SupportedAddons\\RestedXP")
local function IsModuleEnabled() return Config.DBGlobal:GetVariable("RestedXPSupportEnabled") == true end

local RestedXP = nil
local RestedXPWaypointInfo = { step = nil, name = nil, mapID = nil, x = nil, y = nil }
local textLines = {}


local function HandleAccept()
    SupportedAddons_RestedXP.PlaceWaypointAtSession()
end

local REPLACE_PROMPT_INFO = {
    text         = L["RESTEDXP_REPLACEPROMPT"],
    options      = {
        {
            text     = L["REPLACE"],
            callback = HandleAccept
        },
        {
            text     = L["CANCEL"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}


local function ResetWaypointInfo()
    wipe(RestedXPWaypointInfo)

    if MapPin.IsUserNavigationFlagged("RestedXP_Waypoint") then
        MapPin.ClearUserNavigation()
    end
end

local function NormalizeInstructionText(text)
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("|cRXP_[A-Z]+_", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("::%d+", ""):gsub("%s+", " ")
    return strtrim(text)
end

local function GetStepName(step)
    if step.title and step.title ~= "" then
        return step.title
    end

    if step.index then
        return string.format(RestedXP.locale.Get("Step %d"), step.index)
    end

    wipe(textLines)

    for _, element in ipairs(step.elements or {}) do
        local frame = element.frame
        local text = frame and frame.text and frame.text:GetText()
        if not text or text == "" or text == " " then
            text = element.text or element.tooltipText or element.rawtext
        end

        if text then
            text = RestedXP.ReplaceNpcIds(RestedXP.locale.Get(text), element)
            text = NormalizeInstructionText(text)
            if text ~= "" then
                textLines[#textLines + 1] = text
            end
        end
    end

    if #textLines > 0 then
        return table.concat(textLines, "\n")
    end

    local text = step.text
    if not text or text == "" then text = step.hiddentext end
    if text and text ~= "" then
        text = NormalizeInstructionText(RestedXP.ReplaceNpcIds(RestedXP.locale.Get(text)))
        if text ~= "" then return text end
    end

    return "RestedXP"
end

function SupportedAddons_RestedXP.PlaceWaypointAtSession()
    if not IsModuleEnabled() then return end
    if not RestedXPWaypointInfo.mapID or not RestedXPWaypointInfo.x or not RestedXPWaypointInfo.y then return end
    if not RestedXPWaypointInfo.step or not RestedXPWaypointInfo.step.active then return end

    MapPin.NewUserNavigation({
        name = RestedXPWaypointInfo.name,
        mapID = RestedXPWaypointInfo.mapID,
        x = RestedXPWaypointInfo.x,
        y = RestedXPWaypointInfo.y,
        flags = "RestedXP_Waypoint",
        iconTexture = Path.Root .. "\\Art\\Icons\\TomTomArrow",
        requestRecolor = true
    })
end

local function RefreshSessionWaypoint()
    local arrow = RestedXP and RestedXP.arrowFrame
    local element = arrow and arrow.element
    local step = element and element.step
    if not IsModuleEnabled() or not arrow or not arrow:IsShown() or not step or not step.active or not element.zone or not element.x or not element.y then
        ResetWaypointInfo()
        return
    end

    local name = GetStepName(step)
    local waypointChanged = RestedXPWaypointInfo.step ~= step or RestedXPWaypointInfo.mapID ~= element.zone or RestedXPWaypointInfo.x ~= element.x or RestedXPWaypointInfo.y ~= element.y
    local nameChanged = RestedXPWaypointInfo.name ~= name

    RestedXPWaypointInfo.step = step
    RestedXPWaypointInfo.name = name
    RestedXPWaypointInfo.mapID = element.zone
    RestedXPWaypointInfo.x = element.x
    RestedXPWaypointInfo.y = element.y

    if not waypointChanged then
        if nameChanged and MapPin.IsUserNavigationFlagged("RestedXP_Waypoint") then
            local currentWaypoint = MapPin.GetUserNavigation()
            currentWaypoint.name = name
            MapPin.SetUserNavigation(currentWaypoint)
            CallbackRegistry.Trigger("MapPin.NewUserNavigation", currentWaypoint, { suppressPathfinding = true })
        end
        return
    end

    if Config.DBGlobal:GetVariable("RestedXPAutoReplaceWaypoint") == true or not C_SuperTrack.IsSuperTrackingAnything() or MapPin.IsUserNavigationFlagged("RestedXP_Waypoint") then
        SupportedAddons_RestedXP.PlaceWaypointAtSession()
    else
        WUISharedPrompt:Open(REPLACE_PROMPT_INFO, name)
    end
end

local function OnAddonLoad()
    RestedXP = LibStub("AceAddon-3.0"):GetAddon("RXPGuides", true)
    if not RestedXP or not RestedXP.arrowFrame then return end

    hooksecurefunc(RestedXP, "UpdateMap", RefreshSessionWaypoint)
    hooksecurefunc(RestedXP, "UpdateGotoSteps", RefreshSessionWaypoint)
    RestedXP.arrowFrame:HookScript("OnHide", function(self)
        if self:IsShown() then return end
        ResetWaypointInfo()
    end)

    SavedVariables.OnChange("WaypointDB_Global", "RestedXPSupportEnabled", RefreshSessionWaypoint)

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDONS_UNLOADING")
    f:SetScript("OnEvent", ResetWaypointInfo)

    RefreshSessionWaypoint()
end

SupportedAddons.Add("RXPGuides", OnAddonLoad)
