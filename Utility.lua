--print("Loaded <Utility.lua>")obj:BreakGUID
local const = _G.LEDII_TILE_CONST
local log = _G.LEDII_TILE_LOG

local function class()
	local obj = {}

	--General use
	function obj:Split(s, delimiter)
		result = {};
		for match in (s..delimiter):gmatch("(.-)"..delimiter) do
			table.insert(result, match);
		end
		return result;
	end

	function obj:CloneTableShallow(inTable)
		local orig_type = type(inTable)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in pairs(inTable) do
				copy[orig_key] = orig_value
			end
		else -- number, string, boolean, etc
			copy = inTable
		end
		return copy
	end

	function obj:CloneTableDeep(inTable)
		local orig_type = type(inTable)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, inTable, nil do
				copy[obj:CloneTableDeep(orig_key)] = obj:CloneTableDeep(orig_value)
			end
			setmetatable(copy, obj:CloneTableDeep(getmetatable(inTable)))
		else -- number, string, boolean, etc
			copy = inTable
		end
		return copy
	end

	function obj:JoinTable(inTable, delimiter)
		local text = ""

		for key in pairs(inTable) do
			if (text ~= "") then
				text = text .. delimiter
			end
			text = text .. inTable[key]
		end

		return text
	end

	function obj:RoundNumberNear(number, treshhold)
		treshhold = treshhold or 0.1

		local nearest = math.floor(number + 0.5)
		if (math.abs(nearest - number) < treshhold) then
			return nearest
		else
			return number
		end
	end

	function obj:RoundNumberAbove(number, treshhold)
		if (number >= treshhold) then
			return math.floor(number + 0.5)
		else
			return number
		end
	end

	function obj:LimitNumber(number, maxDecimals)
		local text = string.format("%." .. maxDecimals .. "f", number)
		return tonumber(text)

		--local text = number .. ""
		--if (string.find(text, "%.")) then
			--text = string.format("%." .. maxDecimals .. "f", number)
		--end

		--return text
	end

	function obj:DynamicNumber(number, maxDigits)
		--log:Info("Number: " .. number)
		local intStr, decStr = strsplit(".", number .. "")

		local intCount = string.len(intStr)
		local decCount = maxDigits - intCount

		local text = string.format("%." .. decCount .. "f", number)
		return tonumber(text)
	end

	function obj:TableContains(items, item)
		for i = 1, #items do
			if items[i] == item then
				return true
			end
		end

		return false
	end

	function obj:StringContains(items, item)
		for i = 1, #items do
			if (string.find(items[i], item)) then
				return true
			end
		end

		return false
	end

	function obj:StringAfter(string, find)
		return string.sub(string, string.len(find) + 1)
	end

	function obj:TruncateNumber(number)
		if (number >= 0) then
			return math.floor(number)
		else
			return math.ceil(number)
		end
	end

	function obj:SignNumber(number)
		if (number > 0) then
			return 1
		elseif (number < 0) then
			return -1
		else
			return 0
		end
	end

	return obj
end

_G.LEDII_TILE_UTILS = class()