-- Shared helpers for the service modules.

local ROOT = (...):match("^(.*)%.[^%.]+$")
local json = require(ROOT .. ".lib.json")

local Utils = {}

--- Returns {} for a nil optional JSON-object parameter.
function Utils.emptyFix(tbl)
	if tbl == nil then
		return {}
	end
	return tbl
end

--- Marks a list param so it still encodes as [] when empty (empty tables otherwise encode as {}).
function Utils.array(list)
	if list == nil then
		return nil
	end
	return json.array(list)
end

function Utils.split(s, sep)
	local out = {}
	if s == nil then
		return out
	end
	local pattern = "([^" .. sep:gsub("%p", "%%%0") .. "]*)"
	for part in (s .. sep):gmatch(pattern .. sep:gsub("%p", "%%%0")) do
		out[#out + 1] = part
	end
	return out
end

-- No-ops: the JSON encoder already writes empty tables as {}.
function Utils.markEmptyObjects(value)
	return value
end

function Utils.encodeEmptyObjects(s)
	return s
end

return Utils
