-- App profile: function(payload) -> lowercase hex MD5 request signature. Same contract as the other SDKs' appProfile.

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local md5 = require(ROOT .. ".lib.md5")
local bit = require(ROOT .. ".lib.bit")
local Platform = require(ROOT .. ".platform.core")

local Profile = {}

local x = bit.bxor

-- Nil for an empty value: requests go unsigned.
function Profile.fromValue(value)
	if value == nil or value == "" then
		return nil
	end
	local n = #value
	local p, q = {}, {}
	for i = 1, n do
		p[i] = Platform.random(0, 255)
		q[i] = x(value:byte(i), p[i])
	end
	-- LÖVE's native MD5 when present (love.js runs plain Lua 5.1, where the Lua one is slow)
	local nativeMd5 = type(love) == "table" and love.data and love.data.hash
	return function(payload)
		local t = {}
		for i = 1, n do
			t[i] = string.char(x(p[i], q[i]))
		end
		local s = table.concat(t)
		for i = 1, n do
			t[i] = nil
		end
		if nativeMd5 then
			local digest = love.data.hash("md5", payload .. s)
			return (digest:gsub(".", function(c)
				return string.format("%02x", c:byte())
			end))
		end
		local m = md5.new()
		m:update(payload)
		m:update(s)
		return md5.tohex(m:finish())
	end
end

return Profile
