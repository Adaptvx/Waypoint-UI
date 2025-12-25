local env = select(2, ...)
local UIKit = env.WPM:Import("wpm_modules\\ui-kit")
local GenericEnum = env.WPM:New("wpm_modules\\generic-enum")

do -- Color
    GenericEnum.ColorRGB01 = {
        White      = { r = 1, g = 1, b = 1 },
        Black      = { r = 0, g = 0, b = 0 },
        Orange     = { r = 1, g = 0.5, b = 0.25 },
        Yellow     = { r = 1, g = 1, b = 0 },
        Green      = { r = 0.1, g = 1, b = 0.1 },
        Red        = { r = 1, g = 0.125, b = 0.125 },
        Gray       = { r = 0.5, g = 0.5, b = 0.5 },
        LightGray  = { r = 0.75, g = 0.75, b = 0.75 },
        NormalText = { r = 1, g = 0.823, b = 0 }
    }

    GenericEnum.ColorRGB255 = {
        White      = { r = 255, g = 255, b = 255 },
        Black      = { r = 0, g = 0, b = 0 },
        Orange     = { r = 255, g = 128, b = 64 },
        Yellow     = { r = 255, g = 255, b = 0 },
        Green      = { r = 26, g = 255, b = 26 },
        Red        = { r = 255, g = 32, b = 32 },
        Gray       = { r = 128, g = 128, b = 128 },
        LightGray  = { r = 191, g = 191, b = 191 },
        NormalText = { r = 255, g = 210, b = 0 }
    }

    GenericEnum.UIColorRGB = {
        White      = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 },
        Black      = UIKit.Define.Color_RGBA{ r = 0, g = 0, b = 0, a = 1 },
        Orange     = UIKit.Define.Color_RGBA{ r = 255, g = 128, b = 64, a = 1 },
        Yellow     = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 0, a = 1 },
        Green      = UIKit.Define.Color_RGBA{ r = 26, g = 255, b = 26, a = 1 },
        Red        = UIKit.Define.Color_RGBA{ r = 255, g = 32, b = 32, a = 1 },
        Gray       = UIKit.Define.Color_RGBA{ r = 128, g = 128, b = 128, a = 1 },
        LightGray  = UIKit.Define.Color_RGBA{ r = 191, g = 191, b = 191, a = 1 },
        NormalText = UIKit.Define.Color_RGBA{ r = 255, g = 210, b = 0, a = 1 }
    }

    GenericEnum.ColorHEX = {
        White      = "|cffFFFFFF",
        Black      = "|cff000000",
        Orange     = "|cffFFA500",
        Yellow     = "|cffFFCC1A",
        Green      = "|cff54CB34",
        Red        = "|cffD05555",
        Gray       = "|cff9D9D9D",
        LightGray  = "|cffCDCDCD",
        NormalText = "|cffFFD200"
    }
end
