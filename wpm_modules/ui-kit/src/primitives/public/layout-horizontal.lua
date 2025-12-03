local env                               = select(2, ...)
local MixinUtil                         = env.WPM:Import("wpm_modules/mixin-util")
local UIKit_Utils                       = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Define                      = env.WPM:Import("wpm_modules/ui-kit/define")

local Mixin                             = MixinUtil.Mixin
local wipe                              = wipe

local UIKit_Primitives_Frame            = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")
local UIKit_Primitives_LayoutHorizontal = env.WPM:New("wpm_modules/ui-kit/primitives/layout-horizontal")


-- Layout (Horizontal)
--------------------------------

local LayoutHorizontalMixin = {}
do
    -- Init
    --------------------------------

    function LayoutHorizontalMixin:Init()
        self.__visibleChildren = {}
    end


    -- Layout
    --------------------------------

    function LayoutHorizontalMixin:RenderElements()
        local children = self:GetFrameChildren()
        if not children then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        -- Collect visible children and calculate dimensions
        local totalChildWidth, maxChildHeight, visibleCount = 0, 0, 0

        for _, child in ipairs(children) do
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List" then
                visibleCount = visibleCount + 1
                visibleChildren[visibleCount] = child

                local childWidth, childHeight = child:GetSize()
                childWidth = childWidth or 0
                childHeight = childHeight or 0
                totalChildWidth = totalChildWidth + childWidth
                if childHeight > maxChildHeight then maxChildHeight = childHeight end
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
            or spacingSetting == UIKit_Define.Percentage and UIKit_Utils:CalculateRelativePercentage(containerWidth, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta)
            or 0

        local contentWidth = totalChildWidth + ((visibleCount - 1) * spacing)

        -- Apply fit-to-content sizing
        local fitWidthToContent, fitHeightToContent = self:GetFitContent()
        if fitWidthToContent then
            containerWidth = self:ResolveFitSize("width", contentWidth, self.uk_prop_width)
            self:SetWidth(containerWidth)
        end
        if fitHeightToContent then
            containerHeight = self:ResolveFitSize("height", maxChildHeight, self.uk_prop_height)
            self:SetHeight(containerHeight)
        end

        -- Calculate start position based on horizontal alignment
        local alignmentH = self.uk_prop_layoutAlignmentH or "LEADING"
        local currentX = alignmentH == "JUSTIFIED" and (containerWidth - contentWidth) * 0.5
            or alignmentH == "TRAILING" and containerWidth - contentWidth
            or 0

        -- Position children
        local alignmentV = self.uk_prop_layoutAlignmentV or "LEADING"

        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth, childHeight = child:GetSize()
            childWidth = childWidth or 0
            childHeight = childHeight or 0

            local verticalOffset = alignmentV == "JUSTIFIED" and (containerHeight - childHeight) * 0.5
                or alignmentV == "TRAILING" and containerHeight - childHeight
                or 0

            if index > 1 then
                currentX = currentX + spacing
            end

            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", currentX, -verticalOffset)

            currentX = currentX + childWidth
        end
    end


    -- Property
    --------------------------------

    function LayoutHorizontalMixin:GetAlignmentH()
        return self.uk_prop_layoutAlignmentH or "LEADING"
    end

    function LayoutHorizontalMixin:SetAlignmentH(layoutAlignmentH)
        self.uk_prop_layoutAlignmentH = layoutAlignmentH
        self:RenderElements()
    end

    function LayoutHorizontalMixin:GetAlignmentV()
        return self.uk_prop_layoutAlignmentV or "LEADING"
    end

    function LayoutHorizontalMixin:SetAlignmentV(layoutAlignmentV)
        self.uk_prop_layoutAlignmentV = layoutAlignmentV
        self:RenderElements()
    end
end


function UIKit_Primitives_LayoutHorizontal.New(name, parent)
    name = name or "undefined"


    local LayoutHorizontal = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(LayoutHorizontal, LayoutHorizontalMixin)
    LayoutHorizontal:Init()


    return LayoutHorizontal
end
