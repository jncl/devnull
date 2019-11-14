local aName, aObj = ...
local _G = _G

local LibStub = _G.LibStub

function aObj:SetupOptions()

	local optTables = {

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
						achFilterType = not self.isClassic and {
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
						noOrderHall = not self.isClassic and {
							type = 'toggle',
							name = self.L["OrderHall Chat"],
							desc = self.L["Mute OrderHall NPC Chat"],
						} or nil,
					},
				},
				city = {
					type = "group",
					order = 2,
					name = self.L["City/Town Settings"],
					desc = self.L["Change the City/Town settings"],
					args = {
						noDiscovery = not self.isClassic and {
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
				instance = not self.isClassic and {
					type = "group",
					order = 3,
					name = self.L["Instance Settings"],
					desc = self.L["Change the Instance settings"],
					args = {
						iChat = {
							type = 'toggle',
							width = "double",
							name = self.L["General chat in Instances"],
							desc = self.L["Mute General chat in Instances."],
						},
					},
				} or nil,
				garrison = not self.isClassic and {
					type = "group",
					order = 4,
					name = self.L["Garrison Settings"],
					desc = self.L["Change the Garrison Settings"],
					args = {
						gChat = {
							type = 'toggle',
							width = "double",
							name = self.L["General chat in Garrisons"],
							desc = self.L["Mute General chat in Garrisons."],
						},
						noBguard = {
							type = 'toggle',
							name = self.L["Bodyguard Chat"],
							desc = self.L["Mute Bodyguard Chat & Faction updates"],
						},
					},
				} or nil,
			},
		},
	}

	-- option tables list
	local optNames = {"Mutes", "Profiles"}
	-- add DB profile options
	optTables.Profiles = LibStub:GetLibrary("AceDBOptions-3.0"):GetOptionsTable(self.db)

	-- register the options tables and add them to the blizzard frame
	local ACR = LibStub:GetLibrary("AceConfigRegistry-3.0")
	local ACD = LibStub:GetLibrary("AceConfigDialog-3.0")

	LibStub:GetLibrary("AceConfig-3.0"):RegisterOptionsTable(aName, optTables.General, {aName, "dn"})
	self.optionsFrame = ACD:AddToBlizOptions(aName, aName)

	-- register the options, add them to the Blizzard Options
	local optCheck = {}
	for _, v in _G.ipairs(optNames) do
		local optTitle = (" "):join(aName, v)
		ACR:RegisterOptionsTable(optTitle, optTables[v])
		self.optionsFrame[self.L[v]] = ACD:AddToBlizOptions(optTitle, self.L[v], aName)
		-- build the table used by the chatCommand function
		optCheck[v:lower()] = v
	end
	-- runs when the player clicks "Okay"
	self.optionsFrame[self.L["Mutes"]].okay = function()
		self:getBGNames()
		self:unfilterMGs()
		self:removeMFltrs()
		self:filterMGs()
		self:addMFltrs()
	end

	-- Slash command handler
	local function chatCommand(input)

		local cmds = { (" "):split(input) }

		if not input or input:trim() == "" then
			-- Open general panel if there are no parameters
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame)
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame)
		elseif optCheck[input:lower()] then
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame[optCheck[input:lower()]])
			_G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame[optCheck[input:lower()]])
		elseif input:lower() == "status" then
			aObj:Print("City mode:", self.inHub, "Taxi:", self.onTaxi)
			if not aObj.isClassic then
				aObj:Print("Vehicle:", self.inVehicle, "Scenario:", self.inScenario, "Instance:", self.prdb.inInst)
				aObj:Print("Garrison:", self.inGarrison, "Bodyguard mode:", self.prdb.noBguard, "OrderHall mode:", self.prdb.noOrderHall)
			end
		elseif input:lower() == "loud" then
			aObj.debugLevel = 5
			aObj:Print("Debug messages ON")
		elseif input:lower() == "quiet" then
			aObj.debugLevel = 1
			aObj:Print("Debug messages OFF")
		elseif input:lower() == "locate" then
			_G.C_Map.GetBestMapForUnit("player")
			aObj:Print("You Are Here: [", _G.GetRealZoneText(), "][", _G.GetSubZoneText(), "][", self.GetCurrentMapAreaID(), "]")
		elseif input:lower() == "mapinfo" then
			local uiMapID = _G.C_Map.GetBestMapForUnit("player")
			local mapinfo = _G.C_Map.GetMapInfo(uiMapID)
			local posn = _G.C_Map.GetPlayerMapPosition(uiMapID, "player")
			local areaName= _G.MapUtil.FindBestAreaNameAtMouse(uiMapID, posn["x"], posn["y"])
			aObj:Print("Map Info:", mapinfo["mapID"], mapinfo["name"], mapinfo["mapType"], mapinfo["parentMapID"], posn["x"], posn["y"], areaName)
			uiMapID, mapinfo, posn, areaName = nil, nil, nil, nil
		else
			LibStub:GetLibrary("AceConfigCmd-3.0"):HandleCommand(aName, aName, input)
		end

	end

	-- Register slash command handlers
	self:RegisterChatCommand(aName, chatCommand)
	self:RegisterChatCommand("dn", chatCommand)

	-- setup the DB object
	self.DBObj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(aName, {
		type = "data source",
		text = aObj:updateDBtext(),
		icon = [[Interface\Icons\Spell_Holy_Silence]],
		OnClick = function() _G.InterfaceOptionsFrame_OpenToCategory(aObj.optionsFrame) end,
	})

end
