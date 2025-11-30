local env = select(2, ...)
local UIKit_Renderer_Cleaner = env.WPM:Import("wpm_modules/ui-kit/renderer/cleaner")
local UIKit_Define = env.WPM:Import("wpm_modules/ui-kit/define")
local UIKit_Renderer_Scanner = env.WPM:New("wpm_modules/ui-kit/renderer/scanner")

local AddDirty = UIKit_Renderer_Cleaner.AddDirty
local UIKit_Define_Percentage = UIKit_Define.Percentage
local UIKit_Define_Num = UIKit_Define.Num
local UIKit_Define_Fit = UIKit_Define.Fit

local LAYOUT_TYPES = {
    Grid = true,
    VStack = true,
    HStack = true
}


-- Internal
--------------------------------

local function analyzeFrameProperty(frame)
    local frameType = frame.uk_type
    local isLayoutType = LAYOUT_TYPES[frameType]
    
    -- Point
    --------------------------------

    if frame.uk_prop_point then
        AddDirty(UIKit_Renderer_Cleaner, "Point", frame)
    end
    
    -- Anchor
    --------------------------------

    if frame.uk_prop_anchor then
        AddDirty(UIKit_Renderer_Cleaner, "Anchor", frame)
    end
    
    -- Position (x/y)
    --------------------------------

    local propX = frame.uk_prop_x
    local propY = frame.uk_prop_y
    if (propX == UIKit_Define_Percentage or propX == UIKit_Define_Num) or (propY == UIKit_Define_Percentage or propY == UIKit_Define_Num) then
        AddDirty(UIKit_Renderer_Cleaner, "PositionOffset", frame)
    end
    
    -- Size (width/height)
    --------------------------------

    local propWidth = frame.uk_prop_width
    local propHeight = frame.uk_prop_height
    local hasPercentageSize = (propWidth == UIKit_Define_Percentage or propHeight == UIKit_Define_Percentage)
    local hasFitSize = (propWidth == UIKit_Define_Fit or propHeight == UIKit_Define_Fit)
    
    if hasPercentageSize then
        AddDirty(UIKit_Renderer_Cleaner, "SizeStatic", frame)
    end
    
    if hasFitSize then
        AddDirty(UIKit_Renderer_Cleaner, "SizeFit", frame)
    end
    
    -- Layout (if width or height changed and frame is a layout type)
    --------------------------------

    if isLayoutType and (propWidth or propHeight) then
        AddDirty(UIKit_Renderer_Cleaner, "Layout", frame)
    end
    
    -- Size Fill
    --------------------------------

    if frame.uk_prop_fill then
        AddDirty(UIKit_Renderer_Cleaner, "SizeFill", frame)
    end
    
    -- Scroll Bar
    --------------------------------

    if frameType == "ScrollBar" then
        AddDirty(UIKit_Renderer_Cleaner, "ScrollBar", frame)
    end
end

local function scan(frame)
    analyzeFrameProperty(frame)
    
    -- ScrollView/LazyScrollView Content
    local contentFrame = frame.GetContentFrame and frame:GetContentFrame()
    if contentFrame then
        scan(contentFrame)
    end
    
    -- Child frames
    local children = frame.GetFrameChildren and frame:GetFrameChildren()
    if children then
        for i = 1, #children do
            if not children[i].uk_flag_renderBreakpoint then
                scan(children[i])
            end
        end
    end
end


-- API
--------------------------------

function UIKit_Renderer_Scanner.ScanFrame(rootFrame)
    scan(rootFrame)
end
