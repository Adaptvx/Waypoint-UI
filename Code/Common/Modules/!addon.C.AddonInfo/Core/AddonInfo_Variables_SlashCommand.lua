---@class addon
local addon = select(2, ...)
local NS = addon.C.AddonInfo; addon.C.AddonInfo = NS

--------------------------------

NS.Variables = NS.Variables or {}
NS.Variables.SlashCommand = {}

--------------------------------
-- VARIABLES
--------------------------------

do -- MAIN

end

do  -- CONSTANTS
	do -- REGISTER
		local function WAYPOINT_UI_WAY_LOCATION()
			local playerMapID = C_Map.GetBestMapForUnit("player")
			local playerPosition = C_Map.GetPlayerMapPosition(playerMapID, "player")

			DEFAULT_CHAT_FRAME:AddMessage(addon.CREF:GetChatIcon("chat-subdivider", 16) .. " " .. addon.C.AddonInfo.Locales["SlashCommand - /way - Map ID - Prefix"] .. playerMapID .. addon.C.AddonInfo.Locales["SlashCommand - /way - Map ID - Suffix"])
			DEFAULT_CHAT_FRAME:AddMessage(addon.CREF:GetChatIcon("chat-subdivider", 16) .. " " .. addon.C.AddonInfo.Locales["SlashCommand - /way - Position - Axis (X) - Prefix"] .. math.ceil(playerPosition.x * 100) .. addon.C.AddonInfo.Locales["SlashCommand - /way - Position - Axis (X) - Suffix"] .. addon.C.AddonInfo.Locales["SlashCommand - /way - Position - Axis (Y) - Prefix"] .. math.ceil(playerPosition.y * 100) .. addon.C.AddonInfo.Locales["SlashCommand - /way - Position - Axis (Y) - Suffix"])
		end

		local function WAYPOINT_UI_WAY_CATCH()
			DEFAULT_CHAT_FRAME:AddMessage(addon.CREF:GetAddonInlineIcon(16) .. " /way " .. addon.CREF:GetSharedColor().RGB_YELLOW_HEXCODE .. "#<mapID> <x> <y> <name>" .. "|r")
			DEFAULT_CHAT_FRAME:AddMessage(addon.CREF:GetChatIcon("chat-subdivider", 16) .. " /way " .. addon.CREF:GetSharedColor().RGB_YELLOW_HEXCODE .. "<x> <y> <name>" .. "|r")
			DEFAULT_CHAT_FRAME:AddMessage(addon.CREF:GetChatIcon("chat-subdivider", 16) .. " /way " .. addon.CREF:GetSharedColor().RGB_YELLOW_HEXCODE .. "reset" .. "|r")

			WAYPOINT_UI_WAY_LOCATION()
		end

		NS.Variables.SlashCommand.REGISTER = {
			[1] = {
				["name"] = "WAYPOINT_UI_WAY",
				["hook"] = "TOMTOM_WAY",
				["command"] = "way",
				["callback"] = function(msg, tokens)
					if #tokens >= 1 then
						local firstToken = tokens[1]:lower()
						local token1 = tokens[1]
						local token2 = tokens[2]
						local token3 = tokens[3]

						local mapID = nil
						local x = nil
						local y = nil
						local name = ""

						--------------------------------

						if firstToken == "reset" then
							WaypointUI_ResetWay()
						else
							-- <#mapID> <x> <y>
							if token1 and token2 and token3 and (not tonumber(token1) and tonumber(token2) and tonumber(token3)) then
								if addon.C.API.Util:FindString(token1, "#") then
									mapID = token1:gsub("#", "")
									x = token2
									y = token3
									for i = 4, #tokens do
										if #name >= 1 then
											name = name .. " " .. tokens[i]
										else
											name = name .. tokens[i]
										end
									end
								end

							-- <x> <y>
							elseif token1 and token2 and (tonumber(token1) and tonumber(token2)) then
								mapID = C_Map.GetBestMapForUnit("player")
								x = token1
								y = token2
								for i = 3, #tokens do
									if #name >= 1 then
										name = name .. " " .. tokens[i]
									else
										name = name .. tokens[i]
									end
								end
							else
								WAYPOINT_UI_WAY_CATCH()

								--------------------------------

								return
							end

							--------------------------------

							WaypointUI_NewWay(name, mapID, x, y)
						end
					else
						WAYPOINT_UI_WAY_CATCH()

						--------------------------------

						return
					end
				end
			}
		}
	end
end
