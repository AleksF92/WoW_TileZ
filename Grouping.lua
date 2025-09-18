--print("Loaded <Grouping.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS
local ui = _G.LEDII_TILE_UI
local tiling = _G.LEDII_TILE_TILING

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	--Consts
	local SCAN_INTERVAL = 5.0
	local ADDON_PREFIX = "Ledii_TileZ"
	local DEBUG = true

	--Privates
	local scanActive = false
	local playersToPing = nil
	local playersWithAddon = nil
	local playersInParty = {}

	--Saved
	local playersInSync = {}
	----- VARIABLES END -----



	----- SETUP BEGIN -----
	function obj:Load()
		--Init data
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		playersInSync = LediiData_TileZ_Character.playersInSync or {}
	end

	function obj:Save()
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		LediiData_TileZ_Character.playersInSync = playersInSync
	end

	function obj:Reset()
		LediiData_TileZ = nil
		LediiData_TileZ_Character = nil
	end
	----- SETUP END -----



	----- UTILITY BEGIN -----
	function obj:Setup()
		C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
	end

	function obj:PingNextPlayer(index)
		index = index or 1
		if (index > #playersToPing) then
			scanActive = false
			return
		end

		local player = playersToPing[index]
		obj:Broadcast("WHISPER", { "PingRequest", "Init", index, player.fullName }, player.fullName)

		C_Timer.After(0.3, function()
			obj:PingNextPlayer(index + 1)
		end)
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

	function obj:GetPlayerData(unit)
		local name, realm = UnitFullName(unit)

		local player = {}
		player.fullName = name .. "-" .. realm

		return player
	end
	----- UTILITY END -----



	----- EVENTS BEGIN -----
	function obj:OnPlayerLogin()
		--obj:Broadcast("PARTY", { "Login", "PlayerNameHere" })
		obj:Load()

		C_Timer.After(3, function()
			local player = obj:GetPlayerData("player")
			--obj:OnGroupJoin(player.fullName)
		end)
	end

	function obj:OnScan()
		if (FriendsFrame:IsVisible() or scanActive) then
			log:Info(const:Color("WARNING") .. "Frame is busy, unable to scan right now.")
			return
		end

		log:Info("Starting scan for players with addon...")
		scanActive = true
		playersToPing = {}
		playersWithAddon = nil
		C_FriendList.SendWho("")
	end

	function obj:OnBroadcastReceived(prefix, csvMessage, channel, sender)
		if (prefix ~= ADDON_PREFIX) then return end
		local player = obj:GetPlayerData("player")
		if (not DEBUG and sender == player.fullName) then return end

		local values = utils:Split(csvMessage, ",")
		local type = values[1]
		local state = values[2]

		log:Info("[In]: " .. csvMessage)

		if (type == "PingRequest") then
			local index = tonumber(values[3])

			if (state == "Init") then
				obj:Broadcast("WHISPER", { type, "Confirm", index }, sender)
			elseif (state == "Confirm") then
				
				if (playersInParty[sender] or sender == player.fullName) then
					obj:OnInviteInit(player.fullName, sender)
				else
					table.insert(playersWithAddon, playersToPing[index])
				end
			end
		elseif (type == "SyncRequest") then
			if (state == "Init") then
				obj:OnInviteConfirm(sender, player.fullName)
			elseif (state == "Confirm") then
				obj:OnInviteCompleted(sender)
			end
		end
	end

	function obj:OnWhoListUpdate()
		if (playersToPing == nil) then return end --Not expecting who update
		if (playersWithAddon ~= nil) then return end --Has received who update

		FriendsFrame:Hide()
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

	function obj:OnGroupUpdate()
		local numMembers = GetNumGroupMembers()
		local newPlayersInParty = {}

		-- Detect join
		for i = 1, numMembers do
			local unit = "party"..i
			if (UnitExists(unit)) then
				local player = obj:GetPlayerData(unit)

				newPlayersInParty[player.fullName] = true

				if (not playersInParty[player.fullName]) then
					obj:OnGroupJoin(player.fullName, unit)
				end
			end
		end

		-- Detect leave
		for fullName in pairs(playersInParty) do
			if not newPlayersInParty[fullName] then
				obj:OnGroupLeave(fullName)
			end
		end

		playersInParty = newPlayersInParty
	end

	function obj:OnGroupJoin(fullName, unit)
		if (not UnitIsGroupLeader(unit) and unit ~= "player") then return end

		log:Info("Player joined party: " .. fullName)

		obj:Broadcast("WHISPER", { "PingRequest", "Init", nil, fullName }, fullName)
	end

	function obj:OnGroupLeave(fullName)
		log:Info("Player left party: " .. fullName)
	end

	function obj:OnInviteInit(sender, receiver)
		if (playersInSync[receiver]) then
			log:Info("Player already synced: " .. receiver)
			return
		end

		local description = receiver .. " is also playing with TileZ."
			.. " Would you like to sync your playthrough?"
		
		ui:RequestPopupDialog(
			"TileZ_SyncInit", description, "Yes", "No",
			function()
				obj:Broadcast("WHISPER", { "SyncRequest", "Init", sender }, receiver)
			end,
			nil
		)
	end

	function obj:OnInviteConfirm(sender, receiver)
		local description = sender .. " has invited you to sync TileZ."
			.. " Would you like to sync your playthrough?"
		
		ui:RequestPopupDialog(
			"TileZ_SyncConfirm", description, "Yes", "No",
			function()
				obj:Broadcast("WHISPER", { "SyncRequest", "Confirm", receiver }, sender)
				obj:OnInviteCompleted(sender)
			end,
			nil
		)
	end

	function obj:OnInviteCompleted(fullName)
		log:Info("Added player to synced: " .. fullName)
		playersInSync[fullName] = true
		obj:Save()
	end
	----- EVENTS END -----

	return obj
end

local class = PrivateClass()
class:Setup()
_G.LEDII_TILE_GROUPING = class