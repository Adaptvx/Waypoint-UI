local env                                                                                                                  = select(2, ...)
local MixinUtil                                                                                                            = env.WPM:Import("wpm_modules/mixin-util")
local Path                                                                                                                 = env.WPM:Import("wpm_modules/path")
local UIFont                                                                                                               = env.WPM:Import("wpm_modules/ui-font")
local UIKit                                                                                                                = env.WPM:Import("wpm_modules/ui-kit")
local Frame, Grid, VStack, HStack, ScrollView, ScrollBar, Text, Input, LinearSlider, InteractiveRect, LazyScrollView, List = UIKit.UI.Frame, UIKit.UI.Grid, UIKit.UI.VStack, UIKit.UI.HStack, UIKit.UI.ScrollView, UIKit.UI.ScrollBar, UIKit.UI.Text, UIKit.UI.Input, UIKit.UI.LinearSlider, UIKit.UI.InteractiveRect, UIKit.UI.LazyScrollView, UIKit.UI.List
local UIAnim                                                                                                               = env.WPM:Import("wpm_modules/ui-anim")
local UICSharedMixin                                                                                                       = env.WPM:Import("wpm_modules/uic-sharedmixin")
local Utils_Texture                                                                                                        = env.WPM:Import("wpm_modules/utils/texture")

local Mixin                                                                                                                = MixinUtil.Mixin
local CreateFromMixins                                                                                                     = MixinUtil.CreateFromMixins

local UICGameInput                                                                                                         = env.WPM:New("wpm_modules/uic-game/input")




-- Shared
--------------------------------

local PATH  = Path.Root .. "/wpm_modules/uic-game/resources/"
local ATLAS = UIKit.Define.Texture_Atlas{ path = PATH .. "UICGameInput.png", inset = 128, scale = .125 }
local FIT   = UIKit.Define.Fit{}
local FILL  = UIKit.Define.Fill{}


Utils_Texture:PreloadAsset(PATH .. "UICGameInput.png")


-- Base
--------------------------------

local BACKGROUND             = ATLAS{ left = 0 / 768, top = 0 / 512, right = 256 / 768, bottom = 256 / 512 }
local BACKGROUND_HIGHLIGHTED = ATLAS{ left = 256 / 768, top = 0 / 512, right = 512 / 768, bottom = 256 / 512 }
local BACKGROUND_DISABLED    = ATLAS{ left = 512 / 768, top = 0 / 512, right = 768 / 768, bottom = 256 / 512 }
local BACKGROUND_CARET       = ATLAS{ left = 0 / 512, top = 256 / 512, right = 256 / 512, bottom = 512 / 512 }
local TEXT_COLOR             = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 }
local CARET_COLOR            = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 }
local PLACEHOLDER_COLOR      = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = .5 }
local HIGHLIGHT_COLOR        = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = .375 }
local INPUT_SIZE             = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 17.5 }
local BACKGROUND_SIZE        = UIKit.Define.Fill{ delta = 0 }



local CaretAnimation = UIAnim:New()

local Blink = UIAnim.Animate()
    :property(UIAnim.Enum.Property.Alpha)
    :easing(UIAnim.Enum.Easing.Linear)
    :duration(.1)
    :from(0)
    :to(1)
    :loop(UIAnim.Enum.Looping.Yoyo)
    :loopDelayEnd(.5)

CaretAnimation:State("NORMAL", function(frame)
    Blink:Play(frame)
end)



local InputMixin = CreateFromMixins(UICSharedMixin.InputMixin)

function InputMixin:GetInput()
    return self.Input
end

function InputMixin:OnLoad()
    self:InitInput()

    self:RegisterMouseEventsWithComponents(self.Hitbox, self.Input)
    self:HookButtonStateChange(self.UpdateAnimation)
    self:HookEnableChange(self.UpdateAnimation)
    self:HookFocusChange(self.UpdateAnimation)
    self:UpdateAnimation()
end


function InputMixin:UpdateAnimation()
    local focused = self:IsFocused()
    local enabled = self:IsEnabled()

    if not enabled then
        self.Background:background(BACKGROUND_DISABLED)
    elseif focused then
        self.Background:background(BACKGROUND_HIGHLIGHTED)

        if not CaretAnimation:IsPlaying(self.Caret, "NORMAL") then
            CaretAnimation:Play(self.Caret, "NORMAL")
        end
    else
        local buttonState = self:GetButtonState()
        if buttonState == "HIGHLIGHTED" then
            self.Background:background(BACKGROUND_HIGHLIGHTED)
        else
            self.Background:background(BACKGROUND)
        end
    end
end

function InputMixin:SetMultiline(value)
    self.Input:inputMultiLine(value)
end

function InputMixin:SetPlaceholder(value)
    self.Input:placeholder(value)
end



UICGameInput.New = UIKit.Prefab(function(id, name, children, ...)
    local frame =
        Frame(name, {
            InteractiveRect(name .. ".Hitbox")
                :id("Hitbox", id)
                :frameLevel(5)
                :size(FILL)
                :_excludeFromCalculations()
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

            Frame(name .. ".Background")
                :id("Background", id)
                :frameLevel(1)
                :size(BACKGROUND_SIZE)
                :background(BACKGROUND)
                :_excludeFromCalculations()
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

            Input(name .. ".Input", {
                Frame(name .. ".Caret", {

                })
                    :id("Caret", id)
                    :under("INPUT_CARET")
                    :frameLevel(3)
                    :size(FILL)
                    :background(BACKGROUND_CARET)
                    :backgroundColor(CARET_COLOR)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })
                :id("Input", id)
                :frameLevel(2)
                :point(UIKit.Enum.Point.Center)
                :size(INPUT_SIZE, FIT)
                :fontObject(UIFont.UIFontObjectNormal10)
                :textColor(TEXT_COLOR)
                :inputPlaceholderFont(UIFont.UIFontNormal)
                :inputPlaceholderFontSize(11)
                :inputPlaceholderTextColor(PLACEHOLDER_COLOR)
                :inputMultiLine(false)
                :inputHighlightColor(HIGHLIGHT_COLOR)
                :inputCaretWidth(2)
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
        })
        :enableMouse(true)
        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)

    frame.Hitbox = UIKit.GetElementById("Hitbox", id)
    frame.Background = UIKit.GetElementById("Background", id)
    frame.Input = UIKit.GetElementById("Input", id)
    frame.Caret = UIKit.GetElementById("Caret", id)

    Mixin(frame, InputMixin)
    frame:OnLoad()

    return frame
end)
