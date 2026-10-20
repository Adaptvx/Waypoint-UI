local env = select(2, ...)
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local UIKit_Enum = env.modules:Import("packages\\ui-kit\\enum")
local UIKit_Define = env.modules:Import("packages\\ui-kit\\define")
local UIKit_Primitives_Frame = env.modules:Import("packages\\ui-kit\\primitives\\frame")
local UIKit_Renderer_Processor = env.modules:Await("packages\\ui-kit\\renderer\\processor")
local UIKit_Primitives_LayoutHorizontal = env.modules:New("packages\\ui-kit\\primitives\\layout-horizontal")

local Mixin = Mixin
local max = math.max
local type = type
local UIKit_Enum_Direction_Leading = UIKit_Enum.Direction.Leading
local UIKit_Enum_Direction_Justified = UIKit_Enum.Direction.Justified
local UIKit_Enum_Direction_Trailing = UIKit_Enum.Direction.Trailing
local UIKit_Define_Percentage = UIKit_Define.Percentage


local LayoutHorizontalMixin = {}

function LayoutHorizontalMixin:OnLoad()
    self.__visibleChildren = {}
    self.__cachedWidths = {}
    self.__cachedHeights = {}
    self.__growBaseWidths = {}
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

function LayoutHorizontalMixin:RenderElements()
    local allChildren = self:GetFrameChildren()
    if not allChildren then return end

    local visibleChildren = self.__visibleChildren
    local cachedWidths = self.__cachedWidths
    local cachedHeights = self.__cachedHeights
    local growBaseWidths = self.__growBaseWidths
    local prevCount = self.__visibleCount or 0
    local horizontalAlignment = self.uk_prop_layoutAlignmentH or UIKit_Enum_Direction_Leading
    local verticalAlignment = self.uk_prop_layoutAlignmentV or UIKit_Enum_Direction_Leading
    local stretchHeight = self:GetStretchV()

    local totalChildrenWidth, maxChildHeight, visibleChildCount, totalGrow, totalPush = 0, 0, 0, 0, 0

    for childIndex = 1, #allChildren do
        local child = allChildren[childIndex]
        local isLayoutChild = child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List"
        if child and (not isLayoutChild or not stretchHeight) and child:ResetLayoutStretch() then
            UIKit_Renderer_Processor.RefreshLayoutSize(child)
        end
        if isLayoutChild then
            visibleChildCount = visibleChildCount + 1
            visibleChildren[visibleChildCount] = child

            local childWidth, childHeight = child:GetLayoutSize()
            childWidth, childHeight = childWidth or 0, childHeight or 0

            local grow = child.uk_prop_layoutGrow or 0
            local growBaseWidth = growBaseWidths[child]
            if grow > 0 then
                if growBaseWidth == nil then
                    growBaseWidth = childWidth
                    growBaseWidths[child] = growBaseWidth
                end
                childWidth = growBaseWidth
                totalGrow = totalGrow + grow
            elseif growBaseWidth ~= nil then
                childWidth = growBaseWidth
                growBaseWidths[child] = nil
                if child:GetWidth() ~= childWidth then child:SetWidth(childWidth) end
            end

            cachedWidths[visibleChildCount] = childWidth
            cachedHeights[visibleChildCount] = childHeight

            totalChildrenWidth = totalChildrenWidth + childWidth
            if childHeight > maxChildHeight then maxChildHeight = childHeight end
            if child.uk_prop_layoutPushH then totalPush = totalPush + 1 end
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

    local spacing = ResolveSpacing(self:GetSpacing(), containerWidth)
    local shouldFitWidth, shouldFitHeight = self:GetFitContent()
    if shouldFitHeight then
        containerHeight = self:ResolveFitSize("height", maxChildHeight, self.uk_prop_height)
        self:SetHeight(containerHeight)
    end

    if stretchHeight then
        totalChildrenWidth = 0
        for childIndex = 1, visibleChildCount do
            local child = visibleChildren[childIndex]
            local grow = child.uk_prop_layoutGrow or 0
            if UIKit_Renderer_Processor.LayoutStretch(child, nil, containerHeight) then
                cachedWidths[childIndex] = child:GetWidth() or 0
                if grow > 0 then growBaseWidths[child] = cachedWidths[childIndex] end
            end
            cachedHeights[childIndex] = child:GetHeight() or 0
            totalChildrenWidth = totalChildrenWidth + cachedWidths[childIndex]
        end
    end

    local contentWidth = totalChildrenWidth + max(0, visibleChildCount - 1) * spacing
    if shouldFitWidth then
        containerWidth = self:ResolveFitSize("width", contentWidth, self.uk_prop_width)
        self:SetWidth(containerWidth)
    end

    if totalGrow > 0 then
        local remainingWidth = max(0, containerWidth - contentWidth)
        for childIndex = 1, visibleChildCount do
            local child = visibleChildren[childIndex]
            local grow = child.uk_prop_layoutGrow or 0
            if grow > 0 then
                local childWidth = cachedWidths[childIndex] + remainingWidth * grow / totalGrow
                cachedWidths[childIndex] = childWidth
                if child:GetWidth() ~= childWidth then child:SetWidth(childWidth) end
            end
        end
        contentWidth = contentWidth + remainingWidth
    end

    local pushSpacing = 0
    if totalPush > 0 then
        local remainingWidth = max(0, containerWidth - contentWidth)
        pushSpacing = remainingWidth / totalPush
        contentWidth = contentWidth + remainingWidth
    end

    local currentX = horizontalAlignment == UIKit_Enum_Direction_Justified and (containerWidth - contentWidth) * 0.5
        or horizontalAlignment == UIKit_Enum_Direction_Trailing and (containerWidth - contentWidth)
        or 0

    for childIndex = 1, visibleChildCount do
        local child = visibleChildren[childIndex]
        local childWidth = cachedWidths[childIndex]
        local childHeight = cachedHeights[childIndex]

        if child.uk_prop_layoutPushH then currentX = currentX + pushSpacing end

        local verticalOffset = verticalAlignment == UIKit_Enum_Direction_Justified and (containerHeight - childHeight) * 0.5
            or verticalAlignment == UIKit_Enum_Direction_Trailing and (containerHeight - childHeight)
            or 0

        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", self, "TOPLEFT", currentX, -verticalOffset)

        currentX = currentX + childWidth + spacing
    end
end

function LayoutHorizontalMixin:GetAlignmentH()
    return self.uk_prop_layoutAlignmentH or UIKit_Enum_Direction_Leading
end

function LayoutHorizontalMixin:SetAlignmentH(layoutAlignmentH)
    self.uk_prop_layoutAlignmentH = layoutAlignmentH
    self:RenderElements()
end

function LayoutHorizontalMixin:GetAlignmentV()
    return self.uk_prop_layoutAlignmentV or UIKit_Enum_Direction_Leading
end

function LayoutHorizontalMixin:SetAlignmentV(layoutAlignmentV)
    self.uk_prop_layoutAlignmentV = layoutAlignmentV
    self:RenderElements()
end

function LayoutHorizontalMixin:GetStretchV()
    return self.uk_prop_layoutStretchV == true
end

function LayoutHorizontalMixin:SetStretchV(stretch)
    assert(type(stretch) == "boolean", "Invalid variable `layoutStretchV`: Must be of type `boolean`")
    if self.uk_prop_layoutStretchV == stretch then return end
    self.uk_prop_layoutStretchV = stretch
    if self.uk_ready then self:_Render() end
end

function UIKit_Primitives_LayoutHorizontal.New(name, parent)
    name = name or "undefined"

    local frame = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(frame, LayoutHorizontalMixin)
    frame:OnLoad()

    return frame
end
