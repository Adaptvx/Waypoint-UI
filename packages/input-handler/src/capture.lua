local env = select(2, ...)
local InputHandler_Devices = env.modules:Import("packages\\input-handler\\devices")
local InputHandler_Handler = env.modules:Import("packages\\input-handler\\handler")
local InputHandler_Capture = env.modules:New("packages\\input-handler\\capture")

local activeCapture = nil
local CaptureMixin = {}

function CaptureMixin:Start()
    if self.isCapturing or InCombatLockdown() then return end
    if activeCapture then activeCapture:Stop() end

    activeCapture = self
    self.isCapturing = true
    self.frame:EnableKeyboard(true)
    self.frame:EnableGamePadButton(true)
    self.frame:EnableMouseWheel(true)
    self.frame:SetPropagateKeyboardInput(true)
    self.onStateChanged()
end

function CaptureMixin:Stop()
    if not self.isCapturing then return end

    if activeCapture == self then activeCapture = nil end
    self.isCapturing = false
    self.frame:EnableKeyboard(false)
    self.frame:EnableGamePadButton(false)
    self.frame:EnableMouseWheel(false)
    self.onStateChanged()
end

function CaptureMixin:IsCapturing()
    return self.isCapturing
end

function CaptureMixin:SetValidator(validator)
    self.validator = validator
end

function CaptureMixin:ProcessInput(input, device)
    if not self.isCapturing then return end

    local binding = InputHandler_Handler.GetBindingChord(input)
    if not binding or (self.validator and not self.validator(binding, device)) then return end

    self:Stop()

    InputHandler_Devices.SetInputDevice(device)
    self.onBinding(binding, device)
end

function CaptureMixin:OnInputDown(key, device)
    if not self.isCapturing then return end

    InputHandler_Handler.BlockKeyEvent()
    self:ProcessInput(key, device)
end

function CaptureMixin:OnInputUp()
    if not self.isCapturing then return end
    InputHandler_Handler.BlockKeyEvent()
end

function InputHandler_Capture.New(frame, onBinding, onStateChanged)
    local capture = Mixin({
        frame = frame,
        onBinding = onBinding,
        onStateChanged = onStateChanged,
        isCapturing = false
    }, CaptureMixin)

    InputHandler_Handler.BindFrame(frame, function(key, device)
        capture:OnInputDown(key, device)
    end, function()
        capture:OnInputUp()
    end)
    frame:SetScript("OnMouseWheel", function(_, delta)
        capture:ProcessInput(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN", InputHandler_Devices.Enum.InputDevices.KBM)
    end)
    frame:HookScript("OnHide", function()
        capture:Stop()
    end)
    frame:EnableKeyboard(false)
    frame:EnableGamePadButton(false)
    frame:EnableMouseWheel(false)

    return capture
end

local EL = CreateFrame("Frame")
EL:RegisterEvent("PLAYER_REGEN_DISABLED")
EL:SetScript("OnEvent", function()
    if activeCapture then activeCapture:Stop() end
end)
