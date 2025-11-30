local env                       = select(2, ...)

local type                      = type

local UIKit_TagManager          = env.WPM:Import("wpm_modules/ui-kit/tag-manager")
local UIKit_Renderer            = env.WPM:Import("wpm_modules/ui-kit/renderer")
local UIKit_Utils               = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Define              = env.WPM:Import("wpm_modules/ui-kit/define")
local UIKit_Enum                = env.WPM:Import("wpm_modules/ui-kit/enum")
local UIKit_UI_Scanner          = env.WPM:Import("wpm_modules/ui-kit/ui/scanner")
local React                     = env.WPM:Import("wpm_modules/react")
local UIKit_Renderer_Background = env.WPM:Import("wpm_modules/ui-kit/renderer/background")
local Frame                     = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")



-- Helper
--------------------------------

-- If a frame is passed to `id`, return itself, otherwise it resolves the using the TagManager
---@param id string
---@param groupID? string
local function resolveFrameReference(id, groupID)
    if type(id) == "string" then
        if UIKit_TagManager.IsGroupCaptureString(id) then
            local newID, newGroupID = UIKit_TagManager.ReadGroupCaptureString(id)
            return UIKit_TagManager.GetElementById(newID, newGroupID)
        else
            return UIKit_TagManager.GetElementById(id, groupID)
        end
    else
        return id
    end
end

-- If the provided variable is a React variable, hook an OnChange that calls the propName on the frame
---@param frame any
---@param value any
---@param propName string
---@param argumentIndex? number
local function handleReact(frame, value, propName, argumentIndex)
    if React.IsVariable(value) then
        if not frame["uk_prop_REACT_" .. propName] then
            frame["uk_prop_REACT_" .. propName] = value

            local index = value:OnChange(function(self)
                if argumentIndex then
                    local args = {}

                    for i = 1, argumentIndex do
                        args[i] = nil
                    end
                    args[argumentIndex] = self

                    frame[propName](unpack(args))
                else
                    frame[propName](frame, value)
                end
            end)

            frame["uk_prop_REACT_" .. propName .. "_INDEX"] = index
        end

        return value:Get()
    else
        if frame["uk_prop_REACT_" .. propName] and frame["uk_prop_REACT_" .. propName .. "_INDEX"] then
            frame["uk_prop_REACT_" .. propName]:OffChange(frame["uk_prop_REACT_" .. propName .. "_INDEX"])
        end
    end

    return value
end



-- General
--------------------------------

do -- TagManager
    Frame.FrameProps["id"] = function(frame, value, groupID)
        UIKit_TagManager.Id.Add(frame, value, groupID)
    end

    Frame.FrameProps["class"] = function(frame, value, groupID)
        UIKit_TagManager.Class.Add(frame, value, groupID)
    end
end

do -- General
    Frame.FrameProps["under"] = function(frame, aliasName)
        assert(aliasName, "Invalid variable `aliasName`")

        frame.uk_prop_under = aliasName
    end

    Frame.FrameProps["parent"] = function(frame, target, targetGroupId)
        assert(target, "Invalid variable `target`")
        assert(frame.uk_type ~= "InteractiveRect", "Invalid variable `frame`: Must be of type `InteractiveRect`")

        target = resolveFrameReference(target, targetGroupId)


        local ukParent = frame:GetFrameParent()
        if ukParent == target then
            return
        end


        local actualParent = frame:GetParent()
        if actualParent and actualParent.uk_type then
            actualParent:RemoveFrameChild(frame)
        end


        if target.uk_type then
            target:AddFrameChild(frame)
        end


        frame:SetFrameParent(target)
        frame:SetParent(target)


        local frameStrata = frame.uk_prop_frameStrata
        if frameStrata then frame:frameStrata(frameStrata) end

        local frameLevel = frame.uk_prop_frameLevel
        if frameLevel then frame:frameLevel(frameLevel) end
    end


    Frame.FrameProps["frameStrata"] = function(frame, frameStrata, frameLevel)
        assert(type(frameStrata) == "string", "Invalid variable `frameStrata`: Must be of type `string`")
        if frameLevel then assert(type(frameLevel) == "number", "Invalid variable `frameLevel`: Must be of type `number`") end

        frame.uk_prop_frameStrata = frameStrata
        frame:SetFrameStrata(frameStrata)

        if frameLevel then frame:frameLevel(frameLevel) end
    end

    Frame.FrameProps["frameLevel"] = function(frame, frameLevel)
        assert(type(frameLevel) == "number", "Invalid variable `frameLevel`: Must be of type `number`")

        frame.uk_prop_frameLevel = frameLevel
        frame:SetFrameLevel(frameLevel)
    end
end

do -- Port
    -- >>> React
    Frame.FrameProps["alpha"] = function(frame, opacity)
        opacity = handleReact(frame, opacity, "alpha")

        assert(type(opacity) == "number", "Invalid variable `opacity`: Must be of type `number`")

        frame:SetAlpha(opacity)
    end

    -- >>> React
    Frame.FrameProps["scale"] = function(frame, scale)
        scale = handleReact(frame, scale, "scale")

        assert(type(scale) == "number", "Invalid variable `scale`: Must be of type `number`")

        frame:SetScale(scale)
    end

    -- >>> React
    Frame.FrameProps["movable"] = function(frame, movable)
        movable = handleReact(frame, movable, "movable")

        assert(type(movable) == "boolean", "Invalid variable `movable`: Must be of type `boolean`")

        frame:SetMovable(movable)
    end

    -- >>> React
    Frame.FrameProps["resizable"] = function(frame, resizable)
        resizable = handleReact(frame, resizable, "resizable")

        assert(type(resizable) == "boolean", "Invalid variable `resizable`: Must be of type `boolean`")

        frame:SetResizable(resizable)
    end

    Frame.FrameProps["resizeBounds"] = function(frame, minWidth, minHeight, maxWidth, maxHeight)
        assert(type(minWidth) == "number", "Invalid variable `minWidth`: Must be of type `number`")
        assert(type(minHeight) == "number", "Invalid variable `minHeight`: Must be of type `number`")
        assert(type(maxWidth) == "number", "Invalid variable `maxWidth`: Must be of type `number`")
        assert(type(maxHeight) == "number", "Invalid variable `maxHeight`: Must be of type `number`")

        frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    end

    -- >>> React
    Frame.FrameProps["enableMouse"] = function(frame, enableMouse)
        enableMouse = handleReact(frame, enableMouse, "enableMouse")

        assert(type(enableMouse) == "boolean", "Invalid variable `enableMouse`: Must be of type `boolean`")

        frame:EnableMouse(enableMouse)
    end

    -- >>> React
    Frame.FrameProps["enableMouseMotion"] = function(frame, enableMouseMotion)
        enableMouseMotion = handleReact(frame, enableMouseMotion, "enableMouseMotion")

        assert(type(enableMouseMotion) == "boolean", "Invalid variable `enableMouseMotion`: Must be of type `boolean`")

        frame:EnableMouseMotion(enableMouseMotion)
    end

    -- >>> React
    Frame.FrameProps["enableMouseWheel"] = function(frame, enableMouseWheel)
        enableMouseWheel = handleReact(frame, enableMouseWheel, "enableMouseWheel")

        assert(type(enableMouseWheel) == "boolean", "Invalid variable `enableMouseWheel`: Must be of type `boolean`")

        frame:EnableMouseWheel(enableMouseWheel)
    end

    -- >>> React
    Frame.FrameProps["enableKeyboard"] = function(frame, enableKeyboard)
        enableKeyboard = handleReact(frame, enableKeyboard, "enableKeyboard")

        assert(type(enableKeyboard) == "boolean", "Invalid variable `enableKeyboard`: Must be of type `boolean`")

        frame:SetPropagateKeyboardInput(enableKeyboard)
    end

    -- >>> React
    Frame.FrameProps["clampedToScreen"] = function(frame, clampedToScreen)
        clampedToScreen = handleReact(frame, clampedToScreen, "clampedToScreen")

        assert(type(clampedToScreen) == "boolean", "Invalid variable `clampedToScreen`: Must be of type `boolean`")

        frame:SetClampedToScreen(clampedToScreen)
    end

    -- >>> React
    Frame.FrameProps["clipsChildren"] = function(frame, clipsChildren)
        clipsChildren = handleReact(frame, clipsChildren, "clipsChildren")

        assert(type(clipsChildren) == "boolean", "Invalid variable `clipsChildren`: Must be of type `boolean`")

        frame:SetClipsChildren(clipsChildren)
    end

    -- >>> React
    Frame.FrameProps["ignoreParentScale"] = function(frame, ignoreParentScale)
        ignoreParentScale = handleReact(frame, ignoreParentScale, "ignoreParentScale")

        assert(type(ignoreParentScale) == "boolean", "Invalid variable `ignoreParentScale`: Must be of type `boolean`")

        frame:SetIgnoreParentScale(ignoreParentScale)
    end

    -- >>> React
    Frame.FrameProps["ignoreParentAlpha"] = function(frame, ignoreParentAlpha)
        ignoreParentAlpha = handleReact(frame, ignoreParentAlpha, "ignoreParentAlpha")

        assert(type(ignoreParentAlpha) == "boolean", "Invalid variable `ignoreParentAlpha`: Must be of type `boolean`")

        frame:SetIgnoreParentAlpha(ignoreParentAlpha)
    end
end

do -- Move/Resize handle
    local function loadTargetFrame(frame)
        local id = frame.uk_prop_moveHandle_targetId or frame.uk_prop_resizeHandle_targetId
        local groupID = frame.uk_prop_moveHandle_targetGroupId or frame.uk_prop_resizeHandle_targetGroupId
        frame.uk_prop_handleTarget = UIKit_TagManager.GetElementById(id, groupID)
    end

    local function moveHandle_handleMouseDown(frame)
        if not frame.uk_prop_handleTarget then loadTargetFrame(frame) end

        assert(frame.uk_prop_handleTarget, "Invalid variable `handleTarget`")

        frame.uk_prop_handleTarget:StartMoving()
    end

    local function moveHandle_handleMouseUp(frame)
        if not frame.uk_prop_handleTarget then loadTargetFrame(frame) end

        assert(frame.uk_prop_handleTarget, "Invalid variable `handleTarget`")

        frame.uk_prop_handleTarget:StopMovingOrSizing()
    end

    local function resizeHandle_handleMouseDown(frame)
        if not frame.uk_prop_handleTarget then loadTargetFrame(frame) end

        assert(frame.uk_prop_handleTarget, "Invalid variable `handleTarget`")

        frame.uk_prop_handleTarget:StartSizing()
    end

    local function resizeHandle_handleMouseUp(frame)
        if not frame.uk_prop_handleTarget then loadTargetFrame(frame) end

        assert(frame.uk_prop_handleTarget, "Invalid variable `handleTarget`")

        frame.uk_prop_handleTarget:StopMovingOrSizing()
    end



    Frame.FrameProps["moveHandle"] = function(frame, target, targetGroupId)
        frame.uk_prop_moveHandle_targetId = target
        frame.uk_prop_moveHandle_targetGroupId = targetGroupId
        frame:HookScript("OnMouseDown", moveHandle_handleMouseDown)
        frame:HookScript("OnMouseUp", moveHandle_handleMouseUp)
    end

    Frame.FrameProps["resizeHandle"] = function(frame, target, targetGroupId)
        frame.uk_prop_resizeHandle_targetId = target
        frame.uk_prop_resizeHandle_targetGroupId = targetGroupId
        frame:HookScript("OnMouseDown", resizeHandle_handleMouseDown)
        frame:HookScript("OnMouseUp", resizeHandle_handleMouseUp)
    end
end

do -- Positioning
    Frame.FrameProps["point"] = function(frame, point, relativePoint)
        frame.uk_prop_point = point
        frame.uk_prop_point_relative = relativePoint
    end

    -- >>> React
    Frame.FrameProps["anchor"] = function(frame, anchor)
        anchor = handleReact(frame, anchor, "anchor")
        anchor = resolveFrameReference(anchor)
        frame.uk_prop_anchor = anchor
    end

    -- >>> React
    Frame.FrameProps["x"] = function(frame, x)
        x = handleReact(frame, x, "x")

        assert(x == UIKit_Define.Num or x == UIKit_Define.Percentage or x == UIKit_Define.Fit, "Invalid variable `x`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage` or `UIKit.Define.Fit`")

        frame.uk_prop_x = x
    end

    -- >>> React
    Frame.FrameProps["y"] = function(frame, y)
        y = handleReact(frame, y, "y")

        assert(y == UIKit_Define.Num or y == UIKit_Define.Percentage or y == UIKit_Define.Fit, "Invalid variable `y`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage` or `UIKit.Define.Fit`")

        frame.uk_prop_y = y
    end

    -- >>> React
    Frame.FrameProps["width"] = function(frame, width)
        width = handleReact(frame, width, "width")

        assert(width == UIKit_Define.Num or width == UIKit_Define.Percentage or width == UIKit_Define.Fit or width == UIKit_Define.Fill, "Invalid variable `width`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage`, `UIKit.Define.Fit` or `UIKit.Define.Fill`")

        frame.uk_prop_width = width
        if width == UIKit_Define.Num then frame:SetWidth(width.value) end
    end

    -- >>> React
    Frame.FrameProps["height"] = function(frame, height)
        height = handleReact(frame, height, "height")

        assert(height == UIKit_Define.Num or height == UIKit_Define.Percentage or height == UIKit_Define.Fit or height == UIKit_Define.Fill, "Invalid variable `height`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage`, `UIKit.Define.Fit` or `UIKit.Define.Fill`")

        frame.uk_prop_height = height
        if height == UIKit_Define.Num then frame:SetHeight(height.value) end
    end

    -- >>> React
    Frame.FrameProps["minWidth"] = function(frame, minWidth)
        minWidth = handleReact(frame, minWidth, "minWidth")

        if minWidth == nil then
            frame.uk_prop_minWidth = nil
            return
        end

        assert(minWidth == UIKit_Define.Num or minWidth == UIKit_Define.Percentage, "Invalid variable `minWidth`: Must be of type `UIKit.Define.Num` or `UIKit.Define.Percentage`")

        frame.uk_prop_minWidth = minWidth
    end

    -- >>> React
    Frame.FrameProps["minHeight"] = function(frame, minHeight)
        minHeight = handleReact(frame, minHeight, "minHeight")

        if minHeight == nil then
            frame.uk_prop_minHeight = nil
            return
        end

        assert(minHeight == UIKit_Define.Num or minHeight == UIKit_Define.Percentage, "Invalid variable `minHeight`: Must be of type `UIKit.Define.Num` or `UIKit.Define.Percentage`")

        frame.uk_prop_minHeight = minHeight
    end

    -- >>> React
    Frame.FrameProps["maxWidth"] = function(frame, maxWidth)
        maxWidth = handleReact(frame, maxWidth, "maxWidth")

        if maxWidth == nil then
            frame.uk_prop_maxWidth = nil
            return
        end

        assert(maxWidth == UIKit_Define.Num or maxWidth == UIKit_Define.Percentage, "Invalid variable `maxWidth`: Must be of type `UIKit.Define.Num` or `UIKit.Define.Percentage`")

        frame.uk_prop_maxWidth = maxWidth
    end

    -- >>> React
    Frame.FrameProps["maxHeight"] = function(frame, maxHeight)
        maxHeight = handleReact(frame, maxHeight, "maxHeight")

        if maxHeight == nil then
            frame.uk_prop_maxHeight = nil
            return
        end

        assert(maxHeight == UIKit_Define.Num or maxHeight == UIKit_Define.Percentage, "Invalid variable `maxHeight`: Must be of type `UIKit.Define.Num` or `UIKit.Define.Percentage`")

        frame.uk_prop_maxHeight = maxHeight
    end

    -- >>> React
    Frame.FrameProps["minSize"] = function(frame, width, height)
        if width ~= nil then frame:minWidth(width) end
        if height ~= nil then frame:minHeight(height) end
    end

    -- >>> React
    Frame.FrameProps["maxSize"] = function(frame, width, height)
        if width ~= nil then frame:maxWidth(width) end
        if height ~= nil then frame:maxHeight(height) end
    end

    -- >>> React
    Frame.FrameProps["size"] = function(frame, width, height)
        if width == UIKit_Define.Fill then
            frame.uk_prop_fill = width
            return
        end

        frame:width(width)
        frame:height(height)
    end
end

do -- Background
    -- >>> React
    Frame.FrameProps["background"] = function(frame, background)
        background = handleReact(frame, background, "background")

        assert(background == UIKit_Define.Texture or background == UIKit_Define.Texture_NineSlice or background == UIKit_Define.Texture_Atlas, "Invalid variable `background`: Must be a `Texture`, `Texture_NineSlice` or `Texture_Atlas`")
        local backgroundObject = frame:GetBackground()
        assert(not backgroundObject or (backgroundObject and backgroundObject.__isMaskTexture == false), "Error! Failed to set `background`: a mask texture background object already exists")

        frame.uk_prop_background = background
        UIKit_Renderer_Background:SetBackground(frame, false)
    end

    -- >>> React
    Frame.FrameProps["maskBackground"] = function(frame, background)
        background = handleReact(frame, background, "maskBackground")

        assert(background == UIKit_Define.Texture or background == UIKit_Define.Texture_NineSlice or background == UIKit_Define.Texture_Atlas, "Invalid variable `background`: Must be a `Texture`, `Texture_NineSlice` or `Texture_Atlas`")
        local backgroundObject = frame:GetBackground()
        assert(not backgroundObject or (backgroundObject and backgroundObject.__isMaskTexture), "Error! Failed to set `maskBackground`: a non-mask texture background object already exists")

        frame.uk_prop_background = background
        UIKit_Renderer_Background:SetBackground(frame, true)
    end

    Frame.FrameProps["backdropColor"] = function(frame, backgroundColor, borderColor)
        assert(backgroundColor == UIKit_Define.Color_RGBA or backgroundColor == UIKit_Define.Color_HEX, "Invalid variable `background`: Must be a `Color_RGBA` or `Color_HEX`")
        assert(borderColor == UIKit_Define.Color_RGBA or borderColor == UIKit_Define.Color_HEX, "Invalid variable `border`: Must be a `Color_RGBA` or `Color_HEX`")

        frame.uk_prop_backdropColor_background, frame.uk_prop_backdropColor_border = backgroundColor, borderColor
        UIKit_Renderer_Background:SetBackdropColor(frame)
    end

    -- >>> React
    Frame.FrameProps["backgroundColor"] = function(frame, color)
        color = handleReact(frame, color, "backgroundColor")

        assert(color == UIKit_Define.Color_RGBA or color == UIKit_Define.Color_HEX, "Invalid variable `backgroundColor`: Must be a `Color_RGBA` or `Color_HEX`")

        frame.uk_prop_backgroundColor = color
        UIKit_Renderer_Background:SetBackgroundColor(frame)
    end

    -- >>> React
    Frame.FrameProps["backgroundRotation"] = function(frame, radians)
        radians = handleReact(frame, radians, "backgroundRotation")

        assert(type(radians) == "number", "Invalid variable `backgroundRotation`: Must be a number")

        frame.uk_prop_backgroundRotation = radians
        UIKit_Renderer_Background:SetRotation(frame)
    end

    -- >>> React
    Frame.FrameProps["backgroundBlendMode"] = function(frame, backgroundBlendMode)
        backgroundBlendMode = handleReact(frame, backgroundBlendMode, "backgroundBlendMode")

        assert(type(backgroundBlendMode) == "string", "Invalid variable `backgroundBlendMode`: Must be a string")

        frame.uk_prop_blendMode = backgroundBlendMode
        UIKit_Renderer_Background:SetBlendMode(frame)
    end

    -- >>> React
    Frame.FrameProps["backgroundDesaturated"] = function(frame, backgroundDesaturated)
        backgroundDesaturated = handleReact(frame, backgroundDesaturated, "backgroundDesaturated")

        assert(type(backgroundDesaturated) == "boolean", "Invalid variable `backgroundDesaturated`: Must be a boolean")

        frame.uk_prop_desaturated = backgroundDesaturated
        UIKit_Renderer_Background:SetDesaturated(frame)
    end

    Frame.FrameProps["mask"] = function(frame, mask)
        mask = handleReact(frame, mask, "mask")
        mask = resolveFrameReference(mask)

        local maskBackgroundObject = mask.GetBackground and mask:GetBackground()
        assert(mask == UIKit_Define.Texture or (maskBackgroundObject and maskBackgroundObject.__isMaskTexture == true), "Invalid variable `mask`: Must be a `Texture` or a frame with a `maskBackground` object")

        UIKit_Renderer_Background:SetMaskTexture(frame, mask)
    end
end

do -- Flag
    Frame.FrameProps["_updateMode"] = function(frame, updateMode)
        frame.uk_flag_updateMode = updateMode

        if updateMode ~= UIKit_Enum.UpdateMode.All then
            frame:SetScript("OnSizeChanged", nil)
        end

        if updateMode == UIKit_Enum.UpdateMode.None then
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
        end
    end

    Frame.FrameProps["_renderBreakpoint"] = function(frame)
        frame.uk_flag_renderBreakpoint = true
    end

    Frame.FrameProps["_excludeFromCalculations"] = function(frame)
        frame.uk_flag_excludeFromCalculations = true
    end
end

do -- Behavior
    Frame.FrameProps["_Render"] = function(frame)
        if not frame.uk_prop_rendered then
            frame.uk_prop_rendered = true

            UIKit_UI_Scanner.SetupFrame(frame)
            UIKit_UI_Scanner.SetupFrameRecursive(frame)
        end

        UIKit_Renderer.Scanner.ScanFrame(frame)
    end
end



-- Layout Group
--------------------------------

-- >>> React
Frame.FrameProps["layoutSpacing"] = function(frame, spacing)
    spacing = handleReact(frame, spacing, "layoutSpacing")

    assert(spacing == UIKit_Define.Num or spacing == UIKit_Define.Percentage, "Invalid variable `spacing`: Must be of type `UIKit.Define.Num` or `UIKit.Define.Percentage`")

    frame.uk_prop_layoutSpacing = spacing
end

-- >>> React
Frame.FrameProps["layoutAlignmentH"] = function(frame, alignment)
    alignment = handleReact(frame, alignment, "layoutAlignmentH")

    assert(alignment == UIKit_Enum.Direction.Justified or alignment == UIKit_Enum.Direction.Leading or alignment == UIKit_Enum.Direction.Trailing, "Invalid variable `alignment`: Must be of type `UIKit.Enum.Direction.Justified`, `UIKit.Enum.Direction.Leading` or `UIKit.Enum.Direction.Trailing`")

    frame.uk_prop_layoutAlignmentH = alignment
end

-- >>> React
Frame.FrameProps["layoutAlignmentV"] = function(frame, alignment)
    alignment = handleReact(frame, alignment, "layoutAlignmentV")

    assert(alignment == UIKit_Enum.Direction.Justified or alignment == UIKit_Enum.Direction.Leading or alignment == UIKit_Enum.Direction.Trailing, "Invalid variable `alignment`: Must be of type `UIKit.Enum.Direction.Justified`, `UIKit.Enum.Direction.Leading` or `UIKit.Enum.Direction.Trailing`")

    frame.uk_prop_layoutAlignmentV = alignment
end

-- >>> React
Frame.FrameProps["layoutDirection"] = function(frame, direction)
    direction = handleReact(frame, direction, "layoutDirection")

    assert(direction == UIKit_Enum.Direction.Horizontal or direction == UIKit_Enum.Direction.Vertical, "Invalid variable `direction`: Must be of type `UIKit.Enum.Direction.Horizontal` or `UIKit.Enum.Direction.Vertical`")

    frame.uk_prop_layoutDirection = direction
end

-- >>> React
Frame.FrameProps["columns"] = function(frame, columns)
    columns = handleReact(frame, columns, "columns")

    assert(type(columns) == "number" and columns > 0, "Invalid variable `columns`: Must be a positive number")

    frame.uk_gridColumns = columns
end

-- >>> React
Frame.FrameProps["rows"] = function(frame, rows)
    rows = handleReact(frame, rows, "rows")

    assert(type(rows) == "number" and rows > 0, "Invalid variable `rows`: Must be a positive number")

    frame.uk_gridRows = rows
end



-- Scrolling
--------------------------------

Frame.FrameProps["scrollDirection"] = function(frame, direction)
    assert(frame.uk_type == "ScrollBar" or frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView", "Invalid variable `scrollDirection`: Must be called on `ScrollBar` or `ScrollView` or `LazyScrollView`")

    if frame.uk_type == "ScrollBar" then
        frame:SetVertical(direction == "VERTICAL" or direction == "BOTH")
    end

    if frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView" then
        local vertical = direction == "VERTICAL" or direction == "BOTH"
        local horizontal = direction == "HORIZONTAL" or direction == "BOTH"
        frame:SetDirection(vertical, horizontal)
    end
end

do -- Scroll Bar
    Frame.FrameProps["scrollBarTarget"] = function(frame, target, targetGroupId)
        target = resolveFrameReference(target, targetGroupId)
        assert(frame.uk_type == "ScrollBar" and target and (target.uk_type == "ScrollView" or target.uk_type == "LazyScrollView"), "Invalid variable `scrollBarTarget`: Must be called on `ScrollBar` with a `ScrollView` or `LazyScrollView` target")

        frame.uk_prop_scrollBarTarget = target
        frame:SetTarget(target)
    end
end

do -- Scroll View
    -- >>> React
    Frame.FrameProps["scrollViewContentWidth"] = function(frame, width)
        width = handleReact(frame, width, "scrollViewContentWidth")

        assert(frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView", "Invalid variable `scrollViewContentWidth`: Must be called on `ScrollView` or `LazyScrollView`")
        assert(width == UIKit_Define.Num or width == UIKit_Define.Percentage or width == UIKit_Define.Fit, "Invalid variable `scrollViewContentWidth`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage` or `UIKit.Define.Fit`")

        frame:GetContentFrame().uk_prop_width = width
        if width == UIKit_Define.Num then frame:GetContentFrame():SetWidth(width.value) end
    end

    -- >>> React
    Frame.FrameProps["scrollViewContentHeight"] = function(frame, height)
        height = handleReact(frame, height, "scrollViewContentHeight")

        assert(frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView", "Invalid variable `scrollViewContentHeight`: Must be called on `ScrollView` or `LazyScrollView`")
        assert(height == UIKit_Define.Num or height == UIKit_Define.Percentage or height == UIKit_Define.Fit, "Invalid variable `scrollViewContentHeight`: Must be of type `UIKit.Define.Num`, `UIKit.Define.Percentage` or `UIKit.Define.Fit`")

        frame:GetContentFrame().uk_prop_height = height
        if height == UIKit_Define.Num then frame:GetContentFrame():SetHeight(height.value) end
    end

    -- >>> React
    Frame.FrameProps["scrollInterpolation"] = function(frame, interpolation)
        interpolation = handleReact(frame, interpolation, "scrollInterpolation")

        assert(frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView", "Invalid variable `scrollInterpolation`: Must be called on `ScrollView` or `LazyScrollView`")
        assert(type(interpolation) == "number", "Invalid variable `scrollInterpolation`: Must be a number")

        frame.uk_prop_scrollInterpolation = interpolation
        frame:SetSmoothScrolling((interpolation ~= nil), interpolation)
    end

    -- >>> React
    Frame.FrameProps["scrollStepSize"] = function(frame, stepSize)
        stepSize = handleReact(frame, stepSize, "scrollStepSize")

        assert(frame.uk_type == "ScrollView" or frame.uk_type == "LazyScrollView", "Invalid variable `scrollStepSize`: Must be called on `ScrollView` or `LazyScrollView`")
        assert(type(stepSize) == "number", "Invalid variable `scrollStepSize`: Must be a number")

        frame.uk_prop_scrollStepSize = stepSize
        frame:SetStepSize(stepSize)
    end
end



-- Text
--------------------------------

-- >>> React
Frame.FrameProps["text"] = function(frame, text)
    text = handleReact(frame, text, "text")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `text`: Must be called on `Text` or `Input`")
    assert(type(text) == "string", "Invalid variable `text`: Must be a string")

    frame:SetText(text)
end

-- >>> React
Frame.FrameProps["font"] = function(frame, fontFamily)
    fontFamily = handleReact(frame, fontFamily, "font")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `font`: Must be called on `Text` or `Input`")
    assert(fontFamily == UIKit_Define.FontFamily, "Invalid variable `font`: Must be a `FontFamily`")

    frame:SetFont(fontFamily.path)
end

-- >>> React
Frame.FrameProps["fontObject"] = function(frame, fontObject)
    fontObject = handleReact(frame, fontObject, "fontObject")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `fontObject`: Must be called on `Text` or `Input`")
    assert(fontObject and fontObject.GetObjectType and fontObject:GetObjectType() == "Font", "Invalid variable `fontObject`: Must be a `Font`")

    frame:SetFontObject(fontObject)
end

-- >>> React
Frame.FrameProps["fontSize"] = function(frame, fontSize)
    fontSize = handleReact(frame, fontSize, "fontSize")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `fontSize`: Must be called on `Text` or `Input`")
    assert(type(fontSize) == "number", "Invalid variable `fontSize`: Must be a number")

    frame:SetFontSize(fontSize)
end

-- >>> React
Frame.FrameProps["fontFlags"] = function(frame, fontFlags)
    fontFlags = handleReact(frame, fontFlags, "fontFlags")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `fontFlags`: Must be called on `Text` or `Input`")
    assert(type(fontFlags) == "string", "Invalid variable `fontFlags`: Must be a string")

    frame:SetFontFlags(fontFlags)
end

-- >>> React
Frame.FrameProps["textJustifyH"] = function(frame, justifyH)
    justifyH = handleReact(frame, justifyH, "justifyH")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textJustifyH`: Must be called on `Text` or `Input`")
    assert(type(justifyH) == "string", "Invalid variable `textJustifyH`: Must be a string")

    frame:SetJustifyH(justifyH)
end

-- >>> React
Frame.FrameProps["textJustifyV"] = function(frame, justifyV)
    justifyV = handleReact(frame, justifyV, "justifyV")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textJustifyV`: Must be called on `Text` or `Input`")
    assert(type(justifyV) == "string", "Invalid variable `textJustifyV`: Must be a string")

    frame:SetJustifyV(justifyV)
end

-- >>> React
Frame.FrameProps["textAlignment"] = function(frame, justifyH, justifyV)
    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textAlignment`: Must be called on `Text` or `Input`")

    if justifyH then frame:textJustifyH(justifyH) end
    if justifyV then frame:textJustifyV(justifyV) end
end

-- >>> React
Frame.FrameProps["textVerticalSpacing"] = function(frame, spacing)
    spacing = handleReact(frame, spacing, "textVerticalSpacing")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textVerticalSpacing`: Must be called on `Text` or `Input`")
    assert(type(spacing) == "number", "Invalid variable `textVerticalSpacing`: Must be a number")

    frame:SetSpacing(spacing)
end

-- >>> React
Frame.FrameProps["textColor"] = function(frame, color)
    color = handleReact(frame, color, "textColor")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textColor`: Must be called on `Text` or `Input`")
    assert(color == UIKit_Define.Color_RGBA or color == UIKit_Define.Color_HEX, "Invalid variable `textColor`: Must be a `Color_RGBA` or `Color_HEX`")

    local parsedColor = UIKit_Utils:ProcessColor(color)
    frame:SetTextColor(parsedColor.r, parsedColor.g, parsedColor.b, parsedColor.a)
end

-- >>> React
Frame.FrameProps["wordWrap"] = function(frame, wrap)
    wrap = handleReact(frame, wrap, "wordWrap")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `wordWrap`: Must be called on `Text` or `Input`")
    assert(type(wrap) == "boolean", "Invalid variable `wordWrap`: Must be a boolean")

    frame:SetWordWrap(wrap)
end

-- >>> React
Frame.FrameProps["indentedWordWrap"] = function(frame, wrap)
    wrap = handleReact(frame, wrap, "indentedWordWrap")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `indentedWordWrap`: Must be called on `Text` or `Input`")
    assert(type(wrap) == "boolean", "Invalid variable `indentedWordWrap`: Must be a boolean")

    frame:SetIndentedWordWrap(wrap)
end

-- >>> React
Frame.FrameProps["nonSpaceWordWrap"] = function(frame, wrap)
    wrap = handleReact(frame, wrap, "nonSpaceWordWrap")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `nonSpaceWordWrap`: Must be called on `Text` or `Input`")
    assert(type(wrap) == "boolean", "Invalid variable `nonSpaceWordWrap`: Must be a boolean")

    frame:SetNonSpaceWrap(wrap)
end

-- >>> React
Frame.FrameProps["maxLines"] = function(frame, maxLines)
    maxLines = handleReact(frame, maxLines, "maxLines")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `maxLines`: Must be called on `Text` or `Input`")
    assert(type(maxLines) == "number", "Invalid variable `maxLines`: Must be a number")
    frame:SetMaxLines(maxLines)
end

-- >>> React
Frame.FrameProps["shadowColor"] = function(frame, color)
    color = handleReact(frame, color, "shadowColor")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `shadowColor`: Must be called on `Text` or `Input`")
    assert(color == UIKit_Define.Color_RGBA or color == UIKit_Define.Color_HEX, "Invalid variable `shadowColor`: Must be a `Color_RGBA` or `Color_HEX`")

    local parsedColor = UIKit_Utils:ProcessColor(color)
    frame:SetShadowColor(parsedColor.r, parsedColor.g, parsedColor.b, parsedColor.a)
end

-- >>> React
Frame.FrameProps["textHeight"] = function(frame, height)
    height = handleReact(frame, height, "textHeight")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textHeight`: Must be called on `Text` or `Input`")
    assert(type(height) == "number", "Invalid variable `textHeight`: Must be a number")

    frame:SetTextHeight(height)
end

-- >>> React
Frame.FrameProps["textRotation"] = function(frame, radians)
    radians = handleReact(frame, radians, "textRotation")

    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `textRotation`: Must be called on `Text` or `Input`")
    assert(type(radians) == "number", "`textRotation` must be a number")

    frame:SetRotation(radians)
end

Frame.FrameProps["alphaGradient"] = function(frame, start, length)
    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `alphaGradient`: Must be called on `Text` or `Input`")
    assert(type(start) == "number", "Invalid variable `alphaGradient start`: Must be a number")
    assert(type(length) == "number", "Invalid variable `alphaGradient length`: Must be a number")

    frame:SetAlphaGradient(start, length)
end

Frame.FrameProps["shadowOffset"] = function(frame, x, y)
    assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `shadowOffset`: Must be called on `Text` or `Input`")
    assert(type(x) == "number", "Invalid variable `shadowOffset x`: Must be a number")
    assert(type(y) == "number", "Invalid variable `shadowOffset y`: Must be a number")

    frame:SetShadowOffset(x, y)
end

do -- Input
    -- >>> React
    Frame.FrameProps["placeholder"] = function(frame, text)
        text = handleReact(frame, text, "placeholder")

        assert(frame.uk_type == "Input", "Invalid variable `placeholder`: Must be called on `Input`")
        assert(type(text) == "string", "Invalid variable `placeholder`: Must be a string")

        frame:SetPlaceholder(text)
    end

    -- >>> React
    Frame.FrameProps["inputCaretWidth"] = function(frame, width)
        width = handleReact(frame, width, "inputCaretWidth")

        assert(frame.uk_type == "Input", "Invalid variable `inputCaretWidth`: Must be called on `Input`")
        assert(type(width) == "number", "Invalid variable `inputCaretWidth`: Must be a number")

        frame:SetCaretWidth(width)
    end

    -- >>> React
    Frame.FrameProps["inputCaretOffsetX"] = function(frame, offset)
        offset = handleReact(frame, offset, "inputCaretOffsetX")

        assert(frame.uk_type == "Input", "Invalid variable `inputCaretOffsetX`: Must be called on `Input`")
        assert(type(offset) == "number", "Invalid variable `inputCaretOffsetX`: Must be a number")

        frame:SetCaretOffsetX(offset)
    end

    -- >>> React
    Frame.FrameProps["inputMultiLine"] = function(frame, multiLine)
        multiLine = handleReact(frame, multiLine, "inputMultiLine")

        assert(frame.uk_type == "Input", "Invalid variable `inputMultiLine`: Must be called on `Input`")
        assert(type(multiLine) == "boolean", "Invalid variable `inputMultiLine`: Must be a boolean")

        frame:SetMultiLine(multiLine)
    end



    -- >>> React
    Frame.FrameProps["inputHighlightColor"] = function(frame, color)
        color = handleReact(frame, color, "inputHighlightColor")

        assert(frame.uk_type == "Input", "Invalid variable `inputHighlightColor`: Must be called on `Input`")
        assert(color == UIKit_Define.Color_RGBA or color == UIKit_Define.Color_HEX, "`inputHighlightColor` must be a `Color_RGBA` or `Color_HEX`")

        local parsedColor = UIKit_Utils:ProcessColor(color)
        frame:SetHighlightColor(parsedColor.r, parsedColor.g, parsedColor.b, parsedColor.a)
    end

    -- >>> React
    Frame.FrameProps["inputPlaceholderTextColor"] = function(frame, color)
        color = handleReact(frame, color, "inputPlaceholderTextColor")

        assert(frame.uk_type == "Input", "Invalid variable `inputPlaceholderTextColor`: Must be called on `Input`")
        assert(color == UIKit_Define.Color_RGBA or color == UIKit_Define.Color_HEX, "Invalid variable `inputPlaceholderTextColor`: Must be a `Color_RGBA` or `Color_HEX`")

        local parsedColor = UIKit_Utils:ProcessColor(color)
        frame.__Placeholder:SetTextColor(parsedColor.r, parsedColor.g, parsedColor.b, parsedColor.a)
    end

    -- >>> React
    Frame.FrameProps["inputPlaceholderFont"] = function(frame, fontFamily)
        fontFamily = handleReact(frame, fontFamily, "font")

        assert(frame.uk_type == "Text" or frame.uk_type == "Input", "Invalid variable `font`: Must be called on `Text` or `Input`")
        assert(fontFamily == UIKit_Define.FontFamily, "Invalid variable `font`: Must be a `FontFamily`")

        frame:SetPlaceholderFont(fontFamily.path)
    end

    -- >>> React
    Frame.FrameProps["inputPlaceholderFontSize"] = function(frame, size)
        size = handleReact(frame, size, "inputPlaceholderFontSize")

        assert(frame.uk_type == "Input", "Invalid variable `inputPlaceholderFontSize`: Must be called on `Input`")
        assert(type(size) == "number", "Invalid variable `inputPlaceholderFontSize`: Must be a number")

        frame:SetPlaceholderFontSize(size)
    end

    -- >>> React
    Frame.FrameProps["inputPlaceholderFontFlags"] = function(frame, flags)
        flags = handleReact(frame, flags, "inputPlaceholderFontFlags")

        assert(frame.uk_type == "Input", "Invalid variable `inputPlaceholderFontFlags`: Must be called on `Input`")
        assert(type(flags) == "string", "Invalid variable `inputPlaceholderFontFlags`: Must be a string")

        frame:SetPlaceholderFontFlags(flags)
    end
end



-- Range
--------------------------------

do -- Linear Slider
    -- >>> React
    Frame.FrameProps["linearSliderOrientation"] = function(frame, orientation)
        orientation = handleReact(frame, orientation, "linearSliderOrientation")

        assert(frame.uk_type == "LinearSlider", "Invalid variable `linearSliderOrientation`: Must be called on `LinearSlider`")
        assert(orientation == UIKit_Enum.Orientation.Horizontal or orientation == UIKit_Enum.Orientation.Vertical, "Invalid variable `linearSliderOrientation`: Must be `HORIZONTAL` or `VERTICAL`")

        frame:SetOrientation(orientation)
    end

    -- >>> React
    Frame.FrameProps["linearSliderThumbWidth"] = function(frame, width)
        width = handleReact(frame, width, "linearSliderThumbWidth")

        assert(frame.uk_type == "LinearSlider", "Invalid variable `linearSliderThumbWidth`: Must be called on `LinearSlider`")
        assert(width and type(width) == "number", "Invalid variable `linearSliderThumbWidth`: Must be a number")

        frame.__ThumbAnchor:SetWidth(width)
    end

    -- >>> React
    Frame.FrameProps["linearSliderThumbHeight"] = function(frame, height)
        height = handleReact(frame, height, "linearSliderThumbHeight")

        assert(frame.uk_type == "LinearSlider", "Invalid variable `linearSliderThumbHeight`: Must be called on `LinearSlider`")
        assert(height and type(height) == "number", "Invalid variable `linearSliderThumbHeight`: Must be a number")

        frame.__ThumbAnchor:SetHeight(height)
    end

    -- >>> React
    Frame.FrameProps["linearSliderThumbSize"] = function(frame, width, height)
        assert(frame.uk_type == "LinearSlider", "Invalid variable `linearSliderThumbSize`: Must be called on `LinearSlider`")
        assert(width and type(width) == "number", "Invalid variable `linearSliderThumbSize`: Must be a number")
        assert(height and type(height) == "number", "Invalid variable `linearSliderThumbSize`: Must be a number")

        if width then frame:linearSliderThumbWidth(width) end
        if height then frame:linearSliderThumbHeight(height) end
    end

    Frame.FrameProps["linearSliderThumbPropagateMouse"] = function(frame, propagateMouse)
        assert(frame.uk_type == "LinearSlider", "Invalid variable `linearSliderThumbPropagateMouse`: Must be called on `LinearSlider`")
        assert(type(propagateMouse) == "boolean", "Invalid variable `linearSliderThumbPropagateMouse`: Must be a boolean")

        frame:GetThumb():AwaitSetPropagateMouseClicks(propagateMouse)
        frame:GetThumb():AwaitSetPropagateMouseMotion(propagateMouse)
    end
end



-- Interactive Rect
--------------------------------

do -- Interactive Rect
    Frame.FrameProps["onEnter"] = function(frame, callback)
        assert(frame.uk_type == "InteractiveRect", "Invalid variable `onEnter`: Must be called on `InteractiveRect`")

        frame:AddOnEnter(callback)
    end

    Frame.FrameProps["onLeave"] = function(frame, callback)
        assert(frame.uk_type == "InteractiveRect", "Invalid variable `onLeave`: Must be called on `InteractiveRect`")

        frame:AddOnLeave(callback)
    end

    Frame.FrameProps["onMouseDown"] = function(frame, callback)
        assert(frame.uk_type == "InteractiveRect", "Invalid variable `onMouseDown`: Must be called on `InteractiveRect`")

        frame:AddOnMouseDown(callback)
    end

    Frame.FrameProps["onMouseUp"] = function(frame, callback)
        assert(frame.uk_type == "InteractiveRect", "Invalid variable `onMouseUp`: Must be called on `InteractiveRect`")

        frame:AddOnMouseUp(callback)
    end
end




-- Pooling
--------------------------------

Frame.FrameProps["poolOnElementUpdate"] = function(frame, func)
    assert(frame.uk_type == "List" or frame.uk_type == "LazyScrollView", "Invalid variable `poolOnElementUpdate`: Must be called on `List` or `LazyScrollView`")
    assert(type(func) == "function", "Invalid variable `func`: Must be a function")

    frame:SetOnElementUpdate(func)
end

Frame.FrameProps["poolPrefab"] = function(frame, prefabFunc)
    assert(frame.uk_type == "List" or frame.uk_type == "LazyScrollView", "Invalid variable `poolPrefab`: Must be called on `List` or `LazyScrollView`")
    assert(type(prefabFunc) == "function", "Invalid variable `prefabFunc`: Must be a function")

    frame:SetPrefab(prefabFunc)
end

do -- Lazy Scroll View
    Frame.FrameProps["lazyScrollViewElementHeight"] = function(frame, height)
        assert(frame.uk_type == "LazyScrollView", "Invalid variable `lazyScrollViewElementHeight`: Must be called on `LazyScrollView`")
        assert(type(height) == "number", "Invalid variable `lazyScrollViewElementHeight`: Must be a number")

        frame:SetElementHeight(height)
    end
end
