local L = AceLibrary("AceLocale-2.2"):new("LoggerHead")
local T = AceLibrary("Tourist-2.0")
local Tablet = AceLibrary("Tablet-2.0")

LoggerHead = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0","AceDB-2.0", "AceEvent-2.0", "FuBarPlugin-2.0")
LoggerHead:RegisterDB("LoggerHeadDB")
LoggerHead:RegisterDefaults("profile", {
	log = {}
})

LoggerHead.hasIcon = "Interface\\AddOns\\LoggerHead\\disabled"
LoggerHead.hasNoText = true
LoggerHead.defaultPosition = "RIGHT"

--- Totally ganked this function from oTweaks/Haste

local range = function(n, CVar, d, min, max, s)
	return {
		name = n,
		type = 'range',
		desc = d,
		get = function()
			return GetCVar(CVar)
		end,
		set = function(a1)
			SetCVar(CVar, a1)
		end,
		min = min,
		max = max,
		step = s
	}
end

LoggerHead.OnMenuRequest = {
	type = "group",
	args = {
		instances = {
			order = 100,
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
			order = 200,
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
		spacer = { type = "header", order = 300 },
		combatlog = {
			order = 400,
			type = "group",
			name = L["Log Range"],
			desc = L["Log range settings."],
			args = {
				creature = range(L["Creature"], "CombatLogRangeCreature", L["Creature combat log range. Default: 30"], 5, 200, 5),
				friendlyplayers = range(L["Friendly players"], "CombatLogRangeFriendlyPlayers", L["Friendly players combat log range. Default: 50"], 5, 200, 5),
				friendlyplayerspets = range(L["Friendly players' pet"], "CombatLogRangeFriendlyPlayersPets", L["Friendly players pet combat log range. Default: 50"], 5, 200, 5),
				hostileplayers = range(L["Hostile players"], "CombatLogRangeHostilePlayers", L["Hostile players combat log range. Default: 50"], 5, 200, 5),
				hostileplayerspets = range(L["Hostile players' pet"], "CombatLogRangeHostilePlayersPets", L["Hostile players pet combat log range. Default: 50"], 5, 200, 5),
				party = range(L["Party members"], "CombatLogRangeParty", L["Party members combat log range. Default: 50"], 5, 200, 5),
				partypets = range(L["Party members' pet"], "CombatLogRangePartyPet", L["Party members' pet combat log range. Default: 50"], 5, 200, 5),
				death = range(L["Death"], "CombatDeathLogRange", L["Range for death messages. Default: 60"], 5, 200, 5),
				target = range("Target", "targetNearestDistance", "Max range for targeting. Default: 50", 30, 120, 5),
				targetradius = range("Target Radius", "targetNearestDistanceRadius", "Max radius for targeting. Default: 10", 1, 25, 1),
			}
		}
	}
}

	-- Methods

function LoggerHead:OnInitialize()
	for zone in T:IterateEasternKingdoms() do
		--LoggerHead:Print(instance)
		if (T:IsInstance(zone)) then
			local key = zone
			LoggerHead.OnMenuRequest.args.instances.args.easternkingdoms.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		else
			local key = zone
			LoggerHead.OnMenuRequest.args.zones.args.easternkingdoms.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		end
	end
	for zone in T:IterateKalimdor() do
		--LoggerHead:Print(instance)
		if (T:IsInstance(zone)) then
			local key = zone
			LoggerHead.OnMenuRequest.args.instances.args.kalimdor.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		else
			local key = zone
			LoggerHead.OnMenuRequest.args.zones.args.kalimdor.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		end
	end
	for zone in T:IterateOutland() do
		--LoggerHead:Print(instance)
		if (T:IsInstance(zone)) then
			local key = zone
			LoggerHead.OnMenuRequest.args.instances.args.outland.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		else
			local key = zone
			LoggerHead.OnMenuRequest.args.zones.args.outland.args[key] = {
				type = "toggle",
				name = zone,
				desc = L["Toggle Logging"],
				get = function() return LoggerHead.db.profile.log[key] end,
				set = function(v) LoggerHead.db.profile.log[key] = v end,
			}
		end
	end

	StaticPopupDialogs["LoggerHeadLogConfirm"] = {
		text = "You have entered |cffd9d919%s.|r Do you want to enable logging for this zone/instance?",
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
end


function LoggerHead:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA","ZoneChangedNewArea")

	self:ZoneChangedNewArea()
end

function LoggerHead:ZoneChangedNewArea()
	local zone = GetRealZoneText()

	if zone == nil or zone == "" then
		-- zone hasn't been loaded yet, try again in 5 secs.
		self:ScheduleEvent(self.ZoneChangedNewArea,5,self)
		--self:Print("Unable to determine zone - retrying in 5 secs")
		return
	end

	--self:Print(zone,tostring(LoggerHead.db.profile.log[zone]));

	--local key = string.gsub(zone," ","")
	if LoggerHead.db.profile.log[zone] == nil then
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
	if (not LoggingCombat()) then
		RaidWarningFrame:AddMessage("Combat Log Enabled")
		self:Print("Combat Log Enabled")
	end
	LoggingCombat(1)
	self:SetIcon("Interface\\AddOns\\LoggerHead\\enabled")
	self:UpdateTooltip()
end

function LoggerHead:DisableLogging()
	if (LoggingCombat()) then
		RaidWarningFrame:AddMessage("Combat Log Disabled")
		self:Print("Combat Log Disabled")
	end
	LoggingCombat(0)
	self:SetIcon("Interface\\AddOns\\LoggerHead\\disabled")
	self:UpdateTooltip()
end

function LoggerHead:ToggleLogging()
	if (LoggingCombat()) then
		self:DisableLogging()
	else
		self:EnableLogging()
	end
end

function LoggerHead:OnClick()
	self:ToggleLogging()
end

function LoggerHead:OnTooltipUpdate()
	local cat = Tablet:AddCategory(
		'columns', 2,
		'child_textR', 1,
		'child_textG', 1,
		'child_textB', 0,
		'child_text2R', 1,
		'child_text2G', 1,
		'child_text2B', 1
	)

	cat:AddLine(
		'text',L["Combat Log"],
		'text2',LoggingCombat() and L["Enabled"] or L["Disabled"]
	)
	
	--self:Print(zone,tostring(LoggerHead.db.profile.log[zone]));
end
