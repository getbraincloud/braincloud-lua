local base64 = {}

local CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local ENC, DEC = {}, {}
for i = 1, 64 do
	local c = CHARS:sub(i, i)
	ENC[i - 1] = c
	DEC[c:byte()] = i - 1
end

function base64.encode(s)
	local out = {}
	for i = 1, #s, 3 do
		local a, b, c = s:byte(i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		out[#out + 1] = ENC[math.floor(n / 262144) % 64]
			.. ENC[math.floor(n / 4096) % 64]
			.. (b and ENC[math.floor(n / 64) % 64] or "=")
			.. (c and ENC[n % 64] or "=")
	end
	return table.concat(out)
end

function base64.decode(s)
	local out = {}
	local acc, bits = 0, 0
	for i = 1, #s do
		local v = DEC[s:byte(i)]
		if v then
			acc = (acc % 262144) * 64 + v
			bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				out[#out + 1] = string.char(math.floor(acc / 2 ^ bits) % 256)
			end
		end
	end
	return table.concat(out)
end

-- atob/btoa aliases
base64.btoa = base64.encode
base64.atob = base64.decode

return base64
