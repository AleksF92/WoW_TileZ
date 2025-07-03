--print("Loaded <Logger.lua>")
local const = _G.LEDII_TILE_CONST

local function class()
	local obj = {}

	function obj:Info(msg)
		print(const:Color("HEADER") .. "[" .. const:String("NAME") .. "] " .. const:Color("TEXT") .. msg)
	end

	function obj:GetIndentStr(depth)
		string.rep("  ", depth)
	end

	function obj:ValueString(inValue, label, maxDepth, depth)
		label = label or "Value"
		depth = depth or 0
		maxDepth = maxDepth or 0

		local depthStr = string.rep("  ", depth)

		if (type(inValue) ~= "table") then
			obj:Info(string.format("%s%s = %s", depthStr, label, tostring(inValue)))
			return
		end
		if (maxDepth > 0 and depth >= maxDepth) then
			obj:Info(string.format("%s%s = Table { ... }", depthStr, label))
			return
		end

		obj:Info(string.format("%s%s = Table {", depthStr, label))
		for key, value in pairs(inValue) do
			obj:ValueString(value, string.format("[%s]", key), depth + 1)
		end
		obj:Info(string.format("%s}", depthStr))

		return
	end

	function obj:PairTable(table)
		for key, value in pairs(table) do
			obj:Info("[" .. key .. "] = " .. tostring(value))
		end
	end

	function obj:IndexTable(table)
		for i, value in ipairs(table) do
			obj:Info("[" .. i .. "] = " .. tostring(value))
		end
	end

	return obj
end

_G.LEDII_TILE_LOG = class()