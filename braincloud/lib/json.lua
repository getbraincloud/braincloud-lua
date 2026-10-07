-- JSON encode/decode for brainCloud payloads.
-- Empty tables encode as {} (the server rejects [] for map params); use json.array() for [].
-- Decoded arrays keep an array marker so they round-trip as [] even when empty.

local json = {}

local ARRAY_MT = { __jsontype = "array" }
local OBJECT_MT = { __jsontype = "object" }

json.null = setmetatable({}, { __tostring = function() return "null" end, __jsontype = "null" })

function json.array(t)
	return setmetatable(t or {}, ARRAY_MT)
end

function json.object(t)
	return setmetatable(t or {}, OBJECT_MT)
end

function json.isArray(t)
	if type(t) ~= "table" then
		return false
	end
	local mt = getmetatable(t)
	if mt and mt.__jsontype then
		return mt.__jsontype == "array"
	end
	local n = 0
	for k in pairs(t) do
		if type(k) ~= "number" or k <= 0 or k % 1 ~= 0 then
			return false
		end
		n = n + 1
	end
	if n == 0 then
		return false
	end
	for i = 1, n do
		if t[i] == nil then
			return false
		end
	end
	return true
end

local escapes = {
	['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
	["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t",
}

local function escapeString(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		return escapes[c] or string.format("\\u%04x", c:byte())
	end) .. '"'
end

local function encodeNumber(n)
	if n ~= n or n == math.huge or n == -math.huge then
		return "null"
	end
	if n % 1 == 0 and n >= -9007199254740992 and n <= 9007199254740992 then
		return string.format("%.0f", n)
	end
	return string.format("%.17g", n)
end

local encodeValue

local function encodeTable(t, out, seen)
	if seen[t] then
		error("json: circular reference")
	end
	seen[t] = true
	if json.isArray(t) then
		out[#out + 1] = "["
		for i = 1, #t do
			if i > 1 then
				out[#out + 1] = ","
			end
			encodeValue(t[i], out, seen)
		end
		out[#out + 1] = "]"
	else
		out[#out + 1] = "{"
		local keys = {}
		for k in pairs(t) do
			keys[#keys + 1] = k
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local first = true
		for _, k in ipairs(keys) do
			local v = t[k]
			if type(v) ~= "function" and type(v) ~= "userdata" then
				if not first then
					out[#out + 1] = ","
				end
				first = false
				out[#out + 1] = escapeString(tostring(k))
				out[#out + 1] = ":"
				encodeValue(v, out, seen)
			end
		end
		out[#out + 1] = "}"
	end
	seen[t] = nil
end

encodeValue = function(v, out, seen)
	local tv = type(v)
	if v == nil or v == json.null then
		out[#out + 1] = "null"
	elseif tv == "boolean" then
		out[#out + 1] = v and "true" or "false"
	elseif tv == "number" then
		out[#out + 1] = encodeNumber(v)
	elseif tv == "string" then
		out[#out + 1] = escapeString(v)
	elseif tv == "table" then
		encodeTable(v, out, seen)
	else
		error("json: cannot encode " .. tv)
	end
end

function json.encode(v)
	local out = {}
	encodeValue(v, out, {})
	return table.concat(out)
end

-- Decoder

local function decodeError(s, i, msg)
	error(string.format("json: %s at position %d", msg, i), 0)
end

local function skip(s, i)
	return s:find("[^ \t\r\n]", i) or #s + 1
end

local function utf8char(cp)
	if cp < 0x80 then
		return string.char(cp)
	elseif cp < 0x800 then
		return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
	elseif cp < 0x10000 then
		return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
	end
	return string.char(
		0xF0 + math.floor(cp / 0x40000),
		0x80 + math.floor(cp / 0x1000) % 0x40,
		0x80 + math.floor(cp / 0x40) % 0x40,
		0x80 + cp % 0x40
	)
end

local unescapes = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }

local function decodeString(s, i)
	local parts = {}
	local j = i + 1
	while true do
		local k = s:find('["\\]', j)
		if not k then
			decodeError(s, i, "unterminated string")
		end
		parts[#parts + 1] = s:sub(j, k - 1)
		if s:sub(k, k) == '"' then
			return table.concat(parts), k + 1
		end
		local c = s:sub(k + 1, k + 1)
		if c == "u" then
			local hex = s:sub(k + 2, k + 5)
			local cp = tonumber(hex, 16)
			if not cp then
				decodeError(s, k, "bad unicode escape")
			end
			local nextJ = k + 6
			if cp >= 0xD800 and cp <= 0xDBFF and s:sub(nextJ, nextJ + 1) == "\\u" then
				local lo = tonumber(s:sub(nextJ + 2, nextJ + 5), 16)
				if lo and lo >= 0xDC00 and lo <= 0xDFFF then
					cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
					nextJ = nextJ + 6
				end
			end
			parts[#parts + 1] = utf8char(cp)
			j = nextJ
		else
			local u = unescapes[c]
			if not u then
				decodeError(s, k, "bad escape")
			end
			parts[#parts + 1] = u
			j = k + 2
		end
	end
end

local decodeAt

local function decodeArray(s, i)
	local arr = json.array({})
	i = skip(s, i + 1)
	if s:sub(i, i) == "]" then
		return arr, i + 1
	end
	local n = 0
	while true do
		local v
		v, i = decodeAt(s, i)
		n = n + 1
		arr[n] = v
		i = skip(s, i)
		local c = s:sub(i, i)
		if c == "]" then
			return arr, i + 1
		elseif c ~= "," then
			decodeError(s, i, "expected , or ]")
		end
		i = skip(s, i + 1)
	end
end

local function decodeObject(s, i)
	local obj = {}
	i = skip(s, i + 1)
	if s:sub(i, i) == "}" then
		return obj, i + 1
	end
	while true do
		if s:sub(i, i) ~= '"' then
			decodeError(s, i, "expected string key")
		end
		local k
		k, i = decodeString(s, i)
		i = skip(s, i)
		if s:sub(i, i) ~= ":" then
			decodeError(s, i, "expected :")
		end
		local v
		v, i = decodeAt(s, skip(s, i + 1))
		obj[k] = v
		i = skip(s, i)
		local c = s:sub(i, i)
		if c == "}" then
			return obj, i + 1
		elseif c ~= "," then
			decodeError(s, i, "expected , or }")
		end
		i = skip(s, i + 1)
	end
end

decodeAt = function(s, i)
	i = skip(s, i)
	local c = s:sub(i, i)
	if c == "{" then
		return decodeObject(s, i)
	elseif c == "[" then
		return decodeArray(s, i)
	elseif c == '"' then
		return decodeString(s, i)
	elseif s:sub(i, i + 3) == "true" then
		return true, i + 4
	elseif s:sub(i, i + 4) == "false" then
		return false, i + 5
	elseif s:sub(i, i + 3) == "null" then
		return nil, i + 4
	end
	local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
	if num and #num > 0 then
		local n = tonumber(num)
		if n then
			return n, i + #num
		end
	end
	decodeError(s, i, "unexpected character '" .. c .. "'")
end

function json.decode(s)
	if type(s) ~= "string" then
		error("json: expected string, got " .. type(s))
	end
	local v, i = decodeAt(s, 1)
	i = skip(s, i)
	if i <= #s then
		decodeError(s, i, "trailing data")
	end
	return v
end

return json
