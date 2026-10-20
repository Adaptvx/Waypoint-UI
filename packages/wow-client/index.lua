local env = select(2, ...)
local WoWClient_Versioning = env.modules:Import("packages\\wow-client\\versioning")
local WoWClient = env.modules:New("packages\\wow-client")

WoWClient.IS_RETAIL = WoWClient_Versioning.IS_RETAIL
WoWClient.IS_FOREVER = WoWClient_Versioning.IS_FOREVER
WoWClient.IS_CLASSIC_ERA = WoWClient_Versioning.IS_CLASSIC_ERA
WoWClient.IS_CLASSIC_TBC = WoWClient_Versioning.IS_CLASSIC_TBC
WoWClient.IS_CLASSIC_MISTS = WoWClient_Versioning.IS_CLASSIC_MISTS
WoWClient.IS_CLASSIC_ALL = WoWClient_Versioning.IS_CLASSIC_ALL

