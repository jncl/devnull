local aName, aObj = ...

local _G = _G

do
	if aObj:checkLibraries({"LibBabble-SubZone-3.0"}) then
		aObj:createAddOn()
	else
		return
	end
end

function aObj:OnInitialize()

	self:LevelDebug(1, "debugging is enabled")

	self:LevelDebug(5, "OnInitialize")

	-- setup default values in table
	self:SetupDefaults()

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
		for _, entry in _G.ipairs(self.oocTab) do
			entry[1](_G.unpack(entry[2]))
		end
		self.oocTab = {}
	end)

end

function aObj:OnEnable()
	self:LevelDebug(5, "OnEnable")

	-- register events
	for evt, _ in _G.pairs(self.events) do
		self:LevelDebug(4, "Registering Event:", evt)
		self:RegisterEvent(evt, "CheckEvent")
	end

	-- get existing Channels
	local cwc = {_G.GetChatWindowChannels(1)}
	for	 i = 1, #cwc, 2 do
		self:LevelDebug(4, "cwc: [%s]", cwc[i])
		self.prdb.cf1Channels[cwc[i]] = true
	end
	-- hook to add channel
	self:RawHook("ChatFrame_AddChannel", function(chatFrame, channel)
		self.hooks.ChatFrame_AddChannel(chatFrame, channel)
		if chatFrame:GetID() == 1 then
			self.prdb.cf1Channels[channel] = true
		end
	end, true)
	-- hook to remove channel
	self:RawHook("ChatFrame_RemoveChannel", function(chatFrame, channel)
		self.hooks.ChatFrame_RemoveChannel(chatFrame, channel)
		if chatFrame:GetID() == 1 then
			self.prdb.cf1Channels[channel] = false
		end
	end, true)

	-- get existing Message Group settings
	for group, _ in _G.pairs(self.mGs) do
		if _G.tContains(_G.ChatFrame1.messageTypeList, group) then
			self.mGs[group] = true
		end
	end

	-- update message groups
	self:updateMGs()

	if self.isRtl then
		-- get Bodyguard follower names
		self:getBGNames()
	else
		self.getBGNames = _G.nop
	end

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

	self:CheckMode("init")

end

function aObj:OnDisable()
	self:LevelDebug(5, "OnDisable")

	-- unregister events
	self:UnregisterAllEvents()
	-- unhook functions
	self:UnhookAll()

	-- re-add message groups
	self.updateMGs()
	-- remove message filters
	self.updateMFltrs()

	-- turn channels back on
	for channel, on in _G.pairs(self.prdb.cf1Channels) do
		if on then
			_G.ChatFrame_AddChannel(_G.ChatFrame1, channel)
		end
	end

end

--> Flying Handler <--
local function checkTaxi(event, _)
	aObj:LevelDebug(4, "checkTaxi", event, _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"))
	-- if on Taxi then disable events
	if event == "PLAYER_CONTROL_LOST"
	or _G.UnitOnTaxi("player")
	then
		aObj:resetModes()
		aObj.modeTab.Taxi = true
		aObj:UncheckAllEvents()
		aObj.events["PLAYER_CONTROL_GAINED"].check = true
		if aObj.prdb.chatback then
			aObj:Print(_G.strjoin(" ", aObj.L["Taxi"], aObj.L["mode"], aObj.L["enabled"]))
		end
	-- if finished Taxi ride then enable events
	elseif event == "PLAYER_CONTROL_GAINED"
	and not _G.UnitOnTaxi("player")
	then
		aObj.modeTab.Taxi = false
		aObj:CheckAllEvents()
		aObj.events[event].check = false
		if aObj.prdb.chatback then
			aObj:Print(_G.strjoin(" ", aObj.L["Taxi"], aObj.L["mode"], aObj.L["disabled"]))
		end
	end
	return aObj.modeTab.Taxi
end
--> Vehicle Handler <--
local checkVehicle = _G.nop
if not aObj.isClscERA then
	function checkVehicle(event, ...)
		aObj:LevelDebug(4, "checkVehicle", event, ...)
		-- if in a vehicle then disable events
		if event == "UNIT_ENTERED_VEHICLE"
		or _G.UnitInVehicle("player")
		then
			aObj:resetModes()
			aObj.modeTab.Vehicle = true
			aObj:UncheckAllEvents()
			aObj.events["UNIT_EXITED_VEHICLE"].check = true
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Vehicle"], aObj.L["mode"], aObj.L["enabled"]))
			end
		-- if exited from vehicle then enable events
		elseif event == "UNIT_EXITED_VEHICLE"
		and not _G.UnitInVehicle("player")
		then
			aObj.modeTab.Vehicle = false
			aObj:CheckAllEvents()
			aObj.events[event].check = false
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Vehicle"], aObj.L["mode"], aObj.L["disabled"]))
			end
		end
		return aObj.modeTab.Vehicle
	end
end
--> NPC Handler <--
local NPCname
local function checkNPC(event, ...)
	aObj:LevelDebug(4, "checkNPC", event, ...)
	--@debug@
	if event == "CHAT_MSG_MONSTER_SAY" then
		local args = {...}
		aObj:LevelDebug(4, "checkNPC", event, _G.CountTable(args))
		_G.Spew("checkNPC", args)
	end
	--@end-debug@
	-- clear remembered NPC names
	_G.wipe(aObj.questNPC)
	-- remember NPC name if required
	if event == "GOSSIP_SHOW"
	or event == "QUEST_DETAIL"
	or event == "QUEST_GREETING"
	or event == "QUEST_PROGRESS"
	then
		NPCname = _G.UnitName("Target")
		if NPCname then
			aObj.questNPC[NPCname] = true
			aObj:LevelDebug(4, "Saved Gossip/Quest NPC: [%s]", NPCname)
		end
		return true
	end
end
--> Instance/Scenario Handler <--
local checkIorS, instInfo = _G.nop
if not aObj.isClscERA then
	function checkIorS()
		instInfo = {_G.GetInstanceInfo()}
		aObj:LevelDebug(4, "checkIorS: [%s, %s, %s, %s, %s]", aObj.modeTab.Instance, instInfo[2], instInfo[1], instInfo[9], instInfo[8])
		aObj:LevelDebug(4, "Instance/Scenario Handler", instInfo[2] ~= "none", aObj:isGarrison(instInfo[1]), aObj.modeTab.Instance, _G.C_Scenario and _G.C_Scenario.IsInScenario() or "n/a")
		if instInfo[2] ~= "none"
		and not aObj:isGarrison(instInfo[1])
		then
			if instInfo[2] == "scenario"
			or (instInfo[2] == "party" and instInfo[1]:find("Boost Experience"))
			then
				if not aObj.modeTab.Scenario then
					aObj:resetModes()
					aObj.modeTab.Scenario = true
					if aObj.prdb.chatback then
						aObj:Print(_G.strjoin(" ", aObj.L["Scenario"], aObj.L["mode"], aObj.L["enabled"]))
					end
				end
			else
				if not aObj.modeTab.Instance then
					aObj:resetModes()
					aObj.modeTab.Instance = true
					aObj.events["SCENARIO_UPDATE"].check = false
					aObj.events["ZONE_CHANGED"].check = false
					aObj.events["ZONE_CHANGED_INDOORS"].check = false
					aObj.events["ZONE_CHANGED_NEW_AREA"].check = false
					if aObj.prdb.chatback then
						aObj:Print(_G.strjoin(" ", aObj.L["Instance"], aObj.L["mode"], aObj.L["enabled"]))
					end
					if aObj.prdb.noIChat then
						for _, channel in _G.pairs{aObj.L["General"], aObj.L["LocalDefense"], aObj.L["WorldDefense"]} do
							if aObj.prdb.cf1Channels[channel] then
								-- use hooked function so as not to change existing value
								aObj.hooks.ChatFrame_RemoveChannel(_G.ChatFrame1, channel)
								aObj:LevelDebug(2, "Removed CF1 Channel: [%s]", channel)
							end
						end
					end
				end
			end
		else
			if aObj.modeTab.Scenario then
				aObj.modeTab.Scenario = false
				if aObj.prdb.chatback then
					aObj:Print(_G.strjoin(" ", aObj.L["Scenario"], aObj.L["mode"], aObj.L["disabled"]))
				end
			elseif aObj.modeTab.Instance then
				aObj.modeTab.Instance = false
				aObj.events["SCENARIO_UPDATE"].check = true
				aObj.events["ZONE_CHANGED"].check = true
				aObj.events["ZONE_CHANGED_INDOORS"].check = true
				aObj.events["ZONE_CHANGED_NEW_AREA"].check = true
				if aObj.prdb.chatback then
					aObj:Print(_G.strjoin(" ", aObj.L["Instance"], aObj.L["mode"], aObj.L["disabled"]))
				end
				if aObj.prdb.noIChat then
					for _, channel in _G.pairs{aObj.L["General"], aObj.L["LocalDefense"], aObj.L["WorldDefense"]} do
						if aObj.prdb.cf1Channels[channel] then
							-- use hooked function so as not to change existing value
							aObj.hooks.ChatFrame_AddChannel(_G.ChatFrame1, channel)
							aObj:LevelDebug(2, "Added CF1 Channel: [%s]", channel)
						end
					end
				end
			end
		end
		return aObj.modeTab.Scenario or aObj.modeTab.Instance
	end
end
--> Garrison Handler <--
local checkGarrison = _G.nop
if aObj.isRtl then
	function checkGarrison()
		aObj:LevelDebug(4, "Garrison Handler", _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_6_0_Garrison), _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_7_0_Garrison), aObj.garrisons[_G.GetRealZoneText()], _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_9_0_Garrison))
		if _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_6_0_Garrison) -- Garrison (WoD)
		or _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_7_0_Garrison) -- Order Hall (Legion)
		or aObj.garrisons[_G.GetRealZoneText()] -- ?? (BfA)
		or _G.C_Garrison.IsPlayerInGarrison(_G.Enum.GarrisonType.Type_9_0_Garrison) -- Sanctum (Shadowlands)
		then
			if not aObj.modeTab.Garrison then
				aObj:resetModes()
				aObj.modeTab.Garrison = true
				if aObj.prdb.chatback then
					aObj:Print(_G.strjoin(" ", aObj.L["Garrison"], aObj.L["mode"], aObj.L["enabled"]))
				end
			end
		else
			if aObj.modeTab.Garrison then
				aObj.modeTab.Garrison = false
				if aObj.prdb.chatback then
					aObj:Print(_G.strjoin(" ", aObj.L["Garrison"], aObj.L["mode"], aObj.L["disabled"]))
				end
			end
		end
		return aObj.modeTab.Garrison
	end
end
--> Sanctuary Handler <--
local pvpType
local function checkSanctuary()
	pvpType = _G.select(1, _G.C_PvP.GetZonePVPInfo())
	aObj:LevelDebug(4, "Sanctuary Handler", pvpType)
	if pvpType == "sanctuary" then
		if not aObj.modeTab.Sanctuary then
			aObj:resetModes()
			aObj.modeTab.Sanctuary = true
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Sanctuary"], aObj.L["mode"], aObj.L["enabled"]))
			end
		end
	else
		if aObj.modeTab.Sanctuary then
			aObj.modeTab.Sanctuary = false
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Sanctuary"], aObj.L["mode"], aObj.L["disabled"]))
			end
		end
	end
	return aObj.modeTab.Sanctuary
end
--> Hub Handler <--
local subZoneText, realZoneText, cMAID
local function checkHub()
	subZoneText, realZoneText = _G.GetSubZoneText(), _G.GetRealZoneText()
	aObj:LevelDebug(4, "Hub Handler", aObj.nullHubs[realZoneText], aObj.nullHubsByID[cMAID], aObj.nullTowns[subZoneText]--[[, aObj.nullTownsByID[cMAID]--]], aObj.nullAreas[subZoneText])
	if aObj.nullHubs[realZoneText]
	or aObj.nullHubsByID[cMAID]
	or aObj.nullTowns[subZoneText]
	-- or aObj.nullTownsByID[cMAID]
	or aObj.nullAreas[subZoneText]
	then
		if not aObj.modeTab.Hub then
			aObj:resetModes()
			aObj.modeTab.Hub = true
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Hub"], aObj.L["mode"], aObj.L["enabled"]))
			end
		end
	else
		if aObj.modeTab.Hub then
			aObj.modeTab.Hub = false
			if aObj.prdb.chatback then
				aObj:Print(_G.strjoin(" ", aObj.L["Hub"], aObj.L["mode"], aObj.L["disabled"]))
			end
		end
	end
	return aObj.modeTab.Hub
end

local modeTypes, modeDetected = {checkIorS, checkGarrison, checkSanctuary, checkHub}
function aObj:CheckMode(event, ...)

	self:LevelDebug(2, "CheckMode: [%s, %s, %s]", event, self.events[event] and self.events[event].check or "nil", ... or "nil")

	cMAID = _G.C_Map.GetBestMapForUnit("player")

	-- are we on a Taxi, in a Vehicle or talking to an NPC?
	for _, func in _G.ipairs{checkTaxi, checkVehicle, checkNPC} do
		if func then
			modeDetected = func(event, ...)
			if modeDetected then
				break
			end
		end
	end

	if not modeDetected then
		self:LevelDebug(3, "You Are Here: [%s, %s:%s, %s, %s, %d]",
			_G.GetZoneText() or "<Anon>",
			_G.GetRealZoneText() or "<Anon>",
			_G.GetSubZoneText() or "<Anon>",
			_G.GetMinimapZoneText() or "<Anon>",
			_G.select(1, _G.C_PvP.GetZonePVPInfo()),
			_G.C_Map.GetBestMapForUnit("player")
		)
		--> Event Handler <--
		for _, func in _G.ipairs(modeTypes) do
			modeDetected = func()
			self:LevelDebug(5, "checkFunc: [%s, %s]", func, modeDetected)
			if modeDetected then
				break
			end
		end
		-- update message filters
		self:updateMFltrs()
	end

	-- update DB object text
	self.DBObj.text = self:updateDBtext()

end

local args, event
function aObj:CheckEvent(...)

	args = ...
	event = _G.select(1, args)

	self:LevelDebug(2, "CheckEvent: [%s, %s]", event, self.events[event] and self.events[event].check or "nil")

	-- DON'T check events unless required
	if not self.events[event]
	or not self.events[event].check
	then
		return
	end

	-- delay before checking mode, this allows the current state to be ascertained properly, especially Taxi mode
	_G.C_Timer.After(0.25, function()
		self:CheckMode(args)
	end)

end
