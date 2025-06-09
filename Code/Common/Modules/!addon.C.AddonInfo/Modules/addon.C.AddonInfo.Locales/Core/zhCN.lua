---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.zhCN = {}
local NS = L.zhCN; L.zhCN = NS

--------------------------------

function NS:Load()
	--------------------------------
	-- GENERAL
	--------------------------------

	do
		L["Distance - Prefix"] = ""
		L["Distance - Prefix - Singular"] = ""
		L["Distance - Suffix"] = " 码"
		L["Distance - Suffix - Singular"] = " 码"
	end

	--------------------------------
	-- WAYPOINT SYSTEM
	--------------------------------

	do
		-- PINPOINT
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "可交任务"
	end

	--------------------------------
	-- SLASH COMMAND
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "当前地图ID: "
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
		L["Config - Appearance"] = "外观"
		L["Config - Appearance - Title"] = "外观"
		L["Config - Appearance - Title - Subtext"] = "自定义用户界面的外观。"

		L["Config - Appearance - WaypointSystem - Type"] = "启用"
		L["Config - Appearance - WaypointSystem - Type - Both"] = "所有"
		L["Config - Appearance - WaypointSystem - Type - Waypoint"] = "路径点"
		L["Config - Appearance - WaypointSystem - Type - Pinpoint"] = "标记点"

		L["Config - Appearance - WaypointSystem - General"] = "通用"
		L["Config - Appearance - WaypointSystem - General - Transition Distance"] = "标记点距离"
		L["Config - Appearance - WaypointSystem - General - Transition Distance - Description"] = "标记点显示的最大距离。"
		L["Config - Appearance - WaypointSystem - General - Hide Distance"] = "最小距离"
		L["Config - Appearance - WaypointSystem - General - Hide Distance - Description"] = "超出距离后隐藏路径点和标记点。"

		L["Config - Appearance - WaypointSystem - Waypoint"] = "路径点"
		L["Config - Appearance - WaypointSystem - WaypointScale"] = "路径点大小"
		L["Config - Appearance - WaypointSystem - WaypointScale - Description"] = "路径点的大小会跟随距离变化。此选项用于调整整体大小。"
		L["Config - Appearance - WaypointSystem - WaypointMinScale"] = "最小%"
		L["Config - Appearance - WaypointSystem - WaypointMinScale - Description"] = "可缩小到的最小百分比。"
		L["Config - Appearance - WaypointSystem - WaypointMaxScale"] = "最大%"
		L["Config - Appearance - WaypointSystem - WaypointMaxScale - Description"] = "可放大到的最大百分比。"
		
		L["Config - Appearance - WaypointSystem - Pinpoint"] = "标记点"
		L["Config - Appearance - WaypointSystem - PinpointScale"] = "标记点大小"
		L["Config - Appearance - WaypointSystem - PinpointDetail"] = "显示扩展信息"
		L["Config - Appearance - WaypointSystem - PinpointDetail - Description"] = "包含额外的信息，例如名称/描述。"
	end
end

NS:Load()
