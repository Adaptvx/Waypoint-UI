local addonName, env = ...

local CreateFrame = CreateFrame
local GetTime = GetTime

local CallbackRegistry = env.WPM:Import("wpm_modules\\callback-registry")
local WoWClient_Events = env.WPM:New("wpm_modules\\wow-client\\events")


-- Events
----------------------------------------------------------------------------------------------------

do -- UI Scale Changed
    local lastChangedTime = 0
    local thresholdToClassifyAsEnd = 0.25

    local awaitScaleEnd = CreateFrame("Frame")
    awaitScaleEnd:SetScript("OnUpdate", function()
        if GetTime() < lastChangedTime + thresholdToClassifyAsEnd then return end
        awaitScaleEnd:Hide()
        CallbackRegistry.Trigger("WoWClient.OnUIScaleChanged")
    end)

    local f = CreateFrame("Frame")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:SetScript("OnEvent", function(self, event, ...)
        lastChangedTime = GetTime()
        awaitScaleEnd:Show()
    end)
end

do -- Addon Loaded
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local name = ...
            if name == addonName then
                CallbackRegistry.Trigger("WoWClient.OnAddonLoaded")
            end
        end
    end)
end

do -- Mouse
    WoWClient_Events.IsPlayerTurning = false
    WoWClient_Events.IsPlayerLooking = false

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_STARTED_LOOKING")
    f:RegisterEvent("PLAYER_STOPPED_LOOKING")
    f:RegisterEvent("PLAYER_STARTED_TURNING")
    f:RegisterEvent("PLAYER_STOPPED_TURNING")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_STARTED_TURNING" or event == "PLAYER_STOPPED_TURNING" then
            WoWClient_Events.IsPlayerTurning = (event == "PLAYER_STARTED_TURNING")
        end
        if event == "PLAYER_STARTED_MOVING" or event == "PLAYER_STOPPED_MOVING" then
            WoWClient_Events.IsPlayerLooking = (event == "PLAYER_STARTED_MOVING")
        end
    end)
end
