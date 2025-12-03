local env                         = select(2, ...)
local MixinUtil                   = env.WPM:Import("wpm_modules/mixin-util")
local UIKit_Define                = env.WPM:Import("wpm_modules/ui-kit/define")
local UIKit_Utils                 = env.WPM:Import("wpm_modules/ui-kit/utils")

local Mixin                       = MixinUtil.Mixin
local wipe                        = wipe
local ipairs                      = ipairs
local math                        = math
local tonumber                    = tonumber
local type                        = type

local UIKit_Primitives_Frame      = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")
local UIKit_Primitives_LayoutGrid = env.WPM:New("wpm_modules/ui-kit/primitives/layout-grid")


local LayoutGridMixin = {}
do
    function LayoutGridMixin:Init()
        self.__visibleChildren = {}
    end


    function LayoutGridMixin:RenderElements()
        local children = self:GetFrameChildren()
        if not children then return end

        local visibleChildren = self.__visibleChildren
        wipe(visibleChildren)

        local visibleCount = 0

        for _, child in ipairs(children) do
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations and child.uk_type ~= "List" then
                visibleCount = visibleCount + 1
                visibleChildren[visibleCount] = child
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

        local rawColumns = tonumber(self.uk_LayoutGridColumns)
        local rawRows = tonumber(self.uk_LayoutGridRows)
        local columns = rawColumns and rawColumns > 0 and rawColumns or nil
        local rows = rawRows and rawRows > 0 and rawRows or nil

        if columns then
            rows = math.ceil(visibleCount / columns)
        elseif rows then
            columns = math.ceil(visibleCount / rows)
        else
            columns = math.max(1, math.floor(math.sqrt(visibleCount)))
            rows = math.ceil(visibleCount / columns)
        end

        if columns < 1 then columns = 1 end
        if rows < 1 then rows = 1 end

        local columnWidths = {}
        local rowHeights = {}

        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth, childHeight = child:GetSize()
            childWidth = childWidth or 0
            childHeight = childHeight or 0

            local colIndex = ((index - 1) % columns) + 1
            local rowIndex = math.floor((index - 1) / columns) + 1

            local currentColWidth = columnWidths[colIndex] or 0
            if childWidth > currentColWidth then
                columnWidths[colIndex] = childWidth
            end

            local currentRowHeight = rowHeights[rowIndex] or 0
            if childHeight > currentRowHeight then
                rowHeights[rowIndex] = childHeight
            end
        end

        local spacingSetting = self:GetSpacing()
        local spacingH, spacingV

        if type(spacingSetting) == "number" then
            spacingH, spacingV = spacingSetting, spacingSetting
        elseif spacingSetting == UIKit_Define.Num then
            local value = spacingSetting.value or 0
            spacingH, spacingV = value, value
        elseif spacingSetting == UIKit_Define.Percentage then
            spacingH = UIKit_Utils:CalculateRelativePercentage(containerWidth, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta, self)
            spacingV = UIKit_Utils:CalculateRelativePercentage(containerHeight, spacingSetting.value or 0, spacingSetting.operator, spacingSetting.delta, self)
        else
            spacingH, spacingV = 0, 0
        end

        local contentWidth, contentHeight = 0, 0

        for col = 1, columns do
            contentWidth = contentWidth + (columnWidths[col] or 0)
        end
        for row = 1, rows do
            contentHeight = contentHeight + (rowHeights[row] or 0)
        end

        if columns > 1 then
            contentWidth = contentWidth + (columns - 1) * spacingH
        end
        if rows > 1 then
            contentHeight = contentHeight + (rows - 1) * spacingV
        end

        local fitWidthToContent, fitHeightToContent = self:GetFitContent()
        if fitWidthToContent then
            containerWidth = self:ResolveFitSize("width", contentWidth, self.uk_prop_width)
            self:SetWidth(containerWidth)
        end
        if fitHeightToContent then
            containerHeight = self:ResolveFitSize("height", contentHeight, self.uk_prop_height)
            self:SetHeight(containerHeight)
        end

        local alignmentH = self.uk_prop_layoutAlignmentH or "LEADING"
        local alignmentV = self.uk_prop_layoutAlignmentV or "LEADING"

        local startX = alignmentH == "JUSTIFIED" and (containerWidth - contentWidth) * 0.5
            or alignmentH == "TRAILING" and (containerWidth - contentWidth)
            or 0

        local startY = alignmentV == "JUSTIFIED" and (containerHeight - contentHeight) * 0.5
            or alignmentV == "TRAILING" and (containerHeight - contentHeight)
            or 0

        local columnOffsets = {}
        local rowOffsets = {}

        local accumX = startX
        for col = 1, columns do
            columnOffsets[col] = accumX
            accumX = accumX + (columnWidths[col] or 0) + spacingH
        end

        local accumY = startY
        for row = 1, rows do
            rowOffsets[row] = accumY
            accumY = accumY + (rowHeights[row] or 0) + spacingV
        end

        for index = 1, visibleCount do
            local child = visibleChildren[index]
            local childWidth, childHeight = child:GetSize()
            childWidth = childWidth or 0
            childHeight = childHeight or 0

            local colIndex = ((index - 1) % columns) + 1
            local rowIndex = math.floor((index - 1) / columns) + 1

            local cellWidth = columnWidths[colIndex] or 0
            local cellHeight = rowHeights[rowIndex] or 0

            local innerOffsetX = alignmentH == "JUSTIFIED" and (cellWidth - childWidth) * 0.5
                or alignmentH == "TRAILING" and (cellWidth - childWidth)
                or 0

            if innerOffsetX < 0 then innerOffsetX = 0 end

            local innerOffsetY = alignmentV == "JUSTIFIED" and (cellHeight - childHeight) * 0.5
                or alignmentV == "TRAILING" and (cellHeight - childHeight)
                or 0

            if innerOffsetY < 0 then innerOffsetY = 0 end

            local x = (columnOffsets[colIndex] or 0) + innerOffsetX
            local y = (rowOffsets[rowIndex] or 0) + innerOffsetY

            child:ClearAllPoints()
            child:SetPoint("TOPLEFT", self, "TOPLEFT", x, -y)
        end
    end


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
