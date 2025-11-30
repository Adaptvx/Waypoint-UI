local env = select(2, ...)

local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemID = C_Container.GetContainerItemID
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetItemInfo = C_Item.GetItemInfo
local FindAuraByName = AuraUtil.FindAuraByName
local ColorPickerFrame = ColorPickerFrame
local StaticPopup_Show = StaticPopup_Show
local StaticPopup_Hide = StaticPopup_Hide

local Utils_Blizzard = env.WPM:New("wpm_modules/utils/blizzard")





-- Bags
--------------------------------

-- Searches the player"s inventory for the specified item by name.
---@param itemName string
---@return any: itemID
---@return any: itemLink
function Utils_Blizzard:FindItemInInventory(itemName)
    if not itemName then
        return nil, nil
    end

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemID = GetContainerItemID(bag, slot) or nil
            local itemLink = GetContainerItemLink(bag, slot) or nil

            if itemLink then
                local itemNameInBag = GetItemInfo(itemLink)
                if itemNameInBag and itemNameInBag:lower() == itemName:lower() then
                    return itemID, itemLink
                end
            end
        end
    end

    return nil
end




-- Auras
--------------------------------

-- Gets if the player is in shapeshift form by spell name.
---@returns boolean
function Utils_Blizzard:IsPlayerInShapeshiftForm()
    local auras = {
        "Cat Form", --Druid Cat Form
        "Bear Form", --Druid Bear Form
        "Travel Form", --Druid Travel Form
        "Moonkin Form", --Druid Moonkin Form
        "Aquatic Form", --Druid Aquatic Form
        "Treant Form", --Druid Treant Form
        "Mount Form" --Druid Mount Form
    }

    for k, v in ipairs(auras) do
        if FindAuraByName(v, "Player") then
            return true
        end
    end

    return false
end




-- Color Picker
-- Blizzard FrameXML — https://wowpedia.fandom.com/wiki/Using_the_ColorPickerFrame
--------------------------------

-- Shows Blizzard"s Color Picker frame.
---@param initialColor table
---@param callback function
---@param opacityCallback function
---@param confirmCallback function
---@param cancelCallback function
function Utils_Blizzard:ShowColorPicker(initialColor, callback, opacityCallback, confirmCallback, cancelCallback)
    ColorPickerFrame:SetupColorPickerAndShow(initialColor)
    ColorPickerFrame.opacity = initialColor.a

    ColorPickerFrame.func = callback
    ColorPickerFrame.opacityFunc = opacityCallback
    ColorPickerFrame.swatchFunc = confirmCallback
    ColorPickerFrame.cancelFunc = cancelCallback

    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

-- Hides Blizzard"s Color Picker frame.
function Utils_Blizzard:HideColorPicker()
    ColorPickerFrame:Hide()
end

function Utils_Blizzard:NewConfirmPopup(PopupInfo)
    assert(PopupInfo, "Invalid variable `PopupInfo`")
    assert(PopupInfo.id and PopupInfo.text and PopupInfo.button1Text and PopupInfo.button2Text and PopupInfo.acceptCallback and PopupInfo.cancelCallback and PopupInfo.hideOnEscape, "Invalid variable `PopupInfo`: Missing required fields")

    StaticPopupDialogs[PopupInfo.id] = {
        text           = PopupInfo.text,
        button1        = PopupInfo.button1Text,
        button2        = PopupInfo.button2Text,
        OnAccept       = PopupInfo.acceptCallback,
        OnCancel       = PopupInfo.cancelCallback,
        hideOnEscape   = PopupInfo.hideOnEscape,
        timeout        = PopupInfo.timeout or 0,
        preferredIndex = 3
    }
end

function Utils_Blizzard:ShowPopup(id, ...)
    StaticPopup_Show(id, ...)
end

function Utils_Blizzard:HidePopup(id)
    StaticPopup_Hide(id)
end
