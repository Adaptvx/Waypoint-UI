local env                         = select(2, ...)
local UIKit_Define                = env.WPM:Import("wpm_modules\\ui-kit\\define")
local UIKit_Utils                 = env.WPM:Import("wpm_modules\\ui-kit\\utils")

local Mixin                       = Mixin
local wipe                        = wipe
local math                        = math
local tonumber                    = tonumber
local type                        = type

local UIKit_Primitives_Frame      = env.WPM:Import("wpm_modules\\ui-kit\\primitives\\frame")
local UIKit_Primitives_LayoutGrid = env.WPM:New("wpm_modules\\ui-kit\\primitives\\layout-grid")


-- Layout (Grid)
----------------------------------------------------------------------------------------------------

local LayoutGridMixin = {}
do
    -- Init
    ----------------------------------------------------------------------------------------------------

    function LayoutGridMixin:Init()
        self.__visibleChildren = {}
        self.__columnWidths    = {}
        self.__rowHeights      = {}
        self.__columnOffsets   = {}
        self.__rowOffsets      = {}
        self.__cachedWidths    = {}
        self.__cachedHeights   = {}
    end


    -- Layout
    ----------------------------------------------------------------------------------------------------

    local function ResolveSpacing(spacingSetting, refWidth, refHeight)
        if not spacingSetting then return 0, 0 end
        local spacingType = type(spacingSetting) == "number" and "num"
            or spacingSetting == UIKit_Define.Percentage and "percent"
            or nil
        if spacingType == "num" then
            return spacingSetting, spacingSetting
        elseif spacingType == "percent" then
            local pctVal, op, delta = spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta
            return UIKit_Utils:CalculateRelativePercentage(refWidth, pctVal, op, delta),
                UIKit_Utils:CalculateRelativePercentage(refHeight, pctVal, op, delta)
        end
        return 0, 0
    end

    local function ComputeGridDimensions(visibleChildCount, requestedColumns, requestedRows)
        local columnCount, rowCount

        if requestedColumns and requestedColumns > 0 then
            columnCount = requestedColumns
            rowCount = math.ceil(visibleChildCount / columnCount)
        elseif requestedRows and requestedRows > 0 then
            rowCount = requestedRows
            columnCount = math.ceil(visibleChildCount / rowCount)
        else
            columnCount = math.max(1, math.floor(math.sqrt(visibleChildCount)))
            rowCount = math.ceil(visibleChildCount / columnCount)
        end

        return math.max(1, columnCount), math.max(1, rowCount)
    end

    function LayoutGridMixin:RenderElements()
        local allChildren = self:GetFrameChildren()
        if not allChildren then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        local visibleChildCount = 0
        for childIndex = 1, #allChildren do
            local child = allChildren[childIndex]
            local isLayoutChild = child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List"
            if isLayoutChild then
                visibleChildCount = visibleChildCount + 1
                visibleChildren[visibleChildCount] = child
            end
        end

        if visibleChildCount == 0 then return end

        local parent = self:GetParent()
        local containerWidth, containerHeight = self:GetSize()
        containerWidth = containerWidth or (parent and parent:GetWidth()) or UIParent:GetWidth()
        containerHeight = containerHeight or (parent and parent:GetHeight()) or UIParent:GetHeight()

        local horizontalSpacing, verticalSpacing = ResolveSpacing(self:GetSpacing(), containerWidth, containerHeight)
        local horizontalAlignment = self.uk_prop_layoutAlignmentH or "LEADING"
        local verticalAlignment = self.uk_prop_layoutAlignmentV or "LEADING"

        local cachedWidths = self.__cachedWidths
        local cachedHeights = self.__cachedHeights
        local rowHeights = self.__rowHeights
        local columnWidths = self.__columnWidths

        local currentRowIndex = 1
        local currentRowWidth = 0
        local currentRowMaxHeight = 0

        for childIndex = 1, visibleChildCount do
            local child = visibleChildren[childIndex]
            local childWidth, childHeight = child:GetSize()
            childWidth, childHeight = childWidth or 0, childHeight or 0

            cachedWidths[childIndex] = childWidth
            cachedHeights[childIndex] = childHeight
            columnWidths[childIndex] = currentRowIndex

            local requiredWidth = currentRowWidth + childWidth
            if currentRowWidth > 0 then requiredWidth = requiredWidth + horizontalSpacing end

            if currentRowWidth > 0 and requiredWidth > containerWidth then
                rowHeights[currentRowIndex] = currentRowMaxHeight
                currentRowIndex = currentRowIndex + 1
                currentRowWidth = childWidth
                currentRowMaxHeight = childHeight
                columnWidths[childIndex] = currentRowIndex
            else
                currentRowWidth = requiredWidth
                if childHeight > currentRowMaxHeight then currentRowMaxHeight = childHeight end
            end
        end
        rowHeights[currentRowIndex] = currentRowMaxHeight

        local rowCount = currentRowIndex
        local contentHeight = 0
        for rowIndex = 1, rowCount do
            contentHeight = contentHeight + rowHeights[rowIndex]
        end
        contentHeight = contentHeight + (rowCount - 1) * verticalSpacing

        local shouldFitWidth, shouldFitHeight = self:GetFitContent()
        if shouldFitHeight then
            containerHeight = self:ResolveFitSize("height", contentHeight, self.uk_prop_height)
            self:SetHeight(containerHeight)
        end

        local gridStartY = verticalAlignment == "JUSTIFIED" and (containerHeight - contentHeight) * 0.5
            or verticalAlignment == "TRAILING" and (containerHeight - contentHeight)
            or 0

        local rowOffsets = self.__rowOffsets
        local accumulatedY = gridStartY
        for rowIndex = 1, rowCount do
            rowOffsets[rowIndex] = accumulatedY
            accumulatedY = accumulatedY + rowHeights[rowIndex] + verticalSpacing
        end

        local columnOffsets = self.__columnOffsets
        for rowIndex = 1, rowCount do columnOffsets[rowIndex] = 0 end

        currentRowIndex = 1
        local currentRowContentWidth = 0

        for childIndex = 1, visibleChildCount do
            local childWidth = cachedWidths[childIndex]
            local rowIndex = columnWidths[childIndex]

            if rowIndex ~= currentRowIndex then
                columnOffsets[currentRowIndex] = currentRowContentWidth
                currentRowIndex = rowIndex
                currentRowContentWidth = childWidth
            else
                if currentRowContentWidth > 0 then currentRowContentWidth = currentRowContentWidth + horizontalSpacing end
                currentRowContentWidth = currentRowContentWidth + childWidth
            end
        end
        columnOffsets[currentRowIndex] = currentRowContentWidth

        currentRowIndex = 1
        local currentRowXOffset = 0

        for childIndex = 1, visibleChildCount do
            local childWidth = cachedWidths[childIndex]
            local childHeight = cachedHeights[childIndex]
            local rowIndex = columnWidths[childIndex]

            if rowIndex ~= currentRowIndex then
                currentRowIndex = rowIndex
                currentRowXOffset = 0
            end

            local rowHeight = rowHeights[rowIndex]
            local rowOffsetY = rowOffsets[rowIndex]
            local rowContentWidth = columnOffsets[rowIndex]

            local gridStartX = horizontalAlignment == "JUSTIFIED" and (containerWidth - rowContentWidth) * 0.5
                or horizontalAlignment == "TRAILING" and (containerWidth - rowContentWidth)
                or 0

            local cellOffsetY = verticalAlignment == "JUSTIFIED" and (rowHeight - childHeight) * 0.5
                or verticalAlignment == "TRAILING" and (rowHeight - childHeight)
                or 0

            if cellOffsetY < 0 then cellOffsetY = 0 end

            local child = visibleChildren[childIndex]
            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", gridStartX + currentRowXOffset, -(rowOffsetY + cellOffsetY))

            currentRowXOffset = currentRowXOffset + childWidth + horizontalSpacing
        end
    end


    -- Property
    ----------------------------------------------------------------------------------------------------

    function LayoutGridMixin:GetAlignmentH()
        return self.uk_prop_layoutAlignmentH or "LEADING"
    end

    function LayoutGridMixin:SetAlignmentH(layoutAlignmentH)
        self.uk_prop_layoutAlignmentH = layoutAlignmentH
        self:RenderElements()
    end

    function LayoutGridMixin:GetAlignmentV()
        return self.uk_prop_layoutAlignmentV or "LEADING"
    end

    function LayoutGridMixin:SetAlignmentV(layoutAlignmentV)
        self.uk_prop_layoutAlignmentV = layoutAlignmentV
        self:RenderElements()
    end

    function LayoutGridMixin:GetColumns()
        return self.uk_LayoutGridColumns
    end

    function LayoutGridMixin:SetColumns(columns)
        self.uk_LayoutGridColumns = tonumber(columns)
        self:RenderElements()
    end

    function LayoutGridMixin:GetRows()
        return self.uk_LayoutGridRows
    end

    function LayoutGridMixin:SetRows(rows)
        self.uk_LayoutGridRows = tonumber(rows)
        self:RenderElements()
    end
end


function UIKit_Primitives_LayoutGrid.New(name, parent)
    name = name or "undefined"


    local LayoutGrid = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(LayoutGrid, LayoutGridMixin)
    LayoutGrid:Init()


    return LayoutGrid
end
