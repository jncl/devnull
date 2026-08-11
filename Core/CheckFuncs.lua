local _, aObj = ...

local _G = _G

local cMAID
local checkPetBattle, checkVehicle, checkIorS, checkGarrison = _G.nop, _G.nop, _G.nop, _G.nop
local checkTaxi, checkNPC, checkSanctuary, checkHub
local modeTypes, modeDetected

function aObj.setupCheckFuncs()

	--> Pet Battle Handler <--
	if not aObj.isClscERA then
		function checkPetBattle(event, _)
			aObj:LevelDebug(4, "checkPetBattle", event, _G.C_PetBattles.GetBattleState())
			-- if started a Pet Battle then disable events
			if event == "PET_BATTLE_OPENING_DONE"
			then
				aObj:UncheckAllEvents()
				aObj.events["PET_BATTLE_CLOSE"].check = true
				aObj:resetModes()
				aObj.modeTab.PetBattle = true
				aObj:print2Chat("Pet Battle mode enabled")
			-- if finished Pet battle then enable events
			elseif event == "PET_BATTLE_CLOSE"
			then
				aObj:ResetAllEvents()
				aObj.modeTab.PetBattle = false
				aObj:print2Chat("Pet Battle mode disabled")
			end
			return aObj.modeTab.PetBattle
		end
	end
	--> Taxi Handler <--
	function checkTaxi(event, _)
		aObj:LevelDebug(4, "checkTaxi", event, _G.UnitOnTaxi("player"), _G.UnitIsCharmed("player"), _G.UnitIsPossessed("player"))
		-- if on Taxi then disable events
		if event == "PLAYER_CONTROL_LOST"
		and _G.UnitOnTaxi("player")
		then
			aObj:UncheckAllEvents()
			aObj.events["PLAYER_CONTROL_GAINED"].check = true
			aObj:resetModes()
			aObj.modeTab.Taxi = true
			aObj:print2Chat("Taxi mode enabled")
		-- if finished Taxi ride then enable events
		elseif event == "PLAYER_CONTROL_GAINED"
		and not _G.UnitOnTaxi("player")
		then
			aObj:ResetAllEvents()
			aObj.modeTab.Taxi = false
			aObj:print2Chat("Taxi mode disabled")
		end
		return aObj.modeTab.Taxi
	end
	--> Vehicle Handler <--
	if not aObj.isClscERA then
		function checkVehicle(event, ...)
			aObj:LevelDebug(4, "checkVehicle", event, ...)
			-- if in a vehicle then disable events
			if event == "UNIT_ENTERED_VEHICLE"
			or _G.UnitInVehicle("player")
			then
				aObj:UncheckAllEvents()
				aObj.events["UNIT_EXITED_VEHICLE"].check = true
				aObj:resetModes()
				aObj.modeTab.Vehicle = true
				aObj:print2Chat("Vehicle mode enabled")
			-- if exited from vehicle then enable events
			elseif event == "UNIT_EXITED_VEHICLE"
			and not _G.UnitInVehicle("player")
			then
				aObj:ResetAllEvents()
				aObj.modeTab.Vehicle = false
				aObj:print2Chat("Vehicle mode disabled")
			end
			return aObj.modeTab.Vehicle
		end
	end
	--> NPC Handler <--
	local NPCname
	function checkNPC(event, ...)
		aObj:LevelDebug(4, "checkNPC", event, ...)
		--@debug@
		if event == "CHAT_MSG_MONSTER_SAY" then
			local args = {...}
			aObj:LevelDebug(4, "checkNPC", event, _G.CountTable(args))
			-- _G.Spew("checkNPC", args)
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
			if _G.canaccessvalue
			and _G.canaccessvalue(_G.UnitName("Target"))
			then
				NPCname = _G.UnitName("Target")
				if NPCname then
					aObj.questNPC[NPCname] = true
					aObj:LevelDebug(4, "Saved Gossip/Quest NPC: [%s]", NPCname)
				end
				return true
			end
		end
	end
	--> Instance/Scenario Handler <--
	if not aObj.isClscERA then
		local instInfo
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
						aObj:print2Chat("Scenario mode enabled")
					end
				else
					if not aObj.modeTab.Instance then
						aObj.events["SCENARIO_UPDATE"].check = false
						aObj.events["ZONE_CHANGED"].check = false
						aObj.events["ZONE_CHANGED_INDOORS"].check = false
						aObj.events["ZONE_CHANGED_NEW_AREA"].check = false
						aObj:resetModes()
						aObj.modeTab.Instance = true
						aObj:print2Chat("Instance mode enabled")
						if aObj.prdb.noIChat then
							for _, channel in _G.pairs{aObj.L["General"], aObj.L["LocalDefense"], aObj.L["WorldDefense"]} do
								if aObj.prdb.cf1Channels[channel] then
									-- use hooked function so as not to change existing value
									if not aObj.isMnln
									and not aObj.isClscBCA
									and not aObj.isClsc
									then
										aObj.hooks.ChatFrame_RemoveChannel(_G.ChatFrame1, channel)
									else
										aObj.hooks[_G.ChatFrame1].RemoveChannel(_G.ChatFrame1, channel)
									end
									aObj:LevelDebug(2, "Removed CF1 Channel: [%s]", channel)
								end
							end
						end
					end
				end
			else
				if aObj.modeTab.Scenario then
					aObj.modeTab.Scenario = false
					aObj:print2Chat("Scenario mode disabled")
				elseif aObj.modeTab.Instance then
					aObj.events["SCENARIO_UPDATE"].check = true
					aObj.events["ZONE_CHANGED"].check = true
					aObj.events["ZONE_CHANGED_INDOORS"].check = true
					aObj.events["ZONE_CHANGED_NEW_AREA"].check = true
					aObj.modeTab.Instance = false
					aObj:print2Chat("Instance mode disabled")
					if aObj.prdb.noIChat then
						for _, channel in _G.pairs{aObj.L["General"], aObj.L["LocalDefense"], aObj.L["WorldDefense"]} do
							if aObj.prdb.cf1Channels[channel] then
								-- use hooked function so as not to change existing value
								if not aObj.isMnln
								and not aObj.isClscBCA
								and not aObj.isClsc
								then
									aObj.hooks.ChatFrame_AddChannel(_G.ChatFrame1, channel)
								else
									aObj.hooks[_G.ChatFrame1].AddChannel(_G.ChatFrame1, channel)
								end
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
	if aObj.isMnln then
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
					aObj:print2Chat("Garrison mode enabled")
				end
			else
				if aObj.modeTab.Garrison then
					aObj.modeTab.Garrison = false
					aObj:print2Chat("Garrison mode disabled")
				end
			end
			return aObj.modeTab.Garrison
		end
	end
	--> Sanctuary Handler <--
	local pvpType
	function checkSanctuary()
		pvpType = _G.select(1, _G.C_PvP.GetZonePVPInfo())
		aObj:LevelDebug(4, "Sanctuary Handler", pvpType)
		if pvpType == "sanctuary" then
			if not aObj.modeTab.Sanctuary then
				aObj:resetModes()
				aObj.modeTab.Sanctuary = true
				aObj:print2Chat("Sanctuary mode enabled")
			end
		else
			if aObj.modeTab.Sanctuary then
				aObj.modeTab.Sanctuary = false
				aObj:print2Chat("Sanctuary mode disabled")
			end
		end
		return aObj.modeTab.Sanctuary
	end
	--> Hub Handler <--
	local subZoneText, realZoneText
	function checkHub()
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
				aObj:print2Chat("Hub mode enabled")
			end
		else
			if aObj.modeTab.Hub then
				aObj.modeTab.Hub = false
				aObj:print2Chat("Hub mode disabled")
			end
		end
		return aObj.modeTab.Hub
	end

	modeTypes = {checkSanctuary, checkHub, checkGarrison, checkIorS}

end

function aObj:CheckMode(event, ...)

	self:LevelDebug(2, "CheckMode: [%s, %s, %s]", event, self.events[event] and self.events[event].check or "nil", ... or "nil")

	cMAID = _G.C_Map.GetBestMapForUnit("player")

	-- are we fighting a Pet Battle, on a Taxi, in a Vehicle or talking to an NPC?
	for _, func in _G.ipairs{checkPetBattle, checkTaxi, checkVehicle, checkNPC} do
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
		self:updateMsgFltrs()
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
	-- _G.C_Timer.After(0.25, function()
	_G.RunNextFrame(function()
		self:CheckMode(args)
	end)

end
