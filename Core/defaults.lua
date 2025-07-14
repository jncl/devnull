local aName, aObj = ...

local _G = _G

function aObj:SetupDefaults()

	self.modeTab = {
		["Garrison"]  = false,
		["Hub"]       = false,
		["Instance"]  = false,
		["Sanctuary"] = false,
		["Scenario"]  = false,
		["Taxi"]      = false,
		["Vehicle"]   = false,
	}

	-- store player and pet names & player faction
	self.player  = _G.UnitName("player")
	self.pet     = _G.UnitName("pet")
	self.faction = _G.UnitFactionGroup("player")

	local defaults = { profile = {
		achFilterType = 1,
		chatback      = true,
		shrink        = false,
		noBguard      = true,
		noDiscovery   = true,
		noDrunk       = true,
		noDuel        = true,
		noEmote       = true,
		noGChat       = true,
		noIChat       = true,
		noMYell       = true,
		noNPC         = true,
		noPetInfo     = true,
		noPYell       = true,
		noTradeskill  = true,
		-- ChatFrame1 channel settings
		cf1Channels = {
			[self.L["General"]]      = false, -- (All Versions)
			[self.L["Trade"]]        = false, -- (All Versions)
			[self.L["LocalDefense"]] = false, -- (All Versions)
			-- LookingForGroup -- (Classic)
			-- GuildRecruitment -- (Classic)
			[self.L["NewcomerChat"]] = false, -- (Retail)
			-- ShadowlandsBetaDiscussion -- (Retail)
			-- ShadowlandsPTRDiscussion -- (Retail)
			-- DragonflightTestDiscussion -- (Retail)
			-- ChromieTime (Retail)
			[self.L["Services"]]     = false, -- (Retail)
			[self.L["WorldDefense"]] = false, -- (??)
		},
	}}

	self.db = _G.LibStub:GetLibrary("AceDB-3.0"):New(aName .. "DB", defaults, "Default")
	self.prdb = self.db.profile

	-- message groups to filter
	self.mGs = {
		["MONSTER_YELL"]      = false,
		["TRADESKILLS"]       = false,
		["PET_INFO"]          = false,
		["ACHIEVEMENT"]       = false,
		["GUILD_ACHIEVEMENT"] = false,
	}
	-- remember quest NPC's
	self.questNPC = {}

	-- pointer to LibBabble-SubZone-3.0 library
	local SZL = _G.LibStub:GetLibrary("LibBabble-SubZone-3.0"):GetLookupTable()

	-- Map IDs can be found here: http://wowpedia.org/MapID
	-- These have been changed in BfA and a transitional list can be found here:
	-- AddOns/Blizzard_Deprecated/UIMapIDToWorldMapAreaID.lua
	self.nullTowns = {
		-- Kalimdor
		[SZL["Everlook"]]          = true,
		[SZL["Gadgetzan"]]         = true,
		[SZL["Ratchet"]]           = true,
		[SZL["Theramore Isle"]]    = true,
		-- Eastern Kingdoms
		[SZL["Booty Bay"]]         = true,
		[SZL["Goldshire"]]         = true, -- in Elwynn Forest
	}
	self.nullAreas = {
		[SZL["The Old Port Authority"]]  = true, -- in Booty Bay
		[SZL["The Salty Sailor Tavern"]] = true, -- in Booty Bay
		[SZL["Foothold Citadel"]]        = true, -- in Theramore Isle
	}
	self.nullHubs = {
		-- Kalimdor
		[SZL["Orgrimmar"]]         = true,
		[SZL["Thunder Bluff"]]     = true,
		[SZL["Darnassus"]]         = true,
		-- Eastern Kingdoms
		[SZL["Stormwind City"]]    = true,
		[SZL["City of Ironforge"]] = true,
		[SZL["Undercity"]]         = true,
	}
	self.nullHubsByID = {}
	self.checkZones = {
		-- used for smaller area changes
		[SZL["Northern Barrens"]]          = true, -- (for Ratchet)
		[SZL["Elwynn Forest"]]             = true, -- (for Goldshire)
		[SZL["Deadwind Pass"]]             = true, -- (for Karazhan)
		[SZL["Stonetalon Mountains"]]      = true, -- (for Krom'gar Fortess)
		[SZL["Dustwallow Marsh"]]          = true, -- (for Theramore Isle)
		[SZL["Tanaris"]]                   = true, -- (for Gadgetzan)
		[SZL["Winterspring"]]              = true, -- (for Everlook)
		[SZL["The Cape of Stranglethorn"]] = true, -- (for Booty Bay)
	}
	self.checkZonesByID = {}
	self.garrisons = {}
	self.events = {
		["GOSSIP_SHOW"]           = {check = true}, -- this is for NPC name check
		["PLAYER_CONTROL_GAINED"] = {check = true}, -- this is for taxi check
		["PLAYER_CONTROL_LOST"]   = {check = true}, -- this is for taxi check
		["PLAYER_LEAVING_WORLD"]  = {check = true}, -- this is for boat trips
		["QUEST_DETAIL"]          = {check = true}, -- this is for NPC name check
		["QUEST_GREETING"]        = {check = true}, -- this is for NPC name check
		["QUEST_PROGRESS"]        = {check = true}, -- this is for NPC name check
		["ZONE_CHANGED"]          = {check = true}, -- used to handle boat trips
		["ZONE_CHANGED_INDOORS"]  = {check = true}, -- for tunnel into Booty Bay & Boralus Harbor
		["ZONE_CHANGED_NEW_AREA"] = {check = true}, -- used to handle changes of area
	}

	if self.isClscERA then
		return
	end

	self.events["UNIT_ENTERED_VEHICLE"] = {check = true} -- this is used for vehicle check
	self.events["UNIT_EXITED_VEHICLE"] = {check = false} -- this is used for vehicle check

	-- Eversong Woods (TBC)
	self.nullHubs[SZL["Silvermoon City"]]              = true -- Blood Elf starting area (Horde)
	-- Azuremyst Isle (TBC)
	self.nullHubs[SZL["The Exodar"]]                   = true -- Draenei starting area (Alliance)
	-- Outland (TBC)
	self.nullTowns[SZL["Area 52"]]                     = true -- Netherstorm
	self.nullTowns[SZL["Honor Hold"]]                  = true -- Hellfire Peninsula (Alliance)
	self.nullTowns[SZL["Mudsprocket"]]                 = true -- Dustwallow Marsh (Neutral)
	self.nullTowns[SZL["Thrallmar"]]                   = true -- Hellfire Peninsula (Horde)
	self.checkZones[SZL["Hellfire Peninsula"]]         = true -- (for Honor Hold & Thrallmar)
	self.checkZones[SZL["Netherstorm"]]                = true -- (for Area 52)
	-- WotLK
	self.nullTowns[SZL["Warsong Hold"]]                = true -- Borean Tundra (Horde)
	self.nullTowns[SZL["Valiance Keep"]]               = true -- Borean Tundra (Alliance)
	self.nullTowns[SZL["Vengeance Landing"]]           = true -- Howling Fjord (Horde)
	self.nullTowns[SZL["Valgarde"]]                    = true -- Howling Fjord (Alliance)
	self.checkZones[SZL["Borean Tundra"]]              = true -- (for Valiance Keep/Warsong Hold)
	self.checkZones[SZL["Howling Fjord"]]              = true -- (for Valgarde/Vengeance Landing)

	if self.isClsc then
		return
	end

	self.events["SCENARIO_UPDATE"] = {check = true}  -- this is for scenario check
	self.events["PLAYER_ENTERING_WORLD"] = {check = true} -- this is for garrison check

	-- Cata
	self.checkZones[SZL["Kezan"]]                      = true -- (for KTC Headquarters)
	self.checkZones[SZL["Timeless Isle"]]              = true -- Timeless Isle
	self.nullAreas[SZL["KTC Headquarters"]]            = true -- Goblin starting area
	self.nullAreas[SZL["Krom'gar Fortress"]]           = true -- Horde Base in Stonetalon Mts
	-- MoP
	self.nullAreas[SZL["The Celestial Court"]]         = true -- Timeless Isle
	self.nullHubs[SZL["Shrine of Two Moons"]]          = true -- Vale of Eternal Blossoms (Horde)
	self.nullHubs[SZL["Shrine of Seven Stars"]]        = true -- Vale of Eternal Blossoms (Alliance)
	--  WoD
	self.nullHubs[SZL["Warspear"]]                     = true -- Ashran (Horde)
	self.nullHubs[SZL["Stormshield"]]                  = true -- Ashran (Alliance)
	-- Legion
	self.nullAreas[SZL["The Vindicaar"]]               = true -- Argus
	-- BfA
	self.checkZonesByID[862]                           = true -- Zuldazar (Horde)
	self.checkZonesByID[895]                           = true -- Tiragarde Sound (Alliance)
	self.checkZonesByID[1161]                          = true -- Boralus (Alliance)
	self.checkZonesByID[1165]                          = true -- Dazar'alor (Horde)
	self.nullAreas[SZL["Upton Borough"]]               = true -- Boralus (Alliance)
	self.nullHubs[SZL["Boralus Harbor"]]               = true -- Boralus (Alliance)
	self.nullHubs[SZL["Stormsong Monastery"]]          = true -- Boralus (Alliance)
	self.nullHubsByID[1161]                            = true -- Boralus, Tiragarde Sound (Alliance)
	self.nullHubsByID[862]                             = true -- Dazar'alor [The Royal Treasury], Zuldazar (Horde)
	self.nullHubsByID[1163]                            = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1164]                            = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1165]                            = true -- Dazar'alor, Zuldazar (Horde)
	self.nullHubsByID[1355]                            = true -- Nazjatar
	self.nullHubsByID[1462]                            = true -- Mechagon
	self.garrisons[SZL["Wind's Redemption"]]		   = true -- Boralus (Alliance)
	self.garrisons[SZL["The Banshee's Wail"]]		   = true -- Zuldazar (Horde)
	-- SL
	-- DF

end
