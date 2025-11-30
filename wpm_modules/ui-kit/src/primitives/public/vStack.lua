local env          = select(2, ...)
local MixinUtil    = env.WPM:Import("wpm_modules/mixin-util")
local UIKit_Utils  = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Define = env.WPM:Import("wpm_modules/ui-kit/define")
local Frame        = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")

local Mixin        = MixinUtil.Mixin
local wipe         = wipe

local VStack       = env.WPM:New("wpm_modules/ui-kit/primitives/vStack")




local VStackMixin = {}
do
    -- Init
    --------------------------------

    function VStackMixin:Init()
        self.__visibleChildren = {}
    end


    -- Layout
    --------------------------------

    function VStackMixin:RenderElements()
        local children = self:GetFrameChildren()
        if not children then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        -- Collect visible children and calculate dimensions
        local totalChildHeight, maxChildWidth, visibleCount = 0, 0, 0

        for _, child in ipairs(children) do
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations then
                visibleCount = visibleCount + 1
                visibleChildren[visibleCount] = child

                local childWidth = child:GetWidth() or 0
                local childHeight = child:GetHeight() or 0
                totalChildHeight = totalChildHeight + childHeight
                if childWidth > maxChildWidth then maxChildWidth = childWidth end
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
            or spacingSetting == UIKit_Define.Percentage and UIKit_Utils:CalculateRelativePercentage(containerHeight, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta)
            or 0

        local contentHeight = totalChildHeight + ((visibleCount - 1) * spacing)

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
        local accountedSpacing = (visibleCount > 2 and spacing or 0)
        local alignmentV = self.uk_prop_layoutAlignmentV or "LEADING"
        local currentY = alignmentV == "JUSTIFIED" and (containerHeight - contentHeight - accountedSpacing) * 0.5
            or alignmentV == "TRAILING" and containerHeight - contentHeight
            or 0

        -- Position children
        local alignmentH = self.uk_prop_layoutAlignmentH or "LEADING"

        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth = child:GetWidth() or 0
            local childHeight = child:GetHeight() or 0

            local horizontalOffset = alignmentH == "JUSTIFIED" and (containerWidth - childWidth) * 0.5
                or alignmentH == "TRAILING" and containerWidth - childWidth
                or 0

            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", horizontalOffset, -currentY)

            currentY = currentY + childHeight + spacing
        end
    end

    -- Property
    --------------------------------

    function VStackMixin:GetAlignmentH()
        return self.uk_prop_layoutAlignmentH or "LEADING"
    end

    function VStackMixin:SetAlignmentH(layoutAlignmentH)
        self.uk_prop_layoutAlignmentH = layoutAlignmentH
        self:RenderElements()
    end

    function VStackMixin:GetAlignmentV()
        return self.uk_prop_layoutAlignmentV or "LEADING"
    end

    function VStackMixin:SetAlignmentV(layoutAlignmentV)
        self.uk_prop_layoutAlignmentV = layoutAlignmentV
        self:RenderElements()
    end
end




function VStack:New(name, parent)
    name = name or "undefined"


    local vStack = Frame:New("Frame", name, parent)
    Mixin(vStack, VStackMixin)
    vStack:Init()


    return vStack
end
