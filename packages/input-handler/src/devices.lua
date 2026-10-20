local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local InputHandler_Devices = env.modules:New("packages\\input-handler\\devices")

InputHandler_Devices.Enum = {
    InputDevices = {
        KBM     = 1,
        GamePad = 2
    },
    DisplayInputDevices = {
        KBM  = 1,
        Xbox = 2,
        PS   = 3
    }
}

local activeInputDevice = InputHandler_Devices.Enum.InputDevices.KBM
local activeDisplayInputDevice = InputHandler_Devices.Enum.DisplayInputDevices.KBM

function InputHandler_Devices.GetInputDevice()
    return activeInputDevice
end

function InputHandler_Devices.SetInputDevice(device)
    if device == activeInputDevice then return end
    activeInputDevice = device
    CallbackRegistry.Trigger("InputHandler.InputDeviceChanged", device)
end

function InputHandler_Devices.GetDisplayInputDevice()
    return activeDisplayInputDevice
end

function InputHandler_Devices.SetDisplayInputDevice(device)
    if device == activeDisplayInputDevice then return end
    activeDisplayInputDevice = device
    CallbackRegistry.Trigger("InputHandler.DisplayInputDeviceChanged", device)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GAME_PAD_ACTIVE_CHANGED")
eventFrame:SetScript("OnEvent", function(_, _, isActive)
    InputHandler_Devices.SetInputDevice(isActive and InputHandler_Devices.Enum.InputDevices.GamePad or InputHandler_Devices.Enum.InputDevices.KBM)
end)
