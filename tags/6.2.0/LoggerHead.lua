local ADDON_NAME, ADDON_TABLE = ...
local LoggerHead = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0","AceEvent-3.0","LibSink-2.0")
local Dialog = LibStub("LibDialog-1.0")
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

local garrisonmaps = {
	[1152] = true,  -- Horde level 1
	[1330] = true,  -- Horde level 2
	[1153] = true,  -- Horde level 3
	[1158] = true,  -- Alliance level 1
	[1331] = true,  -- Alliance level 2
	[1160] = true,  -- Alliance level 3
}

local difficultyLookup = {
	DUNGEON_DIFFICULTY1,
	DUNGEON_DIFFICULTY2,
	RAID_DIFFICULTY_10PLAYER,
	RAID_DIFFICULTY_25PLAYER,
	RAID_DIFFICULTY_10PLAYER_HEROIC,
	RAID_DIFFICULTY_25PLAYER_HEROIC,
	RAID_FINDER,
	CHALLENGE_MODE,
	RAID_DIFFICULTY_40PLAYER,
	nil,
	nil, -- Norm scen
	nil, -- heroic scen
	nil,
	PLAYER_DIFFICULTY1, --14: Normal
	PLAYER_DIFFICULTY2, -- 15: Heroic
	PLAYER_DIFFICULTY6, -- 16: Mythic
	PLAYER_DIFFICULTY3 -- 17: Raid Finder
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


function LoggerHead:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults, "Default")
	db = self.db.profile

	self:SetSinkStorage(self.db.profile.sink)

	if not db.version or db.version < 3 then
		db.log = {}
		db.version = 3
	end

	Dialog:Register(ADDON_NAME, {
		text = ADDON_NAME,
		on_show = function(self, data) self.text:SetFormattedText(data.prompt, data.diff, data.zone) end,
		buttons = {
			{ text = ENABLE,
			  on_click = function(self, data) data.accept() end,
			},
			{ text = DISABLE,
			  on_click = function(self, data) data.reject() end,
			},
		},
		sound = "levelup2",
		show_while_dead = true,
		hide_on_escape = true,
	})

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
					LoggerHead:Update()
				end

				data.reject = function()
				  	db.log[zonetype][zone] = db.log[zonetype][zone] or {}
					db.log[zonetype][zone][difficulty] = false
					LoggerHead:Update()
				end

				if Dialog:ActiveDialog(ADDON_NAME) then
					Dialog:Dismiss(ADDON_NAME)
				end

				Dialog:Spawn(ADDON_NAME, data)
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

