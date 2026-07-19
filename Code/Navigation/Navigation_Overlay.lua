local env = select(2, ...)
local GenericEnum = env.modules:Import("packages\\generic-enum")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UIAnim = env.modules:Import("packages\\ui-anim")
local UIWidgets = env.modules:Import("@\\UIWidgets")
local UICSharedMixin = env.modules:Import("packages\\uic-sharedmixin")
local Waypoint_DataProvider = env.modules:Import("@\\Waypoint\\DataProvider")
local Navigation_Preload = env.modules:Import("@\\Navigation\\Preload")

local GetItemInfo = C_Item.GetItemInfo
local GetItemIconByID = C_Item.GetItemIconByID
local InCombatLockdown = InCombatLockdown
local type = type
local tonumber = tonumber


local function GetItemData(itemID)
    if not itemID then return nil, nil end

    local itemTexture = GetItemIconByID(itemID)
    local itemInfo, _, itemRarity = GetItemInfo(itemID)
    itemRarity = itemRarity or GenericEnum.ItemRarity.Common

    if type(itemInfo) == "table" then
        itemRarity = itemInfo.quality or itemRarity
    end

    return itemTexture, itemRarity
end


do --WUINavigationOverlayFrame
    local NavigationOverlayFrameMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

    function NavigationOverlayFrameMixin:OnLoad()
        self:InitButton()
        self.overlayVisible = false
        self.overlayFadeId = 0

        self:EnableMouse(true)
        self:RegisterMouseEvents()
        self:HookButtonStateChange(self.UpdateAnimation)
        self:HookMouseEnter(self.ShowTooltip)
        self:HookMouseLeave(self.HideTooltip)
        self:SetItem(nil)
        self:UpdateAnimation()

        self:SetAlpha(0)
        self:Hide()
    end

    function NavigationOverlayFrameMixin:UpdateAnimation()
        if not self:IsEnabled() then
            self.ContentFrame:SetAlpha(1)
        elseif self:GetButtonState() == "PUSHED" then
            self.ContentFrame:SetAlpha(0.75)
        elseif self:GetButtonState() == "HIGHLIGHTED" then
            self.ContentFrame:SetAlpha(0.875)
        else
            self.ContentFrame:SetAlpha(1)
        end
    end

    function NavigationOverlayFrameMixin:ShowTooltip()
        if not self.itemID then return end

        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -5)
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end

    function NavigationOverlayFrameMixin:HideTooltip()
        GameTooltip:Hide()
    end

    function NavigationOverlayFrameMixin:SetContextIcon(contextIcon)
        if not contextIcon then
            self.TitleFrameContextIconTexture:SetTexture(nil)
            return
        end

        if contextIcon.type == "ATLAS" then
            self.TitleFrameContextIconTexture:SetAtlas(contextIcon.path)
        elseif contextIcon.path then
            self.TitleFrameContextIconTexture:SetTexture(contextIcon.path)
        else
            self.TitleFrameContextIconTexture:SetAtlas(contextIcon)
        end
    end

    function NavigationOverlayFrameMixin:SetTitle(contextIcon, titleText)
        self:SetContextIcon(contextIcon)
        self.TitleFrameLabel:SetText(titleText or "")
    end

    function NavigationOverlayFrameMixin:SetText(text)
        self.ContentFrameLabel:SetText(text or "")
    end

    function NavigationOverlayFrameMixin:SetItem(itemID)
        self.itemID = itemID
        self:SetEnabled(itemID ~= nil)

        if itemID then
            self:SetActionItem(itemID)
        else
            self:ClearAction()
        end

        local itemTexture, itemRarity = GetItemData(itemID)
        if itemTexture then
            self.ContentFrameSpellIcon:SetItem(itemTexture, itemRarity)
            self.ContentFrameSpellIcon:Show()
        else
            self.ContentFrameSpellIcon:SetItem(nil, nil)
            self.ContentFrameSpellIcon:Hide()
        end

        if not itemID then
            self:HideTooltip()
        end

        if not InCombatLockdown() then
            self:_Render()
        end
    end

    function NavigationOverlayFrameMixin.ShowFrame(frame)
        frame:SetAlpha(1)
        frame:Show()
    end

    function NavigationOverlayFrameMixin.HideFrame(frame)
        if frame.fadeOutPlayback == true then return end
        frame:SetAlpha(0)
        frame:Hide()
    end

    function NavigationOverlayFrameMixin:FadeIn()
        self.overlayVisible = true
        self.overlayFadeId = self.overlayFadeId + 1

        if InCombatLockdown() then
            UIKit_Utils:AwaitProtectedEvent(NavigationOverlayFrameMixin.ShowFrame, self)
            return
        end

        self.AnimGroup:Stop(self, false)
        self:Show()
        self.AnimGroup:Play(self, "FADE_IN")
    end

    function NavigationOverlayFrameMixin:FadeOut()
        self.overlayVisible = false
        self.overlayFadeId = self.overlayFadeId + 1
        local fadeId = self.overlayFadeId

        self:SetItem(nil)
        if not self:IsShown() then return end

        self.AnimGroup:Stop(self, false)

        self.fadeOutPlayback = true
        self.AnimGroup:Play(self, "FADE_OUT"):onFinish(function()
            if self.overlayFadeId == fadeId and self.overlayVisible == false then
                self.fadeOutPlayback = false

                if InCombatLockdown() then
                    UIKit_Utils:AwaitProtectedEvent(NavigationOverlayFrameMixin.HideFrame, self)
                else
                    self:HideFrame()
                end
            end
        end)

        if InCombatLockdown() then UIKit_Utils:AwaitProtectedEvent(NavigationOverlayFrameMixin.HideFrame, self) end
    end

    function NavigationOverlayFrameMixin:ShowStep(step, destinationSnapshot)
        if not step or not destinationSnapshot or not destinationSnapshot.name then
            self:FadeOut()
            return
        end

        self:SetTitle(destinationSnapshot.iconTexture or Waypoint_DataProvider.FallbackPinIcon, destinationSnapshot.name)
        self:SetText(step.name)
        self:SetItem(step.method == Navigation_Preload.Enum.NavigationMethod.Item and step.metadata and tonumber(step.metadata.itemID) or nil)

        if not self:IsShown() or self.overlayVisible ~= true then self:FadeIn() end

        if not InCombatLockdown() then
            self:_Render()
        end
    end

    NavigationOverlayFrameMixin.AnimGroup = UIAnim.New()
    do
        local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):easing(UIAnim.Enum.Easing.Linear):duration(0.3):from(0):to(1)
        NavigationOverlayFrameMixin.AnimGroup:State("FADE_IN", function(frame)
            FadeIn:Play(frame)
        end)

        local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):easing(UIAnim.Enum.Easing.Linear):duration(0.3):to(0)
        NavigationOverlayFrameMixin.AnimGroup:State("FADE_OUT", function(frame)
            FadeOut:Play(frame)
        end)
    end


    local name = "WUINavigationOverlayFrame"
    local id = "WUINavigationOverlayFrame"

    local frame = SecureButton(name, {
            LayoutVertical(name .. ".Container", {
                LayoutHorizontal(name .. ".TitleFrame", {
                    Frame(name .. ".TitleFrameContextIcon")
                        :id("TitleFrameContextIcon", id)
                        :size(15, 15)
                        :background(UIKit.UI.TEXTURE_NIL),

                    Text(name .. ".TitleFrameLabel")
                        :id("TitleFrameLabel", id)
                        :size(UIKit.UI.FIT, UIKit.UI.P_FILL)
                        :fontObject(UIFont.UIFontObjectNormal10)
                        :textColor(GenericEnum.UIColorRGB.WHITE_FONT_COLOR)
                })
                    :id("TitleFrame", id)
                    :size(UIKit.UI.FIT, 15)
                    :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                    :layoutSpacing(2)
                    :alpha(0.5),

                LayoutHorizontal(name .. ".ContentFrame", {
                    UIWidgets.ItemSlot(name .. ".ContentFrameSpellIcon")
                        :id("ContentFrameSpellIcon", id)
                        :size(22, 22),

                    Text(name .. ".ContentFrameLabel")
                        :id("ContentFrameLabel", id)
                        :size(UIKit.UI.FIT, UIKit.UI.P_FILL)
                        :fontObject(UIFont.UIFontObjectNormal18)
                        :textColor(GenericEnum.UIColorRGB.NORMAL_FONT_COLOR)
                })
                    :id("ContentFrame", id)
                    :size(UIKit.UI.FIT, 23)
                    :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                    :layoutAlignmentV(UIKit.Enum.Direction.Justified)
                    :layoutSpacing(4)
            })
                :id("Container", id)
                :size(UIKit.UI.FIT, UIKit.UI.FIT)
                :point(UIKit.Enum.Point.Center)
                :layoutAlignmentH(UIKit.Enum.Direction.Justified)
                :layoutSpacing(2)
        })
        :point(UIKit.Enum.Point.Top)
        :y(-20)
        :size(UIKit.UI.FIT, UIKit.UI.FIT)
        :parent(UIParent)
        :frameStrata(UIKit.Enum.FrameStrata.Medium)
        :enableMouse(true)
        :registerForClicks("LeftButtonDown", "LeftButtonUp")
        :_Render()

    frame.Container = UIKit.GetElementById("Container", id)
    frame.TitleFrame = UIKit.GetElementById("TitleFrame", id)
    frame.TitleFrameContextIcon = UIKit.GetElementById("TitleFrameContextIcon", id)
    frame.TitleFrameContextIconTexture = frame.TitleFrameContextIcon:GetTextureFrame()
    frame.TitleFrameLabel = UIKit.GetElementById("TitleFrameLabel", id)
    frame.ContentFrame = UIKit.GetElementById("ContentFrame", id)
    frame.ContentFrameSpellIcon = UIKit.GetElementById("ContentFrameSpellIcon", id)
    frame.ContentFrameSpellIconTexture = frame.ContentFrameSpellIcon:GetTextureFrame()
    frame.ContentFrameLabel = UIKit.GetElementById("ContentFrameLabel", id)
    WUINavigationOverlayFrame = frame

    Mixin(WUINavigationOverlayFrame, NavigationOverlayFrameMixin)
    WUINavigationOverlayFrame:OnLoad()
end
