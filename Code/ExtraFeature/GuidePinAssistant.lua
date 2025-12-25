local env                     = select(2, ...)
local L                       = env.L
local Config                  = env.Config

local IsSuperTrackingAnything = C_SuperTrack.IsSuperTrackingAnything
local SetCVar                 = SetCVar
local GetCVar                 = GetCVar

local CallbackRegistry        = env.WPM:Import("wpm_modules\\callback-registry")
local SavedVariables          = env.WPM:Import("wpm_modules\\saved-variables")
local MapPin                  = env.WPM:Import("@\\MapPin")


-- Helpers
----------------------------------------------------------------------------------------------------

local cachedSFXVolume = nil
local cachedGuidePin = nil

local function ShowGuidePin()
    if not cachedGuidePin then return end
    cachedGuidePin:SetAlpha(1)
end

local function HideGuidePin()
    if not cachedGuidePin then return end
    cachedGuidePin:SetAlpha(0)
end

local function PlaceUserNavigationAtGuidePin()
    if not cachedGuidePin then return end
    MapPin.NewUserNavigation(cachedGuidePin.name, C_Map.GetBestMapForUnit("player"), cachedGuidePin.normalizedX * 100, cachedGuidePin.normalizedY * 100, "GuidePin")
    HideGuidePin()
end

local function MuteSFXChannel()
    SetCVar("Sound_SFXVolume", 0)
end

local function UnmuteSFXChannel()
    SetCVar("Sound_SFXVolume", cachedSFXVolume or 1)
end

local function LocateGuidePin()
    -- Refresh pins by opening and immediately closing WorldMapFrame
    local isWorldMapVisible = WorldMapFrame:IsVisible()
    cachedSFXVolume = GetCVar("Sound_SFXVolume")

    if not isWorldMapVisible then
        MuteSFXChannel()

        WorldMapFrame:Show()
        WorldMapFrame:Hide()

        C_Timer.After(0.5, UnmuteSFXChannel)
    end

    -- Locate GossipPinTemplate aka Guide pin
    for pin in WorldMapFrame:EnumeratePinsByTemplate("GossipPinTemplate") do
        cachedGuidePin = pin
        return pin
    end

    return nil
end


-- Shared
----------------------------------------------------------------------------------------------------

local function HandleAccept()
    PlaceUserNavigationAtGuidePin()
end

local function HandleCancel()
    ShowGuidePin()
end

local REPLACE_PROMPT_INFO = {
    text         = L["Guide Pin Assistant - ReplacePrompt"],
    options      = {
        {
            text     = L["Guide Pin Assistant - ReplacePrompt - Yes"],
            callback = HandleAccept
        },
        {
            text     = L["Guide Pin Assistant - ReplacePrompt - No"],
            callback = HandleCancel
        }
    },
    hideOnEscape = true,
    timeout      = 10
}


-- Events
----------------------------------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("DYNAMIC_GOSSIP_POI_UPDATED")
f:SetScript("OnEvent", function(self, event)
    if not LocateGuidePin() then return end
    if not cachedGuidePin then return end

    if not IsSuperTrackingAnything() then
        PlaceUserNavigationAtGuidePin()
    else
        WUISharedPrompt:Open(REPLACE_PROMPT_INFO, cachedGuidePin.name)
    end
end)


-- Settings
----------------------------------------------------------------------------------------------------

local function UpdateToMatchSetting()
    local Setting_GuidePinAssistantEnabled = Config.DBGlobal:GetVariable("GuidePinAssistantEnabled")
    if Setting_GuidePinAssistantEnabled then
        f:RegisterEvent("DYNAMIC_GOSSIP_POI_UPDATED")
    else
        f:UnregisterEvent("DYNAMIC_GOSSIP_POI_UPDATED")
    end
end

SavedVariables.OnChange("WaypointDB_Global", "GuidePinAssistantEnabled", UpdateToMatchSetting)
CallbackRegistry.Add("Preload.DatabaseReady", UpdateToMatchSetting)
