local env                    = select(2, ...)
local MixinUtil              = env.WPM:Import("wpm_modules/mixin-util")
local Utils_LazyTable        = env.WPM:Import("wpm_modules/utils/lazy-table")
local UIKit_Define           = env.WPM:Import("wpm_modules/ui-kit/define")
local UIKit_FrameCache       = env.WPM:Import("wpm_modules/ui-kit/frame-cache")
local UIKit_Utils            = env.WPM:Import("wpm_modules/ui-kit/utils")
local UIKit_Enum             = env.WPM:Import("wpm_modules/ui-kit/enum")
local UIKit_UI_Scanner       = env.WPM:Await("wpm_modules/ui-kit/ui/scanner")

local Mixin                  = MixinUtil.Mixin
local CreateFrame            = CreateFrame
local math_huge              = math.huge
local type                   = type
local tinsert                = table.insert
local tremove                = table.remove

local UIKit_Primitives_Frame = env.WPM:New("wpm_modules/ui-kit/primitives/frame")


-- Shared
--------------------------------

UIKit_Primitives_Frame.FrameProps = {}

local dummy = CreateFrame("Frame"); dummy:Hide()
local Method_SetSize                   = getmetatable(dummy).__index.SetSize
local Method_SetWidth                  = getmetatable(dummy).__index.SetWidth
local Method_SetHeight                 = getmetatable(dummy).__index.SetHeight
local Method_SetPropagateMouseClicks   = getmetatable(dummy).__index.SetPropagateMouseClicks
local Method_SetPropagateMouseMotion   = getmetatable(dummy).__index.SetPropagateMouseMotion
local Method_SetPropagateKeyboardInput = getmetatable(dummy).__index.SetPropagateKeyboardInput


-- Frame
--------------------------------

local cachedMetas = {}
local sharedHandlers = {}

local FrameMixin = {}
do
    -- Helper
    --------------------------------

    local function getParentSize(frame, axis)
        local parent = frame:GetParent()
        if not parent or not parent.GetWidth then
            parent = UIParent
        end

        return (axis == "width" and parent:GetWidth() or parent:GetHeight()) or 0
    end

    local function resolveBoundValue(frame, boundConfig, axis)
        if not boundConfig then return nil end

        if boundConfig == UIKit_Define.Num then
            local value = boundConfig.value or 0
            local delta = boundConfig.delta or 0
            return value + delta
        end

        if boundConfig == UIKit_Define.Percentage then
            local parentSize = getParentSize(frame, axis)
            if parentSize == 0 then return 0 end
            return UIKit_Utils:CalculateRelativePercentage(parentSize, boundConfig.value or 0, boundConfig.operator, boundConfig.delta)
        end

        return boundConfig
    end


    -- Hierachy
    --------------------------------

    function FrameMixin:SetFrameParent(parent)
        self.uk_parent = parent
    end

    function FrameMixin:GetFrameParent()
        return self.uk_parent
    end


    function FrameMixin:SetFrameChildren(children)
        self.uk_children = children
    end

    function FrameMixin:GetFrameChildren()
        return UIKit_FrameCache.GetFramesInLazyTable(self, "uk_children")
    end

    function FrameMixin:AddFrameChild(frame)
        Utils_LazyTable.Insert(self, "uk_children", frame.uk_id)
    end

    function FrameMixin:RemoveFrameChild(frame)
        local children = self:GetFrameChildren()
        if not children then return end

        for i = 1, #children do
            if children[i] == frame then
                Utils_LazyTable.Remove(children, "uk_children", i)
                return
            end
        end
    end


    -- Accessor
    --------------------------------

    function FrameMixin:GetBackground()
        return self.Background
    end


    -- Attribute
    --------------------------------

    function FrameMixin:GetID()
        return self.uk_id
    end


    -- Get
    --------------------------------

    function FrameMixin:GetSpacing()
        return self.uk_prop_layoutSpacing
    end

    function FrameMixin:GetMaxWidth()
        return resolveBoundValue(self, self.uk_prop_maxWidth, "width")
    end

    function FrameMixin:GetMaxHeight()
        return resolveBoundValue(self, self.uk_prop_maxHeight, "height")
    end

    function FrameMixin:GetMinWidth()
        return resolveBoundValue(self, self.uk_prop_minWidth, "width")
    end

    function FrameMixin:GetMinHeight()
        return resolveBoundValue(self, self.uk_prop_minHeight, "height")
    end


    -- Fit Content
    --------------------------------

    local function getBoundLimits(frame, axis)
        if axis == "width" then return frame:GetMinWidth(), frame:GetMaxWidth() end
        return frame:GetMinHeight(), frame:GetMaxHeight()
    end

    local function applyDeltaAndClamp(frame, axis, measuredSize, prop)
        local minSize, maxSize = getBoundLimits(frame, axis)
        local baseSize = measuredSize or 0

        if minSize and baseSize < minSize then baseSize = minSize end
        if maxSize and baseSize > maxSize then baseSize = maxSize end

        local delta = (prop == UIKit_Define.Fit and prop.delta) or 0
        local adjustedSize = baseSize + delta

        if minSize and adjustedSize < minSize then adjustedSize = minSize end
        if maxSize then
            local maxLimit = maxSize + delta
            if adjustedSize > maxLimit then adjustedSize = maxLimit end
        end

        return adjustedSize > 0 and adjustedSize or 0
    end

    local function resolveHorizontalBounds(parentLeft, width, rawLeft, rawRight)
        if rawLeft and rawRight then
            local left = rawLeft - parentLeft
            local right = rawRight - parentLeft
            return left < right and left or right, left > right and left or right
        end

        if rawLeft then
            local left = rawLeft - parentLeft
            return left, left + width
        end

        if rawRight then
            local right = rawRight - parentLeft
            return right - width, right
        end

        return 0, width
    end

    local function resolveVerticalBounds(parentTop, height, rawTop, rawBottom)
        if rawTop and rawBottom then
            local top = parentTop - rawTop
            local bottom = parentTop - rawBottom
            return top < bottom and top or bottom, top > bottom and top or bottom
        end

        if rawTop then
            local top = parentTop - rawTop
            return top, top + height
        end

        if rawBottom then
            local bottom = parentTop - rawBottom
            return bottom - height, bottom
        end

        return 0, height
    end

    local function measureChildBounds(parentLeft, parentTop, child)
        local rectLeft, rectBottom, rectWidth, rectHeight = child:GetRect()
        if rectLeft then
            local rectRight = rectLeft + rectWidth
            local rectTop = rectBottom + rectHeight
            local left = rectLeft - parentLeft
            local right = rectRight - parentLeft
            local top = parentTop - rectTop
            local bottom = parentTop - rectBottom

            if left > right then left, right = right, left end
            if top > bottom then top, bottom = bottom, top end

            return left, top, right, bottom
        end

        local width = child:GetWidth() or 0
        local height = child:GetHeight() or 0
        local left, right = resolveHorizontalBounds(parentLeft, width, child:GetLeft(), child:GetRight())
        local top, bottom = resolveVerticalBounds(parentTop, height, child:GetTop(), child:GetBottom())

        return left, top, right, bottom
    end

    function FrameMixin:ResolveFitSize(axis, measuredSize, prop)
        return applyDeltaAndClamp(self, axis, measuredSize or 0, prop)
    end

    function FrameMixin:GetFitContent()
        local widthProp = self.uk_prop_width
        local heightProp = self.uk_prop_height
        return widthProp == UIKit_Define.Fit or false, heightProp == UIKit_Define.Fit or false
    end

    function FrameMixin:FitContent(fitX, fitY, children)
        local shouldFitWidth, shouldFitHeight = self:GetFitContent()
        fitX = fitX == nil and shouldFitWidth or fitX
        fitY = fitY == nil and shouldFitHeight or fitY
        if not fitX and not fitY then return end

        children = children or self:GetFrameChildren()
        if not children then return end

        local minLeft, minTop, maxRight, maxBottom = math_huge, math_huge, -math_huge, -math_huge
        local hasVisibleChildren = false
        local parentLeft, parentTop = self:GetLeft(), self:GetTop()

        for i = 1, #children do
            local child = children[i]
            if child and child:IsShown() and not child.uk_flag_excludeFromCalculations then
                local left, top, right, bottom = measureChildBounds(parentLeft, parentTop, child)
                if left < minLeft then minLeft = left end
                if top < minTop then minTop = top end
                if right > maxRight then maxRight = right end
                if bottom > maxBottom then maxBottom = bottom end
                hasVisibleChildren = true
            end
        end

        if fitX then
            local width = hasVisibleChildren and (maxRight - minLeft) or 0
            local newWidth = self:ResolveFitSize("width", width > 0 and width or 0, self.uk_prop_width)
            if self:GetWidth() ~= newWidth then self:SetWidth(newWidth) end
        end

        if fitY then
            local height = hasVisibleChildren and (maxBottom - minTop) or 0
            local newHeight = self:ResolveFitSize("height", height > 0 and height or 0, self.uk_prop_height)
            if self:GetHeight() ~= newHeight then self:SetHeight(newHeight) end
        end
    end


    -- Alias
    --------------------------------

    function FrameMixin:AddAlias(aliasName, frame)
        if not aliasName or not frame then return end

        local registry = self.uk_aliasRegistry
        if not registry then
            registry = {}
            self.uk_aliasRegistry = registry
        end
        registry[aliasName] = frame
    end

    function FrameMixin:GetAlias(aliasName)
        if not aliasName then return end

        local registry = self.uk_aliasRegistry
        return registry and registry[aliasName]
    end


    -- Events
    --------------------------------

    function FrameMixin:HookEvent(event, func)
        if not event or type(func) ~= "function" then return end

        local eventRegistry = self.uk_eventRegistry
        if not eventRegistry then
            eventRegistry = {}
            self.uk_eventRegistry = eventRegistry
        end

        local registry = eventRegistry[event]
        if not registry then
            registry = {}
            eventRegistry[event] = registry
        end

        for i = 1, #registry do
            if registry[i] == func then return end
        end

        tinsert(registry, func)
    end

    function FrameMixin:UnhookEvent(event, func)
        if not event or not func then return end

        local eventRegistry = self.uk_eventRegistry
        if not eventRegistry then return end

        local registry = eventRegistry[event]
        if not registry then return end

        for i = #registry, 1, -1 do
            if registry[i] == func then
                tremove(registry, i)
            end
        end
    end

    function FrameMixin:TriggerEvent(event, ...)
        if not event then return end

        local eventRegistry = self.uk_eventRegistry
        if not eventRegistry then return end

        local registry = eventRegistry[event]
        if not registry then return end

        for i = 1, #registry do
            registry[i](self, ...)
        end
    end


    -- Override
    --------------------------------

    function FrameMixin:SetSize(...)
        Method_SetSize(self, ...)

        -- If in UserUpdate mode, explicitly trigger layout updates
        if self.uk_flag_updateMode == UIKit_Enum.UpdateMode.UserUpdate then
            UIKit_UI_Scanner.ScanFrame(self)
        end
    end

    function FrameMixin:SetWidth(...)
        Method_SetWidth(self, ...)

        -- If in UserUpdate mode, explicitly trigger layout updates
        if self.uk_flag_updateMode == UIKit_Enum.UpdateMode.UserUpdate then
            UIKit_UI_Scanner.ScanFrame(self)
        end
    end

    function FrameMixin:SetHeight(...)
        Method_SetHeight(self, ...)

        -- If in UserUpdate mode, explicitly trigger layout update
        if self.uk_flag_updateMode == UIKit_Enum.UpdateMode.UserUpdate then
            UIKit_UI_Scanner.ScanFrame(self)
        end
    end

    local function propagateEnableMouseClick(self)
        self:SetPropagateMouseClicks(true)
    end

    local function propagateDisableMouseClick(self)
        self:SetPropagateMouseClicks(false)
    end

    local function propagateEnableMouseMotion(self)
        self:SetPropagateMouseMotion(true)
    end

    local function propagateDisableMouseMotion(self)
        self:SetPropagateMouseMotion(false)
    end

    local function propagateEnableKeyboardInput(self)
        self:SetPropagateKeyboardInput(true)
    end

    local function propagateDisableKeyboardInput(self)
        self:SetPropagateKeyboardInput(false)
    end

    function FrameMixin:AwaitSetPropagateMouseClicks(propagate)
        if propagate then
            UIKit_Utils:AwaitProtectedEvent(propagateEnableMouseClick, self)
        else
            UIKit_Utils:AwaitProtectedEvent(propagateDisableMouseClick, self)
        end
    end

    function FrameMixin:AwaitSetPropagateMouseMotion(propagate)
        if propagate then
            UIKit_Utils:AwaitProtectedEvent(propagateEnableMouseMotion, self)
        else
            UIKit_Utils:AwaitProtectedEvent(propagateDisableMouseMotion, self)
        end
    end

    function FrameMixin:AwaitSetPropagateKeyboardInput(propagate)
        if propagate then
            UIKit_Utils:AwaitProtectedEvent(propagateEnableKeyboardInput, self)
        else
            UIKit_Utils:AwaitProtectedEvent(propagateDisableKeyboardInput, self)
        end
    end

    function FrameMixin:SetPropagateMouseClicks(propagate)
        if InCombatLockdown() then return end
        Method_SetPropagateMouseClicks(self, propagate)
    end

    function FrameMixin:SetPropagateMouseMotion(propagate)
        if InCombatLockdown() then return end
        Method_SetPropagateMouseMotion(self, propagate)
    end

    function FrameMixin:SetPropagateKeyboardInput(propagate)
        if InCombatLockdown() then return end
        Method_SetPropagateKeyboardInput(self, propagate)
    end
end


function UIKit_Primitives_Frame.New(frameType, name, parent, template)
    name = name or "undefined"


    local frame = CreateFrame(frameType, name, parent, template)

    local meta = cachedMetas[frameType]
    if not meta then
        local originalMeta = getmetatable(frame)
        local originalIndex = originalMeta and originalMeta.__index

        meta = {
            __index = function(t, k)
                local propFunc = UIKit_Primitives_Frame.FrameProps[k]
                if propFunc then
                    local handler = sharedHandlers[k]
                    if not handler then
                        handler = function(frame, ...)
                            propFunc(frame, ...)
                            return frame
                        end
                        sharedHandlers[k] = handler
                    end
                    return handler
                end

                if not originalIndex then return nil end
                return type(originalIndex) == "function" and originalIndex(t, k) or originalIndex[k]
            end
        }
        cachedMetas[frameType] = meta
    end

    setmetatable(frame, meta)
    Mixin(frame, FrameMixin)

    if name then _G[name] = nil end
    return frame
end
