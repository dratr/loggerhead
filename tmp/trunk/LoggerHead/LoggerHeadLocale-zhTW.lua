﻿local L = AceLibrary("AceLocale-2.2"):new("LoggerHead")

L:RegisterTranslations("zhTW", function() return {
    ["Log Range"] = "日誌範圍",
    ["Log range settings."] = "設定日誌範圍",
    ["Creature"] = "生物",
    ["Creature combat log range. Default: 30"] = "生物作戰日誌範圍。預設: 30",
    ["Friendly players"] = "友方玩家",
    ["Friendly players combat log range. Default: 50"] = "友方玩家作戰日誌範圍。預設: 50",
    ["Friendly players' pet"] = "友方玩家的寵物",
    ["Friendly players pet combat log range. Default: 50"] = "友方玩家的寵物作戰日誌範圍。預設: 50",
    ["Hostile players"] = "敵方玩家",
    ["Hostile players combat log range. Default: 50"] = "敵方玩家作戰日誌範圍。預設: 50",
    ["Hostile players' pet"] = "敵方玩家的寵物",
    ["Hostile players pet combat log range. Default: 50"] = "敵方玩家的寵物作戰日誌範圍。預設: 50",
    ["Party members"] = "小隊成員",
    ["Party members combat log range. Default: 50"] = "小隊成員作戰日誌範圍。預設: 50",
    ["Party members' pet"] = "小隊成員的寵物",
    ["Party members' pet combat log range. Default: 50"] = "小隊成員的寵物作戰日誌範圍。預設: 50",
    ["Death"] = "死亡",
    ["Range for death messages. Default: 60"] = "記錄死亡訊息的範圍。預設: 60",
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
} end)