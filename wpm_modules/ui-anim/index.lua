local env           = select(2, ...)
local UIAnim_Engine = env.WPM:Import("wpm_modules/ui-anim/engine")
local UIAnim_Enum   = env.WPM:Import("wpm_modules/ui-anim/enum")
local UIAnim        = env.WPM:New("wpm_modules/ui-anim")


-- API
--------------------------------

UIAnim.Enum    = UIAnim_Enum
UIAnim.New     = UIAnim_Engine.New
UIAnim.Animate = UIAnim_Engine.Animate
