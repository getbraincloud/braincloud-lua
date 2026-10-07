-- App profile: a function(payload) -> lowercase hex MD5(payload .. value) that keeps the value
-- split, joining it only while signing. Same contract as the other SDKs' appProfile.

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local md5 = require(ROOT .. ".lib.md5")
local bit = require(ROOT .. ".lib.bit")
local Platform = require(ROOT .. ".platform.core")

local Profile = {}

local bxor = bit.bxor

-- Nil for an empty value: requests go unsigned.
function Profile.fromValue(value)
	if value == nil or value == "" then
		return nil
	end
	local n = #value
	local a, b = {}, {}
	for i = 1, n do
		a[i] = Platform.random(0, 255)
		b[i] = bxor(value:byte(i), a[i])
	end
	-- LÖVE's native MD5 when present (love.js runs plain Lua 5.1, where the Lua one is slow)
	local nativeMd5 = type(love) == "table" and love.data and love.data.hash
	return function(payload)
		local joined = {}
		if nativeMd5 then
			for i = 1, n do
				joined[i] = string.char(bxor(a[i], b[i]))
			end
			local digest = love.data.hash("md5", payload .. table.concat(joined))
			for i = 1, n do
				joined[i] = nil
			end
			return (digest:gsub(".", function(c)
				return string.format("%02x", c:byte())
			end))
		end
		for i = 1, n do
			joined[i] = string.char(bxor(a[i], b[i]))
		end
		local m = md5.new()
		m:update(payload)
		m:update(table.concat(joined))
		for i = 1, n do
			joined[i] = nil
		end
		return md5.tohex(m:finish())
	end
end

return Profile
