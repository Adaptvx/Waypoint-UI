---@class addon
local addon = select(2, ...)
local CallbackRegistry = addon.C.CallbackRegistry.Script
local PrefabRegistry = addon.C.PrefabRegistry.Script
local L = addon.C.AddonInfo.Locales
local NS = addon.WaypointSystem; addon.WaypointSystem = NS

--------------------------------

NS.Variables = {}

--------------------------------

function NS.Variables:Load()
	--------------------------------
	-- VARIABLES
	--------------------------------

	do -- CONSTANTS
		do -- SCALE
			NS.Variables.RATIO_REFERENCE = 1000

			--------------------------------

			do -- FUNCTIONS
				function NS.Variables:RATIO(level)
					return NS.Variables.RATIO_REFERENCE / addon.C.Variables:RAW_RATIO(level)
				end
			end
		end

		do -- MAIN
			NS.Variables.PATH = addon.CREF:GetAddonPathElement() .. "Waypoint/"
			NS.Variables.PADDING = 10
			NS.Variables.DEFAULT_HEIGHT = 125
			NS.Variables.BLOCKED_HEIGHT = 75
			NS.Variables.ANIMATION_HEIGHT = 25

			NS.Variables.FRAME_STRATA = "BACKGROUND"
			NS.Variables.FRAME_LEVEL = 99
			NS.Variables.FRAME_LEVEL_MAX = 999
		end
	end

	do -- MAIN
		NS.Variables.ArrivalTime = nil
		NS.Variables.Session = {
			["isInInstance"] = nil,
			["state"] = nil,
			["lastState"] = nil,
			["id"] = nil,
			["quest"] = nil,
			["questContextIcon"] = nil,
		}
	end

	--------------------------------
	-- EVENTS
	--------------------------------
end
