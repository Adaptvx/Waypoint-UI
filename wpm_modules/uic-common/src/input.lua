local env = select(2, ...)
local Path = env.WPM:Import("wpm_modules\\path")
local UIFont = env.WPM:Import("wpm_modules\\ui-font")
local UIKit = env.WPM:Import("wpm_modules\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List = unpack(UIKit.UI.Frames)
local UIAnim = env.WPM:Import("wpm_modules\\ui-anim")
local UICSharedMixin = env.WPM:Import("wpm_modules\\uic-sharedmixin")
local Utils_Texture = env.WPM:Import("wpm_modules\\utils\\texture")
local UICCommonInput = env.WPM:New("wpm_modules\\uic-common\\input")

local Mixin = Mixin
local CreateFromMixins = CreateFromMixins

Utils_Texture.Preload(Path.Root .. "\\wpm_modules\\uic-common\\resources\\input.png")
local ATLAS = UIKit.Define.Texture_Atlas{ path = Path.Root .. "\\wpm_modules\\uic-common\\resources\\input.png", inset = 37, scale = 0.5 }
local UIDef = {
    UIInput             = ATLAS{ left = 0 / 192, top = 0 / 128, right = 64 / 192, bottom = 64 / 128 },
    UIInput_Highlighted = ATLAS{ left = 64 / 192, top = 0 / 128, right = 128 / 192, bottom = 64 / 128 },
    UIInput_Disabled    = ATLAS{ left = 128 / 192, top = 0 / 128, right = 192 / 192, bottom = 64 / 128 },
    UIInputCaret        = ATLAS{ left = 0 / 192, top = 64 / 128, right = 64 / 192, bottom = 128 / 128 }
}

do --Input
    local TEXT_COLOR = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 }
    local CARET_COLOR = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 1 }
    local PLACEHOLDER_COLOR = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 0.5 }
    local HIGHLIGHT_COLOR = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 0.375 }
    local INPUT_SIZE = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 17.5 }
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = 0 }

    local InputMixin = CreateFromMixins(UICSharedMixin.InputMixin)

    function InputMixin:GetInput()
        return self.Input
    end

    function InputMixin:OnLoad()
        self:InitInput()

        self:RegisterMouseEventsWithComponents(self.HitRect, self.Input)
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookEnableChange(self.UpdateAnimation)
        self:HookFocusChange(self.UpdateAnimation)
        self:UpdateAnimation()
    end

    function InputMixin:UpdateAnimation()
        local focused = self:IsFocused()
        local enabled = self:IsEnabled()

        if not enabled then
            self.Background:background(UIDef.UIInput_Disabled)
        elseif focused then
            self.Background:background(UIDef.UIInput_Highlighted)

            if not self.AnimGroup:IsPlaying(self.Caret, "NORMAL") then
                self.AnimGroup:Play(self.Caret, "NORMAL")
            end
        else
            local buttonState = self:GetButtonState()
            if buttonState == "HIGHLIGHTED" then
                self.Background:background(UIDef.UIInput_Highlighted)
            else
                self.Background:background(UIDef.UIInput)
            end
        end
    end

    function InputMixin:SetMultiline(value)
        self.Input:inputMultiLine(value)
    end

    function InputMixin:SetPlaceholder(value)
        self.Input:placeholder(value)
    end

    InputMixin.AnimGroup = UIAnim.New()
    do
        local Blink = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):easing(UIAnim.Enum.Easing.Linear):duration(0.1):from(0):to(1):loop(UIAnim.Enum.Looping.Yoyo):loopDelayEnd(0.5)
        InputMixin.AnimGroup:State("NORMAL", function(frame)
            Blink:Play(frame)
        end)
    end

    UICCommonInput.New = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                HitRect(name .. ".HitRect")
                    :id("HitRect", id)
                    :frameLevel(5)
                    :size(UIKit.UI.FILL)
                    :_excludeFromCalculations()
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(1)
                    :size(BACKGROUND_SIZE)
                    :background(UIDef.UIInput)
                    :_excludeFromCalculations()
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

                Input(name .. ".Input", {
                    Frame(name .. ".Caret")
                        :id("Caret", id)
                        :as("INPUT_CARET")
                        :frameLevel(3)
                        :size(UIKit.UI.FILL)
                        :background(UIDef.UIInputCaret)
                        :backgroundColor(CARET_COLOR)
                        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
                })
                    :id("Input", id)
                    :frameLevel(2)
                    :point(UIKit.Enum.Point.Center)
                    :size(INPUT_SIZE, UIKit.UI.FIT)
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

        frame.HitRect = UIKit.GetElementById("HitRect", id)
        frame.Background = UIKit.GetElementById("Background", id)
        frame.Input = UIKit.GetElementById("Input", id)
        frame.Caret = UIKit.GetElementById("Caret", id)

        Mixin(frame, InputMixin)
        frame:OnLoad()

        return frame
    end)
end
