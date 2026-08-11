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

	-- get Locale strings
	self.L = _G.LibStub:GetLibrary("AceLocale-3.0"):GetLocale(aName)

	-- pointer to LibDBIcon-1.0 library
	self.DBIcon = _G.LibStub:GetLibrary("LibDBIcon-1.0")

	--@debug@
	self:checkLocaleStrings()
	--@end-debug@

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

	-- Setup AddOn Compartment Icon
	self:setupACI()

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
	if not aObj.isMnln
	and not aObj.isClscBCA
	and not aObj.isClscPTR
	and not aObj.isClscERAPTR
	then
		self:RawHook("ChatFrame_AddChannel", function(chatFrame, channel)
			self.hooks.ChatFrame_AddChannel(chatFrame, channel)
			if chatFrame:GetID() == 1 then
				self.prdb.cf1Channels[channel] = true
			end
		end, true)
	else
		self:RawHook(_G.ChatFrame1, "AddChannel", function(this, channel)
			self.hooks[this].AddChannel(this, channel)
			self.prdb.cf1Channels[channel] = true
		end, true)
	end
	-- hook to remove channel
	if not aObj.isMnln
	and not aObj.isClscBCA
	and not aObj.isClscPTR
	and not aObj.isClscERAPTR
	then
		self:RawHook("ChatFrame_RemoveChannel", function(chatFrame, channel)
			self.hooks.ChatFrame_RemoveChannel(chatFrame, channel)
			if chatFrame:GetID() == 1 then
				self.prdb.cf1Channels[channel] = false
			end
		end, true)
	else
		self:RawHook(_G.ChatFrame1, "RemoveChannel", function(this, channel)
			self.hooks[this].RemoveChannel(this, channel)
			self.prdb.cf1Channels[channel] = false
		end, true)
	end

	-- get existing Message Group settings
	for mGroup, opt in _G.pairs(self.mGroups) do
		if _G.tContains(_G.ChatFrame1.messageTypeList, mGroup) then
			self.prdb[opt] = true
		end
	end

	-- update message groups
	self:updateMsgGrps()

	if self.isMnln then
		-- get Bodyguard follower names
		self:getBGNames()
	else
		self.getBGNames = _G.nop
	end

	self:handleProfileChanges()

	self:setupCheckFuncs()

	self:CheckMode("init")

	--@debug@
	-- Register PLAYER_LOGOUT to save LocaleStrings
	self:RegisterEvent("PLAYER_LOGOUT", function()
		_G[aName .. "LocaleStrings"] = self.localeStrings
	end)
	--@end-debug@

end

function aObj:OnDisable()
	self:LevelDebug(5, "OnDisable")

	-- unregister events
	self:UnregisterAllEvents()
	-- unhook functions
	self:UnhookAll()

	-- re-add message groups
	self.updateMsgGrps()
	-- remove message filters
	self.updateMsgFltrs()

	-- turn channels back on
	for channel, on in _G.pairs(self.prdb.cf1Channels) do
		if on then
			if not aObj.isMnln then
				_G.ChatFrame_AddChannel(_G.ChatFrame1, channel)
			else
				_G.ChatFrame1.AddChannel(channel)
			end
		end
	end

end
