local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UIAnim = env.modules:Import("packages\\ui-anim")
local WoWClient = env.modules:Import("packages\\wow-client")
local UICCommonPreload = env.modules:Import("packages\\uic-common\\preload")
local UICCommonButton = env.modules:Import("packages\\uic-common\\button")
local UICCommonInput = env.modules:Import("packages\\uic-common\\input")
local UICCommonPrompt = env.modules:New("packages\\uic-common\\prompt")

local Mixin = Mixin

local UIDEF = {
    UIPrompt = UICCommonPreload.ATLAS{ inset = 11, scale = 1, left = 4 / 512, right = 46 / 512, top = 330 / 512, bottom = 372 / 512 }
}

do --Prompt Button
    local WIDTH = 125
    local HEIGHT = 25

    UICCommonPrompt.Button = UIKit.Template(function(id, name, children, ...)
        local frame =
            UICCommonButton.RedTextButton(name)
            :size(WIDTH, HEIGHT)

        return frame
    end)
end

do --Prompt
    local PROMPT_BACKGROUND_COLOR = UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = 0.875 }
    local PROMPT_WIDTH = UIKit.Define.Fit{ delta = 36 }
    local PROMPT_HEIGHT = UIKit.Define.Fit{ delta = 36 }
    local PROMPT_CONTENT_SPACING = 9
    local PROMPT_CONTENT_SIZE = UIKit.Define.Fit{}
    local PROMPT_BUTTON_SPACING = 5
    local PROMPT_BUTTON_SIZE = UIKit.Define.Fit{}

    local PromptMixin = {}

    local function OnElementClick(self)
        if self.value.callback then
            self.value.callback()
        end
        self:GetFrameParent().__parentRef:HidePrompt()
    end

    local function OnElementUpdate(element, index, value)
        element.index = index
        element.value = value

        element:HookMouseUp(OnElementClick, true)
        element:SetText(value.text)
    end

    function PromptMixin:OnLoad()
        self.hideOnEscape = false

        CallbackRegistry.Add("WoWClient.OnEscapePressed", function()
            if self.hideOnEscape and self:IsShown() then
                WoWClient.BlockKeyEvent()
                self:OnEscape()
            end
        end)
    end

    function PromptMixin:ShowPrompt()
        self:Show()
        self.AnimGroup:Play(self, "INTRO")
    end

    function PromptMixin:HidePrompt()
        if self.AnimGroup:IsPlaying(self, "OUTRO") then return end
        if self.timeoutTimer then self.timeoutTimer:Cancel() end

        self.AnimGroup:Play(self, "OUTRO"):onFinish(function()
            self:Hide()
        end)
    end

    function PromptMixin:OnEscape()
        self:HidePrompt()
    end

    function PromptMixin:OnTimeout()
        self:HidePrompt()
    end

    function PromptMixin:SetTimeout(seconds)
        if self.timeoutTimer then self.timeoutTimer:Cancel() end

        self.timeoutTimer = C_Timer.NewTimer(seconds, function()
            self:OnTimeout()
        end)
    end

    function PromptMixin:HandleOpen(info, ...)
        --[[
            Expected table:
                options = {
                    {
                        text (string),
                        callback (function)
                    }
                },
                hideOnEscape? (boolean),
                timeout? (number)
        ]]

        assert(info, "Invalid variable `info`")
        assert(info.options, "Invalid variable `info`: Missing required fields")

        self.hideOnEscape = info.hideOnEscape or false
        if info.timeout then self:SetTimeout(info.timeout) end

        self.Content.ButtonContainer.List:SetData(info.options)

        self:_Render()
        self:ShowPrompt()
    end

    PromptMixin.AnimGroup = UIAnim.New()
    do
        local IntroAlpha = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.325):from(0):to(1)
        local IntroTranslate = UIAnim.Animate():property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.ElasticOut):duration(1.25):from(-15):to(0)
        PromptMixin.AnimGroup:State("INTRO", function(frame)
            IntroAlpha:Play(frame)
            IntroTranslate:Play(frame)
        end)

        local OutroAlpha = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.325):to(0)
        local OutroTranslate = UIAnim.Animate():property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.QuintInOut):duration(0.375):to(-15)
        PromptMixin.AnimGroup:State("OUTRO", function(frame)
            OutroAlpha:Play(frame)
            OutroTranslate:Play(frame)
        end)
    end

    UICCommonPrompt.New = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                LayoutVertical(name .. ".Content", {
                    Frame(name .. ".DetailsFrame", {
                        unpack(children)
                    })
                        :id("DetailsFrame", id)
                        :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

                    LayoutHorizontal(name .. ".Content.ButtonContainer", {
                        List()
                            :id("Content.ButtonContainer.List", id)
                            :poolTemplate(UICCommonPrompt.Button)
                            :poolElementUpdate(OnElementUpdate)
                            :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
                    })
                        :id("Content.ButtonContainer", id)
                        :size(PROMPT_BUTTON_SIZE, PROMPT_BUTTON_SIZE)
                        :layoutSpacing(PROMPT_BUTTON_SPACING)
                        :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
                })
                    :id("Content", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(PROMPT_CONTENT_SIZE, PROMPT_CONTENT_SIZE)
                    :layoutSpacing(PROMPT_CONTENT_SPACING)
                    :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })
            :size(PROMPT_WIDTH, PROMPT_HEIGHT)
            :background(UIDEF.UIPrompt)
            :backgroundColor(PROMPT_BACKGROUND_COLOR)
            :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)

        frame.Content = UIKit.GetElementById("Content", id)
        frame.DetailsFrame = UIKit.GetElementById("DetailsFrame", id)
        frame.Content.ButtonContainer = UIKit.GetElementById("Content.ButtonContainer", id)
        frame.Content.ButtonContainer.List = UIKit.GetElementById("Content.ButtonContainer.List", id)

        Mixin(frame, PromptMixin)
        frame:OnLoad()
        frame.Content.ButtonContainer.__parentRef = frame

        return frame
    end)
end

do --Prompt (Text)
    local PromptTextMixin = {}

    function PromptTextMixin:Open(info, ...)
        local textToDisplay = ""
        if ... then
            textToDisplay = string.format(info.text, ...)
        else
            textToDisplay = info.text
        end
        self.Text:SetText(textToDisplay)

        self:HandleOpen(info, ...)
    end

    UICCommonPrompt.Text = UIKit.Template(function(id, name, children, ...)
        local frame =
            UICCommonPrompt.New(name, {
                Text(name .. ".Text")
                    :id("Text", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                    :fontObject(UIFont.UIFontObjectNormal12)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })

        frame.Text = UIKit.GetElementById("Text", id)

        Mixin(frame, PromptTextMixin)

        return frame
    end)
end

do --Prompt (Input)
    local CONTENT_SPACING = 9

    local PromptInputMixin = {}

    function PromptInputMixin:Open(info, ...)
        local inputText = info.inputText or ""
        self.Input:GetInput():SetText(inputText)

        local textToDisplay = ""
        if ... then
            textToDisplay = string.format(info.text, ...)
        else
            textToDisplay = info.text
        end
        self.Text:SetText(textToDisplay)

        self:HandleOpen(info, ...)

        if info.autoFocus then
            self.Input:GetInput():SetFocus()
        end
    end

    UICCommonPrompt.Input = UIKit.Template(function(id, name, children, ...)
        local frame =
            UICCommonPrompt.New(name, {
                LayoutVertical(name .. ".InputContentFrame", {
                    Text(name .. ".Text")
                        :id("Text", id)
                        :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                        :fontObject(UIFont.UIFontObjectNormal12)
                        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

                    UICCommonInput.New(name .. ".Input")
                        :id("Input", id)
                        :size(UIKit.UI.P_FILL, 25)
                        :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
                })
                    :id("InputContentFrame", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.FIT)
                    :layoutSpacing(CONTENT_SPACING)
                    :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                    :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged)
            })

        frame.InputContentFrame = UIKit.GetElementById("InputContentFrame", id)
        frame.Text = UIKit.GetElementById("Text", id)
        frame.Input = UIKit.GetElementById("Input", id)
        frame.Input:SetMultiline(false)

        Mixin(frame, PromptInputMixin)

        return frame
    end)
end
