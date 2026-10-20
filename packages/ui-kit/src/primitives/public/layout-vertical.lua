local env = select(2, ...)
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local UIKit_Enum = env.modules:Import("packages\\ui-kit\\enum")
local UIKit_Define = env.modules:Import("packages\\ui-kit\\define")
local UIKit_Primitives_Frame = env.modules:Import("packages\\ui-kit\\primitives\\frame")
local UIKit_Renderer_Processor = env.modules:Await("packages\\ui-kit\\renderer\\processor")
local UIKit_Primitives_LayoutVertical = env.modules:New("packages\\ui-kit\\primitives\\layout-vertical")

local Mixin = Mixin
local max = math.max
local type = type
local UIKit_Enum_Direction_Leading = UIKit_Enum.Direction.Leading
local UIKit_Enum_Direction_Justified = UIKit_Enum.Direction.Justified
local UIKit_Enum_Direction_Trailing = UIKit_Enum.Direction.Trailing
local UIKit_Define_Percentage = UIKit_Define.Percentage


local LayoutVerticalMixin = {}

function LayoutVerticalMixin:OnLoad()
    self.__visibleChildren = {}
    self.__cachedWidths = {}
    self.__cachedHeights = {}
    self.__growBaseHeights = {}
    self.__visibleCount = 0
end

local function ResolveSpacing(spacingSetting, referenceSize)
    if not spacingSetting then return 0 end
    if type(spacingSetting) == "number" then return spacingSetting end
    if spacingSetting == UIKit_Define_Percentage then
        return UIKit_Utils:CalculateRelativePercentage(referenceSize, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta)
    end
    return 0
end

function LayoutVerticalMixin:RenderElements()
    local allChildren = self:GetFrameChildren()
    if not allChildren then return end

    local visibleChildren = self.__visibleChildren
    local cachedWidths = self.__cachedWidths
    local cachedHeights = self.__cachedHeights
    local growBaseHeights = self.__growBaseHeights
    local prevCount = self.__visibleCount or 0
    local horizontalAlignment = self.uk_prop_layoutAlignmentH or UIKit_Enum_Direction_Leading
    local verticalAlignment = self.uk_prop_layoutAlignmentV or UIKit_Enum_Direction_Leading
    local stretchWidth = self:GetStretchH()

    local totalChildrenHeight, maxChildWidth, visibleChildCount, sizedChildCount, totalGrow, totalPush = 0, 0, 0, 0, 0, 0

    for childIndex = 1, #allChildren do
        local child = allChildren[childIndex]
        local isLayoutChild = child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List"
        if child and (not isLayoutChild or not stretchWidth) and child:ResetLayoutStretch() then
            UIKit_Renderer_Processor.RefreshLayoutSize(child)
        end
        if isLayoutChild then
            visibleChildCount = visibleChildCount + 1
            visibleChildren[visibleChildCount] = child

            local childWidth, childHeight = child:GetLayoutSize()
            childWidth, childHeight = childWidth or 0, childHeight or 0

            local grow = child.uk_prop_layoutGrow or 0
            local growBaseHeight = growBaseHeights[child]
            if grow > 0 then
                if growBaseHeight == nil then
                    growBaseHeight = childHeight
                    growBaseHeights[child] = growBaseHeight
                end
                childHeight = growBaseHeight
                totalGrow = totalGrow + grow
            elseif growBaseHeight ~= nil then
                childHeight = growBaseHeight
                growBaseHeights[child] = nil
                if child:GetHeight() ~= childHeight then child:SetHeight(childHeight) end
            end

            cachedWidths[visibleChildCount] = childWidth
            cachedHeights[visibleChildCount] = childHeight

            totalChildrenHeight = totalChildrenHeight + childHeight
            if childWidth > maxChildWidth then maxChildWidth = childWidth end
            if childHeight > 0 or grow > 0 then sizedChildCount = sizedChildCount + 1 end
            if child.uk_prop_layoutPushV then totalPush = totalPush + 1 end
        end
    end

    for i = visibleChildCount + 1, prevCount do
        visibleChildren[i] = nil
    end
    self.__visibleCount = visibleChildCount

    local parent = self:GetParent()
    local containerWidth, containerHeight = self:GetSize()
    containerWidth = containerWidth or (parent and parent:GetWidth()) or UIParent:GetWidth()
    containerHeight = containerHeight or (parent and parent:GetHeight()) or UIParent:GetHeight()

    local spacing = ResolveSpacing(self:GetSpacing(), containerHeight)
    local spacingGapCount = sizedChildCount > 1 and (sizedChildCount - 1) or 0
    local shouldFitWidth, shouldFitHeight = self:GetFitContent()
    if shouldFitWidth then
        containerWidth = self:ResolveFitSize("width", maxChildWidth, self.uk_prop_width)
        self:SetWidth(containerWidth)
    end

    if stretchWidth then
        totalChildrenHeight, sizedChildCount = 0, 0
        for childIndex = 1, visibleChildCount do
            local child = visibleChildren[childIndex]
            local grow = child.uk_prop_layoutGrow or 0
            if UIKit_Renderer_Processor.LayoutStretch(child, containerWidth) then
                cachedHeights[childIndex] = child:GetHeight() or 0
                if grow > 0 then growBaseHeights[child] = cachedHeights[childIndex] end
            end
            cachedWidths[childIndex] = child:GetWidth() or 0
            local childHeight = cachedHeights[childIndex]
            totalChildrenHeight = totalChildrenHeight + childHeight
            if childHeight > 0 or grow > 0 then sizedChildCount = sizedChildCount + 1 end
        end
        spacingGapCount = sizedChildCount > 1 and (sizedChildCount - 1) or 0
    end

    local contentHeight = totalChildrenHeight + spacingGapCount * spacing
    if shouldFitHeight then
        containerHeight = self:ResolveFitSize("height", contentHeight, self.uk_prop_height)
        self:SetHeight(containerHeight)
    end

    if totalGrow > 0 then
        local remainingHeight = max(0, containerHeight - contentHeight)
        for childIndex = 1, visibleChildCount do
            local child = visibleChildren[childIndex]
            local grow = child.uk_prop_layoutGrow or 0
            if grow > 0 then
                local childHeight = cachedHeights[childIndex] + remainingHeight * grow / totalGrow
                cachedHeights[childIndex] = childHeight
                if child:GetHeight() ~= childHeight then child:SetHeight(childHeight) end
            end
        end
        contentHeight = contentHeight + remainingHeight
    end

    local pushSpacing = 0
    if totalPush > 0 then
        local remainingHeight = max(0, containerHeight - contentHeight)
        pushSpacing = remainingHeight / totalPush
        contentHeight = contentHeight + remainingHeight
    end

    local currentY = verticalAlignment == UIKit_Enum_Direction_Justified and (containerHeight - contentHeight) * 0.5
        or verticalAlignment == UIKit_Enum_Direction_Trailing and (containerHeight - contentHeight)
        or 0

    local hasPlacedSizedChild = false
    for childIndex = 1, visibleChildCount do
        local child = visibleChildren[childIndex]
        local childWidth = cachedWidths[childIndex]
        local childHeight = cachedHeights[childIndex]

        local horizontalOffset = horizontalAlignment == UIKit_Enum_Direction_Justified and (containerWidth - childWidth) * 0.5
            or horizontalAlignment == UIKit_Enum_Direction_Trailing and (containerWidth - childWidth)
            or 0

        local grow = child.uk_prop_layoutGrow or 0
        local isSizedChild = childHeight > 0 or grow > 0
        if isSizedChild and hasPlacedSizedChild then
            currentY = currentY + spacing
        end

        if child.uk_prop_layoutPushV then currentY = currentY + pushSpacing end

        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", self, "TOPLEFT", horizontalOffset, -currentY)

        currentY = currentY + childHeight
        if isSizedChild then hasPlacedSizedChild = true end
    end
end

function LayoutVerticalMixin:GetAlignmentH()
    return self.uk_prop_layoutAlignmentH or UIKit_Enum_Direction_Leading
end

function LayoutVerticalMixin:SetAlignmentH(layoutAlignmentH)
    self.uk_prop_layoutAlignmentH = layoutAlignmentH
    self:RenderElements()
end

function LayoutVerticalMixin:GetAlignmentV()
    return self.uk_prop_layoutAlignmentV or UIKit_Enum_Direction_Leading
end

function LayoutVerticalMixin:SetAlignmentV(layoutAlignmentV)
    self.uk_prop_layoutAlignmentV = layoutAlignmentV
    self:RenderElements()
end

function LayoutVerticalMixin:GetStretchH()
    return self.uk_prop_layoutStretchH == true
end

function LayoutVerticalMixin:SetStretchH(stretch)
    assert(type(stretch) == "boolean", "Invalid variable `layoutStretchH`: Must be of type `boolean`")
    if self.uk_prop_layoutStretchH == stretch then return end
    self.uk_prop_layoutStretchH = stretch
    if self.uk_ready then self:_Render() end
end

function UIKit_Primitives_LayoutVertical.New(name, parent)
    name = name or "undefined"

    local frame = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(frame, LayoutVerticalMixin)
    frame:OnLoad()

    return frame
end
