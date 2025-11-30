local env                                                                                                                  = select(2, ...)
local MixinUtil                                                                                                            = env.WPM:Import("wpm_modules/mixin-util")
local Path                                                                                                                 = env.WPM:Import("wpm_modules/path")
local Sound                                                                                                                = env.WPM:Import("wpm_modules/sound")
local UIKit                                                                                                                = env.WPM:Import("wpm_modules/ui-kit")
local Frame, Grid, VStack, HStack, ScrollView, ScrollBar, Text, Input, LinearSlider, InteractiveRect, LazyScrollView, List = UIKit.UI.Frame, UIKit.UI.Grid, UIKit.UI.VStack, UIKit.UI.HStack, UIKit.UI.ScrollView, UIKit.UI.ScrollBar, UIKit.UI.Text, UIKit.UI.Input, UIKit.UI.LinearSlider, UIKit.UI.InteractiveRect, UIKit.UI.LazyScrollView, UIKit.UI.List
local UIAnim                                                                                                               = env.WPM:Import("wpm_modules/ui-anim")
local UICSharedMixin                                                                                                       = env.WPM:Import("wpm_modules/uic-sharedmixin")
local Utils_Texture                                                                                                        = env.WPM:Import("wpm_modules/utils/texture")

local Mixin                                                                                                                = MixinUtil.Mixin
local CreateFromMixins                                                                                                     = MixinUtil.CreateFromMixins

local UICGameScrollBar                                                                                                     = env.WPM:New("wpm_modules/uic-game/scrollBar")




-- Shared
--------------------------------

local PATH                         = Path.Root .. "/wpm_modules/uic-game/resources/"
local FILL                         = UIKit.Define.Fill{}
local ATLAS                        = UIKit.Define.Texture_Atlas{ path = PATH .. "UICGameScrollBar.png" }
local BACKGROUND                   = ATLAS{ inset = 128, scale = .125, left = 0 / 1280, right = 256 / 1280, top = 0 / 512, bottom = 512 / 512 }
local BACKGROUND_THUMB             = ATLAS{ inset = 128, scale = .0975, left = 256 / 1280, right = 512 / 1280, top = 0 / 512, bottom = 256 / 512 }
local BACKGROUND_THUMB_HIGHLIGHTED = ATLAS{ inset = 128, scale = .0975, left = 512 / 1280, right = 768 / 1280, top = 0 / 512, bottom = 256 / 512 }
local BACKGROUND_THUMB_PUSHED      = ATLAS{ inset = 128, scale = .0975, left = 768 / 1280, right = 1024 / 1280, top = 0 / 512, bottom = 256 / 512 }
local BACKGROUND_THUMB_DISABLED    = ATLAS{ inset = 128, scale = .0975, left = 1024 / 1280, right = 1280 / 1280, top = 0 / 512, bottom = 256 / 512 }


Utils_Texture:PreloadAsset(PATH .. "UICGameScrollBar.png")


-- Scroll Bar
--------------------------------

local ScrollBarMixin = CreateFromMixins(UICSharedMixin.ScrollBarMixin)

function ScrollBarMixin:OnLoad()
    self:InitScrollBar()

    self.Hitbox:AddOnEnter(function() self:OnEnter() end)
    self.Hitbox:AddOnLeave(function() self:OnLeave() end)
    self.Hitbox:AddOnMouseDown(function() self:OnMouseDown() end)
    self.Hitbox:AddOnMouseUp(function() self:OnMouseUp() end)

    self:HookButtonStateChange(self.UpdateAnimation)
    self:HookEnableChange(self.UpdateAnimation)
    self:HookMouseDown(self.PlayInteractSound)
    self:HookMouseUp(self.PlayInteractSound)
    self:UpdateAnimation()
end

function ScrollBarMixin:UpdateAnimation()
    local buttonState = self:GetButtonState()
    local enabled = self:IsEnabled()

    if not enabled then
        self.Thumb:background(BACKGROUND_THUMB_DISABLED)
    elseif buttonState == "PUSHED" then
        self.Thumb:background(BACKGROUND_THUMB_PUSHED)
    elseif buttonState == "HIGHLIGHTED" then
        self.Thumb:background(BACKGROUND_THUMB_HIGHLIGHTED)
    else
        self.Thumb:background(BACKGROUND_THUMB)
    end
end

function ScrollBarMixin:PlayInteractSound()
    Sound:PlaySound("UI", SOUNDKIT.U_CHAT_SCROLL_BUTTON)
end


UICGameScrollBar.New = UIKit.Prefab(function(id, name, children, ...)
    local frame =
        ScrollBar(name, {
            InteractiveRect(name .. ".Hitbox")
                :id("Hitbox", id)
                :frameLevel(3)
                :size(FILL)
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

            Frame(name .. ".Thumb")
                :id("Thumb", id)
                :frameLevel(2)
                :under("LINEAR_SLIDER_THUMB")
                :size(FILL)
                :background(BACKGROUND_THUMB)
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),

            Frame(name .. ".Track")
                :id("Track", id)
                :frameLevel(1)
                :under("LINEAR_SLIDER_TRACK")
                :size(FILL)
                :background(BACKGROUND)
                :_updateMode(UIKit.Enum.UpdateMode.ExcludeVisibilityChanged),
        })

    frame.Hitbox = UIKit.GetElementById("Hitbox", id)
    frame.Thumb = UIKit.GetElementById("Thumb", id)
    frame.Track = UIKit.GetElementById("Track", id)

    Mixin(frame, ScrollBarMixin)
    frame:OnLoad()

    return frame
end)
