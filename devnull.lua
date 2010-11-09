local aName, devnull = ...
local _G = _G

-- check to see if required libraries are loaded
assert(LibStub, aName.." requires LibStub")
for _, lib in pairs{"CallbackHandler-1.0", "AceAddon-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceLocale-3.0", "LibBabble-Zone-3.0", "LibTourist-3.0", "AceDB-3.0", "AceDBOptions-3.0", "AceGUI-3.0",  "AceConfig-3.0", "AceConfigCmd-3.0", "AceConfigRegistry-3.0", "AceConfigDialog-3.0", "LibDataBroker-1.1",} do
	assert(LibStub:GetLibrary(lib, true), aName.." requires "..lib)
end

-- create the addon
LibStub("AceAddon-3.0"):NewAddon(devnull, aName, "AceConsole-3.0", "AceEvent-3.0")

-- specify where debug messages go
devnull.debugFrame = ChatFrame10
devnull.debugLevel = 5

-- store player and pet names
devnull.player = UnitName("player")
devnull.pet = UnitName("pet")

-- Get Locale
local L = LibStub("AceLocale-3.0"):GetLocale("devnull")
local ZL = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local T = LibStub("LibTourist-3.0")

local prdb, inCity, onTaxi, exitedInstBG

local nullCities = {
	[ZL["Stormwind City"]] = true,
	[ZL["Ironforge"]] = true,
	[ZL["Darnassus"]] = true,
	[ZL["Orgrimmar"]] = true,
	[ZL["Undercity"]] = true,
	[ZL["Thunder Bluff"]] = true,
	[ZL["The Exodar"]] = true, -- TBC
	[ZL["Silvermoon City"]] = true, -- TBC
	[ZL["Shattrath City"]] = true, -- TBC
	[ZL["Dalaran"]] = true, -- WotLK
}
local nullAreas = {
	[L["The Old Port Authority"]] = true, -- in BB
	[L["The Salty Sailor Tavern"]] = true, -- in BB
	[L["Foothold Citadel"]] = true, -- in Theramore Isle
}
local nullTowns = {
	[ZL["Booty Bay"]] = true,
	[ZL["Everlook"]] = true,
	[ZL["Gadgetzan"]] = true,
	[ZL["Ratchet"]] = true,
	[ZL["Theramore Isle"]] = true,
	[L["Goldshire"]] = true, -- in Elwynn Forest
	[L["Honor Hold"]] = true, -- TBC
	[L["Area 52"]] = true, -- TBC
	[L["Valiance Keep"]] = true, -- WotLK (BT)
	[L["Warsong Hold"]] = true, -- WotLK (BT)
	[L["Valgarde"]] = true, -- WotLK (HF)
	[L["Vengeance Landing"]] = true, -- WotLK (HF)
	[L["Fort Wildervar"]] = true, -- WotLK (HF)
}
local checkZones = { -- used for smaller area changes
	[ZL["Stranglethorn Vale"]] = true, -- for Booty Bay
	[ZL["Winterspring"]] = true, -- for Everlook
	[ZL["Tanaris"]] = true, -- for Gadgetzan
	[ZL["The Barrens"]] = true, -- for Ratchet
	[ZL["Dustwallow Marsh"]] = true, -- for Theramore Isle
	[ZL["Hellfire Peninsula"]] = true, -- for Honor Hold
	[ZL["Netherstorm"]] = true, -- for Area 52
	[ZL["Borean Tundra"]] = true, -- for Valiance Keep/Warsong Hold
	[ZL["Howling Fjord"]] = true, -- for Valgarde/Vengeance Landing
}
local icecrownInstances = {
	[ZL["Icecrown Citadel"]] = true,
	[ZL["Halls of Reflection"]] = true, -- Frozen Halls
	[ZL["Pit of Saron"]] = true, -- Frozen Halls
	[ZL["The Forge of Souls"]] = true, -- Frozen Halls
}
local checkEvent = {
    ["ZONE_CHANGED_INDOORS"] = true, -- for tunnel into Booty Bay
    ["ZONE_CHANGED_NEW_AREA"] = true, -- used to handle most changes of area
    ["ZONE_CHANGED"] = true, -- used to handle boat trips
    ["PLAYER_CONTROL_GAINED"] = true, -- this is for taxi check
}
local trackEvent = {
    ["ZONE_CHANGED_NEW_AREA"] = true, -- this is for changes of area
    ["PLAYER_LEAVING_WORLD"] = true, -- this is for boat trips
    ["PLAYER_CONTROL_LOST"] = true, -- this is for taxi check
}
local function enableEvents()

	devnull:LevelDebug(5, "enableEvents:", onTaxi, _G.UnitOnTaxi("player"))
	if not onTaxi and _G.UnitOnTaxi("player") then -- on Taxi
		devnull:LevelDebug(3, "on Taxi")
		devnull:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		onTaxi = true
	else
		devnull:LevelDebug(3, "registering normal events")
		-- register required events
		for tEvent, enable in pairs(trackEvent) do
			if enable then devnull:RegisterEvent(tEvent, "CheckMode") end
		end
	end

end
local function updateDBtext()

	return onTaxi and L["Taxi"]
	or inCity and L["City"]
	or prdb.inInst and L["Instance"]
	or prdb.inBG and L["Battleground"]
	or L["Off"]

end
-- Printing Functions
local function makeString(t)

	if type(t) == "table" then
		if type(rawget(t, 0)) == "userdata"
		and type(t.GetObjectType) == "function"
		then
			return ("<%s:%s>"):format(t:GetObjectType(), t:GetName() or "<Anon>")
		end
	end

	return tostring(t)

end
local function makeText(a1, ...)

	local tmpTab = {}
	local output = ""

	if a1:find("%%") and select('#', ...) >= 1 then
		for i = 1, select('#', ...) do
			tmpTab[i] = makeString(select(i, ...))
		end
		output = output .. " " .. a1:format(unpack(tmpTab))
	else
		tmpTab[1] = output
		tmpTab[2] = a1
		for i = 1, select('#', ...) do
			tmpTab[i+2] = makeString(select(i, ...))
		end
		output = table.concat(tmpTab, " ")
	end

	return output

end
local function printIt(text, frame, r, g, b)

	(frame or _G.DEFAULT_CHAT_FRAME):AddMessage(text, r, g, b, 1, 5)

end

--@debug@
function devnull:Debug(a1, ...)

	local output = ("|cff7fff7f(DBG) %s:[%s.%3d]|r"):format(aName, date("%H:%M:%S"), (GetTime() % 1) * 1000)

	printIt(output.." "..makeText(a1, ...), self.debugFrame)

end

function devnull:LevelDebug(lvl, a1, ...) if self.debugLevel >= lvl then self:Debug(a1, ...) end end
--@end-debug@
--[===[@non-debug@
function devnull:Debug() end
function devnull:LevelDebug() end
--@end-non-debug@]===]

-- message filters & groups
local function msgFilter1(self, event, msg, charFrom, ...)
	devnull:LevelDebug(5, "msgFilter1:", ...)

	local charTo = select(7, ...)
	devnull:LevelDebug(3, "mf1:[%s],[%s],[%s]", msg, charFrom, charTo)

	-- allow emotes/says to/from the player/pet
	if (msg:find(devnull.player)
	or charFrom == devnull.player
	or (msg:find(L["[Yy]ou"])
	and charTo == devnull.player
	or charTo == devnull.pet))
	then
		devnull:LevelDebug(3, "Emote/Say to/from player/pet")
		return false
	else
		return true
	end

end
local function msgFilter2(self, event, msg, charFrom, ...)
	devnull:LevelDebug(5, "msgFilter2:", ...)
	devnull:LevelDebug(3, "mf2:[%s]", charFrom)

	-- allow yells from the player
	if charFrom == devnull.player
	then
		devnull:LevelDebug(3, "Player Yell")
		return false
	else
		return true
	end

end
local function msgFilter3(self, event, msg, ...)
	devnull:LevelDebug(5, "msgFilter3:", ...)
	devnull:LevelDebug(3, "mf3:[%s]", msg)

	-- ignore Duelling messages
	if msg:find(L["in a duel"])
	then
		devnull:LevelDebug(3, "Duel")
		return true
	else
		return false
	end

end
local function msgFilter4(self, event, msg, ...)
	devnull:LevelDebug(5, "msgFilter4:", ...)
	devnull:LevelDebug(3, "mf4:[%s]", msg)

	-- ignore Drunken messages
	if (msg:find(L["tipsy"])
	or msg:find(L["drunk"])
	or msg:find(L["smashed"])
	or msg:find(L["sober"]))
	then
		devnull:LevelDebug(3, "Drunken")
		return true
	else
		return false
	end

end
local function msgFilter5(self, event, msg, ...)
	devnull:LevelDebug(5, "msgFilter5:", ...)
	devnull:LevelDebug(3, "mf5:[%s]", msg)

	-- ignore discovery messages
	if msg:find(L["DISCOVERY"])
	then
		devnull:LevelDebug(3, "Discovery")
		return true
	else
		return false
	end

end
local function msgFilter6(self, event, msg, charFrom, ...)
	devnull:LevelDebug(5, "msgFilter6:", ...)
	devnull:LevelDebug(3, "mf6:[%s][%s]", msg, charFrom)

	-- ignore Achievement messages if not from Guild/Party/Raid members
	if UnitIsInMyGuild(charFrom)
	or UnitInParty(charFrom)
	or UnitInRaid(charFrom)
	then
		devnull:LevelDebug(3, "Guild/Party/Raid Achievement")
		return false
	else
		return true
	end

end
local function addMFltrs(allFilters)

	if inCity then
		-- add message filters as required
		if prdb.noEmote then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", msgFilter1)
		end
		if prdb.noNPC then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", msgFilter1) end
		if prdb.noPYell then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", msgFilter2) end
		if prdb.noDrunk	then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter4)	end
		if prdb.noDiscovery then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", msgFilter5) end
	end

	if allFilters then
		if prdb.noDuel then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter3) end
		if prdb.achFilterType == 2 then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", msgFilter6) end
	end

end
local function removeMFltrs(allFilters)

	if not inCity
	or allFilters
	then
		-- remove message filters as required
		if prdb.noEmote then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", msgFilter1)
		end
		if prdb.noNPC then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", msgFilter1) end
		if prdb.noPYell then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", msgFilter2) end
	 	if prdb.noDrunk then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter4) end
		if prdb.noDiscovery then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", msgFilter5) end
	end

	if allFilters then
		if prdb.noDuel then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter3) end
		if prdb.achFilterType == 2 then _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_ACHIEVEMENT", msgFilter6) end
	end

end
local function updateMFltrs()

	-- update message filters as required
	if prdb.noEmote then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", msgFilter1)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", msgFilter1)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", msgFilter1)
	else
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", msgFilter1)
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", msgFilter1)
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", msgFilter1)
	end
	if prdb.noNPC then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", msgFilter1)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", msgFilter1) end
	if prdb.noPYell then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", msgFilter2)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", msgFilter2) end
	if prdb.noDuel then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter3)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter3) end
	if prdb.noDrunk then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter4)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", msgFilter4) end
	if prdb.noDiscovery then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", msgFilter5)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", msgFilter5) end
	if prdb.achFilterType == 2 then _G.ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", msgFilter6)
	else _G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_ACHIEVEMENT", msgFilter6) end

end
local function addMGs()

	-- add message groups as required
	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame"..i]
		if not prdb.noMYell then _G.ChatFrame_AddMessageGroup(cf, "MONSTER_YELL") end
		if not prdb.noTradeskill then _G.ChatFrame_AddMessageGroup(cf, "TRADESKILLS") end
		if not prdb.noPetInfo then _G.ChatFrame_AddMessageGroup(cf, "PET_INFO") end
		if prdb.achFilterType == 0 then _G.ChatFrame_AddMessageGroup(cf, "ACHIEVEMENT") end
	end

end
local function removeMGs()

	-- remove message groups as required
	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame"..i]
		if prdb.noMYell then _G.ChatFrame_RemoveMessageGroup(cf, "MONSTER_YELL") end
		if prdb.noTradeskill then _G.ChatFrame_RemoveMessageGroup(cf, "TRADESKILLS") end
		if prdb.noPetInfo then _G.ChatFrame_RemoveMessageGroup(cf, "PET_INFO") end
		if prdb.achFilterType == 1 then _G.ChatFrame_RemoveMessageGroup(cf, "ACHIEVEMENT") end
	end

end

function devnull:OnInitialize()
	self:LevelDebug(5, "OnInitialize")

--@debug@
	self:Print("Debugging is enabled")
	self:LevelDebug(1, "Debugging is enabled")
--@end-debug@

	local defaults = { profile = {
		chatback      = true,
		achFilterType = 0,
		noDiscovery   = true,
		noDrunk       = true,
		noDuel        = true,
		noEmote       = false,
		noNPC         = false,
		noPetInfo     = false,
		noTradeskill  = false,
		noMYell       = false,
		noPYell       = false,
		iChat         = true,
		inInst        = false,
		inBG          = false,
		-- ChatFrame1 channel settings
		cf1Channels = {
		   [L["General"]]          = false,
		   [L["Trade"]]            = false,
		   [L["LocalDefense"]]     = false,
		   [L["WorldDefense"]]     = false,
		   [L["GuildRecruitment"]] = false,
		},
	}}

	self.db = LibStub("AceDB-3.0"):New("devnullDB", defaults, "Default")

	prdb = self.db.profile

	-- convert any old settings
	if prdb.CHAT_MSG_YELL then
		prdb.noPYell = prdb.CHAT_MSG_YELL
		prdb.CHAT_MSG_YELL = nil
	end
	if prdb.CHAT_MSG_MONSTER_YELL then
		prdb.noMYell = prdb.CHAT_MSG_MONSTER_YELL
		prdb.CHAT_MSG_MONSTER_YELL = nil
	end
	if prdb.CHAT_MSG_MONSTER_SAY then
		prdb.noNPC = prdb.CHAT_MSG_MONSTER_SAY
		prdb.CHAT_MSG_MONSTER_SAY = nil
	end
	if prdb.CHAT_MSG_TEXT_EMOTE then
		prdb.noEmote = prdb.CHAT_MSG_TEXT_EMOTE
		prdb.CHAT_MSG_TEXT_EMOTE = nil
		prdb.CHAT_MSG_MONSTER_EMOTE = nil
	end
	if prdb.CHAT_MSG_TRADESKILLS then
		prdb.noTradeskill = prdb.CHAT_MSG_TRADESKILLS
		prdb.CHAT_MSG_TRADESKILLS = nil
	end
	if prdb.CHAT_MSG_ACHIEVEMENT then
		prdb.noAchievement = prdb.CHAT_MSG_ACHIEVEMENT
		prdb.CHAT_MSG_ACHIEVEMENT = nil
	end
	if prdb.CHAT_MSG_PET_INFO then
		prdb.noPetInfo = prdb.CHAT_MSG_PET_INFO
		prdb.CHAT_MSG_PET_INFO = nil
	end
	-- changed Achievement type
	if prdb.noAchievement then
		prdb.achFilterType = 1
	else
		prdb.achFilterType = 0
	end
	prdb.noAchievement = nil

	local optTables = {

		General = {
			type = "group",
	    	name = aName,
			get = function(info) return prdb[info[#info]] end,
			set = function(info, value) prdb[info[#info]] = value end,
			args = {
				desc = {
					type = "description",
					order = 1,
					name = L["shhhh"] .." - "..(GetAddOnMetadata(aName, "X-Curse-Packaged-Version") or GetAddOnMetadata(aName, "Version") or "").."\n",
				},
				longdesc = {
					type = "description",
					order = 2,
					name = L["Mutes various chat related annoyances while in capital cities and instances"] .. "\n",
				},
				chatback = {
					type = 'toggle',
					order = 3,
					name = L["Chat Feedback"],
					desc = L["Print chat message when toggling mute."],
				},
			},
		},
		Mutes = {
			type = "group",
			name = L["Mute Options"],
			childGroups = "tab",
			get = function(info) return prdb[info[#info]] end,
			set = function(info, value) prdb[info[#info]] = value end,
			args = {
				desc = {
					type = "description",
					name = L["Toggle the types of message to mute"],
				},
				global = {
					type = "group",
					order = 1,
					name = L["Global Settings"],
					desc = L["Change the Global settings"],
					args = {
				        achFilterType = {
							type = 'select',
							order = -1,
							name = L["Achievement Filter"],
							style = "radio",
							width = "double",
							values = {
								[0] = L["None"],
								[1] = L["All"],
								[2] = L["All except Guild/Party/Raid"]
							},
						},
						noDuel = {
							type = 'toggle',
							name = L["Duels"],
							desc = L["Mute Duel info."],
						},
				        noPetInfo = {
							type = 'toggle',
				    		name = L["Pet Info"],
				        	desc = L["Mute Pet Info."],
				        },
				        noTradeskill = {
							type = 'toggle',
				    		name = L["Tradeskills"],
				        	desc = L["Mute Tradeskills."],
				        },
						noMYell = {
							type = 'toggle',
							name = L["NPC/Mob Yells"],
							desc = L["Mute NPC/Mob Yells."],
						},
					},
				},
				city = {
					type = "group",
					order = 2,
					name = L["City/Town Settings"],
					desc = L["Change the City/Town settings"],
					args = {
						noDiscovery = {
							type = 'toggle',
							name = L["Discoveries"],
							desc = L["Mute Discovery info."],
						},
						noDrunk = {
							type = 'toggle',
							name = L["Drunks"],
							desc = L["Mute Drunken info."],
						},
						noEmote = {
							type = 'toggle',
							name = L["Emotes"],
							desc = L["Mute Emotes."],
				        },
						noNPC = {
							type = 'toggle',
							name = L["NPCs"],
							desc = L["Mute NPC chat."],
						},
						noPYell = {
							type = 'toggle',
							name = L["Player Yells"],
							desc = L["Mute Player Yells."],
						},
					},
				},
				instance = {
					type = "group",
					order = 3,
					name = L["Instance/Battleground Settings"],
					desc = L["Change the Instance/Battleground settings"],
					args = {
				        iChat = {
							type = 'toggle',
							width = "double",
				    		name = L["General chat in Instances/Battlegrounds"],
				        	desc = L["Mute General chat in Instances/Battlegrounds."],
				        },
					},
				},
			},
		},
	}

	-- add DB profile options
	optTables.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- option tables list
	local optNames = {"Mutes", "Profiles"}

	-- register the options tables and add them to the blizzard frame
	local ACR = LibStub("AceConfigRegistry-3.0")
	local ACD = LibStub("AceConfigDialog-3.0")

	LibStub("AceConfig-3.0"):RegisterOptionsTable(aName, optTables.General, {aName, "dn"})
	self.optionsFrame = ACD:AddToBlizOptions(aName, aName)

	-- register the options, add them to the Blizzard Options
	local optCheck = {}
	for _, v in ipairs(optNames) do
		local optTitle = (" "):join(aName, v)
		ACR:RegisterOptionsTable(optTitle, optTables[v])
		self.optionsFrame[L[v]] = ACD:AddToBlizOptions(optTitle, L[v], aName)
		-- build the table used by the chatCommand function
		optCheck[v:lower()] = v
	end
	-- runs when the player clicks "Okay"
	self.optionsFrame[L["Mutes"]].okay = function()
		updateMFltrs()
		addMGs()
		removeMGs()
	end

	-- Slash command handler
	local function chatCommand(input)

		if not input or input:trim() == "" then
			-- Open general panel if there are no parameters
			_G.InterfaceOptionsFrame_OpenToCategory(devnull.optionsFrame)
		elseif optCheck[input:lower()] then
			_G.InterfaceOptionsFrame_OpenToCategory(devnull.optionsFrame[optCheck[input:lower()]])
		elseif input:lower() == "dbg" then
			devnull:Print("City:", inCity, "Taxi:", onTaxi, "Instance:", prdb.inInst, "Battleground:", prdb.inBG)
		else
			LibStub("AceConfigCmd-3.0"):HandleCommand(aName, aName, input)
		end

	end

	-- Register slash command handlers
	self:RegisterChatCommand(aName, chatCommand)
	self:RegisterChatCommand("dn", chatCommand)

	-- setup the DB object
	self.DBObj = LibStub("LibDataBroker-1.1"):NewDataObject(aName, {
		type = "data source",
		text = updateDBtext(),
		icon = [[Interface\Icons\Spell_Holy_Silence]],
		OnClick = function() _G.InterfaceOptionsFrame_OpenToCategory(devnull.optionsFrame) end,
	})

end

function devnull:OnEnable()
	self:LevelDebug(5, "OnEnable")

	-- register required events
	enableEvents()
	-- add message filters as required
	addMFltrs(true)
	-- remove message groups as required
	removeMGs()

	-- check to see what mode we should be in
	self:CheckMode()

	-- handle profile changes
	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadAddon")

end

function devnull:OnDisable()
	self:LevelDebug(5, "OnDisable")

	inCity, exitedInstBG = nil, nil

	-- unregister events
	self:UnregisterAllEvents()
	-- remove message filters as required
	removeMFltrs(true)
	-- add message groups as required
	addMGs()

	-- turn channels back on
    for channel, on in pairs(cf1Channels) do
        if on then _G.ChatFrame_AddChannel(ChatFrame1, channel) end
    end

end

function devnull:ReloadAddon(callback)
	self:LevelDebug(5, "ReloadAddon:[%s]", callback)

	_G.StaticPopupDialogs["devnull_Reload_UI"] = {
		text = L["Confirm reload of UI to activate profile changes"],
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function()
			ReloadUI()
		end,
		OnCancel = function(this, data, reason)
			if reason == "timeout" or reason == "clicked" then
				self:CustomPrint(1, 1, 0, nil, nil, nil, "The profile '"..devnull.db:GetCurrentProfile().."' will be activated next time you Login or Reload the UI")
			end
		end,
		timeout = 0,
		whileDead = 1,
		exclusive = 1,
		hideOnEscape = 1
	}
	_G.StaticPopup_Show("devnull_Reload_UI")

end

function devnull:CheckMode(...)
	local event = select(1, ...)
	self:LevelDebug(1, "CheckMode: [%s]", event)
	local rZone, rSubZone = GetRealZoneText(), GetSubZoneText()
    self:LevelDebug(2,"You Are Here: [%s:%s]", rZone or "<Anon>", rSubZone or "<Anon>")
    self:LevelDebug(4,"inInstance#1: [%s, %s, %s, %s, %s]", prdb.inInst, prdb.inBG, T:IsBattleground(rZone),  T:IsInstance(rZone), icecrownInstances[rZone])

	-- handle zones when ZONE_CHANGED_NEW_AREA isn't good enough
	if checkZones[rZone] then
		self:RegisterEvent("ZONE_CHANGED", "CheckMode")
	else
		self:UnregisterEvent("ZONE_CHANGED")
	end
	-- handle this for the tunnel into Booty Bay
	if rZone == ZL["Stranglethorn Vale"] then
		self:RegisterEvent("ZONE_CHANGED_INDOORS", "CheckMode")
	else
		self:UnregisterEvent("ZONE_CHANGED_INDOORS")
	end

	-- if flying then disable events
	if event == "PLAYER_CONTROL_LOST" then
		self:UnregisterAllEvents()
		self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		onTaxi = true
		self.DBObj.text = updateDBtext()
		return
	-- if finished flying then enable events
	elseif event == "PLAYER_CONTROL_GAINED" then
		self:UnregisterEvent(event)
		enableEvents()
		onTaxi = false
	end

    --> Pre Event Handler <--
    -- if entering a new area or just been loaded or come out of standby
    if checkEvent[event]then
		if prdb.inInst or prdb.inBG then
            prdb.inInst = false
            prdb.inBG = false
			exitedInstBG = true
        else
        	-- otherwise save the current channel settings for Chat Frame 1
			exitedInstBG = false
            for key, _ in pairs(prdb.cf1Channels) do
                prdb.cf1Channels[key] = false
            end
            local cwc = {_G.GetChatWindowChannels(1)}
            for  i = 1, #cwc, 2 do
	           self:LevelDebug(3, "cwc: [%s]", cwc[i])
	           prdb.cf1Channels[cwc[i]] = true
            end
        end
    end

    --> Event Handler <--
	if nullCities[rZone]
	or nullTowns[rSubZone]
	or nullAreas[rSubZone]
	then
		if not inCity then
			inCity = true
			if prdb.chatback then self:Print(L["City/Town mode enabled"]) end
		end
	else
		if inCity then
			inCity = false
			if prdb.chatback then self:Print(L["City/Town mode disabled"]) end
		end
	end

    --> Instance/Battleground Handler <--
    if T:IsBattleground(rZone) then
        if prdb.chatback then self:Print(L["Battleground mode enabled"]) end
        prdb.inBG = true
    elseif T:IsInstance(rZone)
	or icecrownInstances[rZone]
	then
        if prdb.chatback then self:Print(L["Instance mode enabled"]) end
        prdb.inInst = true
	elseif exitedInstBG then
        if prdb.chatback then self:Print(L["Instance/Battleground mode disabled"]) end
    end
	-- update message filters
	addMFltrs()
	removeMFltrs()

	-- update DB object text
	self.DBObj.text = updateDBtext()

    --> Post Event Handler <--
    -- if entering a new area or just been loaded or come out of standby
    if checkEvent[event]	then
        -- Mute chat in Instances/Battlegrounds if required
        if prdb.iChat
		and prdb.inInst
		or prdb.inBG
		then
            for _, channel in pairs{L["General"], L["LocalDefense"], L["WorldDefense"]} do
				_G.ChatFrame_RemoveChannel(ChatFrame1, channel)
				self:LevelDebug(2, "Removed CF1 Channel: [%s]", channel)
            end
        elseif prdb.iChat
		and exitedInstBG
		then
            for channel, on in pairs(prdb.cf1Channels) do
                if on then
					_G.ChatFrame_AddChannel(ChatFrame1, channel)
					self:LevelDebug(2, "Added CF1 Channel: [%s]", channel)
				end
            end
        end
    end

end
