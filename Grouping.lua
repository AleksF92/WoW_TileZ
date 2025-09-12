--print("Loaded <Grouping.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS
local ui = _G.LEDII_TILE_UI
local tiling = _G.LEDII_TILE_TILING

local function PrivateClass()
	local obj = {}

	--Consts
	local SCAN_INTERVAL = 5.0
	local ADDON_PREFIX = "Ledii_TileZ"
	local DEBUG = true

	--Privates
	local scanTimer = nil

	--Public
	function obj:Setup()
		C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
	end

	function obj:OnPlayerLogin()
		obj:Broadcast("PARTY", { "Login", "PlayerNameHere" })
		obj:SetScanForPlayers(true)
	end

	function obj:SetScanForPlayers(enabled)
		--Clear timer
		if (scanTimer) then
			scanTimer:Cancel()
			scanTimer = nil
		end

		--Start timer
		if (enabled) then
			scanTimer = C_Timer.NewTicker(SCAN_INTERVAL, obj.OnScan)
		end
	end

	function obj:OnScan()
		obj:Broadcast("PARTY", { "ScanRequest", "PlayerNameHere" })
	end

	function obj:Broadcast(channel, values)
		local csvMessage = utils:JoinTable(values, ",")
		--log:Info("Sending addon message: " .. channel .. " | " .. message)

		if (DEBUG) then
			C_ChatInfo.SendAddonMessage(ADDON_PREFIX, csvMessage, "WHISPER", UnitName("player"))
		else
			C_ChatInfo.SendAddonMessage(ADDON_PREFIX, csvMessage, channel)
		end
	end

	function obj:OnBroadcastReceived(prefix, csvMessage, channel, sender)
		if (prefix ~= ADDON_PREFIX) then return end
		if (not DEBUG and sender == UnitName("player")) then return end

		local values = utils:Split(csvMessage, ",")
		local type = values[1]
		local text = values[2]

		log:Info("Received addon message: " .. type .. " | " .. text)
	end

	return obj
end

local class = PrivateClass()
class:Setup()
_G.LEDII_TILE_GROUPING = class