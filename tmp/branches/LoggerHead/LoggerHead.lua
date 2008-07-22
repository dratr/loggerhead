LoggerHead = LibStub("AceAddon-3.0"):NewAddon("LoggerHead", "AceEvent-3.0","AceTimer-3.0","LibSink-2.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LoggerHead", true)
local T = LibStub("LibTourist-3.0")

LoggerHead.dd = LibStub("LibDataBroker-1.1"):NewDataObject("LoggerHead", {
	icon = "Interface\\AddOns\\LoggerHead\\disabled", 
	label = L["Combat Log"], 
	text = L["Disabled"],
	OnClick = function(self, button)
		if button == "RightButton" then
			LibStub("AceConfigDialog-3.0"):Open("LoggerHead")
		end
		
		if button == "LeftButton" then
			if (LoggingCombat()) then
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
		sink = {}
	}
}

options = {
    name = 'Loggerhead',
	type = "group",
	args = {
		instances = {
			order = 1,
			type = "group",
			name = L["Instances"],
			desc = L["Instance log settings"],
			args = {
				easternkingdoms = {
					type = "group",
					name = L["Eastern Kingdoms"],
					desc = L["Instance log settings"],
					args = {},
				},
 				kalimdor = {
 					type = "group",
 					name = L["Kalimdor"],
 					desc = L["Instance log settings"],
 					args = {},
 				},
 				outland = {
 					type = "group",
 					name = L["Outland"],
 					desc = L["Instance log settings"],
 					args = {},
				}
			},
		},
		zones = {
			order = 2,
			type = "group",
			name = L["Zones"],
			desc = L["Zone log settings"],
			args = {
				easternkingdoms = {
					type = "group",
					name = L["Eastern Kingdoms"],
					desc = L["Zone log settings"],
					args = {},
				},
 				kalimdor = {
 					type = "group",
 					name = L["Kalimdor"],
 					desc = L["Zone log settings"],
 					args = {},
 				},
 				outland = {
 					type = "group",
 					name = L["Outland"],
 					desc = L["Zone log settings"],
 					args = {},
 				}
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
		}
	}
}


function LoggerHead:OnInitialize()
	for zone in T:IterateEasternKingdoms() do
		--LoggerHead:Print(instance)
		local key = string.gsub(zone," ","_")
		if (T:IsInstance(zone)) then
			options.args.instances.args.easternkingdoms.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
			}
		else
				options.args.zones.args.easternkingdoms.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
			}
		end
	end
 	for zone in T:IterateKalimdor() do
 		--LoggerHead:Print(instance)
 		local key = string.gsub(zone," ","_")
 		if (T:IsInstance(zone)) then
 			options.args.instances.args.kalimdor.args[key] = {
 				type = "toggle",
 				name = zone,
 				desc = L["Toggle Logging"],
 				get = function() return LoggerHead.db.profile.log[key] end,
 				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
 			}
 		else
 				options.args.zones.args.kalimdor.args[key] = {
 				type = "toggle",
 				name = zone,
 				desc = L["Toggle Logging"],
 				get = function() return LoggerHead.db.profile.log[key] end,
 				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
 			}            
 		end
 	end
 	for zone in T:IterateOutland() do
 		local key = string.gsub(zone," ","_")
 		if (T:IsInstance(zone)) then
 			options.args.instances.args.outland.args[key] = {
 				type = "toggle",
 				name = zone,
 				desc = L["Toggle Logging"],
 				get = function() return LoggerHead.db.profile.log[key] end,
 				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
 			}
 		else
 			options.args.zones.args.outland.args[key] = {
 				type = "toggle",
 				name = zone,
 				desc = L["Toggle Logging"],
 				get = function() return LoggerHead.db.profile.log[key] end,
 				set = function() LoggerHead.db.profile.log[key] = not LoggerHead.db.profile.log[key] end,
 			}
 		end
 	end
	
	StaticPopupDialogs["LoggerHeadLogConfirm"] = {
		text = L["You have entered |cffd9d919%s|r. Do you want to enable logging for this zone/instance?"],
		button1 = L["Enable"],
		button2 = L["Disable"],
		sound = "levelup2",
		whileDead = 0,
		hideOnEscape = 1,
		timeout = 0,
		OnAccept = function()
			LoggerHead.db.profile.log[string.gsub(GetRealZoneText()," ","_")] = true
			self:ZoneChangedNewArea()
		end,
		OnCancel = function()
			LoggerHead.db.profile.log[string.gsub(GetRealZoneText()," ","_")] = false
			self:ZoneChangedNewArea()
		end
	}
	
	LoggerHead.db = LibStub("AceDB-3.0"):New("LoggerHeadDB", defaults)
	db = self.db.profile
	
	self:SetSinkStorage(self.db.profile.sink)
	options.args.output = self:GetSinkAce3OptionsDataTable()

	LibStub("AceConfig-3.0"):RegisterOptionsTable("LoggerHead", options)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("LoggerHead", 800, 600)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LoggerHead", "LoggerHead")
	self:RegisterChatCommand("lh", function() LibStub("AceConfigDialog-3.0"):Open("LoggerHead") end)	
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

	local key = string.gsub(zone," ","_")

	--Added test of 'prompt' option below. The option was added in a previous version, but apparently regressed. -JCinDE
	if LoggerHead.db.profile.log[key] == nil and LoggerHead.db.profile.prompt == true then
		StaticPopup_Show("LoggerHeadLogConfirm", zone)
		return
	end

	if LoggerHead.db.profile.log[key] then
		self:EnableLogging()
	else
		self:DisableLogging()
	end
end

function LoggerHead:EnableLogging()
	if (not LoggingCombat()) then
		self:Pour(L["Combat Log Enabled"])
	end
	LoggingCombat(1)
	
	self.dd.icon = "Interface\\AddOns\\LoggerHead\\enabled"
	self.dd.text = L["Enabled"]
end

function LoggerHead:DisableLogging()
	if (LoggingCombat()) then
		self:Pour(L["Combat Log Disabled"])
	end
	LoggingCombat(0)
	
	self.dd.icon = "Interface\\AddOns\\LoggerHead\\disabled"
	self.dd.text = L["Disabled"]
end


