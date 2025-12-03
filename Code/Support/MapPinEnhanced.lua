local env               = select(2, ...)

local MPE_TRACKER_FRAME = MapPinEnhancedSuperTrackedPin
local MPE_DATABASE      = MapPinEnhancedDB
local CreateFrame       = CreateFrame
local pairs, ipairs     = pairs, ipairs

local Support           = env.WPM:Import("@/Support")
local MapPinEnhanced    = env.WPM:New("@/Support/MapPinEnhanced")


-- Setup
--------------------------------

function MapPinEnhanced.SetupEvents()
    MPE_TRACKER_FRAME:HookScript("OnShow", function()
        MPE_TRACKER_FRAME:Hide()
    end)
end

function MapPinEnhanced.GetReferences()
    if MPE_TRACKER_FRAME and MPE_DATABASE then return end

    MPE_TRACKER_FRAME = MapPinEnhancedSuperTrackedPin
    MPE_DATABASE      = MapPinEnhancedDB
end

--[[
	function NS:GetSets()
		for set, setContent in pairs(MPE_DATABASE.sets) do
			for pin, pinContent in pairs(setContent.pins) do
				-- Pin content
			end
		end
	end
]]

-- Setup
--------------------------------

local function OnAddonLoad()
    local EL = CreateFrame("Frame")
    EL:RegisterEvent("SUPER_TRACKING_CHANGED")
    EL:SetScript("OnEvent", function(self, event)
        if event == "SUPER_TRACKING_CHANGED" then
            MapPinEnhanced.GetReferences()
            MapPinEnhanced.SetupEvents()

            EL:Hide()
        end
    end)

end
Support.Add("MapPinEnhanced", OnAddonLoad)
