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
	local playersToPing = nil
	local playersWithAddon = nil

	--Public
	function obj:Setup()
		C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
	end

	function obj:OnPlayerLogin()
		--obj:Broadcast("PARTY", { "Login", "PlayerNameHere" })
	end

	function obj:OnScan()
		log:Info("Starting scan for players with addon...")
		playersToPing = {}
		playersWithAddon = nil
		C_FriendList.SendWho("")
	end

	function obj:Broadcast(channel, values, player)
		local csvMessage = utils:JoinTable(values, ",")
		--log:Info("[Out]" .. csvMessage)

		if (DEBUG) then
			C_ChatInfo.SendAddonMessage(ADDON_PREFIX, csvMessage, "WHISPER", UnitName("player"))
		else
			C_ChatInfo.SendAddonMessage(ADDON_PREFIX, csvMessage, channel, player)
		end
	end

	function obj:OnBroadcastReceived(prefix, csvMessage, channel, sender)
		if (prefix ~= ADDON_PREFIX) then return end
		if (not DEBUG and sender == UnitName("player")) then return end

		local values = utils:Split(csvMessage, ",")
		local type = values[1]
		local state = values[2]

		log:Info("[In]: " .. csvMessage)

		if (type == "PingRequest") then
			local index = tonumber(values[3])

			if (state == "Init") then
				obj:Broadcast("WHISPER", { type, "Confirm", index }, sender)
			elseif (state == "Confirm") then
				table.insert(playersWithAddon, playersToPing[index])
			end
		end
	end

	function obj:OnWhoListUpdate()
		if (playersToPing == nil) then return end --Not expecting who update
		if (playersWithAddon ~= nil) then return end --Has received who update

		playersWithAddon = {}

		--Store player info
        local numWhos = C_FriendList.GetNumWhoResults()
        for i = 1, numWhos do
            local player = C_FriendList.GetWhoInfo(i)
			table.insert(playersToPing, player)
        end

		--Ping players
		log:Info("Pinging " .. numWhos .. " from who list...")
		obj:PingNextPlayer()
	end

	function obj:PingNextPlayer(index)
		index = index or 1
		if (index > #playersToPing) then return end

		local player = playersToPing[index]
		obj:Broadcast("WHISPER", { "PingRequest", "Init", index, player.fullName }, player.fullName)

		C_Timer.After(0.3, function()
			obj:PingNextPlayer(index + 1)
		end)
	end

	return obj
end

local class = PrivateClass()
class:Setup()
_G.LEDII_TILE_GROUPING = class