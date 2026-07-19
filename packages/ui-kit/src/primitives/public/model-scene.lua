local env = select(2, ...)
local UIKit_Primitives_Frame = env.modules:Import("packages\\ui-kit\\primitives\\frame")
local UIKit_Primitives_ModelScene = env.modules:New("packages\\ui-kit\\primitives\\model-scene")

local GetCursorPosition = GetCursorPosition
local Mixin = Mixin

local DEFAULT_CAMERA = {
    position    = { x = 4, y = 0, z = 0 },
    orientation = { yaw = math.pi, pitch = 0, roll = 0 },
    fieldOfView = 0.75,
    nearClip    = 0.01,
    farClip     = 100,
    light       = {
        visible   = true,
        type      = 0,
        direction = { x = -1, y = 0, z = -1 },
        diffuse   = { r = 0.8, g = 0.8, b = 0.8 },
        ambient   = { r = 0.6, g = 0.6, b = 0.6 }
    }
}


local ModelSceneMixin = {}

local function GetCursorScale(frame)
    local scale = frame:GetEffectiveScale()
    return scale ~= 0 and (1 / scale) or 1
end

function ModelSceneMixin:GetActor()
    return self.__ActorFrame
end

function ModelSceneMixin:SetActor(actor)
    self.__ActorFrame = actor
end

function ModelSceneMixin:GetCameraSettings()
    return self.__cameraSettings
end

function ModelSceneMixin:InitializeCamera(settings)
    if not settings then settings = DEFAULT_CAMERA end

    if settings.position then self:SetCameraPosition(settings.position.x, settings.position.y, settings.position.z) end
    if settings.orientation then self:SetCameraOrientationByYawPitchRoll(settings.orientation.yaw, settings.orientation.pitch, settings.orientation.roll) end
    if settings.fieldOfView then self:SetCameraFieldOfView(settings.fieldOfView) end
    if settings.nearClip then self:SetCameraNearClip(settings.nearClip) end
    if settings.farClip then self:SetCameraFarClip(settings.farClip) end
    if settings.light then
        if settings.light.visible ~= nil then self:SetLightVisible(settings.light.visible) end
        if settings.light.type ~= nil then self:SetLightType(settings.light.type) end
        if settings.light.direction then self:SetLightDirection(settings.light.direction.x, settings.light.direction.y, settings.light.direction.z) end
        if settings.light.diffuse then self:SetLightDiffuseColor(settings.light.diffuse.r, settings.light.diffuse.g, settings.light.diffuse.b) end
        if settings.light.ambient then self:SetLightAmbientColor(settings.light.ambient.r, settings.light.ambient.g, settings.light.ambient.b) end
    end

    self.__cameraSettings = settings
    return self
end

function ModelSceneMixin:OnMouseDown(button)
    if button ~= "LeftButton" then return end

    local actor = self.__ActorFrame
    if not actor or not actor:IsLoaded() then return end

    local cursorX = GetCursorPosition()
    if not cursorX then return end

    self.__rotationOriginX = cursorX * GetCursorScale(self)
    self.__rotationOriginYaw = actor:GetYaw() or 0
end

function ModelSceneMixin:OnMouseUp(button)
    if button ~= "LeftButton" then return end

    self.__rotationOriginX = nil
    self.__rotationOriginYaw = nil
end

function ModelSceneMixin:OnHide()
    self.__rotationOriginX = nil
    self.__rotationOriginYaw = nil
end

function ModelSceneMixin:OnUpdate()
    local originX = self.__rotationOriginX
    local originYaw = self.__rotationOriginYaw
    local actor = self.__ActorFrame
    if not originX or not originYaw or not actor then return end

    local cursorX = GetCursorPosition()
    if not cursorX then return end

    local yaw = originYaw + (cursorX * GetCursorScale(self) - originX) * (math.pi / 360)
    actor:SetYaw(yaw)
end


function UIKit_Primitives_ModelScene.New(name, parent, template)
    name = name or "undefined"

    local frame = UIKit_Primitives_Frame.New("ModelScene", name, parent, template)
    if template then return frame end

    Mixin(frame, ModelSceneMixin)
    frame:InitializeCamera()

    local actorFrame = frame:CreateActor(name .. ".ActorFrame")
    actorFrame:SetPosition(0, 0, 0)
    actorFrame:SetUseCenterForOrigin(true, true, true)
    actorFrame:SetYaw(0)
    actorFrame:Show()

    frame.__ActorFrame = actorFrame
    frame:EnableMouse(true)

    frame:HookScript("OnMouseDown", function(_, button) frame:OnMouseDown(button) end)
    frame:HookScript("OnMouseUp", function(_, button) frame:OnMouseUp(button) end)
    frame:HookScript("OnHide", function() frame:OnHide() end)
    frame:HookScript("OnUpdate", function() frame:OnUpdate() end)

    return frame
end
