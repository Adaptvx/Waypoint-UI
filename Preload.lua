local env = select(2, ...)
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local CVarUtil = env.modules:Import("packages\\cvar-util")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local SlashCommand = env.modules:Import("packages\\slash-command")
local Path = env.modules:Import("packages\\path")
local Utils_InlineIcon = env.modules:Import("packages\\utils\\inline-icon")
local GenericEnum = env.modules:Import("packages\\generic-enum")
local MapPin = env.modules:Await("@\\MapPin")

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded


env.NAME = "Waypoint UI"
env.LOGO = Path.Root .. "\\Art\\Icons\\Logo"
env.LOGO_ALT = Path.Root .. "\\Art\\Icons\\Logo-White"
env.VERSION_STRING = "1.6.0"
env.VERSION_NUMBER = 010600
env.DEBUG_MODE = false


local L = {}; env.L = L


local Enum = {}; env.Enum = Enum
do
    Enum.ColorRGB01 = {
        Other           = { r = 255 / 255, g = 241 / 255, b = 180 / 255 },
        NormalQuest     = { r = 255 / 255, g = 255 / 255, b = 156 / 255 },
        RepeatableQuest = { r = 158 / 255, g = 207 / 255, b = 245 / 255 },
        ImportantQuest  = { r = 249 / 255, g = 196 / 255, b = 255 / 255 },
        IncompleteQuest = { r = 200 / 255, g = 200 / 255, b = 200 / 255 }
    }

    Enum.ColorHEX = {
        Other           = "|cffFFF1B4",
        NormalQuest     = "|cffFFEC9C",
        RepeatableQuest = "|cff9ECFF5",
        ImportantQuest  = "|cffF9C4FF",
        IncompleteQuest = "|cffE1E1E1"
    }

    Enum.Sound = {
        WaypointShow      = SOUNDKIT.UI_RUNECARVING_OPEN_MAIN_WINDOW,
        PinpointShow      = SOUNDKIT.UI_RUNECARVING_CLOSE_MAIN_WINDOW,
        NewUserNavigation = 89712
    }

    Enum.PathProvider = {
        None          = 1,
        FarstriderLib = 2,
        Mapzeroth     = 3
    }

    Enum.ContextIconAppearance = {
        Diamond = 1,
        Circle  = 2
    }

    Enum.ContextIconScaleOffset = {
        [Enum.ContextIconAppearance.Diamond] = 1,
        [Enum.ContextIconAppearance.Circle]  = 0.85
    }
end


local Config = {}; env.Config = Config
do
    Config.DBGlobal = nil
    Config.DBGlobalPersistent = nil
    Config.DBLocal = nil
    Config.DBLocalPersistent = nil

    local NAME_GLOBAL = "WaypointDB_Global"
    local NAME_GLOBAL_PERSISTENT = "WaypointDB_Global_Persistent"
    local NAME_LOCAL = "WaypointDB_Local"
    local NAME_LOCAL_PERSISTENT = "WaypointDB_Local_Persistent"

    ---@format enable
    local DB_GLOBAL_DEFAULTS = {
        lastLoadedVersion                          = nil,
        fontPath                                   = nil,

        WaypointSystemType                         = 1,
        DistanceThresholdPinpoint                  = 325,
        DistanceThresholdHidden                    = 25,
        AlwaysShow                                 = false,
        RightClickToClear                          = true,
        BackgroundPreview                          = true,
        PrefMetric                                 = false,
        WaypointScale                              = 1,
        WaypointUseWorldScale                      = true,
        WaypointScaleMin                           = 0.01,
        WaypointScaleMax                           = 2,
        ContextIconAppearance                      = Enum.ContextIconAppearance.Diamond,
        WaypointAlpha                              = 1,
        WaypointBeam                               = true,
        WaypointBeamAlpha                          = 1,
        WaypointDistanceTextFontFlags              = 1, --UIFont.Enum.FontFlags
        WaypointDistanceText                       = true,
        WaypointDistanceTextType                   = 1,
        WaypointDistanceTextScale                  = 1,
        WaypointDistanceTextAlpha                  = 0.7,
        WaypointDistanceSubtextAlpha               = 0.7,
        PinpointFontFlags                          = 1, --UIFont.Enum.FontFlags
        PinpointTextAlignment                      = 1,
        PinpointAllowInQuestArea                   = false,
        PinpointScale                              = 1,
        PinpointAlpha                              = 1,
        PinpointShowContextIcon                    = true,
        PinpointInfo                               = true,
        PinpointInfoExtended                       = true,
        NavigatorShow                              = true,
        NavigatorShowContextIcon                   = true,
        NavigatorShowArrow                         = true,
        NavigatorScale                             = 1,
        NavigatorArrowScale                        = 1,
        NavigatorAlpha                             = 1,
        NavigatorDistance                          = 1,
        NavigatorDynamicDistance                   = true,

        CustomColor                                = false,
        CustomColorQuestIncomplete                 = { r = Enum.ColorRGB01.IncompleteQuest.r, g = Enum.ColorRGB01.IncompleteQuest.g, b = Enum.ColorRGB01.IncompleteQuest.b, a = 1 },
        CustomColorQuestIncompleteTint             = false,
        CustomColorQuestIncompleteTintBeam         = true,
        CustomColorQuestIncompleteBeam             = { r = Enum.ColorRGB01.IncompleteQuest.r, g = Enum.ColorRGB01.IncompleteQuest.g, b = Enum.ColorRGB01.IncompleteQuest.b, a = 1 },
        CustomColorQuestComplete                   = { r = Enum.ColorRGB01.NormalQuest.r, g = Enum.ColorRGB01.NormalQuest.g, b = Enum.ColorRGB01.NormalQuest.b, a = 1 },
        CustomColorQuestCompleteTint               = false,
        CustomColorQuestCompleteTintBeam           = true,
        CustomColorQuestCompleteBeam               = { r = Enum.ColorRGB01.NormalQuest.r, g = Enum.ColorRGB01.NormalQuest.g, b = Enum.ColorRGB01.NormalQuest.b, a = 1 },
        CustomColorQuestCompleteRepeatable         = { r = Enum.ColorRGB01.RepeatableQuest.r, g = Enum.ColorRGB01.RepeatableQuest.g, b = Enum.ColorRGB01.RepeatableQuest.b, a = 1 },
        CustomColorQuestCompleteRepeatableTint     = false,
        CustomColorQuestCompleteRepeatableTintBeam = true,
        CustomColorQuestCompleteRepeatableBeam     = { r = Enum.ColorRGB01.RepeatableQuest.r, g = Enum.ColorRGB01.RepeatableQuest.g, b = Enum.ColorRGB01.RepeatableQuest.b, a = 1 },
        CustomColorQuestCompleteImportant          = { r = Enum.ColorRGB01.ImportantQuest.r, g = Enum.ColorRGB01.ImportantQuest.g, b = Enum.ColorRGB01.ImportantQuest.b, a = 1 },
        CustomColorQuestCompleteImportantTint      = false,
        CustomColorQuestCompleteImportantTintBeam  = true,
        CustomColorQuestCompleteImportantBeam      = { r = Enum.ColorRGB01.ImportantQuest.r, g = Enum.ColorRGB01.ImportantQuest.g, b = Enum.ColorRGB01.ImportantQuest.b, a = 1 },
        CustomColorOther                           = { r = Enum.ColorRGB01.Other.r, g = Enum.ColorRGB01.Other.g, b = Enum.ColorRGB01.Other.b, a = 1 },
        CustomColorOtherTint                       = false,
        CustomColorOtherTintBeam                   = true,
        CustomColorOtherBeam                       = { r = Enum.ColorRGB01.Other.r, g = Enum.ColorRGB01.Other.g, b = Enum.ColorRGB01.Other.b, a = 1 },

        AudioGlobal                                = true,
        AudioCustom                                = false,
        AudioCustomShowWaypoint                    = Enum.Sound.WaypointShow,
        AudioCustomShowPinpoint                    = Enum.Sound.PinpointShow,
        AudioCustomNewUserNavigation               = Enum.Sound.NewUserNavigation,

        CustomMapPinsEnabled                       = false,
        PathfindingEnabled                         = false,
        PathfindingProvider                        = Enum.PathProvider.None,
        AutoTrackPlacedPinEnabled                  = true,
        AutoTrackChatLinkPinEnabled                = true,
        GuidePinAssistantEnabled                   = true,

        TomTomSupportEnabled                       = true,
        TomTomAutoReplaceWaypoint                  = true,
        DugisSupportEnabled                        = true,
        DugisAutoReplaceWaypoint                   = true,
        APRSupportEnabled                          = false,
        APRAutoReplaceWaypoint                     = true,
        SilverDragonSupportEnabled                 = false
    }
    local DB_GLOBAL_PERSISTENT_DEFAULTS = {}
    local DB_LOCAL_DEFAULTS = {
        mapPinSessionData = nil
    }
    local DB_LOCAL_PERSISTENT_DEFAULTS = {}
    ---@format disable

    local DB_GLOBAL_MIGRATION            = {
        -- < 1.3.9
        {
            migrationType = "execute",
            script = function(db)
                if db and db.GetVariable and db.SetVariable then
                    local PrefFont = db:GetVariable("PrefFont")
                    if PrefFont and PrefFont ~= 1 and UIFont.CustomFont.FontExists(PrefFont) then
                        db:SetVariable("fontPath", UIFont.CustomFont.GetFontPathForIndex(PrefFont))
                    end
                    db:SetVariable("PrefFont", nil)
                end
            end
        },

        -- < 1.0.0
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_TYPE" },
            to            = "WaypointSystemType"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_RIGHT_CLICK_TO_CLEAR" },
            to            = "RightClickToClear"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_BACKGROUND_PREVIEW" },
            to            = "BackgroundPreview"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_DISTANCE_TRANSITION" },
            to            = "DistanceThresholdPinpoint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_DISTANCE_HIDE" },
            to            = "DistanceThresholdHidden"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_DISTANCE_TEXT_TYPE" },
            to            = "WaypointDistanceTextType"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_PINPOINT_INFO" },
            to            = "PinpointInfo"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_PINPOINT_INFO_EXTENDED" },
            to            = "PinpointInfoExtended"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "WS_NAVIGATOR" },
            to            = "NavigatorShow"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_SCALE" },
            to            = "WaypointScale"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_SCALE_MIN" },
            to            = "WaypointScaleMin"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_SCALE_MAX" },
            to            = "WaypointScaleMax"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_BEAM" },
            to            = "WaypointBeam"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_BEAM_ALPHA" },
            to            = "WaypointBeamAlpha"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_DISTANCE_TEXT" },
            to            = "WaypointDistanceText"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_DISTANCE_TEXT_SCALE" },
            to            = "WaypointDistanceTextScale"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_WAYPOINT_DISTANCE_TEXT_ALPHA" },
            to            = "WaypointDistanceTextAlpha"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_PINPOINT_SCALE" },
            to            = "PinpointScale"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_NAVIGATOR_SCALE" },
            to            = "NavigatorScale"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_NAVIGATOR_ALPHA" },
            to            = "NavigatorAlpha"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_NAVIGATOR_DISTANCE" },
            to            = "NavigatorDistance"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR" },
            to            = "CustomColor"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_INCOMPLETE_TINT" },
            to            = "CustomColorQuestIncompleteTint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_INCOMPLETE" },
            to            = "CustomColorQuestIncomplete"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE_TINT" },
            to            = "CustomColorQuestCompleteTint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE" },
            to            = "CustomColorQuestComplete"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT" },
            to            = "CustomColorQuestCompleteRepeatableTint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE_REPEATABLE" },
            to            = "CustomColorQuestCompleteRepeatable"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT" },
            to            = "CustomColorQuestCompleteImportantTint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_QUEST_COMPLETE_IMPORTANT" },
            to            = "CustomColorQuestCompleteImportant"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_NEUTRAL_TINT" },
            to            = "CustomColorOtherTint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "APP_COLOR_NEUTRAL" },
            to            = "CustomColorOther"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "AUDIO_GLOBAL" },
            to            = "AudioGlobal"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "AUDIO_CUSTOM" },
            to            = "AudioCustom"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "AUDIO_CUSTOM_WAYPOINT_SHOW" },
            to            = "AudioCustomShowWaypoint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "AUDIO_CUSTOM_PINPOINT_SHOW" },
            to            = "AudioCustomShowPinpoint"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "AUDIO_CUSTOM_NEW_USER_NAVIGATION" },
            to            = "AudioCustomNewUserNavigation"
        },
        {
            migrationType = "variable",
            from          = { "profiles", "Default", "PREF_METRIC" },
            to            = "PrefMetric"
        },
        {
            migrationType = "delete",
            to            = "profiles"
        },
        {
            migrationType = "delete",
            to            = "profileKeys"
        }
    }
    local DB_GLOBAL_PERSISTENT_MIGRATION = {
        {
            migrationType = "delete",
            to            = "profileKeys"
        }
    }

    function Config.LoadDB()
        if WaypointDB_Global and WaypointDB_Global.lastLoadedVersion == env.VERSION_NUMBER then
            -- Same version, skip migration
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS)
        else
            -- Migrate if new version
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS).migrationPlan(DB_GLOBAL_MIGRATION)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS).migrationPlan(DB_GLOBAL_PERSISTENT_MIGRATION)
        end

        SavedVariables.RegisterDatabase(NAME_LOCAL).defaults(DB_LOCAL_DEFAULTS)
        SavedVariables.RegisterDatabase(NAME_LOCAL_PERSISTENT).defaults(DB_LOCAL_PERSISTENT_DEFAULTS)

        Config.DBGlobal = SavedVariables.GetDatabase(NAME_GLOBAL)
        Config.DBGlobalPersistent = SavedVariables.GetDatabase(NAME_GLOBAL_PERSISTENT)
        Config.DBLocal = SavedVariables.GetDatabase(NAME_LOCAL)
        Config.DBLocalPersistent = SavedVariables.GetDatabase(NAME_LOCAL_PERSISTENT)

        CallbackRegistry.Trigger("Preload.DatabaseReady")
    end
end


local SlashCmdRegister = {}
do
    local Handlers = {}
    do -- /way
        local GetBestMapForUnit = C_Map.GetBestMapForUnit

        local INLINE_ADDON_ICON = Utils_InlineIcon.New(env.LOGO_ALT, 16, 16)
        local PIPE = Utils_InlineIcon.New(Path.Root .. "\\Art\\Icons\\Pipe", 16, 16)
        local WAY_COMMAND_ICON = Path.Root .. "\\Art\\Icons\\Navigation"

        local INVALID_WAY_LINE_1 = INLINE_ADDON_ICON .. " /way " .. GenericEnum.ColorHEX.NORMAL_FONT_COLOR .. "#<mapID> <x> <y> <name>" .. "|r"
        local INVALID_WAY_LINE_2 = PIPE .. " /way " .. GenericEnum.ColorHEX.NORMAL_FONT_COLOR .. "<x> <y> <name>" .. "|r"
        local INVALID_WAY_LINE_3 = PIPE .. " /way " .. GenericEnum.ColorHEX.NORMAL_FONT_COLOR .. "reset" .. "|r"
        local INVALID_WAY_LINE_4 = PIPE .. " /way " .. GenericEnum.ColorHEX.NORMAL_FONT_COLOR .. "paste" .. "|r"

        local function ThrowSlashWayError()
            DEFAULT_CHAT_FRAME:AddMessage(INVALID_WAY_LINE_1)
            DEFAULT_CHAT_FRAME:AddMessage(INVALID_WAY_LINE_2)
            DEFAULT_CHAT_FRAME:AddMessage(INVALID_WAY_LINE_3)

            if Config.DBGlobal:GetVariable("CustomMapPinsEnabled") then
                DEFAULT_CHAT_FRAME:AddMessage(INVALID_WAY_LINE_4)
            end
        end

        local function HandlePasteWayCommands()
            MapPin.PasteWayCommands(WUISharedInputPrompt.Input:GetInput():GetText(), {
                flags          = "WaypointUI_SlashWay",
                iconTexture    = WAY_COMMAND_ICON,
                requestRecolor = true
            })
        end

        function Handlers.HandleSlashCmd_Way(inputMessage)
            local isTomTomLoaded = IsAddOnLoaded("TomTom")
            if not inputMessage or inputMessage == "" then
                if not isTomTomLoaded then
                    return ThrowSlashWayError()
                end
                return
            end

            if Config.DBGlobal:GetVariable("CustomMapPinsEnabled") and inputMessage:lower():match("^%s*paste%s*$") then
                WUISharedInputPrompt:Open({
                    text         = L["WAY_PASTE_PROMPT"],
                    inputText    = "",
                    autoFocus    = true,
                    options      = {
                        {
                            text     = L["PASTE"],
                            callback = HandlePasteWayCommands
                        },
                        {
                            text     = L["CANCEL"],
                            callback = nil
                        }
                    },
                    hideOnEscape = true
                })
                return
            end

            local parsedLine = MapPin.ParseWayCommand(inputMessage, GetBestMapForUnit("player"))
            if not parsedLine then
                if not isTomTomLoaded then
                    return ThrowSlashWayError()
                end
                return
            end

            if parsedLine.command == "clear" then
                return WaypointUIAPI.Navigation.ClearUserNavigation(nil, true)
            end

            if isTomTomLoaded then
                return
            end

            if not MapPin.IsMultiPinEnabled() then
                local userNavigation = MapPin.NewUserNavigation({
                    name           = parsedLine.name,
                    mapID          = parsedLine.mapID,
                    x              = parsedLine.x,
                    y              = parsedLine.y,
                    flags          = "WaypointUI_SlashWay",
                    iconTexture    = WAY_COMMAND_ICON,
                    requestRecolor = true
                })
                if not userNavigation then
                    return ThrowSlashWayError()
                end
                return
            end

            local pinInfo, pinID = MapPin.NewGeneratedPin({
                name           = parsedLine.name,
                mapID          = parsedLine.mapID,
                x              = parsedLine.x,
                y              = parsedLine.y,
                flags          = "WaypointUI_SlashWay",
                iconTexture    = WAY_COMMAND_ICON,
                requestRecolor = true
            })
            if not pinInfo or not pinID then
                if not isTomTomLoaded then
                    return ThrowSlashWayError()
                end
                return
            end

            MapPin.NewUserNavigationFromPin(pinID)
        end
    end
    do -- /waypoint /wp
        function Handlers.HandleSlashCmd_Waypoint(_, tokens)
            if #tokens >= 1 then
                local firstToken = tokens[1]:lower()

                if firstToken == "reset" or firstToken == "clear" or firstToken == "r" or firstToken == "c" then
                    WaypointUIAPI.Navigation.ClearDestination()
                end
            end
        end
    end

    local Schema = {
        -- /way
        {
            name     = "WAYPOINT_UI_WAY",
            hook     = "TOMTOM_WAY",
            command  = "way",
            callback = Handlers.HandleSlashCmd_Way
        },
        -- /waypoint /wp
        {
            name     = "WAYPOINT_UI",
            hook     = nil,
            command  = { "waypoint", "wp" },
            callback = Handlers.HandleSlashCmd_Waypoint
        }
    }

    function SlashCmdRegister.LoadSchema()
        SlashCommand.AddFromSchema(Schema)
    end
end


local SoundHandler = {}
do
    local function UpdateMainSoundLayer()
        local Settings_AudioGlobal = Config.DBGlobal:GetVariable("AudioGlobal")

        if Settings_AudioGlobal == true then
            Sound.SetEnabled("Main", true)
        elseif Settings_AudioGlobal == false then
            Sound.SetEnabled("Main", false)
        end
    end

    SavedVariables.OnChange("WaypointDB_Global", "AudioGlobal", UpdateMainSoundLayer)

    function SoundHandler.Load()
        UpdateMainSoundLayer()
    end
end


local FontHandler = {}
do
    local function UpdateFonts()
        UIFont.CustomFont:RefreshFontList()

        local fontPath = Config.DBGlobal:GetVariable("fontPath")
        if fontPath == nil or not UIFont.CustomFont.FontExists(fontPath) then
            fontPath = UIFont.CustomFont.GetFontPathForIndex(1)
        end

        UIFont.WUIFooterFont:SetFontFile(fontPath)
        UIFont.WUIFooterFont:SetFontFlags(UIFont.Enum.FontFlags[Config.DBGlobal:GetVariable("WaypointDistanceTextFontFlags") or 1])
        UIFont.WUIPinpointFont:SetFontFile(fontPath)
        UIFont.WUIPinpointFont:SetFontFlags(UIFont.Enum.FontFlags[Config.DBGlobal:GetVariable("PinpointFontFlags") or 1])

        UIFont.SetNormalFont(fontPath)
        Config.DBGlobal:SetVariable("fontPath", fontPath)
    end

    SavedVariables.OnChange("WaypointDB_Global", "fontPath", UpdateFonts)
    SavedVariables.OnChange("WaypointDB_Global", "WaypointDistanceTextFontFlags", UpdateFonts)
    SavedVariables.OnChange("WaypointDB_Global", "PinpointFontFlags", UpdateFonts)

    function FontHandler.Load()
        UpdateFonts()
    end
end


local function LoadAddon()
    Config.LoadDB()
    SlashCmdRegister.LoadSchema()
    SoundHandler.Load()

    CVarUtil.SetCVar("showInGameNavigation", true, CVarUtil.Enum.TemporaryType.UntilLogout)
    Config.DBGlobal:SetVariable("lastLoadedVersion", env.VERSION_NUMBER)
    CallbackRegistry.Trigger("Preload.AddonReady")
end

CallbackRegistry.Add("WoWClient.OnAddonLoaded", LoadAddon)
CallbackRegistry.Add("WoWClient.OnPlayerLogin", FontHandler.Load)
