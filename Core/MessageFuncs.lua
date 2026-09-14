local _, aObj = ...

local _G = _G

-- message Filters
aObj.mFilters = {
	["Global"] = {
		["achFilterType"] = {
			["mf6"] = {"CHAT_MSG_ACHIEVEMENT", "CHAT_MSG_GUILD_ACHIEVEMENT"}
		},
		["noDrunk"]       = {
			["mf3"] = {"CHAT_MSG_SYSTEM"}
		},
		["noDuel"]        = {
			["mf3"] = {"CHAT_MSG_SYSTEM"}
		},
		-- noMYell      -- handled by message groups
		-- noPetInfo    -- handled by message groups
		-- noTradeskill -- hand;ed by message groups
	},
	["City"] = {
		["noDiscovery"]   = {
			["mf5"] = {"CHAT_MSG_BG_SYSTEM_NEUTRAL"}
		},
		["noEmote"]       = {
			["mf1"] = {"CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_MONSTER_EMOTE"}
		},
		["noNPC"]         = {
			["mf4"] = {"CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_WHISPER"}
		},
		["noPYell"]       = {
			["mf2"] = {"CHAT_MSG_YELL"}
		},
	},
	["Instance"] = {
		["noIChat"]       = {
			["mf1"] = {"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_PARTY", "CHAT_MSG_MONSTER_WHISPER", "CHAT_MSG_MONSTER_BOSS_WHISPER"}
		},
	},
	["Garrison"] = {
		["noGChat"]       = {
			["mf4"] = {"CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_WHISPER"}
		},
		["noBguard"]      = {
			["mf4"] = {"CHAT_MSG_MONSTER_SAY"}
		},
	},
}
-- message Groups to filter
aObj.mGroups = {
	["MONSTER_YELL"]      = "noMYell",
	["TRADESKILLS"]       = "noTradeskill",
	["PET_INFO"]          = "noPetInfo",
	["ACHIEVEMENT"]       = "achFilterType",
	["GUILD_ACHIEVEMENT"] = "achFilterType",
}

-- N.B. return values for each Event are documented in ChatInfoDocumentation.lua

local msg, charFrom, charTo
-- "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_MONSTER_EMOTE" events
local function msgFilter1(_, event, ...)
	aObj:LevelDebug(5, "msgFilter1:", event, ...)

	msg = _G.select(1, ...)
	charFrom = _G.select(2, ...)
	charTo = _G.select(5, ...)
	aObj:LevelDebug(3, "mf1: [%s],[%s],[%s]", msg, charFrom, charTo)

	-- allow emotes/says to/from the player/pet
	if charTo == aObj.player
	or charTo == aObj.pet
	or charFrom == aObj.player
	or aObj.questNPC[charFrom]
	or msg:find(aObj.player)
	or aObj.pet and msg:find(aObj.pet)
	or msg:find(aObj.L["[Yy]ou"])
	and aObj.prdb.noEmote
	then
		aObj:LevelDebug(3, "Emote/Say to/from player/pet")
		if not aObj.questNPC[charFrom] then
			aObj.questNPC[charFrom] = true
		end
		return false, ...
	else
		return true
	end

end
-- "CHAT_MSG_YELL" event
local function msgFilter2(_, event, ...)
	aObj:LevelDebug(5, "msgFilter2:", event, ...)

	charFrom = _G.select(2, ...)
	aObj:LevelDebug(3, "mf2:[%s]", charFrom)

	-- allow yells from the player
	if charFrom == aObj.player
	and aObj.prdb.noPYell
	then
		aObj:LevelDebug(3, "Player Yell")
		return false, ...
	else
		return true
	end

end
-- "CHAT_MSG_SYSTEM" event
local function msgFilter3(_, event, ...)
	aObj:LevelDebug(5, "msgFilter3:", event, ...)

	msg = _G.select(1, ...)
	aObj:LevelDebug(3, "mf3:[%s]", msg)

	-- ignore Duelling messages
	if msg:find(aObj.L["in a duel"])
	and aObj.prdb.noDuel
	then
		aObj:LevelDebug(3, "Duel")
		return true
	-- ignore Drunken messages
	elseif msg:find(aObj.L["tipsy"])
	or msg:find(aObj.L["drunk"])
	or msg:find(aObj.L["smashed"])
	or msg:find(aObj.L["sober"])
	and aObj.prdb.noDrunk
	then
		aObj:LevelDebug(3, "Drunken")
		return true
	else
		return false, ...
	end

end
-- "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_WHISPER" events
-- "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_MONSTER_PARTY", "CHAT_MSG_MONSTER_BOSS_WHISPER" events
local function msgFilter4(_, event, ...)
	aObj:LevelDebug(5, "msgFilter4:", event, ...)

	msg = _G.select(1, ...)
	charFrom = _G.select(2, ...)
	-- charTo = _G.select(5, ...)
	aObj:LevelDebug(3, "mf4:[%s][%s]", msg, charFrom--[[, charTo]])

	-- ignore Bodyguard's chat or Reputation gains
	if aObj.modeTab.Garrison then
		if aObj.prdb.noGChat then
			return true
		elseif aObj.prdb.noBguard
		and aObj.bodyguardNames[charFrom]
		or aObj.bodyguardNames[msg:match(aObj.L["Reputation with"] .. "%s(.*)%s" .. aObj.L["increased by"])]
		then
			return true
		end
	-- ignore Instance Chat
	elseif aObj.modeTab.Instance
	and aObj.prdb.noGChat
	then
		return true
	-- ignore City NPC chat
	elseif aObj.modeTab.Hub
	or aObj.modeTab.Sanctuary
	and aObj.prdb.noNPC
	and charFrom ~= aObj.player
	or aObj.questNPC[charFrom]
	then
		return true
	else
		return false, ...
	end

end
-- "CHAT_MSG_BG_SYSTEM_NEUTRAL" event
local function msgFilter5(_, event, ...)
	aObj:LevelDebug(5, "msgFilter5:", event, ...)

	msg = _G.select(1, ...)
	aObj:LevelDebug(3, "mf5:[%s]", msg)

	-- ignore discovery messages
	if msg:find(aObj.L["DISCOVERY"]) then
		aObj:LevelDebug(3, "Discovery")
		return true
	else
		return false, ...
	end

end
-- "CHAT_MSG_ACHIEVEMENT", "CHAT_MSG_GUILD_ACHIEVEMENT" events
local function msgFilter6(_, event, ...)
	aObj:LevelDebug(5, "msgFilter6:", event, ...)

	msg = _G.select(1, ...)
	charFrom = _G.select(2, ...)
	aObj:LevelDebug(3, "mf6:[%s][%s]", msg, charFrom)

	-- ignore Achievement messages if not from Guild/Party/Raid members
	if _G.UnitIsInMyGuild(charFrom)
	or _G.UnitInParty(charFrom)
	or _G.UnitInRaid(charFrom)
	then
		aObj:LevelDebug(3, "Guild/Party/Raid Achievement")
		return false, ...
	else
		return true
	end

end
local mfFuncs = {
	["mf1"] = msgFilter1,
	["mf2"] = msgFilter2,
	["mf3"] = msgFilter3,
	["mf4"] = msgFilter4,
	["mf5"] = msgFilter5,
	["mf6"] = msgFilter6,
}

local function applyMsgFlts(table)
	aObj:LevelDebug(5, "applyMsgFlts:", table)

	for opt, oTab in _G.pairs(table) do
		if opt == "achFilterType"
		and aObj.prdb[opt] ~= 2
		then
			_G.nop()
		else
			for filter, fTab in _G.pairs(oTab) do
				for _, eName in _G.pairs(fTab) do
					aObj:LevelDebug(3, "aMF:[%s][%s][%s][%s]", opt, aObj.prdb[opt], mfFuncs[filter], eName)
					if aObj.prdb[opt] then
						_G.ChatFrameUtil.AddMessageEventFilter(eName, mfFuncs[filter])
					else
						_G.ChatFrameUtil.RemoveMessageEventFilter(eName, mfFuncs[filter])
					end
				end
			end
		end
	end
end

function aObj:updateMsgFltrs()
	-- called by CheckMode function when events trigger changes

	if _G. InCombatLockdown() then
		self:add2Table(self.oocTab, {self.updateMsgFltrs, {self}})
		return
	end

	for type, tTab in _G.pairs(self.mFilters) do
		if type == "Global" then
			applyMsgFlts(tTab)
		elseif type == "City"
		and (self.modeTab.Hub
		  or self.modeTab.Sanctuary)
		then
			applyMsgFlts(tTab)
		elseif type == "Instance"
		and self.modeTab.Instance
		then
			applyMsgFlts(tTab)
		elseif type == "Garrison"
		and self.modeTab.Garrison
		then
			applyMsgFlts(tTab)
		end
	end

end

function aObj:updateMsgGrps()

	if _G. InCombatLockdown() then
		self:add2Table(self.oocTab, {self.updateMsgGrps, {self}})
		return
	end

	-- re-add message groups if they were originally enabled
	-- otherwise remove message groups
	for mGroup, opt in _G.pairs(self.mGroups) do
		if opt ~= "achFilterType" then
			if self.prdb[opt] then
				_G.ChatFrameMixin.RemoveMessageGroup(_G. ChatFrame1, mGroup)
			else
				_G.ChatFrameMixin.AddMessageGroup(_G. ChatFrame1, mGroup)
			end
		else
			if self.prdb[opt] == 0 then
				_G.ChatFrameMixin.AddMessageGroup(_G. ChatFrame1, mGroup)
			elseif self.prdb[opt] == 2
			and mGroup:find("GUILD", 1)
			then
				_G.ChatFrameMixin.AddMessageGroup(_G. ChatFrame1, mGroup)
			else
				_G.ChatFrameMixin.RemoveMessageGroup(_G. ChatFrame1, mGroup)
			end
		end
	end

end
