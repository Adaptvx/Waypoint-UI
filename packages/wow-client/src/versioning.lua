local env = select(2, ...)
local WoWClient_Versioning = env.modules:New("packages\\wow-client\\versioning")

local BUILD_NUMBER = select(4, GetBuildInfo())
WoWClient_Versioning.IS_RETAIL = BUILD_NUMBER >= 120000
WoWClient_Versioning.IS_CLASSIC_ERA = BUILD_NUMBER >= 10000 and BUILD_NUMBER < 20000
WoWClient_Versioning.IS_CLASSIC_TBC = BUILD_NUMBER >= 20000 and BUILD_NUMBER < 30000
WoWClient_Versioning.IS_CLASSIC_MISTS = BUILD_NUMBER >= 50000 and BUILD_NUMBER < 60000
WoWClient_Versioning.IS_CLASSIC_ALL = not WoWClient_Versioning.IS_RETAIL
