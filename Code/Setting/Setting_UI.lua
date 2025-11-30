local env                                                                                                                  = select(2, ...)
local Path                                                                                                                 = env.WPM:Import("wpm_modules/path")
local UIKit                                                                                                                = env.WPM:Import("wpm_modules/ui-kit")
local Frame, Grid, VStack, HStack, ScrollView, ScrollBar, Text, Input, LinearSlider, InteractiveRect, LazyScrollView, List = UIKit.UI.Frame, UIKit.UI.Grid, UIKit.UI.VStack, UIKit.UI.HStack, UIKit.UI.ScrollView, UIKit.UI.ScrollBar, UIKit.UI.Text, UIKit.UI.Input, UIKit.UI.LinearSlider, UIKit.UI.InteractiveRect, UIKit.UI.LazyScrollView, UIKit.UI.List
local UIAnim                                                                                                               = env.WPM:Import("wpm_modules/ui-anim")

local UICGame                                                                                                              = env.WPM:Import("wpm_modules/uic-game")


-- Shared
--------------------------------

local NAME = "WUISettingFrame"


-- Frame
--------------------------------

local TEXTURE_DIVIDER = UIKit.Define.Texture{ path = Path.Root .. "/Art/Shape/Square.png" }


Frame(NAME .. ".Frame", {
    Frame(NAME .. ".Sidebar", {
        Frame(NAME .. ".Sidebar.Divider")
            :id(NAME .. ".Sidebar.Divider")
            :point(UIKit.Enum.Point.Right)
            :size(UIKit.Define.Num{ value = 2 }, UIKit.Define.Percentage{ value = 100 })
            :background(TEXTURE_DIVIDER)
            :backgroundColor(UIKit.Define.Color_RGBA{ r = 142.5, g = 142.5, b = 142.5, a = .2375 }),

        Frame(NAME .. ".Sidebar.Content", {
            VStack(NAME .. ".Sidebar.Tab")
                :id(NAME .. ".Sidebar.Tab")
                :point(UIKit.Enum.Point.Top)
                :size(UIKit.Define.Percentage{ value = 100 }, UIKit.Define.Percentage{ value = 100, operator = "-", delta = 75 })
                :layoutSpacing(UIKit.Define.Num{ value = 3 }),

            VStack(NAME .. ".Sidebar.Footer")
                :id(NAME .. ".Sidebar.Footer")
                :point(UIKit.Enum.Point.Bottom)
                :size(UIKit.Define.Percentage{ value = 100 }, UIKit.Define.Num{ value = 75 })
                :layoutAlignmentV(UIKit.Enum.Direction.Trailing)
                :layoutSpacing(UIKit.Define.Num{ value = 3 })
        })
            :id(NAME .. ".Sidebar.Content")
            :size(UIKit.Define.Fill{ delta = 45 })
    })
        :id(NAME .. ".Sidebar")
        :point(UIKit.Enum.Point.Left)
        :size(UIKit.Define.Num{ value = 212 }, UIKit.Define.Percentage{ value = 100 }),

    Frame(NAME .. ".Content", {
        Frame(NAME .. ".Content.Container")
            :id(NAME .. ".Content.Container")
            :point(UIKit.Enum.Point.Center)
            :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = 35 }, UIKit.Define.Percentage{ value = 100 })
    })
        :id(NAME .. ".Content")
        :point(UIKit.Enum.Point.Right)
        :size(UIKit.Define.Percentage{ value = 100, operator = "-", delta = 212 }, UIKit.Define.Percentage{ value = 100 })
})
    :id(NAME)

WUISettingFrame = UIKit.GetElementById(NAME)
WUISettingFrame.Sidebar = UIKit.GetElementById(NAME .. ".Sidebar")
WUISettingFrame.Sidebar.Content = UIKit.GetElementById(NAME .. ".Sidebar.Content")
WUISettingFrame.Sidebar.Image = UIKit.GetElementById(NAME .. ".Sidebar.Image")
WUISettingFrame.Sidebar.Tab = UIKit.GetElementById(NAME .. ".Sidebar.Tab")
WUISettingFrame.Sidebar.Footer = UIKit.GetElementById(NAME .. ".Sidebar.Footer")
WUISettingFrame.Content = UIKit.GetElementById(NAME .. ".Content")
WUISettingFrame.Content.Container = UIKit.GetElementById(NAME .. ".Content.Container")



-- Selection Menu
--------------------------------

WUISettingFrame.SelectionMenu = UICGame.SelectionMenu(NAME .. ".SelectionMenu")
    :parent(WUISettingFrame)
    :frameStrata(UIKit.Enum.FrameStrata.FullscreenDialog)
    :size(UIKit.Define.Num{ value = 175 }, UIKit.Define.Fit{})
    :_Render()
