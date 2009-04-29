local LoggerHead = LibStub("AceAddon-3.0"):NewAddon("LoggerHead", "AceConsole-3.0","AceEvent-3.0","AceTimer-3.0","LibSink-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LoggerHead", true)
local T = LibStub("LibTourist-3.0")
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)

local db
local defaults = {
	profile = {
		log = {},
		prompt = true,
		default = false,
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
			LoggerHead.db.profile.log[GetRealZoneText()] = {}
			LoggerHead.db.profile.log[GetRealZoneText()][GetInstanceDifficulty()] = true
			self:ZoneChangedNewArea()
		end,
		OnCancel = function()
			LoggerHead.db.profile.log[GetRealZoneText()] = {}
			LoggerHead.db.profile.log[GetRealZoneText()][GetInstanceDifficulty()] = false
			self:ZoneChangedNewArea()
		end
	}

	self.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults, "Default")
	db = self.db.profile
	self:SetSinkStorage(self.db.profile.sink)

	if not db.version then

		for k,v in pairs(db.log) do
			local zone = k:gsub("_", " ")
			local continent = (T:GetContinent(zone)):gsub(" ","")
			local type = T:IsInstance(zone) and "instances" or "zones"

			db.log[k] = {}
			if ((T:GetLevel(zone) >= 70 and T:GetInstanceGroupSize(zone) == 5) and type == "instances") or (continent == BZ["Northrend"]  and type == "instances") then
				db.log[k][1] = v
				db.log[k][2] = v
			else
				db.log[k][1] = v
			end
		end

		if not db.minimap then
			db.minimap = {
				hide = false,
				minimapPos = 250,
				radius = 80,
			}
		end

		db.version = 2
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
	
	self:RegisterChatCommand("lh", LoggerHead.ShowConfig )
end


function LoggerHead:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")

	self:ZoneChangedNewArea()
end

function LoggerHead:ZoneChangedNewArea()
	local zone = GetRealZoneText()

	if zone == nil or zone == "" then
		-- zone hasn't been loaded yet, try again in 5 secs.
		self:ScheduleTimer(self.ZoneChangedNewArea,5,self)
		--self:Print("Unable to determine zone - retrying in 5 secs")
		return
	end

	--self:Print(zone,tostring(LoggerHead.db.profile.log[zone]));

	--Added test of 'prompt' option below. The option was added in a previous version, but apparently regressed. -JCinDE
	if LoggerHead.db.profile.log[zone] == nil and LoggerHead.db.profile.prompt == true then
		StaticPopup_Show("LoggerHeadLogConfirm", ((GetInstanceDifficulty() > 1) and DUNGEON_DIFFICULTY2 or "").." "..zone)
		return
	end

	if LoggerHead.db.profile.log[zone] and LoggerHead.db.profile.log[zone][GetInstanceDifficulty()] then
		self:EnableLogging()
	else
		self:DisableLogging()
	end
end

function LoggerHead:EnableLogging()
	if not LoggingCombat() then
		self:Pour(COMBATLOGENABLED)
	end
	LoggingCombat(1)

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

	-- The ordering here matters, it determines the order in the Blizzard Interface Options
	local ACD3 = LibStub("AceConfigDialog-3.0")
	LoggerHead.optionsFrames = {}
	LoggerHead.optionsFrames.LoggerHead 	= ACD3:AddToBlizOptions("LoggerHead", "LoggerHead",nil, "general")
	LoggerHead.optionsFrames.Instances	= ACD3:AddToBlizOptions("LoggerHead", L["Instances"], "LoggerHead","instances")
	LoggerHead.optionsFrames.Zones		= ACD3:AddToBlizOptions("LoggerHead", L["Zones"], "LoggerHead","zones")
	LoggerHead.optionsFrames.Pvp			= ACD3:AddToBlizOptions("LoggerHead", PVP, "LoggerHead","pvp")
	LoggerHead.optionsFrames.Unknown		= ACD3:AddToBlizOptions("LoggerHead", L["Unclassified"], "LoggerHead","unknown")
	LoggerHead.optionsFrames.Output		= ACD3:AddToBlizOptions("LoggerHead", L["Output"], "LoggerHead","output")
	LoggerHead.optionsFrames.Profiles		= ACD3:AddToBlizOptions("LoggerHead", L["Profiles"], "LoggerHead","profiles")
	--LoggerHead:RegisterModuleOptions("Profiles", function() return LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db) end, L["Profiles"])
end

function LoggerHead.GenerateOptions()
	if LoggerHead.noconfig then assert(false, LoggerHead.noconfig) end
	if not LoggerHead.options then
		LoggerHead.GenerateOptionsInternal()
		LoggerHead.GenerateOptionsInternal = nil
	end
	return LoggerHead.options
end

function LoggerHead.GenerateOptionsInternal()
	local Kalimdor, Eastern_Kingdoms, Outland, Northrend = GetMapContinents()

--	LoggerHead:Print(Kalimdor, Eastern_Kingdoms, Outland, Northrend)

	Kalimdor, Eastern_Kingdoms, Outland, Northrend = Kalimdor:gsub(" ",""), Eastern_Kingdoms:gsub(" ",""), Outland:gsub(" ",""), Northrend:gsub(" ","")

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
			instances = {
				order = 1,
				type = "group",
				name = L["Instances"],
				desc = SETTINGS,
				args = {
					[BZ["Eastern Kingdoms"]] = {
						type = "group",
						name = BZ["Eastern Kingdoms"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Kalimdor"]] = {
						type = "group",
						name = BZ["Kalimdor"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Outland"]] = {
						type = "group",
						name = BZ["Outland"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Northrend"]] = {
						type = "group",
						name = BZ["Northrend"],
						desc = SETTINGS,
						args = {},
					},
				},
			},
			zones = {
				order = 2,
				type = "group",
				name = L["Zones"],
				desc = SETTINGS,
				args = {
					[BZ["Eastern Kingdoms"]] = {
						type = "group",
						name = BZ["Eastern Kingdoms"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Kalimdor"]] = {
						type = "group",
						name = BZ["Kalimdor"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Outland"]] = {
						type = "group",
						name = BZ["Outland"],
						desc = SETTINGS,
						args = {},
					},
					[BZ["Northrend"]] = {
						type = "group",
						name = BZ["Northrend"],
						desc = SETTINGS,
						args = {},
					},
				},
			},
			pvp = {
				order = 3,
				type = "group",
				name = PVP,
				desc = SETTINGS,
				args = {},
			},
			unknown = {
				order = 4,
				type = "group",
				name = UNKNOWN,
				desc = SETTINGS,
				args = {},
			},
		},
	}

	local function buildmenu(options,zone)
		local continent = (T:GetContinent(zone))--:gsub(" ","")

		if (continent ~= UNKNOWN) then
			local type = (T:IsArena(zone) or T:IsBattleground(zone) or zone == BZ["Wintergrasp"]) and "pvp" or (T:IsInstance(zone) and "instances") or "zones"
			local heroic = ((T:GetLevel(zone) >= 70 and T:GetInstanceGroupSize(zone) == 5) and type == "instances") or (continent == BZ["Northrend"]  and type == "instances")

			if (options.args[type] and type == "pvp") then
				options.args[type].args[zone] = {
					type = "multiselect",
					name = zone,
					desc = BINDING_NAME_TOGGLECOMBATLOG,
					values = function() return {[0x1] = DUNGEON_DIFFICULTY1} end,
					get = function(info,key) return (LoggerHead.db.profile.log[zone] and LoggerHead.db.profile.log[zone][key]) or nil end,
					set = function(info,key, value) if not LoggerHead.db.profile.log[zone] then LoggerHead.db.profile.log[zone] = {} end  LoggerHead.db.profile.log[zone][key] = value end,
				}
			elseif (options.args[type] and options.args[type].args[continent]) then
				if heroic then
					options.args[type].args[continent].args[zone] = {
						type = "multiselect",
						name = zone,
						desc = BINDING_NAME_TOGGLECOMBATLOG,
						values = function() return {[0x1] = DUNGEON_DIFFICULTY1, [0x2] = DUNGEON_DIFFICULTY2} end,
						get = function(info,key) return (LoggerHead.db.profile.log[zone] and LoggerHead.db.profile.log[zone][key]) or nil end,
						set = function(info,key, value) if not LoggerHead.db.profile.log[zone] then LoggerHead.db.profile.log[zone] = {} end LoggerHead.db.profile.log[zone][key] = value end,
					}
				else
					options.args[type].args[continent].args[zone] = {
						type = "multiselect",
						name = zone,
						desc = BINDING_NAME_TOGGLECOMBATLOG,
						values = function() return {[0x1] = DUNGEON_DIFFICULTY1} end,
						get = function(info,key) return (LoggerHead.db.profile.log[zone] and LoggerHead.db.profile.log[zone][key]) or nil end,
						set = function(info,key, value) if not LoggerHead.db.profile.log[zone] then LoggerHead.db.profile.log[zone] = {} end  LoggerHead.db.profile.log[zone][key] = value end,
					}
				end
			end
		else
			options.args.unknown.args[zone] = {
				type = "multiselect",
				name = zone,
				desc = BINDING_NAME_TOGGLECOMBATLOG,
				values = function() return {[0x1] = DUNGEON_DIFFICULTY1, [0x2] = DUNGEON_DIFFICULTY2} end,
				get = function(info,key) return (LoggerHead.db.profile.log[zone] and LoggerHead.db.profile.log[zone][key]) or nil end,
				set = function(info,key, value) LoggerHead.db.profile.log[zone][key] = value end,
			}
		end
	end

	for zone,value in pairs(db.log) do
		buildmenu(LoggerHead.options,zone)
	end

	for zone in T:IterateZonesAndInstances() do
		buildmenu(LoggerHead.options,zone)
	end

	LoggerHead.options.args.output = LoggerHead:GetSinkAce3OptionsDataTable()
	LoggerHead.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(LoggerHead.db)
end