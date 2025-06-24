-- ♡ Translation // Crazyyoungs

---@class addon
local addon = select(2, ...)
local L = addon.C.AddonInfo.Locales

--------------------------------

L.koKR = {}
local NS = L.koKR; L.koKR = NS

--------------------------------

function NS:Load()
	if GetLocale() ~= "koKR" then
		return
	end

	--------------------------------
	-- 일반
	--------------------------------

	do

	end

	--------------------------------
	-- 웨이포인트 시스템
	--------------------------------

	do
		-- PINPOINT
		L["WaypointSystem - Pinpoint - Quest - Complete"] = "퀘스트 완료 후 보고 가능"
	end

	--------------------------------
	-- 슬래시 명령어
	--------------------------------

	do
		L["SlashCommand - /way - Map ID - Prefix"] = "현재 지도ID: "
		L["SlashCommand - /way - Map ID - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (X) - Prefix"] = "X: "
		L["SlashCommand - /way - Position - Axis (X) - Suffix"] = ""
		L["SlashCommand - /way - Position - Axis (Y) - Prefix"] = ", Y: "
		L["SlashCommand - /way - Position - Axis (Y) - Suffix"] = ""
	end

	--------------------------------
	-- 설정
	--------------------------------

	do
		L["Config - General"] = "일반"
		L["Config - General - Title"] = "일반"
		L["Config - General - Title - Subtext"] = "전체 설정을 사용자 지정합니다."
		L["Config - General - Preferences"] = "환경 설정"
		L["Config - General - Preferences - Meter"] = "단위를 야드 대신 미터 변경"
		L["Config - General - Preferences - Meter - Description"] = "측정 단위를 미터법으로 변경합니다.\n[ 거리가 1000M 이상이면 1KM 단위가 변경 됩니다. ]"
		L["Config - General - Reset"] = "재설정"
		L["Config - General - Reset - Button"] = "기본값으로 재설정"
		L["Config - General - Reset - Confirm"] = "모든 설정을 재설정 하시겠습니까?"
		L["Config - General - Reset - Confirm - Yes"] = "확인"
		L["Config - General - Reset - Confirm - No"] = "취소"

		L["Config - WaypointSystem"] = "목표 지점"
		L["Config - WaypointSystem - Title"] = "목표 지점"
		L["Config - WaypointSystem - Title - Subtext"] = "사용자 인터페이스의 외형을 사용자 지정합니다."
		L["Config - WaypointSystem - Type"] = "활성화"
		L["Config - WaypointSystem - Type - Both"] = "모두"
		L["Config - WaypointSystem - Type - Waypoint"] = "목표 지점 아이콘"
		L["Config - WaypointSystem - Type - Pinpoint"] = "목표 지점 툴팁"
		L["Config - WaypointSystem - General"] = "일반"
		L["Config - WaypointSystem - General - Transition Distance"] = "목표 지점 - 최대 거리"
		L["Config - WaypointSystem - General - Transition Distance - Description"] = "경로점이 표시되는 최대 거리."
		L["Config - WaypointSystem - General - Hide Distance"] = "목표 지점 - 최소 거리"
		L["Config - WaypointSystem - General - Hide Distance - Description"] = "목표 지점이 숨겨지기 전 거리."
		L["Config - WaypointSystem - Waypoint"] = "목표 지점 아이콘"
		L["Config - WaypointSystem - Waypoint - Footer - Type"] = "추가 정보 옵션"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Both"] = "모두"
		L["Config - WaypointSystem - Waypoint - Footer - Type - Distance"] = "거리"
		L["Config - WaypointSystem - Waypoint - Footer - Type - ETA"] = "도착 시간"
		L["Config - WaypointSystem - Waypoint - Footer - Type - None"] = "없음"
		L["Config - WaypointSystem - Pinpoint"] = "목표 지점 툴팁"
		L["Config - WaypointSystem - Pinpoint - Detail"] = "추가 정보 표시"
		L["Config - WaypointSystem - Pinpoint - Detail - Description"] = "이름 / 설명 등의 추가 정보 포함."

		L["Config - Appearance"] = "외형"
		L["Config - Appearance - Title"] = "외형"
		L["Config - Appearance - Title - Subtext"] = "UI의 외형을 원하는 대로 변경하세요."
		L["Config - Appearance - Waypoint"] = "Waypoint"
		L["Config - Appearance - Waypoint - Scale"] = "목표 지점 아이콘 크기"
		L["Config - Appearance - Waypoint - Scale - Description"] = "목표 지점 아이콘 크기는 거리에 따라 조정됩니다. 이 옵션은 전체 크기를 조정하는 데 사용됩니다."
		L["Config - Appearance - Waypoint - Scale - Min"] = "축소 - 최소 크기"
		L["Config - Appearance - Waypoint - Scale - Min - Description"] = "목표 지점를 축소할 수 있는 최소 크기."
		L["Config - Appearance - Waypoint - Scale - Max"] = "확대 - 최대 크기"
		L["Config - Appearance - Waypoint - Scale - Max - Description"] = "목표 지점를 확대할 수 있는 최대 크기."
		L["Config - Appearance - Waypoint - Beam"] = "Show Beam"
		L["Config - Appearance - Waypoint - Beam - Alpha"] = "투명도"
		L["Config - Appearance - Waypoint - Footer - Alpha"] = "Info Text Transparency"
		L["Config - Appearance - Pinpoint"] = "목표 지점 툴팁"
		L["Config - Appearance - Pinpoint - Scale"] = "툴팁 크기"
		L["Config - Appearance - Visual"] = "Visual"
		L["Config - Appearance - Visual - UseCustomColor"] = "Use Custom Color"
		L["Config - Appearance - Visual - UseCustomColor - Color"] = "Color"
		L["Config - Appearance - Visual - UseCustomColor - TintIcon"] = "Tint Icon"
		L["Config - Appearance - Visual - UseCustomColor - Reset"] = "Reset"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Default"] = "Normal Quest"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Repeatable"] = "Repeatable Quest"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Complete - Important"] = "Important Quest"
		L["Config - Appearance - Visual - UseCustomColor - Quest - Incomplete"] = "Incomplete Quest"
		L["Config - Appearance - Visual - UseCustomColor - Neutral"] = "Generic Waypoint"

		L["Config - Audio"] = "오디오"
		L["Config - Audio - Title"] = "오디오"
		L["Config - Audio - Title - Subtext"] = "Waypoint UI 오디오 효과 구성."
		L["Config - Audio - General"] = "일반"
		L["Config - Audio - General - EnableGlobalAudio"] = "오디오 활성화"

		L["Config - About"] = "정보"
		L["Config - About - Contributors"] = "제작 참여자"
		L["Config - About - Developer"] = "개발자"
	end

	--------------------------------
	-- 제작 참여자
	--------------------------------

	do
		L["Contributors - ZamestoTV - Description"] = "번역가: 러시아어"
		L["Contributors - huchang47 - Description"] = "번역가: 중국어(간체)"
		L["Contributors - BlueNightSky - Description"] = "번역가: 중국어(번체)"
		L["Contributors - Crazyyoungs - Description"] = "번역가: 한국어"
		L["Contributors - y45853160 - Description"] = "코드: 베타 버그 수정"
	end
end

NS:Load()
