--print("Loaded <Tracking.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	local unlockedTiles = {}
	local tileLength = 50.0
	local tileCount = -1
	local mapTileCount = -1
	local tileWidthRatio = 0.6684
	local zoneBlacklistIds = { 1414, 1415, 947 }
	local yardsToMeter = 0.9144
	local mapGridTexture = "Interface/Addons/TileZ/TileZ_GridTexture2"
	local mapTileTexture = "Interface/Addons/TileZ/TileZ_TileTexture4"
	local minimapTileTexture = "Interface/Addons/TileZ/TileZ_GridTexture"

	local cachedVisible = false
	local cachedHeight = 0
	local cachedMapId = 0
	local cachedTile = nil

	local coordLabel = nil
	local measureLabel = nil
	local mapGridFrame = nil
	local mapTileFrames = {}
	local minimapTileFrames = {}
	local minimapTileLayerFrame = nil
	local mapMarkerFrame = nil
	local screenBlockerFrame = nil
	local experienceFrame = nil
	
	local lastMeasure = nil
	local storeMeasure = false
	local totalTiles = 0
	local availableTiles = 0
	local currentXp = 0
	local nextXp = 0
	local forceUpdateTile = false
	local autoUnlock = false
	----- VARIABLES END -----



	----- SETUP BEGIN -----
	function obj:SetupFrames()
		coordLabel = obj:CreateMinimapLabel(-10)
		measureLabel = obj:CreateMinimapLabel(-30)
		mapGridFrame = obj:CreatemapGridFrame()
		mapMarkerFrame = obj:CreatemapMarkerFrame()
		screenBlockerFrame = obj:CreatescreenBlockerFrame()
		experienceFrame = obj:CreateExperienceFrame()
		minimapTileLayerFrame = obj:CreateMinimapFrameLayer()
	end

	function obj:CreateMinimapLabel(y)
		local type = "Button"
		local name = "Tilez_Coordinates"
		local parent = UIParent
		local template = "UIPanelButtonTemplate"

		local frame = CreateFrame(type, name, parent, template)
		frame:SetWidth(160)
		frame:SetHeight(24)
		frame:SetFrameStrata("TOOLTIP")
		frame:SetPoint("TOP", parent, "TOP", 0, y)
		frame:SetText("Loading...")
		frame:Disable()

		--frame.texture = frame:CreateTexture()
		--frame.texture:SetAllPoints(frame)

		frame:Show()
		
		return frame
	end

	function obj:CreatemapGridFrame()
		local type = "Frame"
		local name = "Tilez_Grid"
		local parent = WorldMapFrame:GetCanvasContainer()
		local template = "BackdropTemplate"

		local frame = CreateFrame(type, name, parent, template)
		frame:SetFrameStrata("TOOLTIP")

		return frame
	end

	function obj:CreatemapMarkerFrame()
		local type = "Frame"
		local name = "TileZ PlayerMarker"
		local parent = WorldMapFrame.ScrollContainer

		local frame = CreateFrame(type, name, parent)
		frame:SetFrameStrata("TOOLTIP")
		frame:SetSize(2, 2)

		local tex = frame:CreateTexture()
		tex:SetAllPoints()
		tex:SetColorTexture(1, 0, 0, 1)

		return frame
	end

	function obj:CreateTileFrame(parent, texture, strata)
		local type = "Frame"
		local name = "Tilez_Section"

		local frame = CreateFrame(type, name, parent)
		
		frame:SetFrameStrata(strata)

		-- Create texture to display the tile
		local tex = frame:CreateTexture(nil, "ARTWORK")
		tex:SetTexture(texture)
		tex:SetAllPoints()

		frame.texture = tex

		return frame
	end

	function obj:CreatescreenBlockerFrame()
		local type = "Frame"
		local name = "TileZ ViewBlocker"
		local parent = UIParent

		local frame = CreateFrame(type, name, parent)
		frame:SetSize(parent:GetSize())

		local tex = frame:CreateTexture()
		tex:SetAllPoints()
		tex:SetColorTexture(0, 0, 0, 0.9)

		frame:SetFrameStrata("BACKGROUND")
		frame:SetAllPoints(parent)
		--frame:SetFrameLevel(100)
		frame:Hide()

		type = "Button"
		name = "TileZ UnlockButton"
		local template = "UIPanelButtonTemplate"
		local unlockButton = CreateFrame(type, name, frame, template)
		unlockButton:SetWidth(160)
		unlockButton:SetHeight(24)
		unlockButton:SetFrameStrata("TOOLTIP")
		unlockButton:SetPoint("TOP", frame, "TOP", 0, -50)
		unlockButton:SetText("Unlock Tile")
		unlockButton:Show()
		unlockButton:SetScript("OnClick", function()
			local coords = {}
			coords.x = cachedTile.x
			coords.y = cachedTile.y
			local mapId = cachedTile.zoneId
			obj:UnlockTile(mapId, coords)
		end)

		return frame
	end

	function obj:CreateExperienceFrame()
		local type = "Frame"
		local name = "TileZ Experience"
		local parent = UIParent

		local frame = CreateFrame(type, name, parent)
		frame:SetSize(200, 20)

		local tex = frame:CreateTexture()
		tex:SetAllPoints()
		tex:SetColorTexture(1, 0, 0, 1)

		return frame
	end

	function obj:CreateMinimapFrameLayer()
		local type = "Frame"
		local name = "Tilez_SectionLayer"
		local parent = Minimap

		local frame = CreateFrame(type, name, parent)
		frame:SetFrameStrata("LOW")
		frame:SetClipsChildren(true)
		frame:SetSize(parent:GetWidth(), parent:GetHeight())
		frame:SetPoint("CENTER", parent, "CENTER")

		-- Create the texture that will be masked
		local tex = frame:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\Buttons\\WHITE8x8") -- or your tile texture
		tex:SetColorTexture(0, 0, 0, 0) -- Optional color for testing
		tex:SetAllPoints(parent)

		-- Apply the mask to the texture (not the frame)
		local maskTex = frame:CreateMaskTexture()
		maskTex:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		maskTex:SetAllPoints(parent)
		tex:AddMaskTexture(maskTex)

		frame.texture = tex -- Save reference if you want to change later
		frame:Show()

		return frame
	end
	----- SETUP END -----



	----- UTILITY BEGIN -----
	function obj:GetZoneScale(mapId)
		local zone = GetZoneText()
		
		if (zone == "Mulgore") then
			return 1.0
		end
	end

	function obj:GetCurrentTile()
		local zoneId = C_Map.GetBestMapForUnit("player")
		local coords = C_Map.GetPlayerMapPosition(zoneId, "player")
		
		if (tileCount ~= nil) then
			local output = {}
			output.zoneId = zoneId
			output.rawX = coords.x
			output.rawY = coords.y
			output.scaledX = coords.x * (tileCount / tileWidthRatio)
			output.scaledY = coords.y * tileCount
			output.x = math.floor(output.scaledX)
			output.y = math.floor(output.scaledY)

			return output
		else
			local output = {}
			output.zoneId = zoneId
			output.rawX = coords.x
			output.rawY = coords.y
			output.scaledX = coords.x
			output.scaledY = coords.y
			output.x = -1
			output.y = -1

			return output
		end
	end

	function obj:IndexOfValue(inTable, value)
		for i, v in ipairs(inTable) do
			if v == value then
				return i
			end
		end
		return nil
	end

	function obj:IsTileUnlocked(mapId, coords)
		local zoneData = unlockedTiles[mapId]
		if (zoneData == nil) then return false end

		for i = 1, #zoneData.coords do
			local unlockedCoords = zoneData.coords[i]
			if (unlockedCoords.x == coords.x and unlockedCoords.y == coords.y) then
				return true
			end
		end
		
		return false
	end

	function obj:UnlockTile(mapId, coords)
		local mapName = C_Map.GetMapInfo(mapId).name
		log:Info("Try unlock tile " .. coords.x .. ", " .. coords.y .. " in " .. mapName)	

		if (obj:IsTileUnlocked(mapId, coords)) then return end
		if (utils:TableContains(zoneBlacklistIds, mapId)) then return end
		
		--if (availableTiles < 1) then return end
		availableTiles = availableTiles - 1

		local zoneData = unlockedTiles[mapId]
		if (zoneData == nil) then
			zoneData = {}
			zoneData.name = mapName
			zoneData.coords = {}
		end

		table.insert(zoneData.coords, coords)
		unlockedTiles[mapId] = zoneData
		forceUpdateTile = true
		obj:Save()

		--log:Info("Unlocked tile at " .. coords.x .. ", " .. coords.y .. " (" .. zoneData.name .. ")")
	end

	function obj:CalculateTileCount(mapId)
		local mapName = C_Map.GetMapInfo(mapId).name

		local mapData = ledii.zones[mapName]
		if (mapData == nil) then return nil end

		local mapHeight = mapData.estimatedArea.height
		return mapHeight / tileLength
	end

	function obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked)
		if (isPlayerTile and isUnlocked) then
			tileFrame.texture:SetVertexColor(1, 1, 1, 0.75)
		elseif (isPlayerTile) then
			tileFrame.texture:SetVertexColor(1, 0, 0, 0.75)
		elseif (isUnlocked) then
			tileFrame.texture:SetVertexColor(0, 1, 0, 0.5)
		end
	end
	----- UTILITY END -----



	----- UPDATES BEGIN ---
	function obj:Tick()
		if (coordLabel == nil) then return end

		--log:Info("PlayerTileCount: " .. tileCount)
		--log:Info("MapTileCount: " .. mapTileCount)

		--Initialize current tile
		local tile = obj:GetCurrentTile()
		if (cachedTile == nil) then
			cachedTile = tile
			tileCount = obj:CalculateTileCount(tile.zoneId)
		end

		--Update coord label
		local strX = string.format("%.2f", tile.scaledX)
		local strY = string.format("%.2f", tile.scaledY)
		local strFacing = string.format("%.1f", math.deg(GetPlayerFacing()))
		--coordLabel:SetText(strX .. ", " .. strY .. "   (" .. strFacing .. " *)")

		local locX, locY, locZ = UnitPosition("player")
		local locStr = string.format("%.1f, %.1f", locX, locY)
		coordLabel:SetText(locStr)

		--Check for changes to map
		local visible = WorldMapFrame:IsVisible()
		local height = WorldMapFrame:GetHeight()
		local mapId = WorldMapFrame:GetMapID()

		if (cachedVisible ~= visible or cachedHeight ~= height or cachedMapId ~= mapId) then
			cachedVisible = visible
			cachedHeight = height
			cachedMapId = mapId
			
			obj:OnMapChanged()
		end

		--Check for changes to tile
		if (cachedTile.x ~= tile.x or cachedTile.y ~= tile.y or forceUpdateTile) then
			cachedTile = tile
			forceUpdateTile = false

			obj:OnTileChanged()
			obj:OnMapChanged()
		end

		--Update current position
		obj:UpdatemapMarkerFrame(tile.rawX, tile.rawY)
		obj:UpdateMinimapFrames(tile)
		obj:UpdateMeasureLabel()
	end

	function obj:OnMapChanged()
		obj:ClearGrid()

		if (cachedVisible) then
			obj:UpdateGrid()
		end
	end

	function obj:OnTileChanged()
		local coords = {}
		coords.x = cachedTile.x
		coords.y = cachedTile.y

		local zoneId = C_Map.GetBestMapForUnit("player")
		tileCount = obj:CalculateTileCount(zoneId)

		if (autoUnlock) then
			obj:UnlockTile(zoneId, coords)
		end

		if (obj:IsTileUnlocked(zoneId, coords)) then
			--log:Info("Entered unlocked tile at " .. coords.x .. ", " .. coords.y)
			screenBlockerFrame:Hide()
		else
			--log:Info("Entered locked tile at " .. coords.x .. ", " .. coords.y)
			screenBlockerFrame:Show()
		end
	end

	function obj:ClearGrid()
		mapGridFrame:Hide()

		for i = 1, #mapTileFrames do
			mapTileFrames[i]:Hide()
		end
	end

	function obj:UpdateGrid()
		local zoneName = C_Map.GetMapInfo(cachedMapId).name
		--log:Info("Setup zone map: " .. zoneName .. " (" .. cachedMapId .. ")")
		
		if (utils:TableContains(zoneBlacklistIds, cachedMapId)) then return end

		mapTileCount = obj:CalculateTileCount(cachedMapId)
		if (mapTileCount == nil) then return end
		log:Info("Update grid count: " .. mapTileCount)

		obj:UpdateMapGridFrame()

		--Add unlocked tiles
		local zoneData = unlockedTiles[cachedMapId]
		local lastIndex = 0
		if (zoneData ~= nil) then
			for i = 1, #zoneData.coords do
				local coord = zoneData.coords[i]
				if (coord.x ~= cachedTile.x or coord.y ~= cachedTile.y) then
					lastIndex = lastIndex + 1
					obj:UpdateTileFrame(lastIndex, coord.x, coord.y)
				end
			end
		end

		--Add players current tile
		local zoneId = C_Map.GetBestMapForUnit("player")
		if (zoneId == cachedMapId) then
			local current = obj:GetCurrentTile()
			obj:UpdateTileFrame(lastIndex + 1, current.x, current.y)
		end
	end

	function obj:UpdateMapGridFrame()
		local parent = WorldMapFrame:GetCanvasContainer()
		local length = parent:GetHeight()
		local interval = length / mapTileCount

		--log:Info("MapSize: " .. parent:GetWidth() .. ", " .. parent:GetHeight() .. " = " .. parent:GetHeight()/parent:GetWidth())

		mapGridFrame:SetSize(parent:GetWidth(), parent:GetHeight())
		mapGridFrame:SetBackdrop({
			bgFile = mapGridTexture,
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
			tile = true, tileSize = interval, edgeSize = 4, 
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		})

		mapGridFrame:SetBackdropColor(0, 0, 0, 0.5)
		mapGridFrame:SetBackdropBorderColor(0, 0, 0, 0)

		--local posX = ((parent:GetWidth() - parent:GetHeight()) * 0.5)
		local posX = 0
		local posY = 0
		mapGridFrame:SetPoint("TOPLEFT", parent, posX, -posY)

		mapGridFrame:Show()
	end

	function obj:UpdateTileFrame(index, x, y)
		local tileParent = WorldMapFrame.ScrollContainer
		local tileFrame = mapTileFrames[index]
		if (tileFrame == nil) then
			tileFrame = obj:CreateTileFrame(tileParent, mapTileTexture, "MEDIUM")
			table.insert(mapTileFrames, tileFrame)
		end

		local length = tileParent:GetHeight() / mapTileCount
		tileFrame:SetSize(length, length)

		if (x == cachedTile.x and y == cachedTile.y) then
			tileFrame.texture:SetVertexColor(1, 1, 1, 0.75)
		else
			tileFrame.texture:SetVertexColor(0, 1, 0, 0.5)
		end

		--local posX = (length * x) + ((parent:GetWidth() - parent:GetHeight()) * 0.5)
		local posX = (length * x)
		local posY = (length * y)
		tileFrame:SetPoint("TOPLEFT", tileParent, posX, -posY)
		tileFrame:Show()
	end

	function obj:UpdatemapMarkerFrame(x, y)
		local mapCanvas = WorldMapFrame.ScrollContainer

		local posX = x * mapCanvas:GetWidth()
		local posY = -y * mapCanvas:GetHeight()
		mapMarkerFrame:SetPoint("CENTER", mapCanvas, "TOPLEFT", posX, posY)
		
		local zoneId = C_Map.GetBestMapForUnit("player")
		if (zoneId == cachedMapId) then
			mapMarkerFrame:Show()
		else
			mapMarkerFrame:Hide()
		end
	end

	function obj:UpdateMinimapFrames(tile)
		for i = 1, #minimapTileFrames do
			minimapTileFrames[i]:Hide()
		end

		local lastIndex = 0
		local extent = 1
		local zoneId = C_Map.GetBestMapForUnit("player")

		for offsetY = -extent, extent do
			for offsetX = -extent, extent do
				local coords = {}
				coords.x = tile.x + offsetX
				coords.y = tile.y + offsetY

				local isPlayerTile = (coords.x == cachedTile.x and coords.y == cachedTile.y)
				local isUnlocked = obj:IsTileUnlocked(zoneId, coords)

				if (isPlayerTile or isUnlocked) then
					lastIndex = lastIndex + 1
					obj:UpdateMinimapTileFrame(tile, lastIndex, coords, isPlayerTile, isUnlocked)
				end
			end
		end
	end

	function obj:UpdateMinimapTileFrame(tile, index, coords, isPlayerTile, isUnlocked)
		--log:Info("UpdateMinimapTileFrame at: " .. x .. ", " .. y)
		local tileParent = minimapTileLayerFrame
		local tileFrame = minimapTileFrames[index]
		if (tileFrame == nil) then
			tileFrame = obj:CreateTileFrame(tileParent, minimapTileTexture, "TOOLTIP")
			tileFrame.texture:AddMaskTexture(tileParent.texture:GetMaskTexture(1))
			table.insert(minimapTileFrames, tileFrame)
		end

		local zoomOffsets = { 0.0, 0.175, 0.4, 0.75, 1.3, 2.5 }
		local zoomIndex = Minimap:GetZoom() + 1
		local zoomMultiplier = 1.0 + zoomOffsets[zoomIndex]
		local length = 40 * zoomMultiplier
		tileFrame:SetSize(length, length)

		obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked)

		local fractionX = tile.scaledX - coords.x - 0.5
		local fractionY = tile.scaledY - coords.y - 0.5
		local posX = fractionX * -length
		local posY = fractionY * length
		--log:Info(string.format("%.2f, %.2f", fractionX, fractionY))

		tileFrame:SetPoint("CENTER", tileParent, "CENTER", posX, posY)
		tileFrame:Show()
	end

	function obj:UpdateMeasureLabel()
		local text = "Invalid measurement"
		local measure = {}
		measure.zone = GetZoneText()
		measure.zoneId = C_Map.GetBestMapForUnit("player")
		measure.coords = C_Map.GetPlayerMapPosition(measure.zoneId, "player")

		local locX, locY = UnitPosition("player")
		measure.position = {}
		measure.position.x = locY --y axis is positive west
		measure.position.y = locX --x axis is positive north

		if (lastMeasure ~= nil) then
			if (measure.zoneId == lastMeasure.zoneId) then
				--Calculate delta values
				local delta = {}

				delta.yards = {}
				delta.yards.x = math.abs(measure.position.x - lastMeasure.position.x)
				delta.yards.y = math.abs(measure.position.y - lastMeasure.position.y)
				delta.yards.distance = math.sqrt((delta.yards.x * delta.yards.x) + (delta.yards.y * delta.yards.y))

				delta.meters = {}
				delta.meters.x = delta.yards.x * yardsToMeter
				delta.meters.y = delta.yards.y * yardsToMeter
				delta.meters.distance = math.sqrt((delta.meters.x * delta.meters.x) + (delta.meters.y * delta.meters.y))

				delta.coords = {}
				delta.coords.x = math.abs(measure.coords.x - lastMeasure.coords.x)
				delta.coords.y = math.abs(measure.coords.y - lastMeasure.coords.y)
				delta.coords.distance = math.sqrt((delta.coords.x * delta.coords.x) + (delta.coords.y * delta.coords.y))

				--Calculate relative scale
				local scale = {}

				scale.yards = {}
				scale.yards.x = math.floor(delta.yards.x * (1.0 / delta.coords.x))
				scale.yards.y = math.floor(delta.yards.y * (1.0 / delta.coords.y))
				scale.yards.distance = math.sqrt((scale.yards.x * scale.yards.x) + (scale.yards.y * scale.yards.y))

				scale.meters = {}
				scale.meters.x = scale.yards.x * yardsToMeter
				scale.meters.y = scale.yards.y * yardsToMeter
				scale.meters.distance = math.sqrt((scale.meters.x * scale.meters.x) + (scale.meters.y * scale.meters.y))

				--Log data
				if (storeMeasure) then
					log:Info("----- Measurement Delta -----")
					log:Info(string.format("Position (yards): %.2f, %.2f", delta.yards.x, delta.yards.y))
					log:Info(string.format("Position (meters): %.2f, %.2f", delta.meters.x, delta.meters.y))
					log:Info(string.format("Map coordinates: %.6f, %.6f", delta.coords.x, delta.coords.y))
					log:Info("----- Measurement Estimate -----")
					log:Info(string.format("Zone size (yards): %.0f, %.0f", scale.yards.x, scale.yards.y))
					log:Info(string.format("Zone size (meters): %.0f, %.0f", scale.meters.x, scale.meters.y))
				end

				text = string.format("Y: %.2f, %.2f (%.2f)", delta.yards.x, delta.yards.y, delta.yards.distance)
				--text = string.format("M: %.2f, %.2f (%.2f)", delta.meters.x, delta.meters.y, delta.meters.distance)
			end
		end

		measureLabel:SetText(text)

		if (storeMeasure) then
			storeMeasure = false
			lastMeasure = measure
			log:Info("Captured data for " .. measure.zone .. "...")
		end
	end
	----- UPDATES END -----



	----- INTERFACE BEGIN -----
	function obj:Load()
		--log:Info("Loading")

		--Init data
		if (LediiData_TileZ == nil) then
			LediiData_TileZ = {}
		end
		if (LediiData_TileZ_Character == nil) then
			LediiData_TileZ_Character = {}
		end

		--Try fetch data
		if (LediiData_TileZ_Character["unlockedTiles"] ~= nil) then
			unlockedTiles = LediiData_TileZ_Character["unlockedTiles"]
		end
	end

	function obj:Save()
		--log:Info("Saving")

		LediiData_TileZ_Character["unlockedTiles"] = unlockedTiles
	end

	function obj:Measure()
		storeMeasure = true
	end

	function obj:OnExperienceChanged(source, xp)
		log:Info("Experience changed: +" .. xp .. " from " .. source)
	end

	function obj:Reset()
		LediiData_TileZ = nil
		LediiData_TileZ_Character = nil
		obj:Load()
	end
	----- INTERFACE END -----

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_TILING = class
C_Timer.NewTicker(0.1, class.Tick)