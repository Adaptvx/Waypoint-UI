local env               = select(2, ...)
local UIKit             = env.WPM:Import("wpm_modules\\ui-kit")
local React             = env.WPM:Import("wpm_modules\\react")

local UIFont_CustomFont = env.WPM:Import("wpm_modules\\ui-font\\custom-font")
local UIFont_FontUtil   = env.WPM:Import("wpm_modules\\ui-font\\font-util")
local UIFont            = env.WPM:New("wpm_modules\\ui-font")

-- Predefined Fonts
----------------------------------------------------------------------------------------------------

local UIFontNormal = React.New(GameFontNormal:GetFont())
UIFont.UIFontNormal = UIFontNormal

local function CreateUIFontObjectNormal(fontHeight)
    local fontObject = UIFont_FontUtil:CreateFontObject()
    fontObject:SetFont(GameFontNormal:GetFont(), fontHeight, "")
    fontObject:SetShadowOffset(1, -1)
    fontObject:SetShadowColor(0, 0, 0, 1)
    
    return fontObject
end

local UIFontObjectNormal8 = CreateUIFontObjectNormal(8)
UIFont.UIFontObjectNormal8 = UIFontObjectNormal8

local UIFontObjectNormal10 = CreateUIFontObjectNormal(10)
UIFont.UIFontObjectNormal10 = UIFontObjectNormal10

local UIFontObjectNormal11 = CreateUIFontObjectNormal(11)
UIFont.UIFontObjectNormal11 = UIFontObjectNormal11

local UIFontObjectNormal12 = CreateUIFontObjectNormal(12)
UIFont.UIFontObjectNormal12 = UIFontObjectNormal12

local UIFontObjectNormal14 = CreateUIFontObjectNormal(14)
UIFont.UIFontObjectNormal14 = UIFontObjectNormal14

local UIFontObjectNormal16 = CreateUIFontObjectNormal(16)
UIFont.UIFontObjectNormal16 = UIFontObjectNormal16

local UIFontObjectNormal18 = CreateUIFontObjectNormal(18)
UIFont.UIFontObjectNormal18 = UIFontObjectNormal18

-- API
----------------------------------------------------------------------------------------------------

UIFont.CustomFont = UIFont_CustomFont
