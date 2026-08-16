local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local UIKit = env.modules:Import("packages\\ui-kit")
local Utils_Texture = env.modules:Import("packages\\utils\\texture")
local MapPinFrame_Preload = env.modules:New("@\\MapPinFrame\\Preload")

MapPinFrame_Preload.Enum = {
    MapPinType   = {
        UserNavigation   = 1,
        Pin              = 2,
        PathStepWaypoint = 3
    },
    DisplayLayer = {
        WorldMap = 1,
        Minimap  = 2
    }
}

local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\Art\\MapPinFrame\\MapPinFrame" }
Utils_Texture.Preload(Path.Root .. "\\Art\\MapPinFrame\\MapPinFrame")
MapPinFrame_Preload.UIDEF = {
    UIMapPinFrame                   = ATLAS{ left = 0 / 256, right = 64 / 256, top = 0 / 128, bottom = 64 / 128 },
    UIMapPinFrame_Highlighted       = ATLAS{ left = 64 / 256, right = 128 / 256, top = 0 / 128, bottom = 64 / 128 },
    UIMapPinFrameGlow               = ATLAS{ left = 0 / 256, right = 64 / 256, top = 64 / 128, bottom = 128 / 128 },
    UIMapPinFrameCircle             = ATLAS{ left = 128 / 256, right = 192 / 256, top = 0 / 128, bottom = 64 / 128 },
    UIMapPinFrameCircle_Highlighted = ATLAS{ left = 192 / 256, right = 256 / 256, top = 0 / 128, bottom = 64 / 128 },
    UIMapPinFrameCircleGlow         = ATLAS{ left = 128 / 256, right = 192 / 256, top = 64 / 128, bottom = 128 / 128 },
    UIMinimapPin                    = ATLAS{ left = 64 / 256, right = 128 / 256, top = 64 / 128, bottom = 128 / 128 },
    UIMinimapPinCircle              = ATLAS{ left = 192 / 256, right = 256 / 256, top = 64 / 128, bottom = 128 / 128 }
}
