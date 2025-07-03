--print("Loaded <Tracking.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS
local ui = _G.LEDII_TILE_UI

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	local currentXP = 0
	local nextXP = 0
	local availableTiles = 0
	local totalTiles = 0
	local unlockedTiles = {}

	local tileSize = 25
	local worldData = nil
	local mapData = nil
	local measureData = nil
	local measureTrigger = false
	local measureHistory = {}
	local measureDistance = 0
	local debug = false
	----- VARIABLES END -----



	----- SETUP BEGIN -----
	function obj:Load()
		--Init data
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		--Try fetch data
		currentXP = LediiData_TileZ_Character.currentXP or 0
		availableTiles = LediiData_TileZ_Character.availableTiles or 0
		totalTiles = LediiData_TileZ_Character.totalTiles or 0
		unlockedTiles = LediiData_TileZ_Character.unlockedTiles or {}
	end

	function obj:Save()
		LediiData_TileZ = LediiData_TileZ or {}
		LediiData_TileZ_Character = LediiData_TileZ_Character or {}

		LediiData_TileZ_Character.currentXP = currentXP
		LediiData_TileZ_Character.availableTiles = availableTiles
		LediiData_TileZ_Character.totalTiles = totalTiles
		LediiData_TileZ_Character.unlockedTiles = unlockedTiles
	end

	function obj:Reset()
		LediiData_TileZ = nil
		LediiData_TileZ_Character = nil

		obj:Load()
		nextXP = obj:CalculateNextXP(1)

		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
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

		data.zoneId = C_Map.GetBestMapForUnit("player")
		data.zoneName = C_Map.GetMapInfo(data.zoneId).name
		data.continentId = C_Map.GetMapInfo(data.zoneId).parentMapID
		data.continentName = C_Map.GetMapInfo(data.continentId).name

		local worldY, worldX = UnitPosition("player")
		local mapX, mapY = C_Map.GetPlayerMapPosition(data.zoneId, "player"):GetXY()
		data.world = { x = worldX, y = worldY }
		data.map = { x = mapX, y = mapY }
		data.tile = { x = worldX / tileSize , y = worldY / tileSize }
		data.tileId = { x = utils:TruncateNumber(data.tile.x), y = utils:TruncateNumber(data.tile.y) }
		data.tileSize = tileSize

		if (worldData == nil) then return data end

		data.isNewZone = data.zoneId ~= worldData.zoneId
		if (data.isNewZone) then
			data.isUnlocked = worldData.isUnlocked
		else
			local tileKey = string.format("%d_%d", data.tileId.x, data.tileId.y)
			data.isUnlocked = obj:IsTileUnlocked(tileKey, data.zoneId, data.continentId)
		end

		return data
	end

	function obj:GetMapPositionData()
		local data = {}
		data.zoneId = WorldMapFrame:GetMapID()
		data.zoneName = C_Map.GetMapInfo(data.zoneId).name
		data.continentId = C_Map.GetMapInfo(data.zoneId).parentMapID

		if (data.continentId == 0) then return nil end
		data.continentName = C_Map.GetMapInfo(data.continentId).name

		local mapPos = C_Map.GetPlayerMapPosition(data.zoneId, "player")
		if (mapPos == nil) then return data end

		local mapX, mapY = mapPos:GetXY()
		data.map = { x = mapX, y = mapY }

		local zoneData = ledii.zones[data.zoneName]
		if (zoneData == nil) then return data end
		local zoneEstimation = zoneData.estimatedArea
		if (zoneEstimation == nil) then return data end

		data.bounds = {}
		data.bounds.west = zoneEstimation.refWorldX - (zoneEstimation.refMapX * zoneEstimation.width)	--Negative X
		data.bounds.east = data.bounds.west + zoneEstimation.width										--Positive X
		data.bounds.south = zoneEstimation.refWorldY - (zoneEstimation.refMapY * zoneEstimation.height)	--Negative Y
		data.bounds.north = data.bounds.south + zoneEstimation.height									--Positive Y

		return data
	end

	function obj:GetMeasurePositionData()
		local data = {}

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

	function obj:UnlockCurrentTile()
		if (worldData == nil) then return end

		local tileKey = string.format("%d_%d", worldData.tileId.x, worldData.tileId.y)
		local zoneId = worldData.zoneId
		local continentId = worldData.continentId

		local isZoneBorderException = worldData.isNewZone and worldData.isUnlocked
		local canUnlock = availableTiles > 0 or isZoneBorderException or debug

		if (not canUnlock) then return end
		if (obj:IsTileUnlocked(tileKey, zoneId, continentId)) then return end

		unlockedTiles[continentId] = unlockedTiles[continentId] or {}
		unlockedTiles[continentId][zoneId] = unlockedTiles[continentId][zoneId] or {}
		unlockedTiles[continentId][zoneId][tileKey] = true

		if (debug) then
			totalTiles = totalTiles + 1
			log:Info("Unlocked debug tile: " .. worldData.tileId.x .. ", " .. worldData.tileId.y)
		elseif (isZoneBorderException) then
			log:Info("Unlocked exception tile: " .. worldData.tileId.x .. ", " .. worldData.tileId.y)
		else
			availableTiles = availableTiles - 1
			log:Info("Unlocked consumed tile: " .. worldData.tileId.x .. ", " .. worldData.tileId.y)
		end

		obj:Save()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end
	----- UTILITY END -----



	----- EVENTS BEGIN -----
	function obj:OnPlayerLogin()
		obj:Load()
		nextXP = obj:CalculateNextXP()

		ui:SetupTiling()
		ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
	end

	function obj:OnExperienceChanged(source, xp, historicLevel)
		log:Info("Experience changed: +" .. xp .. " from " .. source)
		currentXP = currentXP + xp

		while (currentXP >= nextXP) do
			log:Info(currentXP .. " > " .. nextXP)
			availableTiles = availableTiles + 1
			totalTiles = totalTiles + 1
			currentXP = currentXP - nextXP
			nextXP = obj:CalculateNextXP(historicLevel)
			log:Info("+1 Tile Unlocked")
		end

		if (historicLevel == nil) then
			obj:Save()
			ui:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
		end
	end

	function obj:OnTick()
		worldData = obj:GetWorldPositionData()
		mapData = obj:GetMapPositionData()

		local newMeasureData = obj:GetMeasurePositionData()

		if (measureTrigger) then
			log:Info("Set measure point")
			measureHistory = {}
			measureData = newMeasureData
			measureTrigger = false
		end

		obj:UnlockCurrentTile()

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
			refData.refZone = worldData.zoneName
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
	----- EVENTS END -----

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_TILING = class
C_Timer.NewTicker(0.1, class.OnTick)