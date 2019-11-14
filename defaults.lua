local aName, aObj = ...
local _G = _G

function aObj:SetupDefaults()

	-- get Locale
	self.L = LibStub:GetLibrary("AceLocale-3.0"):GetLocale(aName)

	local defaults = { profile = {
		chatback      = true,
		shrink        = false,
		achFilterType = 0,
		noDiscovery   = true,
		noDrunk       = true,
		noDuel        = true,
		noEmote       = false,
		noNPC         = false,
		noPetInfo     = false,
		noTradeskill  = false,
		noMYell       = false,
		noPYell       = false,
		gChat         = false,
		noBguard      = false,
		noOrderHall   = false,
		iChat         = true,
		inInst        = false,
		-- ChatFrame1 channel settings
		cf1Channels = {
			[self.L["General"]]          = false,
			[self.L["Trade"]]            = false,
			[self.L["LocalDefense"]]     = false,
			[self.L["WorldDefense"]]     = false,
			[self.L["GuildRecruitment"]] = false,
		},
	}}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New(aName .. "DB", defaults, "Default")

	-- message groups to filter
	self.mGs = {
		["MONSTER_YELL"] = false,
		["TRADESKILLS"] = false,
		["PET_INFO"] = false,
		["ACHIEVEMENT"] = false,
		["GUILD_ACHIEVEMENT"] = false,
	}
	-- events to track
	self.trackEvent = {
		["ZONE_CHANGED_INDOORS"]  = true, -- for tunnel into Booty Bay & Boralus Harbor
		["ZONE_CHANGED"]		  = true, -- this is for changes of sub area
		["ZONE_CHANGED_NEW_AREA"] = true, -- this is for changes of area
		["PLAYER_LEAVING_WORLD"]  = true, -- this is for boat trips
		["PLAYER_CONTROL_LOST"]   = true, -- this is for taxi check
	}

	-- pointer to LibBabble-SubZone-3.0 library
	local SZL = LibStub:GetLibrary("LibBabble-SubZone-3.0"):GetLookupTable()

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
		[SZL["The Old Port Authority"]]  = true, -- in BB
		[SZL["The Salty Sailor Tavern"]] = true, -- in BB
		[SZL["Foothold Citadel"]]        = true, -- in Theramore Isle
	}
	self.nullHubs = {
		-- Kalimdor
		[SZL["Orgrimmar"]] = true, -- Orgrimmar
		[SZL["Thunder Bluff"]] = true, -- Thunder Bluff
		[SZL["Darnassus"]] = true, -- Darnassus
		-- Eastern Kingdoms
		[SZL["Stormwind City"]] = true, -- Stormwind City
		[SZL["Ironforge"]] = true, -- Ironforge
		[SZL["Undercity"]] = true, -- Undercity
	}
	self.checkZones = {
		-- used for smaller area changes
		[SZL["Northern Barrens"]] = true, -- Northern Barrens (for Ratchet)
		[SZL["Elwynn Forest"]] = true, -- Elwynn Forest (for Goldshire)
		[SZL["Deadwind Pass"]] = true, -- Deadwind Pass (for Karazhan)
		[SZL["Stonetalon Mountains"]] = true, -- Stonetalon Mountains (for Krom'gar Fortess)
		[SZL["Dustwallow Marsh"]] = true, -- Dustwallow Marsh (for Theramore Isle)
		[SZL["Tanaris"]] = true, -- Tanaris (for Gadgetzan)
		[SZL["Winterspring"]] = true, -- Winterspring (for Everlook)
		[SZL["The Cape of Stranglethorn"]] = true, -- The Cape of Stranglethorn (for Booty Bay)
	}
	self.checkZonesByID = {}
	self.garrisonZones= {}
	self.orderHalls = {}
	self.checkEvent = {
		["ZONE_CHANGED_INDOORS"]  = true, -- for tunnel into Booty Bay
		["ZONE_CHANGED"]          = true, -- used to handle boat trips
		["ZONE_CHANGED_NEW_AREA"] = true, -- used to handle most changes of area
		["PLAYER_CONTROL_GAINED"] = true, -- this is for taxi check
	}

	if not aObj.isClassic then
		self.nullTowns[SZL["Mudsprocket"]] = true
		-- Outland (TBC)
		self.nullTowns[SZL["Thrallmar"]] = true -- Hellfire Peninsula (Horde)
		self.nullTowns[SZL["Honor Hold"]] = true -- Hellfire Peninsula (Alliance)
		self.nullTowns[SZL["Area 52"]] = true -- Netherstorm
		-- Northrend (WotLK)
		self.nullTowns[SZL["Warsong Hold"]] = true -- Borean Tundra (Horde)
		self.nullTowns[SZL["Valiance Keep"]] = true -- Borean Tundra (Alliance)
		self.nullTowns[SZL["Vengeance Landing"]] = true -- Howling Fjord (Horde)
		self.nullTowns[SZL["Valgarde"]] = true -- Howling Fjord (Alliance)

		-- Kul Tiras (BfA)
		self.nullTownsByID[1161] = true -- Boralus, Tiragarde Sound (Alliance)
		-- Zandalar (BfA)
		self.nullTownsByID[1163] = true -- Dazar'alor [The Great Seal], Zuldazar (Horde)
		self.nullTownsByID[1165] = true -- Dazar'alor, Zuldazar (Horde)
		-- Nazjatar
		self.nullTownsByID[1355] = true
		-- Mechagon
		self.nullTownsByID[1462] = true

		self.nullAreas[SZL["The Darkmoon Faire"]] = true -- Darkmoon Island (patch 4.3)
		self.nullAreas[SZL["KTC Headquarters"]] = true -- Goblin starting area (Cataclysm)
		self.nullAreas[SZL["Karazhan"]] = true -- Karazhan
		self.nullAreas[SZL["Krom'gar Fortress"]] = true -- Horde Base in Stonetalon Mts (Cataclysm)
		self.nullAreas[SZL["The Celestial Court"]] = true -- Timeless Isle (MoP)
		self.nullAreas[SZL["The Vindicaar"]] = true -- The Vindicaar (Legion [Argus])
		self.nullAreas["Upton Borough"] = true -- Boralus Hub (BfA)

		-- Outland (TBC)
		self.nullHubs[SZL["Shattrath City"]] = true -- Shattrath City
		-- Northrend (WotLK)
		self.nullHubs[SZL["Dalaran"]] = true -- Dalaran
		-- Pandaria (MoP)
		self.nullHubs[SZL["Shrine of Two Moons"]] = true -- Shrine of Two Moons (Horde)
		self.nullHubs[SZL["Shrine of Seven Stars"]] = true -- Shrine of Seven Stars (Alliance)
		-- Ashran (Draenor)
		self.nullHubs[SZL["Stormshield"]] = true -- Stormshield (Alliance)
		self.nullHubs[SZL["Warspear"]] = true -- Warspear (Horde)
		-- Boralus (BfA)
		self.nullHubs["Boralus Harbor"] = true -- (Alliance)
		self.nullHubs["Stormsong Monastery"] = true -- (Alliance)

		self.checkZones[SZL["Hellfire Peninsula"]] = true -- Hellfire Peninsula (for Honor Hold)
		self.checkZones[SZL["Netherstorm"]] = true -- Netherstorm (for Area 52)
		self.checkZones[SZL["Borean Tundra"]] = true -- Borean Tundra (for Valiance Keep/Warsong Hold)
		self.checkZones[SZL["Howling Fjord"]] = true -- Howling Fjord (for Valgarde/Vengeance Landing)
		self.checkZones[SZL["Kezan"]] = true -- Kezan (for KTC Headquarters)
		self.checkZones[SZL["Timeless Isle"]] = true -- Timeless Isle

		self.checkZonesByID[862] = true -- Zuldazar (Horde)
		self.checkZonesByID[895] = true -- Tiragarde Sound (Alliance)
		self.checkZonesByID[1161] = true -- Boralus (Alliance)
		self.checkZonesByID[1165] = true -- Dazar'alor (Horde)

		self.garrisonZones[582] = true -- Lunarfall (Alliance)
		self.garrisonZones[590] = true -- Frostwall (Horde)

		self.orderHalls[695] = true -- Skyhold (Warrior)
		self.orderHalls[702] = true -- Netherlight Temple (Priest)
		self.orderHalls[709] = true -- The Wandering Isle (Monk)
		self.orderHalls[719] = true -- Mardum, the Shattered Abyss (Demon Hunter)
		-- self.orderHalls[726] = true -- The Heart of Azeroth (Shaman)
		self.orderHalls[734] = true -- Hall of the Guardian (Mage)
		self.orderHalls[739] = true -- Trueshot Lodge (Hunter)
		self.orderHalls[747] = true -- The Dreamgrove (Druid)

		self.checkEvent["SCENARIO_UPDATE"] = true -- this is for scenario check
		self.checkEvent["UNIT_EXITED_VEHICLE"] = false -- this is used when in a vehicle

		self.trackEvent["SCENARIO_UPDATE"] = true -- this is for scenario check
		self.trackEvent["UNIT_ENTERED_VEHICLE"] = true -- this is used when in a vehicle
		-- self.trackEvent["UNIT_EXITED_VEHICLE"] = false -- this is used when in a vehicle
		self.trackEvent["PLAYER_ENTERING_WORLD"] = true -- this is for garrison check

	end

	self.inHub = false
	self.onTaxi = false
	self.exitedInst = false
	self.inScenario = false
	self.inGarrison = false
	self.inOrderHall = false
	self.inVehicle = false

	-- store player and pet names
	self.player = _G.UnitName("player")
	self.pet = _G.UnitName("pet")

end
