-- Bit ops: LuaJIT's bit, else Lua 5.2's bit32. Results are unsigned 32-bit.

local ok, b = pcall(require, "bit")
if ok and b then
	local band, bor, bxor, lshift, rshift = b.band, b.bor, b.bxor, b.lshift, b.rshift
	local function u(x)
		return x % 4294967296
	end
	return {
		band = function(x, y) return u(band(x, y)) end,
		bor = function(x, y) return u(bor(x, y)) end,
		bxor = function(x, y) return u(bxor(x, y)) end,
		lshift = function(x, n) return u(lshift(x, n)) end,
		rshift = function(x, n) return u(rshift(x, n)) end,
	}
end

local okB32, b32 = pcall(require, "bit32")
b32 = bit32 or (okB32 and b32) or nil
if b32 then
	return {
		band = b32.band,
		bor = b32.bor,
		bxor = b32.bxor,
		lshift = b32.lshift,
		rshift = b32.rshift,
	}
end

-- Plain Lua 5.1 (love.js): arithmetic bit ops, a nibble at a time.
local NIB = {}
for a = 0, 15 do
	NIB[a] = {}
	for b = 0, 15 do
		local andv, orv, xorv, p, x, y = 0, 0, 0, 1, a, b
		for _ = 1, 4 do
			local xb, yb = x % 2, y % 2
			if xb == 1 and yb == 1 then
				andv = andv + p
			end
			if xb + yb >= 1 then
				orv = orv + p
			end
			if xb + yb == 1 then
				xorv = xorv + p
			end
			x, y, p = (x - xb) / 2, (y - yb) / 2, p * 2
		end
		NIB[a][b] = { andv, orv, xorv }
	end
end

local function op(which)
	return function(x, y)
		x, y = x % 4294967296, y % 4294967296
		local r, p = 0, 1
		for _ = 1, 8 do
			local xa, ya = x % 16, y % 16
			r = r + NIB[xa][ya][which] * p
			x, y, p = (x - xa) / 16, (y - ya) / 16, p * 16
		end
		return r
	end
end

return {
	band = op(1),
	bor = op(2),
	bxor = op(3),
	lshift = function(x, n)
		return (x * 2 ^ n) % 4294967296
	end,
	rshift = function(x, n)
		return math.floor((x % 4294967296) / 2 ^ n)
	end,
}
