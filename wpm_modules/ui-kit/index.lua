local env                    = select(2, ...)
local UIKit_Enum             = env.WPM:Import("wpm_modules/ui-kit/enum")
local UIKit_Define           = env.WPM:Import("wpm_modules/ui-kit/define")
local UIKit_TagManager       = env.WPM:Import("wpm_modules/ui-kit/tag-manager")
local UIKit_UI               = env.WPM:Import("wpm_modules/ui-kit/ui")
local UIKit_Prefab           = env.WPM:Import("wpm_modules/ui-kit/prefab")

local UIKit                  = env.WPM:New("wpm_modules/ui-kit")
UIKit.Enum                   = UIKit_Enum
UIKit.Define                 = UIKit_Define
UIKit.TagManager             = UIKit_TagManager
UIKit.UI                     = UIKit_UI
UIKit.Prefab                 = UIKit_Prefab.New

UIKit.GetElementById         = UIKit_TagManager.GetElementById
UIKit.GetElementsByClass     = UIKit_TagManager.GetElementsByClass
UIKit.AddElementToId         = UIKit_TagManager.AddElementToId
UIKit.RemoveElementFromId    = UIKit_TagManager.RemoveElementFromId
UIKit.AddElementToClass      = UIKit_TagManager.AddElementToClass
UIKit.RemoveElementFromClass = UIKit_TagManager.RemoveElementFromClass
UIKit.NewGroupCaptureString  = UIKit_TagManager.NewGroupCaptureString
UIKit.ReadGroupCaptureString = UIKit_TagManager.ReadGroupCaptureString
UIKit.IsGroupCaptureString   = UIKit_TagManager.IsGroupCaptureString
