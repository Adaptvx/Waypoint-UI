local env                    = select(2, ...)

local type                   = type
local pairs                  = pairs

local CallbackRegistry       = env.WPM:Import("wpm_modules\\callback-registry")
local SavedVariables_Enum    = env.WPM:Import("wpm_modules\\saved-variables\\enum")
local SavedVariables_Handler = env.WPM:New("wpm_modules\\saved-variables\\handler")


-- Shared
----------------------------------------------------------------------------------------------------

local registeredDatabases = {}


-- Helpers
----------------------------------------------------------------------------------------------------

local function ResolveNestedPath(rootTable, pathKeys)
    local current = rootTable
    for i = 1, #pathKeys do
        if current == nil then return nil end
        current = current[pathKeys[i]]
    end
    return current
end

local function SetVariable(self, key, value)
    local storedData = _G[self.databaseName]
    if type(value) ~= "table" and storedData[key] == value then return end

    storedData[key] = value
    CallbackRegistry.Trigger(self.callbackPrefix .. key, value)
end

local function GetVariable(self, key)
    local storedValue = _G[self.databaseName][key]
    if storedValue ~= nil then return storedValue end
    return self.defaultValues[key]
end

local function ResetVariable(self, key)
    local defaultValue = self.defaultValues[key]
    _G[self.databaseName][key] = defaultValue
    CallbackRegistry.Trigger(self.callbackPrefix .. key, defaultValue)
end

local function WipeDatabase(self)
    _G[self.databaseName] = {}
end

local function SetDefaults(self, defaultsTable)
    self.defaultValues = defaultsTable
    return self
end

local function Migrate(self, migrationSchema)
    local storedData = _G[self.databaseName]
    if not storedData or type(migrationSchema) ~= "table" then return self end

    for i = 1, #migrationSchema do
        local migration = migrationSchema[i]
        local migrationType = migration.migrationType

        local sourceIsPath = type(migration.from) == "table"
        local destinationIsPath = type(migration.to) == "table"

        local sourceValue = sourceIsPath and ResolveNestedPath(storedData, migration.from) or storedData[migration.from]
        local destinationKey = destinationIsPath and ResolveNestedPath(storedData, migration.to) or migration.to

        if migrationType == "directory" and sourceValue and destinationKey then
            local targetTable
            if not destinationIsPath and migration.to == SavedVariables_Enum.Root then
                targetTable = storedData
            elseif destinationIsPath then
                targetTable = destinationKey
            else
                targetTable = storedData[migration.to]
            end

            if targetTable then
                for sourceKey, sourceVal in pairs(sourceValue) do
                    if targetTable[sourceKey] == nil then
                        targetTable[sourceKey] = sourceVal
                        sourceValue[sourceKey] = nil
                    end
                end
            end
        elseif migrationType == "variable" and sourceValue and destinationKey and storedData[destinationKey] == nil then
            storedData[destinationKey] = sourceValue
            storedData[migration.from] = nil
        elseif migrationType == "delete" and destinationKey then
            storedData[destinationKey] = nil
        end
    end
    return self
end


-- API
----------------------------------------------------------------------------------------------------

local databaseMetatable = {
    __index = function(self, key)
        if key == "defaults" then
            return function(defaultsTable)
                return SetDefaults(self, defaultsTable)
            end
        elseif key == "migrationPlan" then
            return function(migrationSchema)
                return Migrate(self, migrationSchema)
            end
        end
    end
}

function SavedVariables_Handler.RegisterDatabase(databaseName)
    if not _G[databaseName] then _G[databaseName] = {} end

    local callbackPrefix = "SavedVariables." .. databaseName .. "."
    local databaseEntry = {
        SetVariable    = SetVariable,
        GetVariable    = GetVariable,
        ResetVariable  = ResetVariable,
        Wipe           = WipeDatabase,
        databaseName   = databaseName,
        defaultValues  = {},
        callbackPrefix = callbackPrefix
    }
    setmetatable(databaseEntry, databaseMetatable)

    registeredDatabases[databaseName] = databaseEntry
    return databaseEntry
end

function SavedVariables_Handler.RemoveDatabase(databaseName)
    registeredDatabases[databaseName] = nil
end

function SavedVariables_Handler.GetDatabase(databaseName)
    return registeredDatabases[databaseName]
end

function SavedVariables_Handler.OnChange(databaseName, variableName, callbackFunction)
    CallbackRegistry.Add("SavedVariables." .. databaseName .. "." .. variableName, callbackFunction)
end
