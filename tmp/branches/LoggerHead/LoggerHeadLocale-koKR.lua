local L = AceLibrary("AceLocale-2.2"):new("LoggerHead")

L:RegisterTranslations("koKR", function() return {
	["LoggerHead"] = "LoggerHead",
	["Toggle Logging"] = "로그 파일 기록 토글",
	["Instances"] = "인스턴스",
	["Instance log settings"] = "인스턴스 로그 설정",
	["Zones"] = "지역",
	["Zone log settings"] = "지역 로그 설정",
	["Eastern Kingdoms"] = "동부 왕국",
	["Kalimdor"] = "칼림도어",
	["Outland"] = "아웃랜드",
	["You have entered |cffd9d919%s.|r Do you want to enable logging for this zone/instance?"] = "\"|cffd9d919%s.|r\"에 들어섰습니다. 이 지역(인스턴스던전)에 대한 로그를 파일로 기록하시겠습니까?",
	["Enable"] = "가능",
	["Disable"] = "불가능",
	["Enabled"] = "|cff00ff00가능|r",
	["Disabled"] = "|cffff0000불가능|r",
	["Combat Log"] = "전투 로그",
	["Shift-Click to open configuration"] = "쉬프트-클릭: 설정창 열기",
	["Click to toggle combat logging"] = "클릭: 전투 로그 토글",
	["Prompt on new zone?"] = "새로운 지역 바로 기록",
	["Prompt when entering a new zone?"] = "새로운 지역에 들어서면 로그 기록을 바로 시작하시겠습니까?",
} end)