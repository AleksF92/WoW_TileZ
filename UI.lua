--print("Loaded <UI.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	local debug = false

	local tilingStatus = {}
	local tilingMinimap = {}
	local tilingMap = {}
	local tilingSettings = {}
	local tilingBlocker = {}
	local tilingTaxi = {}
	local tilingIntro = {}

	local whiteTexture = "Interface\\Buttons\\WHITE8x8"
	local minimapMaskTexture = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
	local minimapTileTextureMip = {
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_1px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_2px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_4px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_6px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_8px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_10px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_12px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_14px",
		"Interface\\Addons\\TileZ\\Textures\\Tile_Outline_16px"
	}
	local settingsTexture = "Interface\\Addons\\TileZ\\Textures\\Icon_Cogwheel"
	local lockedModeTexture = "Interface\\Addons\\TileZ\\Textures\\Icon_Padlock_Closed"
	local unlockedModeTexture = "Interface\\Addons\\TileZ\\Textures\\Icon_Padlock_Open"
	local transportModeTexture = "Interface\\Addons\\TileZ\\Textures\\Icon_Eye"
	local buttonFrameTexture = "Interface\\Buttons\\UI-Panel-Button-Down"
	local screenCoverTexture = "Interface\\Addons\\TileZ\\Textures\\Screen_Cover"

	local refreshMap = false
	local cachedMinimapSize = 0
	local PRESS_DOWN_COUNT = 0
	local PRESS_UP_COUNT = -1
	local showIntro = false
	local GRID_OFFSET_N = -100000
	local GRID_OFFSET_W = 100000
	----- VARIABLES END -----



	----- PUBLIC BEGIN -----
	function obj:SetupTiling()
		obj:SetupTilingStatus()
		obj:SetupTilingMinimap()
		obj:SetupTilingMap()
		obj:SetupTilingSettings()
		obj:SetupTilingBlocker()
		obj:SetupIntro()
	end

	function obj:SetupTilingStatus()
		tilingStatus.container = obj:CreateBackdropFrame("Tilez_StatusContainer", UIParent)
		tilingStatus.container:SetPoint("TOP", UIParent, "TOP", 0, -10)
		tilingStatus.container:SetSize(300, 50)

		tilingStatus.availableLabel = obj:CreateLabelFrame("Tilez_AvailableLabel", tilingStatus.container)
		tilingStatus.availableLabel:SetPoint("RIGHT", tilingStatus.container, "RIGHT", -20, 8)
		tilingStatus.availableLabel:SetText("????")

		tilingStatus.totalLabel = obj:CreateLabelFrame("Tilez_TotalLabel", tilingStatus.container)
		tilingStatus.totalLabel:SetPoint("RIGHT", tilingStatus.container, "RIGHT", -20, -8)
		tilingStatus.totalLabel:SetText("????")

		tilingStatus.positionLabel = obj:CreateLabelFrame("Tilez_TotalLabel", tilingStatus.container)
		tilingStatus.positionLabel:SetPoint("LEFT", tilingStatus.container, "LEFT", 20, -8)
		tilingStatus.positionLabel:SetText("?.??, ?.??")
		tilingStatus.positionLabel:SetWidth(220)

		tilingStatus.measureLabel = obj:CreateLabelFrame("Tilez_TotalLabel", tilingStatus.container)
		tilingStatus.measureLabel:SetPoint("LEFT", tilingStatus.container, "LEFT", 20, -8)
		tilingStatus.measureLabel:SetText("?.??, ?.??")
		tilingStatus.measureLabel:SetWidth(220)
		tilingStatus.measureLabel:Hide()

		tilingStatus.xpBar = obj:CreateExperienceFrame("Tilez_XPBar", tilingStatus.container, 220)
		tilingStatus.xpBar:SetPoint("LEFT", tilingStatus.container, "LEFT", 20, 8)
		tilingStatus.xpBar:SetStatusBarColor(1, 0, 0)

		if (debug) then
			tilingStatus.positionLabel:SetJustifyH("LEFT")
			tilingStatus.measureLabel:SetJustifyH("RIGHT")
			tilingStatus.measureLabel:Show()
		end

		tilingStatus.settingsButton = obj:CreateButtonFrame("TileZ_SettingsButton", tilingStatus.container, settingsTexture, 10)
		tilingStatus.settingsButton:SetPoint("RIGHT", tilingStatus.container, "LEFT", 0, 0)
		tilingStatus.settingsButton:SetSize(40, 40)
		tilingStatus.settingsButton.onMouseHeld = obj.OnSettingsButtonClicked

		tilingStatus.unlockButton = obj:CreateButtonFrame("TileZ_UnlockButton", tilingStatus.container, lockedModeTexture, 10)
		tilingStatus.unlockButton:SetPoint("LEFT", tilingStatus.container, "RIGHT", 0, 0)
		tilingStatus.unlockButton:SetSize(40, 40)
		tilingStatus.unlockButton.frame:SetBackdropColor(1, 0, 0, 0.5)
		tilingStatus.unlockButton.onMouseHeld = obj.OnUnlockButtonClicked
	end

	function obj:SetupTilingMinimap()
		local parent = Minimap

		tilingMinimap.container = obj:CreateTextureFrame("Tilez_MinimapContainer", parent, whiteTexture)
		tilingMinimap.container:SetFrameStrata("LOW")
		tilingMinimap.container:SetClipsChildren(true)
		tilingMinimap.container:SetSize(parent:GetWidth(), parent:GetHeight())
		tilingMinimap.container:SetPoint("CENTER", parent, "CENTER")
		tilingMinimap.container.texture:SetColorTexture(0, 0, 0, 0)

		tilingMinimap.container.mask = tilingMinimap.container:CreateMaskTexture()
		tilingMinimap.container.mask:SetTexture(minimapMaskTexture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		tilingMinimap.container.mask:SetAllPoints(tilingMinimap.container)
		tilingMinimap.container.texture:AddMaskTexture(tilingMinimap.container.mask)

		tilingMinimap.player = obj:CreateTextureFrame("TileZ_PlayerDot", tilingMinimap.container, whiteTexture)
		tilingMinimap.player:SetSize(2, 2)
		tilingMinimap.player.texture:SetVertexColor(0, 0, 0, 1)
		tilingMinimap.player:SetPoint("CENTER", 0, 0)
		tilingMinimap.player:SetFrameStrata("DIALOG")

		tilingMinimap.tileFrames = {}
	end

	function obj:SetupTilingMap()
		tilingMap.lastZoneId = 0
		tilingMap.lastHeight = 0
		tilingMap.lastVisible = false
		tilingMap.lastTileKey = ""
		tilingMap.lastUnlocked = false

		tilingMap.gridMask = obj:CreateContainerFrame("TileZ_MapGridMask", WorldMapFrame.ScrollContainer)
		tilingMap.gridMask:SetAllPoints(WorldMapFrame.ScrollContainer)
		tilingMap.gridMask:SetClipsChildren(true)
		tilingMap.gridMask:SetFrameStrata("HIGH")

		tilingMap.grid = obj:CreateBackdropFrame("TileZ_MapGrid", tilingMap.gridMask)

		tilingMap.player = obj:CreateTextureFrame("TileZ_PlayerDot", WorldMapFrame.ScrollContainer, whiteTexture)
		tilingMap.player:SetSize(2, 2)
		tilingMap.player.texture:SetVertexColor(0, 0, 0, 1)
		tilingMap.player:SetFrameStrata("DIALOG")
		tilingMap.player:Hide()

		tilingMap.tileFrames = {}
	end

	function obj:SetupTilingSettings()
		local tiling = _G.LEDII_TILE_TILING

		tilingSettings.container = obj:CreateBackdropFrame("Tilez_StatusContainer", tilingStatus.container)
		tilingSettings.container:SetPoint("TOP", tilingStatus.container, "BOTTOM", 0, 0)
		tilingSettings.container:SetSize(400, 160)
		tilingSettings.container:Hide()

		tilingSettings.tileSizeSelector = obj:CreateIncrementFrame(
			"Tilez_TileSizeSelector", tilingSettings.container,
			"Tile Size", "%d yards", 5, 1000, 5,
			tiling.tileSize, obj.OnTileSizeSelected
		)
		tilingSettings.tileSizeSelector:SetPoint("TOP", tilingSettings.container, "TOP", 0, -10)

		tilingSettings.startTilesSelector = obj:CreateIncrementFrame(
			"Tilez_StartTilesSelector", tilingSettings.container,
			"Start Tiles", "%dx", 1, 10, 1,
			tiling.startCount, obj.OnStartTilesSelected
		)
		tilingSettings.startTilesSelector:SetPoint("TOP", tilingSettings.tileSizeSelector, "BOTTOM", 0, 0)

		tilingSettings.xpRateSelector = obj:CreateIncrementFrame(
			"Tilez_XPRateSelector", tilingSettings.container,
			"XP Rate", "%.1fx", 0, 10, 0.1,
			tiling.xpRate, obj.OnXPRateSelected
		)
		tilingSettings.xpRateSelector:SetPoint("TOP", tilingSettings.startTilesSelector, "BOTTOM", 0, 0)

		tilingSettings.progressLabel = obj:CreateLabelFrame("TileZ_HintLabel", tilingSettings.container)
		tilingSettings.progressLabel:SetPoint("BOTTOMLEFT", tilingSettings.container, "BOTTOMLEFT", 14, 14)
		tilingSettings.progressLabel:SetText(
			const:Color("UNCOMMON") .. "Progress status" .. const:Color("TEXT_HIGHLIGHT")
			.. "\nAvailable: ???? Tiles"
			.. "\nnUnlocked: ???? Tiles / ?? Instances"
		)
		tilingSettings.progressLabel:SetTextColor(1, 1, 1, 1)
		tilingSettings.progressLabel:SetJustifyH("LEFT")

		local version = GetAddOnMetadata("TileZ", "Version")
		tilingSettings.versionLabel = obj:CreateLabelFrame("TileZ_HonorLabel", tilingSettings.container)
		tilingSettings.versionLabel:SetPoint("BOTTOMRIGHT", tilingSettings.container, "BOTTOMRIGHT", -14, 14)
		tilingSettings.versionLabel:SetText(string.format("v%s Beta", version))
		tilingSettings.versionLabel:SetTextColor(0.6, 0.6, 0.6, 1)
		tilingSettings.versionLabel:SetJustifyH("RIGHT")
	end

	function obj:SetupTilingBlocker()
		tilingBlocker.isShowingScreen = true

		tilingBlocker.container = obj:CreateContainerFrame("TileZ_BlockerContainer", UIParent)
		tilingBlocker.container:SetAllPoints(UIParent)
		tilingBlocker.container:SetFrameStrata("BACKGROUND")
		UIFrameFadeOut(tilingBlocker.container, 0, 1, 0)

		tilingBlocker.cover = obj:CreateTextureFrame("TileZ_BlockerCover", tilingBlocker.container, screenCoverTexture)
		tilingBlocker.cover:SetAllPoints(tilingBlocker.container)
		tilingBlocker.cover.texture:SetVertexColor(0, 0, 0, 1)
		tilingBlocker.cover:SetFrameLevel(tilingBlocker.container:GetFrameLevel() - 1)

		tilingBlocker.label = obj:CreateLabelFrame("TileZ_BlockerLabel", tilingBlocker.container)
		tilingBlocker.label:SetPoint("CENTER", tilingBlocker.container, "CENTER", 0, 150)
		local fontFile, fontSize, fontFlags = tilingBlocker.label:GetFont()
		tilingBlocker.label:SetFont(fontFile, 24, fontFlags)
	end

	function obj:SetupIntro()
		tilingIntro.container = obj:CreateBackdropFrame("Tilez_IntroContainer", tilingStatus.container)
		tilingIntro.container:SetPoint("TOP", tilingStatus.container, "BOTTOM", 0, 0)
		tilingIntro.container:SetSize(400, 276)
		tilingIntro.container:Hide()

		tilingIntro.headerLabel = obj:CreateLabelFrame("TileZ_IntroHeaderLabel", tilingIntro.container)
		tilingIntro.headerLabel:SetPoint("TOPLEFT", tilingSettings.container, "TOPLEFT", 14, -14)
		tilingIntro.headerLabel:SetText("Introduction to the Tile Challenge")
		tilingIntro.headerLabel:SetTextColor(1, 1, 1, 1)
		tilingIntro.headerLabel:SetJustifyH("LEFT")

		tilingIntro.authorLabel = obj:CreateLabelFrame("TileZ_AuthorLabel", tilingIntro.container)
		tilingIntro.authorLabel:SetPoint("TOPRIGHT", tilingIntro.container, "TOPRIGHT", -14, -14)
		tilingIntro.authorLabel:SetText("TileZ by Ledii")
		tilingIntro.authorLabel:SetTextColor(0.6, 0.6, 0.6, 1)

		tilingIntro.descriptionLabel = obj:CreateLabelFrame("TileZ_IntroDescriptionLabel", tilingIntro.container)
		tilingIntro.descriptionLabel:SetPoint("TOP", tilingIntro.headerLabel, "TOP", 0, -28)
		tilingIntro.descriptionLabel:SetPoint("LEFT", tilingIntro.container, "LEFT", 14, 0)
		tilingIntro.descriptionLabel:SetPoint("RIGHT", tilingIntro.container, "RIGHT", -14, 0)
		tilingIntro.descriptionLabel:SetText(
			const:Color("UNCOMMON") .. "Ruleset" .. const:Color("TEXT_HIGHLIGHT")
			.. "\n\n"
			.. "The world is divided into tiles and the player may only traverse within the boundaries of their unlocked tiles."
			.. " To unlock new tiles the player must earn the rights to do so, either through gaining experience or completing personal insentives."
			.. "\n\n"
			.. "Unlocking your first tile will start your journey and lock your settings."
			.. " For a faithful run you should not modify your settings during the playthrough,"
			.. " but you may still do so for now as the balance level is still not determined."
			.. "\n\n"
			.. const:Color("UNCOMMON") .. "Hints" .. const:Color("TEXT_HIGHLIGHT")
			.. "\n\n"
			.. "Lock button interactions:"
			.. "\n- Left Click: Use to progress your journey"
			.. "\n- Right Click: Use for scouting, flights or ships"
		)
		tilingIntro.descriptionLabel:SetTextColor(1, 1, 1, 1)
		tilingIntro.descriptionLabel:SetJustifyH("LEFT")
	end

	function obj:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles, totalInstances)
		tilingStatus.xpBar:SetMinMaxValues(0, nextXP)
		tilingStatus.xpBar:SetValue(currentXP)
		tilingStatus.xpBar.text:SetText(string.format("Next Tile XP %d / %d", currentXP, nextXP))

		tilingStatus.availableLabel:SetText(availableTiles)
		tilingStatus.totalLabel:SetText(string.format("%d / %d", totalTiles, totalInstances))

		tilingSettings.progressLabel:SetText(string.format(
			const:Color("UNCOMMON") .. "Progress status" .. const:Color("TEXT_HIGHLIGHT")
			.. "\nAvailable: %d Tiles"
			.. "\nUnlocked: %d Tiles / %d Instances",
			availableTiles, totalTiles, totalInstances
		))
	end

	function obj:OnPositionChanged(worldData, mapData, measureData)
		--Update label info
		tilingStatus.positionLabel:SetText(obj:GetPositionText(worldData))
		tilingStatus.measureLabel:SetText(obj:GetMeasureText(measureData))
		tilingBlocker.label:SetText(obj:GetBlockerText(worldData))

		--Update minimap tiles
		obj:UpdateMinimapTiles(worldData)

		if (worldData == nil) then
			if (not tilingBlocker.isUnlocked) then
				tilingBlocker.isUnlocked = true
				UIFrameFadeOut(tilingBlocker.container, 0.25, 1, 0)
				tilingMap.player:Hide()
			end
			return
		end

		if (worldData.isTransport) then
			tilingStatus.unlockButton.icon:SetTexture(transportModeTexture, "REPEAT", "REPEAT")
			tilingStatus.unlockButton.frame:SetBackdropColor(0, 1, 1, 0.5)
		end

		--Update buttons
		obj:SetSelectorEnabled(tilingSettings.tileSizeSelector, worldData.allowSetup)
		obj:SetSelectorEnabled(tilingSettings.startTilesSelector, worldData.allowSetup)
		obj:SetSelectorEnabled(tilingSettings.xpRateSelector, true)

		--Modify rule changes
		if (showIntro ~= worldData.allowSetup) then
			showIntro = worldData.allowSetup
			if (showIntro and not tilingSettings.container:IsShown()) then
				tilingIntro.container:Show()
			else
				tilingIntro.container:Hide()
			end
		end

		--Show blocker for current tile if nessesary
		local shouldShowScreen = worldData.isUnlocked or worldData.isTransport
		local newScreenState = (tilingBlocker.isShowingScreen ~= shouldShowScreen)
		local newZoneState = (worldData.isNewZone ~= nil and not worldData.isNewZone == true)
		if (newScreenState and newZoneState) then
			tilingBlocker.isShowingScreen = shouldShowScreen

			if (not debug) then
				if (tilingBlocker.isShowingScreen) then
					UIFrameFadeOut(tilingBlocker.container, 0.25, 1, 0)
				else
					UIFrameFadeIn(tilingBlocker.container, 0.25, 0, 1)
				end
			end
		end

		if (mapData ~= nil) then
			--Set player dot
			if (mapData.map ~= nil) then
				local playerX = mapData.map.x * WorldMapFrame.ScrollContainer:GetWidth()
				local playerY = -mapData.map.y * WorldMapFrame.ScrollContainer:GetHeight()
				tilingMap.player:SetPoint("CENTER", WorldMapFrame.ScrollContainer, "TOPLEFT", playerX, playerY)
				tilingMap.player:Show()
			else
				tilingMap.player:Hide()
			end

			--Check for map changes
			if (
				(mapData.isVisible ~= tilingMap.lastVisible) or
				(mapData.height ~= tilingMap.lastHeight) or
				(mapData.zoneId ~= tilingMap.lastZoneId) or
				(worldData.tileKey ~= tilingMap.lastTileKey) or
				(worldData.isUnlocked ~= tilingMap.lastUnlocked) or
				refreshMap
			) then
				tilingMap.lastVisible = mapData.isVisible
				tilingMap.lastHeight = mapData.height
				tilingMap.lastZoneId = mapData.zoneId
				tilingMap.lastTileKey = worldData.tileKey
				tilingMap.lastUnlocked = worldData.isUnlocked
				refreshMap = false
				obj:OnMapChanged(mapData, worldData)
			end
		end
	end

	function obj:OnMapChanged(mapData, worldData)
		local tiling = _G.LEDII_TILE_TILING

		--Setup visibility
		if (mapData.zoneEstimation ~= nil) then
			tilingMap.grid:Show()
			--log:Info("Zone estimation valid. Calculating tiles...")
		else
			tilingMap.grid:Hide()
			--log:Info("Zone estimation missing! (" .. mapData.zoneName .. " | " .. mapData.zoneId .. ")")
			obj:UpdateMapTiles(mapData, worldData)
			return
		end

		--Setup tiling
		local pixelsPerWorldUnit = mapData.width / mapData.zoneEstimation.width
		local tilePixelSize = tiling.tileSize * pixelsPerWorldUnit
		local tileTextureMip = obj:GetTileTextureMip(tilePixelSize * 2)

		tilingMap.grid:SetBackdrop({
			bgFile = tileTextureMip,
			tile = true,
			tileSize = tilePixelSize
		})
		tilingMap.grid:SetBackdropColor(1, 1, 1, 0.25)

		local sizeX = mapData.width + (tilePixelSize * 2)
		local sizeY = mapData.height + (tilePixelSize * 2)
		tilingMap.grid:SetSize(sizeX, sizeY)

		--Calculate offset to align north west corner to grid
		local tileW = (mapData.bounds.west / tiling.tileSize) + GRID_OFFSET_W
		local tileN = (mapData.bounds.north / tiling.tileSize) + GRID_OFFSET_N
		local relTileW = tileW - utils:TruncateNumber(tileW)
		local relTileN = tileN - utils:TruncateNumber(tileN)
		local offsetW = (1 - relTileW) * -tilePixelSize
		local offsetN = relTileN * -tilePixelSize
		
		--log:Info(string.format("Zone offset: %.2f, %.2f | %.2f, %.2f | %.2f, %.2f",
		--tileW, tileN, relTileW, relTileN, offsetW, offsetN))

		--log:Info(string.format("Zone boundary: %.2fW | %.2fE | %.2fS | %.2fN",
		--mapData.bounds.west, mapData.bounds.east,
		--mapData.bounds.south, mapData.bounds.north))

		--log:Info(string.format("Zone ref: %.2f, %.2f | %.2f, %.2f",
		--mapData.zoneEstimation.refWorldX, mapData.zoneEstimation.refWorldY,
		--mapData.zoneEstimation.refMapX, mapData.zoneEstimation.refMapY))

		tilingMap.grid:ClearAllPoints()
		tilingMap.grid:SetPoint("TOPLEFT", tilingMap.gridMask, "TOPLEFT", offsetW, offsetN)

		obj:UpdateMapTiles(mapData, worldData)
	end
	----- PUBLIC END -----



	----- PRIVATE BEGIN -----
	function obj:GetMeasureText(measureData)
		if (measureData == nil) then return "N/A" end
		if (measureData.estimateWidth == nil) then return "N/A" end

		local numberFormat = "%.2f"
		if (IsShiftKeyDown()) then
			numberFormat = "%d"
		end

		local format = ""
		if (measureData.estimateValidWidth) then
			format = format .. const:Color("UNCOMMON") .. numberFormat .. const:Color("COMMON")
		else
			format = format .. numberFormat
		end
		format = format .. ", "
		if (measureData.estimateValidHeight) then
			format = format .. const:Color("UNCOMMON") .. numberFormat .. const:Color("COMMON")
		else
			format = format .. numberFormat
		end

		if (IsShiftKeyDown()) then
			return string.format(format, measureData.estimateWidth, measureData.estimateHeight)
		else
			return string.format(format, measureData.deltaWorld.x, measureData.deltaWorld.y)
		end
	end

	function obj:GetPositionText(worldData)
		if (worldData == nil) then
			return "?.??, ?.??"
		end

		if (worldData.continentName == "Instance") then
			if (IsShiftKeyDown()) then
				if (worldData.nearestInstanceEntrance ~= nil) then
					local wingId = worldData.nearestInstanceEntrance.entranceId
					return string.format("Instance: %d (Wing: %d)", worldData.zoneId, wingId)
				else
					return string.format("Instance: %d", worldData.zoneId)
				end
			else
				return worldData.zoneName
			end
		end

		if (IsShiftKeyDown()) then
			return string.format("World: %d, %d", worldData.world.x, worldData.world.y)
		else
			return string.format("Tile: %.2f, %.2f", worldData.tile.x, worldData.tile.y)
		end
	end

	function obj:GetBlockerText(worldData)
		if (worldData ~= nil) then
			if (worldData.continentName == "Instance") then
				local message = "This instance is not unlocked yet"

				local tiling = _G.LEDII_TILE_TILING
				local cost = tiling:GetUnlockCost(worldData)
				if (cost ~= nil) then
					if (cost > 0) then
						message = message .. string.format("\nUnlock cost is %s%d Tiles",
							const:Color("NEGATIVE_VALUE"), cost
						)
					else
						message = message .. string.format("\nUnlock cost is %sFree",
							const:Color("POSITIVE_VALUE")
						)
					end
				else
					message = message .. string.format("\nUnlock cost is %sUndefined (Free)\n\n%sPlease report bug if found!",
						const:Color("POSITIVE_VALUE"), const:Color("WARNING")
					)
				end

				return message
			end
		end

		return "This tile is not unlocked yet"
	end

	function obj:UpdateMinimapTiles(worldData)
		--Hide current tiles
		for i = 1, #tilingMinimap.tileFrames do
			tilingMinimap.tileFrames[i]:Hide()
		end

		if (worldData == nil) then return end
		--Calculate frame size based on zoom
		local tiling = _G.LEDII_TILE_TILING
		local isInside = tiling.isInsideZone or tiling.isInsideArea
		local pixelsPerWorldUnit = obj:GetZoomMultiplier(worldData.zoneId, isInside)
		local frameSize = worldData.tileSize * pixelsPerWorldUnit
		local tileTextureMip = obj:GetTileTextureMip(frameSize)

		--Show surrounding tiles
		local frameIndex = 1
		local tileParent = tilingMinimap.container
		local extent = 2
		local drawDirectionX = -1
		local drawDirectionY = -1

		for offsetY = -extent, extent do
			for offsetX = -extent, extent do
				--Evaluate data for tile
				local tileX = worldData.tile.x + offsetX
				local tileY = worldData.tile.y + offsetY
				local tileKey = tiling:GetTileKey(tileX, tileY)
				local isPlayerTile = (offsetX == 0 and offsetY == 0)
				local isUnlocked = tiling:IsTileUnlocked(tileKey, worldData.zoneId, worldData.continentId)

				local framePosX = obj:GetTileMinimapOffset(worldData.tile.x, worldData.tileId.x, offsetX, frameSize, drawDirectionX)
				local framePosY = obj:GetTileMinimapOffset(worldData.tile.y, worldData.tileId.y, offsetY, -frameSize, drawDirectionY)

				--Draw tile
				if (isPlayerTile or isUnlocked) then
					--Initialize tile
					--log:Info(string.format("Draw tile: %.2f, %.2f (offset %d, %d | key %s)", tileX, tileY, offsetX, offsetY, tileKey))
					local tileFrame = tilingMinimap.tileFrames[frameIndex]
					if (tileFrame == nil) then
						local name = "TileZ_Section_" .. frameIndex
						tileFrame = obj:CreateTextureFrame(name, tileParent, tileTextureMip)
						tileFrame.texture:AddMaskTexture(tileParent.mask)
						table.insert(tilingMinimap.tileFrames, tileFrame)
					end

					--Update tile
					tileFrame.texture:SetTexture(tileTextureMip)
					obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked, 0.4)
					tileFrame:ClearAllPoints()
					tileFrame:SetSize(frameSize, frameSize)
					tileFrame:SetPoint("CENTER", tileParent, "CENTER", framePosX, framePosY)
					tileFrame:Show()

					frameIndex = frameIndex + 1
				end
			end
		end
	end

	function obj:UpdateMapTiles(mapData, worldData)
		--Hide current tiles
		for i = 1, #tilingMap.tileFrames do
			tilingMap.tileFrames[i]:Hide()
		end

		if (mapData.zoneEstimation == nil) then return end

		local tiling = _G.LEDII_TILE_TILING
		local offsetW, offsetN = utils:GetPointByName(tilingMap.grid, "TOPLEFT")
		local pixelsPerWorldUnit = mapData.width / mapData.zoneEstimation.width
		local tilePixelSize = tiling.tileSize * pixelsPerWorldUnit

		local tileTextureMip = obj:GetTileTextureMip(tilePixelSize)
		local updateMipTexture = false
		if (tilePixelSize ~= cachedMinimapSize) then
			cachedMinimapSize = tilePixelSize
			updateMipTexture = true
		end

		--Show unlocked tiles
		local frameIndex = 1
		local tileParent = tilingMap.grid

		local unlockedZoneTiles = {}
		local allTiles = mapData.unlockedTiles
		if (allTiles ~= nil) then
			local continentTiles = allTiles[mapData.continentId]
			if (continentTiles ~= nil) then
				local zoneTiles = continentTiles[mapData.zoneId]
				if (zoneTiles ~= nil) then
					unlockedZoneTiles = utils:CloneTableShallow(zoneTiles)
				end
			end
		end

		if (mapData.zoneId == worldData.zoneId) then
			unlockedZoneTiles[worldData.tileKey] = true
		end
		
		for key, value in pairs(unlockedZoneTiles) do
			--Fetch tile values
			local keyParts = utils:Split(key, "_")
			local tileIdX = tonumber(keyParts[1])
			local tileIdY = tonumber(keyParts[2])
			local isPlayerTile = (key == worldData.tileKey)
			local isUnlocked = utils:Turnary(isPlayerTile, worldData.isUnlocked, true)

			--Calculate offset relative to topleft of grid
			local relUnitsX = (tileIdX * tiling.tileSize) - mapData.bounds.west
			local relUnitsY = (tileIdY * tiling.tileSize) - mapData.bounds.north
			local relIdX = (-relUnitsX / tiling.tileSize) + utils:Turnary(string.find(tileIdX, "-"), 0, -1)
			local relIdY = (relUnitsY / tiling.tileSize) + utils:Turnary(string.find(tileIdY, "-"), 0, 1)
			local framePosX = (relIdX * tiling.tileSize * pixelsPerWorldUnit) - offsetW
			local framePosY = (relIdY * tiling.tileSize * pixelsPerWorldUnit) - offsetN

			--Initialize tile
			local tileFrame = tilingMap.tileFrames[frameIndex]
			if (tileFrame == nil) then
				local name = "TileZ_Section_" .. frameIndex
				tileFrame = obj:CreateTextureFrame(name, tileParent, tileTextureMip)
				table.insert(tilingMap.tileFrames, tileFrame)
			end

			--Update tile
			if (updateMipTexture) then
				tileFrame.texture:SetTexture(tileTextureMip)
			end
			
			obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked)
			tileFrame:ClearAllPoints()
			tileFrame:SetSize(tilePixelSize, tilePixelSize)
			tileFrame:SetPoint("TOPLEFT", tileParent, "TOPLEFT", framePosX, framePosY)
			tileFrame:Show()

			local strata = utils:Turnary(isPlayerTile, "TOOLTIP", "MEDIUM")
			tileFrame:SetFrameStrata(strata)

			frameIndex = frameIndex + 1
		end
	end

	function obj:GetTileTextureMip(size)
		--log:Info("pixelsPerWorldUnit: " .. size)

		if (size < 7) then return minimapTileTextureMip[9] end
		if (size < 8.5) then return minimapTileTextureMip[8] end
		if (size < 10) then return minimapTileTextureMip[7] end
		if (size < 12.5) then return minimapTileTextureMip[6] end
		if (size < 15) then return minimapTileTextureMip[5] end
		if (size < 25) then return minimapTileTextureMip[4] end
		if (size < 50) then return minimapTileTextureMip[3] end
		if (size < 100) then return minimapTileTextureMip[2] end

		return minimapTileTextureMip[1]
	end

	function obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked, alpha)
		local tiling = _G.LEDII_TILE_TILING
		local a = alpha or 1.0
		local glowA = math.min(1.0, a * 2)

		if (isPlayerTile and isUnlocked) then
			local color = tiling.colors.currentUnlocked
			tileFrame.texture:SetVertexColor(color.r, color.g, color.b, glowA)
		elseif (isPlayerTile) then
			local color = tiling.colors.currentLocked
			tileFrame.texture:SetVertexColor(color.r, color.g, color.b, glowA)
		elseif (isUnlocked) then
			local color = tiling.colors.otherUnlocked
			tileFrame.texture:SetVertexColor(color.r, color.g, color.b, a)
		end
	end

	function obj:GetTileMinimapOffset(tile, tileId, offset, tileSize, direction)
		local relOffset = offset + (utils:Turnary(tile >= 0, -0.5, 0.5) * direction)
		local relTile = tile + (relOffset * direction)
		local playerDelta = (relTile - tileId)
		local centerOffset = playerDelta * tileSize

		return centerOffset
	end

	function obj:GetZoomMultiplier(zoneId, isIndoor)
		local zoomOffsets = { 0.0, 0.175, 0.4, 0.75, 1.3, 2.5 }

		if (isIndoor) then
			zoomOffsets = { 0.5, 1.0, 1.6, 2.75, 5, 9 }
		end

		local zoomIndex = Minimap:GetZoom() + 1
		local zoomMultiplier = 1.0 + zoomOffsets[zoomIndex]
		return 0.3 * zoomMultiplier
	end

	function obj:SetSelectorEnabled(selector, enabled)
		if (enabled) then
			selector.previous:Enable()
			selector.next:Enable()
			selector.previous.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
			selector.next.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
		else
			selector.previous:Disable()
			selector.next:Disable()
			selector.previous.frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
			selector.next.frame:SetBackdropColor(0.3, 0.3, 0.3, 0.5)
		end
	end

	function obj:SetSelectorValue(selector, value)
		selector.index = utils:IndexOf(selector.optionValues, value)
		selector.valueLabel:SetText(selector.optionTexts[selector.index])
	end

	function obj:SetIncrementValue(selector, value)
		selector.value = value
		selector.valueLabel:SetText(string.format(selector.format, selector.value))
	end

	function obj:UpdateSettings()
		local tiling = _G.LEDII_TILE_TILING
		obj:SetIncrementValue(tilingSettings.tileSizeSelector, tiling.tileSize)
		obj:SetIncrementValue(tilingSettings.startTilesSelector, tiling.startCount)
		obj:SetIncrementValue(tilingSettings.xpRateSelector, tiling.xpRate)

		obj:OnTileSizeSelected(tiling.tileSize)
	end

	function obj:OnSettingsButtonClicked(button, heldCount)
		if (button ~= "LeftButton") then return end
		if (heldCount ~= PRESS_UP_COUNT) then return end

		if (tilingSettings.container:IsShown()) then
			tilingSettings.container:Hide()
			if (showIntro) then
				tilingIntro.container:Show()
			end
		else
			tilingSettings.container:Show()
			tilingIntro.container:Hide()
		end
	end

	function obj:OnUnlockButtonClicked(button, heldCount)
		if (heldCount ~= PRESS_UP_COUNT) then return end

		local tiling = _G.LEDII_TILE_TILING

		if (button == "LeftButton") then
			if (tiling.lockMode ~= "Unlocked") then
				tiling.lockMode = "Unlocked"
				tilingIntro.container:Hide()
			else
				tiling.lockMode = "Locked"
			end
		elseif (button == "RightButton") then
			if (tiling.lockMode ~= "Transport") then
				tiling.lockMode = "Transport"
			else
				tiling.lockMode = "Locked"
			end
		end

		obj:SetupUnlockButtonStatus()
	end

	function obj:SetupUnlockButtonStatus()
		local tiling = _G.LEDII_TILE_TILING
		if (tiling.lockMode == "Unlocked") then
			tilingStatus.unlockButton.icon:SetTexture(unlockedModeTexture, "REPEAT", "REPEAT")
			tilingStatus.unlockButton.frame:SetBackdropColor(0, 1, 0, 0.5)
		elseif (tiling.lockMode == "Transport") then
			tilingStatus.unlockButton.icon:SetTexture(transportModeTexture, "REPEAT", "REPEAT")
			tilingStatus.unlockButton.frame:SetBackdropColor(0, 1, 1, 0.5)
		else
			tilingStatus.unlockButton.icon:SetTexture(lockedModeTexture, "REPEAT", "REPEAT")
			tilingStatus.unlockButton.frame:SetBackdropColor(1, 0, 0, 0.5)
		end
	end

	function obj:OnTileSizeSelected(value)
		--log:Info("OnTileSizeSelected: " .. value)

		local tiling = _G.LEDII_TILE_TILING
		tiling.tileSize = value
		tiling:Save()

		--Ensure zoom level is max
		for i = 1, 5 do
			MinimapZoomIn:Click()
		end
		if (value > 50) then MinimapZoomOut:Click() end
		if (value > 75) then MinimapZoomOut:Click() end
		if (value > 100) then MinimapZoomOut:Click() end
		if (value > 125) then MinimapZoomOut:Click() end
		if (value > 150) then MinimapZoomOut:Click() end

		refreshMap = true
	end

	function obj:OnStartTilesSelected(value)
		--log:Info("OnStartTilesSelected: " .. index)

		local tiling = _G.LEDII_TILE_TILING
		tiling:SetStartTiles(value)
	end

	function obj:OnXPRateSelected(value)
		--log:Info("OnXPRateSelected: " .. index)

		local tiling = _G.LEDII_TILE_TILING
		tiling.xpRate = value
		tiling:Save()
	end
	----- PRIVATE END -----



	----- UTILITY BEGIN -----
	function obj:CreateContainerFrame(name, parent)
		local container = CreateFrame("Frame", name, parent)

		return container
	end

	function obj:CreateBackdropFrame(name, parent, bgFile, edgeFile, tile, tileSize, edgeSize, insets)
		local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
		insets = insets or 4

		frame:SetSize(100, 100)
		frame:SetBackdrop({
			bgFile = bgFile or "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = edgeFile or "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = tile or true,
			tileSize = tileSize or 16,
			edgeSize = edgeSize or 16,
			insets = { left = insets, right = insets, top = insets, bottom = insets }
		})

		return frame
	end

	function obj:CreateTextureFrame(name, parent, file, tileSize, tileX, tileY)
		local frame = obj:CreateContainerFrame(name, parent)

		frame.texture = frame:CreateTexture(nil, "ARTWORK")
		frame.texture:SetTexture(file, "REPEAT", "REPEAT")
		frame.texture:SetAllPoints(frame)
		frame.texture:SetHorizTile(tileX or false)
		frame.texture:SetVertTile(tileY or false)

		return frame
	end

	function obj:CreateButtonFrame(name, parent, iconFile, insets)
		local button = CreateFrame("Button", name, parent)

		--Setup font
		button:SetNormalFontObject("GameFontNormalLarge")
		local normalFont = button:GetNormalFontObject()
		normalFont:SetTextColor(1, 1, 1, 1)
		button:SetNormalFontObject(normalFont)

		button:SetHighlightFontObject("GameFontHighlightLarge")
		local highlightFont = button:GetHighlightFontObject()
		highlightFont:SetTextColor(1, 1, 1, 1)
		button:SetHighlightFontObject(highlightFont)

		--Setup frame
		button.frame = obj:CreateBackdropFrame(name .. "_Frame", button, whiteTexture)
		button.frame:SetAllPoints(button)
		button.frame:SetBackdropColor(0, 0, 0, 0.5)
		button.frame:SetFrameLevel(button:GetFrameLevel() - 1)
		
		--Setup icon
		if (iconFile ~= nil) then
			button.icon = button.frame:CreateTexture(nil, "ARTWORK")
			button.icon:SetTexture(iconFile, "REPEAT", "REPEAT")

			insets = insets or 0 
			button.icon:SetPoint("TOPLEFT", button.frame, "TOPLEFT", insets, -insets)
			button.icon:SetPoint("BOTTOMRIGHT", button.frame, "BOTTOMRIGHT", -insets, insets)
		end

		--Setup down function
		button:SetScript("OnMouseDown", function(self, btn)
			if (self.icon ~= nil) then
				self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", insets, -insets - 2)
				self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -insets, insets - 2)
			end

			if (self.onMouseHeld ~= nil) then
				self.heldCount = 0
				self.heldTimer = C_Timer.NewTicker(0.1, function()
					self.onMouseHeld(self, btn, self.heldCount)
					self.heldCount = self.heldCount + 1
				end)
			end
		end)

		--Setup up function
		button:SetScript("OnMouseUp", function(self, btn)
			if (self.icon ~= nil) then
				self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", insets, -insets)
				self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -insets, insets)
			end

			if (self.onMouseHeld ~= nil) then
				self.heldTimer:Cancel()
				self.onMouseHeld(self, btn, -1)
			end
		end)

		return button
	end

	function obj:CreateTemplateFrame()
		--
	end

	function obj:CreateLabelFrame(name, parent, fontTemplate)
		local drawLayer = "OVERLAY"
		local template = "GameFontNormal"
		local label = parent:CreateFontString(name, drawLayer, template)

		label:SetTextColor(1, 1, 1, 1)
		label:SetText("New label")

		if (fontTemplate ~= nil) then
			local font, size, flags = fontTemplate:GetFont()
			label:SetFont(font, size, flags)
		end

		return label
	end

	function obj:CreateExperienceFrame(name, parent, width)
		-- Create XP bar
		local xpBar = CreateFrame("StatusBar", name, UIParent)
		xpBar:SetSize(width, 8)
		xpBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		xpBar:GetStatusBarTexture():SetHorizTile(false)
		xpBar:SetMinMaxValues(0, 100)
		xpBar:SetValue(50)

		-- Create background texture (behind the bar)
		local bg = xpBar:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.25)

		-- Create border frame (above the XP bar, below the text)
		local inset = 4
		local border = obj:CreateBackdropFrame(nil, xpBar, "", nil, nil, nil, 10, inset)
		border:SetPoint("TOPLEFT", xpBar, "TOPLEFT", -inset, inset)
		border:SetPoint("BOTTOMRIGHT", xpBar, "BOTTOMRIGHT", inset, -inset)
		border:SetBackdropBorderColor(1, 1, 1, 1)

		-- XP Text overlay (on top of everything)
		xpBar.text = obj:CreateLabelFrame(nil, border, TextStatusBarText)
		xpBar.text:SetPoint("CENTER", xpBar, "CENTER", 0, 0)
		xpBar.text:SetTextColor(1, 1, 1, 1)
		xpBar.text:SetText("XP ? / ?")
		xpBar.text:Hide()

		-- Show XP text on mouseover
		xpBar:EnableMouse(true)
		xpBar:SetScript("OnEnter", function()
			xpBar.text:Show()
		end)
		xpBar:SetScript("OnLeave", function()
			xpBar.text:Hide()
		end)

		return xpBar
	end

	function obj:CreateSelectorFrame(name, parent, label, optionTexts, optionValues, selectedValue, callback)
		local selector = obj:CreateContainerFrame(name .. "_Container", parent)
		selector:SetSize(parent:GetWidth(), 30)
		selector.index = utils:IndexOf(optionValues, selectedValue)
		selector.optionValues = optionValues
		selector.optionTexts = optionTexts

		local widthInset = 20
		local nameWidth = (selector:GetWidth() * 0.5) - widthInset
		local valueWidth = (selector:GetWidth() * 0.5) - widthInset
		local buttonSize = 28

		selector.nameLabel = obj:CreateLabelFrame(name .. "_Label", selector)
		selector.nameLabel:SetText(label or "Property name")
		selector.nameLabel:SetPoint("LEFT", selector, "LEFT", 20, 0)
		selector.nameLabel:SetSize(nameWidth, selector:GetHeight())
		selector.nameLabel:SetJustifyH("LEFT")

		selector.valueLabel = obj:CreateLabelFrame(name .. "_Label", selector)
		selector.valueLabel:SetText("?")
		selector.valueLabel:SetPoint("RIGHT", selector, "RIGHT", -20, 0)
		selector.valueLabel:SetSize(valueWidth, selector:GetHeight())

		if (optionTexts ~= nil) then
			local option = selector.optionTexts[selector.index]
			if (optionTexts ~= nil) then
				selector.valueLabel:SetText(option)
			end
		end

		selector.previous = obj:CreateButtonFrame(name .. "_PreviousButton", selector)
		selector.previous:SetText("<")
		selector.previous:SetPoint("LEFT", selector.valueLabel, "LEFT", 0, 0)
		selector.previous:SetSize(buttonSize, buttonSize)
		selector.previous.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
		selector.previous.onMouseHeld = function()
			selector.index = ((selector.index - 1 - 1 + #selector.optionTexts) % #selector.optionTexts) + 1
			local option = selector.optionTexts[selector.index]
			selector.valueLabel:SetText(option)
			if (callback ~= nil) then
				callback(nil, selector.index)
			end
		end

		selector.next = obj:CreateButtonFrame(name .. "_NextButton", selector)
		selector.next:SetText(">")
		selector.next:SetPoint("RIGHT", selector.valueLabel, "RIGHT", 0, 0)
		selector.next:SetSize(buttonSize, buttonSize)
		selector.next.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
		selector.next.onMouseHeld = function()
			selector.index = ((selector.index - 1 + 1 + #selector.optionTexts) % #selector.optionTexts) + 1
			local option = selector.optionTexts[selector.index]
			selector.valueLabel:SetText(option)
			if (callback ~= nil) then
				callback(nil, selector.index)
			end
		end

		return selector
	end

	function obj:CreateIncrementFrame(name, parent, label, format, min, max, increment, selectedValue, callback)
		local selector = obj:CreateContainerFrame(name .. "_Container", parent)
		selector:SetSize(parent:GetWidth(), 30)
		selector.value = selectedValue or 50
		selector.min = min or 0
		selector.max = max or 100
		selector.increment = increment or 5
		selector.format = format or "%d"

		local widthInset = 20
		local nameWidth = (selector:GetWidth() * 0.5) - widthInset
		local valueWidth = (selector:GetWidth() * 0.5) - widthInset
		local buttonSize = 28

		selector.nameLabel = obj:CreateLabelFrame(name .. "_Label", selector)
		selector.nameLabel:SetText(label or "Property name")
		selector.nameLabel:SetPoint("LEFT", selector, "LEFT", 20, 0)
		selector.nameLabel:SetSize(nameWidth, selector:GetHeight())
		selector.nameLabel:SetJustifyH("LEFT")

		selector.valueLabel = obj:CreateLabelFrame(name .. "_Label", selector)
		selector.valueLabel:SetText(string.format(selector.format, selector.value))
		selector.valueLabel:SetPoint("RIGHT", selector, "RIGHT", -20, 0)
		selector.valueLabel:SetSize(valueWidth, selector:GetHeight())

		selector.previous = obj:CreateButtonFrame(name .. "_PreviousButton", selector)
		selector.previous:SetText("<")
		selector.previous:SetPoint("LEFT", selector.valueLabel, "LEFT", 0, 0)
		selector.previous:SetSize(buttonSize, buttonSize)
		selector.previous.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
		selector.previous.onMouseHeld = function(self, button, heldCount)
			if (heldCount == PRESS_DOWN_COUNT) then return end
			selector.value = math.max(selector.value - selector.increment, selector.min)
			selector.valueLabel:SetText(string.format(selector.format, selector.value))
			if (callback ~= nil) then
				callback(nil, selector.value)
			end
		end

		selector.next = obj:CreateButtonFrame(name .. "_NextButton", selector)
		selector.next:SetText(">")
		selector.next:SetPoint("RIGHT", selector.valueLabel, "RIGHT", 0, 0)
		selector.next:SetSize(buttonSize, buttonSize)
		selector.next.frame:SetBackdropColor(0.5, 0.1, 0.1, 1)
		selector.next.onMouseHeld = function(self, button, heldCount)
			if (heldCount == PRESS_DOWN_COUNT) then return end
			selector.value = math.min(selector.value + selector.increment, selector.max)
			selector.valueLabel:SetText(string.format(selector.format, selector.value))
			if (callback ~= nil) then
				callback(nil, selector.value)
			end
		end

		return selector
	end
	----- UTILITY END -----

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_UI = class
--C_Timer.NewTicker(0.1, class.Tick)