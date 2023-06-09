local aName, aObj = ...

local _G = _G

function aObj:SetupOptions()

	local iof_otc
	if not self.isRtl then
		iof_otc = _G.InterfaceOptionsFrame_OpenToCategory
	else
		iof_otc = _G.Settings.OpenToCategory
	end
	self.optTables = {
		General = {
			type = "group",
			name = aName,
			get = function(info) return self.prdb[info[#info]] end,
			set = function(info, value)
				self.prdb[info[#info]] = value
				if info[#info] == "shrink" then aObj.DBObj.text = aObj:updateDBtext() end
			end,
			args = {
				desc = {
					type = "description",
					order = 1,
					name = self.L["shhhh"] .." - "..(_G.GetAddOnMetadata(aName, "X-Curse-Packaged-Version") or _G.GetAddOnMetadata(aName, "Version") or "").."\n",
				},
				longdesc = {
					type = "description",
					order = 2,
					name = self.L["Mutes various chat related annoyances while in capital cities and instances"] .. "\n",
				},
				chatback = {
					type = 'toggle',
					order = 3,
					name = self.L["Chat Feedback"],
					desc = self.L["Print chat message when toggling mute."],
				},
				shrink = {
					type = 'toggle',
					order = 3,
					name = self.L["Shrink label"],
					desc = self.L["Abbreviate the Data Broker label."],
				},
			},
		},
		Mutes = {
			type = "group",
			name = self.L["Mute Options"],
			childGroups = "tab",
			get = function(info) return self.prdb[info[#info]] end,
			set = function(info, value) self.prdb[info[#info]] = value end,
			args = {
				desc = {
					type = "description",
					name = self.L["Toggle the types of message to mute"],
				},
				global = {
					type = "group",
					order = 1,
					name = self.L["Global Settings"],
					desc = self.L["Change the Global settings"],
					args = {
						achFilterType = not self.isClscERA and {
							type = 'select',
							order = -1,
							name = self.L["Achievement Filter"],
							style = "radio",
							width = "double",
							values = {
								[0] = self.L["None"],
								[1] = self.L["All"],
								[2] = self.L["All except Guild/Party/Raid"]
							},
						} or nil,
						noDuel = {
							type = 'toggle',
							name = self.L["Duels"],
							desc = self.L["Mute Duel info."],
						},
						noPetInfo = {
							type = 'toggle',
							name = self.L["Pet Info"],
							desc = self.L["Mute Pet Info."],
						},
						noTradeskill = {
							type = 'toggle',
							name = self.L["Tradeskills"],
							desc = self.L["Mute Tradeskills."],
						},
						noMYell = {
							type = 'toggle',
							name = self.L["NPC/Mob Yells"],
							desc = self.L["Mute NPC/Mob Yells."],
						},
					},
				},
				city = {
					type = "group",
					order = 2,
					name = self.L["Hub Settings"],
					desc = self.L["Change the Hub settings"],
					args = {
						h1 = {
							type = "description",
							order = 1,
							name = self.L["These settings are used in Cities, Towns and Sanctuaries"] .. "\n\n",
						},
						noDiscovery = self.isRtl and {
							type = 'toggle',
							name = self.L["Discoveries"],
							desc = self.L["Mute Discovery info."],
						} or nil,
						noDrunk = {
							type = 'toggle',
							name = self.L["Drunks"],
							desc = self.L["Mute Drunken info."],
						},
						noEmote = {
							type = 'toggle',
							name = self.L["Emotes"],
							desc = self.L["Mute Emotes."],
						},
						noNPC = {
							type = 'toggle',
							name = self.L["NPCs"],
							desc = self.L["Mute NPC chat."],
						},
						noPYell = {
							type = 'toggle',
							name = self.L["Player Yells"],
							desc = self.L["Mute Player Yells."],
						},
					},
				},
				instance = self.isRtl and {
					type = "group",
					order = 3,
					name = self.L["Instance Settings"],
					desc = self.L["Change the Instance settings"],
					args = {
						noIChat = {
							type = 'toggle',
							width = "double",
							name = self.L["General chat in Instances"],
							desc = self.L["Mute General chat in Instances."],
						},
					},
				} or nil,
				garrison = self.isRtl and {
					type = "group",
					order = 4,
					name = self.L["Garrison Settings"],
					desc = self.L["Change the Garrison Settings"],
					args = {
						h1 = {
							type = "description",
							order = 1,
							name = self.L["These settings are used in Garrisons, Order Halls and Sanctums"] .. "\n\n",
						},
						noGChat = {
							type = 'toggle',
							width = "double",
							name = self.L["General chat"],
							desc = self.L["Mute General chat."],
						},
						noBguard = {
							type = 'toggle',
							name = self.L["Bodyguard chat"],
							desc = self.L["Mute Bodyguard chat & Faction updates"],
						},
					},
				} or nil,
			},
		},
	}

	self.ACD = _G.LibStub:GetLibrary("AceConfigDialog-3.0")
	self.ACR = _G.LibStub:GetLibrary("AceConfigRegistry-3.0", true)

	local function postLoadFunc()
		local method
		if not aObj.isRtl then
			method = "okay"
		else
			method = "OnCommit"
		end
		-- runs when the player clicks "Okay"
		aObj.optionsFrames[aObj.L["Mutes"]][method] = function()
			aObj:getBGNames()
			aObj:unfilterMGs()
			aObj:removeMFltrs()
			aObj:filterMGs()
			aObj:addMFltrs()
		end
	end

	self:setupOptions({"Mutes"}, {}, _G.nop, postLoadFunc)

	-- Slash command handler
	local function chatCommand(input)
		if not input or input:trim() == "" then
			-- Open general panel if there are no parameters
			aObj.callbacks:Fire("Options_Selected")
			if not aObj.isRtl then
				iof_otc(aObj.optionsFrames[aName])
				iof_otc(aObj.optionsFrames[aName])
			else
				iof_otc(aName)
			end
		elseif aObj.optCheck[input:lower()] then
			aObj.callbacks:Fire("Options_Selected")
			if not aObj.isRtl then
				iof_otc(aObj.optionsFrames[aObj.optCheck[input:lower()]])
				iof_otc(aObj.optionsFrames[aObj.optCheck[input:lower()]])
			else
				iof_otc(aName)
			end
		elseif input:lower() == "status" then
			aObj:Print("Hub:", self.inHub, "Taxi:", self.onTaxi)
			if aObj.isRtl then
				aObj:Print("Vehicle:", self.inVehicle, "Scenario:", self.inScenario, "Instance:", self.prdb.inInst)
				aObj:Print("Garrison:", self.inGarrison, "Bodyguard mode:", self.prdb.noBguard)
			end
		elseif input:lower() == "loud" then
			aObj.debugLevel = 5
			aObj:Print("Debug messages ON")
		elseif input:lower() == "quiet" then
			aObj.debugLevel = 1
			aObj:Print("Debug messages OFF")
		elseif input:lower() == "locate" then
			_G.C_Map.GetBestMapForUnit("player")
			aObj:Print("You Are Here: [", _G.GetRealZoneText(), "][", _G.GetSubZoneText(), "][", _G.C_Map.GetBestMapForUnit("player"), "]")
		elseif input:lower() == "mapinfo" then
			local uiMapID = _G.C_Map.GetBestMapForUnit("player")
			local mapinfo = _G.C_Map.GetMapInfo(uiMapID)
			local posn = _G.C_Map.GetPlayerMapPosition(uiMapID, "player")
			local areaName= _G.MapUtil.FindBestAreaNameAtMouse(uiMapID, posn["x"], posn["y"])
			aObj:Print("Map Info:", mapinfo["mapID"], mapinfo["name"], mapinfo["mapType"], mapinfo["parentMapID"], posn["x"], posn["y"], areaName)
		else
			_G.LibStub:GetLibrary("AceConfigCmd-3.0"):HandleCommand(aName, aName, input)
		end
	end

	-- Register slash command handlers
	self:RegisterChatCommand(self.L[aName], chatCommand) -- N.B. use localised name
	self:RegisterChatCommand("dn", chatCommand)

	-- setup the DB object
	self.DBObj = _G.LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(aName, {
		type = "data source",
		text = aObj:updateDBtext(),
		icon = [[Interface\Icons\Spell_Holy_Silence]],
		OnClick = function()
			aObj.callbacks:Fire("Options_Selected")
			if not aObj.isRtl then
			-- do twice to overcome Blizzard bug
				iof_otc(aObj.optionsFrames[aName])
				iof_otc(aObj.optionsFrames[aName])
			else
				iof_otc(aName)
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(aObj.L[aName] .. " - " .. aObj.L[self:updateDBtext(true)])
			tooltip:AddLine(aObj.L["Click to open config panel"], 1, 1, 1)
		end,
	})

end
