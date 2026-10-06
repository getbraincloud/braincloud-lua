-- Engine adapter: LÖVE 11.4+/12 when `love` is present, plain LuaJIT + LuaSocket otherwise.

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Platform = {}

local isLove = type(love) == "table" and love.filesystem ~= nil
Platform.isLove = isLove
Platform.root = ROOT

local okSocket, socketModule = pcall(require, "socket")
local socket = okSocket and socketModule or nil
Platform.socket = socket

function Platform.now()
	if socket then
		return socket.gettime()
	end
	if isLove and love.timer then
		return love.timer.getTime()
	end
	return os.time()
end

function Platform.sleep(seconds)
	if socket then
		socket.sleep(seconds)
	end
end

local function hostOS()
	if isLove and love.system then
		return love.system.getOS()
	end
	local os_ = jit and jit.os or ""
	if os_ == "OSX" then
		return "OS X"
	end
	return os_
end

Platform.osName = hostOS()

local RELEASE_PLATFORMS = {
	["OS X"] = "MAC",
	Windows = "WINDOWS",
	Linux = "LINUX",
	Android = "ANG",
	iOS = "IOS",
	Web = "WEB",
}

function Platform.releasePlatform()
	return RELEASE_PLATFORMS[Platform.osName] or "UNKNOWN"
end

function Platform.engineName()
	if isLove then
		local major, minor, rev = love.getVersion()
		return string.format("LOVE %d.%d.%d", major, minor, rev)
	end
	return (jit and jit.version) or _VERSION
end

function Platform.loveMajor()
	if isLove then
		return (love.getVersion())
	end
	return 0
end

-- Randomness: love.math when available (seeded per run), else math.random seeded once here.
local seeded = false
local function rand(lo, hi)
	if isLove and love.math then
		return love.math.random(lo, hi)
	end
	if not seeded then
		seeded = true
		math.randomseed(math.floor((Platform.now() % 1) * 1e9) + os.time())
		for _ = 1, 10 do
			math.random()
		end
	end
	return math.random(lo, hi)
end
Platform.random = rand

function Platform.randomBytes(n)
	local t = {}
	for i = 1, n do
		t[i] = string.char(rand(0, 255))
	end
	return table.concat(t)
end

function Platform.uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (template:gsub("[xy]", function(c)
		local v = c == "x" and rand(0, 15) or rand(8, 11)
		return string.format("%x", v)
	end))
end

-- Compression is optional: requests go uncompressed when nothing can gzip.
function Platform.gzip(data)
	if isLove and love.data and love.data.compress then
		local ok, out = pcall(love.data.compress, "string", "gzip", data)
		if ok then
			return out
		end
	end
	return nil
end

function Platform.gunzip(data)
	if isLove and love.data and love.data.decompress then
		local ok, out = pcall(love.data.decompress, "string", "gzip", data)
		if ok then
			return out
		end
	end
	return nil
end

function Platform.canGunzip()
	return isLove and love.data ~= nil and love.data.decompress ~= nil
end

-- language, country from the client override, else the OS locale (LANG=en_US.UTF-8), else en/US.
function Platform.locale(client)
	local lang = client and client.languageCode
	local country = client and client.countryCode
	if not (lang and country) then
		local env = os.getenv("LC_ALL") or os.getenv("LANG") or ""
		local l, c = env:match("^(%a%a)[_%-](%a%a)")
		lang = lang or (l and l:lower()) or "en"
		country = country or (c and c:upper()) or "US"
	end
	return lang, country
end

-- Hours east of UTC.
function Platform.timeZoneOffset(client)
	if client and client.timeZoneOffset then
		return client.timeZoneOffset
	end
	local now = os.time()
	return os.difftime(now, os.time(os.date("!*t", now))) / 3600
end

-- Small persistent key/value files (saved profile/anonymous ids).
local memoryStore = {}

function Platform.readFile(name)
	if isLove then
		if love.filesystem.getInfo(name) then
			return love.filesystem.read(name)
		end
		return nil
	end
	if Platform.storageDir then
		local f = io.open(Platform.storageDir .. "/" .. name, "rb")
		if f then
			local data = f:read("*a")
			f:close()
			return data
		end
		return nil
	end
	return memoryStore[name]
end

function Platform.writeFile(name, data)
	if isLove then
		return love.filesystem.write(name, data)
	end
	if Platform.storageDir then
		local f = io.open(Platform.storageDir .. "/" .. name, "wb")
		if f then
			f:write(data)
			f:close()
			return true
		end
		return false
	end
	memoryStore[name] = data
	return true
end

function Platform.removeFile(name)
	if isLove then
		return love.filesystem.remove(name)
	end
	if Platform.storageDir then
		return os.remove(Platform.storageDir .. "/" .. name)
	end
	memoryStore[name] = nil
	return true
end

--- Reads a file by path: game-relative/save dir in LÖVE, filesystem path otherwise.
function Platform.readLocalFile(path)
	if isLove and love.filesystem.getInfo(path) then
		return love.filesystem.read(path)
	end
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

function Platform.log(...)
	print("[brainCloud]", ...)
end

return Platform
