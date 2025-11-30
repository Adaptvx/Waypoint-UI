local env              = select(2, ...)
local UIKit_Enum       = env.WPM:Import("wpm_modules/ui-kit/enum")
local UIKit_Renderer   = env.WPM:Import("wpm_modules/ui-kit/renderer")
local UIKit_UI_Scanner = env.WPM:New("wpm_modules/ui-kit/ui/scanner")



local function setupFrame(frame)
    local frameType = frame.uk_type

    -- Size changed
    if frameType == "Input" then
        frame:HookEvent("OnSizeChanged", UIKit_UI_Scanner.ScanFrameFromEvent)
    else
        if frame.uk_flag_updateMode == UIKit_Enum.UpdateMode.All then
            frame:SetScript("OnSizeChanged", UIKit_UI_Scanner.ScanFrameFromEvent)
        end
    end

    -- Visibillity changed
    if frame.uk_flag_updateMode ~= UIKit_Enum.UpdateMode.None and frame.uk_flag_updateMode ~= UIKit_Enum.UpdateMode.ExcludeVisibilityChanged then
        frame:HookScript("OnShow", UIKit_UI_Scanner.OnVisibilityChanged)
        frame:HookScript("OnHide", UIKit_UI_Scanner.OnVisibilityChanged)
    end

    -- Text changed
    if frameType == "Text" then frame:HookEvent("OnTextChanged", UIKit_UI_Scanner.ScanFrameFromEvent) end

    -- Ready
    frame.uk_ready = true
end



function UIKit_UI_Scanner.SetupFrame(frame)
    if frame.uk_type == "InteractiveRect" then return false end
    setupFrame(frame)
end

function UIKit_UI_Scanner.SetupFrameRecursive(start)
    -- Scan children
    local children = start:GetFrameChildren()
    if not children then return end

    for i = 1, #children do
        local child = children[i]
        if not child.uk_flag_renderBreakpoint then
            UIKit_UI_Scanner.SetupFrame(child)
            UIKit_UI_Scanner.SetupFrameRecursive(child)
        end
    end

    -- Scan children of aliases, if the alias is of frame type
    local aliasRegistry = start.uk_aliasRegistry
    if aliasRegistry then
        for _, alias in pairs(aliasRegistry) do
            if alias.GetObjectType and alias:GetObjectType() == "Frame" then
                if UIKit_UI_Scanner.SetupFrame(alias) then
                    UIKit_UI_Scanner.SetupFrameRecursive(alias)
                end
            end
        end
    end
end

function UIKit_UI_Scanner.ScanFrame(frame)
    if UIKit_Renderer.Cleaner.onCooldown then return end

    -- Check for scrollbar / nested frames
    local root = (frame.uk_parent and frame.uk_parent.uk_parent) or frame.uk_parent or frame
    if not root then return end
    if root == UIParent then root = frame end

    UIKit_Renderer.Scanner.ScanFrame(root)
end

function UIKit_UI_Scanner.ScanFrameFromEvent(frame)
    if frame.uk_flag_updateMode == UIKit_Enum.UpdateMode.None then return end
    if frame.uk_flag_updateMode == UIKit_Enum.UpdateMode.ChildrenVisibilityChanged then return end
    if frame.uk_flag_updateMode == UIKit_Enum.UpdateMode.UserUpdate then return end

    UIKit_UI_Scanner.ScanFrame(frame)
end




function UIKit_UI_Scanner.OnVisibilityChanged(frame)
    local parent = frame.uk_parent

    while parent do
        -- Stop if parent is set to None update mode to prevent full re-scanning when unnecessary
        if parent.uk_flag_updateMode == UIKit_Enum.UpdateMode.None or parent.uk_flag_updateMode == UIKit_Enum.UpdateMode.ExcludeVisibilityChanged then return end

        -- Scan if parent is set to ChildrenVisibilityChanged update mode
        if parent.uk_flag_updateMode == UIKit_Enum.UpdateMode.ChildrenVisibilityChanged then
            UIKit_UI_Scanner.ScanFrame(parent)
            return
        end

        -- Traverse parent hierarchy
        parent = parent.uk_parent
    end
end
