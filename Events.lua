--print("Loaded <Events.lua>")
local log = _G.LEDII_TILE_LOG
local const = _G.LEDII_TILE_CONST
local tiling = _G.LEDII_TILE_TILING

local function PrivateClass()
	local obj = {}

	obj.xpLevel = 1
	obj.xpAmount = 0
	obj.xpNext = 0
	obj.xpSource = ""

	function obj:OnPlayerLogin()
		obj.xpLevel = UnitLevel("player")
		obj.xpAmount = UnitXP("player")
		obj.xpNext = UnitXPMax("player")

		log:Info("Version " .. const:String("VERSION") .. " loaded!")
		log:Info(_G.LEDII_TILE_WELCOME)

		tiling:OnPlayerLogin() --sometimes fails
	end

	function obj:OnExperienceChanged(xp)
		tiling:OnExperienceChanged(obj.xpSource, xp)
	end

	function obj:OnZoneChanged(indoors)
		tiling:OnZoneChanged(indoors)
	end

	function obj:ParseCombatXP(message)
		local output = {}
		log:Info("Parsing 2: " .. message)

		-- This regex will match all numbers in the message
		local numbers = {}
		for num in message:gmatch("%d+") do
			table.insert(numbers, tonumber(num))
		end

		if (#numbers > 0) then
			output.total = numbers[1]
		end
		if (#numbers > 1) then
			output.bonus = numbers[2]
		end

		return output
	end

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_EVENTS = class

local function OnEvent(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		class:OnPlayerLogin()
	elseif (event == "PLAYER_XP_UPDATE") then
		local xpDelta = UnitXP("player") - class.xpAmount
		if (UnitLevel("player") > class.xpLevel) then
			xpDelta = class.xpNext - class.xpAmount + UnitXP("player")
		end
		class.xpLevel = UnitLevel("player")
		class.xpAmount = UnitXP("player")
		class.xpNext = UnitXPMax("player")
		class:OnExperienceChanged(xpDelta)
	elseif (event == "CHAT_MSG_COMBAT_XP_GAIN") then
		class.xpSource = "COMBAT"
	elseif (event == "CHAT_MSG_SYSTEM") then
		class.xpSource = "DISCOVER"
	elseif (event == "QUEST_TURNED_IN") then
		class.xpSource = "QUEST"
	elseif (event == "ZONE_CHANGED") then
		class:OnZoneChanged(false)
	elseif (event == "ZONE_CHANGED_INDOORS") then
		class:OnZoneChanged(true)
	end
end

--Register the event
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:SetScript("OnEvent", OnEvent)