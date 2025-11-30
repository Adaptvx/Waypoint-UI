local env              = select(2, ...)

local type             = type
local find             = string.find
local tremove          = table.remove

local UIKit_TagManager = env.WPM:New("wpm_modules/ui-kit/tag-manager")
UIKit_TagManager.Id    = { Registry = {} }
UIKit_TagManager.Class = { Registry = {}, Lookup = {} }
UIKit_TagManager.Tag   = { Registry = {} }



-- Helper
--------------------------------

local function withGroup(value, groupID)
    return (value and groupID) and (value .. "_" .. groupID) or value
end



-- Group Capture String
--------------------------------

function UIKit_TagManager.NewGroupCaptureString(id, groupID)
    return tostring(id .. "$groupID" .. groupID)
end

function UIKit_TagManager.ReadGroupCaptureString(groupCaptureString)
    local id, groupID = string.match(groupCaptureString, "(.-)$groupID(.+)")
    return id, groupID
end

function UIKit_TagManager.IsGroupCaptureString(groupCaptureString)
    local isString = (type(groupCaptureString) == "string")
    local hasGroupIDString = (isString and find(groupCaptureString, "$groupID") ~= nil)

    return isString and hasGroupIDString
end



-- Id
--------------------------------

function UIKit_TagManager.Id.Add(frame, id, groupID)
    local registry = UIKit_TagManager.Id.Registry
    local normalizedId = withGroup(id, groupID)
    local previousId = frame.uk_tagManager_id

    if previousId == normalizedId then return end

    if previousId then
        registry[previousId] = nil
    end

    if normalizedId then
        registry[normalizedId] = frame
    end

    frame.uk_tagManager_id = normalizedId
end

function UIKit_TagManager.Id.Remove(id, groupID)
    local registry = UIKit_TagManager.Id.Registry
    local normalizedId = withGroup(id, groupID)
    if not normalizedId then return end

    local frame = registry[normalizedId]
    if frame then
        frame.uk_tagManager_id = nil
        registry[normalizedId] = nil
    end
end



-- Class
--------------------------------

local registry = UIKit_TagManager.Class.Registry
local lookup = UIKit_TagManager.Class.Lookup

local function parseClasses(class, groupID)
    if type(class) ~= "string" or class == "" then return nil, nil end

    class = withGroup(class, groupID)
    local classes = {}
    for singleClass in class:gmatch("%S+") do
        classes[#classes + 1] = singleClass
    end

    return #classes > 0 and class or nil, #classes > 0 and classes or nil
end

local function removeFromRegistries(frame, classes)
    for i = 1, #classes do
        local singleClass = classes[i]
        local classTable = registry[singleClass]
        local classLookup = lookup[singleClass]

        if classTable and classLookup then
            local index = classLookup[frame]
            if index then
                tremove(classTable, index)
                classLookup[frame] = nil

                -- Update indices for remaining elements
                for j = index, #classTable do
                    classLookup[classTable[j]] = j
                end

                if #classTable == 0 then
                    registry[singleClass] = nil
                    lookup[singleClass] = nil
                end
            end
        end
    end
end

function UIKit_TagManager.Class.Add(frame, class, groupID)
    local normalizedClass, classes = parseClasses(class, groupID)

    if frame.uk_tagManager_class == normalizedClass then return end

    if frame.uk_tagManager_classes then
        removeFromRegistries(frame, frame.uk_tagManager_classes)
    end

    if not classes then
        frame.uk_tagManager_class = nil
        frame.uk_tagManager_classes = nil
        return
    end

    frame.uk_tagManager_class = normalizedClass
    frame.uk_tagManager_classes = classes

    for i = 1, #classes do
        local singleClass = classes[i]

        local classTable = registry[singleClass]
        if not classTable then
            classTable = {}
            registry[singleClass] = classTable
        end

        local classLookup = lookup[singleClass]
        if not classLookup then
            classLookup = {}
            lookup[singleClass] = classLookup
        end

        if not classLookup[frame] then
            classTable[#classTable + 1] = frame
            classLookup[frame] = #classTable
        end
    end
end

function UIKit_TagManager.Class.Remove(frame, class, groupID)
    local _, classes = parseClasses(class, groupID)
    classes = classes or (frame and frame.uk_tagManager_classes)
    if not classes then return end

    removeFromRegistries(frame, classes)
    frame.uk_tagManager_class = nil
    frame.uk_tagManager_classes = nil
end



-- Get
--------------------------------

function UIKit_TagManager.GetElementById(id, groupID)
    return UIKit_TagManager.Id.Registry[withGroup(id, groupID)]
end

function UIKit_TagManager.GetElementsByClass(class, groupID)
    return UIKit_TagManager.Class.Registry[withGroup(class, groupID)] or {}
end



-- Clean up
--------------------------------

function UIKit_TagManager.CleanupFrame(frame)
    if not frame then return end

    if frame.uk_tagManager_id then
        UIKit_TagManager.Id.Remove(frame.uk_tagManager_id)
    end

    if frame.uk_tagManager_class then
        UIKit_TagManager.Class.Remove(frame, frame.uk_tagManager_class)
    end
end
