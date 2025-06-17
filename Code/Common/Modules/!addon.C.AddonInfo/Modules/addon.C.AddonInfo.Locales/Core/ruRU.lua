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
		L["Config - General"] = "Общие"
		L["Config - General - Title"] = "Общие"
		L["Config - General - Title - Subtext"] = "Настройте общие параметры."
		L["Config - General - Preferences"] = "Предпочтения"
		L["Config - General - Preferences - Meter"] = "Используйте метры вместо ярдов"
		L["Config - General - Preferences - Meter - Description"] = "Изменяет единицу измерения на метрическую."
		L["Config - General - Reset"] = "Сбросить"
		L["Config - General - Reset - Button"] = "Сброс по умолчанию"
		L["Config - General - Reset - Confirm"] = "Вы уверены, что хотите сбросить все настройки?"
		L["Config - General - Reset - Confirm - Yes"] = "Подтвердить"
		L["Config - General - Reset - Confirm - No"] = "Отмена"

		L["Config - WaypointSystem"] = "Точка маршрута"
		L["Config - WaypointSystem - Title"] = "Точка маршрута"
		L["Config - WaypointSystem - Title - Subtext"] = "Управлять поведением маркера внутри мира и значка цели внутри мира."
		L["Config - WaypointSystem - Type"] = "Включить"
		L["Config - WaypointSystem - Type - Both"] = "ВСЕ"
		L["Config - WaypointSystem - Type - Waypoint"] = "Точка маршрута"
		L["Config - WaypointSystem - Type - Pinpoint"] = "Точка привязки"
		L["Config - WaypointSystem - General"] = "Общие"
		L["Config - WaypointSystem - General - Transition Distance"] = "Точное расстояние"
		L["Config - WaypointSystem - General - Transition Distance - Description"] = "Показано максимальное расстояние до точечного обнаружения."
		L["Config - WaypointSystem - General - Hide Distance"] = "Минимальное расстояние"
		L["Config - WaypointSystem - General - Hide Distance - Description"] = "Расстояние до точки маршрута/точке привязки скрыто."
		L["Config - WaypointSystem - Waypoint"] = "Точка маршрута"
		L["Config - WaypointSystem - WaypointFooterType"] = "Дополнительная информация"
		L["Config - WaypointSystem - WaypointFooterType - Both"] = "Все"
		L["Config - WaypointSystem - WaypointFooterType - Distance"] = "Расстояние"
		L["Config - WaypointSystem - WaypointFooterType - ETA"] = "Время прибытия"
		L["Config - WaypointSystem - WaypointFooterType - None"] = "Нет"
		L["Config - WaypointSystem - WaypointFooterOpacity"] = "Прозрачность"
		L["Config - WaypointSystem - WaypointScale"] = "Размер точки маршрута"
		L["Config - WaypointSystem - WaypointScale - Description"] = "Размер точки маршрута меняется в зависимости от расстояния. Эта опция задает общий размер."
		L["Config - WaypointSystem - WaypointMinScale"] = "Минимум %"
		L["Config - WaypointSystem - WaypointMinScale - Description"] = "Минимальный % размер, до которого можно уменьшить."
		L["Config - WaypointSystem - WaypointMaxScale"] = "Максимум %"
		L["Config - WaypointSystem - WaypointMaxScale - Description"] = "Максимальный % размер, до которого можно увеличить."
		L["Config - WaypointSystem - Pinpoint"] = "Точка привязки"
		L["Config - WaypointSystem - PinpointScale"] = "Размер точки привязки"
		L["Config - WaypointSystem - PinpointDetail"] = "Показать расширенную информацию"
		L["Config - WaypointSystem - PinpointDetail - Description"] = "Включите дополнительную информацию, например, имя/описание."

		L["Config - Appearance"] = "Появление"
		L["Config - Appearance - Title"] = "Появление"
		L["Config - Appearance - Title - Subtext"] = "Настройте внешний вид пользовательского интерфейса."

		L["Config - Audio"] = "Аудио"
		L["Config - Audio - Title"] = "Аудио"
		L["Config - Audio - Title - Subtext"] = "Конфигурация звуковых эффектов интерфейса точки маршрута."
		L["Config - Audio - General"] = "Общие"
		L["Config - Audio - General - EnableGlobalAudio"] = "Включить аудио"

		L["Config - About"] = "О"
		L["Config - About - Contributors"] = "Участники"
		L["Config - About - Developer"] = "Разработчик"
	end

	--------------------------------
	-- CONTRIBUTORS
	--------------------------------

	do
		L["Contributors - ZamestoTV - Description"] = "Переводчик — на русский язык"
		L["Contributors - huchang47 - Description"] = "Переводчик — на китайский (упрощенный) язык"
		L["Contributors - BlueNightSky - Description"] = "Переводчик — на китайский (традиционный) язык"
		L["Contributors - Crazyyoungs - Description"] = "Translator — Korean"
		L["Contributors - y45853160 - Description"] = "Код — Исправление ошибок в бета-версии"
	end
end

NS:Load()
