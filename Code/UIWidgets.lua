local env = select(2, ...)
local Path = env.modules:Import("packages\\path")
local GenericEnum = env.modules:Import("packages\\generic-enum")
local UIFont = env.modules:Import("packages\\ui-font")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UIWidgets = env.modules:New("@\\UIWidgets")

local Mixin = Mixin

local UIDEF = {
    ItemSlot  = UIKit.Define.Texture{ path = Path.Root .. "\\Art\\Shared\\ItemSlot" },
    ItemMask  = UIKit.Define.Texture{ path = Path.Root .. "\\Art\\Shared\\Mask-ItemSlot" }
}

do -- Item Slot
    local BACKGROUND_SIZE = UIKit.Define.Fill{ delta = -12 }
    local ITEM_SIZE = UIKit.Define.Fill{ delta = 4 }

    local ItemSlotMixin = {}

    function ItemSlotMixin:SetItem(texture, rarity)
        rarity = rarity or GenericEnum.ItemRarity.Common
        self.ItemTexture:SetTexture(texture)
        self.Background:backgroundColor(GenericEnum.ItemRarityColor[rarity])
    end

    function ItemSlotMixin:SetAmount(amount)
        self.AmountText:SetShown(amount ~= nil)
        if amount then
            self.AmountText:SetText(amount)
        end
    end

    UIWidgets.ItemSlot = UIKit.Template(function(id, name, children, ...)
        local frame =
            Frame(name, {
                Frame(name .. ".Background")
                    :id("Background", id)
                    :frameLevel(2)
                    :background(UIDEF.ItemSlot)
                    :size(BACKGROUND_SIZE),

                Frame(name .. ".Item")
                    :id("Item", id)
                    :frameLevel(1)
                    :size(ITEM_SIZE)
                    :background(UIKit.UI.TEXTURE_NIL)
                    :mask(UIDEF.ItemMask),

                Text(name .. ".AmountText")
                    :id("AmountText", id)
                    :frameLevel(3)
                    :point(UIKit.Enum.Point.BottomRight)
                    :position(-5, 6)
                    :size(50, 50)
                    :fontObject(UIFont.UIFontObjectNormal10)
                    :textColor(GenericEnum.UIColorRGB.WHITE_FONT_COLOR)
                    :textJustifyH("RIGHT")
                    :textJustifyV("BOTTOM")
            })


        frame.Background = UIKit.GetElementById("Background", id)
        frame.BackgroundTexture = frame.Background:GetTextureFrame()
        frame.Item = UIKit.GetElementById("Item", id)
        frame.ItemTexture = frame.Item:GetTextureFrame()
        frame.AmountText = UIKit.GetElementById("AmountText", id)

        Mixin(frame, ItemSlotMixin)
        frame.AmountText:Hide()

        return frame
    end)
end
