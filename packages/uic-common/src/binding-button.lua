local env = select(2, ...)
local UIKit = env.modules:Import("packages\\ui-kit")
local InputHandler = env.modules:Import("packages\\input-handler")
local UICCommonButton = env.modules:Import("packages\\uic-common\\button")
local UICCommonPreload = env.modules:Import("packages\\uic-common\\preload")
local UICCommonBindingButton = env.modules:New("packages\\uic-common\\binding-button")

local Mixin = Mixin

local UIDEF = {
    UIBindingButton             = UICCommonPreload.ATLAS{ inset = 14, left = 403 / 1024, right = 496 / 1024, top = 7 / 512, bottom = 48 / 512 },
    UIBindingButton_Highlighted = UICCommonPreload.ATLAS{ inset = 14, left = 502 / 1024, right = 595 / 1024, top = 7 / 512, bottom = 48 / 512 },
    UIBindingButton_Pushed      = UICCommonPreload.ATLAS{ inset = 14, left = 601 / 1024, right = 694 / 1024, top = 7 / 512, bottom = 48 / 512 },
    UIBindingButton_Disabled    = UICCommonPreload.ATLAS{ inset = 14, left = 700 / 1024, right = 793 / 1024, top = 7 / 512, bottom = 48 / 512 },
    UIBindingButton_Entry       = UICCommonPreload.ATLAS{ inset = 14, left = 799 / 1024, right = 892 / 1024, top = 7 / 512, bottom = 48 / 512 }
}

do -- Binding Button
    local TEXT_ALPHA_BOUND = 1
    local TEXT_ALPHA_UNBOUND = 0.5

    local BindingButtonMixin = {}

    function BindingButtonMixin:OnLoad()
        self.binding = nil
        self.bindingFunc = nil
        self.textFormattingFunc = nil
        self.capture = InputHandler.NewCapture(self, function(binding, device) if self.bindingFunc then self.bindingFunc(self, binding, device) end end, function() self:UpdateCaptureAnimation() end)

        self:HookButtonStateChange(self.UpdateCaptureAnimation)
        self:HookEnableChange(self.OnEnableChange)
        self:HookClick(self.BindingButton_OnClick)
        self:HookMouseUp(self.BindingButton_OnMouseUp)
        self:UpdateCaptureAnimation()
    end

    function BindingButtonMixin:UpdateCaptureAnimation()
        local buttonState = self:GetButtonState()

        if not self:IsEnabled() then
            self.Texture:background(UIDEF.UIBindingButton_Disabled)
        elseif self:IsCapturing() then
            self.Texture:background(UIDEF.UIBindingButton_Entry)
        elseif buttonState == "HIGHLIGHTED" then
            self.Texture:background(UIDEF.UIBindingButton_Highlighted)
        elseif buttonState == "PUSHED" then
            self.Texture:background(UIDEF.UIBindingButton_Pushed)
        else
            self.Texture:background(UIDEF.UIBindingButton)
        end
    end

    function BindingButtonMixin:OnEnableChange(isEnabled)
        if isEnabled then
            self:UpdateCaptureAnimation()
        else
            self:StopCapture()
        end
    end

    function BindingButtonMixin:BindingButton_OnClick(button)
        if button ~= "LeftButton" then return end

        if self:IsCapturing() then
            self:StopCapture()
        else
            self:StartCapture()
        end
    end

    function BindingButtonMixin:BindingButton_OnMouseUp(button)
        if not self:IsMouseOver() then return end

        if button == "RightButton" then
            self:StopCapture()
            if self.bindingFunc then self.bindingFunc(self, nil) end
        elseif button ~= "LeftButton" then
            self.capture:ProcessInput(button, InputHandler.Enum.InputDevices.KBM)
        end
    end

    function BindingButtonMixin:StartCapture()
        if self:IsEnabled() then self.capture:Start() end
    end

    function BindingButtonMixin:StopCapture()
        self.capture:Stop()
    end

    function BindingButtonMixin:IsCapturing()
        return self.capture:IsCapturing()
    end

    function BindingButtonMixin:SetBinding(binding)
        self.binding = binding

        local text = binding or ""
        if binding and self.textFormattingFunc then
            text = self.textFormattingFunc(binding)
        end

        self:SetText(text)
        self.Text:SetAlpha(binding and TEXT_ALPHA_BOUND or TEXT_ALPHA_UNBOUND)
    end

    function BindingButtonMixin:GetBinding()
        return self.binding
    end

    function BindingButtonMixin:SetOnBinding(func)
        self.bindingFunc = func
    end

    function BindingButtonMixin:SetBindingValidator(func)
        self.capture:SetValidator(func)
    end

    function BindingButtonMixin:SetTextFormattingFunc(func)
        self.textFormattingFunc = func
        self:SetBinding(self.binding)
    end

    UICCommonBindingButton.New = UIKit.Template(function(id, name, children, ...)
        local frame = UICCommonButton.GrayTextButton(name, children)

        Mixin(frame, BindingButtonMixin)
        frame:OnLoad()

        return frame
    end)
end
