--print("Loaded <UI.lua>")
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG
local utils = _G.LEDII_TILE_UTILS

local function PrivateClass()
	local obj = {}

	----- VARIABLES BEGIN -----
	local tilingStatus = {}
	local tilingMinimap = {}
	local tilingMap = {}
	local debug = true

	local whiteTexture = "Interface\\Buttons\\WHITE8x8"
	local minimapMaskTexture = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
	local minimapTileTexture = "Interface/Addons/TileZ/Textures/Tile_Outline_4px"
	----- VARIABLES END -----



	----- PUBLIC BEGIN -----
	function obj:SetupTiling()
		obj:SetupTilingStatus()
		obj:SetupTilingMinimap()
		obj:SetupTilingMap()
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

		tilingMinimap.tileFrames = {}
	end

	function obj:SetupTilingMap()

	end

	function obj:OnExperienceChanged(currentXP, nextXP, availableTiles, totalTiles)
		tilingStatus.xpBar:SetMinMaxValues(0, nextXP)
		tilingStatus.xpBar:SetValue(currentXP)
		tilingStatus.xpBar.text:SetText(string.format("Next Tile XP %d / %d", currentXP, nextXP))

		tilingStatus.availableLabel:SetText(availableTiles)
		tilingStatus.totalLabel:SetText(totalTiles)
	end

	function obj:OnPositionChanged(worldData, mapData, measureData)
		tilingStatus.positionLabel:SetText(obj:GetPositionText(worldData))
		tilingStatus.measureLabel:SetText(obj:GetMeasureText(measureData))
		obj:UpdateMinimapTiles(worldData)
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
		if (IsShiftKeyDown()) then
			return string.format("%d, %d", worldData.world.x, worldData.world.y)
		else
			return string.format("%.2f, %.2f", worldData.tile.x, worldData.tile.y)
		end
	end

	function obj:UpdateMinimapTiles(worldData)
		--Hide current tiles
		for i = 1, #tilingMinimap.tileFrames do
			tilingMinimap.tileFrames[i]:Hide()
		end

		--Calculate frame size based on zoom
		local zoomOffsets = { 0.0, 0.175, 0.4, 0.75, 1.3, 2.5 }
		local zoomIndex = Minimap:GetZoom() + 1
		local zoomMultiplier = 1.0 + zoomOffsets[zoomIndex]
		local frameSize = worldData.tileSize * 0.25 * zoomMultiplier

		--Show surrounding tiles
		local tiling = _G.LEDII_TILE_TILING
		local frameIndex = 1
		local tileParent = tilingMinimap.container
		local extent = 2
		for offsetY = -extent, extent do
			for offsetX = -extent, extent do
				--Evaluate data for tile
				local tileX = worldData.tile.x + offsetX
				local tileY = worldData.tile.y + offsetY
				local tileKey = string.format("%d_%d", utils:TruncateNumber(tileX), utils:TruncateNumber(tileY))
				local isPlayerTile = (offsetX == 0 and offsetY == 0)
				local isUnlocked = tiling:IsTileUnlocked(tileKey, worldData.zoneId, worldData.continentId)
				
				local framePosX = obj:GetTileMinimapOffset(tileX, offsetX, worldData.tileId.x, frameSize)
				local framePosY = obj:GetTileMinimapOffset(tileY, offsetY, worldData.tileId.y, -frameSize)

				--Draw tile
				if (isPlayerTile or isUnlocked) then
					--Initialize tile
					local tileFrame = tilingMinimap.tileFrames[frameIndex]
					if (tileFrame == nil) then
						local name = "TileZ_Section_" .. frameIndex
						tileFrame = obj:CreateTextureFrame(name, tileParent, minimapTileTexture)
						tileFrame.texture:AddMaskTexture(tileParent.mask)
						table.insert(tilingMinimap.tileFrames, tileFrame)
					end

					--Update tile
					obj:SetTileColor(tileFrame, isPlayerTile, isUnlocked)
					tileFrame:ClearAllPoints()
					tileFrame:SetSize(frameSize, frameSize)
					tileFrame:SetPoint("CENTER", tileParent, "CENTER", framePosX, framePosY)
					tileFrame:Show()

					frameIndex = frameIndex + 1
				end
			end
		end
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

	function obj:GetTileMinimapOffset(frameTile, offset, playerTile, tileSize)
		local dx = frameTile - playerTile - 0.5
		if (frameTile < 0) then
			local negTile = frameTile - (offset * 2)
			dx = negTile - playerTile + 0.5
		end
		local offsetX = dx * tileSize

		return offsetX, 0
	end
	----- PRIVATE END -----



	----- UTILITY BEGIN -----
	function obj:CreateContainerFrame(name, parent)
		local container = CreateFrame("Frame", name, parent)

		container:SetSize(parent:GetSize())
		container:SetAllPoints(parent)

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
		frame.texture:SetHorizTile(tileY or false)
		frame.texture:SetVertTile(tileX or false)

		-- Repeat across dimensions based on tile size
		if (tileSize ~= nil) then
			frame.texture:SetTexCoord(
				0, frame:GetWidth() / tileSize,
				0, frame:GetHeight() / tileSize
			)
		end

		return frame
	end

	function obj:CreateTemplateFrame()

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
	----- UTILITY END -----

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_UI = class
--C_Timer.NewTicker(0.1, class.Tick)