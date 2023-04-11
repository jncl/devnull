local aName, aObj = ...

local _G = _G

function aObj:SetupDefaults()

	self.exitedInst  = false
	self.inGarrison  = false
	self.inHub       = false
	self.inOrderHall = false
	self.inScenario  = false
	self.inVehicle   = false
	self.onTaxi      = false

	-- store player and pet names & player faction
	self.player  = _G.UnitName("player")
	self.pet     = _G.UnitName("pet")
	self.faction = _G.UnitFactionGroup("player")

	-- get Locale
	self.L = _G.LibStub:GetLibrary("AceLocale-3.0"):GetLocale(aName)

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
			[self.L["General"]]          = false,
			[self.L["Trade"]]            = false,
			[self.L["LocalDefense"]]     = false,
			[self.L["WorldDefense"]]     = false,
			[self.L["GuildRecruitment"]] = false,
		},
		-- stored inInstance setting
		inInst        = false,
	}}

	self.db = _G.LibStub:GetLibrary("AceDB-3.0"):New(aName .. "DB", defaults, "Default")

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
	self.nullTownsByID = {}
	self.nullAreas = {
		[SZL["The Old Port Authority"]]  = true, -- in Booty Bay
		[SZL["The Salty Sailor Tavern"]] = true, -- in Booty Bay
		[SZL["Foothold Citadel"]]        = true, -- in Theramore Isle
	}
	self.nullHubs = {
		-- Kalimdor
		[SZL["Orgrimmar"]]      = true,
		[SZL["Thunder Bluff"]]  = true,
		[SZL["Darnassus"]]      = true,
		-- Eastern Kingdoms
		[SZL["Stormwind City"]] = true,
		[SZL["Ironforge"]]      = true,
		[SZL["Undercity"]]      = true,
	}
	self.nullHubsByID = {}
	self.sanctums = {}
	self.sanctumsByID = {}
	self.sanctuaries = {}
	self.sanctuariesByID = {}
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
	self.checkEvent = {
		["ZONE_CHANGED_INDOORS"]  = true, -- for tunnel into Booty Bay
		["ZONE_CHANGED"]          = true, -- used to handle boat trips
		["ZONE_CHANGED_NEW_AREA"] = true, -- used to handle changes of area
		["PLAYER_CONTROL_GAINED"] = true, -- this is for taxi check
	}
	self.trackEvent = {
		["ZONE_CHANGED_INDOORS"]  = true, -- for tunnel into Booty Bay & Boralus Harbor
		["ZONE_CHANGED"]		  = true, -- this is for changes of sub area
		["ZONE_CHANGED_NEW_AREA"] = true, -- this is for changes of area
		["PLAYER_CONTROL_LOST"]   = true, -- this is for taxi check
		["PLAYER_LEAVING_WORLD"]  = true, -- this is for boat trips
		["GOSSIP_SHOW"]           = true, -- this is for NPC name checks
		["QUEST_GREETING"]        = true, -- this is for NPC name checks
		["QUEST_DETAIL"]          = true, -- this is for NPC name checks
		["QUEST_PROGRESS"]        = true, -- this is for NPC name checks
	}

	if self.isClscERA then
		return
	end

	-- Eversong Woods (TBC)
	self.nullHubs[SZL["Silvermoon City"]]              = true -- Blood Elf starting area (Horde)
	-- Azuremyst Isle (TBC)
	self.nullHubs[SZL["The Exodar"]]                   = true -- Draenei starting area (Alliance)
	-- Outland (TBC)
	self.nullTowns[SZL["Area 52"]]                     = true -- Netherstorm
	self.nullTowns[SZL["Honor Hold"]]                  = true -- Hellfire Peninsula (Alliance)
	self.nullTowns[SZL["Mudsprocket"]]                 = true -- Dustwallow Marsh (Neutral)
	self.nullTowns[SZL["Thrallmar"]]                   = true -- Hellfire Peninsula (Horde)
	self.sanctuaries[SZL["The Stair of Destiny"]]      = true -- The Dark Portal, Blasted Lands
	self.sanctuariesByID[self.isRtl and 111 or 1955]   = true -- Shattrath City (Terrace of Light/Lower City/Aldor Rise/Scryer's Tier)
	self.sanctuaries[SZL["Acherus: The Ebon Hold"]]    = true -- Eastern Plaguelands
	self.checkZones[SZL["Hellfire Peninsula"]]         = true -- (for Honor Hold & Thrallmar)
	self.checkZones[SZL["Netherstorm"]]                = true -- (for Area 52)
	-- WotLK
	self.nullTowns[SZL["Warsong Hold"]]                = true -- Borean Tundra (Horde)
	self.nullTowns[SZL["Valiance Keep"]]               = true -- Borean Tundra (Alliance)
	self.nullTowns[SZL["Vengeance Landing"]]           = true -- Howling Fjord (Horde)
	self.nullTowns[SZL["Valgarde"]]                    = true -- Howling Fjord (Alliance)
	self.sanctuariesByID[125]                          = true -- Dalaran, Crystalsong Forest
	self.sanctuaries[SZL["Argent Tournament Grounds"]] = true -- Icecrown
	self.sanctuaries[SZL["The Frozen Halls"]]          = true -- Icecrown Citadel, Icecrown
	self.checkZones[SZL["Borean Tundra"]]              = true -- (for Valiance Keep/Warsong Hold)
	self.checkZones[SZL["Howling Fjord"]]              = true -- (for Valgarde/Vengeance Landing)

	self.checkEvent["UNIT_EXITED_VEHICLE"]             = false -- this is used when in a vehicle
	self.trackEvent["UNIT_ENTERED_VEHICLE"]            = true -- this is used when in a vehicle

	if self.isClsc then
		return
	end

	-- Cataclysm
	self.nullAreas[SZL["KTC Headquarters"]]            = true -- Goblin starting area (Cata)
	self.nullAreas[SZL["Karazhan"]]                    = true -- Deadwind Pass (Cata)
	self.nullAreas[SZL["Krom'gar Fortress"]]           = true -- Horde Base in Stonetalon Mts (Cata)
	-- Pandaria
	self.nullAreas[SZL["The Celestial Court"]]         = true -- Timeless Isle (MoP)
	-- Legion
	self.nullAreas[SZL["The Vindicaar"]]               = true -- Argus (Legion)
	-- BfA
	self.nullAreas[SZL["Upton Borough"]]               = true -- Boralus Hub (BfA)
	-- Pandaria (MoP)
	self.nullHubs[SZL["Shrine of Two Moons"]]          = true -- (Horde)
	self.nullHubs[SZL["Shrine of Seven Stars"]]        = true -- (Alliance)
	-- Ashran (WoD)
	self.nullHubs[SZL["Warspear"]]                     = true -- (Horde)
	self.nullHubs[SZL["Stormshield"]]                  = true -- (Alliance)
	-- Boralus (BfA)
	self.nullHubs[SZL["Boralus Harbor"]]               = true -- (Alliance)
	self.nullHubs[SZL["Stormsong Monastery"]]          = true -- (Alliance)
	-- Kul Tiras (BfA)
	self.nullHubsByID[1161]                            = true -- Boralus, Tiragarde Sound (Alliance)
	-- Zandalar (BfA)
	self.nullHubsByID[862]                             = true -- Dazar'alor [The Royal Treasury], Zuldazar (Horde)
	self.nullHubsByID[1163]                            = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1164]                            = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1165]                            = true -- Dazar'alor, Zuldazar (Horde)
	-- Nazjatar (BfA)
	self.nullHubsByID[1355]                            = true
	-- Mechagon (BfA)
	self.nullHubsByID[1462]                            = true

	-- Cataclysm
	self.sanctuaries[SZL["Temple of Earth"]]           = true -- Deepholm
	-- self.sanctuaries[SZL["Malfurion's Breach"]]     = true -- The Molten Front, Firelands ?
	-- Darkmoon Island locations include the Darkmoon Faire, Darkmoon Island Cave, Cauldron of Rock, The Great Sea
	self.sanctuaries[SZL["Darkmoon Island"]]           = true -- Darkmoon Island
	-- Pandaria
	self.sanctuaries[SZL["Cave of the Crane"]]         = true -- Kun-Lai Summit
	self.sanctuaries[SZL["Peak of Serenity"]]          = true -- Kun-Lai Summit
	self.sanctuaries[SZL["Shrine of the Ox"]]          = true -- Kun-Lai Summit
	self.sanctuaries[SZL["Terrace of the Tiger"]]      = true -- Kun-Lai Summit
	self.sanctuaries[SZL["Training Grounds"]]          = true -- Kun-Lai Summitx
	-- Legion
	self.sanctuariesByID[627]                          = true -- Dalaran, Broken Isles (Legion)
	self.sanctuariesByID[647]                          = true -- Acherus: The Ebon Hold, Broken Isles [DeathKnight Order Hall]
	self.sanctuaries[SZL["Light's Hope Chapel"]]       = true -- Eastern Plaguelands
	self.sanctuaries[SZL["Shal'Aran"]]                 = true -- Suramar
	self.sanctuaries[SZL["Deliverance Point"]]         = true -- Broken Shore
	self.sanctuaries[SZL["The Dreamgrove"]]            = true -- Val'sharah [Druid Order Hall]
	self.sanctuaries[SZL["Netherlight Temple"]]        = true -- Twisting Nether [Priest Order Hall]
	self.sanctuaries[SZL["Dreadscar Rift"]]            = true -- Twisting Nether [Warlock Order Hall]
	self.sanctuaries[SZL["The Heart of Azeroth"]]      = true -- The Maelstrom [Shaman Order Hall]
	self.sanctuaries[SZL["The Fel Hammer"]]            = true -- Mardum [Demon Hunter Order Hall]
	self.sanctuaries[SZL["Temple of Five Dawns"]]      = true -- The Wandering Isle [Monk Order Hall]
	self.sanctuaries[SZL["Trueshot Lodge"]]            = true -- Highmountain [Hunter Order Hall]
	self.sanctuaries[SZL["Skyhold"]]                   = true -- Stormheim [Warrior Order Hall]
	-- Sanctum of Light (Light's Hope Chapel) [Paladin Order Hall]
	-- Hall of Shadows (Dalaran) [Rogue Order Hall]
	-- Hall of the Guardian (Dalaran) [Mage Order Hall]
	-- BfA
	self.sanctuaries[SZL["Magni's Encampment"]]        = true -- Silithus
	self.sanctuaries[SZL["Chamber of Heart"]]          = true -- Silithus [Zone in it's own right]
	-- SL
	self.sanctuaries[SZL["Oribos"]]                    = true -- Oribos
	self.sanctuaries[SZL["Hero's Rest"]]               = true -- Bastion
	self.sanctuaries[SZL["Ve'nari's Refuge"]]          = true -- The Maw
	self.sanctuaries[SZL["Keeper's Respite"]]          = true -- Korthia
	self.sanctuaries[SZL["Haven"]]                     = true -- Zereth Mortis
	self.sanctuaries[SZL["Exile's Hollow"]]            = true -- Zereth Mortis
	self.sanctuaries[SZL["Pilgrim's Grace"]]           = true -- Zereth Mortis
	-- Covenant Sanctums (SL) also Sanctuaries
	self.sanctums[SZL["Heart of the Forest"]]          = true -- Ardenweald [Night Fae] (1565)
	self.sanctums[SZL["Seat of the Primus"]]           = true -- Maldraxxus [Necrolord] (1698)
	self.sanctums[SZL["Sinfall"]]                      = true -- Revendreth [Venthyr] (1699)
	self.sanctumsByID[1707]                            = true -- Bastion [Kyrian] (Elysian Hold/Valiant's Path/Archon's Rise/The Eternal Watch)
	self.sanctumsByID[1708]                            = true -- Bastion [Kyrian] (Sanctum of Binding)

	-- (Cata)
	self.checkZones[SZL["Kezan"]]                      = true -- (for KTC Headquarters)
	self.checkZones[SZL["Timeless Isle"]]              = true
	-- (BfA)
	self.checkZonesByID[862]                           = true -- Zuldazar (Horde)
	self.checkZonesByID[895]                           = true -- Tiragarde Sound (Alliance)
	self.checkZonesByID[1161]                          = true -- Boralus (Alliance)
	self.checkZonesByID[1165]                          = true -- Dazar'alor (Horde)

	self.checkEvent["SCENARIO_UPDATE"]                 = true -- this is for scenario check
	self.checkEvent["UNIT_EXITED_VEHICLE"]             = false -- this is used when in a vehicle

	self.trackEvent["SCENARIO_UPDATE"]                 = true -- this is for scenario check
	self.trackEvent["UNIT_ENTERED_VEHICLE"]            = true -- this is used when in a vehicle
	self.trackEvent["PLAYER_ENTERING_WORLD"]           = true -- this is for garrison check
	-- self.trackEvent["UNIT_EXITED_VEHICLE"]          = false -- this is used when in a vehicle

end
