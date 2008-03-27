local L = AceLibrary("AceLocale-2.2"):new("LoggerHead")

L:RegisterTranslations("enUS", function() return {
	["LoggerHead"] = true,
	["Toggle Logging"] = true,
	["Instances"] = true,
	["Instance log settings"] = true,
	["Zones"] = true,
	["Zone log settings"] = true,    
	["Eastern Kingdoms"] = true,
	["Kalimdor"] = true,
	["Outland"] = true,
	["You have entered %s. Do you want to enable logging for this zone/instance?"] = true,
	["Enable"] = true,
	["Disable"] = true,
	["Enabled"] = "|cff00ff00Enabled|r",
	["Disabled"] = "|cffff0000Disabled|r",
	["Combat Log"] = true,
	["Shift-Click to open configuration"] = true,
	["Click to toggle combat logging"] = true,
	["Prompt on new zone?"] = true,
	["Prompt when entering a new zone?"] = true,
} end)