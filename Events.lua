--print("Loaded <Events.lua>")
local log = _G.LEDII_TILE_LOG
local const = _G.LEDII_TILE_CONST
local tiling = _G.LEDII_TILE_TILING

local function PrivateClass()
	local obj = {}
	local ignoreNextCombat = false

	function obj:OnPlayerLogin()
		log:Info("Version " .. const:String("VERSION") .. " loaded!")
		log:Info(_G.LEDII_TILE_WELCOME)

		tiling:OnPlayerLogin() --sometimes fails
	end

	function obj:OnExperienceChanged(source, xp)
		if (source == "COMBAT" and ignoreNextCombat) then
			ignoreNextCombat = false
			return
		end

		if (source == "QUEST") then
			ignoreNextCombat = true
		end

		tiling:OnExperienceChanged(source, xp)
	end

	function obj:OnZoneChanged(indoors)
		tiling:OnZoneChanged(indoors)
	end

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_EVENTS = class

local function OnEvent(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		class:OnPlayerLogin()
	elseif (event == "CHAT_MSG_COMBAT_XP_GAIN") then
		local message = ...
		local xp = tonumber(message:match("gain (%d+) experience"))
        local bonus = message:match("%+%d+ exp Rested bonus")
		class:OnExperienceChanged("COMBAT", xp)
	elseif (event == "CHAT_MSG_SYSTEM") then
		local message = ...
		local xp = string.match(message, "^Discovered .-: (%d+) experience gained$")
		if (xp == nil) then return end
		class:OnExperienceChanged("DISCOVER", xp)
	elseif (event == "QUEST_TURNED_IN") then
		local id, xp = ...
		class:OnExperienceChanged("QUEST", xp)
	elseif (event == "ZONE_CHANGED") then
		class:OnZoneChanged(false)
	elseif (event == "ZONE_CHANGED_INDOORS") then
		class:OnZoneChanged(true)
	end
end

--Register the event
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:SetScript("OnEvent", OnEvent)