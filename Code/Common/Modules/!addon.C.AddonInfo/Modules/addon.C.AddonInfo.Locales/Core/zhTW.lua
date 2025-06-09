-- ♡ Translation // BlueNightSky

---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.zhTW = {}
local NS = L.zhTW; L.zhTW = NS

--------------------------------

function NS:Load()
	if GetLocale() ~= "zhTW" then
		return
	end

	--------------------------------
	-- GENERAL
	--------------------------------

	do
		L["Distance - Prefix"] = ""
		L["Distance - Prefix - Singular"] = ""
		L["Distance - Suffix"] = " 碼"
		L["Distance - Suffix - Singular"] = " 碼"
	end

	--------------------------------
	-- WAYPOINT SYSTEM
	--------------------------------

	do
		-- PINPOINT
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "可交付任務"
	end

	--------------------------------
	-- SLASH COMMAND
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "當前地圖ID: "
		L["SlashCommand - /way - Map ID - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (X) - Prefix"] = "X: "
		L["SlashCommand - /way - Position - Axis (X) - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (Y) - Prefix"] = ", Y: "
		L["SlashCommand - /way - Position - Axis (Y) - Suffix"] = ""
	end

	--------------------------------
	-- CONFIG
	--------------------------------

	do
		L["Config - Appearance"] = "外觀"
		L["Config - Appearance - Title"] = "外觀"
		L["Config - Appearance - Title - Subtext"] = "自定義用戶界面的外觀。"

		L["Config - Appearance - WaypointSystem - Type"] = "啟用"
		L["Config - Appearance - WaypointSystem - Type - Both"] = "所有"
		L["Config - Appearance - WaypointSystem - Type - Waypoint"] = "路徑點"
		L["Config - Appearance - WaypointSystem - Type - Pinpoint"] = "標記點"

		L["Config - Appearance - WaypointSystem - General"] = "一般"
		L["Config - Appearance - WaypointSystem - General - Transition Distance"] = "標記點距離"
		L["Config - Appearance - WaypointSystem - General - Transition Distance - Description"] = "標記點顯示的最大距離。"
		L["Config - Appearance - WaypointSystem - General - Hide Distance"] = "最小距離"
		L["Config - Appearance - WaypointSystem - General - Hide Distance - Description"] = "路徑點/標記點 隱藏的最小距離。"

		L["Config - Appearance - WaypointSystem - Waypoint"] = "路徑點"
		L["Config - Appearance - WaypointSystem - WaypointScale"] = "路徑點大小"
		L["Config - Appearance - WaypointSystem - WaypointScale - Description"] = "路徑點大小根據距離變化，此選項設置了整體尺寸。"
		L["Config - Appearance - WaypointSystem - WaypointMinScale"] = "最小 %"
		L["Config - Appearance - WaypointSystem - WaypointMinScale - Description"] = "可以減小到的最小 % 尺寸。"
		L["Config - Appearance - WaypointSystem - WaypointMaxScale"] = "最大 %"
		L["Config - Appearance - WaypointSystem - WaypointMaxScale - Description"] = "可以放大到的最大 % 尺寸。"

		L["Config - Appearance - WaypointSystem - Pinpoint"] = "標記點"
		L["Config - Appearance - WaypointSystem - PinpointScale"] = "標記點大小"
		L["Config - Appearance - WaypointSystem - PinpointDetail"] = "顯示額外訊息"
		L["Config - Appearance - WaypointSystem - PinpointDetail - Description"] = "包含額外的訊息，例如名稱/描述。"
	end
end

NS:Load()
