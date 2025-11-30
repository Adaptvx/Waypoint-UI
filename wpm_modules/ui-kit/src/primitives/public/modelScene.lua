-- [TODO]

local env          = select(2, ...)
local MixinUtil    = env.WPM:Import("wpm_modules/mixin-util")
local Frame        = env.WPM:Import("wpm_modules/ui-kit/primitives/frame")

local Mixin        = MixinUtil.Mixin

local ModelScene = env.WPM:New("wpm_modules/ui-kit/primitives/modelScene")



local dummy = CreateFrame("ModelScene"); dummy:Hide()



local ModelSceneMixin = {}
do

end




function ModelScene:New(name, parent)
    name = name or "undefined"


    local modelScene = Frame:New("ModelScene", name, parent)
    Mixin(modelScene, ModelSceneMixin)


    return modelScene
end
