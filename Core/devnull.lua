local aName, aObj = ...

local _G = _G
-- luacheck: ignore 631 (line is too long)

do
	-- check to see if required libraries are loaded
	assert(_G.LibStub, aName .. " requires LibStub")
	local lTab = {"AceAddon-3.0", "AceConfig-3.0", "AceConfigCmd-3.0", "AceConfigDialog-3.0", "AceConfigRegistry-3.0", "AceConsole-3.0", "AceDB-3.0", "AceDBOptions-3.0", "AceEvent-3.0", "AceGUI-3.0", "AceHook-3.0", "AceLocale-3.0", "CallbackHandler-1.0", "LibBabble-SubZone-3.0", "LibDataBroker-1.1"}
	local hasError
	for _, lib in _G.ipairs(lTab) do
		hasError = not assert(_G.LibStub:GetLibrary(lib, true), aName .. " requires " .. lib)
	end
	if hasError then return end

	-- create the addon
	_G.LibStub:GetLibrary("AceAddon-3.0"):NewAddon(aObj, aName, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")

	aObj:checkVersion()

	-- setup callback registry
	aObj.callbacks = _G.LibStub:GetLibrary("CallbackHandler-1.0"):New(aObj)

end

function aObj:OnInitialize()
	--@debug@
	self:Print("Debugging is enabled")
	self:LevelDebug(1, "Debugging is enabled")
	--@end-debug@

	self:LevelDebug(5, "OnInitialize")

	-- setup default values in table
	self:SetupDefaults()

	self.prdb = self.db.profile

	-- setup options
	self:SetupOptions()

	-- convert any old settings
	if self.prdb.CHAT_MSG_YELL then
		self.prdb.noPYell = self.prdb.CHAT_MSG_YELL
		self.prdb.CHAT_MSG_YELL = nil
	end
	if self.prdb.CHAT_MSG_MONSTER_YELL then
		self.prdb.noMYell = self.prdb.CHAT_MSG_MONSTER_YELL
		self.prdb.CHAT_MSG_MONSTER_YELL = nil
	end
	if self.prdb.CHAT_MSG_MONSTER_SAY then
		self.prdb.noNPC = self.prdb.CHAT_MSG_MONSTER_SAY
		self.prdb.CHAT_MSG_MONSTER_SAY = nil
	end
	if self.prdb.CHAT_MSG_TEXT_EMOTE then
		self.prdb.noEmote = self.prdb.CHAT_MSG_TEXT_EMOTE
		self.prdb.CHAT_MSG_TEXT_EMOTE = nil
		self.prdb.CHAT_MSG_MONSTER_EMOTE = nil
	end
	if self.prdb.CHAT_MSG_TRADESKILLS then
		self.prdb.noTradeskill = self.prdb.CHAT_MSG_TRADESKILLS
		self.prdb.CHAT_MSG_TRADESKILLS = nil
	end
	if self.prdb.CHAT_MSG_ACHIEVEMENT then
		self.prdb.noAchievement = self.prdb.CHAT_MSG_ACHIEVEMENT
		self.prdb.CHAT_MSG_ACHIEVEMENT = nil
	end
	if self.prdb.CHAT_MSG_PET_INFO then
		self.prdb.noPetInfo = self.prdb.CHAT_MSG_PET_INFO
		self.prdb.CHAT_MSG_PET_INFO = nil
	end
	-- changed Achievement type
	if self.prdb.noAchievement then
		self.prdb.achFilterType = 1
		self.prdb.noAchievement = nil
	end
	-- removed OrderHall option
	if self.prdb.noOrderHall then
		self.prdb.noOrderHall = nil
	end

	-- handle InCombat issues
	self.oocTab = {}
	self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
		for _, v in _G.pairs(self.oocTab) do
			v[1](_G.unpack(v[2]))
		end
		_G.wipe(self.oocTab)
	end)

end

function aObj:OnEnable()
	self:LevelDebug(5, "OnEnable")

	-- get existing Message Group settings
	for group, _ in _G.pairs(self.mGs) do
		if _G.tContains(_G.ChatFrame1.messageTypeList, group) then
			self.mGs[group] = true
		end
	end

	-- register required events
	self:enableEvents()

	-- get Bodyguard follower names
	self:getBGNames()

	-- remove message groups
	self:filterMGs()

	-- add message filters
	self:addMFltrs()

	self:CheckMode("OnEnable")

	-- handle profile changes
	_G.StaticPopupDialogs[aName .. "_Reload_UI"] = {
		text = self.L["Confirm reload of UI to activate profile changes"],
		button1 = _G.OKAY,
		button2 = _G.CANCEL,
		OnAccept = function()
			_G.ReloadUI()
		end,
		OnCancel = function(_, _, reason)
			if reason == "timeout"
			or reason == "clicked"
			then
				aObj.CustomPrint(1, 1, 0, "The profile '" .. aObj.db:GetCurrentProfile() .. "' will be activated next time you Login or Reload the UI")
			end
		end,
		timeout = 0,
		whileDead = 1,
		exclusive = 1,
		hideOnEscape = 1
	}
	local function reloadAddon(callback)
		aObj:LevelDebug(5, "ReloadAddon:[%s]", callback)
		-- store shortcut
		aObj.prdb = aObj.db.profile
		-- prompt for reload
		_G.StaticPopup_Show(aName .. "_Reload_UI")
	end
	self.db.RegisterCallback(self, "OnProfileChanged", reloadAddon)
	self.db.RegisterCallback(self, "OnProfileCopied", reloadAddon)
	self.db.RegisterCallback(self, "OnProfileReset", reloadAddon)

end

function aObj:OnDisable()
	self:LevelDebug(5, "OnDisable")

	-- unregister events
	self:UnregisterAllEvents()
	-- re-add message groups
	self.unfilterMGs()
	-- remove message filters
	self.removeMFltrs()

	-- turn channels back on
	for channel, on in _G.pairs(self.prdb.cf1Channels) do
		if on then
			_G.ChatFrame_AddChannel(_G.ChatFrame1, channel)
		end
	end

end

local NPCname
function aObj:CheckMode(event, ...)

	-- local event = select(1, ...)
	self:LevelDebug(2, "CheckMode: [%s, %s]", event, ... or "nil")

	-- if WorldMapFrame currently open defer check until it is closed
	if _G.WorldMapFrame:IsShown() then
		if not self:IsHooked(_G.WorldMapFrame, "OnHide") then
			self:SecureHookScript(_G.WorldMapFrame, "OnHide", function(_)
				self:CheckMode("WorldMap closed")
				self:Unhook(_G.WorldMapFrame, "OnHide")
			end)
		end
		return
	end

	-- if flying then disable events
	if event == "PLAYER_CONTROL_LOST"
	and not self.prdb.inInst
	then
		self:LevelDebug(5, "PLAYER_CONTROL_LOST", _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"), self.prdb.inInst)
		self:UnregisterAllEvents()
		self:RegisterEvent("PLAYER_CONTROL_GAINED", "CheckMode")
		_G.C_Timer.After(0.5, function() -- add delay before UnitOnTaxi check
			if _G.UnitOnTaxi("player") then
				self.onTaxi = true
				self.DBObj.text = self:updateDBtext()
			end
		end)
		return
	-- if finished flying then enable events
	elseif event == "PLAYER_CONTROL_GAINED"
	and not self.prdb.inInst
	then
		self:LevelDebug(5, "PLAYER_CONTROL_GAINED", _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"), self.prdb.inInst)
		self:UnregisterEvent(event)
		self.onTaxi = false
		_G.C_Timer.After(0.5, function() -- add delay before UnitOnTaxi check
			self:enableEvents()
		end)
	end

	-- clear remembered NPC names
	_G.wipe(self.questNPC)
	-- remember NPC name if required
	if event == "GOSSIP_SHOW"
	or event == "QUEST_DETAIL"
	or event == "QUEST_GREETING"
	or event == "QUEST_PROGRESS"
	then
		NPCname = _G.UnitName("Target")
		if NPCname then
			self.questNPC[NPCname] = true
			self:LevelDebug(4, "Saved Gossip/Quest NPC: [%s]", NPCname)
		end
		return
	end

	local cMAID = _G.C_Map.GetBestMapForUnit("player")

	if not self.isClscERA then
		-- if in a vehicle then disable events
		if event == "UNIT_ENTERED_VEHICLE"
		and _G.select(1, ...) == " "
		then
			self:LevelDebug(5, "UNIT_ENTERED_VEHICLE", cMAID)
			self:UnregisterAllEvents()
			self:RegisterEvent("UNIT_EXITED_VEHICLE", "CheckMode")
			self.inVehicle = true
			self.DBObj.text = self:updateDBtext()
			return
		-- if exited from vehicle then enable events
		elseif event == "UNIT_EXITED_VEHICLE"
		then
			self:LevelDebug(5, "UNIT_EXITED_VEHICLE", cMAID)
			self:UnregisterEvent(event)
			self:enableEvents()
			self.inVehicle = false
		end
	end

	--> Pre Event Handler <--
	-- if entering a new area or just been loaded or come out of standby
	self:LevelDebug(4, "Pre-Event Handler", self.checkEvent[event], self.prdb.inInst)
	if self.checkEvent[event]then
		if self.prdb.inInst
		then
			self.prdb.inInst = false
			self.exitedInst = true
		else
			-- otherwise save the current channel settings for Chat Frame 1
			self.exitedInst = false
			for key, _ in _G.pairs(self.prdb.cf1Channels) do
				self.prdb.cf1Channels[key] = false
			end
			local cwc = {_G.GetChatWindowChannels(1)}
			for	 i = 1, #cwc, 2 do
				self:LevelDebug(3, "cwc: [%s]", cwc[i])
				self.prdb.cf1Channels[cwc[i]] = true
			end
		end
	end

	local rZone, rSubZone = _G.GetRealZoneText(), _G.GetSubZoneText()
	self:LevelDebug(3, "You Are Here: [%s:%s, %s]", rZone or "<Anon>", rSubZone or "<Anon>", cMAID)

	--> Event Handler <--
	self:LevelDebug(4, "Event Handler", self.nullHubs[rZone], self.nullHubsByID[cMAID], self.nullTowns[rSubZone], self.nullTownsByID[cMAID], self.nullAreas[rSubZone], self.sanctuaries[rZone], self.sanctuaries[rSubZone], self.sanctuariesByID[cMAID])
	if self.nullHubs[rZone]
	or self.nullHubsByID[cMAID]
	or self.nullTowns[rSubZone]
	or self.nullTownsByID[cMAID]
	or self.nullAreas[rSubZone]
	or self.sanctuaries[rZone]
	or self.sanctuaries[rSubZone]
	or self.sanctuariesByID[cMAID]
	then
		if not self.inHub then
			self.inHub = true
			if self.prdb.chatback then self:Print(self.L["Hub mode enabled"]) end
		end
	else
		self.inHub = false
	end

	if self.isRtl then
		--> Garrison Handler <--
		self:LevelDebug(4, "Garrison Handler", _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_6_0), _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_7_0), self.sanctums[rSubZone], self.sanctumsByID[cMAID])
		if _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_6_0)
		or _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_7_0) -- Order Hall
		or self.sanctums[rSubZone]
		or self.sanctumsByID[cMAID]
		then
			if not self.inGarrison then
				self.inGarrison = true
				if self.prdb.chatback then
					self:Print(self.L["Garrison mode enabled"])
				end
			end
		else
			self.inGarrison = false
		end
		--> Instance/Scenario Handler <--
		local instInfo = {_G.GetInstanceInfo()}
		self:LevelDebug(4, "inInstance#1: [%s, %s, %s, %s, %s]", self.prdb.inInst, instInfo[2], instInfo[1], instInfo[9], instInfo[8])
		self:LevelDebug(4, "Instance/Scenario Handler", instInfo[2] ~= "none", self:isGarrison(instInfo[1]), self.prdb.inInst, self.exitedInst, self.inScenario, _G.C_Scenario.IsInScenario())
		if instInfo[2] ~= "none"
		and not self:isGarrison(instInfo[1])
		then
			if instInfo[2] == "scenario"
			or (instInfo[2] == "party"
			and instInfo[1]:find("Boost Experience"))
			then
				if not self.inScenario then
					self.inScenario = true
					if self.prdb.chatback then self:Print(self.L["Scenario mode enabled"]) end
				end
			else
				if not self.prdb.inInst then
					self.prdb.inInst = true
					if self.prdb.chatback then self:Print(self.L["Instance mode enabled"]) end
				end
			end
		else
			self.inScenario = false
			self.prdb.inInst = false
		end
	end

	-- update message filters
	self:updateMFltrs()

	-- update DB object text
	self.DBObj.text = self:updateDBtext()

	--> Post Event Handler <--
	-- if entering a new area or just been loaded or come out of standby
	if self.checkEvent[event] then
		-- Mute chat in Instances if required
		if self.prdb.noIChat
		and self.prdb.inInst
		then
			for _, channel in _G.pairs{self.L["General"], self.L["LocalDefense"], self.L["WorldDefense"]} do
				_G.ChatFrame_RemoveChannel(_G.ChatFrame1, channel)
				self:LevelDebug(2, "Removed CF1 Channel: [%s]", channel)
			end
		elseif self.prdb.noIChat
		and self.exitedInst
		then
			for channel, on in _G.pairs(self.prdb.cf1Channels) do
				if on then
					_G.ChatFrame_AddChannel(_G.ChatFrame1, channel)
					self:LevelDebug(2, "Added CF1 Channel: [%s]", channel)
				end
			end
		end
	end

end
