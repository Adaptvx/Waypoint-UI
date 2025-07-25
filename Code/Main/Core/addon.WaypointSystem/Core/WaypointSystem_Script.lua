---@class addon
local addon = select(2, ...)
local CallbackRegistry = addon.C.CallbackRegistry.Script
local PrefabRegistry = addon.C.PrefabRegistry.Script
local TagManager = addon.C.TagManager.Script
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
	local Frame_World = Frame.REF_WORLD
	local Frame_World_Waypoint = Frame.REF_WORLD_WAYPOINT
	local Frame_World_Pinpoint = Frame.REF_WORLD_PINPOINT
	local Frame_Navigator = Frame.REF_NAVIGATOR
	local Frame_Navigator_Arrow = Frame.REF_NAVIGATOR_ARROW
	local Frame_BlizzardWaypoint = SuperTrackedFrame
	local Callback = NS.Script; NS.Script = Callback

	Frame.navFrame = {}
	local function GetNavFrame()
		Frame.navFrame["frame"] = C_Navigation.GetFrame()
	end

	--------------------------------
	-- FUNCTIONS (FRAME)
	--------------------------------

	do
		do -- NAV
			function Frame.navFrame:GetDistanceFromEdge()
				if not Frame.navFrame.frame then return end
				if not Frame.navFrame.frame:GetCenter() then return end

				--------------------------------

				local screenLeft, screenTop, screenRight, screenBottom = 0, GetScreenHeight(), GetScreenWidth(), 0

				local frameX, frameY = Frame.navFrame.frame:GetCenter()
				local deltaLeft = (frameX - screenLeft) / GetScreenWidth()
				local deltaTop = (screenTop - frameY) / GetScreenHeight()
				local deltaRight = (screenRight - frameX) / GetScreenWidth()
				local deltaBottom = (frameY - screenBottom) / GetScreenHeight()

				local resultMinDistance = math.min(deltaLeft, deltaRight, deltaTop, deltaBottom)
				return resultMinDistance
			end

			function Frame.navFrame:GetNormalizedDistanceFromCursor()
				if not Frame.navFrame.frame then return end
				if not Frame.navFrame.frame:GetCenter() then return end

				--------------------------------

				local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
				local aspectRatio = screenWidth / screenHeight

				local frameScale = Frame.navFrame.frame:GetEffectiveScale()
				local frameX, frameY = Frame.navFrame.frame:GetCenter(); frameX = frameX * frameScale; frameY = frameY * frameScale
				local deltaX, deltaY = addon.C.API.FrameUtil:GetMouseDelta(frameX, frameY)

				local resultX, resultY = deltaX / aspectRatio, deltaY / aspectRatio
				local resultDistanceTotal = math.abs(resultX) + math.abs(resultY)
				return resultDistanceTotal
			end

			function Frame.navFrame:GetDistanceFromCenter()
				if not Frame.navFrame.frame then return end
				if not Frame.navFrame.frame:GetCenter() then return end

				--------------------------------

				local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
				local screenCenterX, screenCenterY = (screenWidth / 2), (screenHeight / 2) - (screenHeight * .1)

				local frameX, frameY = Frame.navFrame.frame:GetCenter()
				local deltaX = math.abs(frameX - screenCenterX)
				local deltaY = math.abs(frameY - screenCenterY)
				local resultDistanceTotal = deltaX + deltaY

				return resultDistanceTotal
			end
		end

		do -- WAYPOINT
			do -- SET
				function Frame_World_Waypoint:SetText(text, subtext)
					if text then
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_TEXT_FRAME:Show()
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_TEXT:SetText(text)
					else
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_TEXT_FRAME:Hide()
					end

					if subtext then
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME:ShowWithAnimation()
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT:SetText(subtext)
					else
						Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME:HideWithAnimation()
					end

					Frame.LGS_FOOTER()
				end

				function Frame_World_Waypoint:Context_SetOpacity(opacity)
					Frame.REF_WORLD_WAYPOINT_CONTEXT:SetOpacity(opacity)
				end

				function Frame_World_Waypoint:Context_SetImage(image)
					Frame.REF_WORLD_WAYPOINT_CONTEXT:SetInfo(image)
				end

				function Frame_World_Waypoint:Context_SetVFX(type, tintColor)
					if type == "Wave" then
						Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX_WAVE.Animation_Playback_Loop:Start()
						Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX_WAVE_BACKGROUND_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					else
						Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX_WAVE:Hide()
					end
				end

				--------------------------------

				function Frame_World_Waypoint:APP_SetTint(tintColor)
					Frame.REF_WORLD_WAYPOINT_MARKER_PULSE:SetTint(tintColor)
					Frame.REF_WORLD_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_TEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
				end

				function Frame_World_Waypoint:APP_Context_SetTint(tintColor)
					Frame.REF_WORLD_WAYPOINT_CONTEXT:SetTint(tintColor)
				end

				function Frame_World_Waypoint:APP_Context_SetRecolor(recolor)
					if recolor then
						Frame.REF_WORLD_WAYPOINT_CONTEXT:Recolor()
					else
						Frame.REF_WORLD_WAYPOINT_CONTEXT:Decolor()
					end
				end

				function Frame_World_Waypoint:APP_Beam_Set(visible, opacity)
					Frame.REF_WORLD_WAYPOINT_MARKER_CONTENT:SetShown(visible)
					Frame.REF_WORLD_WAYPOINT_MARKER_CONTENT:SetAlpha(opacity)
				end

				function Frame_World_Waypoint:APP_DistanceText_Set(visible, opacity, scale)
					Frame.REF_WORLD_WAYPOINT_FOOTER:SetShown(visible)
					Frame.REF_WORLD_WAYPOINT_FOOTER:SetAlpha(opacity)
					Frame.REF_WORLD_WAYPOINT_FOOTER:SetScale(scale)
				end

				function Frame_World_Waypoint:APP_SetScale(scale)
					Frame.REF_WORLD_WAYPOINT:SetScale(scale)
				end
			end

			do -- LOGIC
				local lastMouseOverAlpha = nil
				local lastCenterDistanceAlpha = nil

				function Frame_World_Waypoint:APP_MouseOverAlpha_Update()
					local distance = Frame.navFrame:GetNormalizedDistanceFromCursor() or 1000
					local minDistance = 7.5 * Frame_World_Waypoint:GetEffectiveScale()
					local maxDistance = 15 * Frame_World_Waypoint:GetEffectiveScale()
					local minAlpha = .125

					distance = math.min(distance, maxDistance)
					distance = math.max(distance, minDistance)

					local alpha = ((distance - minDistance) / (maxDistance - minDistance)) * (1 - minAlpha) + minAlpha

					--------------------------------

					if lastMouseOverAlpha ~= alpha then
						lastMouseOverAlpha = alpha

						--------------------------------

						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTENT, ["duration"] = .5, ["from"] = Frame.REF_WORLD_WAYPOINT_CONTENT:GetAlpha(), ["to"] = alpha, ["ease"] = "EaseExpo_Out", ["stopEvent"] = nil })
					end
				end

				function Frame_World_Waypoint:APP_CenterDistanceAlpha_Update()
					local distance = Frame.navFrame:GetDistanceFromCenter() or 1000
					local minDistance = 75 * Frame_World_Waypoint:GetEffectiveScale()
					local maxDistance = 150 * Frame_World_Waypoint:GetEffectiveScale()
					local minAlpha = .25

					distance = math.min(distance, maxDistance)
					distance = math.max(distance, minDistance)

					local alpha = ((distance - minDistance) / (maxDistance - minDistance)) * (1 - minAlpha) + minAlpha

					--------------------------------

					if lastCenterDistanceAlpha ~= alpha then
						lastCenterDistanceAlpha = alpha

						--------------------------------

						addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT, ["duration"] = .5, ["from"] = Frame.REF_WORLD_WAYPOINT_CONTEXT:GetAlpha(), ["to"] = alpha, ["ease"] = "EaseExpo_Out", ["stopEvent"] = nil })
					end
				end

				function Frame_World_Waypoint:APP_MouseOverAlpha_Reset()
					if Frame.REF_WORLD_WAYPOINT_CONTENT:GetAlpha() < 1 then
						Frame.REF_WORLD_WAYPOINT_CONTENT:SetAlpha(1)
					end
				end

				function Frame_World_Waypoint:APP_CenterDistanceAlpha_Reset()
					if Frame.REF_WORLD_WAYPOINT_CONTEXT:GetAlpha() < 1 then
						Frame.REF_WORLD_WAYPOINT_CONTEXT:SetAlpha(1)
					end
				end
			end
		end

		do -- PINPOINT
			do -- SET
				function Frame_World_Pinpoint:SetText(text)
					if text and text ~= Frame.REF_WORLD_PINPOINT_FOREGROUND_TEXT:GetText() then
						Frame.REF_WORLD_PINPOINT_FOREGROUND_TEXT:SetText(text)
					end

					--------------------------------

					Frame.REF_WORLD_PINPOINT_FOREGROUND:SetShown(text ~= nil)
				end

				function Frame_World_Pinpoint:Context_SetOpacity(opacity)
					Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetOpacity(opacity)
				end

				function Frame_World_Pinpoint:Context_SetImage(image)
					Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetInfo(image)
				end

				--------------------------------

				function Frame_World_Pinpoint:APP_SetTint(tintColor)
					Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW:SetTint(tintColor)
					Frame.REF_WORLD_PINPOINT_FOREGROUND_BACKGROUND_BORDER_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
					Frame.REF_WORLD_PINPOINT_FOREGROUND_TEXT:SetTextColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
				end

				function Frame_World_Pinpoint:APP_Context_SetTint(tintColor)
					Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetTint(tintColor)
				end

				function Frame_World_Pinpoint:APP_Context_SetRecolor(recolor)
					if recolor then
						Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:Recolor()
					else
						Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:Decolor()
					end
				end

				function Frame_World_Pinpoint:APP_SetScale(scale)
					Frame_World_Pinpoint:SetScale(scale)
				end
			end
		end

		do -- NAVIGATOR
			do -- SET
				function Frame_Navigator_Arrow:Context_SetOpacity(opacity)
					Frame.REF_NAVIGATOR_ARROW_CONTEXT:SetOpacity(opacity)
				end

				function Frame_Navigator_Arrow:Context_SetImage(image)
					Frame.REF_NAVIGATOR_ARROW_CONTEXT:SetInfo(image)
				end

				--------------------------------

				function Frame_Navigator_Arrow:APP_SetTint(tintColor)
					Frame.REF_NAVIGATOR_ARROW_INDICATOR_BACKGROUND_TEXTURE:SetVertexColor(tintColor.r, tintColor.g, tintColor.b, tintColor.a)
				end

				function Frame_Navigator_Arrow:APP_Context_SetTint(tintColor)
					Frame.REF_NAVIGATOR_ARROW_CONTEXT:SetTint(tintColor)
				end

				function Frame_Navigator_Arrow:APP_Context_SetRecolor(recolor)
					if recolor then
						Frame.REF_NAVIGATOR_ARROW_CONTEXT:Recolor()
					else
						Frame.REF_NAVIGATOR_ARROW_CONTEXT:Decolor()
					end
				end

				function Frame_Navigator_Arrow:APP_SetScale(scale)
					Frame.REF_NAVIGATOR_ARROW_CONTENT:SetScale(scale)
				end

				function Frame_Navigator_Arrow:APP_SetOpacity(opacity)
					Frame.REF_NAVIGATOR_ARROW_CONTENT:SetAlpha(opacity)
				end

				function Frame_Navigator_Arrow:APP_SetVisibility(visible)
					Frame.REF_NAVIGATOR_ARROW_CONTENT:SetShown(visible)
				end
			end

			do -- LOGIC
				local UP_VECTOR = CreateVector2D(0, 1)

				local function GetCenterScreenPoint()
					local centerX, centerY = WorldFrame:GetCenter()
					local scale = UIParent:GetEffectiveScale() or 1
					return centerX / scale, centerY / scale
				end

				function Frame_Navigator_Arrow:Nav_ClampElliptical()
					if not Frame.navFrame.frame then return end

					--------------------------------

					local centerX, centerY = GetCenterScreenPoint()
					local navX, navY = Frame.navFrame.frame:GetCenter()

					local pX = navX - centerX
					local pY = navY - centerY
					local denominator = math.sqrt(Frame_Navigator_Arrow.majorAxisSquared * pY * pY + Frame_Navigator_Arrow.minorAxisSquared * pX * pX)

					if denominator ~= 0 then
						local ratio = Frame_Navigator_Arrow.axesMultiplied / denominator
						local intersectionX = pX * ratio
						local intersectionY = pY * ratio

						Frame_Navigator_Arrow:ClearAllPoints()
						Frame_Navigator_Arrow:SetPoint("CENTER", WorldFrame, "CENTER", intersectionX, intersectionY)
					end
				end

				function Frame_Navigator_Arrow:Nav_UpdatePosition()
					Frame_Navigator_Arrow:Nav_ClampElliptical()
				end

				function Frame_Navigator_Arrow:Nav_UpdateIndicator()
					if not Frame.navFrame.frame then return end

					--------------------------------

					local centerScreenX, centerScreenY = GetCenterScreenPoint()
					local indicatorX, indicatorY = Frame_Navigator_Arrow:GetCenter()

					local indicatorVec = Frame_Navigator_Arrow.indicatorVec
					indicatorVec:SetXY(indicatorX - centerScreenX, indicatorY - centerScreenY)

					local angle = Vector2D_CalculateAngleBetween(indicatorVec.x, indicatorVec.y, UP_VECTOR.x, UP_VECTOR.y)
					Frame.REF_NAVIGATOR_ARROW_INDICATOR_BACKGROUND_TEXTURE:SetRotation(-angle)
				end

				function Frame_Navigator_Arrow:Nav_SetInfo(major, minor)
					Frame_Navigator_Arrow.mouseToNavVec = CreateVector2D(0, 0)
					Frame_Navigator_Arrow.indicatorVec = CreateVector2D(0, 0)
					Frame_Navigator_Arrow.circularVec = CreateVector2D(0, 0)

					Frame_Navigator_Arrow.majorAxis = major
					Frame_Navigator_Arrow.minorAxis = minor
					Frame_Navigator_Arrow.majorAxisSquared = Frame_Navigator_Arrow.majorAxis * Frame_Navigator_Arrow.majorAxis
					Frame_Navigator_Arrow.minorAxisSquared = Frame_Navigator_Arrow.minorAxis * Frame_Navigator_Arrow.minorAxis
					Frame_Navigator_Arrow.axesMultiplied = Frame_Navigator_Arrow.majorAxis * Frame_Navigator_Arrow.minorAxis
				end

				function Frame_Navigator_Arrow:Nav_UpdateVariables()
					local zoom = GetCameraZoom()
					local baseZoom = 35
					local baseMajor, baseMinor = 200, 100
					local major, minor = math.min(baseMajor * (baseZoom / zoom), 500), math.min(baseMinor * (baseZoom / zoom), 500)

					Frame_Navigator_Arrow:Nav_SetInfo(major, minor)
				end

				Frame.REF_NAVIGATOR_ARROW_CONTENT:SetScript("OnUpdate", function()
					Frame_Navigator_Arrow:Nav_UpdateVariables()
					Frame_Navigator_Arrow:Nav_UpdatePosition()
					Frame_Navigator_Arrow:Nav_UpdateIndicator()
				end)
			end
		end
	end

	--------------------------------
	-- FUNCTIONS (MAIN)
	--------------------------------

	do
		local IsWaypoint = false
		local IsPinpoint = false
		local IsNavigator = false

		--------------------------------

		local C_WS_TYPE
		local C_WS_DISTANCE_TRANSITION
		local C_WS_DISTANCE_HIDE
		local C_WS_DISTANCE_TEXT_TYPE
		local C_WS_PINPOINT_INFO
		local C_WS_PINPOINT_INFO_EXTENDED
		local C_WS_NAVIGATOR
		local C_APP_WAYPOINT_SCALE
		local C_APP_WAYPOINT_SCALE_MIN
		local C_APP_WAYPOINT_SCALE_MAX
		local C_APP_WAYPOINT_BEAM
		local C_APP_WAYPOINT_BEAM_ALPHA
		local C_APP_WAYPOINT_DISTANCE_TEXT
		local C_APP_WAYPOINT_DISTANCE_TEXT_SCALE
		local C_APP_WAYPOINT_DISTANCE_TEXT_ALPHA
		local C_APP_PINPOINT_SCALE
		local C_APP_NAVIGATOR_SCALE
		local C_APP_NAVIGATOR_ALPHA
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
		local C_AUDIO_CUSTOM
		local C_AUDIO_CUSTOM_WAYPOINT_SHOW
		local C_AUDIO_CUSTOM_PINPOINT_SHOW
		local C_PREF_METRIC
		local CVAR_FOV
		local CVAR_ACTIONCAM_SHOULDER
		local CVAR_ACTIONCAM_PITCH

		do
			local function UpdateReferences()
				C_WS_TYPE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_TYPE
				C_WS_DISTANCE_TRANSITION = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_TRANSITION
				C_WS_DISTANCE_HIDE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_HIDE
				C_WS_DISTANCE_TEXT_TYPE = addon.C.Database.Variables.DB_GLOBAL.profile.WS_DISTANCE_TEXT_TYPE
				C_WS_PINPOINT_INFO = addon.C.Database.Variables.DB_GLOBAL.profile.WS_PINPOINT_INFO
				C_WS_PINPOINT_INFO_EXTENDED = addon.C.Database.Variables.DB_GLOBAL.profile.WS_PINPOINT_INFO_EXTENDED
				C_WS_NAVIGATOR = addon.C.Database.Variables.DB_GLOBAL.profile.WS_NAVIGATOR
				C_APP_WAYPOINT_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_SCALE
				C_APP_WAYPOINT_SCALE_MIN = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_SCALE_MIN
				C_APP_WAYPOINT_SCALE_MAX = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_SCALE_MAX
				C_APP_WAYPOINT_BEAM = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_BEAM
				C_APP_WAYPOINT_BEAM_ALPHA = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_BEAM_ALPHA
				C_APP_WAYPOINT_DISTANCE_TEXT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_DISTANCE_TEXT
				C_APP_WAYPOINT_DISTANCE_TEXT_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_DISTANCE_TEXT_SCALE
				C_APP_WAYPOINT_DISTANCE_TEXT_ALPHA = addon.C.Database.Variables.DB_GLOBAL.profile.APP_WAYPOINT_DISTANCE_TEXT_ALPHA
				C_APP_PINPOINT_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_PINPOINT_SCALE
				C_APP_NAVIGATOR_SCALE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_NAVIGATOR_SCALE
				C_APP_NAVIGATOR_ALPHA = addon.C.Database.Variables.DB_GLOBAL.profile.APP_NAVIGATOR_ALPHA
				C_APP_COLOR = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR
				C_APP_COLOR_QUEST_INCOMPLETE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_INCOMPLETE_TINT
				C_APP_COLOR_QUEST_COMPLETE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_TINT
				C_APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_REPEATABLE_TINT
				C_APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_IMPORTANT_TINT
				C_APP_COLOR_NEUTRAL_TINT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_NEUTRAL_TINT
				C_APP_COLOR_QUEST_INCOMPLETE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_INCOMPLETE
				C_APP_COLOR_QUEST_COMPLETE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE
				C_APP_COLOR_QUEST_COMPLETE_REPEATABLE = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_REPEATABLE
				C_APP_COLOR_QUEST_COMPLETE_IMPORTANT = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_QUEST_COMPLETE_IMPORTANT
				C_APP_COLOR_NEUTRAL = addon.C.Database.Variables.DB_GLOBAL.profile.APP_COLOR_NEUTRAL
				C_AUDIO_CUSTOM = addon.C.Database.Variables.DB_GLOBAL.profile.AUDIO_CUSTOM
				C_AUDIO_CUSTOM_WAYPOINT_SHOW = addon.C.Database.Variables.DB_GLOBAL.profile.AUDIO_CUSTOM_WAYPOINT_SHOW
				C_AUDIO_CUSTOM_PINPOINT_SHOW = addon.C.Database.Variables.DB_GLOBAL.profile.AUDIO_CUSTOM_PINPOINT_SHOW
				C_PREF_METRIC = addon.C.Database.Variables.DB_GLOBAL.profile.PREF_METRIC
				CVAR_FOV = tonumber(GetCVar("cameraFov"))
				CVAR_ACTIONCAM_SHOULDER = tonumber(GetCVar("test_cameraOverShoulder"))
				CVAR_ACTIONCAM_PITCH = tonumber(GetCVar("test_cameraDynamicPitch"))
			end

			UpdateReferences()
			CallbackRegistry:Add("C_CONFIG_UPDATE", UpdateReferences)
			CallbackRegistry:Add("C_CONFIG_APPEARANCE_UPDATE", UpdateReferences)
			CallbackRegistry:Add("C_CONFIG_AUDIO_UPDATE", UpdateReferences)
			CallbackRegistry:Add("EVENT_CVAR_UPDATE", UpdateReferences)
		end

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
					distance = 0,
				}
			end

			local function ArrivalTime_Update()
				local distance = C_Navigation.GetDistance()
				local delta = session.distance - distance

				--------------------------------

				session.distance = distance

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
						texture.path = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/map-pin-way.png"
					elseif pinInfo.pinType == Enum.SuperTrackingType.UserWaypoint then
						texture.type = "TEXTURE"
						texture.path = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/map-pin-default.png"
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
						-- texture.path = contextIcon and addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/" .. contextIcon .. ".png" or addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/quest-available.png"

						-- --------------------------------

						texture.type = "TEXTURE"
						texture.path = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/quest-available.png"
					else
						texture.type = "TEXTURE"
						texture.path = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/map-pin-default.png"
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
							texture = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/redirect-repeatable.png"
						elseif questClassification == Enum.QuestClassification.Important then
							texture = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/redirect-important.png"
						else
							texture = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/redirect-default.png"
						end
					else
						texture = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/redirect-incomplete.png"
					end
				else
					texture = addon.CS:GetAddonPath() .. "Art/Elements/ContextIcons/redirect-neutral.png"
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
				local SUPER_TRACK_INFO = Callback:GetSuperTrackingInfo()
				local questInfo = Callback:GetQuestInfo()

				--------------------------------

				local state = nil

				local distance = C_Navigation.GetDistance()
				local isInAreaPOI = Callback:GetInQuestAreaPOI()
				local isQuest = (questInfo ~= nil)
				local isValid = (SUPER_TRACK_INFO.valid)
				local isDefault = (SUPER_TRACK_INFO.texture == "3308452")
				local isRangeProximity = (distance < C_WS_DISTANCE_TRANSITION)
				local isRangeValid = (distance > C_WS_DISTANCE_HIDE)

				if (isInAreaPOI) or (not isRangeValid) or (not isValid) then
					if isInAreaPOI then
						state = "INVALID_RANGE" -- state = "QUEST_AREA_POI"
					elseif not isRangeValid then
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

			function Callback:GetInQuestAreaPOI()
				local result = false

				--------------------------------

				local questID = C_SuperTrack.GetSuperTrackedQuestID()
				result = (questID) and (C_Minimap.IsInsideQuestBlob(questID)) or false

				--------------------------------

				return result
			end

			function Callback:GetRedirectInfo()
				local result = {}

				--------------------------------

				local mapID = C_Map.GetBestMapForUnit("player")
				if mapID then
					local waypointX, waypointY, waypointText = C_SuperTrack.GetNextWaypointForMap(mapID)

					result = {
						valid = (waypointText ~= nil),
						x = waypointX,
						y = waypointY,
						text = waypointText
					}
				else
					result = {
						valid = false,
						x = nil,
						y = nil,
						text = nil,
					}
				end

				--------------------------------

				return result
			end

			--------------------------------

			local clampThreshold = .125

			function Callback:GetIsClamped()
				if not Frame.navFrame.frame then return end

				local resultMinDistance = Frame.navFrame:GetDistanceFromEdge()
				local isClamped = (resultMinDistance < clampThreshold)
				local newClamped = NS.Variables.Session.isClamped ~= isClamped

				return isClamped, newClamped
			end
		end

		do -- SET
			function Callback:Waypoint_Reset(keepElementState)
				if not keepElementState then
					Frame_World_Waypoint.hidden = true
					Frame_World_Waypoint:Hide()

					Frame_World_Pinpoint.hidden = true
					Frame_World_Pinpoint:Hide()
				end

				--------------------------------

				NS.Variables.ArrivalTime = nil
				NS.Variables.Session = {}
			end

			function Callback:Blizzard_Hide()
				Frame_BlizzardWaypoint:Hide()
			end

			function Callback:Blizzard_Show()
				Frame_BlizzardWaypoint:Show()
			end

			function Callback:World_Hide()
				local isSuperTracking = C_SuperTrack.IsSuperTrackingAnything()
				Frame_World:HideWithAnimation()
			end

			function Callback:World_Show()
				Frame_World_Waypoint:SetPoint("CENTER", Frame.navFrame.frame)
				Frame_World_Pinpoint:SetPoint("BOTTOM", Frame.navFrame.frame, "TOP", 0, 75)

				--------------------------------

				local isSuperTracking = C_SuperTrack.IsSuperTrackingAnything()
				Frame_World:ShowWithAnimation()
			end

			function Callback:Navigator_Hide()
				local isSuperTracking = C_SuperTrack.IsSuperTrackingAnything()
				Frame_Navigator:HideWithAnimation()
			end

			function Callback:Navigator_Show()
				local isSuperTracking = C_SuperTrack.IsSuperTrackingAnything()
				local state, isNewState = Callback:GetCurrentState()

				if state == "INVALID_RANGE" then
					Frame_Navigator:HideWithAnimation(true)
				else
					Frame_Navigator:ShowWithAnimation()
				end
			end
		end

		do -- APPEARANCE
			function Callback:APP_GetColor(questID)
				local result = nil

				--------------------------------

				local trackingType = Callback:GetTrackingType(questID)

				local COLOR_QUEST_INCOMPLETE = C_APP_COLOR and C_APP_COLOR_QUEST_INCOMPLETE or addon.CS:GetSharedColor().RGB_PING_QUEST_NEUTRAL
				local COLOR_QUEST_COMPLETE = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE or addon.CS:GetSharedColor().RGB_PING_QUEST_NORMAL
				local COLOR_QUEST_COMPLETE_REPEATABLE = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_REPEATABLE or addon.CS:GetSharedColor().RGB_PING_QUEST_REPEATABLE
				local COLOR_QUEST_COMPLETE_IMPORTANT = C_APP_COLOR and C_APP_COLOR_QUEST_COMPLETE_IMPORTANT or addon.CS:GetSharedColor().RGB_PING_QUEST_IMPORTANT
				local COLOR_NEUTRAL = C_APP_COLOR and C_APP_COLOR_NEUTRAL or addon.CS:GetSharedColor().RGB_PING_NEUTRAL

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
					result = { r = addon.CS:GetSharedColor().RGB_WHITE.r, g = addon.CS:GetSharedColor().RGB_WHITE.g, b = addon.CS:GetSharedColor().RGB_WHITE.b, a = 1 }
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

				Frame_World_Waypoint:APP_SetTint(appearanceInfo.color)
				Frame_World_Waypoint:APP_Context_SetTint(appearanceInfo.color)
				Frame_World_Waypoint:APP_Context_SetRecolor(appearanceInfo.recolorContext)
				Frame_World_Waypoint:APP_Beam_Set(C_APP_WAYPOINT_BEAM, C_APP_WAYPOINT_BEAM_ALPHA)
				Frame_World_Waypoint:APP_SetScale(C_APP_WAYPOINT_SCALE)
				Frame_World_Waypoint:APP_DistanceText_Set(C_APP_WAYPOINT_DISTANCE_TEXT, C_APP_WAYPOINT_DISTANCE_TEXT_ALPHA, C_APP_WAYPOINT_DISTANCE_TEXT_SCALE * .75)

				Frame_World_Pinpoint:APP_SetTint(appearanceInfo.color)
				Frame_World_Pinpoint:APP_Context_SetTint(appearanceInfo.color)
				Frame_World_Pinpoint:APP_Context_SetRecolor(appearanceInfo.recolorContext)
				Frame_World_Pinpoint:APP_SetScale(C_APP_PINPOINT_SCALE)

				Frame_Navigator_Arrow:APP_SetTint(appearanceInfo.color)
				Frame_Navigator_Arrow:APP_Context_SetTint(appearanceInfo.color)
				Frame_Navigator_Arrow:APP_Context_SetRecolor(appearanceInfo.recolorContext)
				Frame_Navigator_Arrow:APP_SetScale(C_APP_NAVIGATOR_SCALE)
				Frame_Navigator_Arrow:APP_SetOpacity(C_APP_NAVIGATOR_ALPHA)
				Frame_Navigator_Arrow:APP_SetVisibility(C_WS_NAVIGATOR)
			end
		end

		do -- LOGIC
			local Transition = {}

			function Transition:Pinpoint(id)
				if not Frame_World_Waypoint.hidden then
					Frame_World_Waypoint:HideWithAnimation(id).onFinish(function()
						Frame_World_Pinpoint:ShowWithAnimation(id, false)
					end)

					--------------------------------

					local audioPath = (C_AUDIO_CUSTOM and C_AUDIO_CUSTOM_PINPOINT_SHOW or nil) or (not C_AUDIO_CUSTOM and SOUNDKIT.UI_RUNECARVING_CLOSE_MAIN_WINDOW)
					addon.C.Sound.Script:PlaySound(audioPath)
				else
					Frame_World_Pinpoint:ShowWithAnimation(id, false)
				end

				--------------------------------

				IsWaypoint = false
				IsPinpoint = true
			end

			function Transition:Waypoint(id)
				if not Frame_World_Pinpoint.hidden then
					Frame_World_Pinpoint:HideWithAnimation(id).onFinish(function()
						Frame_World_Waypoint:ShowWithAnimation(id, false)
					end)


					--------------------------------

					local audioPath = (C_AUDIO_CUSTOM and C_AUDIO_CUSTOM_WAYPOINT_SHOW or nil) or (not C_AUDIO_CUSTOM and SOUNDKIT.UI_RUNECARVING_OPEN_MAIN_WINDOW)
					addon.C.Sound.Script:PlaySound(audioPath)
				else
					Frame_World_Waypoint:ShowWithAnimation(id, false)
				end

				--------------------------------

				IsWaypoint = true
				IsPinpoint = false
			end

			function Transition:OnlyPinpoint(id)
				if Frame_World_Pinpoint.hidden then
					Frame_World_Pinpoint:ShowWithAnimation(id, false)
				end

				if not Frame_World_Waypoint.hidden then
					Frame_World_Waypoint:HideWithAnimation(id, false)

					--------------------------------

					local audioPath = (C_AUDIO_CUSTOM and C_AUDIO_CUSTOM_PINPOINT_SHOW or nil) or (not C_AUDIO_CUSTOM and SOUNDKIT.UI_RUNECARVING_CLOSE_MAIN_WINDOW)
					addon.C.Sound.Script:PlaySound(audioPath)
				end

				--------------------------------

				IsWaypoint = false
				IsPinpoint = true
			end

			function Transition:OnlyWaypoint(id)
				if not Frame_World_Pinpoint.hidden then
					Frame_World_Pinpoint:HideWithAnimation(id, false)
				end

				if Frame_World_Waypoint.hidden then
					Frame_World_Waypoint:ShowWithAnimation(id, false)

					--------------------------------

					local audioPath = (C_AUDIO_CUSTOM and C_AUDIO_CUSTOM_WAYPOINT_SHOW or nil) or (not C_AUDIO_CUSTOM and SOUNDKIT.UI_RUNECARVING_OPEN_MAIN_WINDOW)
					addon.C.Sound.Script:PlaySound(audioPath)
				end

				--------------------------------

				IsWaypoint = true
				IsPinpoint = false
			end

			function Transition:ShowNavigator()
				Frame_Navigator_Arrow:ShowWithAnimation()

				--------------------------------

				IsNavigator = true
			end

			function Transition:HideNavigator()
				Frame_Navigator_Arrow:HideWithAnimation()

				--------------------------------

				IsNavigator = false
			end

			--------------------------------

			local Process = {}

			function Process:GetInfo()
				local questInfo = Callback:GetQuestInfo()
				local appearanceInfo = Callback:APP_GetInfo(questInfo and questInfo.questID)
				local state = Callback:GetCurrentState()
				local id, isNewState = Callback:UpdateStateSession(state)
				local isClamped, isNewClamped = Callback:GetIsClamped()

				NS.Variables.Session = {}
				NS.Variables.Session.questInfo = questInfo
				NS.Variables.Session.appearanceInfo = appearanceInfo
				NS.Variables.Session.state = state
				NS.Variables.Session.id = id
				NS.Variables.Session.isClamped = isClamped

				return { isNewState = isNewState, isNewClamped = isNewClamped }
			end

			function Process:Update_Waypoint_Distance()
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
				Frame_World_Waypoint:SetText(text, subtext)
			end

			function Process:Update_Waypoint()
				local questInfo = NS.Variables.Session.questInfo
				local appearanceInfo = NS.Variables.Session.appearanceInfo

				--------------------------------

				if questInfo then
					local redirectInfo = Callback:GetRedirectInfo()
					local contextIcon = { type = "TEXTURE", path = questInfo.contextIcon.texture }

					if redirectInfo.valid then
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect(questInfo.questID) }
					end

					--------------------------------

					Frame_World_Waypoint:Context_SetOpacity(1)
					Frame_World_Waypoint:Context_SetImage(contextIcon)
					Frame_World_Waypoint:Context_SetVFX("Wave", appearanceInfo.color)
				else
					local redirectInfo = Callback:GetRedirectInfo()
					local contextIcon = (Callback:GetContextIcon_Pin())

					if redirectInfo.valid then
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect() }
					end

					--------------------------------

					Frame_World_Waypoint:Context_SetOpacity(1)
					Frame_World_Waypoint:Context_SetImage(contextIcon)
					Frame_World_Waypoint:Context_SetVFX("Wave", appearanceInfo.color)
				end

				--------------------------------

				Callback:APP_Set(questInfo and questInfo.questID)
			end

			function Process:Update_Pinpoint()
				local questInfo = NS.Variables.Session.questInfo

				--------------------------------

				if questInfo then
					local text = nil
					local contextIcon = { type = "TEXTURE", path = questInfo.contextIcon.texture }

					local redirectInfo = Callback:GetRedirectInfo()
					local isComplete = (questInfo.completed)
					local currentQuestObjective = ((questInfo.objectiveInfo.objectives and #questInfo.objectiveInfo.objectives >= questInfo.objectiveInfo.objectiveIndex and questInfo.objectiveInfo.objectives[questInfo.objectiveInfo.objectiveIndex].text) or "")
					local questName = (C_QuestLog.GetTitleForQuestID(questInfo.questID))

					--------------------------------

					if redirectInfo.valid then
						text = redirectInfo.text
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect(questInfo.questID) }
					else
						if isComplete then
							if C_WS_PINPOINT_INFO_EXTENDED then
								text = questName .. " — " .. L["WaypointSystem - Pinpoint - Quest - Complete"]
							else
								text = L["WaypointSystem - Pinpoint - Quest - Complete"]
							end
						elseif currentQuestObjective then
							text = currentQuestObjective
						end
					end
					if not C_WS_PINPOINT_INFO then text = nil end

					Frame_World_Pinpoint:SetText(text)
					Frame_World_Pinpoint:Context_SetOpacity(text and .25 or 1)
					Frame_World_Pinpoint:Context_SetImage(contextIcon)
				else
					local text = nil
					local contextIcon = (Callback:GetContextIcon_Pin())

					local redirectInfo = Callback:GetRedirectInfo()
					local pinInfo = (Callback:GetPinInfo())

					--------------------------------

					if redirectInfo.valid then
						text = redirectInfo.text
					else
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
							if C_WS_PINPOINT_INFO_EXTENDED then
								if pinInfo.poiInfo and pinInfo.poiInfo.description and #pinInfo.poiInfo.description > 1 then
									text = addon.C.API.Util:StripColorCodes(pinInfo.pinName) .. " — " .. addon.C.API.Util:StripColorCodes(pinInfo.poiInfo.description)
								else
									text = addon.C.API.Util:StripColorCodes(pinInfo.pinName)
								end
							else
								text = addon.C.API.Util:StripColorCodes(pinInfo.pinName)
							end
						end
					end
					if not C_WS_PINPOINT_INFO then text = nil end

					Frame_World_Pinpoint:SetText(text)
					Frame_World_Pinpoint:Context_SetOpacity(text and .25 or 1)
					Frame_World_Pinpoint:Context_SetImage(contextIcon)
				end

				--------------------------------

				Callback:APP_Set()
			end

			function Process:Update_Navigator()
				if not C_WS_NAVIGATOR then return end

				--------------------------------

				local questInfo = NS.Variables.Session.questInfo

				--------------------------------

				if questInfo then
					local redirectInfo = Callback:GetRedirectInfo()
					local contextIcon = { type = "TEXTURE", path = questInfo.contextIcon.texture }

					if redirectInfo.valid then
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect(questInfo.questID) }
					end

					--------------------------------

					Frame_Navigator_Arrow:Context_SetOpacity(1)
					Frame_Navigator_Arrow:Context_SetImage(contextIcon)
				else
					local redirectInfo = Callback:GetRedirectInfo()
					local contextIcon = (Callback:GetContextIcon_Pin())

					if redirectInfo.valid then
						contextIcon = { type = "TEXTURE", path = Callback:GetContextIcon_Redirect() }
					end

					--------------------------------

					Frame_Navigator_Arrow:Context_SetOpacity(1)
					Frame_Navigator_Arrow:Context_SetImage(contextIcon)
				end

				--------------------------------

				Callback:APP_Set(questInfo and questInfo.questID)
			end

			function Process:Update_3D()
				-- [DISTANCE SCALE]
				local DISTANCE = C_Navigation.GetDistance()
				local WAYPOINT_3D_MODIFIER_SCALE = Callback:GetDistanceScale(DISTANCE, 2000, .25, C_APP_WAYPOINT_SCALE_MIN, C_APP_WAYPOINT_SCALE_MAX, 1)
				Frame.REF_WORLD_WAYPOINT_CONTENT:SetScale(WAYPOINT_3D_MODIFIER_SCALE)

				-- [WAYPOINT BEAM ROTATION]
				-- local DISTANCE_2D = Callback:GetDistance2D()
				-- local ELEVATION = Callback:GetElevation()
				-- local WAYPOINT_3D_MODIFIER_ROTATION = Callback:GetPerspectiveRotation(SuperTrackedFrame:GetLeft() or 0, SuperTrackedFrame:GetTop() or 0, GetScreenWidth(), GetScreenHeight(), DISTANCE_2D, ELEVATION, CVAR_FOV)
				-- Frame.REF_WORLD_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetRotation(WAYPOINT_3D_MODIFIER_ROTATION)

				-- local WAYPOINT_3D_MODIFIER_ROTATION = Callback:GetPerspectiveRotation(SuperTrackedFrame:GetLeft() or 0, CVAR_FOV, DISTANCE)
				-- Frame.REF_WORLD_WAYPOINT_MARKER_BACKGROUND_TEXTURE:SetRotation(WAYPOINT_3D_MODIFIER_ROTATION)
			end

			function Process:Update_Appearance()
				if IsWaypoint then
					Frame_World_Waypoint:APP_MouseOverAlpha_Update()

					if CVAR_ACTIONCAM_SHOULDER <= 0 and CVAR_ACTIONCAM_PITCH <= 0 then
						Frame_World_Waypoint:APP_CenterDistanceAlpha_Update()
					else
						Frame_World_Waypoint:APP_CenterDistanceAlpha_Reset()
					end
				end
			end

			--------------------------------

			local Event = {}

			function Event:SuperTrackedChanged()
				Callback:Waypoint_Reset()
			end

			function Event:SuperTrackedNewPath()
				if IsWaypoint then Process:Update_Waypoint() end
				if IsPinpoint then Process:Update_Pinpoint() end
				if IsNavigator then Process:Update_Navigator() end
			end

			function Event:PlayerMoving()
				Process:Update_3D()

				--------------------------------

				if IsWaypoint then
					Process:Update_Waypoint_Distance()
				end
			end

			function Event:ClampChanged()
				if NS.Variables.Session.isClamped then
					Callback:World_Hide()
					Callback:Navigator_Show()
					Callback:Blizzard_Hide()
				else
					Callback:World_Show()
					Callback:Navigator_Hide()
					Callback:Blizzard_Hide()
				end

				--------------------------------

				if NS.Variables.Session.isClamped then
					Transition:ShowNavigator()

					--------------------------------

					CallbackRegistry:Trigger("WaypointSystem.Navigator.Show")
				else
					Transition:HideNavigator()

					--------------------------------

					CallbackRegistry:Trigger("WaypointSystem.Navigator.Hide")
				end
			end

			function Event:StateChanged()
				if NS.Variables.Session.state == "INVALID" or NS.Variables.Session.state == "INVALID_RANGE" then
					if NS.Variables.Session.state == "INVALID_RANGE" then
						if not Frame_World_Waypoint.hidden then
							Frame_World_Waypoint:HideWithAnimation(NS.Variables.Session.id, false)
						end

						if not Frame_World_Pinpoint.hidden then
							Frame_World_Pinpoint:HideWithAnimation(NS.Variables.Session.id, false)
						end

						if not Frame_Navigator.hidden then
							Frame_Navigator:HideWithAnimation()
						end
					end

					--------------------------------

					Callback:Blizzard_Hide()

					--------------------------------

					return
				end

				if NS.Variables.Session.state == "QUEST_PROXIMITY" then
					if C_WS_TYPE == 1 then -- Both
						Transition:Pinpoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 2 then -- Waypoint
						Transition:OnlyWaypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 3 then -- Pinpoint
						Transition:OnlyPinpoint(NS.Variables.Session.id)
					end
				elseif NS.Variables.Session.state == "PROXIMITY" then
					if C_WS_TYPE == 1 then -- Both
						Transition:Pinpoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 2 then -- Waypoint
						Transition:OnlyWaypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 3 then -- Pinpoint
						Transition:OnlyPinpoint(NS.Variables.Session.id)
					end
				elseif NS.Variables.Session.state == "QUEST_AREA" then
					if C_WS_TYPE == 1 then -- Both
						Transition:Waypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 2 then -- Waypoint
						Transition:OnlyWaypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 3 then -- Pinpoint
						Transition:OnlyPinpoint(NS.Variables.Session.id)
					end
				elseif NS.Variables.Session.state == "AREA" then
					if C_WS_TYPE == 1 then -- Both
						Transition:Waypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 2 then -- Waypoint
						Transition:OnlyWaypoint(NS.Variables.Session.id)
					end

					if C_WS_TYPE == 3 then -- Pinpoint
						Transition:OnlyPinpoint(NS.Variables.Session.id)
					end
				end

				--------------------------------

				if IsWaypoint then
					Process:Update_Waypoint()
				end

				if IsPinpoint then
					Process:Update_Pinpoint()
				end

				if IsNavigator then
					Process:Update_Navigator()
				end
			end

			function Event:Update()

			end

			function Event:BackgroundUpdate()
				Process:Update_3D()
				Process:Update_Appearance()

				if IsWaypoint then
					Process:Update_Waypoint_Distance()
				end

				if IsPinpoint then
					Process:Update_Pinpoint()
				end

				if IsNavigator then
					Process:Update_Navigator()
				end
			end

			function Event:NewWaypoint()
				Process:GetInfo()

				--------------------------------

				CallbackRegistry:Trigger("WaypointSystem.ClampChanged")
				CallbackRegistry:Trigger("WaypointSystem.StateChanged")
			end

			function Event:Navigator_Show()
				Process:Update_Navigator()
			end

			CallbackRegistry:Add("WaypointSystem.SuperTrackedChanged", Event.SuperTrackedChanged)
			CallbackRegistry:Add("WaypointSystem.SuperTrackedNewPath", Event.SuperTrackedNewPath)
			CallbackRegistry:Add("WaypointSystem.PlayerMoving", Event.PlayerMoving)
			CallbackRegistry:Add("WaypointSystem.ClampChanged", Event.ClampChanged)
			CallbackRegistry:Add("WaypointSystem.StateChanged", Event.StateChanged)
			CallbackRegistry:Add("WaypointSystem.Update", Event.Update)
			CallbackRegistry:Add("WaypointSystem.BackgroundUpdate", Event.BackgroundUpdate)
			CallbackRegistry:Add("WaypointSystem.NewWaypoint", Event.NewWaypoint)
			CallbackRegistry:Add("WaypointSystem.Navigator.Show", Event.Navigator_Show)

			--------------------------------

			function Callback:UpdateStateSession(currentState)
				local id = nil
				local isNewState = nil

				--------------------------------

				if NS.Variables.Session.state ~= currentState then
					id = addon.C.API.Util:gen_hash()
					isNewState = true
				else
					id = NS.Variables.Session.id
					isNewState = false
				end

				--------------------------------

				return id, isNewState
			end

			--------------------------------

			local updatePerSecond = 60
			local backgroundUpdatePerSecond = 15
			local updateInterval = 1 / updatePerSecond
			local backgroundUpdateInterval = 1 / backgroundUpdatePerSecond
			local updateTimer = 0
			local backgroundUpdateTimer = 0

			local function EventManager_Process()
				local info = Process:GetInfo()

				if info.isNewState then CallbackRegistry:Trigger("WaypointSystem.StateChanged") end
				if info.isNewClamped then CallbackRegistry:Trigger("WaypointSystem.ClampChanged") end
			end

			local function EventManager_Update(context, elapsed)
				-- ▶ Return when the SuperTracking isn't active, or if the player is in a cutscene.
				if not C_SuperTrack.IsSuperTrackingAnything() or IsInCinematicScene() then
					Callback:Navigator_Hide(); Callback:World_Hide(); Callback:Blizzard_Hide(); return
				end
				-- ▶ Return if the player is in an instance.
				if IsInInstance() then
					Callback:Navigator_Hide(); Callback:World_Hide(); Callback:Blizzard_Show(); return
				end

				-- ▶ Get navFrame, if invalid return.
				GetNavFrame()
				if not Frame.navFrame.frame then return end

				--------------------------------

				updateTimer = updateTimer + (elapsed or 0)
				if context or updateTimer >= updateInterval then
					updateTimer = 0

					--------------------------------

					local isMoving = IsPlayerMoving()
					if isMoving then CallbackRegistry:Trigger("WaypointSystem.PlayerMoving") end

					CallbackRegistry:Trigger("WaypointSystem.Update")

					--------------------------------

					backgroundUpdateTimer = backgroundUpdateTimer + (elapsed or 0)
					if context or backgroundUpdateTimer >= backgroundUpdateInterval then
						backgroundUpdateTimer = 0

						--------------------------------

						if context == "SUPER_TRACKING_CHANGED" then
							CallbackRegistry:Trigger("WaypointSystem.SuperTrackedChanged")

							--------------------------------

							C_Timer.After(0, function()
								CallbackRegistry:Trigger("WaypointSystem.NewWaypoint")
							end)
						elseif context == "SUPER_TRACKING_PATH_UPDATED" then
							CallbackRegistry:Trigger("WaypointSystem.SuperTrackedNewPath")
						elseif context == "MAP_PIN_NEW_WAY" then
							CallbackRegistry:Trigger("WaypointSystem.SuperTrackingChanged")
						end

						EventManager_Process()

						CallbackRegistry:Trigger("WaypointSystem.BackgroundUpdate")
					end
				end
			end

			local EventManager = addon.C.FrameTemplates:CreateFrame("Frame")
			EventManager:RegisterEvent("SUPER_TRACKING_CHANGED")
			EventManager:RegisterEvent("SUPER_TRACKING_PATH_UPDATED")
			EventManager:SetScript("OnUpdate", function(_, elapsed)
				EventManager_Update(nil, elapsed)
			end)
			EventManager:SetScript("OnEvent", function(_, event, ...)
				EventManager_Update(event, nil)
			end)
			CallbackRegistry:Trigger("MapPin.NewWay", function()
				EventManager_Update("MAP_PIN_NEW_WAY", nil)
			end)
		end
	end

	--------------------------------
	-- FUNCTIONS (GLOBAL)
	--------------------------------

	do
		function WaypointUI_ClearAll()
			if WaypointUI_IsWay() then
				WaypointUI_ClearWay()
			end

			if C_SuperTrack.IsSuperTrackingAnything() then
				C_SuperTrack.ClearAllSuperTracked()
			end
		end
	end

	--------------------------------
	-- FUNCTIONS (ANIMATION)
	--------------------------------

	do
		do -- WORLD
			do -- SHOW
				function Frame_World:ShowWithAnimation_StopEvent()
					return Frame_World.hidden
				end

				function Frame_World:ShowWithAnimation(skipAnimation)
					if not Frame_World.hidden then
						return
					end
					Frame_World.hidden = false
					Frame_World:Show()

					--------------------------------

					local animation = addon.C.Animation.Sequencer:CreateAnimation({
						["stopEvent"] = Frame_World.ShowWithAnimation_StopEvent,
						["sequences"] = {
							["playback"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										addon.C.Animation:CancelAll(Frame_World)

										--------------------------------

										addon.C.Animation:Alpha({ ["frame"] = Frame_World, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = Frame_World.ShowWithAnimation_StopEvent })
									end
								}
							},
							["instant"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_World:SetAlpha(1)
									end
								},
								[2] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_World:Hide()
									end
								}
							}
						}
					})
					animation:Play(skipAnimation and "instant" or "playback")
				end
			end

			do -- HIDE
				function Frame_World:HideWithAnimation_StopEvent()
					return not Frame_World.hidden
				end

				function Frame_World:HideWithAnimation(skipAnimation)
					if Frame_World.hidden then
						return
					end
					Frame_World.hidden = true

					--------------------------------

					local animation = addon.C.Animation.Sequencer:CreateAnimation({
						["stopEvent"] = Frame_World.HideWithAnimation_StopEvent,
						["sequences"] = {
							["playback"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										addon.C.Animation:CancelAll(Frame_World)

										--------------------------------

										addon.C.Animation:Alpha({ ["frame"] = Frame_World, ["duration"] = .5, ["from"] = Frame_World:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = Frame_World.HideWithAnimation_StopEvent })
									end
								},
								[2] = {
									["wait"] = .5,
									["animation"] = function()
										Frame_World:Hide()
									end
								}
							},
							["instant"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_World:SetAlpha(0)
									end
								},
								[2] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_World:Hide()
									end
								}
							}
						}
					})
					animation:Play(skipAnimation and "instant" or "playback")
				end
			end

			do -- WAYPOINT
				do -- VFX
					do -- WAVE
						local Wave = Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX_WAVE

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
						Wave.Animation_Playback_Loop:SetOnStart(function()
							Wave:Show()
						end)
						Wave.Animation_Playback_Loop:SetOnStop(function()
							Wave:Hide()
						end)
					end
				end

				do -- SHOW
					function Frame_World_Waypoint:ShowWithAnimation_StopEvent(id)
						return NS.Variables.Session.id ~= id
					end

					function Frame_World_Waypoint:ShowWithAnimation(id, skipAnimation)
						Frame_World_Waypoint.hidden = false
						Frame_World_Waypoint:Show()

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end,
							["sequences"] = {
								["playback"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_CONTEXT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_MARKER)

											--------------------------------

											Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_MARKER:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE:Hide()
											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = 3.25, ["to"] = 1, ["ease"] = "EaseSine_Out", ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
										end,
									},
									[2] = {
										["wait"] = .225,
										["animation"] = function()
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX, ["duration"] = 1, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Translate({ ["frame"] = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT, ["duration"] = 1, ["from"] = 15, ["to"] = 0, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_MARKER, ["duration"] = .25, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_WAYPOINT_MARKER, ["duration"] = 1, ["from"] = .25, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:ShowWithAnimation_StopEvent(id) end })

											--------------------------------

											Frame.REF_WORLD_WAYPOINT_CONTEXT:ShowWithAnimation(skipAnimation)
										end
									},
									[3] = {
										["wait"] = .5,
										["animation"] = function()
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE:Show()
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE.Animation_Playback_Loop:Stop()
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE.Animation_Playback_Loop:Start()
										end
									}
								},
								["instant"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_WAYPOINT_CONTEXT:SetScale(1)
											Frame.REF_WORLD_WAYPOINT_CONTEXT:SetAlpha(1)
											Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX:SetAlpha(1)
											Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:SetPoint("CENTER", Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:GetParent(), 0, 0)
											Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:SetAlpha(1)
											Frame.REF_WORLD_WAYPOINT_MARKER:SetAlpha(1)
											Frame.REF_WORLD_WAYPOINT_MARKER:SetScale(1)

											--------------------------------

											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE:Show()
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE.Animation_Playback_Loop:Stop()
											Frame.REF_WORLD_WAYPOINT_MARKER_PULSE.Animation_Playback_Loop:Start()
											Frame.REF_WORLD_WAYPOINT_CONTEXT:ShowWithAnimation(skipAnimation)
										end
									}
								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")
					end
				end

				do -- HIDE
					function Frame_World_Waypoint:HideWithAnimation_StopEvent(id)
						return NS.Variables.Session.id ~= id
					end

					function Frame_World_Waypoint:HideWithAnimation(id, skipAnimation)
						Frame_World_Waypoint.hidden = true

						--------------------------------

						local chain = addon.C.API.Util:AddMethodChain({ "onFinish" })

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end,
							["sequences"] = {
								["playback"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_CONTEXT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_WAYPOINT_MARKER)

											--------------------------------

											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = Frame.REF_WORLD_WAYPOINT_CONTEXT:GetScale(), ["to"] = 2, ["ease"] = "EaseSine_In", ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT, ["duration"] = .25, ["from"] = Frame.REF_WORLD_WAYPOINT_CONTEXT:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX, ["duration"] = .5, ["from"] = Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Translate({ ["frame"] = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .25, ["from"] = 0, ["to"] = 5, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT, ["duration"] = .25, ["from"] = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_WAYPOINT_MARKER, ["duration"] = .375, ["from"] = Frame.REF_WORLD_WAYPOINT_MARKER:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_WAYPOINT_MARKER, ["duration"] = .375, ["from"] = Frame.REF_WORLD_WAYPOINT_MARKER:GetScale(), ["to"] = .25, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Waypoint:HideWithAnimation_StopEvent(id) end })
										end
									},
									[2] = {
										["wait"] = .25,
										["animation"] = function()
											Frame_World_Waypoint:Hide()

											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								},
								["instant"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_WAYPOINT_CONTEXT:SetScale(2)
											Frame.REF_WORLD_WAYPOINT_CONTEXT:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_CONTEXT_VFX:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:SetPoint("CENTER", Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:GetParent(), 0, 7.5)
											Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_MARKER:SetAlpha(0)
											Frame.REF_WORLD_WAYPOINT_MARKER:SetScale(.25)
										end
									},
									[2] = {
										["wait"] = nil,
										["animation"] = function()
											Frame_World_Waypoint:Hide()

											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")

						---------------------------------

						return { onFinish = chain.onFinish.set }
					end
				end

				do -- FOOTER
					local SubtextFrame = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT_FRAME
					local Subtext = Frame.REF_WORLD_WAYPOINT_FOOTER_LAYOUT_SUBTEXT

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

							local animation = addon.C.Animation.Sequencer:CreateAnimation({
								["stopEvent"] = SubtextFrame.ShowWithAnimation_StopEvent,
								["sequences"] = {
									["playback"] = {
										[1] = {
											["wait"] = nil,
											["animation"] = function()
												addon.C.Animation:CancelAll(SubtextFrame)

												--------------------------------

												addon.C.Animation:Alpha({ ["frame"] = SubtextFrame, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = nil, ["stopEvent"] = SubtextFrame.ShowWithAnimation_StopEvent })
												addon.C.Animation:Translate({ ["frame"] = Subtext, ["duration"] = 1, ["from"] = 15, ["to"] = 0, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = SubtextFrame.ShowWithAnimation_StopEvent })
											end
										}
									},
									["instant"] = {
										[1] = {
											["wait"] = nil,
											["animation"] = function()
												SubtextFrame:SetAlpha(1)
												Subtext:SetPoint("CENTER", Subtext:GetParent(), 0, 0)
											end
										}
									}
								}
							})
							animation:Play(skipAnimation and "instant" or "playback")
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

							--------------------------------

							local animation = addon.C.Animation.Sequencer:CreateAnimation({
								["stopEvent"] = SubtextFrame.HideWithAnimation_StopEvent,
								["sequences"] = {
									["playback"] = {
										[1] = {
											["wait"] = nil,
											["animation"] = function()
												addon.C.Animation:CancelAll(SubtextFrame)

												--------------------------------

												addon.C.Animation:Alpha({ ["frame"] = SubtextFrame, ["duration"] = .25, ["from"] = SubtextFrame:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = SubtextFrame.HideWithAnimation_StopEvent })
												addon.C.Animation:Translate({ ["frame"] = Subtext, ["duration"] = .75, ["from"] = 0, ["to"] = 7.5, ["axis"] = "y", ["ease"] = "EaseExpo_Out", ["stopEvent"] = SubtextFrame.HideWithAnimation_StopEvent })
											end
										},
										[2] = {
											["wait"] = .5,
											["animation"] = function()
												SubtextFrame:Hide()
											end
										}
									},
									["instant"] = {
										[1] = {
											["wait"] = nil,
											["animation"] = function()
												SubtextFrame:SetAlpha(0)
												Subtext:SetPoint("CENTER", Subtext:GetParent(), 0, 7.5)
											end
										},
										[2] = {
											["wait"] = nil,
											["animation"] = function()
												SubtextFrame:Hide()
											end
										}
									}
								}
							})
							animation:Play(skipAnimation and "instant" or "playback")
						end
					end
				end
			end

			do -- PINPOINT
				do -- SHOW
					function Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id)
						return NS.Variables.Session.id ~= id
					end

					function Frame_World_Pinpoint:ShowWithAnimation(id, skipAnimation)
						Frame_World_Pinpoint.hidden = false
						Frame_World_Pinpoint:Show()

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = function() return Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id) end,
							["sequences"] = {
								["playback"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_FOREGROUND)

											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .75, ["from"] = 3, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .75, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW, ["duration"] = .75, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_FOREGROUND, ["duration"] = 1.5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Pinpoint:ShowWithAnimation_StopEvent(id) end })
										end
									},
									[2] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:ShowWithAnimation(skipAnimation)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW.Animation_Playback_Loop:Start()
										end
									}
								},
								["instant"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetScale(1)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetAlpha(1)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW:SetAlpha(1)
											Frame.REF_WORLD_PINPOINT_FOREGROUND:SetAlpha(1)
										end
									},
									[2] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:ShowWithAnimation(skipAnimation)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW.Animation_Playback_Loop:Start()
										end
									}
								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")
					end
				end

				do -- HIDE
					function Frame_World_Pinpoint:HideWithAnimation_StopEvent(id)
						return NS.Variables.Session.id ~= id
					end

					function Frame_World_Pinpoint:HideWithAnimation(id, skipAnimation)
						Frame_World_Pinpoint.hidden = true

						--------------------------------

						local chain = addon.C.API.Util:AddMethodChain({ "onFinish" })

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = function() return Frame_World_Pinpoint:HideWithAnimation_StopEvent(id) end,
							["sequences"] = {
								["playback"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW)
											addon.C.Animation:CancelAll(Frame.REF_WORLD_PINPOINT_FOREGROUND)

											addon.C.Animation:Scale({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .5, ["from"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:GetScale(), ["to"] = 2, ["ease"] = "EaseQuart_InOut", ["stopEvent"] = function() return Frame_World_Pinpoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT, ["duration"] = .5, ["from"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Pinpoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW, ["duration"] = .5, ["from"] = Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = function() return Frame_World_Pinpoint:HideWithAnimation_StopEvent(id) end })
											addon.C.Animation:Alpha({ ["frame"] = Frame.REF_WORLD_PINPOINT_FOREGROUND, ["duration"] = .125, ["from"] = Frame.REF_WORLD_PINPOINT_FOREGROUND:GetAlpha(), ["to"] = 0, ["ease"] = nil, ["stopEvent"] = function() return Frame_World_Pinpoint:HideWithAnimation_StopEvent(id) end })
										end
									},
									[2] = {
										["wait"] = .25,
										["animation"] = function()
											Frame_World_Pinpoint:Hide()

											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								},
								["instant"] = {
									[1] = {
										["wait"] = nil,
										["animation"] = function()
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetScale(1.125)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_CONTEXT:SetAlpha(0)
											Frame.REF_WORLD_PINPOINT_BACKGROUND_ARROW:SetAlpha(0)
											Frame.REF_WORLD_PINPOINT_FOREGROUND:SetAlpha(0)
										end
									},
									[2] = {
										["wait"] = .25,
										["animation"] = function()
											Frame_World_Pinpoint:Hide()

											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")

						---------------------------------

						return { onFinish = chain.onFinish.set }
					end
				end
			end
		end

		do -- NAVIGATOR
			do -- SHOW
				function Frame_Navigator:ShowWithAnimation_StopEvent()
					return Frame_Navigator.hidden
				end

				function Frame_Navigator:ShowWithAnimation(skipAnimation)
					if not Frame_Navigator.hidden then
						return
					end
					Frame_Navigator.hidden = false
					Frame_Navigator:Show()

					--------------------------------

					local animation = addon.C.Animation.Sequencer:CreateAnimation({
						["stopEvent"] = Frame_Navigator.ShowWithAnimation_StopEvent,
						["sequences"] = {
							["playback"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										addon.C.Animation:CancelAll(Frame_Navigator)

										--------------------------------

										addon.C.Animation:Alpha({ ["frame"] = Frame_Navigator, ["duration"] = .5, ["from"] = 0, ["to"] = 1, ["ease"] = "EaseExpo_Out", ["stopEvent"] = Frame_Navigator.ShowWithAnimation_StopEvent })
									end
								}
							},
							["instant"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_Navigator:SetAlpha(1)
									end
								}
							}
						}
					})
					animation:Play(skipAnimation and "instant" or "playback")
				end
			end

			do -- HIDE
				function Frame_Navigator:HideWithAnimation_StopEvent()
					return not Frame_Navigator.hidden
				end

				function Frame_Navigator:HideWithAnimation(skipAnimation)
					if Frame_Navigator.hidden then
						return
					end
					Frame_Navigator.hidden = true

					--------------------------------

					local animation = addon.C.Animation.Sequencer:CreateAnimation({
						["stopEvent"] = Frame_Navigator.HideWithAnimation_StopEvent,
						["sequences"] = {
							["playback"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										addon.C.Animation:CancelAll(Frame_Navigator)

										--------------------------------

										addon.C.Animation:Alpha({ ["frame"] = Frame_Navigator, ["duration"] = .5, ["from"] = Frame_Navigator:GetAlpha(), ["to"] = 0, ["ease"] = "EaseExpo_Out", ["stopEvent"] = Frame_Navigator.HideWithAnimation_StopEvent })
									end
								},
								[2] = {
									["wait"] = .5,
									["animation"] = function()
										Frame_Navigator:Hide()
									end
								}
							},
							["instant"] = {
								[1] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_Navigator:SetAlpha(0)
									end
								},
								[2] = {
									["wait"] = nil,
									["animation"] = function()
										Frame_Navigator:Hide()
									end
								}
							}
						}
					})
					animation:Play(skipAnimation and "instant" or "playback")
				end
			end

			do -- ARROW
				do -- SHOW
					function Frame_Navigator_Arrow:ShowWithAnimation_StopEvent()
						return Frame_Navigator_Arrow.hidden
					end

					function Frame_Navigator_Arrow:ShowWithAnimation(skipAnimation)
						Frame_Navigator_Arrow.hidden = false

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = Frame_Navigator_Arrow.ShowWithAnimation_StopEvent,
							["sequences"] = {
								["playback"] = {

								},
								["instant"] = {

								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")
					end
				end

				do -- HIDE
					function Frame_Navigator_Arrow:HideWithAnimation_StopEvent()
						return not Frame_Navigator_Arrow.hidden
					end

					function Frame_Navigator_Arrow:HideWithAnimation(skipAnimation)
						Frame_Navigator_Arrow.hidden = true

						--------------------------------

						local chain = addon.C.API.Util:AddMethodChain({ "onFinish" })

						--------------------------------

						local animation = addon.C.Animation.Sequencer:CreateAnimation({
							["stopEvent"] = Frame_Navigator_Arrow.HideWithAnimation_StopEvent,
							["sequences"] = {
								["playback"] = {
									[1] = {
										["wait"] = .5,
										["animation"] = function()
											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								},
								["instant"] = {
									[1] = {
										["wait"] = .5,
										["animation"] = function()
											if chain.onFinish.variable then
												chain.onFinish.variable()
											end
										end
									}
								}
							}
						})
						animation:Play(skipAnimation and "instant" or "playback")

						--------------------------------

						return { onFinish = chain.onFinish.set }
					end
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

		local function C_CONFIG_APPEARANCE_UPDATE(skipDelay)
			if skipDelay then Callback:APP_Set() else C_Timer.After(0, function() Callback:APP_Set() end) end
		end

		C_CONFIG_APPEARANCE_UPDATE(true)

		--------------------------------

		CallbackRegistry:Add("C_CONFIG_WS_TYPE", C_CONFIG_WS_TYPE)
		CallbackRegistry:Add("C_CONFIG_WS_NAVIGATOR", C_CONFIG_APPEARANCE_UPDATE)
		CallbackRegistry:Add("C_CONFIG_APPEARANCE_UPDATE", C_CONFIG_APPEARANCE_UPDATE)
	end

	--------------------------------
	-- EVENTS
	--------------------------------

	do

	end
end
