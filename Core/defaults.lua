local aName, aObj = ...

local _G = _G

function aObj:SetupDefaults()

	self.inHub       = false
	self.onTaxi      = false
	self.exitedInst  = false
	self.inScenario  = false
	self.inGarrison  = false
	self.inOrderHall = false
	self.inVehicle   = false

	-- store player and pet names
	self.player      = _G.UnitName("player")
	self.pet         = _G.UnitName("pet")

	-- get Locale
	self.L = _G.LibStub:GetLibrary("AceLocale-3.0"):GetLocale(aName)

	local defaults = { profile = {
		achFilterType = 0,
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
		["ZONE_CHANGED_NEW_AREA"] = true, -- used to handle most changes of area
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

	if self.isClsc
	and not self.isClscBC
	then
		return
	end

	-- Eversong Woods (TBC)
	self.nullHubs[SZL["Silvermoon City"]]		= true -- Blood Elf starting area (Horde)
	-- Azuremyst Isle (TBC)
	self.nullHubs[SZL["The Exodar"]]			= true -- Draenei starting area (Alliance)

	-- Outland (TBC)
	self.nullTowns[SZL["Honor Hold"]]           = true -- Hellfire Peninsula (Alliance)
	self.nullTowns[SZL["Thrallmar"]]            = true -- Hellfire Peninsula (Horde)
	self.nullTowns[SZL["Area 52"]]              = true -- Netherstorm
	self.nullHubs[SZL["Shattrath City"]]        = true -- Terokkar Forest
	self.checkZones[SZL["Hellfire Peninsula"]]  = true -- (for Honor Hold & Thrallmar)
	self.checkZones[SZL["Netherstorm"]]         = true -- (for Area 52)

	if self.isClscBC then
		return
	end

	self.nullTowns[SZL["Mudsprocket"]]          = true -- Dustwallow Marsh (Neutral)

	-- Northrend (WotLK)
	self.nullTowns[SZL["Warsong Hold"]]         = true -- Borean Tundra (Horde)
	self.nullTowns[SZL["Valiance Keep"]]        = true -- Borean Tundra (Alliance)
	self.nullTowns[SZL["Vengeance Landing"]]    = true -- Howling Fjord (Horde)
	self.nullTowns[SZL["Valgarde"]]             = true -- Howling Fjord (Alliance)

	self.nullAreas[SZL["The Darkmoon Faire"]]   = true -- Darkmoon Island (patch 4.3)
	self.nullAreas[SZL["KTC Headquarters"]]     = true -- Goblin starting area (Cata)
	self.nullAreas[SZL["Karazhan"]]             = true -- Deadwind Pass (Cata)
	self.nullAreas[SZL["Krom'gar Fortress"]]    = true -- Horde Base in Stonetalon Mts (Cata)
	self.nullAreas[SZL["The Celestial Court"]]  = true -- Timeless Isle (MoP)
	self.nullAreas[SZL["The Vindicaar"]]        = true -- Argus (Legion)
	self.nullAreas[SZL["Upton Borough"]]        = true -- Boralus Hub (BfA)

	-- Northrend (WotLK)
	self.nullHubs[SZL["Dalaran"]]               = true
	-- Pandaria (MoP)
	self.nullHubs[SZL["Shrine of Two Moons"]]   = true -- (Horde)
	self.nullHubs[SZL["Shrine of Seven Stars"]] = true -- (Alliance)
	-- Ashran (WoD)
	self.nullHubs[SZL["Warspear"]]              = true -- (Horde)
	self.nullHubs[SZL["Stormshield"]]           = true -- (Alliance)
	-- Boralus (BfA)
	self.nullHubs[SZL["Boralus Harbor"]]        = true -- (Alliance)
	self.nullHubs[SZL["Stormsong Monastery"]]   = true -- (Alliance)
	-- Oribos (SL)
	self.nullHubs[SZL["Oribos"]]                = true -- Sanctuary

	-- Covenant Sanctums (SL)
	self.sanctums[SZL["Heart of the Forest"]]   = true -- Ardenweald [Night Fae] (1565)
	self.sanctums[SZL["Seat of the Primus"]]    = true -- Maldraxxus [Necrolord] (1698)
	self.sanctums[SZL["Sinfall"]]               = true -- Revendreth [Venthyr] (1699)

	self.sanctumsByID[1707]                     = true -- Bastion [Kyrian] (Elysian Hold/Valiant's Path/Archon's Rise/The Eternal Watch)
	self.sanctumsByID[1708]                     = true -- Bastion [Kyrian] (Sanctum of Binding)

	-- Kul Tiras (BfA)
	self.nullHubsByID[1161]                     = true -- Boralus, Tiragarde Sound (Alliance)
	-- Zandalar (BfA)
	self.nullHubsByID[862]                      = true -- Dazar'alor [The Royal Treasury], Zuldazar (Horde)
	self.nullHubsByID[1163]                     = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1164]                     = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
	self.nullHubsByID[1165]                     = true -- Dazar'alor, Zuldazar (Horde)
	-- Nazjatar (BfA)
	self.nullHubsByID[1355]                     = true
	-- Mechagon (BfA)
	self.nullHubsByID[1462]                     = true

	-- Northrend (WotLK)
	self.checkZones[SZL["Borean Tundra"]]       = true -- (for Valiance Keep/Warsong Hold)
	self.checkZones[SZL["Howling Fjord"]]       = true -- (for Valgarde/Vengeance Landing)
	-- (Cata)
	self.checkZones[SZL["Kezan"]]               = true -- (for KTC Headquarters)
	self.checkZones[SZL["Timeless Isle"]]       = true

	-- (BfA)
	self.checkZonesByID[862]                    = true -- Zuldazar (Horde)
	self.checkZonesByID[895]                    = true -- Tiragarde Sound (Alliance)
	self.checkZonesByID[1161]                   = true -- Boralus (Alliance)
	self.checkZonesByID[1165]                   = true -- Dazar'alor (Horde)

	self.checkEvent["SCENARIO_UPDATE"]          = true -- this is for scenario check
	self.checkEvent["UNIT_EXITED_VEHICLE"]      = false -- this is used when in a vehicle

	self.trackEvent["SCENARIO_UPDATE"]          = true -- this is for scenario check
	self.trackEvent["UNIT_ENTERED_VEHICLE"]     = true -- this is used when in a vehicle
	self.trackEvent["PLAYER_ENTERING_WORLD"]    = true -- this is for garrison check
	-- self.trackEvent["UNIT_EXITED_VEHICLE"]   = false -- this is used when in a vehicle

end
