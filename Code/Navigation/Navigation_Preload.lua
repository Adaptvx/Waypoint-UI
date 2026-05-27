local env = select(2, ...)
local Navigation_Preload = env.modules:New("@\\Navigation\\Preload")

Navigation_Preload.Enum = {
    SuperTrackedPinType = {
        MapPin = 1,
        Content = 2,
        Quest = 3,
        Vignette = 4,
        UserWaypoint = 5
    },
    NavigationMethod = {
        Direct = 1,
        Portal = 2,
        Item = 3
    }
}
