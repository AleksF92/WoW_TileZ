--print("Loaded <Console.lua>")
local log = _G.LEDII_TILE_LOG
local const = _G.LEDII_TILE_CONST
local tiling = _G.LEDII_TILE_TILING
local utils = _G.LEDII_TILE_UTILS

local function PrivateClass()
	local obj = {}

	function obj:Highlight(highlightText, defaultText)
		local highlightStr = const:Color("TEXT_HIGHLIGHT") .. highlightText
		local defaultStr = const:Color("TEXT") .. defaultText
		return highlightStr .. defaultStr
	end

	function obj:Help()
		local cmd = SLASH_LEDII_TILE1
		log:Info(obj:Highlight(cmd .. " alias", " - Logs all command aliases"))
		log:Info(obj:Highlight(cmd .. " add {amount}", " - Manually add tiles"))
		log:Info(obj:Highlight(cmd .. " remove {amount}", " - Manually remove tiles"))
		log:Info(obj:Highlight(cmd .. " reset", " - Resets all data for character"))
		log:Info(obj:Highlight(cmd .. " status", " - Logs status for tiles"))
		log:Info(obj:Highlight(cmd .. " position", " - Logs tile number for current position"))
		log:Info(obj:Highlight(cmd .. " estimate {x} {y}", " - Calculates required tiles to reach destination"))
		log:Info(obj:Highlight(cmd .. " measure", " - Measures the distance for the zone"))
	end

	function obj:Alias()
		local options = { SLASH_LEDII_TILE1, SLASH_LEDII_TILE2 }
		local color1 = const:Color("TEXT_HIGHLIGHT")
		local color2 = const:Color("TEXT")
		local allOptionsStr = color1 .. table.concat(options, color2 .. " or " .. color1)
		log:Info("You can use the following aliases when entering commands:\n" .. allOptionsStr)
	end

	function obj:Add(args)
		local count = args[2]
		log:Info("Adding " .. count .. " tiles")
	end

	function obj:Remove(args)
		local count = args[2]
		log:Info("Removing " .. count .. " tiles")
	end

	function obj:Reset(args)
		log:Info("Reset all tiles...")
		tiling:Reset()
		tiling:CalculateHistoricXP()
	end

	function obj:Status(args)
		local available = 0
		local total = 0
		local currentXP = 0
		local nextXp = 0
		log:Info("Available tiles: " .. available .. "\nTotal tiles: " .. total .. "\nNext tile: " .. currentXP .. " / " .. nextXp .. " XP")
	end

	function obj:Position(args)
		local zone = GetZoneText()
		local tile = tiling:GetCurrentTile()
		log:Info("Current tile is " .. tile.x .. ", " .. tile.y .. " (" .. zone .. ")")
	end

	function obj:Estimate(args)
		local x = args[2]
		local y = args[3]
		local zone = GetZoneText()
		log:Info("Estimate to tile " .. x .. ", " .. y .. " (" .. zone .. ")")
	end

	function obj:Measure(args)
		tiling:OnMeasureStart()
	end

	function obj:CollapseArgs(args, n)
		local keep = {}
		for i = n, #args do
			table.insert(keep, args[i])
		end

		return table.concat(keep, " ")
	end

	return obj
end

local class = PrivateClass()
_G.LEDII_TILE_CONSOLE = class

SLASH_LEDII_TILE1 = '/tilez'
SLASH_LEDII_TILE2 = '/ltz'
function SlashCmdList.LEDII_TILE(msg, editbox)
	local args = utils:Split(msg, " ")

	if (args[1] == "alias") then
		class:Alias()
	elseif (args[1] == "add") then
		class:Add(args)
	elseif (args[1] == "remove") then
		class:Remove(args)
	elseif (args[1] == "reset") then
		class:Reset(args)
	elseif (args[1] == "status") then
		class:Status(args)
	elseif (args[1] == "position") then
		class:Position(args)
	elseif (args[1] == "pos") then
		class:Position(args)
	elseif (args[1] == "estimate") then
		class:Estimate(args)
	elseif (args[1] == "measure") then
		class:Measure(args)
	else
		class:Help()
	end

end

_G.LEDII_TILE_WELCOME = "Type " .. const:Color("TEXT_HIGHLIGHT") .. SLASH_LEDII_TILE1 .. " help" .. const:Color("TEXT") .. " to show the list of commands."