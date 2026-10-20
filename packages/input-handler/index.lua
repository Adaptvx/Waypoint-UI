local env = select(2, ...)
local InputHandler_Devices = env.modules:Import("packages\\input-handler\\devices")
local InputHandler_Handler = env.modules:Import("packages\\input-handler\\handler")
local InputHandler_Bindings = env.modules:Import("packages\\input-handler\\bindings")
local InputHandler_Capture = env.modules:Import("packages\\input-handler\\capture")
local InputHandler_Repeater = env.modules:Import("packages\\input-handler\\repeater")
local InputHandler = env.modules:New("packages\\input-handler")

InputHandler.Enum = InputHandler_Devices.Enum
InputHandler.GetInputDevice = InputHandler_Devices.GetInputDevice
InputHandler.SetInputDevice = InputHandler_Devices.SetInputDevice
InputHandler.GetDisplayInputDevice = InputHandler_Devices.GetDisplayInputDevice
InputHandler.SetDisplayInputDevice = InputHandler_Devices.SetDisplayInputDevice

InputHandler.GetKeyChord = InputHandler_Handler.GetKeyChord
InputHandler.GetBindingChord = InputHandler_Handler.GetBindingChord
InputHandler.BlockKeyEvent = InputHandler_Handler.BlockKeyEvent
InputHandler.IsKeyBinding = InputHandler_Handler.IsKeyBinding
InputHandler.IsKeyBindingSet = InputHandler_Handler.IsKeyBindingSet
InputHandler.IsPlayerTurning = InputHandler_Handler.IsPlayerTurning
InputHandler.IsPlayerLooking = InputHandler_Handler.IsPlayerLooking

InputHandler.NewBindingManager = InputHandler_Bindings.New
InputHandler.NewCapture = InputHandler_Capture.New
InputHandler.NewRepeater = InputHandler_Repeater.New
