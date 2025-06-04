-- ♡ Translation // ZamestoTV (Hubbotu)

---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales
--Переводчик ZamestoTV
--------------------------------

L.ruRU = {}
local NS = L.ruRU; L.ruRU = NS

--------------------------------

function NS:Load()
	if GetLocale() ~= "ruRU" then
		return
		L["Pinpoint - Quest - Complete"] = "Готов к сдаче"
	end

	--------------------------------
	-- WAYPOINT SYSTEM
	--------------------------------

	do
		-- WAYPOINT
		L["WaypointSystem - Waypoint - Distance - Prefix"] = ""
		L["WaypointSystem - Waypoint - Distance - Suffix"] = " ярд"

		-- PINPOINT
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "Готов к сдаче"
	end

	--------------------------------
	-- CONFIG
	--------------------------------

	do
		L["Config - Appearance"] = "Появление"
		L["Config - Appearance - Title"] = "Появление"
		L["Config - Appearance - Title - Subtext"] = "Настройте внешний вид пользовательского интерфейса."
		L["Config - Appearance - WaypointSystem - Type"] = "Включить"
		L["Config - Appearance - WaypointSystem - Type - Both"] = "ВСЕ"
		L["Config - Appearance - WaypointSystem - Type - Waypoint"] = "Точка маршрута"
		L["Config - Appearance - WaypointSystem - Type - Pinpoint"] = "Точка привязки"
		L["Config - Appearance - WaypointSystem - Waypoint"] = "Точка маршрута"
		L["Config - Appearance - WaypointSystem - Pinpoint"] = "Точка привязки"
		L["Config - Appearance - WaypointSystem - WaypointScale"] = "Размер точки маршрута"
		L["Config - Appearance - WaypointSystem - PinpointScale"] = "Размер точки привязки"
		L["Config - Appearance - WaypointSystem - PinpointDetail"] = "Показать расширенную информацию"
		L["Config - Appearance - WaypointSystem - PinpointDetail - Description"] = "Включите дополнительную информацию, например, имя/описание."
	end
end

NS:Load()
