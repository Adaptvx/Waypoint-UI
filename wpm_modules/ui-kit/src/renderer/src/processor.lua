local env                        = select(2, ...)
local UIKit_Define               = env.WPM:Import("wpm_modules\\ui-kit\\define")
local UIKit_Utils                = env.WPM:Import("wpm_modules\\ui-kit\\utils")
local UIKit_Renderer_Positioning = env.WPM:Import("wpm_modules\\ui-kit\\renderer\\positioning")
local UIKit_Renderer_Processor   = env.WPM:New("wpm_modules\\ui-kit\\renderer\\processor")


-- Size — Fit
----------------------------------------------------------------------------------------------------

local function ProcessSizeFit(frame)
    if frame.CustomFitContent then
        frame:CustomFitContent()
    elseif frame.FitContent then
        frame:FitContent()
    end
end
UIKit_Renderer_Processor.SizeFit = ProcessSizeFit


-- Size — Num / Percentage
----------------------------------------------------------------------------------------------------

local function ProcessSizeStatic(frame)
    local parent = frame:GetParent() or UIParent

    local width = frame.uk_prop_width
    if width then
        if type(width) == "number" then
            frame:SetWidth(width)
        elseif width == UIKit_Define.Percentage then
            frame:SetWidth(UIKit_Utils:CalculateRelativePercentage(parent:GetWidth(), width.value, width.operator, width.delta, frame))
        end
    end

    local height = frame.uk_prop_height
    if height then
        if type(height) == "number" then
            frame:SetHeight(height)
        elseif height == UIKit_Define.Percentage then
            frame:SetHeight(UIKit_Utils:CalculateRelativePercentage(parent:GetHeight(), height.value, height.operator, height.delta, frame))
        end
    end
end
UIKit_Renderer_Processor.SizeStatic = ProcessSizeStatic


-- Size — Fill
----------------------------------------------------------------------------------------------------

local function ProcessSizeFill(frame)
    UIKit_Renderer_Positioning.Fill(frame, frame.uk_prop_fill)
end
UIKit_Renderer_Processor.SizeFill = ProcessSizeFill


-- Point
----------------------------------------------------------------------------------------------------

local function ProcessPositionPoint(frame)
    UIKit_Renderer_Positioning.SetPoint(frame, frame.uk_prop_point, frame.uk_prop_point_relative)
end
UIKit_Renderer_Processor.Point = ProcessPositionPoint


local function ProcessPositionAnchor(frame)
    UIKit_Renderer_Positioning.SetAnchor(frame, frame.uk_prop_anchor)
end
UIKit_Renderer_Processor.Anchor = ProcessPositionAnchor


local function ProcessPositionOffset(frame)
    local parent = frame:GetParent() or UIParent

    local xProp = frame.uk_prop_x
    local yProp = frame.uk_prop_y

    local x, y

    if xProp then
        if type(xProp) == "number" then
            x = xProp
        elseif xProp == UIKit_Define.Percentage then
            x = UIKit_Utils:CalculateRelativePercentage(parent:GetWidth(), xProp.value, xProp.operator, xProp.delta, frame)
        end
    end

    if yProp then
        if type(yProp) == "number" then
            y = yProp
        elseif yProp == UIKit_Define.Percentage then
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
UIKit_Renderer_Processor.PositionOffset = ProcessPositionOffset


-- Layout Group
----------------------------------------------------------------------------------------------------

local function ProcessUpdateLayout(frame)
    local frameType = frame.uk_type
    if frameType == "LayoutGrid" or frameType == "LayoutVertical" or frameType == "LayoutHorizontal" then
        frame:RenderElements()
    end
end
UIKit_Renderer_Processor.Layout = ProcessUpdateLayout


-- Scroll Bar
----------------------------------------------------------------------------------------------------

local function ProcessUpdateScrollBar(frame)
    frame:SetThumbSize()
    frame:SyncValue()
end
UIKit_Renderer_Processor.ScrollBar = ProcessUpdateScrollBar
