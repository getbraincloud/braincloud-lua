-- Finds the bundled native networking modules: LuaSec (ssl, OpenSSL linked in) for TLS sockets
-- and HTTPS, plus optional lua-https. LÖVE can't dlopen out of a .love zip, so those get copied
-- to the save directory first.

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local Platform = require(ROOT .. ".platform.core")

local Native = {}

local isLove = Platform.isLove
local folder -- braincloud/ folder: game-relative in LÖVE, filesystem path otherwise

if isLove then
	folder = ROOT:gsub("%.", "/")
else
	local path = package.searchpath and package.searchpath(ROOT .. ".client", package.path)
	folder = path and path:gsub("[/\\]client%.lua$", "") or ROOT:gsub("%.", "/")
end

local function platformDir()
	local os_ = Platform.osName
	local arch = jit and jit.arch or "x64"
	if os_ == "OS X" then
		return "macos", "so"
	elseif os_ == "Windows" then
		return arch == "x86" and "windows-x86" or "windows-x64", "dll"
	elseif os_ == "Linux" then
		return arch == "arm64" and "linux-arm64" or "linux-x64", "so"
	elseif os_ == "Android" then
		return "android-" .. arch, "so"
	end
	return nil
end

local function fileExists(path)
	local f = io.open(path, "rb")
	if f then
		f:close()
		return true
	end
	return false
end

-- Game-relative file → real filesystem path (extracting from a .love archive if needed).
local function realPath(rel)
	if not isLove then
		local p = folder .. "/" .. rel
		return fileExists(p) and p or nil
	end
	local gamePath = folder .. "/" .. rel
	if not love.filesystem.getInfo(gamePath) then
		return nil
	end
	local realDir = love.filesystem.getRealDirectory(gamePath)
	if realDir and fileExists(realDir .. "/" .. gamePath) then
		return realDir .. "/" .. gamePath
	end
	local saveRel = "braincloud-native/" .. rel
	-- recopy when the game ships a different build (e.g. after an app update)
	local saved = love.filesystem.getInfo(saveRel)
	if not saved or saved.size ~= love.filesystem.getInfo(gamePath).size then
		love.filesystem.createDirectory(saveRel:match("^(.*)/[^/]+$"))
		local data = love.filesystem.read(gamePath)
		if not data or not love.filesystem.write(saveRel, data) then
			return nil
		end
	end
	return love.filesystem.getSaveDirectory() .. "/" .. saveRel
end

function Native.readSource(rel)
	if isLove then
		return love.filesystem.read(folder .. "/" .. rel)
	end
	local f = io.open(folder .. "/" .. rel, "rb")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

local isWeb = isLove and love.system and love.system.getOS() == "Web"

local info
-- Paths/sources needed to stand up networking in this state or a love.thread.
function Native.info()
	if info then
		return info
	end
	info = {}
	if isWeb then
		return info -- browsers can't load native modules; the web bridge handles networking
	end
	local dir, ext = platformDir()
	if dir then
		info.sslPath = realPath("native/" .. dir .. "/ssl." .. ext)
		info.httpsPath = realPath("native/" .. dir .. "/https." .. ext)
	end
	info.cafile = realPath("native/cacert.pem")
	info.sslLua = Native.readSource("lib/luasec/ssl.lua")
	info.httpsLua = Native.readSource("lib/luasec/https.lua")
	return info
end

-- Installs ssl / ssl.https preloads from a Native.info() table. Source form so love.thread workers can run it too.
Native.INSTALL_SSL_SOURCE = [[
local cfg = ...
if package.loaded["ssl"] then return true end
-- iOS can't load .so files, so its LÖVE build links LuaSec in and preloads ssl.core itself
local static = package.preload["ssl.core"] ~= nil
if cfg.sslPath and not static then
	for _, m in ipairs({ "core", "context", "x509", "config" }) do
		local fn = package.loadlib(cfg.sslPath, "luaopen_ssl_" .. m)
		if not fn then return false end
		package.preload["ssl." .. m] = fn
	end
end
if cfg.sslPath or static then
	if cfg.sslLua then
		package.preload["ssl"] = function() return assert(loadstring(cfg.sslLua, "=ssl.lua"))() end
	end
	if cfg.httpsLua then
		package.preload["ssl.https"] = function() return assert(loadstring(cfg.httpsLua, "=ssl/https.lua"))() end
	end
end
return (pcall(require, "ssl"))
]]

function Native.installSsl(cfg)
	return assert(loadstring(Native.INSTALL_SSL_SOURCE, "=installSsl"))(cfg)
end

local sslReady
function Native.ssl()
	if sslReady == nil then
		sslReady = Native.installSsl(Native.info())
	end
	return sslReady and require("ssl") or nil
end


return Native
