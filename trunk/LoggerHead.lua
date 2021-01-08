local ADDON_NAME, ADDON_TABLE = ...
local LoggerHead = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0","AceEvent-3.0","LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME, true)
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
local LoggerHeadDS

-- Localize a few functions

local LoggingCombat = _G.LoggingCombat
local LoggingChat = _G.LoggingChat
local IsAddOnLoaded = _G.IsAddOnLoaded
local GetInstanceInfo = _G.GetInstanceInfo
local pairs = _G.pairs
local tonumber = _G.tonumber
local string = _G.string

local enabled_text = GREEN_FONT_COLOR_CODE..VIDEO_OPTIONS_ENABLED..FONT_COLOR_CODE_CLOSE
local disabled_text = RED_FONT_COLOR_CODE..VIDEO_OPTIONS_DISABLED..FONT_COLOR_CODE_CLOSE
local enabled_icon  = "Interface\\AddOns\\"..ADDON_NAME.."\\enabled"
local disabled_icon = "Interface\\AddOns\\"..ADDON_NAME.."\\disabled"

local ID_ENABLE = 1
local ID_DISABLE = 2

local DLG_BACKDROP = {
    bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
    edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {
        left = 11,
        right = 12,
        top = 12,
        bottom = 11,
    },
}


local garrisonmaps = {
	[1152] = true,  -- Horde level 1
	[1330] = true,  -- Horde level 2
	[1153] = true,  -- Horde level 3
	[1158] = true,  -- Alliance level 1
	[1331] = true,  -- Alliance level 2
	[1160] = true,  -- Alliance level 3
}

local difficultyLookup = {
	DUNGEON_DIFFICULTY1, -- 1: Normal dungeon
	DUNGEON_DIFFICULTY2, -- 2: Heroic dungeon
	RAID_DIFFICULTY_10PLAYER, -- 3: 10 man raid
	RAID_DIFFICULTY_25PLAYER, -- 4: 25 man raid
	RAID_DIFFICULTY_10PLAYER_HEROIC, -- 5: 10 man heroic raid
	RAID_DIFFICULTY_25PLAYER_HEROIC, -- 6: 25 man heroic raid
	RAID_FINDER, -- 7: Pre-SoO LFR
	CHALLENGE_MODE, -- 8: CM dungeon
	RAID_DIFFICULTY_40PLAYER, -- 9: 40-man raid
	nil, -- 10: Unknown
	nil, -- 11: Norm scen
	nil, -- 12: heroic scen
	nil, -- 13: Unknown
	PLAYER_DIFFICULTY1, --14: Normal Raid
	PLAYER_DIFFICULTY2, -- 15: Heroic Raid
	PLAYER_DIFFICULTY6, -- 16: Mythic Raid
	PLAYER_DIFFICULTY3, -- 17: Raid Finder
	nil, -- 18: Unknown
	nil, -- 19: Unknown
	nil, -- 20: Unknown
	nil, -- 21: Unknown
	nil, -- 22: Unknown
	PLAYER_DIFFICULTY6, -- 23: Mythic dungeon
	"Timewalking", -- 24: Timewalking
	[167] = "Torghast"
}

local db
local defaults = {
	profile = {
		log = {},
		prompt = true,
		chat = false,
		sink = {},
		minimap = {
			hide = false,
			minimapPos = 250,
			radius = 80,
		},
	}
}

if not LoggerHead.escape_hooked then
	_G.hooksecurefunc("StaticPopup_EscapePressed", function()
		LoggerHead.promptDialog:Hide()
	end)
	LoggerHead.escape_hooked = true
end

local function LoggerHead_ButtonOnClick(btn, mousebtn, down)
	local promptDialog = btn:GetParent()
	if btn:GetID() == ID_ENABLE then
		promptDialog.data.accept()
	else
		promptDialog.data.reject()
	end
	-- Hide dialog
	promptDialog:Hide()
end

function LoggerHead:CreateButton(btnName, parent, text)
	local newBtn = _G.CreateFrame("Button", btnName, parent)
	newBtn:SetWidth(128)
	newBtn:SetHeight(21)

	newBtn:SetNormalTexture([[Interface\Buttons\UI-DialogBox-Button-Up]])
	newBtn:GetNormalTexture():SetTexCoord(0, 1, 0, 0.71875)

	newBtn:SetPushedTexture([[Interface\Buttons\UI-DialogBox-Button-Down]])
	newBtn:GetPushedTexture():SetTexCoord(0, 1, 0, 0.71875)
	newBtn:SetDisabledTexture([[Interface\Buttons\UI-DialogBox-Button-Disabled]])
	newBtn:GetDisabledTexture():SetTexCoord(0, 1, 0, 0.71875)

	newBtn:SetHighlightTexture([[Interface\Buttons\UI-DialogBox-Button-Highlight]], "ADD")
	newBtn:GetHighlightTexture():SetTexCoord(0, 1, 0, 0.71875)

	newBtn:SetNormalFontObject("GameFontNormal")
	newBtn:SetDisabledFontObject("GameFontDisable")
	newBtn:SetHighlightFontObject("GameFontHighlight")

	newBtn:SetText(text)
	newBtn:SetScript("OnClick", LoggerHead_ButtonOnClick)

	newBtn:Show()
	local w = newBtn:GetTextWidth()
	if w > 110 then
		newBtn:SetWidth(w + 20)
	else
		newBtn:SetWidth(120)
	end
	newBtn:Enable()

	return newBtn
end

function LoggerHead:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults, "Default")
	db = self.db.profile

	self:SetSinkStorage(self.db.profile.sink)

	if not db.version or db.version < 3 then
		db.log = {}
		db.version = 3
	end

	-- Create dialog used when prompting to enable/disable new instances
	self.promptDialog = _G.CreateFrame("Frame",
		ADDON_NAME .. "_PromptDialog", _G.UIParent, "BackdropTemplate")
	self.promptDialog:SetWidth(320)
	self.promptDialog:SetHeight(72)
	self.promptDialog:SetBackdrop(DLG_BACKDROP)
	self.promptDialog:SetToplevel(true)
	self.promptDialog:SetFrameStrata("DIALOG")
	self.promptDialog:EnableMouse(true)
	
	
	local closeBtn = _G.CreateFrame("Button", nil,
		self.promptDialog, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -3, -3)
	local text = self.promptDialog:CreateFontString(nil, nil,
		"GameFontHighlight")
	-- Leave some space for close button and other things
	text:SetWidth(320 - 60)
	text:SetPoint("TOP", 0, -16)
	self.promptDialog.text = text

	self.promptDialog.text:SetText(ADDON_NAME)
	
	local promptEnButton = self:CreateButton(ADDON_NAME .. "_PromptEnBtn",
			self.promptDialog, ENABLE)
	local promptDisButton = self:CreateButton(ADDON_NAME .. "_PromptDisBtn",
			self.promptDialog, DISABLE)
	
	promptEnButton:SetPoint("BOTTOMRIGHT", self.promptDialog,
		"BOTTOM", -6, 16)
	promptEnButton:SetID(ID_ENABLE)
	promptDisButton:SetPoint("LEFT", promptEnButton, "RIGHT", 13, 0)
	promptDisButton:SetID(ID_DISABLE)

	-- LDB launcher
	if LDB then
		LoggerHeadDS = LDB:NewDataObject(ADDON_NAME, {
			icon = LoggingCombat() and enabled_icon or disabled_icon,
			text = LoggingCombat() and enabled_text or disabled_text,
			label = COMBAT_LOG,
			type = "data source",
			OnClick = function(self, button)
				if button == "RightButton" then
					LoggerHead:ShowConfig()
				end

				if button == "LeftButton" then
					if LoggingCombat() then
						LoggerHead:DisableLogging()
					else
						LoggerHead:EnableLogging()
					end
				end
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine(ADDON_NAME)
				tooltip:AddLine(" ")
				tooltip:AddLine(L["Click to toggle combat logging"])
				tooltip:AddLine(L["Right-click to open the options menu"])
			end
		})
		if LDBIcon then
			LDBIcon:Register(ADDON_NAME, LoggerHeadDS, db.minimap)
			if (not db.minimap.hide) then LDBIcon:Show(ADDON_NAME) end
		end
	end

	self:SetupOptions()

	self:RegisterChatCommand("loggerhead", function() LoggerHead:ShowConfig() end)

	hooksecurefunc("LoggingCombat", function(input)
		LoggerHead:UpdateLDB()
	end)
end


function LoggerHead:OnEnable()
	self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED","Update")
	self:RegisterEvent("UPDATE_INSTANCE_INFO","Update")
	self:Update()
end

function LoggerHead:ForceUpdate()
	self.lastzone = nil
	self:Update()
end

function LoggerHead:Update(event)
	local zone, zonetype, difficulty, difficultyName = self:GetInstanceInformation()
	if (not zone) and difficulty == 0 then return end
	if zone == self.lastzone and difficulty == self.lastdiff then
	  -- do nothing if the zone hasn't ACTUALLY changed
	  -- otherwise we may override the user's manual enable/disable
	  return
	end
	self.lastzone = zone
	self.lastdiff = difficulty

	if zonetype ~= "none" and zonetype and difficulty and difficultyName and zone then
		if db.log[zonetype] == nil  then
			db.log[zonetype] = {}
		end

		if db.log[zonetype][zone] == nil then
			db.log[zonetype][zone] = {}
		end

		--Added test of 'prompt' option below. The option was added in a previous version, but apparently regressed. -JCinDE
		if db.log[zonetype][zone][difficulty] == nil then
			if db.prompt == true then 
				local data = {}
				data.prompt = L["You have entered |cffd9d919%s %s|r. Enable logging for this area?"]
				data.diff = difficultyName or ""
				data.zone = zone or ""

				data.accept = function() 
			 	 	db.log[zonetype][zone] = db.log[zonetype][zone] or {}
					db.log[zonetype][zone][difficulty] = true
					LoggerHead:ForceUpdate()
				end

				data.reject = function()
				  	db.log[zonetype][zone] = db.log[zonetype][zone] or {}
					db.log[zonetype][zone][difficulty] = false
					LoggerHead:ForceUpdate()
				end

				self.promptDialog:Hide()

				self.promptDialog.data = data

				_G.PlaySound(SOUNDKIT.READY_CHECK)
				self.promptDialog:SetPoint("TOP", _G.UIParent, "TOP", 0, -135)
				self.promptDialog.text:SetFormattedText(data.prompt, data.diff, data.zone)
				
				self.promptDialog:Show()
				-- height = pad + button height + pad + text
				local dlgHeight = 8 + 21 + 32 + self.promptDialog.text:GetHeight()
				self.promptDialog:SetHeight(dlgHeight)

				self.lastzone = nil
				return  -- need to return and then callback to wait for user input
			else
				db.log[zonetype][zone][difficulty] = false
			end
		end

		if db.log[zonetype][zone][difficulty] then
			self:EnableLogging()
			return
		end
	end
	self:DisableLogging()
end

function LoggerHead:UpdateLDB(slash)
	if LoggingCombat() then
		LoggerHeadDS.icon = enabled_icon 
		LoggerHeadDS.text = enabled_text
	else
		LoggerHeadDS.icon = disabled_icon 
		LoggerHeadDS.text = disabled_text
	end
end

function LoggerHead:EnableLogging()
	if not LoggingCombat() then
		self:Pour(COMBATLOGENABLED)
	end
	LoggingCombat(true)

	if db.chat then
		if not LoggingChat() then
			self:Pour(CHATLOGENABLED)
		end
		LoggingChat(true)
	end
	self:UpdateLDB()
end

function LoggerHead:DisableLogging()
	if LoggingCombat() then
		self:Pour(COMBATLOGDISABLED)
	end
	LoggingCombat(false)

	if db.chat then
		if LoggingChat() then
			self:Pour(CHATLOGDISABLED)
		end
		LoggingChat(nil)
	end
	self:UpdateLDB()
end

function LoggerHead:ShowConfig()
	InterfaceOptionsFrame_OpenToCategory(LoggerHead.optionsFrames.Profiles)
	InterfaceOptionsFrame_OpenToCategory(LoggerHead.optionsFrames.LoggerHead)
end

function LoggerHead:SetupOptions()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON_NAME, self.GenerateOptions)

	local ACD3 = LibStub("AceConfigDialog-3.0")
	LoggerHead.optionsFrames = {}
	LoggerHead.optionsFrames.LoggerHead = ACD3:AddToBlizOptions(ADDON_NAME, ADDON_NAME,nil, "general")
	LoggerHead.optionsFrames.Instances	= ACD3:AddToBlizOptions(ADDON_NAME, ARENA, ADDON_NAME,"arena")
	LoggerHead.optionsFrames.Zones		= ACD3:AddToBlizOptions(ADDON_NAME, PARTY, ADDON_NAME,"party")
	LoggerHead.optionsFrames.Pvp		= ACD3:AddToBlizOptions(ADDON_NAME, PVP, ADDON_NAME,"pvp")
	LoggerHead.optionsFrames.Unknown	= ACD3:AddToBlizOptions(ADDON_NAME, RAID, ADDON_NAME,"raid")
	LoggerHead.optionsFrames.Scenario	= ACD3:AddToBlizOptions(ADDON_NAME, SCENARIOS, ADDON_NAME,"scenario")
	LoggerHead.optionsFrames.Output		= ACD3:AddToBlizOptions(ADDON_NAME, L["Output"], ADDON_NAME,"output")
	LoggerHead.optionsFrames.Profiles	= ACD3:AddToBlizOptions(ADDON_NAME, L["Profiles"], ADDON_NAME,"profiles")
end

function LoggerHead.GenerateOptions()
	if LoggerHead.noconfig then assert(false, LoggerHead.noconfig) end

	LoggerHead.GenerateOptionsInternal()

	return LoggerHead.options
end

function LoggerHead.GenerateOptionsInternal()

--    * arena - A PvP Arena instance
--    * none - Normal world area (e.g. Northrend, Kalimdor, Deeprun Tram)
--    * party - An instance for 5-man groups
--    * pvp - A PvP battleground instance
--    * raid - An instance for raid groups

	LoggerHead.options = {
		name = 'Loggerhead',
		type = "group",
		args = {
			general = {
				name = 'Loggerhead',
				type = "group",
				args = {
					prompt = {
						order = 5,
						type = "toggle",
						name = L["Prompt on new zone?"],
						desc = L["Prompt when entering a new zone?"],
						get = function() return LoggerHead.db.profile.prompt end,
						set = function(v) LoggerHead.db.profile.prompt = not LoggerHead.db.profile.prompt end,
					},
					chatlog = {
						order = 5,
						type = "toggle",
						name = L["Enable Chat Logging"],
						desc = L["Enable Chat Logging whenever the Combat Log is enabled"],
						get = function() return LoggerHead.db.profile.chat end,
						set = function(v) LoggerHead.db.profile.chat = not LoggerHead.db.profile.chat end,
					},
					minimap = {
						type = "toggle",
						name = L["Show minimap icon"],
						desc = L["Toggle showing or hiding the minimap icon."],
						get = function() return not LoggerHead.db.profile.minimap.hide end,
						set = function(info, v)
							LoggerHead.db.profile.minimap.hide = not v
							if v then
								LDBIcon:Show(ADDON_NAME)
							else
								LDBIcon:Hide(ADDON_NAME)
							end
						end,
						order = 6,
						hidden = function() return not LDBIcon or not LDBIcon:IsRegistered(ADDON_NAME) end,
					},
				},
			},
			arena = {
				order = 1,
				type = "group",
				name = ARENA,
				desc = SETTINGS,
				args = {},
			},
			party = {
				order = 2,
				type = "group",
				name = PARTY,
				desc = SETTINGS,
				args = {},
			},
			pvp = {
				order = 3,
				type = "group",
				name = PVP,
				desc = SETTINGS,
				args = {},
			},
			raid = {
				order = 4,
				type = "group",
				name = RAID,
				desc = SETTINGS,
				args = {},
			},
			scenario = {
				order = 5,
				type = "group",
				name = SCENARIOS,
				desc = SETTINGS,
				args = {},
			},
			output = LoggerHead:GetSinkAce3OptionsDataTable(),
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LoggerHead.db),
		},
	}

	local function buildmenu(options,zonetype,zone,difficulties)
		local d = {}

		--build our difficulty option table
		for difficulty,_ in pairs(difficulties) do
			d[tonumber(difficulty)] = difficultyLookup[difficulty]
		end

		options.args[zonetype].args[zone] = {
			type = "multiselect",
			name = zone,
			desc = BINDING_NAME_TOGGLECOMBATLOG,
			values = function() return d end,
			get = function(info,key) return (LoggerHead.db.profile.log[zonetype][zone][key]) or nil end,
			set = function(info,key, value) LoggerHead.db.profile.log[zonetype][zone][key] = value end,
		}
	end

	for zonetype,v in pairs(db.log) do
		if zonetype ~= "none" then
			for zone,v2 in pairs(v) do
				if zonetype ~= "none" then
					buildmenu(LoggerHead.options,zonetype,zone,v2)
				end
			end
		end
	end
end

function LoggerHead:GetInstanceInformation()
	local zone, zonetype, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapid = GetInstanceInfo()
	if garrisonmaps[mapid] then return nil end
	local difficulty = difficultyIndex	
	return zone, zonetype, difficulty, difficultyLookup[difficulty]
end

