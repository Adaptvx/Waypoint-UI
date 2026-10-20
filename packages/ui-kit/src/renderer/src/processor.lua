local env = select(2, ...)
local UIKit_Define = env.modules:Import("packages\\ui-kit\\define")
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local UIKit_Renderer_Positioning = env.modules:Import("packages\\ui-kit\\renderer\\positioning")
local UIKit_Renderer_Processor = env.modules:New("packages\\ui-kit\\renderer\\processor")

local type = type
local UIKit_Define_Percentage = UIKit_Define.Percentage

function UIKit_Renderer_Processor.SizeFit(frame)
    if frame.CustomFitContent then
        frame:CustomFitContent()
    elseif frame.FitContent then
        frame:FitContent()
    end
end

function UIKit_Renderer_Processor.SizeStatic(frame)
    local parent = frame:GetParent() or UIParent

    local width = frame.uk_prop_width
    if width and frame.__layoutNaturalWidth == nil then
        if type(width) == "number" then
            frame:SetWidth(width)
        elseif width == UIKit_Define_Percentage then
            frame:SetWidth(UIKit_Utils:CalculateRelativePercentage(parent:GetWidth(), width.value, width.operator, width.delta, frame))
        end
    end

    local height = frame.uk_prop_height
    if height and frame.__layoutNaturalHeight == nil then
        if type(height) == "number" then
            frame:SetHeight(height)
        elseif height == UIKit_Define_Percentage then
            frame:SetHeight(UIKit_Utils:CalculateRelativePercentage(parent:GetHeight(), height.value, height.operator, height.delta, frame))
        end
    end
end

function UIKit_Renderer_Processor.SizeFill(frame)
    UIKit_Renderer_Positioning.Fill(frame, frame.uk_prop_fill)
end

function UIKit_Renderer_Processor.Point(frame)
    UIKit_Renderer_Positioning.SetPoint(frame, frame.uk_prop_point, frame.uk_prop_point_relative)
end

function UIKit_Renderer_Processor.Anchor(frame)
    UIKit_Renderer_Positioning.SetAnchor(frame, frame.uk_prop_anchor)
end

function UIKit_Renderer_Processor.PositionOffset(frame)
    local parent = frame:GetParent() or UIParent

    local xProp = frame.uk_prop_x
    local yProp = frame.uk_prop_y
    local x, y = nil, nil

    if xProp then
        if type(xProp) == "number" then
            x = xProp
        elseif xProp == UIKit_Define_Percentage then
            x = UIKit_Utils:CalculateRelativePercentage(parent:GetWidth(), xProp.value, xProp.operator, xProp.delta, frame)
        end
    end

    if yProp then
        if type(yProp) == "number" then
            y = yProp
        elseif yProp == UIKit_Define_Percentage then
            y = UIKit_Utils:CalculateRelativePercentage(parent:GetHeight(), yProp.value, yProp.operator, yProp.delta, frame)
        end
    end

    if x ~= nil and y ~= nil then
        UIKit_Renderer_Positioning.SetOffset(frame, x, y)
    else
        if x ~= nil then UIKit_Renderer_Positioning.SetOffsetX(frame, x) end
        if y ~= nil then UIKit_Renderer_Positioning.SetOffsetY(frame, y) end
    end
end

function UIKit_Renderer_Processor.Layout(frame)
    local frameType = frame.uk_type
    if frameType == "LayoutGrid" or frameType == "LayoutVertical" or frameType == "LayoutHorizontal" then
        frame:RenderElements()
    end
end

function UIKit_Renderer_Processor.ScrollBar(frame)
    frame:SetThumbSize()
    frame:SyncValue()
end

function UIKit_Renderer_Processor.RefreshLayoutSize(frame)
    UIKit_Renderer_Processor.SizeStatic(frame)
    if frame.uk_prop_fill then UIKit_Renderer_Processor.SizeFill(frame) end
    UIKit_Renderer_Processor.PositionOffset(frame)

    local contentFrame = frame.GetContentFrame and frame:GetContentFrame()
    if contentFrame then UIKit_Renderer_Processor.SizeStatic(contentFrame) end
    local children = frame:GetFrameChildren()
    if children then
        for i = 1, #children do
            local child = children[i]
            if child and not child.uk_flag_renderBreakpoint then
                UIKit_Renderer_Processor.RefreshLayoutSize(child)
            end
        end
    end

    if contentFrame then UIKit_Renderer_Processor.SizeFit(contentFrame) end
    UIKit_Renderer_Processor.SizeFit(frame)
    UIKit_Renderer_Processor.Layout(frame)
end

function UIKit_Renderer_Processor.LayoutStretch(frame, width, height)
    local isChanged = false
    if width ~= nil then
        width = frame:ResolveFitSize("width", width)
        isChanged = frame.__layoutNaturalWidth == nil or frame:GetWidth() ~= width
        frame.__layoutNaturalWidth = frame.__layoutNaturalWidth or frame:GetWidth() or 0
        if frame:GetWidth() ~= width then frame:SetWidth(width) end
    end
    if height ~= nil then
        height = frame:ResolveFitSize("height", height)
        isChanged = isChanged or frame.__layoutNaturalHeight == nil or frame:GetHeight() ~= height
        frame.__layoutNaturalHeight = frame.__layoutNaturalHeight or frame:GetHeight() or 0
        if frame:GetHeight() ~= height then frame:SetHeight(height) end
    end
    if isChanged then UIKit_Renderer_Processor.RefreshLayoutSize(frame) end
    return isChanged
end
