local env                    = select(2, ...)

local IsOnQuest              = C_QuestLog.IsOnQuest
local IsReadyForTurnIn       = C_QuestLog.ReadyForTurnIn
local IsQuestRepeatable      = C_QuestLog.IsRepeatableQuest
local GetQuestClassification = C_QuestInfoSystem.GetQuestClassification
local GetQuestType           = C_QuestLog.GetQuestType

local Path                   = env.WPM:Import("wpm_modules/path")
local Utils_InlineIcon            = env.WPM:Import("wpm_modules/utils/inlineIcon")
local WaypointContextIcon    = env.WPM:New("@/Waypoint/ContextIcon")

local PATH                   = Path.Root .. "/Art/ContextIcon/"



-- Helper
--------------------------------

function WaypointContextIcon:ConvertToInlineIcon(name, isTexture)
    local iconPath = isTexture and name or (PATH .. name .. ".png")
    return Utils_InlineIcon:InlineIcon(iconPath, 16, 16, 0, 0)
end

function WaypointContextIcon:GetQuestInfo(questID)
    local results             = {}

    local questClassification = GetQuestClassification(questID)
    local questType           = GetQuestType(questID)

    local questAvailable      = (QuestFrameAcceptButton:IsVisible())
    local questCompleted      = (IsReadyForTurnIn(questID)) and not questAvailable
    local questActive         = (IsOnQuest(questID) and not questAvailable)

    local questTypeDefault    = (questClassification == Enum.QuestClassification.Normal)
    local questTypeImportant  = (questClassification == Enum.QuestClassification.Important)
    local questTypeCampaign   = (questClassification == Enum.QuestClassification.Campaign)
    local questTypeCalling    = (questClassification == Enum.QuestClassification.Calling)
    local questTypeMeta       = (questClassification == Enum.QuestClassification.Meta)
    local questTypeRecurring  = (questClassification == Enum.QuestClassification.Recurring)
    local questTypeRepeatable = (IsQuestRepeatable(questID))

    local questTypeAccount    = (questType == Enum.QuestTag.Account)
    local questTypeCombatAlly = (questType == Enum.QuestTag.CombatAlly)
    local questTypeDelve      = (questType == Enum.QuestTag.Delve)
    local questTypeDungeon    = (questType == Enum.QuestTag.Dungeon)
    local questTypeGroup      = (questType == Enum.QuestTag.Group)
    local questTypeHeroic     = (questType == Enum.QuestTag.Heroic)
    local questTypeLegendary  = (questClassification == Enum.QuestClassification.Legendary or questType == Enum.QuestTag.Legendary)
    local questTypeArtifact   = (questType == 107)
    local questTypePvP        = (questType == Enum.QuestTag.PvP)
    local questTypeRaid       = (questType == Enum.QuestTag.Raid)
    local questTypeRaid10     = (questType == Enum.QuestTag.Raid10)
    local questTypeRaid25     = (questType == Enum.QuestTag.Raid25)
    local questTypeScenario   = (questType == Enum.QuestTag.Scenario)

    results                   = {
        questAvailable      = questAvailable,
        questCompleted      = questCompleted,
        questActive         = questActive,
        questTypeDefault    = questTypeDefault,
        questTypeImportant  = questTypeImportant,
        questTypeCampaign   = questTypeCampaign,
        questTypeCalling    = questTypeCalling,
        questTypeMeta       = questTypeMeta,
        questTypeRecurring  = questTypeRecurring,
        questTypeRepeatable = questTypeRepeatable,
        questTypeAccount    = questTypeAccount,
        questTypeCombatAlly = questTypeCombatAlly,
        questTypeDelve      = questTypeDelve,
        questTypeDungeon    = questTypeDungeon,
        questTypeGroup      = questTypeGroup,
        questTypeHeroic     = questTypeHeroic,
        questTypeLegendary  = questTypeLegendary,
        questTypeArtifact   = questTypeArtifact,
        questTypePvP        = questTypePvP,
        questTypeRaid       = questTypeRaid,
        questTypeRaid10     = questTypeRaid10,
        questTypeRaid25     = questTypeRaid25,
        questTypeScenario   = questTypeScenario
    }

    return results
end


local ICON_FILE_MAP = {
    { cond = function(data) return data.questTypeDefault end,    name = nil },
    { cond = function(data) return data.questTypeImportant end,  name = "Important" },
    { cond = function(data) return data.questTypeCampaign end,   name = "Campaign" },
    { cond = function(data) return data.questTypeLegendary end,  name = "Legendary" },
    { cond = function(data) return data.questTypeArtifact end,   name = "Artifact" },
    { cond = function(data) return data.questTypeCalling end,    name = "CampaignRecurring" },
    { cond = function(data) return data.questTypeMeta end,       name = "Meta" },
    { cond = function(data) return data.questTypeRecurring end,  name = "Recurring" },
    { cond = function(data) return data.questTypeRepeatable end, name = "Repeatable" }
}

function WaypointContextIcon:GetQuestIconFromInfo(data)
    local statusSuffix
    if data.questCompleted then
        statusSuffix = "Complete"
    elseif data.questActive then
        statusSuffix = "Incomplete"
    else
        statusSuffix = "Available"
    end

    for _, t in ipairs(ICON_FILE_MAP) do
        if t.cond(data) then
            if t.name then
                return ("Quest%s%s"):format(t.name, statusSuffix)
            else
                return ("Quest%s"):format(statusSuffix)
            end
        end
    end

    return nil
end


-- API
--------------------------------

-- Acquires a context icon from the provided `questID`
---@param questID number
---@return string inlineIcon
---@return string texturePath
function WaypointContextIcon:GetContextIcon(questID)
    assert(questID, "Invalid variable `questID`")
    local inlineIcon, texturePath

    local questInfo = WaypointContextIcon:GetQuestInfo(questID)
    local resultPath = WaypointContextIcon:GetQuestIconFromInfo({
        questCompleted      = questInfo.questCompleted,
        questActive         = questInfo.questActive,
        questTypeDefault    = questInfo.questTypeDefault,
        questTypeImportant  = questInfo.questTypeImportant,
        questTypeCampaign   = questInfo.questTypeCampaign,
        questTypeLegendary  = questInfo.questTypeLegendary,
        questTypeArtifact   = questInfo.questTypeArtifact,
        questTypeCalling    = questInfo.questTypeCalling,
        questTypeMeta       = questInfo.questTypeMeta,
        questTypeRecurring  = questInfo.questTypeRecurring,
        questTypeRepeatable = questInfo.questTypeRepeatable
    })

    if resultPath then
        inlineIcon = WaypointContextIcon:ConvertToInlineIcon(resultPath)
        texturePath = PATH .. resultPath .. ".png"
    end

    return inlineIcon, texturePath
end
