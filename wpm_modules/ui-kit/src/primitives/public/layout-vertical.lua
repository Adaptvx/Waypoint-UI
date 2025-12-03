local env                             = select(2, ...)
local MixinUtil                       = env.WPM:Import("wpm_modules/mixin-util")
local UIKit_Utils                     = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Define                    = env.WPM:Import("wpm_modules/ui-kit/define")

local Mixin                           = MixinUtil.Mixin
local wipe                            = wipe

local UIKit_Primitives_Frame          = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")
local UIKit_Primitives_LayoutVertical = env.WPM:New("wpm_modules/ui-kit/primitives/layout-vertical")


-- Layout (Vertical)
--------------------------------

local LayoutVerticalMixin = {}
do
    -- Init
    --------------------------------

    function LayoutVerticalMixin:Init()
        self.__visibleChildren = {}
    end


    -- Layout
    --------------------------------

    function LayoutVerticalMixin:RenderElements()
        local children = self:GetFrameChildren()
        if not children then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        -- Collect visible children and calculate dimensions
        local totalChildHeight, maxChildWidth, visibleCount = 0, 0, 0
        local nonZeroCount = 0

        for _, child in ipairs(children) do
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List" then
                visibleCount = visibleCount + 1
                visibleChildren[visibleCount] = child

                local childWidth, childHeight = child:GetSize()
                childWidth = childWidth or 0
                childHeight = childHeight or 0
                totalChildHeight = totalChildHeight + childHeight
                if childWidth > maxChildWidth then maxChildWidth = childWidth end
                if childHeight > 0 then nonZeroCount = nonZeroCount + 1 end
            end
        end

        if visibleCount == 0 then return end

        local parent = self:GetParent()
        local containerWidth, containerHeight = self:GetSize()
        if not containerWidth then
            containerWidth = (parent and parent:GetWidth()) or UIParent:GetWidth()
        end
        if not containerHeight then
            containerHeight = (parent and parent:GetHeight()) or UIParent:GetHeight()
        end

        -- Calculate spacing
        local spacingSetting = self:GetSpacing()
        local spacing = type(spacingSetting) == "number" and spacingSetting
            or spacingSetting == UIKit_Define.Num and (spacingSetting.value or 0)
            or spacingSetting == UIKit_Define.Percentage and UIKit_Utils:CalculateRelativePercentage(self, containerHeight, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta)
            or 0

        local contentHeight = totalChildHeight + ((nonZeroCount > 0 and (nonZeroCount - 1) or 0) * spacing)

        -- Apply fit-to-content sizing
        local fitWidthToContent, fitHeightToContent = self:GetFitContent()
        if fitWidthToContent then
            containerWidth = self:ResolveFitSize("width", maxChildWidth, self.uk_prop_width)
            self:SetWidth(containerWidth)
        end
        if fitHeightToContent then
            containerHeight = self:ResolveFitSize("height", contentHeight, self.uk_prop_height)
            self:SetHeight(containerHeight)
        end

        -- Calculate start position based on vertical alignment
        local alignmentV = self.uk_prop_layoutAlignmentV or "LEADING"
        local currentY = alignmentV == "JUSTIFIED" and (containerHeight - contentHeight) * 0.5
            or alignmentV == "TRAILING" and containerHeight - contentHeight
            or 0

        -- Position children
        local alignmentH = self.uk_prop_layoutAlignmentH or "LEADING"

        local placedNonZero = 0
        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth, childHeight = child:GetSize()
            childWidth = childWidth or 0
            childHeight = childHeight or 0

            local horizontalOffset = alignmentH == "JUSTIFIED" and (containerWidth - childWidth) * 0.5
                or alignmentH == "TRAILING" and containerWidth - childWidth
                or 0

            if childHeight > 0 and placedNonZero > 0 then
                currentY = currentY + spacing
            end

            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", horizontalOffset, -currentY)

            currentY = currentY + childHeight
            if childHeight > 0 then
                placedNonZero = placedNonZero + 1
            end
        end
    end


    -- Property
    --------------------------------

    function LayoutVerticalMixin:GetAlignmentH()
        return self.uk_prop_layoutAlignmentH or "LEADING"
    end

    function LayoutVerticalMixin:SetAlignmentH(layoutAlignmentH)
        self.uk_prop_layoutAlignmentH = layoutAlignmentH
        self:RenderElements()
    end

    function LayoutVerticalMixin:GetAlignmentV()
        return self.uk_prop_layoutAlignmentV or "LEADING"
    end

    function LayoutVerticalMixin:SetAlignmentV(layoutAlignmentV)
        self.uk_prop_layoutAlignmentV = layoutAlignmentV
        self:RenderElements()
    end
end


function UIKit_Primitives_LayoutVertical.New(name, parent)
    name = name or "undefined"


    local LayoutVertical = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(LayoutVertical, LayoutVerticalMixin)
    LayoutVertical:Init()


    return LayoutVertical
end
