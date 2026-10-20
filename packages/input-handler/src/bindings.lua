local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local InputHandler_Devices = env.modules:Import("packages\\input-handler\\devices")
local InputHandler_Bindings = env.modules:New("packages\\input-handler\\bindings")

local BindingManagerMixin = {}

local function ResolveBinding(defaults, overrides, action, device)
    local actionOverrides = overrides and overrides[action]
    local value = actionOverrides and actionOverrides[device]
    if value == false then return nil end
    if value ~= nil then return value end

    local actionDefaults = defaults[action]
    return actionDefaults and actionDefaults[device]
end

function BindingManagerMixin:GetDefaultBinding(action, device)
    local defaults = self.defaults[action]
    return defaults and defaults[device or InputHandler_Devices.GetInputDevice()]
end

function BindingManagerMixin:GetBinding(action, device)
    local bindings = self.getDatabase():GetVariable(self.variable)
    return ResolveBinding(self.defaults, bindings, action, device or InputHandler_Devices.GetInputDevice())
end

function BindingManagerMixin:GetActionForBinding(binding, device)
    if not binding then return end

    local bindings = self.getDatabase():GetVariable(self.variable)
    device = device or InputHandler_Devices.GetInputDevice()
    for _, action in pairs(self.actions) do
        if ResolveBinding(self.defaults, bindings, action, device) == binding then return action end
    end
end

function BindingManagerMixin:SetBinding(action, device, binding)
    local database = self.getDatabase()
    local storedBindings = database:GetVariable(self.variable) or {}
    local storedAction = storedBindings[action]
    if (storedAction and storedAction[device]) == binding then return end

    local bindings = {}
    for otherAction, values in pairs(storedBindings) do
        bindings[otherAction] = Mixin({}, values)
    end

    local effectiveBinding = binding
    if binding == nil then
        effectiveBinding = self:GetDefaultBinding(action, device)
    end

    local conflicts = {}
    if effectiveBinding then
        for _, otherAction in pairs(self.actions) do
            if otherAction ~= action and ResolveBinding(self.defaults, storedBindings, otherAction, device) == effectiveBinding then
                bindings[otherAction] = bindings[otherAction] or {}
                bindings[otherAction][device] = false
                conflicts[#conflicts + 1] = otherAction
            end
        end
    end
    bindings[action] = bindings[action] or {}
    bindings[action][device] = binding
    database:SetVariable(self.variable, bindings)

    local changedActions = { action }
    for _, otherAction in ipairs(conflicts) do
        changedActions[#changedActions + 1] = otherAction
    end
    CallbackRegistry.Trigger("InputHandler.BindingChanged", self, device, changedActions)

    return conflicts
end

function BindingManagerMixin:ClearAll()
    local database = self.getDatabase()
    local bindings = database:GetVariable(self.variable)
    if not bindings or not next(bindings) then return end

    database:SetVariable(self.variable, {})
    CallbackRegistry.Trigger("InputHandler.BindingChanged", self)
end

function InputHandler_Bindings.New(actions, defaults, getDatabase, variable)
    return Mixin({
        actions = actions,
        defaults = defaults,
        getDatabase = getDatabase,
        variable = variable
    }, BindingManagerMixin)
end
