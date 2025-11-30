local env             = select(2, ...)
local MixinUtil       = env.WPM:Import("wpm_modules/mixin-util")
local Frame           = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")

local Mixin           = MixinUtil.Mixin
local table_insert    = table.insert
local table_remove    = table.remove

local InteractiveRect = env.WPM:New("wpm_modules/ui-kit/primitives/interactiveRect")





local RectMixin = {}
do -- Mixin
    function RectMixin:AddOnEnter(callback)
        self.__enterHooks = self.__enterHooks or {}
        table_insert(self.__enterHooks, callback)
    end

    function RectMixin:AddOnLeave(callback)
        self.__leaveHooks = self.__leaveHooks or {}
        table_insert(self.__leaveHooks, callback)
    end

    function RectMixin:AddOnMouseDown(callback)
        self.__mouseDownHooks = self.__mouseDownHooks or {}
        table_insert(self.__mouseDownHooks, callback)
    end

    function RectMixin:AddOnMouseUp(callback)
        self.__mouseUpHooks = self.__mouseUpHooks or {}
        table_insert(self.__mouseUpHooks, callback)
    end

    function RectMixin:RemoveOnEnter(callback)
        if not self.__enterHooks then return end
        for i = #self.__enterHooks, 1, -1 do
            if self.__enterHooks[i] == callback then
                table_remove(self.__enterHooks, i)
                break
            end
        end
        if #self.__enterHooks == 0 then self.__enterHooks = nil end
    end

    function RectMixin:RemoveOnLeave(callback)
        if not self.__leaveHooks then return end
        for i = #self.__leaveHooks, 1, -1 do
            if self.__leaveHooks[i] == callback then
                table_remove(self.__leaveHooks, i)
                break
            end
        end
        if #self.__leaveHooks == 0 then self.__leaveHooks = nil end
    end

    function RectMixin:RemoveOnMouseDown(callback)
        if not self.__mouseDownHooks then return end
        for i = #self.__mouseDownHooks, 1, -1 do
            if self.__mouseDownHooks[i] == callback then
                table_remove(self.__mouseDownHooks, i)
                break
            end
        end
        if #self.__mouseDownHooks == 0 then self.__mouseDownHooks = nil end
    end

    function RectMixin:RemoveOnMouseUp(callback)
        if not self.__mouseUpHooks then return end
        for i = #self.__mouseUpHooks, 1, -1 do
            if self.__mouseUpHooks[i] == callback then
                table_remove(self.__mouseUpHooks, i)
                break
            end
        end
        if #self.__mouseUpHooks == 0 then self.__mouseUpHooks = nil end
    end

    function RectMixin:RegisterParent(parent)
        self:SetParent(parent)
        self:ClearAllPoints()
        self:SetAllPoints(parent)
        self:SetFrameLevel(1000)
    end
end





local function processCallback(var)
    if not var then return end
    for i = 1, #var do
        var[i]()
    end
end

local function handleEnter(self)
    processCallback(self.__enterHooks)
end

local function handleLeave(self)
    processCallback(self.__leaveHooks)
end

local function handleMouseDown(self)
    processCallback(self.__mouseDownHooks)
end

local function handleMouseUp(self)
    processCallback(self.__mouseUpHooks)
end





function InteractiveRect:New(name, parent)
    name = name or "undefined"


    local frame = Frame:New("Frame", name, parent)
    Mixin(frame, RectMixin)
    frame:EnableMouse(true)
    frame:AwaitSetPropagateMouseClicks(true)
    frame:AwaitSetPropagateMouseMotion(true)

    -- Events
    --------------------------------

    frame:SetScript("OnEnter", handleEnter)
    frame:SetScript("OnLeave", handleLeave)
    frame:SetScript("OnMouseDown", handleMouseDown)
    frame:SetScript("OnMouseUp", handleMouseUp)


    return frame
end
