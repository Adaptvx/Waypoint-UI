-- ♡ Translation // Klep

---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.frFR = {}
local NS = L.frFR; L.frFR = NS

--------------------------------

function NS:Load()
	if GetLocale() ~= "frFR" then
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
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "Ready for Turn-in"
	end

	--------------------------------
	-- SLASH COMMAND
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "ID de la carte actuelle : "
		L["SlashCommand - /way - Map ID - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (X) - Prefix"] = "X : "
		L["SlashCommand - /way - Position - Axis (X) - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (Y) - Prefix"] = ", Y : "
		L["SlashCommand - /way - Position - Axis (Y) - Suffix"] = ""
	end

	--------------------------------
	-- CONFIG
	--------------------------------

	do
		L["Config - General"] = "Général"
		L["Config - General - Title"] = "Général"
		L["Config - General - Title - Subtext"] = "Personnaliser les paramètres généraux."
		L["Config - General - Preferences"] = "Préférences"
		L["Config - General - Preferences - Meter"] = "Utilisez des mètres au lieu de yards"
		L["Config - General - Preferences - Meter - Description"] = "Modifie l'unité de mesure en métrique."
		L["Config - General - Reset"] = "Réinitialiser"
		L["Config - General - Reset - Button"] = "Réinitialiser par défaut"
		L["Config - General - Reset - Confirm"] = "Êtes-vous sûr de vouloir réinitialiser tous les paramètres ?"
		L["Config - General - Reset - Confirm - Yes"] = "Confirmer"
		L["Config - General - Reset - Confirm - No"] = "Annuler"

		L["Config - WaypointSystem"] = "Point de passage"
		L["Config - WaypointSystem - Title"] = "Point de passage"
		L["Config - WaypointSystem - Title - Subtext"] = "Gérer le comportement des différents repères."
		L["Config - WaypointSystem - Type"] = "Activer"
		L["Config - WaypointSystem - Type - Both"] = "Tout"
		L["Config - WaypointSystem - Type - Waypoint"] = "Point de passage"
		L["Config - WaypointSystem - Type - Pinpoint"] = "Pinpoint"
		L["Config - WaypointSystem - General"] = "Général"
		L["Config - WaypointSystem - General - Transition Distance"] = "Pinpoint Distance"
		L["Config - WaypointSystem - General - Transition Distance - Description"] = "Distance before Pinpoint is shown."
		L["Config - WaypointSystem - General - Hide Distance"] = "Distance minimale"
		L["Config - WaypointSystem - General - Hide Distance - Description"] = "Distance avant de masquer."
		L["Config - WaypointSystem - Waypoint"] = "Point de passage"
		L["Config - WaypointSystem - Waypoint - Footer - Type"] = "Informations complémentaires"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Both"] = "Tout"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Distance"] = "Distance"
		L["Config - WaypointSystem - Waypoint - Footer - Type - ETA"] = "Heure d'arrivée"
		L["Config - WaypointSystem - Waypoint - Footer - Type - None"] = "Aucun"
		L["Config - WaypointSystem - Pinpoint"] = "Pinpoint"
		L["Config - WaypointSystem - Pinpoint - Info"] = "Show Info"
		L["Config - WaypointSystem - Pinpoint - Info - Extended"] = "Afficher les informations détaillées"
		L["Config - WaypointSystem - Pinpoint - Info - Extended - Description"] = "Comme le nom et la description."
		L["Config - WaypointSystem - Navigator"] = "Navigator"
		L["Config - WaypointSystem - Navigator - Enable"] = "Show"
		L["Config - WaypointSystem - Navigator - Enable - Description"] = "When the Waypoint or Pinpoint is off-screen, the navigator will point at the direction."

		L["Config - Appearance"] = "Apparence"
		L["Config - Appearance - Title"] = "Apparence"
		L["Config - Appearance - Title - Subtext"] = "Personnalisez l'apparence de l'interface utilisateur."
		L["Config - Appearance - Waypoint"] = "Point de passage"
		L["Config - Appearance - Waypoint - Scale"] = "Taille"
		L["Config - Appearance - Waypoint - Scale - Description"] = "La taille change en fonction de la distance. Cette option définit la taille globale."
		L["Config - Appearance - Waypoint - Scale - Min"] = "% Minimum"
		L["Config - Appearance - Waypoint - Scale - Min - Description"] = "La taille peut être réduite de"
		L["Config - Appearance - Waypoint - Scale - Max"] = "% Maximum"
		L["Config - Appearance - Waypoint - Scale - Max - Description"] = "La taille peut être agrandie de"
		L["Config - Appearance - Waypoint - Beam"] = "Afficher le faisceau"
		L["Config - Appearance - Waypoint - Beam - Alpha"] = "Transparence"
		L["Config - Appearance - Waypoint - Footer"] = "Show Info Text"
		L["Config - Appearance - Waypoint - Footer - Scale"] = "Size"
		L["Config - Appearance - Waypoint - Footer - Alpha"] = "Transparence du texte d'information"
		L["Config - Appearance - Pinpoint"] = "Pinpoint"
		L["Config - Appearance - Pinpoint - Scale"] = "Taille"
		L["Config - Appearance - Navigator"] = "Navigator"
		L["Config - Appearance - Navigator - Scale"] = "Size"
		L["Config - Appearance - Navigator - Alpha"] = "Transparency"
		L["Config - Appearance - Visual"] = "Visuel"
		L["Config - Appearance - Visual - UseCustomColor"] = "Utiliser une couleur personnalisée"
		L["Config - Appearance - Visual - UseCustomColor - Color"] = "Couleur"
		L["Config - Appearance - Visual - UseCustomColor - TintIcon"] = "Colorer l'icône"
		L["Config - Appearance - Visual - UseCustomColor - Reset"] = "Réinitialiser"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Default"] = "Quête normale"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Repeatable"] = "Quête répétable"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Important"] = "Quête importante"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Incomplete"] = "Quête incomplète"
		L["Config - Appearance - Visual - UseCustomColor - Neutral"] = "Point de passage générique"

		L["Config - Audio"] = "Audio"
		L["Config - Audio - Title"] = "Audio"
		L["Config - Audio - Title - Subtext"] = "Configuration des effets audio de l'interface utilisateur."
		L["Config - Audio - General"] = "Général"
		L["Config - Audio - General - EnableGlobalAudio"] = "Activer l'audio"
		L["Config - Audio - Customize"] = "Customize"
		L["Config - Audio - Customize - UseCustomAudio"] = "Use Custom Audio"
		L["Config - Audio - Customize - UseCustomAudio - Sound ID"] = "Sound ID"
		L["Config - Audio - Customize - UseCustomAudio - Sound ID - Placeholder"] = "Custom ID"
		L["Config - Audio - Customize - UseCustomAudio - Preview"] = "Preview"
		L["Config - Audio - Customize - UseCustomAudio - Reset"] = "Reset"
		L["Config - Audio - Customize - UseCustomAudio - WaypointShow"] = "Show Waypoint"
		L["Config - Audio - Customize - UseCustomAudio - PinpointShow"] = "Show Pinpoint"

		L["Config - About"] = "À propos"
		L["Config - About - Contributors"] = "Contributeurs"
		L["Config - About - Developer"] = "Développeur"
		L["Config - About - Developer - AdaptiveX"] = "AdaptiveX"
	end

	--------------------------------
	-- CONTRIBUTORS
	--------------------------------

	do
		L["Contributors - ZamestoTV"] = "ZamestoTV"
		L["Contributors - ZamestoTV - Description"] = "Translator — Russian"
		L["Contributors - huchang47"] = "huchang47"
		L["Contributors - huchang47 - Description"] = "Translator — Chinese (Simplified)"
		L["Contributors - BlueNightSky"] = "BlueNightSky"
		L["Contributors - BlueNightSky - Description"] = "Translator — Chinese (Traditional)"
		L["Contributors - Crazyyoungs"] = "Crazyyoungs"
		L["Contributors - Crazyyoungs - Description"] = "Translator — Korean"
		L["Contributors - Klep"] = "Klep"
		L["Contributors - Klep - Description"] = "Translator — Français"
		L["Contributors - y45853160"] = "y45853160"
		L["Contributors - y45853160 - Description"] = "Code — Beta Bug Fix"
		L["Contributors - lemieszek"] = "lemieszek"
		L["Contributors - lemieszek - Description"] = "Code — Beta Bug Fix"
	end
end

NS:Load()
