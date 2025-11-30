local env = select(2, ...)

local CreateFrame = CreateFrame

local Utils_Texture = env.WPM:New("wpm_modules/utils/texture")




-- Preload
--------------------------------

function Utils_Texture:PreloadAsset(path)
    CreateFrame("Frame"):CreateTexture():SetTexture(path)
end
