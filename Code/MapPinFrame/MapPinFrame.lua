local env = select(2, ...)
local L = env.L
local Config = env.Config
local Pool = env.modules:Import("packages\\pool")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local GenericEnum = env.modules:Import("packages\\generic-enum")
local UIKit = env.modules:Import("packages\\ui-kit")
local Frame, LayoutGrid, LayoutHorizontal, LayoutVertical, Text, ScrollContainer, LazyScrollContainer, ScrollBar, ScrollContainerEdge, Input, LinearSlider, HitRect, List, SecureButton, ModelScene = unpack(UIKit.UI.Frames)
local UICSharedMixin = env.modules:Import("packages\\uic-sharedmixin")
local Navigation_DataProvider = env.modules:Await("@\\Navigation\\DataProvider")
local Waypoint = env.modules:Import("@\\Waypoint")
local Waypoint_DataProvider = env.modules:Import("@\\Waypoint\\DataProvider")
local MapPin = env.modules:Import("@\\MapPin")
local MapPinFrame = env.modules:New("@\\MapPinFrame")
local MapPinFrame_Preload = env.modules:Import("@\\MapPinFrame\\Preload")
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")

local SetSuperTrackedUserWaypoint = C_SuperTrack.SetSuperTrackedUserWaypoint
local IsSuperTrackingUserWaypoint = C_SuperTrack.IsSuperTrackingUserWaypoint
local GetMapInfo = C_Map.GetMapInfo
local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetUserWaypoint = C_Map.GetUserWaypoint
local GetUserWaypointHyperlink = C_Map.GetUserWaypointHyperlink
local ClearUserWaypoint = C_Map.ClearUserWaypoint
local HasUserWaypoint = C_Map.HasUserWaypoint
local CreateFromMixins = CreateFromMixins
local CreateFrame = CreateFrame
local Mixin = Mixin
local IsModifiedClick = IsModifiedClick
local IsControlKeyDown = IsControlKeyDown
local PlaySound = PlaySound
local GetTime = GetTime
local type = type
local pairs = pairs
local max = math.max
local format = string.format



MapPinFrame.numPins = 1
MapPinFrame.StoredPins = {}

local DBGlobal = nil
local WUIMapPinFrame, WUIMinimapPinFrame = nil, nil
local WUIPathStepWaypointFrame, WUIPathStepWaypointMinimapFrame = nil, nil
local HasActivePathfinding = false
local SuppressedWorldMapCtrlClickTime = nil

local USER_WAYPOINT_PIN_TEMPLATE = "WaypointLocationPinTemplate"
local WORLD_MAP_CTRL_CLICK_SUPPRESS_SECONDS = 0.25



local function IsPathfindingEnabled()
    if not DBGlobal or DBGlobal:GetVariable("PathfindingEnabled") ~= true then return false end
    return Navigation_DataProvider:IsEnabled()
end

local function HasWaypointUIPinReplacement()
    return MapPin.GetUserNavigation() ~= nil or MapPin.GetPathStepWaypoint() ~= nil or Navigation_DataProvider:IsCurrentPathStepHandledByOverlay()
end

local function ClearUserNavigationPin()
    if MapPin.GetUserNavigation() then
        MapPin.ClearUserNavigation()
        return
    end

    ClearUserWaypoint()
    SetSuperTrackedUserWaypoint(false)
end

local function ShouldPreserveNativeDestination(options)
    if type(options) == "table" then return options.preserveNativeDestination == true end
    return options == true
end

local function ClearActivePathfinding(options)
    if not IsPathfindingEnabled() then return end

    if Navigation_DataProvider:HasPath() then
        Navigation_DataProvider:ClearSessionData(options)
    end
end

local function StartUserNavigationPath()
    if not IsPathfindingEnabled() then return end

    Navigation_DataProvider:SetUserWaypointDestination()
end

local function SyncUserNavigationAfterPathfindingStop(options)
    if ShouldPreserveNativeDestination(options) then return end

    if IsPathfindingEnabled() then return end

    if MapPin.GetUserNavigation() and MapPin.GetUserNavigation().superTracked then
        MapPin.SyncUserNavigationToNativeWaypoint()
    else
        MapPin.SyncUserNavigationSuperTracking(false)
    end
end

local function SetUserNavigationTracking(superTracked)
    if not MapPin.GetUserNavigation() then
        if IsPathfindingEnabled() and not superTracked then
            ClearActivePathfinding({ preserveNativeDestination = true })
        end
        SetSuperTrackedUserWaypoint(superTracked)
        return
    end

    if IsPathfindingEnabled() then
        if superTracked then
            MapPin.SetUserNavigationSuperTracked(true, false)
            MapPin.SyncUserNavigationToNativeWaypoint()
            StartUserNavigationPath()
        else
            ClearActivePathfinding({ preserveNativeDestination = true })
            MapPin.SetUserNavigationSuperTracked(false, false)
            SetSuperTrackedUserWaypoint(false)
        end
        return
    end

    if superTracked then
        MapPin.SetUserNavigationSuperTracked(true, false)
        MapPin.SyncUserNavigationToNativeWaypoint()
    else
        MapPin.SetUserNavigationSuperTracked(false, true)
        SetSuperTrackedUserWaypoint(false)
    end
end

local function IsUserNavigationDuplicatedByStoredPin(pinInfo)
    return pinInfo and pinInfo.sourcePinID and MapPin.IsCustomMapPinsEnabled() and MapPin.GetPin(pinInfo.sourcePinID) ~= nil
end

local function IsPathfindingUserNavigationPin(pinInfo)
    return pinInfo and MapPin.IsCustomUserNavigation(pinInfo)
end

local function ShouldShowPinWithCustomMapPinsDisabled(pin, pinInfo)
    if not IsPathfindingEnabled() then return false end
    if pin.isPathStepWaypoint then return true end
    return pin.isUserNavigation and IsPathfindingUserNavigationPin(pinInfo)
end

local function IsMinimapPinRegistered(pin)
    local minimapPins = HBDPins.minimapPins
    return minimapPins and minimapPins[pin] ~= nil
end

local function GetMinimapRegistrationFrame(pin)
    return pin and pin.hbdMinimapAnchor or pin
end

local function IsParentZoneMap(mapID, parentMapID)
    local mapInfo = GetMapInfo(mapID)
    local currentParentMapID = mapInfo and mapInfo.parentMapID or nil

    while currentParentMapID do
        if currentParentMapID == parentMapID then
            return true
        end

        mapInfo = GetMapInfo(currentParentMapID)
        currentParentMapID = mapInfo and mapInfo.parentMapID or nil
    end

    return false
end

local function CanShowPinOnMinimap(mapID)
    local playerMapID = GetBestMapForUnit("player")
    if not playerMapID or type(mapID) ~= "number" then return false end

    return mapID == playerMapID or IsParentZoneMap(mapID, playerMapID)
end

local function AddWorldMapPin(pin, mapID, x, y)
    local worldX, worldY, instanceID = HBD:GetWorldCoordinatesFromZone(x, y, mapID)
    if worldX and worldY and instanceID then
        HBDPins:AddWorldMapIconWorld(env, pin, instanceID, worldX, worldY, HBD_PINS_WORLDMAP_SHOW_WORLD)
        return
    end

    HBDPins:AddWorldMapIconMap(env, pin, mapID, x, y, HBD_PINS_WORLDMAP_SHOW_WORLD)
end

do --Map Pin Template
    local FOREGROUND_SIZE = UIKit.Define.Percentage{ value = 100, operator = "-", delta = 14 }
    local CONTENT_SIZE = UIKit.Define.Percentage{ value = 28 }
    local MINIMAP_CONTENT_SIZE = UIKit.Define.Percentage{ value = 36 }
    local WORLD_MAP_HITBOX_INSET = 10
    local MINIMAP_HITBOX_INSET = 16
    local HITBOX_FRAME_LEVEL_OFFSET = 100

    local MapPinFrameMixin = CreateFromMixins(UICSharedMixin.ButtonMixin)

    local function PriorityHitbox_OnEnter(self)
        self:GetParent():OnEnter()
    end

    local function PriorityHitbox_OnLeave(self)
        self:GetParent():OnLeave()
    end

    local function PriorityHitbox_OnMouseDown(self, button)
        self:GetParent():OnMouseDown(button)
    end

    local function PriorityHitbox_OnMouseUp(self, button)
        self:GetParent():OnMouseUp(button)
    end

    function MapPinFrameMixin:GetHitboxInset()
        return self.displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap and MINIMAP_HITBOX_INSET or WORLD_MAP_HITBOX_INSET
    end

    function MapPinFrameMixin:UpdateHitboxSize()
        local hitboxInset = self:GetHitboxInset()
        self:SetHitRectInsets(hitboxInset, hitboxInset, hitboxInset, hitboxInset)

        if self.priorityHitbox then
            self.priorityHitbox:SetHitRectInsets(hitboxInset, hitboxInset, hitboxInset, hitboxInset)
        end
    end

    function MapPinFrameMixin:OnLoad(pinType, displayLayer)
        self:InitButton()

        self.contextIcon = nil
        self.pinID = nil
        self.pinInfo = nil
        self.pinType = pinType or MapPinFrame_Preload.Enum.MapPinType.Pin
        self.displayLayer = displayLayer or MapPinFrame_Preload.Enum.DisplayLayer.WorldMap
        self.isInteractive = self.displayLayer ~= MapPinFrame_Preload.Enum.DisplayLayer.Minimap
        self.isUserNavigation = self.pinType == MapPinFrame_Preload.Enum.MapPinType.UserNavigation
        self.isPathStepWaypoint = self.pinType == MapPinFrame_Preload.Enum.MapPinType.PathStepWaypoint
        self.active = false
        self.pinTemplate = (self.isUserNavigation or self.isPathStepWaypoint) and USER_WAYPOINT_PIN_TEMPLATE or nil
        self.tintColor = {}
        self.resolvedTintColor = {}
        self.iconPath = nil
        self.iconType = nil
        self.iconRecolored = nil
        self.iconOpacity = nil
        self.attachedMapID = nil
        self.attachedX = nil
        self.attachedY = nil
        self.isAttached = false
        self.priorityHitbox = nil

        self:RegisterMouseEvents()
        self:CreatePriorityHitbox()
        self:UpdateHitboxSize()
        self:HookMouseEnter(self.ShowTooltip)
        self:HookMouseLeave(self.HideTooltip)

        if self.isInteractive then
            self:HookButtonStateChange(self.UpdateAnimation)
            self:HookEnableChange(self.UpdateAnimation)
            self:HookMouseDown(self.SuppressWorldMapCtrlClick)
            self:HookMouseUp(self.SuppressWorldMapCtrlClick)
            self:HookClick(self.HandleClick)
            self:SetScale(0.6)
        else
            self:SetScale(1)
            self.Container:SetScale(0.5)
        end

        if self.isUserNavigation or self.isPathStepWaypoint then
            self:RegisterEvent("USER_WAYPOINT_UPDATED")
            self:RegisterEvent("SUPER_TRACKING_CHANGED")
            self:SetScript("OnEvent", self.OnEvent)
        end

        self:SetActive(false)
        if self.isInteractive then self:UpdateAnimation() end
        self:Refresh()
    end

    function MapPinFrameMixin:CreatePriorityHitbox()
        local hitbox = CreateFrame("Button", nil, self)
        hitbox:SetAllPoints(self)
        hitbox:EnableMouse(true)
        hitbox:SetScript("OnEnter", PriorityHitbox_OnEnter)
        hitbox:SetScript("OnLeave", PriorityHitbox_OnLeave)
        hitbox:SetScript("OnMouseDown", PriorityHitbox_OnMouseDown)
        hitbox:SetScript("OnMouseUp", PriorityHitbox_OnMouseUp)

        self.priorityHitbox = hitbox
        self:UpdatePriorityHitbox()
    end

    function MapPinFrameMixin:UpdatePriorityHitbox()
        if not self.priorityHitbox then return end

        if self.displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap then
            self.priorityHitbox:SetFrameStrata(self:GetFrameStrata())
            self.priorityHitbox:SetFrameLevel(self:GetFrameLevel() + HITBOX_FRAME_LEVEL_OFFSET)
            return
        end

        self.priorityHitbox:SetFrameStrata("HIGH")
        self.priorityHitbox:SetFrameLevel(max(self:GetFrameLevel() + HITBOX_FRAME_LEVEL_OFFSET, 9000 + HITBOX_FRAME_LEVEL_OFFSET))
    end

    function MapPinFrameMixin:UpdateAnimation()
        local buttonState = self:GetButtonState()
        local pushed = buttonState == "PUSHED"

        self.Container:ClearAllPoints()
        self.Container:SetPoint("CENTER", self, "CENTER", pushed and 1 or 0, pushed and -1 or 0)
        self.Background:background((pushed or buttonState == "HIGHLIGHTED") and MapPinFrame_Preload.UIDEF.UIMapPinFrame_Highlighted or MapPinFrame_Preload.UIDEF.UIMapPinFrame)
    end

    function MapPinFrameMixin:SuppressWorldMapCtrlClick(button)
        if button ~= "LeftButton" then return end
        if not IsControlKeyDown() then return end
        if not IsPathfindingEnabled() then return end
        if self.displayLayer ~= MapPinFrame_Preload.Enum.DisplayLayer.WorldMap then return end

        MapPinFrame:SuppressNextWorldMapCtrlClick()
    end

    function MapPinFrameMixin:HandleClick(button)
        if button ~= "LeftButton" then return end

        if self.isUserNavigation then
            if IsModifiedClick("CHATLINK") then
                local hyperlink = GetUserWaypointHyperlink()
                if hyperlink then
                    ChatFrameUtil.InsertLink(hyperlink)
                    PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE)
                end
                return
            end

            if IsControlKeyDown() then
                self:HideTooltip()
                ClearUserNavigationPin()
                if IsPathfindingEnabled() then
                    ClearActivePathfinding()
                end
                PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_REMOVE)
                return
            end

            if IsPathfindingEnabled() then
                SetUserNavigationTracking(self.active ~= true)
            else
                SetUserNavigationTracking(not IsSuperTrackingUserWaypoint())
            end

            self:RefreshActive()
            return
        end

        if self.isPathStepWaypoint then
            self:HideTooltip()
            Navigation_DataProvider:AbortPathfindingFromPathStepWaypoint()
            PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_REMOVE)
            return
        end

        if IsModifiedClick("CHATLINK") and self.pinID then
            local userNavigation = MapPin.NewUserNavigationFromPin(self.pinID, true)
            local hyperlink = userNavigation and GetUserWaypointHyperlink()
            if hyperlink then
                ChatFrameUtil.InsertLink(hyperlink)
                PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_CHAT_SHARE)
            end
            return
        end

        if IsControlKeyDown() then
            self:HideTooltip()
            MapPin.ClearPin(self.pinID)
            PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_REMOVE)
            return
        end

        if self.pinID then
            if self:IsActiveUserNavigationSourcePin() then
                local userNavigation = MapPin.GetUserNavigation()
                SetUserNavigationTracking(not (userNavigation and userNavigation.superTracked == true))
                self:RefreshActive()
                return
            end

            MapPin.NewUserNavigationFromPin(self.pinID)
        end
    end

    function MapPinFrameMixin:OnEvent()
        self:Refresh()
    end

    function MapPinFrameMixin:SetIcon(texture)
        if self.iconType == "TEXTURE" and self.iconPath == texture then return end

        self.iconType = "TEXTURE"
        self.iconPath = texture
        self.ImageTexture:SetTexture(texture)
    end

    function MapPinFrameMixin:SetAtlas(atlas)
        if self.iconType == "ATLAS" and self.iconPath == atlas then return end

        self.iconType = "ATLAS"
        self.iconPath = atlas
        self.ImageTexture:SetAtlas(atlas)
    end

    function MapPinFrameMixin:SetOpacity(opacity)
        if self.iconOpacity == opacity then return end

        self.iconOpacity = opacity
        self.Content:SetAlpha(opacity)
    end

    function MapPinFrameMixin:SetTint(color)
        if not color then return end
        if self.tintColor.r == color.r and self.tintColor.g == color.g and self.tintColor.b == color.b and self.tintColor.a == color.a then return end

        self.tintColor.r = color.r
        self.tintColor.g = color.g
        self.tintColor.b = color.b
        self.tintColor.a = color.a
        self.BackgroundTexture:SetColor(self.tintColor)

        if self.iconRecolored then
            self.ImageTexture:SetColor(self.tintColor)
        end
    end

    function MapPinFrameMixin:SetData(contextIcon)
        if not contextIcon then return end

        if contextIcon.type == "ATLAS" then
            self:SetAtlas(contextIcon.path)
        else
            self:SetIcon(contextIcon.path)
        end
    end

    function MapPinFrameMixin:SetIconOpacity(opacity)
        self:SetOpacity(opacity)
    end

    function MapPinFrameMixin:SetIconRecolor(shouldRecolor)
        shouldRecolor = shouldRecolor == true
        if self.iconRecolored == shouldRecolor then return end

        self.iconRecolored = shouldRecolor
        self.ImageTexture:SetDesaturated(shouldRecolor)
        self.ImageTexture:SetColor(shouldRecolor and (self.tintColor.r and self.tintColor or GenericEnum.ColorRGB01.WHITE_FONT_COLOR) or GenericEnum.ColorRGB01.WHITE_FONT_COLOR)
    end

    function MapPinFrameMixin:SetActive(active)
        active = active == true
        self.active = active
        self.Glow:SetShown(active)
    end

    function MapPinFrameMixin:RefreshActive()
        local active = false

        if self.isPathStepWaypoint then
            active = MapPin.IsPathStepWaypointTracked()
        elseif self.isUserNavigation then
            local userNavigation = MapPin.GetUserNavigation()
            if IsPathfindingEnabled() then
                active = userNavigation and userNavigation.superTracked == true
            else
                active = IsSuperTrackingUserWaypoint() == true
            end
        elseif self.pinID then
            local userNavigation = MapPin.GetUserNavigation()
            local sourcePinID = userNavigation and userNavigation.sourcePinID or nil
            active = userNavigation and userNavigation.superTracked == true and sourcePinID ~= nil and sourcePinID == self.pinID
        end

        self:SetActive(active)
    end

    function MapPinFrameMixin:GetResolvedPinInfo()
        if self.isUserNavigation then
            return self.pinInfo or MapPin.GetUserNavigation()
        elseif self.isPathStepWaypoint then
            return MapPin.GetPathStepWaypoint()
        end

        return self.pinID and MapPin.GetPin(self.pinID) or nil
    end

    function MapPinFrameMixin:GetResolvedMapLocation(pinInfo)
        if self.isUserNavigation or self.isPathStepWaypoint then
            if pinInfo and pinInfo.mapID and pinInfo.x and pinInfo.y then
                return pinInfo.mapID, pinInfo.x, pinInfo.y
            end

            if self.isPathStepWaypoint then return nil, nil, nil end

            if not HasUserWaypoint() then return nil, nil, nil end

            local point = GetUserWaypoint()
            if not point or not point.position then return nil, nil, nil end

            return point.uiMapID, point.position.x, point.position.y
        end

        if not pinInfo then return nil, nil, nil end
        return pinInfo.mapID, pinInfo.x, pinInfo.y
    end

    function MapPinFrameMixin:HideFromSurface()
        self:DetachFromSurface()
    end

    function MapPinFrameMixin:IsSameAttachment(mapID, x, y)
        return self.isAttached and self.attachedMapID == mapID and self.attachedX == x and self.attachedY == y
    end

    function MapPinFrameMixin:ClearAttachmentState()
        self.attachedMapID = nil
        self.attachedX = nil
        self.attachedY = nil
        self.isAttached = false
    end

    function MapPinFrameMixin:SetAttachmentState(mapID, x, y, isAttached)
        if isAttached == true then
            self.attachedMapID = mapID
            self.attachedX = x
            self.attachedY = y
            self.isAttached = true
            return
        end

        self:ClearAttachmentState()
    end

    function MapPinFrameMixin:ShowTooltip()
        if not self:IsShown() then return end

        local isMinimap = self.displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap
        local pinInfo = self:GetResolvedPinInfo()
        local mapID, x, y = self:GetResolvedMapLocation(pinInfo)
        local name = nil
        local coordinates = nil
        if type(x) == "number" and type(y) == "number" then
            name = pinInfo and pinInfo.name or (mapID and MapPin.GeneratePinName(mapID) or nil)
            coordinates = format(L["WAYPOINTSYSTEM_COORDINATE_FORMAT"], x * 100, y * 100)
        end

        if not name and not coordinates then return end

        GameTooltip:SetOwner(self, isMinimap and "ANCHOR_CURSOR" or "ANCHOR_RIGHT")
        if isMinimap then
            if name then
                GameTooltip:AddLine(name, GenericEnum.ColorRGB01.WHITE_FONT_COLOR.r, GenericEnum.ColorRGB01.WHITE_FONT_COLOR.g, GenericEnum.ColorRGB01.WHITE_FONT_COLOR.b)
            end
            if coordinates then
                GameTooltip:AddLine(coordinates, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.r, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.g, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.b)
            end
        else
            GameTooltip:AddDoubleLine(name or "", coordinates or "", GenericEnum.ColorRGB01.WHITE_FONT_COLOR.r, GenericEnum.ColorRGB01.WHITE_FONT_COLOR.g, GenericEnum.ColorRGB01.WHITE_FONT_COLOR.b, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.r, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.g, GenericEnum.ColorRGB01.LIGHTGRAY_FONT_COLOR.b)
        end

        if not isMinimap then
            GameTooltip_AddNormalLine(GameTooltip, MAP_PIN_SHARING_TOOLTIP)
            GameTooltip_AddColoredLine(GameTooltip, MAP_PIN_REMOVE, GREEN_FONT_COLOR)
        end

        GameTooltip:Show()
    end

    function MapPinFrameMixin:HideTooltip()
        GameTooltip:Hide()
    end

    function MapPinFrameMixin:AttachToMap(mapID, x, y)
        if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
            self:DetachFromMap()
            return
        end
        if self:IsSameAttachment(mapID, x, y) then return end

        self:DetachFromMap()

        AddWorldMapPin(self, mapID, x, y)
        self:UpdatePriorityHitbox()
        self:SetAttachmentState(mapID, x, y, true)
    end

    function MapPinFrameMixin:DetachFromMap()
        if self.isAttached then HBDPins:RemoveWorldMapIcon(env, self) end
        self:ClearAttachmentState()
        self:Hide()
    end

    function MapPinFrameMixin:CanAttachToMinimap(mapID)
        if IsPathfindingEnabled() and (self.isUserNavigation or self.isPathStepWaypoint) then return true end
        return CanShowPinOnMinimap(mapID)
    end

    function MapPinFrameMixin:AttachToMinimap(mapID, x, y)
        if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" or not self:CanAttachToMinimap(mapID) then
            self:DetachFromMinimap(); return
        end
        if self:IsSameAttachment(mapID, x, y) then return end

        self:DetachFromMinimap()

        local minimapFrame = GetMinimapRegistrationFrame(self)
        HBDPins:AddMinimapIconMap(env, minimapFrame, mapID, x, y, true, false)
        self:UpdatePriorityHitbox()
        if not IsMinimapPinRegistered(minimapFrame) then
            self:ClearAttachmentState()
            self:Hide()
            return
        end

        self:Show()
        self:SetAttachmentState(mapID, x, y, true)
    end

    function MapPinFrameMixin:DetachFromMinimap()
        if self.isAttached then HBDPins:RemoveMinimapIcon(env, GetMinimapRegistrationFrame(self)) end
        self:ClearAttachmentState()
        self:Hide()
    end

    function MapPinFrameMixin:AttachToSurface(mapID, x, y)
        if self.displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap then
            self:AttachToMinimap(mapID, x, y)
        else
            self:AttachToMap(mapID, x, y)
        end
    end

    function MapPinFrameMixin:DetachFromSurface()
        if self.displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap then
            self:DetachFromMinimap()
        else
            self:DetachFromMap()
        end
    end

    function MapPinFrameMixin:GetTintColor()
        if not DBGlobal then return end

        local pinInfo = self:GetResolvedPinInfo()
        if pinInfo and pinInfo.r and pinInfo.g and pinInfo.b then
            self.resolvedTintColor.r = pinInfo.r
            self.resolvedTintColor.g = pinInfo.g
            self.resolvedTintColor.b = pinInfo.b
            self.resolvedTintColor.a = 1
            return self.resolvedTintColor, true
        end

        local requestRecolor = self.contextIcon and self.contextIcon.requestRecolor or false

        if DBGlobal:GetVariable("CustomColor") then
            return Waypoint.ResolveColorIntegrity(DBGlobal:GetVariable("CustomColorOther")), requestRecolor or DBGlobal:GetVariable("CustomColorOtherTint")
        end

        return env.Enum.ColorRGB01.Other, requestRecolor
    end

    function MapPinFrameMixin:GetContextIcon()
        local pinInfo = self:GetResolvedPinInfo()
        if pinInfo then return Waypoint_DataProvider.GetContextIconForPin(pinInfo) end
        if self.isUserNavigation or self.isPathStepWaypoint then return Waypoint_DataProvider.GetContextIconForUserNavigation() end
        return Waypoint_DataProvider.FallbackPinIcon
    end

    function MapPinFrameMixin:IsActiveUserNavigationSourcePin()
        return not self.isUserNavigation and self.pinID and self.pinID == MapPin.GetUserNavigationSourcePinID()
    end

    function MapPinFrameMixin:SetPinInfo(pinID, pinInfo)
        self.pinID = pinID
        self.pinInfo = self.isUserNavigation and pinInfo or nil
        self:Refresh()
    end

    function MapPinFrameMixin:Reset()
        self:HideTooltip()
        self.pinID = nil
        self.pinInfo = nil
        self.contextIcon = nil
        self:SetActive(false)
        self:DetachFromSurface()
    end

    function MapPinFrameMixin:Refresh()
        local pinInfo = self:GetResolvedPinInfo()
        if not MapPin.IsCustomMapPinsEnabled() and not ShouldShowPinWithCustomMapPinsDisabled(self, pinInfo) then
            self:HideFromSurface()
            return
        end

        if self.isUserNavigation and IsUserNavigationDuplicatedByStoredPin(pinInfo) then
            self:HideFromSurface()
            return
        end
        if not self.isUserNavigation and not self.isPathStepWaypoint and not pinInfo then
            self:HideFromSurface()
            return
        end

        local mapID, x, y = self:GetResolvedMapLocation(pinInfo)
        if type(mapID) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then
            self:HideFromSurface()
            return
        end

        self.contextIcon = self:GetContextIcon()
        if not self.contextIcon then return end

        local tintColor, recolor = self:GetTintColor()

        self:SetData(self.contextIcon)

        if tintColor then
            self:SetTint(tintColor)
        end

        self:SetIconRecolor(recolor)
        self:RefreshActive()
        self:AttachToSurface(mapID, x, y)
    end

    MapPinFrame.MapPin = UIKit.Template(function(id, name)
        local frame = Frame(name, {
                Frame(name .. "Container", {
                    Frame(name .. "Background")
                        :id("Background", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(FOREGROUND_SIZE, FOREGROUND_SIZE)
                        :background(MapPinFrame_Preload.UIDEF.UIMapPinFrame)
                        :frameLevel(2),

                    Frame(name .. "Glow")
                        :id("Glow", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(FOREGROUND_SIZE, FOREGROUND_SIZE)
                        :scale(1.5)
                        :alpha(0.75)
                        :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                        :background(MapPinFrame_Preload.UIDEF.UIMapPinFrameGlow)
                        :frameLevel(3),

                    Frame(name .. "Image")
                        :id("Image", id)
                        :point(UIKit.Enum.Point.Center)
                        :background(UIKit.UI.TEXTURE_NIL)
                        :frameLevel(3)
                        :size(CONTENT_SIZE, CONTENT_SIZE)
                })
                    :id("Container", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
            })
            :size(46, 46)
            :scale(1)

        frame.Container = UIKit.GetElementById("Container", id)
        frame.Glow = UIKit.GetElementById("Glow", id)
        frame.Background = UIKit.GetElementById("Background", id)
        frame.BackgroundTexture = frame.Background:GetTextureFrame()
        frame.ImageTexture = UIKit.GetElementById("Image", id):GetTextureFrame()
        frame.Content = frame.Container

        Mixin(frame, MapPinFrameMixin)

        return frame
    end)

    MapPinFrame.MinimapPin = UIKit.Template(function(id, name)
        local frame = Frame(name, {
                Frame(name .. "Container", {
                    Frame(name .. "Background")
                        :id("Background", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(FOREGROUND_SIZE, FOREGROUND_SIZE)
                        :background(MapPinFrame_Preload.UIDEF.UIMinimapPin)
                        :frameLevel(2),

                    Frame(name .. "Glow")
                        :id("Glow", id)
                        :point(UIKit.Enum.Point.Center)
                        :size(FOREGROUND_SIZE, FOREGROUND_SIZE)
                        :scale(1.5)
                        :alpha(0.75)
                        :backgroundBlendMode(UIKit.Enum.BlendMode.Add)
                        :background(MapPinFrame_Preload.UIDEF.UIMapPinFrameGlow)
                        :frameLevel(3),

                    Frame(name .. "Image")
                        :id("Image", id)
                        :point(UIKit.Enum.Point.Center)
                        :background(UIKit.UI.TEXTURE_NIL)
                        :frameLevel(3)
                        :size(MINIMAP_CONTENT_SIZE, MINIMAP_CONTENT_SIZE)
                })
                    :id("Container", id)
                    :point(UIKit.Enum.Point.Center)
                    :size(UIKit.UI.P_FILL, UIKit.UI.P_FILL)
            })
            :size(60, 60)
            :scale(1)

        frame.Container = UIKit.GetElementById("Container", id)
        frame.Glow = UIKit.GetElementById("Glow", id)
        frame.Background = UIKit.GetElementById("Background", id)
        frame.BackgroundTexture = frame.Background:GetTextureFrame()
        frame.ImageTexture = UIKit.GetElementById("Image", id):GetTextureFrame()
        frame.Content = frame.Container

        Mixin(frame, MapPinFrameMixin)

        return frame
    end)
end

local function BuildMapPinFrame(name, pinType, displayLayer)
    local isMinimapPin = displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap
    local anchor = nil
    local template = isMinimapPin and MapPinFrame.MinimapPin or MapPinFrame.MapPin

    if isMinimapPin then
        anchor = CreateFrame("Frame", nil, Minimap)
        anchor:SetSize(1, 1)
        anchor:EnableMouse(false)
        anchor:Hide()
    end

    local frame = template(name)
        :parent(anchor or UIParent)
        :point(UIKit.Enum.Point.Center)
        :_Render()

    frame.hbdMinimapAnchor = anchor or UIParent
    frame:SetIgnoreParentScale(displayLayer ~= MapPinFrame_Preload.Enum.DisplayLayer.Minimap)
    frame:Hide()
    frame:OnLoad(pinType, displayLayer)

    return frame
end

local function AcquireFrameName(prefix, displayLayer)
    local suffix = displayLayer == MapPinFrame_Preload.Enum.DisplayLayer.Minimap and "Minimap" or "World"
    local name = prefix .. MapPinFrame.numPins .. suffix

    MapPinFrame.numPins = MapPinFrame.numPins + 1

    return name
end

local function BuildStoredPinFrame(displayLayer)
    return BuildMapPinFrame(AcquireFrameName("WUIMapPinFrame", displayLayer), MapPinFrame_Preload.Enum.MapPinType.Pin, displayLayer)
end

local function ReleaseStoredPinFrame(_, pin)
    pin:Reset()
end

MapPinFrame.WorldPinPool = Pool.New(function() return BuildStoredPinFrame(MapPinFrame_Preload.Enum.DisplayLayer.WorldMap) end, ReleaseStoredPinFrame)
MapPinFrame.MinimapPinPool = Pool.New(function() return BuildStoredPinFrame(MapPinFrame_Preload.Enum.DisplayLayer.Minimap) end, ReleaseStoredPinFrame)

local function AcquireStoredPinPair(pinID)
    local storedPin = MapPinFrame.StoredPins[pinID]
    if storedPin then return storedPin end

    storedPin = {
        world   = MapPinFrame.WorldPinPool:Acquire(),
        minimap = MapPinFrame.MinimapPinPool:Acquire()
    }
    MapPinFrame.StoredPins[pinID] = storedPin

    return storedPin
end

local function GetStoredPinPair(pinID)
    local storedPin = MapPinFrame.StoredPins[pinID]
    if storedPin then return storedPin end

    local pinInfo = MapPin.GetPin(pinID)
    if not pinInfo then return nil end

    storedPin = AcquireStoredPinPair(pinID)
    storedPin.world:SetPinInfo(pinID, pinInfo)
    storedPin.minimap:SetPinInfo(pinID, pinInfo)

    return storedPin
end

local function ApplyStoredPin(pinID, method, ...)
    local storedPin = GetStoredPinPair(pinID)
    if not storedPin then return false end

    if storedPin.world then storedPin.world[method](storedPin.world, ...) end
    if storedPin.minimap then storedPin.minimap[method](storedPin.minimap, ...) end

    return true
end

function MapPinFrame:SuppressNextWorldMapCtrlClick()
    SuppressedWorldMapCtrlClickTime = GetTime()
end

function MapPinFrame:ConsumeWorldMapPinCtrlClick()
    if not SuppressedWorldMapCtrlClickTime then return false end

    local suppressAge = GetTime() - SuppressedWorldMapCtrlClickTime
    SuppressedWorldMapCtrlClickTime = nil
    if suppressAge <= WORLD_MAP_CTRL_CLICK_SUPPRESS_SECONDS then return true end

    return false
end

local function ApplyUserNavigationPin(method, ...)
    local applied = false

    if WUIMapPinFrame then
        WUIMapPinFrame[method](WUIMapPinFrame, ...)
        applied = true
    end
    if WUIMinimapPinFrame then
        WUIMinimapPinFrame[method](WUIMinimapPinFrame, ...)
        applied = true
    end

    return applied
end

function MapPinFrame:RefreshStoredPin(pinID)
    return ApplyStoredPin(pinID, "Refresh")
end

function MapPinFrame:SetUserNavigationPinInfo(pinInfo)
    return ApplyUserNavigationPin("SetPinInfo", nil, pinInfo)
end

function MapPinFrame:RefreshUserNavigationPin()
    return ApplyUserNavigationPin("Refresh")
end

function MapPinFrame:GetUserNavigationWorldPin()
    return WUIMapPinFrame
end

local function ApplyPathStepWaypointPin(method, ...)
    local applied = false

    if WUIPathStepWaypointFrame then
        WUIPathStepWaypointFrame[method](WUIPathStepWaypointFrame, ...)
        applied = true
    end
    if WUIPathStepWaypointMinimapFrame then
        WUIPathStepWaypointMinimapFrame[method](WUIPathStepWaypointMinimapFrame, ...)
        applied = true
    end

    return applied
end

function MapPinFrame:RefreshPathStepWaypointPin()
    return ApplyPathStepWaypointPin("Refresh")
end

function MapPinFrame:GetPathStepWaypointWorldPin()
    return WUIPathStepWaypointFrame
end

local function UpdateWaypointLocationPinVisibility()
    local shouldHide = MapPin.IsCustomMapPinsEnabled() or (IsPathfindingEnabled() and HasWaypointUIPinReplacement())

    for pin in WorldMapFrame:EnumeratePinsByTemplate(USER_WAYPOINT_PIN_TEMPLATE) do
        pin:EnableMouse(not shouldHide)
        pin:SetAlpha(shouldHide and 0 or 1)
    end
end

local function ReleaseStoredPinPair(pinID)
    local storedPin = MapPinFrame.StoredPins[pinID]
    if not storedPin then return end
    if storedPin.world then MapPinFrame.WorldPinPool:Release(storedPin.world) end
    if storedPin.minimap then MapPinFrame.MinimapPinPool:Release(storedPin.minimap) end
    MapPinFrame.StoredPins[pinID] = nil
end

local function RefreshStoredPinFrames(minimapOnly)
    minimapOnly = minimapOnly == true

    for _, storedPin in pairs(MapPinFrame.StoredPins) do
        if not minimapOnly and storedPin.world then storedPin.world:Refresh() end
        if storedPin.minimap then storedPin.minimap:Refresh() end
    end
end

local function RefreshUserNavigationPins(minimapOnly)
    minimapOnly = minimapOnly == true

    if not minimapOnly and WUIMapPinFrame then WUIMapPinFrame:Refresh() end
    if WUIMinimapPinFrame then WUIMinimapPinFrame:Refresh() end
end

local function RefreshPathStepWaypointPins(minimapOnly)
    minimapOnly = minimapOnly == true

    if not minimapOnly and WUIPathStepWaypointFrame then WUIPathStepWaypointFrame:Refresh() end
    if WUIPathStepWaypointMinimapFrame then WUIPathStepWaypointMinimapFrame:Refresh() end
end

local function RefreshVisiblePins(minimapOnly)
    minimapOnly = minimapOnly == true

    RefreshStoredPinFrames(minimapOnly)
    RefreshUserNavigationPins(minimapOnly)
    RefreshPathStepWaypointPins(minimapOnly)
end

local function RefreshMapPinsState()
    RefreshVisiblePins()
    UpdateWaypointLocationPinVisibility()
end

local function SyncStoredPinPair(pinID, pinInfo)
    if not pinInfo then
        ReleaseStoredPinPair(pinID)
        return
    end

    local storedPin = AcquireStoredPinPair(pinID)
    storedPin.world:SetPinInfo(pinID, pinInfo)
    storedPin.minimap:SetPinInfo(pinID, pinInfo)
end

local function RefreshStoredPins(_, pins, pinID, pinInfo)
    if pinID ~= nil then
        SyncStoredPinPair(pinID, pinInfo)
        return
    end

    pins = pins or MapPin.GetAllPins()
    if pins then
        for currentPinID, currentPinInfo in pairs(pins) do
            SyncStoredPinPair(currentPinID, currentPinInfo)
        end
    end
    for currentPinID in pairs(MapPinFrame.StoredPins) do
        if not pins or not pins[currentPinID] then ReleaseStoredPinPair(currentPinID) end
    end
end

local function RefreshPinsForUserNavigationChange()
    RefreshStoredPins()
    RefreshUserNavigationPins()
    UpdateWaypointLocationPinVisibility()
end

local function RefreshPinsForPathStepWaypointChange()
    RefreshPathStepWaypointPins()
    UpdateWaypointLocationPinVisibility()
end

CallbackRegistry.Add("Waypoint.UpdateColor", RefreshVisiblePins)
CallbackRegistry.Add("Waypoint.UpdateContext", RefreshVisiblePins)
CallbackRegistry.Add("MapPin.PinsChanged", RefreshStoredPins)
CallbackRegistry.Add("MapPin.MapPinsStateChanged", RefreshMapPinsState)
CallbackRegistry.Add("MapPin.UserNavigationChanged", RefreshPinsForUserNavigationChange)
CallbackRegistry.Add("MapPin.UserNavigationCleared", RefreshPinsForUserNavigationChange)
CallbackRegistry.Add("MapPin.PathStepWaypointChanged", RefreshPinsForPathStepWaypointChange)
CallbackRegistry.Add("MapPin.PathStepWaypointCleared", RefreshPinsForPathStepWaypointChange)
CallbackRegistry.Add("Navigation_DataProvider.StartPathfinding", function()
    HasActivePathfinding = true
    RefreshUserNavigationPins()
    RefreshPathStepWaypointPins()
    UpdateWaypointLocationPinVisibility()
end)
CallbackRegistry.Add("Navigation_DataProvider.StopPathfinding", function(_, options)
    HasActivePathfinding = false
    SyncUserNavigationAfterPathfindingStop(options)
    RefreshUserNavigationPins()
    RefreshPathStepWaypointPins()
    UpdateWaypointLocationPinVisibility()
end)
CallbackRegistry.Add("Navigation_DataProvider.ClearSessionData", function(_, options)
    HasActivePathfinding = false
    SyncUserNavigationAfterPathfindingStop(options)
    RefreshUserNavigationPins()
    RefreshPathStepWaypointPins()
    UpdateWaypointLocationPinVisibility()
end)
EventRegistry:RegisterCallback("MapCanvas.MapSet", UpdateWaypointLocationPinVisibility)
EventRegistry:RegisterCallback("WorldMapOnShow", UpdateWaypointLocationPinVisibility)

local EL = CreateFrame("Frame")
EL:RegisterEvent("USER_WAYPOINT_UPDATED")
EL:RegisterEvent("SUPER_TRACKING_CHANGED")
EL:RegisterEvent("PLAYER_ENTERING_WORLD")
EL:RegisterEvent("ZONE_CHANGED")
EL:RegisterEvent("ZONE_CHANGED_INDOORS")
EL:RegisterEvent("ZONE_CHANGED_NEW_AREA")
EL:SetScript("OnEvent", function(self, event)
    if event == "USER_WAYPOINT_UPDATED" or event == "SUPER_TRACKING_CHANGED" then
        if event == "SUPER_TRACKING_CHANGED" then
            MapPin.SyncUserNavigationSuperTracking(HasActivePathfinding)
        end
        UpdateWaypointLocationPinVisibility()
        RefreshUserNavigationPins()
        RefreshPathStepWaypointPins()
    else
        RefreshVisiblePins(true)
    end
end)

CallbackRegistry.Add("Preload.AddonReady", function()
    WUIMapPinFrame = BuildMapPinFrame("WUIMapPinFrame", MapPinFrame_Preload.Enum.MapPinType.UserNavigation, MapPinFrame_Preload.Enum.DisplayLayer.WorldMap)
    WUIMinimapPinFrame = BuildMapPinFrame("WUIMinimapPinFrame", MapPinFrame_Preload.Enum.MapPinType.UserNavigation, MapPinFrame_Preload.Enum.DisplayLayer.Minimap)
    WUIPathStepWaypointFrame = BuildMapPinFrame("WUIPathStepWaypointFrame", MapPinFrame_Preload.Enum.MapPinType.PathStepWaypoint, MapPinFrame_Preload.Enum.DisplayLayer.WorldMap)
    WUIPathStepWaypointMinimapFrame = BuildMapPinFrame("WUIPathStepWaypointMinimapFrame", MapPinFrame_Preload.Enum.MapPinType.PathStepWaypoint, MapPinFrame_Preload.Enum.DisplayLayer.Minimap)
    RefreshStoredPins()
    RefreshUserNavigationPins()
    RefreshPathStepWaypointPins()
    UpdateWaypointLocationPinVisibility()
end)

CallbackRegistry.Add("Preload.DatabaseReady", function()
    DBGlobal = Config.DBGlobal
    RefreshVisiblePins()
end)
