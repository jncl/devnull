local aName, aObj = ...

local _G = _G

function aObj:print2Chat(text)

	if self.prdb.chatback then
		self.Print(aObj.L[aName], aObj.L[text])
	end

end

-- Garrison functions
aObj.bodyguardNames = {}
local info
function aObj.isGarrison(_, str)

	return str and str:find("Garrison Level") and true

end
function aObj:getBGNames()

	-- Followers with Bodyguard trait:
	-- Tormmok (193)
	-- Defender Illona [A] / Aeda Brightdawn [H] (207)
	-- Delvar Ironfist [A] / Vivianne [H] (216)
	-- Talonpriest Ishael (218)
	-- Leorajh (219)
	if self.prdb.noBguard then
		for _, id in _G.pairs{193, 207, 216, 218, 219} do
			info = _G.C_Garrison.GetFollowerInfo(id)
			if info then
				aObj.bodyguardNames[info.name] = true
				aObj:LevelDebug(5, "Follower:", id, info.name)
			end
		end
	end

end

function aObj:resetModes()

	for modeName, _ in _G.pairs(self.modeTab) do
		self:LevelDebug(5, "resetModes#1: [%s, %s, %s]", modeName, self.modeTab[modeName])
		self.modeTab[modeName] = false
		self:LevelDebug(5, "resetModes#2: [%s, %s, %s]", modeName, self.modeTab[modeName])
	end

end

function aObj:ResetAllEvents()

	for evt, _ in _G.pairs(self.events) do
		self.events[evt].check = self.events[evt].default
	end

end

function aObj:UncheckAllEvents()

	for evt, _ in _G.pairs(self.events) do
		self.events[evt].check = false
	end

end

local status
function aObj:updateDBtext(noShrink)

	self:LevelDebug(4, "updateDBtext: [%s:%s, %s:%s, %s:%s, %s:%s]", self.L["Hub"], _G.tostring(self.modeTab.Hub), self.L["Sanctuary"], _G.tostring(self.modeTab.Sanctuary), self.L["Pet Battle"], _G.tostring(self.modeTab.PetBattle), self.L["Taxi"], _G.tostring(self.modeTab.Taxi))
	if not self.isClscERA then
		self:LevelDebug(4, "updateDBtext: [%s:%s, %s:%s, %s:%s]", self.L["Vehicle"], _G.tostring(self.modeTab.Vehicle), self.L["Scenario"], _G.tostring(self.modeTab.Scenario), self.L["Instance"], _G.tostring(self.modeTab.Instance))
	end
	if self.isMnln then
		self:LevelDebug(4, "updateDBtext: [%s:%s, %s %s:%s]", self.L["Garrison"], _G.tostring(self.modeTab.Garrison), self.L["Bodyguard"], _G.tostring(self.prdb.noBguard))
	end

	status = self.L["Off"]
	for modeName, mode in _G.pairs(self.modeTab) do
		self:LevelDebug(5, "updateDBtext mode Info: [%s, %s, %s]", modeName, mode)
		if self.modeTab[modeName] then
			status = self.L[modeName]
			break
		end
	end

	self:LevelDebug(4, "updateDBtext status: [%s]", status)

	if not self.prdb.shrink
	or noShrink
	then
		return status
	else
		return status:sub(1, 1)
	end

end

--@debug@
aObj.debugLevel = 1
function aObj:LevelDebug(lvl, fStr, ...)

	if lvl <= self.debugLevel then
		self:Debug(fStr, ...)
	end

end
--@end-debug@
--[===[@non-debug@
function aObj:LevelDebug() end
--@end-non-debug@]===]
