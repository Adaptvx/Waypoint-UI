local env = select(2, ...)
local InputHandler_Handler = env.modules:Import("packages\\input-handler\\handler")
local InputHandler_Repeater = env.modules:New("packages\\input-handler\\repeater")

local RepeaterMixin = {}

function RepeaterMixin:Start(key, binding, onRepeat, isActive)
    self.key = key
    self.binding = binding
    self.onRepeat = onRepeat
    self.isActive = isActive
    self.elapsed = -self.initialDelay
    self:SetScript("OnUpdate", self.OnUpdate)
end

function RepeaterMixin:Stop()
    self:SetScript("OnUpdate", nil)
    self.key = nil
    self.binding = nil
    self.onRepeat = nil
    self.isActive = nil
    self.elapsed = nil
end

function RepeaterMixin:IsRepeatingKey(key)
    return self.onRepeat ~= nil and self.key == key
end

function RepeaterMixin:OnUpdate(elapsed)
    if not self.onRepeat or not self.isActive() or InputHandler_Handler.GetKeyChord(self.key) ~= self.binding then
        self:Stop()
        return
    end

    self.elapsed = self.elapsed + elapsed
    if self.elapsed < self.interval then return end
    self.elapsed = 0
    if not self.onRepeat() then self:Stop() end
end

function InputHandler_Repeater.New(initialDelay, interval)
    local repeater = Mixin(CreateFrame("Frame"), RepeaterMixin)
    repeater.initialDelay = initialDelay
    repeater.interval = interval
    return repeater
end
