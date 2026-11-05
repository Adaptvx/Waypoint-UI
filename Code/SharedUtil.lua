local env = select(2, ...)
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local Utils_General = env.modules:Import("packages\\utils\\general")
local SharedUtil = env.modules:New("@\\SharedUtil")

local GetScreenWidth, GetScreenHeight = GetScreenWidth, GetScreenHeight
local BreakUpLargeNumbers = BreakUpLargeNumbers
local GetCursorPosition = GetCursorPosition
local InCombatLockdown = InCombatLockdown
local ResetCursor = ResetCursor
local SetCursor = SetCursor
local abs = math.abs

local SNAP_THRESHOLD = 12

do -- Screen Position
    function SharedUtil:GetFrameDistanceFromCursor(frame)
        local frameX, frameY = frame:GetCenter()
        if not frameX or not frameY then return end

        local frameScale = frame:GetEffectiveScale()
        frameX, frameY = frameX * frameScale, frameY * frameScale
        local deltaX, deltaY = Utils_General.GetMouseDelta(frameX, frameY)

        local aspectRatio = GetScreenWidth() / GetScreenHeight()
        return (math.abs(deltaX) + math.abs(deltaY)) / aspectRatio
    end

    function SharedUtil:GetFrameDistanceFromScreenCenter(frame)
        local frameX, frameY = frame:GetCenter()
        if not frameX or not frameY then return end

        frameX = frameX * frame:GetEffectiveScale()
        frameY = frameY * frame:GetEffectiveScale()

        local screenCenterX, screenCenterY = GetScreenWidth() * UIParent:GetEffectiveScale() * 0.5, GetScreenHeight() * UIParent:GetEffectiveScale() * 0.5
        return math.abs(frameX - screenCenterX) + math.abs(frameY - screenCenterY)
    end

    function SharedUtil:GetFrameDistanceFromScreenEdge(frame)
        local frameX, frameY = frame:GetCenter()
        if not frameX or not frameY then return end

        local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()

        local deltaLeft = frameX / screenWidth
        local deltaRight = (screenWidth - frameX) / screenWidth
        local deltaTop = (screenHeight - frameY) / screenHeight
        local deltaBottom = frameY / screenHeight

        return math.min(deltaLeft, deltaRight, deltaTop, deltaBottom)
    end
end

do
    local function GetDefaultPosition(frame)
        local point, relativeTo, relativePoint, x, y = frame:GetDefaultPosition()
        local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = frame:GetPoint()
        if not currentPoint then return end

        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, x, y)
        local left = frame:GetLeft()
        local top = frame:GetTop()

        frame:ClearAllPoints()
        frame:SetPoint(currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY)
        return left, top
    end

    local function SetPosition(frame, left, top, clearPoints)
        if clearPoints then frame:ClearAllPoints() end

        frame:point("TOPLEFT", "BOTTOMLEFT"):anchor(UIParent):position(left, top)
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end

    local function UpdateBounds(frame)
        if not frame.isBoundsDragging then return end
        if InCombatLockdown() then
            SharedUtil:StopMoving(frame)
            return
        end

        local cursorX, cursorY = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        local left = frame.boundsDragLeft + (cursorX - frame.boundsDragCursorX) / scale
        local top = frame.boundsDragTop + (cursorY - frame.boundsDragCursorY) / scale
        if abs(left - frame.boundsDragDefaultLeft) <= SNAP_THRESHOLD
            and abs(top - frame.boundsDragDefaultTop) <= SNAP_THRESHOLD then
            left = frame.boundsDragDefaultLeft
            top = frame.boundsDragDefaultTop
        end

        SetPosition(frame, left, top)
    end

    function SharedUtil:InitializeBoundsForFrame(frame, key, dragHandle)
        frame.boundsKey = key

        dragHandle:SetScript("OnDragStart", function() self:StartMoving(frame) end)
        dragHandle:SetScript("OnDragStop", function() self:StopMoving(frame) end)
        frame:HookScript("OnUpdate", UpdateBounds)
        frame:HookScript("OnHide", function() self:StopMoving(frame) end)

        CallbackRegistry.Add("Preload.DatabaseReady", function()
            UIKit_Utils:AwaitProtectedEvent(function() self:RestoreBounds(frame) end, frame)
        end)
    end

    function SharedUtil:RestoreBounds(frame)
        local bounds = Config.DBGlobal:GetVariable(frame.boundsKey)
        if bounds and bounds.point and bounds.x ~= nil and bounds.y ~= nil then
            frame:point(bounds.point):anchor(UIParent):position(bounds.x, bounds.y)
            frame:ClearAllPoints()
            frame:SetPoint(bounds.point, UIParent, bounds.x, bounds.y)
        else
            frame:SetDefaultPosition()
        end
    end

    function SharedUtil:SaveBounds(frame)
        local left = frame:GetLeft()
        local top = frame:GetTop()
        if left == nil or top == nil then return end

        local defaultLeft, defaultTop = GetDefaultPosition(frame)
        local bounds
        if not defaultLeft or not defaultTop
            or abs(left - defaultLeft) >= 0.5
            or abs(top - defaultTop) >= 0.5 then
            local screenHeight = UIParent:GetHeight() * UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
            bounds = { point = "TOPLEFT", x = left, y = top - screenHeight }
        end

        Config.DBGlobal:SetVariable(frame.boundsKey, bounds)
        self:RestoreBounds(frame)
    end

    function SharedUtil:StartMoving(frame)
        if frame.isBoundsDragging or InCombatLockdown() then return false end

        local left = frame:GetLeft()
        local top = frame:GetTop()
        if left == nil or top == nil then return false end

        local defaultLeft, defaultTop = GetDefaultPosition(frame)
        if defaultLeft == nil or defaultTop == nil then return false end

        local cursorX, cursorY = GetCursorPosition()
        frame.boundsDragCursorX = cursorX
        frame.boundsDragCursorY = cursorY
        frame.boundsDragLeft = left
        frame.boundsDragTop = top
        frame.boundsDragDefaultLeft = defaultLeft
        frame.boundsDragDefaultTop = defaultTop
        frame.isBoundsDragging = true

        SetPosition(frame, left, top, true)
        SetCursor("Interface\\Cursor\\UI-Cursor-Move")
        return true
    end

    function SharedUtil:StopMoving(frame)
        if not frame.isBoundsDragging then return end

        frame.isBoundsDragging = false
        ResetCursor()
        UIKit_Utils:AwaitProtectedEvent(function() self:SaveBounds(frame) end, frame)
    end
end

do -- Conversion
    function SharedUtil:CalculateDistance(yds)
        if Config.DBGlobal:GetVariable("PrefMetric") then
            return math.ceil(yds * 0.9144)
        else
            return math.ceil(yds)
        end
    end

    function SharedUtil:FormatDistance(yds)
        if Config.DBGlobal:GetVariable("PrefMetric") then
            local m = self:CalculateDistance(yds)
            return m > 1000 and string.format("%0.2f", m / 1000) .. " km" or m .. " m"
        else
            return BreakUpLargeNumbers(math.ceil(yds)) .. " yds"
        end
    end
end

do -- Context Icon Scale
    function SharedUtil:GetContextIconScaleOffset()
        return env.Enum.ContextIconScaleOffset[Config.DBGlobal:GetVariable("ContextIconAppearance")]
    end
end
