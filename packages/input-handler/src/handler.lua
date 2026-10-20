local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local InputHandler_Devices = env.modules:Import("packages\\input-handler\\devices")
local InputHandler_Handler = env.modules:New("packages\\input-handler\\handler")

function InputHandler_Handler.BindFrame(frame, onDown, onUp)
    frame:SetScript("OnKeyDown", function(_, key)
        if key:sub(1, 3) == "PAD" then return end
        onDown(key, InputHandler_Devices.Enum.InputDevices.KBM)
    end)
    frame:SetScript("OnKeyUp", function(_, key)
        if key:sub(1, 3) == "PAD" then return end
        onUp(key, InputHandler_Devices.Enum.InputDevices.KBM)
    end)
    frame:SetScript("OnGamePadButtonDown", function(_, key)
        onDown(key, InputHandler_Devices.Enum.InputDevices.GamePad)
    end)
    frame:SetScript("OnGamePadButtonUp", function(_, key)
        onUp(key, InputHandler_Devices.Enum.InputDevices.GamePad)
    end)
end

local keybindFrame = CreateFrame("Frame")
InputHandler_Handler.BindFrame(keybindFrame, function(key, device)
    InputHandler_Devices.SetInputDevice(device)
    CallbackRegistry.Trigger("InputHandler.OnKeyDown", key, device)
    if key == "ESCAPE" then CallbackRegistry.Trigger("InputHandler.OnEscapePressed") end
end, function(key, device)
    CallbackRegistry.Trigger("InputHandler.OnKeyUp", key, device)
end)
keybindFrame:EnableKeyboard(true)
keybindFrame:EnableGamePadButton(true)

local function EnableKeyPropagation()
    if InCombatLockdown() then
        keybindFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    keybindFrame:SetPropagateKeyboardInput(true)
    keybindFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

keybindFrame:SetScript("OnEvent", EnableKeyPropagation)
EnableKeyPropagation()

local keyPropagationTimer = LazyTimer.New()
keyPropagationTimer:SetAction(EnableKeyPropagation)

function InputHandler_Handler.BlockKeyEvent()
    if InCombatLockdown() then return end

    keybindFrame:SetPropagateKeyboardInput(false)
    keyPropagationTimer:Start(0)
end

function InputHandler_Handler.GetKeyChord(input)
    local key = GetConvertedKeyOrButton(input)
    if not key then return end
    return CreateKeyChordStringUsingMetaKeyState(key)
end

function InputHandler_Handler.GetBindingChord(input)
    local key = GetConvertedKeyOrButton(input)
    if not key or IsKeyPressIgnoredForBinding(key) then return end
    return CreateKeyChordStringUsingMetaKeyState(key)
end

function InputHandler_Handler.IsKeyBinding(key, binding)
    if not binding then return false end
    local chord = InputHandler_Handler.GetKeyChord(key)
    if not chord then return false end

    local bindingKey1, bindingKey2 = GetBindingKey(binding)
    return chord == bindingKey1 or chord == bindingKey2
end

function InputHandler_Handler.IsKeyBindingSet(binding)
    local bindingKey1, bindingKey2 = GetBindingKey(binding)
    return bindingKey1 ~= nil or bindingKey2 ~= nil
end

local isPlayerTurning = false
local isPlayerLooking = false

function InputHandler_Handler.IsPlayerTurning()
    return isPlayerTurning
end

function InputHandler_Handler.IsPlayerLooking()
    return isPlayerLooking
end

local mouseEventFrame = CreateFrame("Frame")
mouseEventFrame:RegisterEvent("PLAYER_STARTED_LOOKING")
mouseEventFrame:RegisterEvent("PLAYER_STOPPED_LOOKING")
mouseEventFrame:RegisterEvent("PLAYER_STARTED_TURNING")
mouseEventFrame:RegisterEvent("PLAYER_STOPPED_TURNING")
mouseEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_STARTED_TURNING" or event == "PLAYER_STOPPED_TURNING" then
        isPlayerTurning = event == "PLAYER_STARTED_TURNING"
    elseif event == "PLAYER_STARTED_LOOKING" or event == "PLAYER_STOPPED_LOOKING" then
        isPlayerLooking = event == "PLAYER_STARTED_LOOKING"
    end
end)
