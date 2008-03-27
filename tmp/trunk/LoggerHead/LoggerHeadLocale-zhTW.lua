local L = AceLibrary("AceLocale-2.2"):new("LoggerHead")

L:RegisterTranslations("zhTW", function() return {
	["LoggerHead"] = "LoggerHead",
	["Toggle Logging"] = "開關日誌",
	["Instances"] = "副本",
	["Instance log settings"] = "設定副本日誌",
	["Zones"] = "地區",
	["Zone log settings"] = "設定地區日誌",
	["Eastern Kingdoms"] = "東部王國",
	["Kalimdor"] = "卡林多",
	["Outland"] = "外域",
	["You have entered %s. Do you want to enable logging for this zone/instance?"] = "你已經進入 %s. 您想要為這地區/副本啟動紀錄日誌嗎?",
	["Enable"] = "啟動",
	["Disable"] = "關閉",
	["Enabled"] = "啟動",
	["Disabled"] = "關閉",
	["Combat Log"] = "戰鬥日誌",
	["Shift-Click to open configuration"] = true,
	["Click to toggle combat logging"] = true,
	["Prompt on new zone?"] = true,
	["Prompt when entering a new zone?"] = true,
} end)