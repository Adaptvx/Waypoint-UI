---@class addon
local addon = select(2, ...)
local CallbackRegistry = addon.C.CallbackRegistry.Script
local PrefabRegistry = addon.C.PrefabRegistry.Script
local L = addon.C.AddonInfo.Locales
local NS = addon.C.AddonInfo; addon.C.AddonInfo = NS

--------------------------------

NS.Variables = NS.Variables or {}
NS.Variables.Config = {}

--------------------------------
-- VARIABLES
--------------------------------

do -- MAIN

end

do  -- CONSTANTS
	do -- REFERENCES
		NS.Variables.Config.TYPE_TAB = "Tab"
		NS.Variables.Config.TYPE_TITLE = "Title"
		NS.Variables.Config.TYPE_CONTAINER = "Container"
		NS.Variables.Config.TYPE_TEXT = "Text"
		NS.Variables.Config.TYPE_RANGE = "Range"
		NS.Variables.Config.TYPE_BUTTON = "Button"
		NS.Variables.Config.TYPE_CHECKBOX = "Checkbox"
		NS.Variables.Config.TYPE_DROPDOWN = "Dropdown"
		NS.Variables.Config.TYPE_COLOR = "Color"

		NS.Variables.Config.IMAGE_TYPE_LARGE = "Large"
		NS.Variables.Config.IMAGE_TYPE_SMALL = "Small"

		--------------------------------

		function NS.Variables.Config:NewDescriptor(imageType, imagePath, description)
			local descriptor = {
				["imageType"] = imageType,
				["imagePath"] = imagePath,
				["description"] = description,
			}

			return descriptor
		end
	end

	do -- CONSTRUCTOR
		--------------------------------
		-- Documentation
		--------------------------------

		-- 	local rangeValue = 0
		-- 	local checkboxValue = false
		-- 	local dropdownValue = 1
		-- 	local colorValue = { r = 1, g = 1, b = 1, a = 1 }

		-- 	NS.Variables.Config.TABLE = {
		-- 		[1] = {
		-- 			["name"] = "Placeholder",
		--  		["type"] = NS.Variables.Config.TYPE_TAB,
		-- 			["var_tab_footer"] = false,
		-- 			["elements"] = {
		-- 				[1] = {
		-- 					["name"] = "Placeholder",
		--  				["type"] = NS.Variables.Config.TYPE_TITLE,
		-- 					["var_title_imageTexture"] = addon.CREF:NewIcon("brush"),
		-- 					["var_title_text"] = "Placeholder",
		-- 					["var_title_subtext"] = "Placeholder",
		-- 				},
		-- 				[2] = {
		-- 					["name"] = "Placeholder",
		-- 					["type"] = NS.Variables.Config.TYPE_CONTAINER,
		-- 					["var_hidden"] = function() return false end,
		-- 					["elements"] = {
		-- 						[1] = {
		-- 							["name"] = "Text",
		-- 							["type"] = NS.Variables.Config.TYPE_TEXT,
		-- 							["descriptor"] = nil,
		-- 							["indent"] = 0,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 						[2] = {
		-- 							["name"] = "Range",
		-- 							["type"] = NS.Variables.Config.TYPE_RANGE,
		-- 							["descriptor"] = nil,
		-- 							["indent"] = 0,
		-- 							["var_range_min"] = 1,
		-- 							["var_range_max"] = 10,
		-- 							["var_range_step"] = 1,
		-- 							["var_range_text"] = function(value) return string.format("%.0f", value) end,
		-- 							["var_range_set_lazy"] = function(value) end,
		-- 							["var_get"] = function() return rangeValue end,
		-- 							["var_set"] = function(value) rangeValue = value end,
		-- 							["var_disabled"] = function() return false end,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 						[3] = {
		-- 							["name"] = "Button",
		-- 							["type"] = NS.Variables.Config.TYPE_BUTTON,
		-- 							["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, "Placeholder"),
		-- 							["indent"] = 0,
		-- 							["var_button_text"] = "Placeholder",
		-- 							["var_set"] = function() print("a") end,
		-- 							["var_disabled"] = function() return false end,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 						[4] = {
		-- 							["name"] = "Checkbox",
		-- 							["type"] = NS.Variables.Config.TYPE_CHECKBOX,
		-- 							["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, "Placeholder"),
		--  						["indent"] = 0,
		--  						["var_get"] = function() return checkboxValue end,
		--  						["var_set"] = function(value) checkboxValue = value end,
		-- 							["var_disabled"] = function() return false end,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 						[5] = {
		-- 							["name"] = "Dropdown",
		--  						["type"] = NS.Variables.Config.TYPE_DROPDOWN,
		--  						["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, "Placeholder"),
		-- 							["indent"] = 0,
		-- 							["var_dropdown_info"] = { "Option 1", "Option 2", "Option 3" },
		-- 							["var_get"] = function() return dropdownValue end,
		--  						["var_set"] = function(value) dropdownValue = value; return true end, -- Return true/false to close the context menu on option select
		--  						["var_disabled"] = function() return false end,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 						[6] = {
		-- 							["name"] = "Color",
		-- 							["type"] = NS.Variables.Config.TYPE_COLOR,
		-- 							["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, "Placeholder"),
		-- 							["indent"] = 0,
		-- 							["var_get"] = function() return colorValue end,
		-- 							["var_set"] = function(value) colorValue = value end,
		-- 							["var_disabled"] = function() return false end,
		-- 							["var_hidden"] = function() return false end,
		-- 						},
		-- 					}
		-- 				}
		-- 			}
		-- 		}
		-- 	}

		C_Timer.After(0, function()
			local NEW_PREFIX = addon.CREF:GetInlineIcon("star", 16) .. " "

			local function GetDatabase(name)
				if addon.C.Database and addon.C.Database.Variables then
					return addon.C.Database.Variables[name].profile
				end
			end

			local function GetDefault(db, name)
				if addon.C.Database and addon.C.Database.Variables then
					return addon.C.AddonInfo.Variables.Database[db].profile[name]
				end
			end

			local function ResetEntry(db, db_default, name)
				if addon.C.Database and addon.C.Database.Variables then
					GetDatabase(db)[name] = GetDefault(db_default, name)
				end
			end

			--------------------------------

			NS.Variables.Config.PRELOAD = function()
				addon.C.API.Util:Blizzard_AddConfirmPopup(
					"WAYPOINTUI_RESET_SETTING",
					L["Config - General - Reset - Confirm"],
					L["Config - General - Reset - Confirm - Yes"],
					L["Config - General - Reset - Confirm - No"],
					function()
						addon.C.Database.Script:ResetCache()
						ReloadUI()
					end,
					function()
						addon.C.API.Util:Blizzard_HidePopup("WAYPOINTUI_RESET_SETTING")
					end,
					true
				)
			end

			NS.Variables.Config.TABLE = {
				[1] = {
					["name"] = L["Config - General"],
					["type"] = NS.Variables.Config.TYPE_TAB,
					["var_tab_footer"] = false,
					["elements"] = {
						[1] = {
							["name"] = L["Config - General - Title"],
							["type"] = NS.Variables.Config.TYPE_TITLE,
							["var_title_imageTexture"] = addon.CREF:NewIcon("cog"),
							["var_title_text"] = L["Config - General - Title"],
							["var_title_subtext"] = L["Config - General - Title - Subtext"],
						},
						[2] = {
							["name"] = L["Config - General - Preferences"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - General - Preferences - Meter"],
									["type"] = NS.Variables.Config.TYPE_CHECKBOX,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - General - Preferences - Meter - Description"]),
									["indent"] = 0,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").PREF_METRIC = value end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						},
						[3] = {
							["name"] = L["Config - General - Reset"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,

							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = "",
									["type"] = NS.Variables.Config.TYPE_BUTTON,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_button_text"] = L["Config - General - Reset - Button"],
									["var_set"] = function() addon.C.API.Util:Blizzard_ShowPopup("WAYPOINTUI_RESET_SETTING") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						}
					}
				},
				[2] = {
					["name"] = L["Config - WaypointSystem"],
					["type"] = NS.Variables.Config.TYPE_TAB,
					["var_tab_footer"] = false,
					["elements"] = {
						[1] = {
							["name"] = L["Config - WaypointSystem - Title"],
							["type"] = NS.Variables.Config.TYPE_TITLE,
							["var_title_imageTexture"] = addon.CREF:NewIcon("waypoint"),
							["var_title_text"] = L["Config - WaypointSystem - Title"],
							["var_title_subtext"] = L["Config - WaypointSystem - Title - Subtext"],
						},
						[2] = {
							["name"] = nil,
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = true,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - WaypointSystem - Type"],
									["type"] = NS.Variables.Config.TYPE_DROPDOWN,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_dropdown_info"] = { L["Config - WaypointSystem - Type - Both"], L["Config - WaypointSystem - Type - Waypoint"], L["Config - WaypointSystem - Type - Pinpoint"] },
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_TYPE end,
									["var_set"] = function(value)
										GetDatabase("DB_GLOBAL").WS_TYPE = value; CallbackRegistry:Trigger("C_CONFIG_WS_TYPE"); return true
									end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end
								},
							}
						},
						[3] = {
							["name"] = L["Config - WaypointSystem - General"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - WaypointSystem - General - Transition Distance"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - WaypointSystem - General - Transition Distance - Description"]),
									["indent"] = 0,
									["var_range_min"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC and 55 or 50 end,
									["var_range_max"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC and 547 or 500 end,
									["var_range_step"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC and 5.47 or 5 end,
									["var_range_text"] = function(value) return string.format("%.0f", value * (GetDatabase("DB_GLOBAL").PREF_METRIC and .9144 or 1)) .. (GetDatabase("DB_GLOBAL").PREF_METRIC and "m" or " yds") end,
									["var_range_set_lazy"] = function(value) CallbackRegistry:Trigger("C_CONFIG_WS_DISTANCE_TRANSITION") end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_DISTANCE_TRANSITION end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_DISTANCE_TRANSITION = value end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return GetDatabase("DB_GLOBAL").WS_TYPE ~= 1 end,
								},
								[2] = {
									["name"] = L["Config - WaypointSystem - General - Hide Distance"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - WaypointSystem - General - Hide Distance - Description"]),
									["indent"] = 0,
									["var_range_min"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC and 1 or 1 end,
									["var_range_max"] = function() return GetDatabase("DB_GLOBAL").PREF_METRIC and 109 or 100 end,
									["var_range_step"] = 1,
									["var_range_text"] = function(value) return string.format("%.0f", value * (GetDatabase("DB_GLOBAL").PREF_METRIC and .9144 or 1)) .. (GetDatabase("DB_GLOBAL").PREF_METRIC and "m" or " yds") end,
									["var_range_set_lazy"] = function(value) CallbackRegistry:Trigger("C_CONFIG_WS_DISTANCE_HIDE") end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_DISTANCE_HIDE end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_DISTANCE_HIDE = value end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						},
						[4] = {
							["name"] = L["Config - WaypointSystem - Waypoint"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return GetDatabase("DB_GLOBAL").WS_TYPE ~= 1 and GetDatabase("DB_GLOBAL").WS_TYPE ~= 2 end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - WaypointSystem - Waypoint - Footer - Type"],
									["type"] = NS.Variables.Config.TYPE_DROPDOWN,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_dropdown_info"] = { L["Config - WaypointSystem - Waypoint - Footer - Type - Both"], L["Config - WaypointSystem - Waypoint - Footer - Type - Distance"], L["Config - WaypointSystem - Waypoint - Footer - Type - ETA"], L["Config - WaypointSystem - Waypoint - Footer - Type - None"] },
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_DISTANCE_TEXT_TYPE end,
									["var_set"] = function(value)
										GetDatabase("DB_GLOBAL").WS_DISTANCE_TEXT_TYPE = value; return true
									end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						},
						[5] = {
							["name"] = L["Config - WaypointSystem - Pinpoint"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return GetDatabase("DB_GLOBAL").WS_TYPE ~= 1 and GetDatabase("DB_GLOBAL").WS_TYPE ~= 3 end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - WaypointSystem - Pinpoint - Detail"],
									["type"] = NS.Variables.Config.TYPE_CHECKBOX,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - WaypointSystem - Pinpoint - Detail - Description"]),
									["indent"] = 0,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_PINPOINT_DETAIL end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_PINPOINT_DETAIL = value end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						}
					}
				},
				[3] = {
					["name"] = L["Config - Appearance"],
					["type"] = NS.Variables.Config.TYPE_TAB,
					["var_tab_footer"] = false,
					["elements"] = {
						[1] = {
							["name"] = L["Config - Appearance - Title"],
							["type"] = NS.Variables.Config.TYPE_TITLE,
							["var_title_imageTexture"] = addon.CREF:NewIcon("brush"),
							["var_title_text"] = L["Config - Appearance - Title"],
							["var_title_subtext"] = L["Config - Appearance - Title - Subtext"],
						},
						[2] = {
							["name"] = L["Config - Appearance - Waypoint"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - Appearance - Waypoint - Scale"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - Appearance - Waypoint - Scale - Description"]),
									["indent"] = 0,
									["var_range_min"] = .5,
									["var_range_max"] = 5,
									["var_range_step"] = .1,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_WAYPOINT_SCALE end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_WAYPOINT_SCALE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								},
								[2] = {
									["name"] = L["Config - Appearance - Waypoint - Scale - Min"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - Appearance - Waypoint - Scale - Min - Description"]),
									["indent"] = 1,
									["var_range_min"] = .125,
									["var_range_max"] = 1,
									["var_range_step"] = .125,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_WAYPOINT_MIN_SCALE end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_WAYPOINT_MIN_SCALE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								},
								[3] = {
									["name"] = L["Config - Appearance - Waypoint - Scale - Max"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Config - Appearance - Waypoint - Scale - Max - Description"]),
									["indent"] = 1,
									["var_range_min"] = 1,
									["var_range_max"] = 2,
									["var_range_step"] = .1,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_WAYPOINT_MAX_SCALE end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_WAYPOINT_MAX_SCALE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								},
								[4] = {
									["name"] = L["Config - Appearance - Waypoint - Beam"],
									["type"] = NS.Variables.Config.TYPE_CHECKBOX,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_WAYPOINT_BEAM end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_WAYPOINT_BEAM = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								},
								[5] = {
									["name"] = L["Config - Appearance - Waypoint - Beam - Alpha"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = nil,
									["indent"] = 1,
									["var_range_min"] = .1,
									["var_range_max"] = 1,
									["var_range_step"] = .1,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_WAYPOINT_BEAM_ALPHA end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_WAYPOINT_BEAM_ALPHA = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_WAYPOINT_BEAM end,
								},
								[6] = {
									["name"] = L["Config - Appearance - Waypoint - Footer - Alpha"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_range_min"] = 0,
									["var_range_max"] = 1,
									["var_range_step"] = .1,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_DISTANCE_TEXT_ALPHA end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_DISTANCE_TEXT_ALPHA = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return GetDatabase("DB_GLOBAL").WS_DISTANCE_TEXT_TYPE == 4 end,
								}
							}
						},
						[3] = {
							["name"] = L["Config - Appearance - Pinpoint"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - Appearance - Pinpoint - Scale"],
									["type"] = NS.Variables.Config.TYPE_RANGE,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_range_min"] = .5,
									["var_range_max"] = 2,
									["var_range_step"] = .1,
									["var_range_text"] = function(value) return string.format("%.0f", value * 100) .. "%" end,
									["var_range_set_lazy"] = function(value) end,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").WS_PINPOINT_SCALE end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").WS_PINPOINT_SCALE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						},
						[4] = {
							["name"] = L["Config - Appearance - Visual"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor"],
									["type"] = NS.Variables.Config.TYPE_CHECKBOX,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								},
								[2] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Default"],
									["type"] = NS.Variables.Config.TYPE_CONTAINER,
									["var_subcontainer"] = true,
									["var_transparent"] = false,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
									["elements"] = {
										[1] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - Color"],
											["type"] = NS.Variables.Config.TYPE_COLOR,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return false end,
										},
										[2] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - TintIcon"],
											["type"] = NS.Variables.Config.TYPE_CHECKBOX,
											["descriptor"] = nil,
											["indent"] = 1,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_TINT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_TINT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										},
										[3] = {
											["name"] = "",
											["type"] = NS.Variables.Config.TYPE_BUTTON,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_button_text"] = L["Config - Appearance - Visual - UseCustomColor - Reset"],
											["var_set"] = function() ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE"); ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE_TINT"); CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										}
									}
								},
								[3] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Repeatable"],
									["type"] = NS.Variables.Config.TYPE_CONTAINER,
									["var_subcontainer"] = true,
									["var_transparent"] = false,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
									["elements"] = {
										[1] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - Color"],
											["type"] = NS.Variables.Config.TYPE_COLOR,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_REPEATABLE end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_REPEATABLE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return false end,
										},
										[2] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - TintIcon"],
											["type"] = NS.Variables.Config.TYPE_CHECKBOX,
											["descriptor"] = nil,
											["indent"] = 1,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										},
										[3] = {
											["name"] = "",
											["type"] = NS.Variables.Config.TYPE_BUTTON,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_button_text"] = L["Config - Appearance - Visual - UseCustomColor - Reset"],
											["var_set"] = function() ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE_REPEATABLE"); ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT"); CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										}
									}
								},
								[4] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Important"],
									["type"] = NS.Variables.Config.TYPE_CONTAINER,
									["var_subcontainer"] = true,
									["var_transparent"] = false,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
									["elements"] = {
										[1] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - Color"],
											["type"] = NS.Variables.Config.TYPE_COLOR,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_IMPORTANT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_IMPORTANT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return false end,
										},
										[2] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - TintIcon"],
											["type"] = NS.Variables.Config.TYPE_CHECKBOX,
											["descriptor"] = nil,
											["indent"] = 1,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										},
										[3] = {
											["name"] = "",
											["type"] = NS.Variables.Config.TYPE_BUTTON,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_button_text"] = L["Config - Appearance - Visual - UseCustomColor - Reset"],
											["var_set"] = function() ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE_IMPORTANT"); ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT"); CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										}
									}
								},
								[5] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor - Quest - Incomplete"],
									["type"] = NS.Variables.Config.TYPE_CONTAINER,
									["var_subcontainer"] = true,
									["var_transparent"] = false,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
									["elements"] = {
										[1] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - Color"],
											["type"] = NS.Variables.Config.TYPE_COLOR,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_INCOMPLETE end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_INCOMPLETE = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return false end,
										},
										[2] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - TintIcon"],
											["type"] = NS.Variables.Config.TYPE_CHECKBOX,
											["descriptor"] = nil,
											["indent"] = 1,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_INCOMPLETE_TINT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_QUEST_INCOMPLETE_TINT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										},
										[3] = {
											["name"] = "",
											["type"] = NS.Variables.Config.TYPE_BUTTON,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_button_text"] = L["Config - Appearance - Visual - UseCustomColor - Reset"],
											["var_set"] = function() ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_INCOMPLETE"); ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_QUEST_INCOMPLETE_TINT"); CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										}
									}
								},
								[6] = {
									["name"] = L["Config - Appearance - Visual - UseCustomColor - Neutral"],
									["type"] = NS.Variables.Config.TYPE_CONTAINER,
									["var_subcontainer"] = true,
									["var_transparent"] = false,
									["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
									["elements"] = {
										[1] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - Color"],
											["type"] = NS.Variables.Config.TYPE_COLOR,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_NEUTRAL end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_NEUTRAL = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return false end,
										},
										[2] = {
											["name"] = L["Config - Appearance - Visual - UseCustomColor - TintIcon"],
											["type"] = NS.Variables.Config.TYPE_CHECKBOX,
											["descriptor"] = nil,
											["indent"] = 1,
											["var_get"] = function() return GetDatabase("DB_GLOBAL").APP_COLOR_NEUTRAL_TINT end,
											["var_set"] = function(value) GetDatabase("DB_GLOBAL").APP_COLOR_NEUTRAL_TINT = value; CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										},
										[3] = {
											["name"] = "",
											["type"] = NS.Variables.Config.TYPE_BUTTON,
											["descriptor"] = nil,
											["indent"] = 0,
											["var_button_text"] = L["Config - Appearance - Visual - UseCustomColor - Reset"],
											["var_set"] = function() ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_NEUTRAL"); ResetEntry("DB_GLOBAL", "GLOBAL_DEFAULT", "APP_COLOR_NEUTRAL_TINT"); CallbackRegistry:Trigger("C_CONFIG_APPEARANCE_UPDATE") end,
											["var_disabled"] = function() return false end,
											["var_hidden"] = function() return not GetDatabase("DB_GLOBAL").APP_COLOR end,
										}
									}
								}
							}
						}
					}
				},
				[4] = {
					["name"] = L["Config - Audio"],
					["type"] = NS.Variables.Config.TYPE_TAB,
					["var_tab_footer"] = false,
					["elements"] = {
						[1] = {
							["name"] = L["Config - Audio - Title"],
							["type"] = NS.Variables.Config.TYPE_TITLE,
							["var_title_imageTexture"] = addon.CREF:NewIcon("speaker-on"),
							["var_title_text"] = L["Config - Audio - Title"],
							["var_title_subtext"] = L["Config - Audio - Title - Subtext"],
						},
						[2] = {
							["name"] = L["Config - Audio - General"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = false,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - Audio - General - EnableGlobalAudio"],
									["type"] = NS.Variables.Config.TYPE_CHECKBOX,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_get"] = function() return GetDatabase("DB_GLOBAL").AUDIO_GLOBAL end,
									["var_set"] = function(value) GetDatabase("DB_GLOBAL").AUDIO_GLOBAL = value end,
									["var_disabled"] = function() return false end,
									["var_hidden"] = function() return false end,
								}
							}
						}
					}
				},
				[5] = {
					["name"] = L["Config - About"],
					["type"] = NS.Variables.Config.TYPE_TAB,
					["var_tab_footer"] = true,
					["elements"] = {
						[1] = {
							["name"] = L["Config - About"],
							["type"] = NS.Variables.Config.TYPE_TITLE,
							["var_title_imageTexture"] = addon.C.AddonInfo.Variables.General.ADDON_ICON_ALT,
							["var_title_text"] = addon.CREF:GetAddonName(),
							["var_title_subtext"] = addon.CREF:GetAddonVersionString(),
						},
						[2] = {
							["name"] = L["Config - About - Contributors"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = true,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Contributors - ZamestoTV"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Contributors - ZamestoTV - Description"]),
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								},
								[2] = {
									["name"] = L["Contributors - huchang47"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Contributors - huchang47 - Description"]),
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								},
								[3] = {
									["name"] = L["Contributors - BlueNightSky"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Contributors - BlueNightSky - Description"]),
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								},
								[4] = {
									["name"] = L["Contributors - Crazyyoungs"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Contributors - Crazyyoungs - Description"]),
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								},
								[5] = {
									["name"] = L["Contributors - y45853160"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = NS.Variables.Config:NewDescriptor(nil, nil, L["Contributors - y45853160 - Description"]),
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								}
							}
						},
						[3] = {
							["name"] = L["Config - About - Developer"],
							["type"] = NS.Variables.Config.TYPE_CONTAINER,
							["var_subcontainer"] = false,
							["var_transparent"] = true,
							["var_hidden"] = function() return false end,
							["elements"] = {
								[1] = {
									["name"] = L["Config - About - Developer - AdaptiveX"],
									["type"] = NS.Variables.Config.TYPE_TEXT,
									["descriptor"] = nil,
									["indent"] = 0,
									["var_transparent"] = true,
									["var_hidden"] = function() return false end,
								}
							}
						}
					}
				}
			}
		end)
	end
end
