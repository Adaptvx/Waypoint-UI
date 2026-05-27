--[[
    WaypointUI API Documentation

    `WaypointUIAPI.Navigation`
        `IsUserNavigationTracked()`                                                                 -- Returns true if a user waypoint is currently being tracked
        `IsUserNavigationFlagged(flag)`                                                             -- Returns true when the tracked user navigation has the given flag
        `IsPathStepWaypointTracked()`                                                               -- Returns true if a path step waypoint is currently tracked

        `ClearDestination()`                                                                        -- Clears any active navigation (user waypoint or supertracked content)
        `ClearUserNavigation(preserveWaypoint?, suppressAdvance?)`                                  -- Clears the current user-placed waypoint marker
        `ClearPin(id)`                                                                              -- Removes the pin with the specified ID from storage
        `ClearAllPins()`                                                                            -- Removes all stored pins

        `GetUserNavigation()`                                                                       -- Returns the current waypoint session info or nil
        `GetPin(id)`                                                                                -- Returns the pin info for the specified pin ID or nil
        `GetAllPins()`                                                                              -- Returns all stored session pins keyed by pin ID or nil

        `NewUserNavigation(options)`                                                                -- Creates and tracks a new user waypoint. options keys: name, mapID, x, y, flags, iconTexture, r, g, b, requestRecolor, iconType, suppressAudio, stripCoordinates
        `NewPin(options)`                                                                           -- Creates and stores a new pin. options keys: id, name, mapID, x, y, flags, iconTexture, r, g, b, requestRecolor, iconType, stripCoordinates

    `WaypointUIAPI.OpenSettingsUI()`
]]

local env = select(2, ...)
WaypointUIAPI = WaypointUIAPI or {}

do -- @\\MapPin
    local MapPin = env.modules:Await("@\\MapPin")
    WaypointUIAPI.Navigation = {
        IsUserNavigationTracked   = MapPin.IsUserNavigationTracked,
        IsUserNavigationFlagged   = MapPin.IsUserNavigationFlagged,
        IsPathStepWaypointTracked = MapPin.IsPathStepWaypointTracked,

        ClearDestination          = MapPin.ClearDestination,
        ClearUserNavigation       = MapPin.ClearUserNavigation,
        ClearPin                  = MapPin.ClearPin,
        ClearAllPins              = MapPin.ClearAllPins,

        GetUserNavigation         = MapPin.GetUserNavigation,
        GetPin                    = MapPin.GetPin,
        GetAllPins                = MapPin.GetAllPins,

        NewUserNavigation         = MapPin.NewUserNavigation,
        NewPin                    = MapPin.NewPin
    }
end

do -- @\\Settings
    local Setting = env.modules:Await("@\\Settings")
    WaypointUIAPI_OpenSettingsUI = Setting.OpenSettingsUI
    WaypointUIAPI.OpenSettingsUI = Setting.OpenSettingsUI
end
