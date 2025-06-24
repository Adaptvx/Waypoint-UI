---@class addon
local addon = select(2, ...)
local NS = addon.C.AddonInfo; addon.C.AddonInfo = NS

--------------------------------

NS.Variables = NS.Variables or {}
NS.Variables.Database = {}

--------------------------------
-- VARIABLES
--------------------------------

do -- MAIN

end

do -- CONSTANTS
	do -- REFERENCES
		NS.Variables.Database.GLOBAL_REFERENCE = WaypointDB_Global
		NS.Variables.Database.LOCAL_REFERENCE = WaypointDB_Local
		NS.Variables.Database.GLOBAL_PERSISTENT_REFERENCE = WaypointDB_Global_Persistent
		NS.Variables.Database.LOCAL_PERSISTENT_REFERENCE = WaypointDB_Local_Persistent

		NS.Variables.Database.GLOBAL_NAME = "WaypointDB_Global"
		NS.Variables.Database.LOCAL_NAME = "WaypointDB_Local"
		NS.Variables.Database.GLOBAL_PERSISTENT_NAME = "WaypointDB_Global_Persistent"
		NS.Variables.Database.LOCAL_PERSISTENT_NAME = "WaypointDB_Local_Persistent"
	end

	do -- DEFAULTS
		NS.Variables.Database.GLOBAL_DEFAULT = {
			profile = {
				-- WAYPOINT SYSTEM
				WS_TYPE = 1,
				WS_DISTANCE_TRANSITION = 225,
				WS_DISTANCE_HIDE = 25,
				WS_DISTANCE_TEXT_TYPE = 2,
				WS_DISTANCE_TEXT_ALPHA = .5,

				WS_WAYPOINT_SCALE = 1,
				WS_WAYPOINT_MIN_SCALE = .25,
				WS_WAYPOINT_MAX_SCALE = 1.5,
				WS_PINPOINT_SCALE = 1,
				WS_PINPOINT_DETAIL = false,

				-- APPEARANCE
				APP_WAYPOINT_BEAM = true,
				APP_WAYPOINT_BEAM_ALPHA = 1,
				APP_COLOR = false,
				APP_COLOR_QUEST_INCOMPLETE_TINT = false,
				APP_COLOR_QUEST_INCOMPLETE = { r = addon.CREF:GetSharedColor().RGB_PING_QUEST_NEUTRAL.r, g = addon.CREF:GetSharedColor().RGB_PING_QUEST_NEUTRAL.g, b = addon.CREF:GetSharedColor().RGB_PING_QUEST_NEUTRAL.b, a = 1 },
				APP_COLOR_QUEST_COMPLETE_TINT = false,
				APP_COLOR_QUEST_COMPLETE = { r = addon.CREF:GetSharedColor().RGB_PING_QUEST_NORMAL.r, g = addon.CREF:GetSharedColor().RGB_PING_QUEST_NORMAL.g, b = addon.CREF:GetSharedColor().RGB_PING_QUEST_NORMAL.b, a = 1 },
				APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT = false,
				APP_COLOR_QUEST_COMPLETE_REPEATABLE = { r = addon.CREF:GetSharedColor().RGB_PING_QUEST_REPEATABLE.r, g = addon.CREF:GetSharedColor().RGB_PING_QUEST_REPEATABLE.g, b = addon.CREF:GetSharedColor().RGB_PING_QUEST_REPEATABLE.b, a = 1 },
				APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT = false,
				APP_COLOR_QUEST_COMPLETE_IMPORTANT = { r = addon.CREF:GetSharedColor().RGB_PING_QUEST_IMPORTANT.r, g = addon.CREF:GetSharedColor().RGB_PING_QUEST_IMPORTANT.g, b = addon.CREF:GetSharedColor().RGB_PING_QUEST_IMPORTANT.b, a = 1 },
				APP_COLOR_NEUTRAL_TINT = true,
				APP_COLOR_NEUTRAL = { r = addon.CREF:GetSharedColor().RGB_PING_NEUTRAL.r, g = addon.CREF:GetSharedColor().RGB_PING_NEUTRAL.g, b = addon.CREF:GetSharedColor().RGB_PING_NEUTRAL.b , a = 1 },

				-- AUDIO
				AUDIO_GLOBAL = true,

				-- PREFERENCES
				PREF_METRIC = false,
			},
		}

		NS.Variables.Database.LOCAL_DEFAULT = {
			profile = {

			}
		}

		NS.Variables.Database.GLOBAL_PERSISTENT_DEFAULT = {
			profile = {

			}
		}

		NS.Variables.Database.LOCAL_PERSISTENT_DEFAULT = {
			profile = {
				SAVED_WAY = nil
			}
		}
	end
end
