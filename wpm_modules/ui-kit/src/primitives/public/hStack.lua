local env          = select(2, ...)
local MixinUtil    = env.WPM:Import("wpm_modules/mixin-util")
local UIKit_Utils  = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Define = env.WPM:Import("wpm_modules/ui-kit/define")
local Frame        = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")

local Mixin        = MixinUtil.Mixin
local wipe         = wipe

local HStack       = env.WPM:New("wpm_modules/ui-kit/primitives/hStack")




local HStackMixin = {}
do
    -- Init
    --------------------------------

    function HStackMixin:Init()
        self.__visibleChildren = {}
    end


    -- Layout
    --------------------------------

    function HStackMixin:RenderElements()
        local children = self:GetFrameChildren()
        if not children then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        -- Collect visible children and calculate dimensions
        local totalChildWidth, maxChildHeight, visibleCount = 0, 0, 0

        for _, child in ipairs(children) do
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations then
                visibleCount = visibleCount + 1
                visibleChildren[visibleCount] = child

                local childWidth = child:GetWidth() or 0
                local childHeight = child:GetHeight() or 0
                totalChildWidth = totalChildWidth + childWidth
                if childHeight > maxChildHeight then maxChildHeight = childHeight end
            end
        end

        if visibleCount == 0 then return end

        local parent = self:GetParent()
        local containerWidth = self:GetWidth() or (parent and parent:GetWidth()) or UIParent:GetWidth()
        local containerHeight = self:GetHeight() or (parent and parent:GetHeight()) or UIParent:GetHeight()

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
        local accountedSpacing = (visibleCount > 2 and spacing or 0)
        local alignmentH = self.uk_prop_layoutAlignmentH or "LEADING"
        local currentX = alignmentH == "JUSTIFIED" and (containerWidth - contentWidth - accountedSpacing) * 0.5
            or alignmentH == "TRAILING" and containerWidth - contentWidth
            or 0

        -- Position children
        local alignmentV = self.uk_prop_layoutAlignmentV or "LEADING"

        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth = child:GetWidth() or 0
            local childHeight = child:GetHeight() or 0

            local verticalOffset = alignmentV == "JUSTIFIED" and (containerHeight - childHeight) * 0.5
                or alignmentV == "TRAILING" and containerHeight - childHeight
                or 0

            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", currentX, -verticalOffset)

            currentX = currentX + childWidth + spacing
        end
    end

    -- Property
    --------------------------------

    function HStackMixin:GetAlignmentH()
        return self.uk_prop_layoutAlignmentH or "LEADING"
    end

    function HStackMixin:SetAlignmentH(layoutAlignmentH)
        self.uk_prop_layoutAlignmentH = layoutAlignmentH
        self:RenderElements()
    end

    function HStackMixin:GetAlignmentV()
        return self.uk_prop_layoutAlignmentV or "LEADING"
    end

    function HStackMixin:SetAlignmentV(layoutAlignmentV)
        self.uk_prop_layoutAlignmentV = layoutAlignmentV
        self:RenderElements()
    end
end




function HStack:New(name, parent)
    name = name or "undefined"


    local hStack = Frame:New("Frame", name, parent)
    Mixin(hStack, HStackMixin)
    hStack:Init()


    return hStack
end
