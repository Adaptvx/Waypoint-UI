local env                              = select(2, ...)

local Mixin                            = Mixin
local tinsert                          = table.insert
local tremove                          = table.remove

local UIKit_Primitives_Frame           = env.WPM:Import("wpm_modules\\ui-kit\\primitives\\frame")
local UIKit_Primitives_InteractiveRect = env.WPM:New("wpm_modules\\ui-kit\\primitives\\interactive-rect")


-- Interactive Rect
----------------------------------------------------------------------------------------------------

local InteractiveRectMixin = {}

function InteractiveRectMixin:AddOnEnter(callback)
    self.__enterHooks = self.__enterHooks or {}
    tinsert(self.__enterHooks, callback)
end

function InteractiveRectMixin:AddOnLeave(callback)
    self.__leaveHooks = self.__leaveHooks or {}
    tinsert(self.__leaveHooks, callback)
end

function InteractiveRectMixin:AddOnMouseDown(callback)
    self.__mouseDownHooks = self.__mouseDownHooks or {}
    tinsert(self.__mouseDownHooks, callback)
end

function InteractiveRectMixin:AddOnMouseUp(callback)
    self.__mouseUpHooks = self.__mouseUpHooks or {}
    tinsert(self.__mouseUpHooks, callback)
end

function InteractiveRectMixin:RemoveOnEnter(callback)
    if not self.__enterHooks then return end
    for i = #self.__enterHooks, 1, -1 do
        if self.__enterHooks[i] == callback then
            tremove(self.__enterHooks, i)
            break
        end
    end
    if #self.__enterHooks == 0 then self.__enterHooks = nil end
end

function InteractiveRectMixin:RemoveOnLeave(callback)
    if not self.__leaveHooks then return end
    for i = #self.__leaveHooks, 1, -1 do
        if self.__leaveHooks[i] == callback then
            tremove(self.__leaveHooks, i)
            break
        end
    end
    if #self.__leaveHooks == 0 then self.__leaveHooks = nil end
end

function InteractiveRectMixin:RemoveOnMouseDown(callback)
    if not self.__mouseDownHooks then return end
    for i = #self.__mouseDownHooks, 1, -1 do
        if self.__mouseDownHooks[i] == callback then
            tremove(self.__mouseDownHooks, i)
            break
        end
    end
    if #self.__mouseDownHooks == 0 then self.__mouseDownHooks = nil end
end

function InteractiveRectMixin:RemoveOnMouseUp(callback)
    if not self.__mouseUpHooks then return end
    for i = #self.__mouseUpHooks, 1, -1 do
        if self.__mouseUpHooks[i] == callback then
            tremove(self.__mouseUpHooks, i)
            break
        end
    end
    if #self.__mouseUpHooks == 0 then self.__mouseUpHooks = nil end
end

local function ProcessCallback(var)
    if not var then return end
    for i = 1, #var do
        var[i]()
    end
end

local function HandleEnter(self)
    ProcessCallback(self.__enterHooks)
end

local function HandleLeave(self)
    ProcessCallback(self.__leaveHooks)
end

local function HandleMouseDown(self)
    ProcessCallback(self.__mouseDownHooks)
end

local function HandleMouseUp(self)
    ProcessCallback(self.__mouseUpHooks)
end


function UIKit_Primitives_InteractiveRect.New(name, parent)
    name = name or "undefined"


    local frame = UIKit_Primitives_Frame.New("Frame", name, parent)
    Mixin(frame, InteractiveRectMixin)
    frame:EnableMouse(true)
    frame:AwaitSetPropagateMouseClicks(true)
    frame:AwaitSetPropagateMouseMotion(true)

    -- Events
    ----------------------------------------------------------------------------------------------------

    frame:SetScript("OnEnter", HandleEnter)
    frame:SetScript("OnLeave", HandleLeave)
    frame:SetScript("OnMouseDown", HandleMouseDown)
    frame:SetScript("OnMouseUp", HandleMouseUp)


    return frame
end
