--[[
    widgetName:                         string
    widgetDecsription:                  SettingDefine.Descriptor
    widgetType:                         SettingEnum.WidgetType
    widgetTransparent:                  boolean

    Shared:
        key:                            string
        set:                            function

    Tab:
        widgetTab_isFooter:             boolean

    Title:
        widgetTitle_info:               SettingDefine.TitleInfo

    Container:
        widgetContainer_isNested:       boolean

    Text:

    Range:
        widgetRange_min:                number|function
        widgetRange_max:                number|function
        widgetRange_step:               number|function
        widgetRange_textFormatting      string (%s: value)
        widgetRange_textFormattingFunc: function

    Button:
        widgetButton_text:              string
        widgetButton_refreshOnClick:    boolean

    Checkbox:

    SelectionMenu:
        widgetSelectionMenu_data:       table|function

    Color Input:

    Input:
        widgetInput_placeholder:        string|function

    disableWhen:                        function
    showWhen:                           function
    indent:                             number
    children:                           table
]]


local env              = select(2, ...)
local Config           = env.Config
local L                = env.L

local Path             = env.WPM:Import("wpm_modules/path")
local Utils_Blizzard   = env.WPM:Import("wpm_modules/utils/blizzard")
local Sound            = env.WPM:Import("wpm_modules/sound")
local CallbackRegistry = env.WPM:Import("wpm_modules/callback-registry")
local UIFont           = env.WPM:Import("wpm_modules/ui-font")
local LocalUtil        = env.WPM:Import("@/LocalUtil")
local WaypointEnum     = env.WPM:Import("@/Waypoint/Enum")
local SettingDefine    = env.WPM:Import("@/Setting/Define")
local SettingEnum      = env.WPM:Import("@/Setting/Enum")
local SettingSchema    = env.WPM:New("@/Setting/Schema")




local function handleOnAccept()
    Config.DBGlobal:Wipe()
    ReloadUI()
end

local function handleOnCancel()
    Utils_Blizzard:HidePopup("WAYPOINTUI_RESET_SETTING")
end

Utils_Blizzard:NewConfirmPopup{
    id             = "WAYPOINTUI_RESET_SETTING",
    text           = L["Config - General - Other - ResetPrompt"],
    button1Text    = L["Config - General - Other - ResetPrompt - Yes"],
    button2Text    = L["Config - General - Other - ResetPrompt - No"],
    acceptCallback = handleOnAccept,
    cancelCallback = handleOnCancel,
    hideOnEscape   = true
}




local function alwaysTrue() return true end
local function alwaysFalse() return false end
local function calculateDistance(yds) return function() return LocalUtil:CalculateDistance(yds) end end
local function formatDistance(value) return LocalUtil:FormatDistance(value) end
local function formatPercentage(value) return string.format("%.0f", value * 100) .. "%" end
local function getIcon(name) return Path.Root .. "/Art/Setting/Icon/" .. name .. ".png" end


SettingSchema.SCHEMA = {
    {
        widgetName = L["Config - General"],
        widgetType = SettingEnum.WidgetType.Tab,
        children   = {
            {
                widgetName       = L["Config - General - Title"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = getIcon("Cog"), text = L["Config - General - Title"], subtext = L["Config - General - Title - Subtext"] }
            },
            {
                widgetName = L["Config - General - Preferences"],
                widgetType = SettingEnum.WidgetType.Container,
                children   = {
                    {
                        widgetName               = L["Config - General - Preferences - Font"],
                        widgetType               = SettingEnum.WidgetType.SelectionMenu,
                        widgetSelectionMenu_data = function()
                            UIFont.CustomFont:RefreshFontList()
                            return UIFont.CustomFont:GetFontNames()
                        end,
                        key                      = "PrefFont"
                    },
                    {
                        widgetName        = L["Config - General - Preferences - Meter"],
                        widgetDescription = SettingDefine.Descriptor{ imageType = nil, imagePath = nil, description = L["Config - General - Preferences - Meter - Description"] },
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        key               = "PrefMetric"
                    }
                }
            },
            {
                widgetName = L["Config - General - Other"],
                widgetType = SettingEnum.WidgetType.Container,
                children   = {
                    {
                        widgetName        = nil,
                        widgetType        = SettingEnum.WidgetType.Button,
                        widgetButton_text = L["Config - General - Other - ResetButton"],
                        set               = function() Utils_Blizzard:ShowPopup("WAYPOINTUI_RESET_SETTING") end
                    }
                }
            }
        }
    },
    {
        widgetName = L["Config - WaypointSystem"],
        widgetType = SettingEnum.WidgetType.Tab,
        children   = {
            {
                widgetName       = L["Config - WaypointSystem - Title"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = getIcon("Waypoint"), text = L["Config - WaypointSystem - Title"], subtext = L["Config - WaypointSystem - Title - Subtext"] }
            },
            {

                widgetType               = SettingEnum.WidgetType.SelectionMenu,
                widgetTransparent        = true,
                widgetSelectionMenu_data = {
                    L["Config - WaypointSystem - Type - Both"],
                    L["Config - WaypointSystem - Type - Waypoint"],
                    L["Config - WaypointSystem - Type - Pinpoint"]
                },
                key                      = "WaypointSystemType"
            },
            {
                widgetName = L["Config - WaypointSystem - General"],
                widgetType = SettingEnum.WidgetType.Container,
                children   = {
                    {
                        widgetName        = L["Config - WaypointSystem - General - AlwaysShow"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - General - AlwaysShow - Description"] },
                        key               = "AlwaysShow"
                    },
                    {
                        widgetName        = L["Config - WaypointSystem - General - RightClickToClear"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - General - RightClickToClear - Description"] },
                        key               = "RightClickToClear"
                    },
                    {
                        widgetName        = L["Config - WaypointSystem - General - BackgroundPreview"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - General - BackgroundPreview - Description"] },
                        key               = "BackgroundPreview"
                    },
                    {
                        widgetName                     = L["Config - WaypointSystem - General - Transition Distance"],
                        widgetDescription              = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - General - Transition Distance - Description"] },
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetRange_min                = calculateDistance(50),
                        widgetRange_max                = calculateDistance(500),
                        widgetRange_step               = calculateDistance(5),
                        widgetRange_textFormattingFunc = formatDistance,
                        key                            = "DistanceThresholdPinpoint",
                        showWhen                       = function() return Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.All end
                    },
                    {
                        widgetName                     = L["Config - WaypointSystem - General - Hide Distance"],
                        widgetDescription              = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - General - Hide Distance - Description"] },
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetRange_min                = calculateDistance(1),
                        widgetRange_max                = calculateDistance(100),
                        widgetRange_step               = 1,
                        widgetRange_textFormattingFunc = formatDistance,
                        key                            = "DistanceThresholdHidden"
                    }
                }
            },
            {
                widgetName = L["Config - WaypointSystem - Waypoint"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.All or Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.Waypoint end,
                children   = {
                    {
                        widgetName               = L["Config - WaypointSystem - Waypoint - Footer - Type"],
                        widgetType               = SettingEnum.WidgetType.SelectionMenu,
                        widgetSelectionMenu_data = {
                            L["Config - WaypointSystem - Waypoint - Footer - Type - Both"],
                            L["Config - WaypointSystem - Waypoint - Footer - Type - Distance"],
                            L["Config - WaypointSystem - Waypoint - Footer - Type - ETA"],
                            L["Config - WaypointSystem - Waypoint - Footer - Type - None"]
                        },
                        key                      = "WaypointDistanceTextType"
                    }
                }
            },
            {
                widgetName = L["Config - WaypointSystem - Pinpoint"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.All or Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.Pinpoint end,
                children   = {
                    {
                        widgetName = L["Config - WaypointSystem - Pinpoint - Info"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "PinpointInfo"
                    },
                    {
                        widgetName        = L["Config - WaypointSystem - Pinpoint - Info - Extended"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - Pinpoint - Info - Extended - Description"] },
                        indent            = 1,
                        key               = "PinpointInfoExtended",
                        showWhen          = function() return Config.DBGlobal:GetVariable("PinpointInfo") == true end
                    },
                    {
                        widgetName        = L["Config - WaypointSystem - Pinpoint - ShowInQuestArea"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - Pinpoint - ShowInQuestArea - Description"] },
                        key               = "PinpointAllowInQuestArea"
                    }
                }
            },
            {
                widgetName = L["Config - WaypointSystem - Navigator"],
                widgetType = SettingEnum.WidgetType.Container,
                children   = {
                    {
                        widgetName        = L["Config - WaypointSystem - Navigator - Enable"],
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - WaypointSystem - Navigator - Enable - Description"] },
                        indent            = 0,
                        key               = "NavigatorShow"
                    }
                }
            }
        }
    },
    {
        widgetName = L["Config - Appearance"],
        widgetType = SettingEnum.WidgetType.Tab,
        children   = {
            {
                widgetName       = L["Config - Appearance - Title"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = getIcon("Brush"), text = L["Config - Appearance - Title"], subtext = L["Config - Appearance - Title - Subtext"] }
            },
            {
                widgetName = L["Config - Appearance - Waypoint"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.Waypoint or Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.All end,
                children   = {
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Scale"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetDescription              = SettingDefine.Descriptor{ description = L["Config - Appearance - Waypoint - Scale - Description"] },
                        widgetRange_min                = .5,
                        widgetRange_max                = 5,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointScale"
                    },
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Scale - Min"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetDescription              = SettingDefine.Descriptor{ description = L["Config - Appearance - Waypoint - Scale - Min - Description"] },
                        widgetRange_min                = .125,
                        widgetRange_max                = 1,
                        widgetRange_step               = .125,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointScaleMin",
                        indent                         = 1
                    },
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Scale - Max"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetDescription              = SettingDefine.Descriptor{ description = L["Config - Appearance - Waypoint - Scale - Max - Description"] },
                        widgetRange_min                = 1,
                        widgetRange_max                = 2,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointScaleMax",
                        indent                         = 1
                    },
                    {
                        widgetName = L["Config - Appearance - Waypoint - Beam"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "WaypointBeam"
                    },
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Beam - Alpha"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        showWhen                       = function()
                            return Config.DBGlobal:GetVariable("WaypointBeam") ==
                                true
                        end,
                        indent                         = 1,
                        widgetRange_min                = .1,
                        widgetRange_max                = 1,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointBeamAlpha"
                    },
                    {
                        widgetName = L["Config - Appearance - Waypoint - Footer"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "WaypointDistanceText",
                        showWhen   = function() return Config.DBGlobal:GetVariable("waypointwaypointDistanceTextType") ~= WaypointEnum.WaypointDistanceTextType.None end
                    },
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Footer - Scale"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        showWhen                       = function() return Config.DBGlobal:GetVariable("WaypointDistanceText") == true and Config.DBGlobal:GetVariable("waypointwaypointDistanceTextType") ~= WaypointEnum.WaypointDistanceTextType.None end,
                        indent                         = 1,
                        widgetRange_min                = .1,
                        widgetRange_max                = 2,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointDistanceTextScale"
                    },
                    {
                        widgetName                     = L["Config - Appearance - Waypoint - Footer - Alpha"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        showWhen                       = function() return Config.DBGlobal:GetVariable("WaypointDistanceText") == true and Config.DBGlobal:GetVariable("waypointwaypointDistanceTextType") ~= WaypointEnum.WaypointDistanceTextType.None end,
                        indent                         = 1,
                        widgetRange_min                = 0,
                        widgetRange_max                = 1,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "WaypointDistanceTextAlpha"
                    }
                }
            },
            {
                widgetName = L["Config - Appearance - Pinpoint"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.Pinpoint or Config.DBGlobal:GetVariable("WaypointSystemType") == WaypointEnum.WaypointSystemType.All end,
                children   = {
                    {
                        widgetName                     = L["Config - Appearance - Pinpoint - Scale"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetRange_min                = .5,
                        widgetRange_max                = 2,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "PinpointScale",
                        indent                         = 0
                    }
                }
            },
            {
                widgetName = L["Config - Appearance - Navigator"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("NavigatorShow") == true end,
                children   = {
                    {
                        widgetName                     = L["Config - Appearance - Navigator - Scale"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        indent                         = 0,
                        widgetRange_min                = .5,
                        widgetRange_max                = 2,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "NavigatorScale"
                    },
                    {
                        widgetName                     = L["Config - Appearance - Navigator - Alpha"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetRange_min                = .1,
                        widgetRange_max                = 1,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "NavigatorAlpha"
                    },
                    {
                        widgetName                     = L["Config - Appearance - Navigator - Distance"],
                        widgetType                     = SettingEnum.WidgetType.Range,
                        widgetRange_min                = .1,
                        widgetRange_max                = 3,
                        widgetRange_step               = .1,
                        widgetRange_textFormattingFunc = formatPercentage,
                        key                            = "NavigatorDistance"
                    },
                    {
                        widgetName        = L["Config - Appearance - Navigator - DynamicDistance"],
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - Appearance - Navigator - DynamicDistance - Description"] },
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        key               = "NavigatorDynamicDistance"
                    }
                }
            },
            {
                widgetName = L["Config - Appearance - Color"],
                widgetType = SettingEnum.WidgetType.Container,
                children   = {
                    {
                        widgetName = L["Config - Appearance - Color - CustomColor"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "CustomColor"
                    },
                    {
                        widgetName               = L
                            ["Config - Appearance - Color - CustomColor - Quest - Complete - Default"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("CustomColor") == true end,
                        children                 = {
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - Color"],
                                widgetType = SettingEnum.WidgetType.ColorInput,
                                key        = "CustomColorQuestComplete"
                            },
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - TintIcon"],
                                widgetType = SettingEnum.WidgetType.Checkbox,
                                key        = "CustomColorQuestCompleteTint",
                                indent     = 1
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Appearance - Color - CustomColor - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable("CustomColorQuestComplete")
                                    Config.DBGlobal:ResetVariable("CustomColorQuestCompleteTint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L
                            ["Config - Appearance - Color - CustomColor - Quest - Complete - Repeatable"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("CustomColor") == true end,
                        children                 = {
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - Color"],
                                widgetType = SettingEnum.WidgetType.ColorInput,
                                key        = "CustomColorQuestCompleteRepeatable"
                            },
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - TintIcon"],
                                widgetType = SettingEnum.WidgetType.Checkbox,
                                key        = "CustomColorQuestCompleteRepeatableTint",
                                indent     = 1
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Appearance - Color - CustomColor - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable("CustomColorQuestCompleteRepeatable")
                                    Config.DBGlobal:ResetVariable("CustomColorQuestCompleteRepeatableTint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L
                            ["Config - Appearance - Color - CustomColor - Quest - Complete - Important"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("CustomColor") == true end,
                        children                 = {
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - Color"],
                                widgetType = SettingEnum.WidgetType.ColorInput,
                                key        = "CustomColorQuestCompleteImportant"
                            },
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - TintIcon"],
                                widgetType = SettingEnum.WidgetType.Checkbox,
                                key        = "CustomColorQuestCompleteImportantTint",
                                indent     = 1
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Appearance - Color - CustomColor - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable("CustomColorQuestCompleteImportant")
                                    Config.DBGlobal:ResetVariable("CustomColorQuestCompleteImportantTint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L["Config - Appearance - Color - CustomColor - Quest - Incomplete"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("CustomColor") == true end,
                        children                 = {
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - Color"],
                                widgetType = SettingEnum.WidgetType.ColorInput,
                                key        = "CustomColorQuestIncomplete"
                            },
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - TintIcon"],
                                widgetType = SettingEnum.WidgetType.Checkbox,
                                key        = "CustomColorQuestIncompleteTint",
                                indent     = 1
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Appearance - Color - CustomColor - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable("CustomColorQuestIncomplete")
                                    Config.DBGlobal:ResetVariable("CustomColorQuestIncompleteTint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L["Config - Appearance - Color - CustomColor - Other"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("CustomColor") == true end,
                        children                 = {
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - Color"],
                                widgetType = SettingEnum.WidgetType.ColorInput,
                                key        = "CustomColorOther"
                            },
                            {
                                widgetName = L["Config - Appearance - Color - CustomColor - TintIcon"],
                                widgetType = SettingEnum.WidgetType.Checkbox,
                                key        = "CustomColorOtherTint",
                                indent     = 1
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Appearance - Color - CustomColor - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable("CustomColorOther")
                                    Config.DBGlobal:ResetVariable("CustomColorOtherTint")
                                end
                            }
                        }
                    }
                }
            }
        }
    },
    {
        widgetName = L["Config - Audio"],
        widgetType = SettingEnum.WidgetType.Tab,
        children   = {
            {
                widgetName       = L["Config - Audio - Title"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = getIcon("SpeakerOn"), text = L["Config - Audio - Title"], subtext = L["Config - Audio - Title - Subtext"] }
            },
            {
                widgetName = L["Config - Audio - General"],
                widgetType = SettingEnum.WidgetType.Container,

                children   = {
                    {
                        widgetName = L["Config - Audio - General - EnableGlobalAudio"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "AudioGlobal"
                    }
                }
            },
            {
                widgetName = L["Config - Audio - Customize"],
                widgetType = SettingEnum.WidgetType.Container,
                showWhen   = function() return Config.DBGlobal:GetVariable("AudioGlobal") == true end,
                children   = {
                    {
                        widgetName = L["Config - Audio - Customize - UseCustomAudio"],
                        widgetType = SettingEnum.WidgetType.Checkbox,
                        key        = "AudioCustom"
                    },
                    {
                        widgetName               = L["Config - Audio - Customize - UseCustomAudio - WaypointShow"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("AudioCustom") == true end,
                        children                 = {
                            {
                                widgetName              = L["Config - Audio - Customize - UseCustomAudio - Sound ID"],
                                widgetType              = SettingEnum.WidgetType.Input,
                                widgetInput_placeholder = L
                                    ["Config - Audio - Customize - UseCustomAudio - Sound ID - Placeholder"],
                                key                     = "AudioCustomShowWaypoint",
                                set                     = function(_, value)
                                    if tonumber(value) then
                                        Config.DBGlobal:SetVariable("AudioCustomShowWaypoint", tonumber(value))
                                    else
                                        Config.DBGlobal:SetVariable("AudioCustomShowWaypoint", "")
                                    end
                                end
                            },
                            {
                                widgetType        = SettingEnum.WidgetType.Button,
                                widgetButton_text = L["Config - Audio - Customize - UseCustomAudio - Preview"],
                                set               = function()
                                    Sound:PlaySound("Preview",
                                                    Config.DBGlobal:GetVariable("AudioCustomShowWaypoint"))
                                end
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Audio - Customize - UseCustomAudio - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable(
                                        "AudioCustomShowWaypoint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L["Config - Audio - Customize - UseCustomAudio - PinpointShow"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("AudioCustom") == true end,
                        children                 = {
                            {
                                widgetName              = L["Config - Audio - Customize - UseCustomAudio - Sound ID"],
                                widgetType              = SettingEnum.WidgetType.Input,
                                widgetInput_placeholder = L
                                    ["Config - Audio - Customize - UseCustomAudio - Sound ID - Placeholder"],
                                key                     = "AudioCustomShowPinpoint",
                                set                     = function(_, value)
                                    if tonumber(value) then
                                        Config.DBGlobal:SetVariable("AudioCustomShowPinpoint", tonumber(value))
                                    else
                                        Config.DBGlobal:SetVariable("AudioCustomShowPinpoint", "")
                                    end
                                end
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Audio - Customize - UseCustomAudio - Preview"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Sound:PlaySound("Preview",
                                                    Config.DBGlobal:GetVariable("AudioCustomShowPinpoint"))
                                end
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Audio - Customize - UseCustomAudio - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable(
                                        "AudioCustomShowPinpoint")
                                end
                            }
                        }
                    },
                    {
                        widgetName               = L["Config - Audio - Customize - UseCustomAudio - NewUserNavigation"],
                        widgetType               = SettingEnum.WidgetType.Container,
                        widgetContainer_isNested = true,
                        showWhen                 = function() return Config.DBGlobal:GetVariable("AudioCustom") == true end,
                        children                 = {
                            {
                                widgetName              = L["Config - Audio - Customize - UseCustomAudio - Sound ID"],
                                widgetType              = SettingEnum.WidgetType.Input,
                                widgetInput_placeholder = L
                                    ["Config - Audio - Customize - UseCustomAudio - Sound ID - Placeholder"],
                                key                     = "AudioCustomNewUserNavigation",
                                set                     = function(_, value)
                                    if tonumber(value) then
                                        Config.DBGlobal:SetVariable("AudioCustomNewUserNavigation", tonumber(value))
                                    else
                                        Config.DBGlobal:SetVariable("AudioCustomNewUserNavigation", "")
                                    end
                                end
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Audio - Customize - UseCustomAudio - Preview"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Sound:PlaySound("Preview",
                                                    Config.DBGlobal:GetVariable("AudioCustomNewUserNavigation"))
                                end
                            },
                            {
                                widgetType                  = SettingEnum.WidgetType.Button,
                                widgetButton_text           = L["Config - Audio - Customize - UseCustomAudio - Reset"],
                                widgetButton_refreshOnClick = true,
                                set                         = function()
                                    Config.DBGlobal:ResetVariable(
                                        "AudioCustomNewUserNavigation")
                                end
                            }
                        }
                    }
                }
            }
        }
    },
    {
        widgetName = L["Config - ExtraFeature"],
        widgetType = SettingEnum.WidgetType.Tab,
        children   = {
            {
                widgetName       = L["Config - ExtraFeature - Title"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = getIcon("List"), text = L["Config - ExtraFeature - Title"], subtext = L["Config - ExtraFeature - Title - Subtext"] }
            },
            {
                widgetName = L["Config - ExtraFeature - Pin"],
                widgetType = SettingEnum.WidgetType.Container,

                children   = {
                    {
                        widgetName        = L["Config - ExtraFeature - Pin - AutoTrackPlacedPin"],
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - ExtraFeature - Pin - AutoTrackPlacedPin - Description"] },
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        key               = "AutoTrackPlacedPinEnabled"
                    },
                    {
                        widgetName        = L["Config - ExtraFeature - Pin - AutoTrackChatLinkPin"],
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - ExtraFeature - Pin - AutoTrackChatLinkPin - Description"] },
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        key               = "AutoTrackChatLinkPinEnabled",
                        showWhen          = function() return Config.DBGlobal:GetVariable("AutoTrackPlacedPinEnabled") == false end,
                        indent            = 1
                    },
                    {
                        widgetName        = L["Config - ExtraFeature - Pin - GuidePinAssistant"],
                        widgetDescription = SettingDefine.Descriptor{ description = L["Config - ExtraFeature - Pin - GuidePinAssistant - Description"] },
                        widgetType        = SettingEnum.WidgetType.Checkbox,
                        key               = "GuidePinAssistantEnabled"
                    }
                }
            }
        }
    },
    {
        widgetName         = L["Config - About"],
        widgetType         = SettingEnum.WidgetType.Tab,
        widgetTab_isFooter = true,
        children           = {
            {
                widgetName       = L["Config - About"],
                widgetType       = SettingEnum.WidgetType.Title,
                widgetTitle_info = SettingDefine.TitleInfo{ imagePath = env.ICON_ALT, text = env.NAME, subtext = env.VERSION_STRING }
            },
            {
                widgetName        = L["Config - About - Contributors"],
                widgetType        = SettingEnum.WidgetType.Container,
                widgetTransparent = true,
                children          = {
                    {
                        widgetName        = L["Contributors - ZamestoTV"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - ZamestoTV - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - huchang47"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - huchang47 - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - BlueNightSky"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - BlueNightSky - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Crazyyoungs"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Crazyyoungs - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Klep"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Klep - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Kroffy"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Kroffy - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - cathtail"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - cathtail - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Larsj02"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Larsj02 - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - dabear78"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - dabear78 - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Gotziko"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Gotziko - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - y45853160"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - y45853160 - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - lemieszek"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - lemieszek - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - BadBoyBarny"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - BadBoyBarny - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - Christinxa"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - Christinxa - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - HectorZaGa"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - HectorZaGa - Description"] },
                        widgetTransparent = true
                    },
                    {
                        widgetName        = L["Contributors - SyverGiswold"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetDescription = SettingDefine.Descriptor{ description = L["Contributors - SyverGiswold - Description"] },
                        widgetTransparent = true
                    }
                }
            },
            {
                widgetName        = L["Config - About - Developer"],
                widgetType        = SettingEnum.WidgetType.Container,
                widgetTransparent = true,
                children          = {
                    {
                        widgetName        = L["Config - About - Developer - AdaptiveX"],
                        widgetType        = SettingEnum.WidgetType.Text,
                        widgetTransparent = true
                    }
                }
            }
        }
    }
}
