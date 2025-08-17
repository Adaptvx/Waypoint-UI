---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.esES = {}
local NS = L.esES; L.esES = NS

--------------------------------

function NS:Load()
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
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "Listo para Entregar"
	end

	--------------------------------
	-- SLASH COMMAND
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "ID del Mapa Actual: "
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
		L["Config - General"] = "General"
		L["Config - General - Title"] = "General"
		L["Config - General - Title - Subtext"] = "Personalizar configuración general."
		L["Config - General - Preferences"] = "Preferencias"
		L["Config - General - Preferences - Meter"] = "Usar Metros en lugar de Yardas"
		L["Config - General - Preferences - Meter - Description"] = "Cambia la unidad de medida a Métrica."
		L["Config - General - Preferences - Font"] = "Fuente"
		L["Config - General - Preferences - Font - Description"] = "La fuente utilizada en todo el complemento."
		L["Config - General - Reset"] = "Restablecer"
		L["Config - General - Reset - Button"] = "Restablecer a Predeterminado"
		L["Config - General - Reset - Confirm"] = "¿Estás seguro de que quieres restablecer toda la configuración?"
		L["Config - General - Reset - Confirm - Yes"] = "Confirmar"
		L["Config - General - Reset - Confirm - No"] = "Cancelar"

		L["Config - WaypointSystem"] = "Punto de Ruta"
		L["Config - WaypointSystem - Title"] = "Punto de Ruta"
		L["Config - WaypointSystem - Title - Subtext"] = "Opciones para configurar el comportamiento del sistema de puntos de ruta."
		L["Config - WaypointSystem - Type"] = "Habilitar"
		L["Config - WaypointSystem - Type - Both"] = "Todo"
		L["Config - WaypointSystem - Type - Waypoint"] = "Punto de Ruta"
		L["Config - WaypointSystem - Type - Pinpoint"] = "Punto Preciso"
		L["Config - WaypointSystem - General"] = "General"
		L["Config - WaypointSystem - General - RightClickToClear"] = "Clic Derecho para Limpiar"
		L["Config - WaypointSystem - General - RightClickToClear - Description"] = "Deja de rastrear el objetivo actual haciendo clic derecho en los marcos de navegación."
		L["Config - WaypointSystem - General - BackgroundPreview"] = "Vista Previa de Fondo"
		L["Config - WaypointSystem - General - BackgroundPreview - Description"] = "Reduce la visibilidad del marco de navegación cuando el ratón está sobre él."
		L["Config - WaypointSystem - General - Transition Distance"] = "Distancia del Punto Preciso"
		L["Config - WaypointSystem - General - Transition Distance - Description"] = "Distancia antes de mostrar el Punto Preciso."
		L["Config - WaypointSystem - General - Hide Distance"] = "Distancia Mínima"
		L["Config - WaypointSystem - General - Hide Distance - Description"] = "Distancia antes de ocultar."
		L["Config - WaypointSystem - Waypoint"] = "Punto de Ruta"
		L["Config - WaypointSystem - Waypoint - Footer - Type"] = "Información Adicional"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Both"] = "Todo"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Distance"] = "Distancia"
		L["Config - WaypointSystem - Waypoint - Footer - Type - ETA"] = "Tiempo de Llegada"
		L["Config - WaypointSystem - Waypoint - Footer - Type - None"] = "Ninguno"
		L["Config - WaypointSystem - Pinpoint"] = "Punto Preciso"
		L["Config - WaypointSystem - Pinpoint - Info"] = "Mostrar Información"
		L["Config - WaypointSystem - Pinpoint - Info - Extended"] = "Usar Información Extendida"
		L["Config - WaypointSystem - Pinpoint - Info - Extended - Description"] = "Como nombre y descripción."
		L["Config - WaypointSystem - Navigator"] = "Navegador"
		L["Config - WaypointSystem - Navigator - Enable"] = "Mostrar"
		L["Config - WaypointSystem - Navigator - Enable - Description"] = "Cuando el Punto de Ruta o Punto Preciso está fuera de pantalla, el navegador apuntará en la dirección."

		L["Config - Appearance"] = "Apariencia"
		L["Config - Appearance - Title"] = "Apariencia"
		L["Config - Appearance - Title - Subtext"] = "Personalizar la apariencia de la interfaz de usuario."
		L["Config - Appearance - Waypoint"] = "Punto de Ruta"
		L["Config - Appearance - Waypoint - Scale"] = "Tamaño"
		L["Config - Appearance - Waypoint - Scale - Description"] = "El tamaño cambia según la distancia. Esta opción establece el tamaño general."
		L["Config - Appearance - Waypoint - Scale - Min"] = "Mínimo %"
		L["Config - Appearance - Waypoint - Scale - Min - Description"] = "El tamaño puede reducirse hasta."
		L["Config - Appearance - Waypoint - Scale - Max"] = "Máximo %"
		L["Config - Appearance - Waypoint - Scale - Max - Description"] = "El tamaño puede agrandarse hasta."
		L["Config - Appearance - Waypoint - Beam"] = "Mostrar Haz"
		L["Config - Appearance - Waypoint - Beam - Alpha"] = "Transparencia"
		L["Config - Appearance - Waypoint - Footer"] = "Mostrar Texto de Información"
		L["Config - Appearance - Waypoint - Footer - Scale"] = "Tamaño"
		L["Config - Appearance - Waypoint - Footer - Alpha"] = "Transparencia"
		L["Config - Appearance - Pinpoint"] = "Punto Preciso"
		L["Config - Appearance - Pinpoint - Scale"] = "Tamaño"
		L["Config - Appearance - Navigator"] = "Navegador"
		L["Config - Appearance - Navigator - Scale"] = "Tamaño"
		L["Config - Appearance - Navigator - Alpha"] = "Transparencia"
		L['Config - Appearance - Navigator - Distance'] = "Distancia"
		L["Config - Appearance - Visual"] = "Visual"
		L["Config - Appearance - Visual - UseCustomColor"] = "Usar Color Personalizado"
		L["Config - Appearance - Visual - UseCustomColor - Color"] = "Color"
		L["Config - Appearance - Visual - UseCustomColor - TintIcon"] = "Teñir Icono"
		L["Config - Appearance - Visual - UseCustomColor - Reset"] = "Restablecer"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Default"] = "Misión Normal"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Repeatable"] = "Misión Repetible"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Important"] = "Misión Importante"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Incomplete"] = "Misión Incompleta"
		L["Config - Appearance - Visual - UseCustomColor - Neutral"] = "Punto de Ruta Genérico"

		L["Config - Audio"] = "Audio"
		L["Config - Audio - Title"] = "Audio"
		L["Config - Audio - Title - Subtext"] = "Configuración para efectos de sonido del complemento."
		L["Config - Audio - General"] = "General"
		L["Config - Audio - General - EnableGlobalAudio"] = "Habilitar Audio"
		L["Config - Audio - Customize"] = "Personalizar"
		L["Config - Audio - Customize - UseCustomAudio"] = "Usar Audio Personalizado"
		L["Config - Audio - Customize - UseCustomAudio - Sound ID"] = "ID de Sonido"
		L["Config - Audio - Customize - UseCustomAudio - Sound ID - Placeholder"] = "ID Personalizado"
		L["Config - Audio - Customize - UseCustomAudio - Preview"] = "Vista Previa"
		L["Config - Audio - Customize - UseCustomAudio - Reset"] = "Restablecer"
		L["Config - Audio - Customize - UseCustomAudio - WaypointShow"] = "Mostrar Punto de Ruta"
		L["Config - Audio - Customize - UseCustomAudio - PinpointShow"] = "Mostrar Punto Preciso"

		L["Config - About"] = "Acerca de"
		L["Config - About - Contributors"] = "Colaboradores"
		L["Config - About - Developer"] = "Desarrollador"
		L["Config - About - Developer - AdaptiveX"] = "AdaptiveX"
	end

	--------------------------------
	-- CONTRIBUTORS
	--------------------------------

	do
		L["Contributors - ZamestoTV"] = "ZamestoTV"
		L["Contributors - ZamestoTV - Description"] = "Traductor — Ruso"
		L["Contributors - huchang47"] = "huchang47"
		L["Contributors - huchang47 - Description"] = "Traductor — Chino (Simplificado)"
		L["Contributors - BlueNightSky"] = "BlueNightSky"
		L["Contributors - BlueNightSky - Description"] = "Traductor — Chino (Tradicional)"
		L["Contributors - Crazyyoungs"] = "Crazyyoungs"
		L["Contributors - Crazyyoungs - Description"] = "Traductor — Coreano"
		L["Contributors - Klep"] = "Klep"
		L["Contributors - Klep - Description"] = "Traductor — Francés"
		L["Contributors - Kroffy"] = "Kroffy"
		L["Contributors - Kroffy - Description"] = "Traductor — Francés"
		L["Contributors - cathtail"] = "cathtail"
		L["Contributors - cathtail - Description"] = "Traductor - Portugués Brasileño"
		L["Contributors - Larsj02"] = "Larsj02"
		L["Contributors - Larsj02 - Description"] = "Traductor — Alemán"
		L["Contributors - dabear78"] = "dabear78"
		L["Contributors - dabear78 - Description"] = "Traductor - Alemán"
		L["Contributors - y45853160"] = "y45853160"
		L["Contributors - y45853160 - Description"] = "Código — Corrección de Bug Beta"
		L["Contributors - lemieszek"] = "lemieszek"
		L["Contributors - lemieszek - Description"] = "Código — Corrección de Bug Beta"
		L["Contributors - BadBoyBarny"] = "BadBoyBarny"
		L["Contributors - BadBoyBarny - Description"] = "Código — Corrección de Bug"
		L["Contributors - Christinxa"] = "Christinxa"
		L["Contributors - Christinxa - Description"] = "Código - Corrección de Bug"
		L["Contributors - HectorZaGa"] = "HectorZaGa"
		L["Contributors - HectorZaGa - Description"] = "Código - Corrección de Bug"
		L["Contributors - SyverGiswold"] = "SyverGiswold"
		L["Contributors - SyverGiswold - Description"] = "Código - Característica"
	end
end

NS:Load()
