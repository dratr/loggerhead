local LoggerHead = LibStub("AceAddon-3.0"):NewAddon("LoggerHead", "AceConsole-3.0","AceEvent-3.0","AceTimer-3.0","LibSink-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LoggerHead", true)
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)

local GetInstanceInfo = GetInstanceInfo

local difficultyLookup = { 
	DUNGEON_DIFFICULTY1, 
	DUNGEON_DIFFICULTY2, 
	RAID_DIFFICULTY_10PLAYER, 
	RAID_DIFFICULTY_25PLAYER,
	RAID_DIFFICULTY_10PLAYER_HEROIC,
	RAID_DIFFICULTY_25PLAYER_HEROIC,
	RAID_DIFFICULTY_20PLAYER,
	RAID_DIFFICULTY_40PLAYER
}

local db
local defaults = {
	profile = {
		log = {},
		prompt = true,
		transcriptor = false,
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
	StaticPopupDialogs["LoggerHeadLogConfirm"] = {
		text = L["You have entered |cffd9d919%s|r. Enable logging for this area?"],
		button1 = ENABLE,
		button2 = DISABLE,
		sound = "levelup2",
		whileDead = 0,
		hideOnEscape = 1,
		timeout = 0,
		OnAccept = function()
			local zone, type, difficulty = self:GetInstanceInformation()
			
			if LoggerHead.db.profile.log[type] == nil  then
				LoggerHead.db.profile.log[type] = {}
			end
				
			if LoggerHead.db.profile.log[type][zone] == nil then
				LoggerHead.db.profile.log[type][zone] = {}
			end

			LoggerHead.db.profile.log[type][zone][difficulty] = true
			self:ZoneChangedNewArea()
		end,
		OnCancel = function()
			local zone, type, difficulty = self:GetInstanceInformation()
			
			if LoggerHead.db.profile.log[type] == nil  then
				LoggerHead.db.profile.log[type] = {}
			end
				
			if LoggerHead.db.profile.log[type][zone] == nil then
				LoggerHead.db.profile.log[type][zone] = {}
			end

			LoggerHead.db.profile.log[type][zone][difficulty] = false
			self:ZoneChangedNewArea()
		end
	}

	self.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults, "Default")

	db = self.db.profile
	self:SetSinkStorage(self.db.profile.sink)
	
	if not db.version or db.version < 3 then
		db.log = {}
		db.version = 3
	end	

	-- LDB launcher
	if LDB then
		LoggerHeadDS = LDB:NewDataObject("LoggerHead", {
			icon = "Interface\\AddOns\\LoggerHead\\disabled",
			label = COMBAT_LOG,
			text = COMBATLOGDISABLED,
			type = "data source",
			OnClick = function(self, button)
				if button == "RightButton" then
					LoggerHead:ShowConfig()
				end
		
				if button == "LeftButton" then
					print('here',LoggingCombat())
					if LoggingCombat() then
						LoggerHead:DisableLogging()
					else
						LoggerHead:EnableLogging()
					end
				end
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("LoggerHead")
				tooltip:AddLine(" ")
				tooltip:AddLine(L["Click to toggle combat logging"])
				tooltip:AddLine(L["Right-click to open the options menu"])
			end
		})
		if LDBIcon then
			LDBIcon:Register("LoggerHead", LoggerHeadDS, db.minimap)
			if (not db.minimap.hide) then LDBIcon:Show("LoggerHead") end
		end
	end

	self:SetupOptions()
	
	self:RegisterChatCommand("loggerhead", LoggerHead.ShowConfig )
end


function LoggerHead:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")
	self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED","ZoneChangedNewArea")
	self:RegisterEvent("UPDATE_INSTANCE_INFO","ZoneChangedNewArea")

	self:ZoneChangedNewArea()
end

function LoggerHead:ZoneChangedNewArea()
	local zone, type, difficulty, difficultyName = self:GetInstanceInformation()

	if not zone then
		-- zone hasn't been loaded yet, try again in 5 secs.
		self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
		--self:Print("Unable to determine zone - retrying in 5 secs")
		return
	end

	--self:Print(type,zone,difficulty,difficultyName)
	
	if type ~= "none" then
		if LoggerHead.db.profile.log[type] == nil  then
			LoggerHead.db.profile.log[type] = {}
		end
			
		if LoggerHead.db.profile.log[type][zone] == nil then
			LoggerHead.db.profile.log[type][zone] = {}
		end

		--Added test of 'prompt' option below. The option was added in a previous version, but apparently regressed. -JCinDE
		if LoggerHead.db.profile.log[type][zone][difficulty] == nil then
			if  LoggerHead.db.profile.prompt == true then
				StaticPopup_Show("LoggerHeadLogConfirm", ((difficultyName or "").." "..zone))
				return  -- need to return and then callback to wait for user input 
			else
				LoggerHead.db.profile.log[type][zone][difficulty] = false
			end
		end

		if LoggerHead.db.profile.log[type][zone][difficulty] then
			self:EnableLogging()
		else
			self:DisableLogging()
		end
	end
end

function LoggerHead:EnableLogging()
	if not LoggingCombat() then
		self:Pour(COMBATLOGENABLED)
	end
	LoggingCombat(1)

	if IsAddOnLoaded("Transcriptor") and LoggerHead.db.profile.transcriptor then
		Transcriptor:StartLog()
	end

	if LoggerHead.db.profile.chat then
		if not LoggingChat() then
			self:Pour(CHATLOGENABLED)
		end
		LoggingChat(1)
	end

	LoggerHeadDS.icon = "Interface\\AddOns\\LoggerHead\\enabled"
	LoggerHeadDS.text = "|cff00ff00"..L["Enabled"].."|r"
end

function LoggerHead:DisableLogging()

	if LoggingCombat() then
		self:Pour(COMBATLOGDISABLED)
	end

	if LoggingCombat() and IsAddOnLoaded("Transcriptor") and LoggerHead.db.profile.transcriptor then
		Transcriptor:StopLog()
	end	

	LoggingCombat(0)

	if LoggerHead.db.profile.chat then
		if LoggingChat() then
			self:Pour(CHATLOGDISABLED)
		end
		LoggingChat(0)
	end

	LoggerHeadDS.icon = "Interface\\AddOns\\LoggerHead\\disabled"
	LoggerHeadDS.text = "|cffff0000"..L["Disabled"].."|r"
end

function LoggerHead:ShowConfig()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Profiles)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.LoggerHead)
end

function LoggerHead:SetupOptions()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("LoggerHead", self.GenerateOptions)

	local ACD3 = LibStub("AceConfigDialog-3.0")
	LoggerHead.optionsFrames = {}
	LoggerHead.optionsFrames.LoggerHead = ACD3:AddToBlizOptions("LoggerHead", "LoggerHead",nil, "general")
	LoggerHead.optionsFrames.Instances	= ACD3:AddToBlizOptions("LoggerHead", ARENA, "LoggerHead",string.lower(ARENA))
	LoggerHead.optionsFrames.Zones		= ACD3:AddToBlizOptions("LoggerHead", PARTY, "LoggerHead",string.lower(PARTY))
	LoggerHead.optionsFrames.Pvp		= ACD3:AddToBlizOptions("LoggerHead", PVP, "LoggerHead",string.lower(PVP))
	LoggerHead.optionsFrames.Unknown	= ACD3:AddToBlizOptions("LoggerHead", RAID, "LoggerHead",string.lower(RAID))
	LoggerHead.optionsFrames.Output		= ACD3:AddToBlizOptions("LoggerHead", L["Output"], "LoggerHead","output")
	LoggerHead.optionsFrames.Profiles	= ACD3:AddToBlizOptions("LoggerHead", L["Profiles"], "LoggerHead","profiles")
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
					transcriptor = {
						order = 5,
						type = "toggle",
						name = L["Enable Transcriptor Support"],
						desc = L["Enable Transcriptor Logging whenever the Combat Log is enabled"],
						get = function() return LoggerHead.db.profile.transcriptor end,
						set = function(v) LoggerHead.db.profile.transcriptor = not LoggerHead.db.profile.transcriptor end,
					},
					minimap = {
						type = "toggle",
						name = L["Show minimap icon"],
						desc = L["Toggle showing or hiding the minimap icon."],
						get = function() return not LoggerHead.db.profile.minimap.hide end,
						set = function(info, v)
							LoggerHead.db.profile.minimap.hide = not v
							if v then
								LDBIcon:Show("LoggerHead")
							else
								LDBIcon:Hide("LoggerHead")
							end
						end,
						order = 6,
						hidden = function() return not LDBIcon or not LDBIcon:IsRegistered("LoggerHead") end,
					},
				},
			},
			[string.lower(ARENA)] = {
				order = 1,
				type = "group",
				name = ARENA,
				desc = SETTINGS,
				args = {},
			},
			[string.lower(PARTY)] = {
				order = 2,
				type = "group",
				name = PARTY,
				desc = SETTINGS,
				args = {},
			},
			[string.lower(PVP)] = {
				order = 3,
				type = "group",
				name = PVP,
				desc = SETTINGS,
				args = {},
			},
			[string.lower(RAID)] = {
				order = 4,
				type = "group",
				name = RAID,
				desc = SETTINGS,
				args = {},
			},
			output = LoggerHead:GetSinkAce3OptionsDataTable()
			profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LoggerHead.db)
		},
	}

	local function buildmenu(options,type,zone,difficulties)
		local d = {}
		
		--build our difficulty option table
		for difficulty,_ in pairs(difficulties) do
			--print(type,zone,difficulty,difficultyLookup[difficulty])
			d[tonumber(difficulty)] = difficultyLookup[difficulty]
		end

		options.args[type].args[zone] = {
			type = "multiselect",
			name = zone,
			desc = BINDING_NAME_TOGGLECOMBATLOG,
			values = function() return d end,
			get = function(info,key) return (LoggerHead.db.profile.log[type][zone][key]) or nil end,
			set = function(info,key, value) LoggerHead.db.profile.log[type][zone][key] = value end,
		}
	end

	for type,v in pairs(db.log) do
		for zone,v2 in pairs(v) do
			buildmenu(LoggerHead.options,type,zone,v2)
		end
	end
	
	collectgarbage("collect")
end

function LoggerHead:GetInstanceInformation()
	local zone, type, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()
	local difficulty = 0
	
	--print(zone, type, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic)
		
	if isDynamic then
		difficulty = (maxPlayers == 25 and 4 or 3) + (dynamicDifficulty * 2)
	elseif maxPlayers == 5 then
		difficulty = difficultyIndex
	elseif maxPlayers == 20 then
		difficulty = 7
	elseif maxPlayers == 40 then
		difficulty = 8		
	elseif maxPlayers >= 10 then
		difficulty = difficultyIndex + 2
	end

	return zone, type, difficulty, difficultyLookup[difficulty]
end

