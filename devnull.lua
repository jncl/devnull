local aName, aObj = ...
local _G = _G

local pairs, ipairs, type, rawget, tostring, select, unpack, table, output, date, wipe = _G.pairs, _G.ipairs, _G.type, _G.rawget, _G.tostring, _G.select, _G.unpack, _G.table, _G.output, _G.date, _G.wipe
local LibStub, InCombatLockdown, ChatFrame1, GetMapNameByID, GetCurrentMapAreaID = _G.LibStub, _G.InCombatLockdown, _G.ChatFrame1,  _G.GetMapNameByID, _G.GetCurrentMapAreaID

-- check to see if required libraries are loaded
assert(LibStub, aName.." requires LibStub")
for _, lib in pairs{"CallbackHandler-1.0", "AceAddon-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceLocale-3.0", "LibBabble-SubZone-3.0", "AceDB-3.0", "AceDBOptions-3.0", "AceGUI-3.0",  "AceConfig-3.0", "AceConfigCmd-3.0", "AceConfigRegistry-3.0", "AceConfigDialog-3.0", "LibDataBroker-1.1",} do
	assert(LibStub:GetLibrary(lib, true), aName.." requires "..lib)
end

-- create the addon
LibStub("AceAddon-3.0"):NewAddon(aObj, aName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

-- specify where debug messages go
aObj.debugFrame = ChatFrame10
aObj.debugLevel = 1

-- store player and pet names
aObj.player = UnitName("player")
aObj.pet = UnitName("pet")

-- Get Locale
local L = LibStub("AceLocale-3.0"):GetLocale(aName)
local SZL = LibStub("LibBabble-SubZone-3.0"):GetLookupTable()

local prdb, inCity, onTaxi, exitedInst, inScenario, inGarrison

-- Map IDs can be found here: http://wowpedia.org/MapID
local nullCities = {
	-- Kalimdor
	[GetMapNameByID(321)] = true, -- Orgrimmar
	[GetMapNameByID(362)] = true, -- Thunder Bluff
	[GetMapNameByID(381)] = true, -- Darnassus
	[GetMapNameByID(471)] = true, -- The Exodar
	-- Eastern Kingdoms
	[GetMapNameByID(301)] = true, -- Stormwind City
	[GetMapNameByID(341)] = true, -- Ironforge
	[GetMapNameByID(382)] = true, -- Undercity
	[GetMapNameByID(480)] = true, -- Silvermoon City
	-- Outland (TBC)
	[GetMapNameByID(481)] = true, -- Shattrath City
	-- Northrend (WotLK)
	[GetMapNameByID(504)] = true, -- Dalaran
	-- Pandaria (MoP)
	[GetMapNameByID(903)] = true, -- Shrine of Two Moons (Horde)
	[GetMapNameByID(905)] = true, -- Shrine of Seven Stars (Alliance)
	-- [GetMapNameByID(951)] = true, -- Timeless Isle (All of it)
}
local nullTowns = {
	-- Kalimdor
	[SZL["Booty Bay"]] = true,
	[SZL["Everlook"]] = true,
	[SZL["Gadgetzan"]] = true,
	[SZL["Ratchet"]] = true,
	[SZL["Theramore Isle"]] = true,
	[SZL["Mudsprocket"]] = true,
	-- Eastern Kingdoms
	[SZL["Goldshire"]] = true, -- in Elwynn Forest
	-- Outland (TBC)
	[SZL["Thrallmar"]] = true, -- Hellfire Peninsula (Horde)
	[SZL["Honor Hold"]] = true, -- Hellfire Peninsula (Alliance)
	[SZL["Area 52"]] = true, -- Netherstorm
	-- Northrend (WotLK)
	[SZL["Warsong Hold"]] = true, --  Borean Tundra (Horde)
	[SZL["Valiance Keep"]] = true, --  Borean Tundra (Alliance)
	[SZL["Vengeance Landing"]] = true, -- Howling Fjord (Horde)
	[SZL["Valgarde"]] = true, -- Howling Fjord (Alliance)
}
local nullAreas = {
	[SZL["The Old Port Authority"]] = true, -- in BB
	[SZL["The Salty Sailor Tavern"]] = true, -- in BB
	[SZL["Foothold Citadel"]] = true, -- in Theramore Isle
	[SZL["The Darkmoon Faire"]] = true, -- Darkmoon Island (patch 4.3)
	[SZL["KTC Headquarters"]] = true, -- Goblin starting area (Cataclysm)
	[GetMapNameByID(799)] = true, -- Karazhan
	[SZL["Krom'gar Fortress"]] = true, -- Horde Base in Stonetalon Mts (Cataclysm)
	["The Celestial Court"] = true, -- Timeless Isle (MoP)
}
local checkZones = {
	-- used for smaller area changes
	[GetMapNameByID(11)] = true, -- Northern Barrens (for Ratchet)
	[GetMapNameByID(30)] = true, -- Elwynn Forest (for Goldshire)
	[GetMapNameByID(32)] = true, -- Deadwind Pass (for Karazhan)
	[GetMapNameByID(81)] = true, -- Stonetalon Mountains (for Krom'gar Fortess)
	[GetMapNameByID(141)] = true, -- Dustwallow Marsh (for Theramore Isle)
	[GetMapNameByID(161)] = true, -- Tanaris (for Gadgetzan)
	[GetMapNameByID(281)] = true, -- Winterspring (for Everlook)
	[GetMapNameByID(465)] = true, -- Hellfire Peninsula (for Honor Hold)
	[GetMapNameByID(479)] = true, -- Netherstorm (for Area 52)
	[GetMapNameByID(486)] = true, -- Borean Tundra (for Valiance Keep/Warsong Hold)
	[GetMapNameByID(491)] = true, -- Howling Fjord (for Valgarde/Vengeance Landing)
	[GetMapNameByID(673)] = true, -- The Cape of Stranglethorn (for Booty Bay)
	[GetMapNameByID(605)] = true, -- Kezan (for KTC Headquarters)
	[GetMapNameByID(951)] = true, -- Timeless Isle
}
local garrisonZones = {
	[971] = true, -- Lunarfall (Alliance)
	[976] = true, -- Frostwall (Horde)
}
local checkEvent = {
    ["ZONE_CHANGED_INDOORS"] = true, -- for tunnel into Booty Bay
    ["ZONE_CHANGED_NEW_AREA"] = true, -- used to handle most changes of area
    ["ZONE_CHANGED"] = true, -- used to handle boat trips
    ["PLAYER_CONTROL_GAINED"] = true, -- this is for taxi check
	["SCENARIO_UPDATE"] = true, -- this is for scenario check
}
local trackEvent = {
    ["ZONE_CHANGED_NEW_AREA"] = true, -- this is for changes of area
    ["PLAYER_LEAVING_WORLD"] = true, -- this is for boat trips
    ["PLAYER_CONTROL_LOST"] = true, -- this is for taxi check
    ["PLAYER_ENTERING_WORLD"] = true, -- this is for garrison check
	["SCENARIO_UPDATE"] = true, -- this is for scenario check
}
local function enableEvents()

	aObj:LevelDebug(5, "enableEvents:", onTaxi, _G.UnitOnTaxi("player"))
	if not onTaxi and _G.UnitOnTaxi("player") then -- on Taxi
		aObj:LevelDebug(3, "on Taxi")
		aObj:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		onTaxi = true
	else
		aObj:LevelDebug(3, "registering normal events")
		-- register required events
		for tEvent, enable in pairs(trackEvent) do
			if enable then aObj:RegisterEvent(tEvent, "CheckMode") end
		end
	end

end
local function updateDBtext()

	return onTaxi and L["Taxi"]
	or inCity and L["City"]
	or inScenario and L["Scenario"]
	or prdb.inInst and L["Instance"]
	or inGarrison and L["Garrison"]
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

function aObj:CustomPrint(r, g, b, a1, ...)

	output = ("|cffffff78"..aName..":|r")

	printIt(output.." "..makeText(a1, ...), nil, r, g, b)

end

function aObj:add2Table(table, value)

	table[#table + 1] = value

end

--@debug@
function aObj:Debug(a1, ...)

	local output = ("|cff7fff7f(DBG) %s:[%s.%3d]|r"):format(aName, date("%H:%M:%S"), (_G.GetTime() % 1) * 1000)

	printIt(output.." "..makeText(a1, ...), self.debugFrame)

end

function aObj:LevelDebug(lvl, a1, ...) if self.debugLevel >= lvl then self:Debug(a1, ...) end end
--@end-debug@
--[===[@non-debug@
function aObj:Debug() end
function aObj:LevelDebug() end
--@end-non-debug@]===]

-- message filters & groups
local function msgFilter1(self, event, msg, charFrom, ...)
	aObj:LevelDebug(5, "msgFilter1:", ...)

	local charTo = select(7, ...)
	aObj:LevelDebug(3, "mf1:[%s],[%s],[%s]", msg, charFrom, charTo)

	-- allow emotes/says to/from the player/pet
	if (msg:find(aObj.player)
	or charFrom == aObj.player
	or (msg:find(L["[Yy]ou"])
	and charTo == aObj.player
	or charTo == aObj.pet))
	then
		aObj:LevelDebug(3, "Emote/Say to/from player/pet")
		return false
	else
		return true
	end

end
local function msgFilter2(self, event, msg, charFrom, ...)
	aObj:LevelDebug(5, "msgFilter2:", ...)
	aObj:LevelDebug(3, "mf2:[%s]", charFrom)

	-- allow yells from the player
	if charFrom == aObj.player
	then
		aObj:LevelDebug(3, "Player Yell")
		return false
	else
		return true
	end

end
local function msgFilter3(self, event, msg, ...)
	aObj:LevelDebug(5, "msgFilter3:", ...)
	aObj:LevelDebug(3, "mf3:[%s]", msg)

	-- ignore Duelling messages
	if msg:find(L["in a duel"])
	then
		aObj:LevelDebug(3, "Duel")
		return true
	else
		return false
	end

end
local function msgFilter4(self, event, msg, ...)
	aObj:LevelDebug(5, "msgFilter4:", ...)
	aObj:LevelDebug(3, "mf4:[%s]", msg)

	-- ignore Drunken messages
	if (msg:find(L["tipsy"])
	or msg:find(L["drunk"])
	or msg:find(L["smashed"])
	or msg:find(L["sober"]))
	then
		aObj:LevelDebug(3, "Drunken")
		return true
	else
		return false
	end

end
local function msgFilter5(self, event, msg, ...)
	aObj:LevelDebug(5, "msgFilter5:", ...)
	aObj:LevelDebug(3, "mf5:[%s]", msg)

	-- ignore discovery messages
	if msg:find(L["DISCOVERY"])
	then
		aObj:LevelDebug(3, "Discovery")
		return true
	else
		return false
	end

end
local function msgFilter6(self, event, msg, charFrom, ...)
	aObj:LevelDebug(5, "msgFilter6:", ...)
	aObj:LevelDebug(3, "mf6:[%s][%s]", msg, charFrom)

	-- ignore Achievement messages if not from Guild/Party/Raid members
	if _G.UnitIsInMyGuild(charFrom)
	or _G.UnitInParty(charFrom)
	or _G.UnitInRaid(charFrom)
	then
		aObj:LevelDebug(3, "Guild/Party/Raid Achievement")
		return false
	else
		return true
	end

end
local function addMFltrs(allFilters)

	if InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {addMFltrs, {allFilters}})
		return
	end

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

	if InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {removeMFltrs, {allFilters}})
		return
	end

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

	if InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {updateMFltrs, {}})
		return
	end

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

	if InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {addMGs, {}})
		return
	end

	-- add message groups as required
	if not prdb.noMYell then _G.ChatFrame_AddMessageGroup(ChatFrame1, "MONSTER_YELL") end
	if not prdb.noTradeskill then _G.ChatFrame_AddMessageGroup(ChatFrame1, "TRADESKILLS") end
	if not prdb.noPetInfo then _G.ChatFrame_AddMessageGroup(ChatFrame1, "PET_INFO") end
	if prdb.achFilterType == 0 then
		_G.ChatFrame_AddMessageGroup(ChatFrame1, "ACHIEVEMENT")
		_G.ChatFrame_AddMessageGroup(ChatFrame1, "GUILD_ACHIEVEMENT")
	end

end
local function removeMGs()

	if InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {removeMGs, {}})
		return
	end

	-- remove message groups as required
	if prdb.noMYell then _G.ChatFrame_RemoveMessageGroup(ChatFrame1, "MONSTER_YELL") end
	if prdb.noTradeskill then _G.ChatFrame_RemoveMessageGroup(ChatFrame1, "TRADESKILLS") end
	if prdb.noPetInfo then _G.ChatFrame_RemoveMessageGroup(ChatFrame1, "PET_INFO") end
	if prdb.achFilterType == 1 then
		_G.ChatFrame_RemoveMessageGroup(ChatFrame1, "ACHIEVEMENT")
		_G.ChatFrame_RemoveMessageGroup(ChatFrame1, "GUILD_ACHIEVEMENT")
	end

end

function aObj:OnInitialize()
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
		-- ChatFrame1 channel settings
		cf1Channels = {
		   [L["General"]]          = false,
		   [L["Trade"]]            = false,
		   [L["LocalDefense"]]     = false,
		   [L["WorldDefense"]]     = false,
		   [L["GuildRecruitment"]] = false,
		},
	}}

	self.db = LibStub("AceDB-3.0"):New(aName.."DB", defaults, "Default")

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
		prdb.noAchievement = nil
	end

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
					name = L["shhhh"] .." - "..(_G.GetAddOnMetadata(aName, "X-Curse-Packaged-Version") or _G.GetAddOnMetadata(aName, "Version") or "").."\n",
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
					name = L["Instance Settings"],
					desc = L["Change the Instance settings"],
					args = {
				        iChat = {
							type = 'toggle',
							width = "double",
				    		name = L["General chat in Instances"],
				        	desc = L["Mute General chat in Instances."],
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
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame)
		elseif optCheck[input:lower()] then
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame[optCheck[input:lower()]])
		elseif input:lower() == "status" then
			aObj:Print("City mode:", inCity, "Taxi:", onTaxi, "Instance:", prdb.inInst)
		elseif input:lower() == "loud" then
			aObj.debugLevel = 5
			aObj:Print("Debug messages ON")
		elseif input:lower() == "quiet" then
			aObj.debugLevel = 1
			aObj:Print("Debug messages OFF")
		elseif input:lower() == "locate" then
			aObj:Print("You Are Here:", _G.GetRealZoneText(), _G.GetSubZoneText(), GetCurrentMapAreaID())
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
		OnClick = function() _G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame) end,
	})

	-- handle InCombat issues
	self.oocTab = {}
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		for _, v in pairs(self.oocTab) do
			v[1](unpack(v[2]))
		end
		wipe(self.oocTab)
	end)

end

function aObj:OnEnable()
	self:LevelDebug(5, "OnEnable")

	-- register required events
	enableEvents()
	-- add message filters as required
	addMFltrs(true)
	-- remove message groups as required
	removeMGs()

	-- handle profile changes
	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadAddon")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadAddon")

end

function aObj:OnDisable()
	self:LevelDebug(5, "OnDisable")

	inCity, exitedInst, inScenario, inGarrison = nil, nil, nil ,nil

	-- unregister events
	self:UnregisterAllEvents()
	-- remove message filters as required
	removeMFltrs(true)
	-- add message groups as required
	addMGs()

	-- turn channels back on
    for channel, on in pairs(prdb.cf1Channels) do
        if on then _G.ChatFrame_AddChannel(ChatFrame1, channel) end
    end

end

do
	StaticPopupDialogs[aName.."_Reload_UI"] = {
		text = L["Confirm reload of UI to activate profile changes"],
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = function()
			_G.ReloadUI()
		end,
		OnCancel = function(this, data, reason)
			if reason == "timeout" or reason == "clicked" then
				aObj:CustomPrint(1, 1, 0, "The profile '"..aObj.db:GetCurrentProfile().."' will be activated next time you Login or Reload the UI")
			end
		end,
		timeout = 0,
		whileDead = 1,
		exclusive = 1,
		hideOnEscape = 1
	}
end
function aObj:ReloadAddon(callback)
	self:LevelDebug(5, "ReloadAddon:[%s]", callback)

	_G.StaticPopup_Show(aName.."_Reload_UI")

end

local function isGarrison(str)
	return str:find("Garrison Level") and true or false
end
function aObj:CheckMode(...)

	local event = select(1, ...)
	self:LevelDebug(2, "CheckMode: [%s]", event)

	-- if WorldMapFrame currently open defer check until it is closed
	if _G.WorldMapFrame:IsShown() then
		if not self:IsHooked(_G.WorldMapFrame, "OnHide") then
			self:SecureHookScript(_G.WorldMapFrame, "OnHide", function(this)
				self:CheckMode("WorldMap closed")
				self:Unhook(_G.WorldMapFrame, "OnHide")
			end)
		end
		return
	end

	-- force map change to get correct info
	_G.SetMapToCurrentZone()
	local rZone, rSubZone = _G.GetRealZoneText(), _G.GetSubZoneText()
    self:LevelDebug(3, "You Are Here: [%s:%s, %s]", rZone or "<Anon>", rSubZone or "<Anon>", GetCurrentMapAreaID())
	local instInfo = {_G.GetInstanceInfo()}
	self:LevelDebug(4, "inInstance#1: [%s, %s, %s, %s, %s]", prdb.inInst, instInfo[2], instInfo[1], instInfo[9], instInfo[8])

	-- handle zones when ZONE_CHANGED_NEW_AREA isn't good enough
	if checkZones[rZone] then
	    self:LevelDebug(4, "checkZone - ZONE_CHANGED event registered")
		self:RegisterEvent("ZONE_CHANGED", "CheckMode")
	else
		self:UnregisterEvent("ZONE_CHANGED")
	end

	-- handle this for the tunnel into Booty Bay
	if rZone == GetMapNameByID(673) then -- The Cape of Stranglethorn
		self:RegisterEvent("ZONE_CHANGED_INDOORS", "CheckMode")
	else
		self:UnregisterEvent("ZONE_CHANGED_INDOORS")
	end

	-- if flying then disable events
	if event == "PLAYER_CONTROL_LOST"
	and not prdb.inInst
	then
		self:LevelDebug(5, "PLAYER_CONTROL_LOST", _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"), prdb.inInst)
		self:UnregisterAllEvents()
		self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		onTaxi = true
		self.DBObj.text = updateDBtext()
		return
	-- if finished flying then enable events
	elseif event == "PLAYER_CONTROL_GAINED"
	and not prdb.inInst
	then
		self:LevelDebug(5, "PLAYER_CONTROL_GAINED", _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"), prdb.inInst)
		self:UnregisterEvent(event)
		enableEvents()
		onTaxi = false
	end

    --> Pre Event Handler <--
    -- if entering a new area or just been loaded or come out of standby
	self:LevelDebug(4, "Pre-Event Handler", checkEvent[event], prdb.inInst)
    if checkEvent[event]then
		if prdb.inInst
		then
            prdb.inInst = false
			exitedInst = true
        else
        	-- otherwise save the current channel settings for Chat Frame 1
			exitedInst = false
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
	self:LevelDebug(4, "Event Handler", nullCities[rZone], nullTowns[rSubZone], nullAreas[rSubZone])
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

    --> Instance/Scenario Handler <--
	self:LevelDebug(4, "Instance/Scenario Handler", instInfo[2] ~= "none", isGarrison(instInfo[1]), prdb.inInst, exitedInst, inScenario)
	if instInfo[2] ~= "none"
	and not isGarrison(instInfo[1])
	then
		if instInfo[2] == "scenario" then
			if not inScenario then
		        inScenario = true
		        if prdb.chatback then self:Print(L["Scenario mode enabled"]) end
			end
		else
			if not prdb.inInst then
				prdb.inInst = true
	        	if prdb.chatback then self:Print(L["Instance mode enabled"]) end
			end
		end
	else
		if exitedInst
        and prdb.chatback
		then
			if prdb.inInst
			or inScenario
			then
				self:Print(L["Instance/Scenario mode disabled"])
			end
		end
		prdb.inInst = false
		inScenario = false
    end

	--> Garrison Handler <--
	self:LevelDebug(4, "Garrison Handler", garrisonZones[GetCurrentMapAreaID()], isGarrison(instInfo[1]))
	if garrisonZones[GetCurrentMapAreaID()]
	or isGarrison(instInfo[1])
	then
		if not inGarrison then
			inGarrison = true
			if prdb.chatback then self:Print(L["Garrison mode enabled"]) end
		end
	else
		inGarrison = false
	end

	-- update message filters
	addMFltrs()
	removeMFltrs()

	-- update DB object text
	self.DBObj.text = updateDBtext()

    --> Post Event Handler <--
    -- if entering a new area or just been loaded or come out of standby
    if checkEvent[event] then
        -- Mute chat in Instances if required
        if prdb.iChat
		and prdb.inInst
		then
            for _, channel in pairs{L["General"], L["LocalDefense"], L["WorldDefense"]} do
				_G.ChatFrame_RemoveChannel(ChatFrame1, channel)
				self:LevelDebug(2, "Removed CF1 Channel: [%s]", channel)
            end
        elseif prdb.iChat
		and exitedInst
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
