---@class addon
local addon = select(2, ...)
local CallbackRegistry = addon.C.CallbackRegistry.Script
local PrefabRegistry = addon.C.PrefabRegistry.Script
local L = addon.C.AddonInfo.Locales
local NS = addon.WaypointSystem; addon.WaypointSystem = NS

--------------------------------

NS.Script = {}

--------------------------------

function NS.Script:Load()
	--------------------------------
	-- REFERENCES
	--------------------------------

	local Frame = WaypointFrame.Waypoint
	local Frame_Waypoint = Frame.REF_WAYPOINT
	local Frame_Pinpoint = Frame.REF_PINPOINT
	local Frame_BlizzardWaypoint = SuperTrackedFrame
	local Callback = NS.Script; NS.Script = Callback

	--------------------------------
	-- FUNCTIONS (FRAME)
	--------------------------------

	do
		do -- WAYPOINT
			do -- SET
				function Frame_Waypoint:SetText(text, subtext)
					if text then
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_TEXT_FRAME:Show()
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_TEXT:SetText(text)
					else
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_TEXT_FRAME:Hide()
					end

					if subtext then
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME:ShowWithAnimation()
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT:SetText(subtext)
					else
						Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME:HideWithAnimation()
					end

					Frame.LGS_FOOTER()
				end

				function Frame_Waypoint:Context_SetOpacity(opacity)
					Frame.REF_WAYPOINT_CONTEXT:SetOpacity(opacity)
				end

				function Frame_Waypoint:Context_SetImage(image, opacity)
					Frame.REF_WAYPOINT_CONTEXT:SetInfo(image, opacity)
				end

				function Frame_Waypoint:Context_SetVFX(type, tintColor)
					if type == "Wave" then
						Frame.REF_WAYPOINT_CONTEXT_VFX_WAVE.Animation_Playback_Loop:Start()
						Frame.REF_WAYPOINT_CONTEXT_VFX_WAVE_BACKGROUND_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					else
						Frame.REF_WAYPOINT_CONTEXT_VFX_WAVE:Hide()
					end
				end

				--------------------------------

				function Frame_Waypoint:APP_SetTint(tintColor)
					Frame.REF_WAYPOINT_MARKER_PULSE:SetTint(tintColor)
					Frame.REF_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_WAYPOINT_FOOTER_LAYOUT_TEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
				end

				function Frame_Waypoint:APP_SetTextAlpha(alpha)
					Frame.REF_WAYPOINT_FOOTER:SetAlpha(alpha or .5)
				end

				function Frame_Waypoint:APP_Context_SetTint(tintColor)
					Frame.REF_WAYPOINT_CONTEXT:SetTint(tintColor)
				end

				function Frame_Waypoint:APP_Context_SetRecolor(recolor)
					if recolor then
						Frame.REF_WAYPOINT_CONTEXT:Recolor()
					else
						Frame.REF_WAYPOINT_CONTEXT:Decolor()
					end
				end

				function Frame_Waypoint:APP_Beam_Set(visible, opacity)
					Frame.REF_WAYPOINT_MARKER_CONTENT:SetShown(visible)
					Frame.REF_WAYPOINT_MARKER_CONTENT:SetAlpha(opacity)
				end

				function Frame_Waypoint:APP_SetScale(scale)
					Frame.REF_WAYPOINT:SetScale(scale)
				end
			end
		end

		do -- PINPOINT
			do -- SET
				function Frame_Pinpoint:SetText(text)
					if text and text ~= Frame.REF_PINPOINT_FOREGROUND_TEXT:GetText() then
						Frame.REF_PINPOINT_FOREGROUND_TEXT:SetText(text)
					end

					--------------------------------

					Frame.REF_PINPOINT_FOREGROUND:SetShown(text ~= nil)
				end

				function Frame_Pinpoint:Context_SetOpacity(opacity)
					Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetOpacity(opacity)
				end

				function Frame_Pinpoint:Context_SetImage(image, opacity)
					Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetInfo(image, opacity)
				end

				--------------------------------

				function Frame_Pinpoint:APP_SetTint(tintColor)
					Frame.REF_PINPOINT_BACKGROUND_ARROW:SetTint(tintColor)
					Frame.REF_PINPOINT_FOREGROUND_BACKGROUND_BORDER_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_PINPOINT_FOREGROUND_TEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
				end

				function Frame_Pinpoint:APP_Context_SetTint(tintColor)
					Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetTint(tintColor)
				end

				function Frame_Pinpoint:APP_Context_SetRecolor(recolor)
					if recolor then
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:Recolor()
					else
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:Decolor()
					end
				end

				function Frame_Pinpoint:APP_SetScale(scale)
					Frame_Pinpoint:SetScale(scale)
				end
			end
		end
	end

	--------------------------------
	-- FUNCTIONS (MAIN)
	--------------------------------

	do
		local IS_WAYPOINT = false
		local IS_PINPOINT = false

		local C_WS_TYPE
		local C_WS_WAYPOINT_SCALE
		local C_WS_WAYPOINT_MIN_SCALE
		local C_WS_WAYPOINT_MAX_SCALE
		local C_WS_PINPOINT_SCALE
		local C_WS_PINPOINT_DETAIL
		local C_WS_DISTANCE_TEXT_TYPE
		local C_WS_DISTANCE_TEXT_ALPHA
		local C_APP_WAYPOINT_BEAM
		local C_APP_WAYPOINT_BEAM_ALPHA
		local C_APP_COLOR
		local C_APP_COLOR_QUEST_INCOMPLETE_TINT
		local C_APP_COLOR_QUEST_COMPLETE_TINT
		local C_APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT
		local C_APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT
		local C_APP_COLOR_NEUTRAL_TINT
		local C_APP_COLOR_QUEST_INCOMPLETE
		local C_APP_COLOR_QUEST_COMPLETE
		local C_APP_COLOR_QUEST_COMPLETE_REPEATABLE
		local C_APP_COLOR_QUEST_COMPLETE_IMPORTANT
		local C_APP_COLOR_NEUTRAL
		local C_PREF_METRIC
		local CVAR_FOV

		local function UpdateReferences()
			C_WS_TYPE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_TYPE
			C_WS_WAYPOINT_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_WAYPOINT_SCALE
			C_WS_WAYPOINT_MIN_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_WAYPOINT_MIN_SCALE
			C_WS_WAYPOINT_MAX_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_WAYPOINT_MAX_SCALE
			C_WS_DISTANCE_TEXT_TYPE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_TEXT_TYPE
			C_WS_DISTANCE_TEXT_ALPHA = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_TEXT_ALPHA
			C_WS_PINPOINT_DETAIL = addon.C.Database.Variables.DB_GLOBAL.profile.WS_PINPOINT_DETAIL
			C_WS_PINPOINT_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_PINPOINT_SCALE
			C_APP_WAYPOINT_BEAM = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_BEAM
			C_APP_WAYPOINT_BEAM_ALPHA = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_BEAM_ALPHA
			C_APP_COLOR = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR
			C_APP_COLOR_QUEST_INCOMPLETE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_INCOMPLETE_TINT
			C_APP_COLOR_QUEST_INCOMPLETE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_INCOMPLETE
			C_APP_COLOR_QUEST_COMPLETE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_TINT
			C_APP_COLOR_QUEST_COMPLETE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE
			C_APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT
			C_APP_COLOR_QUEST_COMPLETE_REPEATABLE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_REPEATABLE
			C_APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT
			C_APP_COLOR_QUEST_COMPLETE_IMPORTANT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_IMPORTANT
			C_APP_COLOR_NEUTRAL_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_NEUTRAL_TINT
			C_APP_COLOR_NEUTRAL = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_NEUTRAL
			C_PREF_METRIC = addon.C.Database.Variables.DB_GLOBAL.profile.PREF_METRIC
			CVAR_FOV = GetCVar("cameraFov")
		end

		UpdateReferences()
		CallbackRegistry:Add("C_CONFIG_UPDATE", UpdateReferences)
		CallbackRegistry:Add("C_CONFIG_APPEARANCE_UPDATE", UpdateReferences)

		--------------------------------

		do -- 3D
			-- ---@param framePosX number
			-- ---@param framePosY number
			-- ---@param screenWidth number
			-- ---@param screenHeight number
			-- ---@param horizontalDistance number
			-- ---@param elevationDiff number
			-- ---@param fov number
			-- function Callback:GetPerspectiveRotation(framePosX, framePosY, screenWidth, screenHeight, horizontalDistance, elevationDiff, fov)
			-- 	local fovRad       = math.rad(fov)
			-- 	local f            = (screenWidth * 0.5) / math.tan(fovRad * 0.5)

			-- 	local ratio        = elevationDiff / horizontalDistance
			-- 	local centerX      = screenWidth * 0.5
			-- 	local centerY      = screenHeight * 0.5
			-- 	local dx           = framePosX - centerX
			-- 	local dy           = framePosY - centerY

			-- 	local yawFromPixel = math.atan(dx / f)
			-- 	local scaledYaw    = yawFromPixel * (horizontalDistance / (horizontalDistance + f)) * (ratio / 1 * 1.625)

			-- 	return -scaledYaw
			-- end

			---@param frameX number
			---@param fovDeg number
			---@param distance number
			function Callback:GetPerspectiveRotation(frameX, fovDeg, distance)
				local screenW = GetScreenWidth()
				local centerX = screenW * 0.5
				local fovRad = math.rad(fovDeg)
				local focalLength = centerX / math.tan(fovRad * 0.5)
				local xOffset = frameX - centerX
				local angle = math.atan(xOffset / focalLength)
				local distanceModifier = (1000 / distance) * .075

				return -angle * .075
			end

			---@param distance number Distance from camera to object.
			---@param referenceDistance number Reference distance for referenceScale.
			---@param referenceScale number Desired scale at referenceDistance.
			---@param minScale number Absolute minimum scale.
			---@param maxScale number Absolute maximum scale.
			---@param exponent number Controls falloff curve (default = 1).
			function Callback:GetDistanceScale(distance, referenceDistance, referenceScale, minScale, maxScale, exponent)
				local distance = distance
				local referenceDistance = referenceDistance
				local baselineScale = referenceScale
				local minScale = minScale
				local maxScale = maxScale
				local exponent = exponent or 1

				--------------------------------

				if distance <= 0 then
					return maxScale
				end

				local rawScale = baselineScale * (referenceDistance / distance) ^ exponent

				if rawScale < minScale then
					return minScale
				elseif rawScale > maxScale then
					return maxScale
				else
					return rawScale
				end
			end

			function Callback:GetSuperTrackedPosition()
				local result = {
					mapID = nil,
					normalizedX = nil,
					normalizedY = nil,
					continentID = nil,
					worldPos = nil,
				}

				--------------------------------

				-- Get super track map pin info
				local superTrackedMapElement = addon.Query.Script:GetSuperTrackedMapElement()
				local mapID = C_Map.GetBestMapForUnit("player")

				-- Fill result
				if superTrackedMapElement then
					result.normalizedX, result.normalizedY = superTrackedMapElement.normalizedX, superTrackedMapElement.normalizedY
					result.continentID, result.worldPos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(result.normalizedX, result.normalizedY))
				end

				--------------------------------

				return result
			end

			function Callback:GetDistance2D()
				local mapID = C_Map.GetBestMapForUnit("player")
				local pinInfo = Callback:GetSuperTrackedPosition()
				local _, playerWorldPos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(C_Map.GetPlayerMapPosition(mapID, "player").x, C_Map.GetPlayerMapPosition(mapID, "player").y))

				local dx = pinInfo.worldPos.x - playerWorldPos.x
				local dy = pinInfo.worldPos.y - playerWorldPos.y
				local distance = math.sqrt(dx * dx + dy * dy)

				return distance
			end

			function Callback:GetElevation()
				local d3 = C_Navigation.GetDistance()
				local d2 = Callback:GetDistance2D()
				local elevation = math.sqrt(d3 * d3 - d2 * d2)

				return elevation
			end
		end

		do -- ARRIVAL TIME
			local session = nil

			local function ArrivalTime_Reset()
				session = {
					["lastDistance"] = 0,
				}
			end

			local function ArrivalTime_Update()
				local distance = C_Navigation.GetDistance()
				local delta = session.lastDistance - distance

				--------------------------------

				session.lastDistance = distance

				--------------------------------

				if delta > 0 then
					local arrivalTime = math.ceil(distance / delta)

					--------------------------------

					if arrivalTime > 0 then
						NS.Variables.ArrivalTime = arrivalTime
					else
						NS.Variables.ArrivalTime = nil
					end
				else
					NS.Variables.ArrivalTime = nil
				end
			end

			ArrivalTime_Reset()
			C_Timer.NewTicker(1, ArrivalTime_Update, 0)
		end

		do -- GET
			function Callback:GetSuperTrackingInfo()
				local superTrackingInfo = {
					["valid"] = C_SuperTrack.IsSuperTrackingAnything(),
					["type"] = C_SuperTrack.GetHighestPrioritySuperTrackingType(),
					["texture"] = tostring(Frame_BlizzardWaypoint.Icon:GetTexture()),
				}

				return superTrackingInfo
			end

			function Callback:GetContextIcon_Quest(questID)
				local contextIconInfo = {
					["string"] = nil,
					["texture"] = nil,
				}

				--------------------------------

				contextIconInfo.string, contextIconInfo.texture = addon.ContextIcon.Script:GetContextIcon(nil, nil, questID)

				--------------------------------

				return contextIconInfo
			end

			function Callback:GetContextIcon_Pin()
				local texture = {
					["type"] = nil,
					["path"] = nil
				}

				--------------------------------

				local pinInfo = Callback:GetPinInfo()
				local isWay = WaypointUI_IsWay()

				if pinInfo.pinType then
					if pinInfo.pinType == Enum.SuperTrackingType.Corpse then
						texture.type = "ATLAS"
						texture.path = "poi-torghast"
					elseif pinInfo.poiInfo and pinInfo.poiInfo.atlasName then
						texture.type = "ATLAS"
						texture.path = pinInfo.poiInfo.atlasName
					elseif isWay then
						texture.type = "TEXTURE"
						texture.path = addon.CREF:GetAddonPath() .. "Art/ContextIcons/map-pin-way.png"
					elseif pinInfo.pinType == Enum.SuperTrackingType.UserWaypoint then
						texture.type = "TEXTURE"
						texture.path = addon.CREF:GetAddonPath() .. "Art/ContextIcons/map-pin-default.png"
					elseif pinInfo.poiType == Enum.SuperTrackingMapPinType.TaxiNode then
						texture.type = "ATLAS"
						texture.path = "Crosshair_Taxi_128"
					elseif pinInfo.poiType == Enum.SuperTrackingMapPinType.DigSite then
						texture.type = "ATLAS"
						texture.path = "ArchBlob"
					elseif pinInfo.poiType == Enum.SuperTrackingMapPinType.QuestOffer then
						-- local mapID = C_Map.GetBestMapForUnit("player")
						-- local quests = C_QuestLog.GetQuestsOnMap(mapID)

						-- local currentMapElement = addon.Query.Script:GetSuperTrackedMapElement()
						-- local isProgress, isAccountCompleted, isAnchored, isCampaign, isCombatAllyQuest, isDaily, isHidden, isImportant, isLegendary, isLocalStory, isMapIndicatorQuest, isMeta, isQuestStart = currentMapElement.isProgress, currentMapElement.isAccountCompleted, currentMapElement.isAnchored, currentMapElement.isCampaign, currentMapElement.isCombatAllyQuest, currentMapElement.isDaily, currentMapElement.isHidden, currentMapElement.isImportant, currentMapElement.isLegendary, currentMapElement.isLocalStory, currentMapElement.isMapIndicatorQuest, currentMapElement.isMeta, currentMapElement.isQuestStart
						-- local contextIcon = addon.ContextIcon.Script:GetQuestIconFromInfo({
						-- 	isCompleted = false,
						-- 	isOnQuest = isProgress,
						-- 	isDefault = isLocalStory,
						-- 	isImportant = isImportant,
						-- 	isCampaign = isCampaign,
						-- 	isLegendary = isLegendary,
						-- 	isArtifact = false,
						-- 	isCalling = false,
						-- 	isMeta = isMeta,
						-- 	isRecurring = isDaily,
						-- 	isRepeatable = false,
						-- })

						-- texture.type = "TEXTURE"
						-- texture.path = contextIcon and addon.CREF:GetAddonPath() .. "Art/ContextIcons/" .. contextIcon .. ".png" or addon.CREF:GetAddonPath() .. "Art/ContextIcons/quest-available.png"

						-- --------------------------------

						texture.type = "TEXTURE"
						texture.path = addon.CREF:GetAddonPath() .. "Art/ContextIcons/quest-available.png"
					else
						texture.type = "TEXTURE"
						texture.path = addon.CREF:GetAddonPath() .. "Art/ContextIcons/map-pin-default.png"
					end
				end

				--------------------------------

				return texture
			end

			function Callback:GetContextIcon_Redirect(questID)
				local texture = nil

				--------------------------------

				if questID then
					local questClassification = C_QuestInfoSystem.GetQuestClassification(questID)
					local questComplete = C_QuestLog.IsComplete(questID)

					--------------------------------

					if questComplete then
						if questClassification == Enum.QuestClassification.Recurring then
							texture = addon.CREF:GetAddonPath() .. "Art/ContextIcons/redirect-repeatable.png"
						elseif questClassification == Enum.QuestClassification.Important then
							texture = addon.CREF:GetAddonPath() .. "Art/ContextIcons/redirect-important.png"
						else
							texture = addon.CREF:GetAddonPath() .. "Art/ContextIcons/redirect-default.png"
						end
					else
						texture = addon.CREF:GetAddonPath() .. "Art/ContextIcons/redirect-incomplete.png"
					end
				else
					texture = addon.CREF:GetAddonPath() .. "Art/ContextIcons/redirect-neutral.png"
				end

				--------------------------------

				return texture
			end

			function Callback:GetTrackingType(questID)
				local result = nil

				--------------------------------

				local pinType = C_SuperTrack.GetHighestPrioritySuperTrackingType()

				--------------------------------

				if questID then
					local questClassification = C_QuestInfoSystem.GetQuestClassification(questID)
					local questComplete = C_QuestLog.IsComplete(questID)

					--------------------------------

					if questComplete then
						if questClassification == Enum.QuestClassification.Recurring then
							result = "QUEST_COMPLETE_RECURRING"
						elseif questClassification == Enum.QuestClassification.Important then
							result = "QUEST_COMPLETE_IMPORTANT"
						else
							result = "QUEST_COMPLETE"
						end
					else
						result = "QUEST_INCOMPLETE"
					end
				else
					if pinType == Enum.SuperTrackingType.Corpse then
						result = "CORPSE"
					else
						result = "NEUTRAL"
					end
				end

				--------------------------------

				return result
			end

			--------------------------------

			function Callback:GetQuestInfo()
				local SUPER_TRACK_INFO = Callback:GetSuperTrackingInfo()

				--------------------------------

				local questInfo = {
					["questID"] = C_SuperTrack.GetSuperTrackedQuestID(),
					["completed"] = nil,
					["contextIcon"] = nil,
					["objectiveInfo"] = {
						["objectives"] = nil,
						["objectiveIndex"] = 1,
						["isMultiObjective"] = nil,
					},
				}
				local isQuest = (SUPER_TRACK_INFO.type == Enum.SuperTrackingType.Quest and questInfo.questID)
				local isQuestComplete = (isQuest) and (C_QuestLog.IsComplete(questInfo.questID))
				local isWorldQuest = (isQuest) and (C_TaskQuest.GetQuestInfoByQuestID(questInfo.questID))

				if isQuest and not isWorldQuest then
					questInfo.completed = isQuestComplete
					questInfo.contextIcon = Callback:GetContextIcon_Quest(questInfo.questID)

					--------------------------------

					if not isQuestComplete then
						questInfo.objectiveInfo.objectives = C_QuestLog.GetQuestObjectives(questInfo.questID)
						questInfo.objectiveInfo.isMultiObjective = (questInfo.objectiveInfo.objectives and #questInfo.objectiveInfo.objectives > 1)

						if questInfo.objectiveInfo.objectives then
							for i, objective in ipairs(questInfo.objectiveInfo.objectives) do
								if objective.finished then
									if i < #questInfo.objectiveInfo.objectives then
										questInfo.objectiveInfo.objectiveIndex = i + 1
									else
										questInfo.completed = true
									end
								end
							end
						end
					end

					--------------------------------

					return questInfo
				else
					return nil
				end
			end

			function Callback:GetPinInfo()
				local pinInfo = nil

				--------------------------------

				local pinType = C_SuperTrack.GetHighestPrioritySuperTrackingType() -- Super tracking type
				local poiType, poiID = C_SuperTrack.GetSuperTrackedMapPin()  -- AreaPOI, QuestOffer, TaxiNode, DigSite
				local trackableType, trackableID = C_SuperTrack.GetSuperTrackedContent() -- Appearance, Mount, Achievement

				local poiInfo = poiID and C_AreaPoiInfo.GetAreaPOIInfo(nil, poiID)
				local pinName, pinDescription = C_SuperTrack.GetSuperTrackedItemName() -- Name of super tracked (e.g. The Stockades)
				local isWay = WaypointUI_IsWay()

				pinInfo = {
					["isWay"] = isWay,
					["pinType"] = pinType,
					["poiType"] = poiType,
					["poiID"] = poiID,
					["trackableType"] = trackableType,
					["trackableID"] = trackableID,
					["poiInfo"] = poiInfo,
					["pinName"] = pinName,
					["pinDescription"] = pinDescription,
				}

				--------------------------------

				return pinInfo
			end

			function Callback:GetCurrentState()
				local C_WS_DISTANCE_TRANSITION = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_TRANSITION
				local C_WS_DISTANCE_HIDE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_HIDE

				--------------------------------

				local SUPER_TRACK_INFO = Callback:GetSuperTrackingInfo()
				local questInfo = NS.Variables.Session.questInfo

				--------------------------------

				local state = nil

				local distance = C_Navigation.GetDistance()
				local isInInstance = (IsInInstance())
				local isQuest = (questInfo ~= nil)
				local isValid = (SUPER_TRACK_INFO.valid)
				local isDefault = (SUPER_TRACK_INFO.texture == "3308452")
				local isRangeProximity = (distance < C_WS_DISTANCE_TRANSITION)
				local isRangeValid = (distance > C_WS_DISTANCE_HIDE)

				if (isInInstance) or (not isRangeValid) or (not isValid) then
					if not isRangeValid then
						state = "INVALID_RANGE"
					else
						state = "INVALID"
					end
				elseif isRangeProximity then
					if isQuest and isDefault then
						state = "QUEST_PROXIMITY"
					else
						state = "PROXIMITY"
					end
				else
					if isQuest and isDefault then
						state = "QUEST_AREA"
					else
						state = "AREA"
					end
				end

				--------------------------------

				return state
			end

			function Callback:GetIsClamped()
				local isClamped = Frame_BlizzardWaypoint.isClamped
				local newClamped = NS.Variables.Session.lastClamped ~= isClamped
				NS.Variables.Session.lastClamped = isClamped

				return isClamped, newClamped
			end

			function Callback:GetIsInAreaPOI()

			end
		end

		do -- SET
			function Callback:Waypoint_Reset(keepElementState)
				if not keepElementState then
					Frame_Waypoint.hidden = true
					Frame_Waypoint:Hide()

					Frame_Pinpoint.hidden = true
					Frame_Pinpoint:Hide()
				end

				--------------------------------

				NS.Variables.ArrivalTime = nil
				NS.Variables.Session = {}
			end

			function Callback:Blizzard_Hide()
				Frame_BlizzardWaypoint.Icon:SetAlpha(0)
				Frame_BlizzardWaypoint.DistanceText:SetAlpha(0)
				Frame_BlizzardWaypoint.Arrow:SetAlpha(0)
			end

			function Callback:Blizzard_Show()
				Frame_BlizzardWaypoint.Icon:SetAlpha(1)
				Frame_BlizzardWaypoint.DistanceText:SetAlpha(1)
				Frame_BlizzardWaypoint.Arrow:SetAlpha(1)
			end

			function Callback:Waypoint_Hide()
				Frame:Hide()
			end

			function Callback:Waypoint_Show()
				Frame.Waypoint:SetPoint("CENTER", Frame_BlizzardWaypoint.navFrame)
				Frame.Pinpoint:SetPoint("BOTTOM", Frame_BlizzardWaypoint.navFrame, "TOP", 0, 75)
				Frame:Show()
			end
		end

		do -- APPEARANCE
			function Callback:APP_GetColor(questID)
				local result = nil

				--------------------------------

				local trackingType = Callback:GetTrackingType(questID)

				local COLOR_QUEST_INCOMPLETE = C_APP_COLOR and C_APP_COLOR_QUEST_INCOMPLETE or addon.CREF:GetSharedColor().RGB_PING_QUEST_NEUTRAL
				local COLOR_QUEST_COMPLETE = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE or addon.CREF:GetSharedColor().RGB_PING_QUEST_NORMAL
				local COLOR_QUEST_COMPLETE_REPEATABLE = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_REPEATABLE or addon.CREF:GetSharedColor().RGB_PING_QUEST_REPEATABLE
				local COLOR_QUEST_COMPLETE_IMPORTANT = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_IMPORTANT or addon.CREF:GetSharedColor().RGB_PING_QUEST_IMPORTANT
				local COLOR_NEUTRAL = C_APP_COLOR and C_APP_COLOR_NEUTRAL or addon.CREF:GetSharedColor().RGB_PING_NEUTRAL

				--------------------------------

				if trackingType == "QUEST_COMPLETE" then
					result = COLOR_QUEST_COMPLETE
				elseif trackingType == "QUEST_COMPLETE_RECURRING" then
					result = COLOR_QUEST_COMPLETE_REPEATABLE
				elseif trackingType == "QUEST_COMPLETE_IMPORTANT" then
					result = COLOR_QUEST_COMPLETE_IMPORTANT
				elseif trackingType == "QUEST_INCOMPLETE" then
					result = COLOR_QUEST_INCOMPLETE
				elseif trackingType == "CORPSE" then
					result = { r = addon.CREF:GetSharedColor().RGB_WHITE.r, g = addon.CREF:GetSharedColor().RGB_WHITE.g, b = addon.CREF:GetSharedColor().RGB_WHITE.b, a = 1 }
				else
					result = COLOR_NEUTRAL
				end

				--------------------------------

				return result
			end

			function Callback:APP_CanRecolor(questID)
				local result = nil

				--------------------------------

				local trackingType = Callback:GetTrackingType(questID)

				local RECOLOR_QUEST_INCOMPLETE = (C_APP_COLOR and C_APP_COLOR_QUEST_INCOMPLETE_TINT) or (not C_APP_COLOR and false)
				local RECOLOR_QUEST_COMPLETE = (C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_TINT) or (not C_APP_COLOR and false)
				local RECOLOR_QUEST_COMPLETE_REPEATABLE = (C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT) or (not C_APP_COLOR and false)
				local RECOLOR_QUEST_COMPLETE_IMPORTANT = (C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT) or (not C_APP_COLOR and false)
				local RECOLOR_NEUTRAL = (C_APP_COLOR and C_APP_COLOR_NEUTRAL_TINT) or (not C_APP_COLOR and true)

				--------------------------------

				if trackingType == "QUEST_COMPLETE" then
					result = RECOLOR_QUEST_COMPLETE
				elseif trackingType == "QUEST_COMPLETE_RECURRING" then
					result = RECOLOR_QUEST_COMPLETE_REPEATABLE
				elseif trackingType == "QUEST_COMPLETE_IMPORTANT" then
					result = RECOLOR_QUEST_COMPLETE_IMPORTANT
				elseif trackingType == "QUEST_INCOMPLETE" then
					result = RECOLOR_QUEST_INCOMPLETE
				elseif trackingType == "CORPSE" then
					result = false
				else
					result = RECOLOR_NEUTRAL
				end

				--------------------------------

				return result
			end

			--------------------------------

			function Callback:APP_GetInfo(questID)
				local result = {
					["color"] = Callback:APP_GetColor(questID),
					["recolorContext"] = Callback:APP_CanRecolor(questID),
				}

				--------------------------------

				return result
			end

			function Callback:APP_Set()
				if not NS.Variables.Session.appearanceInfo then
					return
				end

				local appearanceInfo = NS.Variables.Session.appearanceInfo

				--------------------------------

				Frame_Waypoint:APP_SetTint(appearanceInfo.color)
				Frame_Waypoint:APP_Context_SetTint(appearanceInfo.color)
				Frame_Waypoint:APP_Context_SetRecolor(appearanceInfo.recolorContext)
				Frame_Waypoint:APP_SetTextAlpha(C_WS_DISTANCE_TEXT_ALPHA)
				Frame_Waypoint:APP_Beam_Set(C_APP_WAYPOINT_BEAM, C_APP_WAYPOINT_BEAM_ALPHA)
				Frame_Waypoint:APP_SetScale(C_WS_WAYPOINT_SCALE)

				Frame_Pinpoint:APP_SetTint(appearanceInfo.color)
				Frame_Pinpoint:APP_Context_SetTint(appearanceInfo.color)
				Frame_Pinpoint:APP_Context_SetRecolor(appearanceInfo.recolorContext)
				Frame_Pinpoint:APP_SetScale(C_WS_PINPOINT_SCALE)
			end
		end

		do -- LOGIC
			local function Transition_Pinpoint(id)
				if not Frame_Waypoint.hidden then
					Frame_Waypoint:HideWithAnimation(id).onFinish(function()
						Frame_Pinpoint:ShowWithAnimation(id, false)
					end)

					--------------------------------

					addon.C.Sound.Script:PlaySound(SOUNDKIT.UI_RUNECARVING_CLOSE_MAIN_WINDOW)
				else
					Frame_Pinpoint:ShowWithAnimation(id, false)
				end

				--------------------------------

				IS_WAYPOINT = false
				IS_PINPOINT = true
			end

			local function Transition_Waypoint(id)
				if not Frame_Pinpoint.hidden then
					Frame_Pinpoint:HideWithAnimation(id).onFinish(function()
						Frame_Waypoint:ShowWithAnimation(id, false)
					end)


					--------------------------------

					addon.C.Sound.Script:PlaySound(SOUNDKIT.UI_RUNECARVING_OPEN_MAIN_WINDOW)
				else
					Frame_Waypoint:ShowWithAnimation(id, false)
				end

				--------------------------------

				IS_WAYPOINT = true
				IS_PINPOINT = false
			end

			local function Transition_OnlyPinpoint(id)
				if Frame_Pinpoint.hidden then
					Frame_Pinpoint:ShowWithAnimation(id, false)
				end

				if not Frame_Waypoint.hidden then
					Frame_Waypoint:HideWithAnimation(id, false)

					--------------------------------

					addon.C.Sound.Script:PlaySound(SOUNDKIT.UI_RUNECARVING_CLOSE_MAIN_WINDOW)
				end

				--------------------------------

				IS_WAYPOINT = false
				IS_PINPOINT = true
			end

			local function Transition_OnlyWaypoint(id)
				if not Frame_Pinpoint.hidden then
					Frame_Pinpoint:HideWithAnimation(id, false)
				end

				if Frame_Waypoint.hidden then
					Frame_Waypoint:ShowWithAnimation(id, false)

					--------------------------------

					addon.C.Sound.Script:PlaySound(SOUNDKIT.UI_RUNECARVING_OPEN_MAIN_WINDOW)
				end

				--------------------------------

				IS_WAYPOINT = true
				IS_PINPOINT = false
			end

			--------------------------------

			local function Process_Waypoint_Update()
				local questInfo = NS.Variables.Session.questInfo
				local appearanceInfo = NS.Variables.Session.appearanceInfo

				--------------------------------

				if questInfo then
					local contextIcon = { type = "TEXTURE", path = questInfo.contextIcon.texture }
					local currentWaypointObjective = (C_QuestLog.GetNextWaypointText(questInfo.questID))

					if currentWaypointObjective then
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect(questInfo.questID) }
					end

					--------------------------------

					Frame_Waypoint:Context_SetOpacity(1)
					Frame_Waypoint:Context_SetImage(contextIcon)
					Frame_Waypoint:Context_SetVFX("Wave", appearanceInfo.color)
				else
					local contextIcon = (Callback:GetContextIcon_Pin())

					--------------------------------

					Frame_Waypoint:Context_SetOpacity(1)
					Frame_Waypoint:Context_SetImage(contextIcon)
					Frame_Waypoint:Context_SetVFX("Wave", appearanceInfo.color)
				end

				--------------------------------

				Callback:APP_Set(questInfo and questInfo.questID)
			end

			local function Process_Waypoint_Distance()
				local DISTANCE = C_Navigation.GetDistance()

				--------------------------------

				-- Arrival time (hr, min, sec)
				local _, _, _, strHr, strMin, strSec = addon.C.API.Util:FormatTime(NS.Variables.ArrivalTime or 0)
				local arrivalTime = strHr .. strMin .. strSec

				-- Distance (yd/m)
				local yds = addon.C.API.Util:FormatNumber(string.format("%.0f", DISTANCE))
				local km, m = addon.C.API.Util:ConvertYardsToMetric(DISTANCE)
				local formattedKm, formattedM = string.format("%.2f", km), string.format("%.0f", m)
				local distance = C_PREF_METRIC and (km >= 1 and formattedKm .. "km" or formattedM .. "m") or (yds .. " yds")

				-- Gemerate text to display based on user setting
				local text = nil
				local subtext = nil
				if C_WS_DISTANCE_TEXT_TYPE == 1 then -- Distance + Arrival Time
					text = distance
					subtext = arrivalTime and #arrivalTime > 0 and arrivalTime or nil
				elseif C_WS_DISTANCE_TEXT_TYPE == 2 then -- Distance
					text = distance
					subtext = nil
				elseif C_WS_DISTANCE_TEXT_TYPE == 3 then -- Arrival Time
					text = nil
					subtext = arrivalTime and #arrivalTime > 0 and arrivalTime or nil
				else -- Hide
					text = nil
					subtext = nil
				end

				-- Set text
				Frame_Waypoint:SetText(text, subtext)
			end

			local function Process_Pinpoint_Update()
				local questInfo = NS.Variables.Session.questInfo

				--------------------------------

				if questInfo then
					local text = nil
					local contextIcon = { type = "TEXTURE", path = questInfo.contextIcon.texture }

					local isComplete = (questInfo.completed)
					local currentWaypointObjective = (C_QuestLog.GetNextWaypointText(questInfo.questID))
					local currentQuestObjective = ((questInfo.objectiveInfo.objectives and #questInfo.objectiveInfo.objectives >= questInfo.objectiveInfo.objectiveIndex and questInfo.objectiveInfo.objectives[questInfo.objectiveInfo.objectiveIndex].text) or "")
					local questName = (C_QuestLog.GetTitleForQuestID(questInfo.questID))

					--------------------------------

					if currentWaypointObjective then
						text = currentWaypointObjective
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect(questInfo.questID) }
					else
						if isComplete then
							if C_WS_PINPOINT_DETAIL then
								text = questName .. " — " .. L["WaypointSystem - Pinpoint - Quest - Complete"]
							else
								text = L["WaypointSystem - Pinpoint - Quest - Complete"]
							end
						elseif currentQuestObjective then
							text = currentQuestObjective
						end
					end

					Frame_Pinpoint:SetText(text)
					Frame_Pinpoint:Context_SetOpacity(.25)
					Frame_Pinpoint:Context_SetImage(contextIcon)
				else
					local text = nil
					local contextIcon = (Callback:GetContextIcon_Pin())

					local pinInfo = (Callback:GetPinInfo())

					--------------------------------

					if pinInfo.isWay then
						local wayInfo = WaypointUI_GetWay()

						--------------------------------

						if #wayInfo.name >= 1 then
							text = wayInfo.name
						else
							text = nil
						end
					elseif pinInfo.pinType == Enum.SuperTrackingType.UserWaypoint then
						text = nil
					elseif pinInfo.pinType == Enum.SuperTrackingType.Corpse then
						text = nil
					else
						if C_WS_PINPOINT_DETAIL then
							if pinInfo.poiInfo and pinInfo.poiInfo.description and #pinInfo.poiInfo.description > 1 then
								text = pinInfo.pinName .. " — " .. pinInfo.poiInfo.description
							else
								text = pinInfo.pinName
							end
						else
							text = pinInfo.pinName
						end
					end

					Frame_Pinpoint:SetText(text)
					Frame_Pinpoint:Context_SetOpacity(text and .25 or 1)
					Frame_Pinpoint:Context_SetImage(contextIcon)
				end

				--------------------------------

				Callback:APP_Set(questInfo and questInfo.questID)
			end

			local function Process_3D()
				-- [DISTANCE SCALE]
				local DISTANCE = C_Navigation.GetDistance()
				local WAYPOINT_3D_MODIFIER_SCALE = Callback:GetDistanceScale(DISTANCE, 2000, .25, C_WS_WAYPOINT_MIN_SCALE, C_WS_WAYPOINT_MAX_SCALE, 1)
				Frame.REF_WAYPOINT_CONTENT:SetScale(WAYPOINT_3D_MODIFIER_SCALE)

				-- [WAYPOINT BEAM ROTATION]
				-- local DISTANCE_2D = Callback:GetDistance2D()
				-- local ELEVATION = Callback:GetElevation()
				-- local WAYPOINT_3D_MODIFIER_ROTATION = Callback:GetPerspectiveRotation(SuperTrackedFrame:GetLeft() or 0, SuperTrackedFrame:GetTop() or 0, GetScreenWidth(), GetScreenHeight(), DISTANCE_2D, ELEVATION, CVAR_FOV)
				-- Frame.REF_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetRotation(WAYPOINT_3D_MODIFIER_ROTATION)

				-- local WAYPOINT_3D_MODIFIER_ROTATION = Callback:GetPerspectiveRotation(SuperTrackedFrame:GetLeft() or 0, CVAR_FOV, DISTANCE)
				-- Frame.REF_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetRotation(WAYPOINT_3D_MODIFIER_ROTATION)
			end

			--------------------------------

			local function Event_OnStateChanged(state, isNewState, id)
				if state == "INVALID" or state == "INVALID_RANGE" then
					if isNewState and state == "INVALID_RANGE" then
						if not Frame_Waypoint.hidden then
							Frame_Waypoint:HideWithAnimation(id, false)
						end

						if not Frame_Pinpoint.hidden then
							Frame_Pinpoint:HideWithAnimation(id, false)
						end
					end

					--------------------------------

					Callback:Blizzard_Hide()

					--------------------------------

					return
				end

				if isNewState then
					if state == "QUEST_PROXIMITY" then
						if C_WS_TYPE == 1 then -- Both
							Transition_Pinpoint(id)
						end

						if C_WS_TYPE == 2 then -- Waypoint
							Transition_OnlyWaypoint(id)
						end

						if C_WS_TYPE == 3 then -- Pinpoint
							Transition_OnlyPinpoint(id)
						end
					elseif state == "PROXIMITY" then
						if C_WS_TYPE == 1 then -- Both
							Transition_Pinpoint(id)
						end

						if C_WS_TYPE == 2 then -- Waypoint
							Transition_OnlyWaypoint(id)
						end

						if C_WS_TYPE == 3 then -- Pinpoint
							Transition_OnlyPinpoint(id)
						end
					elseif state == "QUEST_AREA" then
						if C_WS_TYPE == 1 then -- Both
							Transition_Waypoint(id)
						end

						if C_WS_TYPE == 2 then -- Waypoint
							Transition_OnlyWaypoint(id)
						end

						if C_WS_TYPE == 3 then -- Pinpoint
							Transition_OnlyPinpoint(id)
						end
					elseif state == "AREA" then
						if C_WS_TYPE == 1 then -- Both
							Transition_Waypoint(id)
						end

						if C_WS_TYPE == 2 then -- Waypoint
							Transition_OnlyWaypoint(id)
						end

						if C_WS_TYPE == 3 then -- Pinpoint
							Transition_OnlyPinpoint(id)
						end
					end

					--------------------------------

					if IS_WAYPOINT then
						Process_Waypoint_Update()
					end
				end
			end

			local function Event_OnClampChanged(isClamped)
				if isClamped then
					Callback:Waypoint_Hide()
					Callback:Blizzard_Hide()
				else
					Callback:Waypoint_Show()
					Callback:Blizzard_Hide()
				end
			end

			local function Event_OnUpdate()
				Process_3D()

				--------------------------------

				if IS_WAYPOINT then
					Process_Waypoint_Distance()
				end

				if IS_PINPOINT then
					Process_Pinpoint_Update()
				end
			end

			--------------------------------

			function Callback:UpdateStateSession(currentState)
				local id = nil
				local isNewState = nil

				--------------------------------

				if NS.Variables.Session.lastState ~= currentState then
					id = addon.C.API.Util:gen_hash()
					isNewState = true
				else
					id = NS.Variables.Session.id
					isNewState = false
				end

				--------------------------------

				return id, isNewState
			end

			function Callback:Update(isNewWaypoint)
				if not C_SuperTrack.IsSuperTrackingAnything() or IsInCinematicScene() then
					Callback:Waypoint_Hide()
					Callback:Blizzard_Hide()

					--------------------------------

					return
				end

				if isNewWaypoint then
					Callback:Waypoint_Reset()
				end

				--------------------------------

				local questInfo = Callback:GetQuestInfo()
				local appearanceInfo = Callback:APP_GetInfo(questInfo and questInfo.questID)
				local state = Callback:GetCurrentState()
				local id, isNewState = Callback:UpdateStateSession(state)
				local isClamped, isNewClamped = Callback:GetIsClamped()

				NS.Variables.Session.questInfo = questInfo
				NS.Variables.Session.appearanceInfo = appearanceInfo
				NS.Variables.Session.lastState = state
				NS.Variables.Session.id = id

				--------------------------------

				if isNewClamped then
					Event_OnClampChanged(isClamped)
				end

				Event_OnStateChanged(state, isNewState, id)
				Event_OnUpdate()
			end
		end
	end

	--------------------------------
	-- FUNCTIONS (ANIMATION)
	--------------------------------

	do
		do -- WAYPOINT
			do -- VFX
				do -- WAVE
					local Wave = Frame.REF_WAYPOINT_CONTEXT_VFX_WAVE

					--------------------------------

					function Wave:Animation_Playback_StopEvent()
						return not Wave:IsShown()
					end

					function Wave:Animation_Playback()
						addon.C.Animation:CancelAll(Wave)

						--------------------------------

						addon.C.Animation:Alpha({ ["frame"] = Wave, ["duration"] = 1.5, ["from"] = 1, ["to"] = 0, ["ease"] = nil, ["stopEvent"] = Wave.Animation_Playback_StopEvent })
						addon.C.Animation:Scale({ ["frame"] = Wave, ["duration"] = 2, ["from"] = .5, ["to"] = 1.5, ["ease"] = "EaseExpo_InOut", ["stopEvent"] = Wave.Animation_Playback_StopEvent })
					end

					Wave.Animation_Playback_Loop = addon.C.Animation.Sequencer:CreateLoop()
					Wave.Animation_Playback_Loop:SetInterval(1.75)
					Wave.Animation_Playback_Loop:SetAnimation(Wave.Animation_Playback)
					Wave.Animation_Playback_Loop:SetOnStart(function() Wave:Show() end)
					Wave.Animation_Playback_Loop:SetOnStop(function() Wave:Hide() end)
				end
			end

			do -- SHOW
				function Frame_Waypoint:ShowWithAnimation_StopEvent(id)
					return NS.Variables.Session.id ~= id
				end

				function Frame_Waypoint:ShowWithAnimation(id, skipAnimation)
					Frame_Waypoint.hidden = false
					Frame_Waypoint:Show()

					--------------------------------

					if skipAnimation then
						Frame.REF_WAYPOINT_CONTEXT:SetScale(1)
						Frame.REF_WAYPOINT_CONTEXT:SetAlpha(1)
						Frame.REF_WAYPOINT_CONTEXT_VFX:SetAlpha(1)
						Frame.REF_WAYPOINT_FOOTER_LAYOUT:SetPoint("CENTER", Frame.REF_WAYPOINT_FOOTER_LAYOUT:GetParent(), 0, 0)
						Frame.REF_WAYPOINT_FOOTER_LAYOUT:SetAlpha(1)
						Frame.REF_WAYPOINT_MARKER:SetAlpha(1)
						Frame.REF_WAYPOINT_MARKER:SetScale(1)
					else
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_CONTEXT)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_CONTEXT_VFX)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_FOOTER_LAYOUT)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_MARKER)

						Frame.REF_WAYPOINT_CONTEXT_VFX:SetAlpha(0)
						Frame.REF_WAYPOINT_FOOTER_LAYOUT:SetAlpha(0)
						Frame.REF_WAYPOINT_MARKER:SetAlpha(0)
						addon.C.Animation:Scale({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = 3.25, ["to"] = 1, ["ease"] = "EaseSine_Out", ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })

						C_Timer.After(.225, function()
							if not Frame_Waypoint:ShowWithAnimation_StopEvent(id) then
								addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT_VFX, ["duration"] = 1, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
								addon.C.Animation:Translate({ ["frame"] = Frame.REF_WAYPOINT_FOOTER_LAYOUT, ["duration"] = 1, ["from"] = 15, ["to"] = 0, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
								addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
								addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_MARKER, ["duration"] = .25, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
								addon.C.Animation:Scale({ ["frame"] = Frame.REF_WAYPOINT_MARKER, ["duration"] = 1, ["from"] = .25, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:ShowWithAnimation_StopEvent(id) end })
							end
						end)
					end

					Frame.REF_WAYPOINT_CONTEXT:ShowWithAnimation(skipAnimation)
					Frame.REF_WAYPOINT_MARKER_PULSE.Animation_Playback_Loop:Start()
				end
			end

			do -- HIDE
				function Frame_Waypoint:HideWithAnimation_StopEvent(id)
					return NS.Variables.Session.id ~= id
				end

				function Frame_Waypoint:HideWithAnimation(id, skipAnimation)
					Frame_Waypoint.hidden = true

					--------------------------------

					local chain = addon.C.API.Util:AddMethodChain({ "onFinish" })

					--------------------------------

					if skipAnimation then
						Frame.REF_WAYPOINT_CONTEXT:SetScale(2)
						Frame.REF_WAYPOINT_CONTEXT:SetAlpha(0)
						Frame.REF_WAYPOINT_CONTEXT_VFX:SetAlpha(0)
						Frame.REF_WAYPOINT_FOOTER_LAYOUT:SetPoint("CENTER", Frame.REF_WAYPOINT_FOOTER_LAYOUT:GetParent(), 0, 7.5)
						Frame.REF_WAYPOINT_FOOTER_LAYOUT:SetAlpha(0)
						Frame.REF_WAYPOINT_MARKER:SetAlpha(0)
						Frame.REF_WAYPOINT_MARKER:SetScale(.25)
					else
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_CONTEXT)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_CONTEXT_VFX)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_FOOTER_LAYOUT)
						addon.C.Animation:CancelAll(Frame.REF_WAYPOINT_MARKER)

						addon.C.Animation:Scale({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = Frame.REF_WAYPOINT_CONTEXT:GetScale(), ["to"] = 2, ["ease"] = "EaseSine_In", ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = Frame.REF_WAYPOINT_CONTEXT:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_CONTEXT_VFX, ["duration"] = .5, ["from"] = Frame.REF_WAYPOINT_CONTEXT_VFX:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Translate({ ["frame"] = Frame.REF_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .25, ["from"] = 0, ["to"] = 5, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .25, ["from"] = Frame.REF_WAYPOINT_FOOTER_LAYOUT:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WAYPOINT_MARKER, ["duration"] = .375, ["from"] = Frame.REF_WAYPOINT_MARKER:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Scale({ ["frame"] = Frame.REF_WAYPOINT_MARKER, ["duration"] = .375, ["from"] = Frame.REF_WAYPOINT_MARKER:GetScale(), ["to"] = .25, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Waypoint:HideWithAnimation_StopEvent(id) end })
					end

					--------------------------------

					if skipAnimation then
						Frame_Waypoint:Hide()

						--------------------------------

						if chain.onFinish.variable then
							chain.onFinish.variable()
						end
					else
						addon.C.Libraries.AceTimer:ScheduleTimer(function()
							if not Frame_Waypoint:HideWithAnimation_StopEvent(id) then
								Frame_Waypoint:Hide()

								--------------------------------

								if chain.onFinish.variable then
									chain.onFinish.variable()
								end
							end
						end, .25)
					end

					---------------------------------

					return { onFinish = chain.onFinish.set }
				end
			end

			do -- FOOTER
				local SubtextFrame = Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME
				local Subtext = Frame.REF_WAYPOINT_FOOTER_LAYOUT_SUBTEXT

				--------------------------------

				do -- SHOW
					function SubtextFrame:ShowWithAnimation_StopEvent()
						return SubtextFrame.hidden
					end

					function SubtextFrame:ShowWithAnimation(skipAnimation)
						if not SubtextFrame.hidden then
							return
						end
						SubtextFrame.hidden = false
						SubtextFrame:Show()

						--------------------------------

						if skipAnimation then
							SubtextFrame:SetAlpha(1)
							Subtext:SetPoint("CENTER", Subtext:GetParent(), 0, 0)
						else
							addon.C.Animation:CancelAll(SubtextFrame)

							--------------------------------

							addon.C.Animation:Alpha({ ["frame"] = SubtextFrame, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = SubtextFrame.ShowWithAnimation_StopEvent })
							addon.C.Animation:Translate({ ["frame"] = Subtext, ["duration"] = 1, ["from"] = 15, ["to"] = 0, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = SubtextFrame.ShowWithAnimation_StopEvent })
						end
					end
				end

				do -- HIDE
					function SubtextFrame:HideWithAnimation_StopEvent()
						return not SubtextFrame.hidden
					end

					function SubtextFrame:HideWithAnimation(skipAnimation)
						if SubtextFrame.hidden then
							return
						end
						SubtextFrame.hidden = true

						C_Timer.After(.5, function()
							if SubtextFrame.hidden then
								SubtextFrame:Hide()
							end
						end)

						--------------------------------

						if skipAnimation then
							SubtextFrame:SetAlpha(0)
							Subtext:SetPoint("CENTER", Subtext:GetParent(), 0, 7.5)
						else
							addon.C.Animation:CancelAll(SubtextFrame)

							--------------------------------

							addon.C.Animation:Alpha({ ["frame"] = SubtextFrame, ["duration"] = .25, ["from"] = SubtextFrame:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = SubtextFrame.HideWithAnimation_StopEvent })
							addon.C.Animation:Translate({ ["frame"] = Subtext, ["duration"] = .75, ["from"] = 0, ["to"] = 7.5, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = SubtextFrame.HideWithAnimation_StopEvent })
						end
					end
				end
			end
		end

		do -- PINPOINT
			do -- SHOW
				function Frame_Pinpoint:ShowWithAnimation_StopEvent(id)
					return NS.Variables.Session.id ~= id
				end

				function Frame_Pinpoint:ShowWithAnimation(id, skipAnimation)
					Frame_Pinpoint.hidden = false
					Frame_Pinpoint:Show()

					--------------------------------

					if skipAnimation then
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetScale(1)
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetAlpha(1)
						Frame.REF_PINPOINT_BACKGROUND_ARROW:SetAlpha(1)
						Frame.REF_PINPOINT_FOREGROUND:SetAlpha(1)
					else
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_BACKGROUND_CONTEXT)
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_BACKGROUND_ARROW)
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_FOREGROUND)

						addon.C.Animation:Scale({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .75, ["from"] = 3, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Pinpoint:ShowWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .75, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Pinpoint:ShowWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_ARROW, ["duration"] = .75, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Pinpoint:ShowWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_FOREGROUND, ["duration"] = 1.5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Pinpoint:ShowWithAnimation_StopEvent(id) end })
					end

					Frame.REF_PINPOINT_BACKGROUND_CONTEXT:ShowWithAnimation(skipAnimation)
					Frame.REF_PINPOINT_BACKGROUND_ARROW.Animation_Playback_Loop:Start()
				end
			end

			do -- HIDE
				function Frame_Pinpoint:HideWithAnimation_StopEvent(id)
					return NS.Variables.Session.id ~= id
				end

				function Frame_Pinpoint:HideWithAnimation(id, skipAnimation)
					Frame_Pinpoint.hidden = true

					--------------------------------

					local chain = addon.C.API.Util:AddMethodChain({ "onFinish" })

					--------------------------------

					if skipAnimation then
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetScale(1.125)
						Frame.REF_PINPOINT_BACKGROUND_CONTEXT:SetAlpha(0)
						Frame.REF_PINPOINT_BACKGROUND_ARROW:SetAlpha(0)
						Frame.REF_PINPOINT_FOREGROUND:SetAlpha(0)
					else
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_BACKGROUND_CONTEXT)
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_BACKGROUND_ARROW)
						addon.C.Animation:CancelAll(Frame.REF_PINPOINT_FOREGROUND)

						addon.C.Animation:Scale({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .5, ["from"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT:GetScale(), ["to"] = 2, ["ease"] = "EaseQuart_InOut", ["stopEvent"] = function() return Frame_Pinpoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .5, ["from"] = Frame.REF_PINPOINT_BACKGROUND_CONTEXT:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_Pinpoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_BACKGROUND_ARROW, ["duration"] = .5, ["from"] = Frame.REF_PINPOINT_BACKGROUND_ARROW:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_Pinpoint:HideWithAnimation_StopEvent(id) end })
						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_PINPOINT_FOREGROUND, ["duration"] = .125, ["from"] = Frame.REF_PINPOINT_FOREGROUND:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_Pinpoint:HideWithAnimation_StopEvent(id) end })
					end

					--------------------------------

					if skipAnimation then
						Frame_Pinpoint:Hide()

						--------------------------------

						if chain.onFinish.variable then
							chain.onFinish.variable()
						end
					else
						addon.C.Libraries.AceTimer:ScheduleTimer(function()
							if not Frame_Pinpoint:HideWithAnimation_StopEvent(id) then
								Frame_Pinpoint:Hide()

								--------------------------------

								if chain.onFinish.variable then
									chain.onFinish.variable()
								end
							end
						end, .25)
					end

					---------------------------------

					return { onFinish = chain.onFinish.set }
				end
			end
		end
	end

	--------------------------------
	-- SETTINGS
	--------------------------------

	do
		local function C_CONFIG_WS_TYPE()
			Callback:Waypoint_Reset(true)
		end

		local function C_CONFIG_APPEARANCE_UPDATE()
			C_Timer.After(.075, function() Callback:APP_Set() end)
		end

		C_CONFIG_WS_TYPE()
		C_CONFIG_APPEARANCE_UPDATE()

		--------------------------------

		CallbackRegistry:Add("C_CONFIG_WS_TYPE", C_CONFIG_WS_TYPE)
		CallbackRegistry:Add("C_CONFIG_APPEARANCE_UPDATE", C_CONFIG_APPEARANCE_UPDATE)
	end

	--------------------------------
	-- EVENTS
	--------------------------------

	do
		local maxUpdatePerSecond = 30
		local updateInterval = 1 / maxUpdatePerSecond
		local updateTimer = 0

		local _ = CreateFrame("Frame")
		_:RegisterEvent("SUPER_TRACKING_CHANGED")
		_:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
		_:SetScript("OnUpdate", function(self, elapsed)
			updateTimer = updateTimer + elapsed
			if updateTimer >= updateInterval then
				updateTimer = 0

				--------------------------------

				Callback:Update(false)
			end
		end)
		_:SetScript("OnEvent", function(_, event)
			if event == "SUPER_TRACKING_CHANGED" then
				Callback:Update(true)
			end
		end)
	end
end
