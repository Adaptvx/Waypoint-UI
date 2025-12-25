local env                             = select(2, ...)
local Support                         = env.WPM:Import("@\\Support")
local Support_UnlimitedMapPinDistance = env.WPM:New("@\\Support\\UnlimitedMapPinDistance")


-- Helpers
----------------------------------------------------------------------------------------------------

local function HideUMPDFrame()
    assert(SuperTrackedFrame.Time, "Invalid variable `SuperTrackedFrame.Time`")

    SuperTrackedFrame.Time:SetParent(nil)
    SuperTrackedFrame.Time:ClearAllPoints()
end


-- Setup
----------------------------------------------------------------------------------------------------

local function OnAddonLoad()
    HideUMPDFrame()
end
Support.Add("UnlimitedMapPinDistance", OnAddonLoad)
