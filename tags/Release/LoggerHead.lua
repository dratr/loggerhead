local LoggerHead = LibStub("AceAddon-3.0"):NewAddon("LoggerHead", "AceConsole-3.0","AceEvent-3.0","AceTimer-3.0","LibSink-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LoggerHead", true)
local T = LibStub("LibTourist-3.0")
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

LoggerHead.dd = LibStub("LibDataBroker-1.1"):NewDataObject("LoggerHead", {
	icon = "Interface\\AddOns\\LoggerHead\\disabled", 
	label = L["Combat Log"], 
	text = L["Disabled"],
	type = "data source",
	OnClick = function(self, button)
		if button == "RightButton" then
			LoggerHead:LoadConfig()
		end
		
		if button == "LeftButton" then
			if LoggingCombat() then
				LoggerHead:DisableLogging()
			else
				LoggerHead:EnableLogging()
			end
		end
	end
})

local db
local defaults = {
	profile = {
		log = {}, 
		prompt = true,
		default = false,
		sink = {},
	}
}

local function createoptions()
	local Kalimdor, Eastern_Kingdoms, Outland, Northrend = GetMapContinents()

--	LoggerHead:Print(Kalimdor, Eastern_Kingdoms, Outland, Northrend)

	Kalimdor, Eastern_Kingdoms, Outland, Northrend = Kalimdor:gsub(" ",""), Eastern_Kingdoms:gsub(" ",""), Outland:gsub(" ",""), Northrend:gsub(" ","")

	local options = {
		name = 'Loggerhead',
		type = "group",
		args = {
			instances = {
				order = 1,
				type = "group",
				name = L["Instances"],
				desc = L["Instance log settings"],
				args = {
					[Eastern_Kingdoms] = {
						type = "group",
						name = BZ["Eastern Kingdoms"],
						desc = L["Instance log settings"],
						args = {},
					},
					[Kalimdor] = {
						type = "group",
						name = BZ["Kalimdor"],
						desc = L["Instance log settings"],
						args = {},
					},
					[Outland] = {
						type = "group",
						name = BZ["Outland"],
						desc = L["Instance log settings"],
						args = {},
					},
					[Northrend] = {
						type = "group",
						name = BZ["Northrend"],
						desc = L["Instance log settings"],
						args = {},
					},
				},
			},
			zones = {
				order = 2,
				type = "group",
				name = L["Zones"],
				desc = L["Zone log settings"],
				args = {
					[Eastern_Kingdoms] = {
						type = "group",
						name = BZ["Eastern Kingdoms"],
						desc = L["Zone log settings"],
						args = {},
					},
					[Kalimdor] = {
						type = "group",
						name = BZ["Kalimdor"],
						desc = L["Zone log settings"],
						args = {},
					},
					[Outland] = {
						type = "group",
						name = BZ["Outland"],
						desc = L["Zone log settings"],
						args = {},
					},
					[Northrend] = {
						type = "group",
						name = BZ["Northrend"],
						desc = L["Zone log settings"],
						args = {},
					},
				},
			},
			--spacer = { type = "header", order = 3 },
			prompt = {
				order = 5,
				type = "toggle",
				name = L["Prompt on new zone?"],
				desc = L["Prompt when entering a new zone?"],
				get = function() return LoggerHead.db.profile.prompt end,
				set = function(v) LoggerHead.db.profile.prompt = not LoggerHead.db.profile.prompt end,
			},
		},
	}

	for zone in T:IterateZonesAndInstances() do
		local continent = (T:GetContinent(zone)):gsub(" ","")

		--LoggerHead:Print(continent)

		if (continent ~= UNKNOWN) then
			local type = T:IsInstance(zone) and "instances" or "zones"
			local key = zone:gsub(" ", "_")

			--LoggerHead:Print(continent,tostring(options.args[type].args[continent]))

			if (options.args[type] and options.args[type].args[continent]) then
				options.args[type].args[continent].args[key] = {
					type = "toggle",
					name = zone,
					desc = L["Toggle Logging"],
					get = function() return LoggerHead.db.profile.log[zone] end,
					set = function(v) LoggerHead.db.profile.log[zone] = not LoggerHead.db.profile.log[zone] end,
				}
			end
		end
	end

	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(LoggerHead.db)
	options.args.output = LoggerHead:GetSinkAce3OptionsDataTable()

	return options
end

local options = nil
local function loadoptions()
	options = createoptions()

	LibStub("AceConfig-3.0"):RegisterOptionsTable("LoggerHead", options)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("LoggerHead", 800, 600)
	local blizzPanel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHead", "LoggerHead")
	LoggerHead:RegisterChatCommand("lh", LoggerHead.LoadConfig )
end

local hijackFrame = CreateFrame("Frame", nil, InterfaceOptionsFrame)
hijackFrame:SetScript("OnShow", function(self)
	if not options then
		loadoptions()
	end

	self:SetScript("OnShow", nil)
end)

function LoggerHead:LoadConfig()
	if not options then
		loadoptions()
	end

	LibStub("AceConfigDialog-3.0"):Open("LoggerHead")
end

function LoggerHead:OnInitialize()
	StaticPopupDialogs["LoggerHeadLogConfirm"] = {
		text = L["You have entered |cffd9d919%s|r. Do you want to enable logging for this zone/instance?"],
		button1 = L["Enable"],
		button2 = L["Disable"],
		sound = "levelup2",
		whileDead = 0,
		hideOnEscape = 1,
		timeout = 0,
		OnAccept = function()
			LoggerHead.db.profile.log[GetRealZoneText()] = true
			self:ZoneChangedNewArea()
		end,
		OnCancel = function()
			LoggerHead.db.profile.log[GetRealZoneText()] = false
			self:ZoneChangedNewArea()
		end
	}
	
	self.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults, "Default")
	db = self.db.profile
	self:SetSinkStorage(self.db.profile.sink)
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
		StaticPopup_Show("LoggerHeadLogConfirm", zone)
		return
	end

	if LoggerHead.db.profile.log[zone] then
		self:EnableLogging()
	else
		self:DisableLogging()
	end
end

function LoggerHead:EnableLogging()
	if not LoggingCombat() then
		self:Pour(L["Combat Log Enabled"])
	end
	LoggingCombat(1)
	
	self.dd.icon = "Interface\\AddOns\\LoggerHead\\enabled"
	self.dd.text = L["Enabled"]
end

function LoggerHead:DisableLogging()
	if LoggingCombat() then
		self:Pour(L["Combat Log Disabled"])
	end
	LoggingCombat(0)
	
	self.dd.icon = "Interface\\AddOns\\LoggerHead\\disabled"
	self.dd.text = L["Disabled"]
end
