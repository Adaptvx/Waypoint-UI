-- ♡ Translation // ZamestoTV (Hubbotu)
-- Переводчик ZamestoTV

---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.ruRU = {}
local NS = L.ruRU; L.ruRU = NS

--------------------------------

function NS:Load()
	if GetLocale() ~= "ruRU" then
		return
	end

	--------------------------------
	-- GENERAL
	--------------------------------

	do
		L["Distance - Prefix"] = ""
		L["Distance - Prefix - Singular"] = ""
		L["Distance - Suffix"] = " ярд"
		L["Distance - Suffix - Singular"] = " ярд"
	end

	--------------------------------
	-- WAYPOINT SYSTEM
	--------------------------------

	do
		-- PINPOINT
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "Готов к сдаче"
	end

	--------------------------------
	-- SLASH COMMAND
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "Текущий ID карты: "
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
		L["Config - Appearance"] = "Появление"
		L["Config - Appearance - Title"] = "Появление"
		L["Config - Appearance - Title - Subtext"] = "Настройте внешний вид пользовательского интерфейса."

		L["Config - Appearance - WaypointSystem - Type"] = "Включить"
		L["Config - Appearance - WaypointSystem - Type - Both"] = "ВСЕ"
		L["Config - Appearance - WaypointSystem - Type - Waypoint"] = "Точка маршрута"
		L["Config - Appearance - WaypointSystem - Type - Pinpoint"] = "Точка привязки"

		L["Config - Appearance - WaypointSystem - Waypoint"] = "Точка маршрута"
		L["Config - Appearance - WaypointSystem - WaypointScale"] = "Размер точки маршрута"

		L["Config - Appearance - WaypointSystem - Pinpoint"] = "Точка привязки"
		L["Config - Appearance - WaypointSystem - PinpointScale"] = "Размер точки привязки"
		L["Config - Appearance - WaypointSystem - PinpointDetail"] = "Показать расширенную информацию"
		L["Config - Appearance - WaypointSystem - PinpointDetail - Description"] = "Включите дополнительную информацию, например, имя/описание."
	end
end

NS:Load()
