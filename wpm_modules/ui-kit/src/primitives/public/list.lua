local env = select(2, ...)
local MixinUtil = env.WPM:Import("wpm_modules/mixin-util")
local Frame = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")

local Mixin = MixinUtil.Mixin
local tinsert = table.insert
local ipairs = ipairs

local List = env.WPM:New("wpm_modules/ui-kit/primitives/list")





local ListMixin = {}
do
    -- Init
    --------------------------------

    function ListMixin:Init()
        self.__elementPool = {}
        self.__data = nil
        self.__prefabConstructorFunc = nil
        self.__onElementUpdateFunc = nil
    end


    -- API
    --------------------------------

    function ListMixin:UpdateAllVisibleElements()
        if not self.__data then return end

        for index, value in ipairs(self.__data) do
            local element = self:GetElement(index)
            self.__onElementUpdateFunc(element, index, value)
        end
    end

    function ListMixin:SetPrefab(prefabConstructorFunc)
        self.__prefabConstructorFunc = prefabConstructorFunc
    end

    function ListMixin:SetOnElementUpdate(func)
        self.__onElementUpdateFunc = func
    end

    function ListMixin:SetData(data)
        self.__data = data
        self:RenderElements()
    end

    function ListMixin:GetData()
        return self.__data
    end


    -- Internal
    --------------------------------

    function ListMixin:HideElements()
        for k, v in ipairs(self.__elementPool) do
            v:Hide()
        end
    end

    function ListMixin:NewElement()
        assert(self.__prefabConstructorFunc, "No prefab constructor set!")
        local index = #self.__elementPool + 1
        local name = self:GetDebugName() .. ".Element" .. index
        local element = self.__prefabConstructorFunc(name)

        assert(self.uk_parent, "No parent set!")
        element:parent(self.uk_parent)
        element:_Render()

        tinsert(self.__elementPool, element)

        return element
    end

    function ListMixin:GetElement(index)
        local element = nil

        if #self.__elementPool < index then
            element = self:NewElement()
        else
            element = self.__elementPool[index]
        end

        return element
    end

    function ListMixin:RenderElements()
        self:HideElements()
        if not self.__data then return end

        for index, value in ipairs(self.__data) do
            local element = self:GetElement(index)
            element:Show()

            if self.__onElementUpdateFunc then
                self.__onElementUpdateFunc(element, index, value)
            end
        end
    end
end





function List:New(name, parent)
    name = name or "undefined"


    local frame = Frame:New("Frame", name, parent)
    Mixin(frame, ListMixin)
    frame:Init()


    return frame
end




--[[
    local BACKGROUND = UIKit.Define.Texture_NineSlice{ path = Path.Root .. "/wpm_modules/uic-game/resources/InputCaret.png", inset = 128, scale = 1 }

    local Element = UIKit.Prefab(function(id, name, children, ...)
        return
            Frame(name, {

            })
            :size(UIKit.Define.Percentage{ value = 100 }, UIKit.Define.Num{ value = 25 })
            :background(BACKGROUND)
            :backgroundColor(UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = .5 })
            :_Render()
    end)

    local function handleOnElementUpdate(element, index, value)
        element:alpha(index * .1)
    end

    Frame{
        VStack{
            List()
                :id("List")
                :poolPrefab(Element)
                :poolOnElementUpdate(handleOnElementUpdate)
        }
            :point(UIKit.Enum.Point.Center)
            :size(UIKit.Define.Percentage{value = 100}, UIKit.Define.Fit{})
            :background(BACKGROUND)
            :backgroundColor(UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = .5 })
            :layoutDirection(UIKit.Enum.Direction.Vertical)
            :layoutSpacing(UIKit.Define.Num{value = 7.5})
    }
        :id("Frame")
        :point(UIKit.Enum.Point.Center)
        :size(UIKit.Define.Num{ value = 325 }, UIKit.Define.Num{ value = 575 })
        :background(BACKGROUND)
        :backgroundColor(UIKit.Define.Color_RGBA{ r = 255, g = 255, b = 255, a = .5 })
        :_Render()

    local data = {
        "entry1",
        "entry2",
        "entry3",
        "entry4",
        "entry5",
        "entry6",
        "entry7",
        "entry8",
        "entry9",
        "entry10",
    }

    myFrame = UIKit.GetElementById("Frame")
    myList = UIKit.GetElementById("List")
    myList:SetData(data)
]]
