local env = select(2, ...)
local UIKit_Primitives_Frame = env.modules:Import("packages\\ui-kit\\primitives\\frame")
local UIKit_Utils = env.modules:Import("packages\\ui-kit\\utils")
local UIKit_Primitives_SecureButton = env.modules:New("packages\\ui-kit\\primitives\\secure-button")

local Mixin = Mixin
local tonumber = tonumber


local ACTION_VALUE_ATTRIBUTES = {
    item = "item",
    spell = "spell",
    macro = "macrotext",
}

local function NormalizeItemValue(item)
    if item == nil then return nil end

    local itemID = tonumber(item)
    if itemID then
        return "item:" .. itemID
    end

    return item
end

local function ApplyAction(frame)
    local actionType = frame.__secureActionType
    local actionValue = frame.__secureActionValue
    local actionValueAttribute = frame.__secureActionValueAttribute
    local previousValueAttribute = frame.__secureActionAppliedValueAttribute

    if previousValueAttribute and previousValueAttribute ~= actionValueAttribute then
        frame:SetAttribute(previousValueAttribute, nil)
    end

    if not actionType or actionValue == nil or not actionValueAttribute then
        if actionValueAttribute then
            frame:SetAttribute(actionValueAttribute, nil)
        end

        frame:SetAttribute("type", nil)
        frame.__secureActionAppliedValueAttribute = nil
        return
    end

    frame:SetAttribute("type", actionType)
    frame:SetAttribute(actionValueAttribute, actionValue)
    frame.__secureActionAppliedValueAttribute = actionValueAttribute
end


local SecureButtonMixin = {}

function SecureButtonMixin:SetAction(actionType, actionValue, actionValueAttribute)
    self.__secureActionType = actionType
    self.__secureActionValue = actionValue
    self.__secureActionValueAttribute = actionValueAttribute or ACTION_VALUE_ATTRIBUTES[actionType] or actionType

    UIKit_Utils:AwaitProtectedEvent(ApplyAction, self)
end

function SecureButtonMixin:SetActionItem(item)
    self:SetAction("item", NormalizeItemValue(item), ACTION_VALUE_ATTRIBUTES.item)
end

function SecureButtonMixin:SetActionSpell(spell)
    self:SetAction("spell", spell, ACTION_VALUE_ATTRIBUTES.spell)
end

function SecureButtonMixin:SetActionMacro(macroText)
    self:SetAction("macro", macroText, ACTION_VALUE_ATTRIBUTES.macro)
end

function SecureButtonMixin:ClearAction()
    self:SetAction(nil, nil, nil)
end


function UIKit_Primitives_SecureButton.New(name, parent)
    name = name or "undefined"

    local frame = UIKit_Primitives_Frame.New("Button", name, parent, "SecureActionButtonTemplate")
    Mixin(frame, SecureButtonMixin)

    return frame
end
