--print("Loaded <Tracking.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS
local ui = _G.LEDII_TILE_UI

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	local debug = false

	local currentXP = 0
	local nextXP = 0
	local availableTiles = 0
	local totalTiles = 0
	local unlockedTiles = {}

	local worldData = nil
	local mapData = nil
	local measureData = nil
	local measureTrigger = false
	local measureHistory = {}
	local measureDistance = 0

	obj.lockMode = "Locked"
	obj.tileSize = 50
	obj.startCount = 3
	obj.xpRate = 1.0

	obj.colors = {}
	obj.colors.currentUnlocked = { r = 0.0, g = 1.0, b = 0.0, a = 1.0 }
	obj.colors.currentLocked = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 }
	obj.colors.otherUnlocked = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }

	obj.textures = {}
	obj.textures.minimap = "Outline"
	obj.textures.map = "Outline"

	obj.isInsideZone = false
	obj.isInsideArea = false

	obj.renderDistance = 3

	----- VARIABLES END -----



	----- SETUP BEGIN -----
	function obj:Load()
		--Init data
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		obj.tileSize = LediiData_TileZ_Character.tileSize or 50
		obj.startCount = LediiData_TileZ_Character.startCount or 3
		obj.xpRate = LediiData_TileZ_Character.xpRate or 1.0

		--Try fetch data
		currentXP = LediiData_TileZ_Character.currentXP or 0
		availableTiles = LediiData_TileZ_Character.availableTiles or obj.startCount
		totalTiles = LediiData_TileZ_Character.totalTiles or 0
		unlockedTiles = LediiData_TileZ_Character.unlockedTiles or {}

		obj.colors = LediiData_TileZ_Character.colors or {}
		obj.colors.currentUnlocked = obj.colors.currentUnlocked or { r = 0.0, g = 1.0, b = 0.0, a = 1.0 }
		obj.colors.currentLocked = obj.colors.currentLocked or { r = 1.0, g = 0.0, b = 0.0, a = 1.0 }
		obj.colors.otherUnlocked = obj.colors.otherUnlocked or { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }

		obj.textures = LediiData_TileZ_Character.textures or {}
		obj.textures.minimap = obj.textures.minimap or "Outline"
		obj.textures.map = obj.textures.map or "Outline"

		obj.renderDistance = LediiData_TileZ_Character.renderDistance or 3
		obj.isInsideZone = LediiData_TileZ_Character.isInsideZone or false
		obj.isInsideArea = LediiData_TileZ_Character.isInsideArea or false
	end

	function obj:Save()
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		LediiData_TileZ_Character.currentXP = currentXP
		LediiData_TileZ_Character.availableTiles = availableTiles
		LediiData_TileZ_Character.totalTiles = totalTiles
		LediiData_TileZ_Character.unlockedTiles = unlockedTiles

		LediiData_TileZ_Character.tileSize = obj.tileSize
		LediiData_TileZ_Character.startCount = obj.startCount
		LediiData_TileZ_Character.xpRate = obj.xpRate

		LediiData_TileZ_Character.colors = obj.colors
		LediiData_TileZ_Character.textures = obj.textures

		LediiData_TileZ_Character.renderDistance = obj.renderDistance
		LediiData_TileZ_Character.isInsideZone = obj.isInsideZone
		LediiData_TileZ_Character.isInsideArea = obj.isInsideArea
	end

	function obj:Reset()
		LediiData_TileZ = nil
		LediiData_TileZ_Character = nil

		local tempStartCount = obj.startCount
		local tempXpRate = obj.xpRate
		obj:Load()
		obj.startCount = tempStartCount
		obj.xpRate = tempXpRate
		availableTiles = obj.startCount

		nextXP = obj:CalculateNextXP(1)

		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
		ui:UpdateSettings()
	end
	----- SETUP END -----



	----- UTILITY BEGIN -----
	function obj:CalculateNextXP(historicLevel)
		local level = historicLevel or UnitLevel("player")
		--local xpPerMob = 45 + (level * 5)
		local xpPerMob = ledii.player.experiencePerMobSameLevel[level]
		return xpPerMob * 4
	end

	function obj:CalculateHistoricXP()
		local level = UnitLevel("player")
		for i = 1, level - 1 do
			local xp = ledii.player.experienceToLevelUp[i]
			nextXP = obj:CalculateNextXP(i)
			obj:OnExperienceChanged("HISTORY_" .. i, xp, i)
		end

		local presentXP = UnitXP("player")
		nextXP = obj:CalculateNextXP(level)
		obj:OnExperienceChanged("HISTORY_" .. level, presentXP)
	end

	function obj:GetWorldPositionData()
		local data = {}

		--Test for special map change null cases
		--if (true) then return nil end

		data.zoneId = C_Map.GetBestMapForUnit("player")

		if (data.zoneId == nil) then return nil end
		data.zoneName = C_Map.GetMapInfo(data.zoneId).name
		data.continentId = C_Map.GetMapInfo(data.zoneId).parentMapID
		data.continentName = C_Map.GetMapInfo(data.continentId).name

		local worldY, worldX = UnitPosition("player")
		local mapX, mapY = C_Map.GetPlayerMapPosition(data.zoneId, "player"):GetXY()
		data.world = { x = worldX, y = worldY }
		data.map = { x = mapX, y = mapY }
		data.tile = { x = data.world.x / obj.tileSize , y = data.world.y / obj.tileSize }
		data.tileId = { x = utils:TruncateNumber(data.tile.x), y = utils:TruncateNumber(data.tile.y) }
		data.tileSize = obj.tileSize
		data.tileKey = obj:GetTileKey(data.tile.x, data.tile.y)
		data.isTransport = obj.lockMode == "Transport"
		data.allowSetup = totalTiles <= 0

		if (worldData == nil) then return data end

		data.isNewZone = data.zoneId ~= worldData.zoneId
		if (data.isNewZone) then
			data.isUnlocked = worldData.isUnlocked
			obj:UnlockCurrentTile(data)
		else
			obj:UnlockCurrentTile(data)
			data.isUnlocked = obj:IsTileUnlocked(data.tileKey, data.zoneId, data.continentId)
		end

		return data
	end

	function obj:GetMapPositionData()
		local data = {}
		data.isVisible = WorldMapFrame:IsVisible()
		data.height = WorldMapFrame.ScrollContainer:GetHeight()
		data.width = WorldMapFrame.ScrollContainer:GetWidth()
		data.unlockedTiles = unlockedTiles

		data.zoneId = WorldMapFrame:GetMapID()
		if (data.zoneId == 0) then return nil end
		data.zoneName = C_Map.GetMapInfo(data.zoneId).name

		data.continentId = C_Map.GetMapInfo(data.zoneId).parentMapID
		if (data.continentId == 0) then
			--Exception for Azeroth
			data.continentId = data.zoneId
		end

		if (data.continentId == 0) then return nil end
		data.continentName = C_Map.GetMapInfo(data.continentId).name

		local mapPos = C_Map.GetPlayerMapPosition(data.zoneId, "player")
		if (mapPos ~= nil) then
			local mapX, mapY = mapPos:GetXY()
			data.map = { x = mapX, y = mapY }
		end

		local zoneData = ledii.zones[data.zoneId]
		if (zoneData == nil) then return data end
		data.zoneEstimation = zoneData.estimatedArea
		if (data.zoneEstimation == nil) then return data end

		local est = data.zoneEstimation
		data.bounds = {}
		data.bounds.west = est.refWorldX + (est.refMapX * est.width)	--Negative X
		data.bounds.east = data.bounds.west - est.width					--Positive X
		data.bounds.north = est.refWorldY + (est.refMapY * est.height)	--Negative Y
		data.bounds.south = data.bounds.north - est.height				--Positive Y

		return data
	end

	function obj:GetMeasurePositionData()
		local data = {}

		if (worldData == nil) then return nil end
		data.zoneId = worldData.zoneId
		data.zoneName = worldData.zoneName
		data.world = { x = worldData.world.x, y = worldData.world.y }
		data.map = { x = worldData.map.x, y = worldData.map.y }

		if (measureData == nil) then return data end
		if (measureData.zoneId ~= data.zoneId) then return data end

		data.deltaWorld = {}
		data.deltaWorld.x = math.abs(data.world.x - measureData.world.x)
		data.deltaWorld.y = math.abs(data.world.y - measureData.world.y)
		data.deltaWorld.distance = math.sqrt((data.deltaWorld.x * data.deltaWorld.x) + (data.deltaWorld.y * data.deltaWorld.y))

		data.deltaMap = {}
		data.deltaMap.x = math.abs(data.map.x - measureData.map.x)
		data.deltaMap.y = math.abs(data.map.y - measureData.map.y)
		data.deltaMap.distance = math.sqrt((data.deltaMap.x * data.deltaMap.x) + (data.deltaMap.y * data.deltaMap.y))

		if (data.deltaWorld.x > 0 or data.deltaWorld.y > 0) then
			data.estimateWidth = math.floor(data.deltaWorld.x / data.deltaMap.x)
			data.estimateHeight = math.floor(data.deltaWorld.y / data.deltaMap.y)
		else
			data.estimateWidth = 0
			data.estimateHeight = 0
		end

		if (data.estimateWidth <= 0 or data.estimateHeight <= 0) then return data end

		local historyCount = 10
		if (data.deltaWorld.distance ~= measureDistance) then
			measureDistance = data.deltaWorld.distance
			table.insert(measureHistory, { w = data.estimateWidth, h = data.estimateHeight })
		end
		while (#measureHistory > historyCount) do
			table.remove(measureHistory, 1)
		end

		local minWidth = math.huge
		local maxWidth = -math.huge
		local minHeight = math.huge
		local maxHeight = -math.huge
		for i = 1, #measureHistory do
			local size = measureHistory[i]
			minWidth = math.min(minWidth, size.w)
			maxWidth = math.max(maxWidth, size.w)
			minHeight = math.min(minHeight, size.h)
			maxHeight = math.max(maxHeight, size.h)
		end

		local threshold = 5
		data.estimateValidWidth = math.abs(maxWidth - minWidth) <= threshold and #measureHistory >= historyCount
		data.estimateValidHeight = math.abs(maxHeight - minHeight) <= threshold and #measureHistory >= historyCount

		return data
	end

	function obj:IsTileUnlocked(tileKey, zoneId, continentId)
		if (unlockedTiles == nil) then return false end

		local continentTiles = unlockedTiles[continentId]
		if (continentTiles == nil) then return false end

		local zoneTiles = continentTiles[zoneId]
		if (zoneTiles == nil) then return false end

		local isUnlocked = zoneTiles[tileKey]
		if (isUnlocked == nil) then return false end

		return true
	end

	function obj:UnlockCurrentTile(unlockData)
		local tileKey = obj:GetTileKey(unlockData.tile.x, unlockData.tile.y)
		local zoneId = unlockData.zoneId
		local continentId = unlockData.continentId

		local isZoneBorderException = unlockData.isNewZone and unlockData.isUnlocked
		local canUnlock = availableTiles > 0 or isZoneBorderException or debug

		if (obj.lockMode ~= "Unlocked" and not isZoneBorderException) then return end
		if (unlockData.isTransport) then return end
		if (not canUnlock) then return end
		if (obj:IsTileUnlocked(tileKey, zoneId, continentId)) then return end

		unlockedTiles[continentId] = unlockedTiles[continentId] or {}
		unlockedTiles[continentId][zoneId] = unlockedTiles[continentId][zoneId] or {}
		unlockedTiles[continentId][zoneId][tileKey] = true

		if (isZoneBorderException) then
			--log:Info("Unlocked exception tile: " .. unlockData.tileId.x .. ", " .. unlockData.tileId.y)
		elseif (debug) then
			totalTiles = totalTiles + 1
			--log:Info("Unlocked debug tile: " .. unlockData.tileId.x .. ", " .. unlockData.tileId.y)
		else
			totalTiles = totalTiles + 1
			availableTiles = availableTiles - 1
			--log:Info("Unlocked consumed tile: " .. unlockData.tileId.x .. ", " .. unlockData.tileId.y)
		end

		obj:Save()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end

	function obj:GetTileKey(tileX, tileY)
		local x = utils:TruncateNumber(tileX) .. ""
		local y = utils:TruncateNumber(tileY) .. ""

		--Ensure minus on zero values
		if (tileX < 0) then
			x = "-" .. math.abs(x)
		end
		if (tileY < 0) then
			y = "-" .. math.abs(y)
		end

		return x .. "_" .. y
	end
	----- UTILITY END -----



	----- EVENTS BEGIN -----
	function obj:OnPlayerLogin()
		obj:Load()
		nextXP = obj:CalculateNextXP()

		ui:SetupTiling()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end

	function obj:OnZoneChanged(indoors)
		if (indoors == obj.isInsideZone) then return end

		obj.isInsideZone = indoors
		obj:Save()
		--log:Info("OnZoneChanged: " .. tostring(indoors))
	end

	function obj:OnExperienceChanged(source, xp, historicLevel)
		--log:Info("Experience changed: +" .. xp .. " from " .. source)
		local xpGain = xp * obj.xpRate
		currentXP = currentXP + xpGain

		while (currentXP >= nextXP) do
			--log:Info(currentXP .. " > " .. nextXP)
			availableTiles = availableTiles + 1
			--totalTiles = totalTiles + 1
			currentXP = currentXP - nextXP
			nextXP = obj:CalculateNextXP(historicLevel)
			--log:Info("+1 Tile Unlocked")
		end

		if (historicLevel == nil) then
			obj:Save()
			ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
		end
	end

	function obj:OnTick()
		if (UnitOnTaxi("player") and obj.lockMode ~= "Transport") then
			obj.lockMode = "Transport"
			ui:SetupUnlockButtonStatus()
		end

		if (IsIndoors() ~= obj.isInsideArea) then
			obj.isInsideArea = IsIndoors()
			obj:Save()
		end

		worldData = obj:GetWorldPositionData()
		mapData = obj:GetMapPositionData()

		local newMeasureData = obj:GetMeasurePositionData()

		if (measureTrigger) then
			log:Info("Set measure point")
			measureHistory = {}
			measureData = newMeasureData
			measureTrigger = false
		end

		--obj:UnlockCurrentTile()

		ui:OnPositionChanged(worldData, mapData, newMeasureData)
	end

	function obj:OnMeasureStart()
		if (IsShiftKeyDown()) then
			measureTrigger = true
		else
			log:Info(
				string.format("Reference point: %d, %d | %.2f, %.2f",
				worldData.world.x, worldData.world.y, worldData.map.x, worldData.map.y)
			)

			local refData = {}
			refData.refZoneId = worldData.zoneId
			refData.refZoneName = worldData.zoneName
			refData.refWorldX = worldData.world.x
			refData.refWorldY = worldData.world.y
			refData.refMapX = worldData.map.x
			refData.refMapY = worldData.map.y
			if (#measureHistory > 1) then
				local lastMeasure = measureHistory[#measureHistory]
				refData.refWidth = lastMeasure.w
				refData.refHeight = lastMeasure.h
			else
				refData.refWidth = 0
				refData.refHeight = 0
			end

			LediiData_TileZ.estimatedArea = refData
		end
	end

	function obj:SetStartTiles(value)
		availableTiles = availableTiles - obj.startCount
		obj.startCount = value
		availableTiles = availableTiles + obj.startCount

		obj:Save()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end

	function obj:SetManualTiles(delta)
		if (delta < 0) then
			if (math.abs(delta) <= availableTiles) then
				log:Info("Removed " .. count .. " tiles")
				availableTiles = availableTiles - delta
			else 
				log:Info("Not enough available tiles to remove")
			end
		elseif (delta > 0) then
			log:Info("Added " .. count .. " tiles")
			availableTiles = availableTiles + delta
		end
		
		obj:Save()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end
	----- EVENTS END -----

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_TILING = class
C_Timer.NewTicker(0.1, class.OnTick)