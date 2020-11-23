local aName, aObj = ...
local _G = _G

-- Mapping functions
function aObj:getCurrentMapAreaID()

	return _G.C_Map.GetBestMapForUnit("player") or nil

end

-- Garrison functions
local bodyguardNames = {
	-- Tormmok [193]
	-- Defender Illona (A) [207]
	-- Aeda Brightdawn (H) [207]
	-- Delvar Ironfist (A) [216]
	-- Vivianne (H) [216]
	-- Talonpriest Ishaal [218]
	-- Leorajh [219]
}
if not aObj.isClsc then
	function aObj:isGarrison(str)

		return str and str:find("Garrison Level") and true or false

	end
	function aObj:getBGNames()

		if self.prdb.noBguard then
			local info
			for _, id in _G.pairs{193, 207, 216, 218, 219} do
				info = _G.C_Garrison.GetFollowerInfo(id)
				bodyguardNames[info.name] = true
				aObj:LevelDebug(5, "Bodyguard:", info.name)
			end
			info = nil
		end

	end
else
	aObj.getBGNames = _G.nop
end

-- message filters & groups
function aObj.msgFilter1(_, event, ...)
	aObj:LevelDebug(5, "msgFilter1:", event, ...)
	local msg = _G.select(1, ...)
	local charFrom = _G.select(2, ...)
	local charTo = _G.select(7, ...)
	aObj:LevelDebug(3, "mf1:[%s],[%s],[%s]", msg, charFrom, charTo)

	-- allow emotes/says to/from the player/pet
	if msg:find(aObj.player)
	or charFrom == aObj.player
	or (msg:find(aObj.L["[Yy]ou"])
	and charTo == aObj.player
	or charTo == aObj.pet)
	or charFrom == aObj.NPC
	or aObj.questNPC[charFrom]
	then
		aObj:LevelDebug(3, "Emote/Say to/from player/pet")
		return false, ...
	else
		return true
	end

end
function aObj.msgFilter2(_, event, ...)
	aObj:LevelDebug(5, "msgFilter2:", event, ...)
	local charFrom = _G.select(2, ...)
	aObj:LevelDebug(3, "mf2:[%s]", charFrom)

	-- allow yells from the player
	if charFrom == aObj.player then
		aObj:LevelDebug(3, "Player Yell")
		return false, ...
	else
		return true
	end

end
function aObj.msgFilter3(_, event, ...)
	aObj:LevelDebug(5, "msgFilter3:", event, ...)
	local msg = _G.select(1, ...)
	aObj:LevelDebug(3, "mf3:[%s]", msg)

	-- ignore Duelling messages
	if msg:find(aObj.L["in a duel"]) then
		aObj:LevelDebug(3, "Duel")
		return true
	else
		return false, ...
	end

end
function aObj.msgFilter4(_, event, ...)
	aObj:LevelDebug(5, "msgFilter4:", event, ...)
	local msg = _G.select(1, ...)
	aObj:LevelDebug(3, "mf4:[%s]", msg)

	-- ignore Drunken messages
	if (msg:find(aObj.L["tipsy"])
	or msg:find(aObj.L["drunk"])
	or msg:find(aObj.L["smashed"])
	or msg:find(aObj.L["sober"]))
	then
		aObj:LevelDebug(3, "Drunken")
		return true
	else
		return false, ...
	end

end
function aObj.msgFilter5(_, event, ...)
	aObj:LevelDebug(5, "msgFilter5:", event, ...)
	local msg = _G.select(1, ...)
	aObj:LevelDebug(3, "mf5:[%s]", msg)

	-- ignore discovery messages
	if msg:find(aObj.L["DISCOVERY"]) then
		aObj:LevelDebug(3, "Discovery")
		return true
	else
		return false, ...
	end

end
function aObj.msgFilter6(_, event, ...)
	aObj:LevelDebug(5, "msgFilter6:", event, ...)
	local msg = _G.select(1, ...)
	local charFrom = _G.select(2, ...)
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
if not aObj.isClsc then
	-- stop messages from followers who are Bodyguards including Faction gains
	function aObj.msgFilter7(_, event, ...)
		aObj:LevelDebug(5, "msgFilter7:", event, ...)
		local msg = _G.select(1, ...)
		local charFrom = _G.select(2, ...)
		aObj:LevelDebug(3, "mf7:[%s][%s]", msg, charFrom)

		-- ignore Bodyguard's chat or Reputation gains
		if bodyguardNames[charFrom]
		or bodyguardNames[msg:match(aObj.L["Reputation with"] .. "%s(.*)%s" .. aObj.L["increased by"])]
		then
			return true
		else
			return false, ...
		end

	end
else
	aObj.msgFilter7 = _G.nop
end

function aObj:addMFltrs()

	if _G. InCombatLockdown() then
		self:add2Table(self.oocTab, {self.addMFltrs, {self}})
		return
	end

	if self.inHub then
		-- add message filters
		if self.prdb.noEmote then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", self.msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", self.msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", self.msgFilter1)
		end
		if self.prdb.noPYell then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", self.msgFilter2)
		end
		if self.prdb.noDrunk then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter4)
		end
		if self.prdb.noDiscovery then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", self.msgFilter5)
		end
	end

	if self.inHub
	or (self.inGarrison and self.prdb.gChat)
	then
		if self.prdb.noNPC then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter1)
		end
	end

	if self.prdb.noDuel then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter3)
	end

	if self.prdb.achFilterType == 2 then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", self.msgFilter6)
	end

	if self.prdb.noBguard then
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter7)
		_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", self.msgFilter7)
	end

end
function aObj:removeMFltrs(upd)

	if _G. InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {self.removeMFltrs, {self, upd}})
		return
	end

	if not self.inHub then
		-- remove message filters
		if self.prdb.noEmote then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", self.msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", self.msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", self.msgFilter1)
		end

		if self.prdb.noPYell then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", self.msgFilter2)
		end

		if self.prdb.noDrunk then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter4)
		end

		if self.prdb.noDiscovery then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", self.msgFilter5)
		end
	end

	if not self.inHub
	and not self.inGarrison
	and not self.inOrderHall
	then
		if self.prdb.noNPC then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter1)
		end
	end

	if self.prdb.noDuel then
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter3)
	end

	if self.prdb.achFilterType == 2 then
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_ACHIEVEMENT", self.msgFilter6)
	end

	if self.prdb.noBguard then
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter7)
		_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_COMBAT_FACTION_CHANGE", self.msgFilter7)
	end

end
function aObj:updateMFltrs()
	-- called by CheckMode function when events trigger changes

	if _G. InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {self.updateMFltrs, {self}})
		return
	end

	-- update message filters
	if self.inHub then
		-- add message filters
		if self.prdb.noEmote then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_EMOTE", self.msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_TEXT_EMOTE", self.msgFilter1)
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", self.msgFilter1)
		end

		if self.prdb.noPYell then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", self.msgFilter2)
		end

		if self.prdb.noDrunk then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter4)
		end

		if self.prdb.noDiscovery then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", self.msgFilter5)
		end
	else
		-- remove message filters
		if self.prdb.noEmote then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_EMOTE", self.msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_TEXT_EMOTE", self.msgFilter1)
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_EMOTE", self.msgFilter1)
		end

		if self.prdb.noPYell then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_YELL", self.msgFilter2)
		end

		if self.prdb.noDrunk then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", self.msgFilter4)
		end

		if self.prdb.noDiscovery then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_BG_SYSTEM_NEUTRAL", self.msgFilter5)
		end
	end

	if self.inHub
	or (self.inGarrison and self.prdb.gChat)
	then
		if self.prdb.noNPC then
			_G.ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter1)
		end
	else
		if self.prdb.noNPC then
			_G.ChatFrame_RemoveMessageEventFilter("CHAT_MSG_MONSTER_SAY", self.msgFilter1)
		end
	end

end
function aObj:filterMGs()

	if _G. InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {self.filterMGs, {self}})
		return
	end

	-- remove message groups
	if self.prdb.noMYell then
		_G.ChatFrame_RemoveMessageGroup(_G. ChatFrame1, "MONSTER_YELL")
	end

	if self.prdb.noTradeskill then
		_G.ChatFrame_RemoveMessageGroup(_G. ChatFrame1, "TRADESKILLS")
	end

	if self.prdb.noPetInfo then
		_G.ChatFrame_RemoveMessageGroup(_G. ChatFrame1, "PET_INFO")
	end

	if self.prdb.achFilterType == 1 then
		_G.ChatFrame_RemoveMessageGroup(_G. ChatFrame1, "ACHIEVEMENT")
		_G.ChatFrame_RemoveMessageGroup(_G. ChatFrame1, "GUILD_ACHIEVEMENT")
	end

end
function aObj:unfilterMGs()

	if _G. InCombatLockdown() then
		aObj:add2Table(aObj.oocTab, {self.unfilterMGs, {self}})
		return
	end

	-- re-add message groups if they were originally enabled
	if not self.prdb.noMYell and self.mGs["MONSTER_YELL"] then
		_G.ChatFrame_AddMessageGroup(_G. ChatFrame1, "MONSTER_YELL")
	end

	if not self.prdb.noTradeskill and self.mGs["TRADESKILLS"] then
		_G.ChatFrame_AddMessageGroup(_G. ChatFrame1, "TRADESKILLS")
	end

	if not self.prdb.noPetInfo and self.mGs["PET_INFO"] then
		_G.ChatFrame_AddMessageGroup(_G. ChatFrame1, "PET_INFO")
	end

	if self.prdb.achFilterType == 0 then
		if self.mGs["ACHIEVEMENT"] then
			_G.ChatFrame_AddMessageGroup(_G. ChatFrame1, "ACHIEVEMENT")
		end
		if self.mGs["GUILD_ACHIEVEMENT"] then
			_G.ChatFrame_AddMessageGroup(_G. ChatFrame1, "GUILD_ACHIEVEMENT")
		end
	end

end

function aObj:enableEvents()

	if not aObj.isClsc then
		aObj:LevelDebug(5, "enableEvents:", self.onTaxi, _G.UnitOnTaxi("player"), self.inVehicle, _G.UnitInVehicle("player"))
	else
		aObj:LevelDebug(5, "enableEvents:", self.onTaxi, _G.UnitOnTaxi("player"))
	end

	-- on Taxi
	if not self.onTaxi
	and _G.UnitOnTaxi("player")
	then
		aObj:LevelDebug(3, "on Taxi")
		aObj:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		self.onTaxi = true
	-- in Vehicle
	elseif not self.inVehicle
	and not aObj.isClsc
	and _G.UnitInVehicle("player")
	then
		aObj:LevelDebug(3, "in Vehicle")
		aObj:RegisterEvent("UNIT_EXITED_VEHICLE", "CheckMode")
		self.inVehicle = true
	else
		aObj:LevelDebug(3, "registering normal events")
		-- register required events
		for tEvent, enable in _G.pairs(self.trackEvent) do
			if enable then
				aObj:RegisterEvent(tEvent, "CheckMode")
			end
		end
	end

end
function aObj:updateDBtext(noShrink)

	local status = self.onTaxi and self.L["Taxi"]
	or self.inVehicle and self.L["Vehicle"]
	or self.prdb.inInst and self.L["Instance"]
	or self.inScenario and self.L["Scenario"]
	or self.inGarrison and self.L["Garrison"]
	or self.inHub and self.L["City"]
	or self.L["Off"]

	if not self.prdb.shrink
	or noShrink
	then
		return status
	else
		return status:sub(1, 1)
	end

end

-- Printing Functions
local function makeString(t)

	if _G.type(t) == "table" then
		if _G.type(_G.rawget(t, 0)) == "userdata"
		and _G.type(t.GetObjectType) == "function"
		then
			return ("<%s:%s>"):format(t:GetObjectType(), t:GetName() or "<Anon>")
		end
	end

	return _G.tostring(t)

end
local function makeText(a1, ...)

	local tmpTab = {}
	local output = ""

	if a1:find("%%") and _G.select('#', ...) >= 1 then
		for i = 1, _G.select('#', ...) do
			tmpTab[i] = makeString(_G.select(i, ...))
		end
		output = output .. " " .. a1:format(_G.unpack(tmpTab))
	else
		tmpTab[1] = output
		tmpTab[2] = a1
		for i = 1, _G.select('#', ...) do
			tmpTab[i+2] = makeString(_G.select(i, ...))
		end
		output = _G.table.concat(tmpTab, " ")
	end

	return output

end
local function printIt(text, frame, r, g, b)

	(frame or _G.DEFAULT_CHAT_FRAME):AddMessage(text, r, g, b)

end

function aObj:CustomPrint(r, g, b, fstr, ...)

	printIt(_G.WrapTextInColorCode(aName, "ffffff78") .. " " .. makeText(fstr, ...), nil, r, g, b)

end
function aObj:add2Table(table, value)

	table[#table + 1] = value

end

--@debug@
-- specify where debug messages go
aObj.debugFrame = _G.ChatFrame10
aObj.debugLevel = 1
function aObj:Debug(fstr, ...)

	local output = ("(DBG) %s:[%s.%3d]"):format(aName, _G.date("%H:%M:%S"), (_G.GetTime() % 1) * 1000)
	printIt(_G.WrapTextInColorCode(output, "ff7fff7f") .. " " .. makeText(fstr, ...), self.debugFrame)
	output = nil

end
function aObj:LevelDebug(lvl, a1, ...)

	if lvl <= self.debugLevel then
		self:Debug(a1, ...)
	end

end
--@end-debug@
--[===[@non-debug@
function aObj:Debug() end
function aObj:LevelDebug() end
--@end-non-debug@]===]

