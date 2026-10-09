-- BrainCloudWrapper: one client plus saved profile/anonymous ids, so anonymous and
-- reconnect logins resume the same profile across runs. Call wrapper:update() every frame.
--
--   local BrainCloud = require("braincloud")
--   local bc = BrainCloud.new("main")
--   bc:init()            -- reads braincloud_config.lua from the setup tool
--   bc:authenticateAnonymous(function(ok, response) ... end)
--   function love.update() bc:update() end

local ROOT = (...):match("^(.*)%.[^%.]+$")
local Client = require(ROOT .. ".client")
local Platform = require(ROOT .. ".platform.core")
local json = require(ROOT .. ".lib.json")

local Wrapper = {}

local function storageName(name)
	return "braincloud_" .. name:gsub("[^%w_%-]", "_") .. ".json"
end

function Wrapper.new(wrapperName)
	local self = setmetatable({}, Wrapper)
	self.wrapperName = wrapperName or "default"
	self._alwaysAllowProfileSwitch = true
	self._saved = { profileId = "", anonymousId = "" }
	self:_load()
	self.client = Client.new(nil, nil, nil, nil, false, self)
	return self
end

-- wrapper.leaderboard, wrapper.lobby ... resolve to the client's services.
Wrapper.__index = function(self, key)
	local v = rawget(Wrapper, key)
	if v ~= nil then
		return v
	end
	local client = rawget(self, "client")
	if client then
		local s = client[key]
		if type(s) == "table" and s.client == client then
			return s
		end
	end
	return nil
end

-- INIT

--- Initializes from braincloud_config.lua (written by the brainCloud setup tool).
--- Returns true on success.
function Wrapper:init(configModule)
	local name = configModule or "braincloud_config"
	local ok, cfg = pcall(require, name)
	if not ok or type(cfg) ~= "table" or not cfg.appId then
		if not ok and not tostring(cfg):find("module '" .. name .. "' not found", 1, true) then
			Platform.log("init(): " .. name .. " failed to load (regenerate it with the setup tool): " .. tostring(cfg))
		else
			Platform.log("init(): no " .. name .. ".lua found. Run the brainCloud setup tool, or call initialize().")
		end
		return false
	end
	-- Child apps in the config: load them too so switchToChildProfile can sign.
	local count = 0
	for _ in pairs(cfg.appProfiles or {}) do
		count = count + 1
	end
	if count > 1 then
		self:initializeWithApps(cfg.appId, cfg.appProfiles, cfg.appVersion, cfg.serverUrl)
		local ids = {}
		for i, id in ipairs(cfg.childAppIds or {}) do
			ids[i] = id
		end
		self._childAppIds = ids
	else
		self:initialize(cfg.appId, cfg.appProfile, cfg.appVersion, cfg.serverUrl)
	end
	return true
end

--- initialize(appId, secretKeyOrAppProfile, appVersion, serverUrl)
function Wrapper:initialize(appId, secretKeyOrProfile, appVersion, serverUrl)
	self.client:initialize(serverUrl, appId, secretKeyOrProfile, appVersion)
	self._childAppIds = {}
	self:_applySaved()
end

--- Multi-app init. secretMap = { [appId] = secretKeyOrAppProfile }.
function Wrapper:initializeWithApps(defaultAppId, secretMap, appVersion, serverUrl)
	self.client:initializeWithApps(serverUrl, defaultAppId, secretMap, appVersion)
	-- map order isn't kept; init() replaces this with the config's order
	local ids = {}
	for id in pairs(secretMap or {}) do
		if id ~= defaultAppId then
			ids[#ids + 1] = id
		end
	end
	self._childAppIds = ids
	self:_applySaved()
end

--- Child app ids from the last init, in config order (the setup panel's [0] is list[1]).
function Wrapper:getChildAppIdList()
	local out = {}
	for i, id in ipairs(self._childAppIds or {}) do
		out[i] = id
	end
	return out
end

function Wrapper:getBCClient()
	return self.client
end

--- Pumps networking and callbacks. Call every frame (love.update).
function Wrapper:update()
	self.client:update()
end

Wrapper.runCallbacks = Wrapper.update

-- SAVED IDS

function Wrapper:_load()
	local data = Platform.readFile(storageName(self.wrapperName))
	if data then
		local ok, t = pcall(json.decode, data)
		if ok and type(t) == "table" then
			self._saved.profileId = t.profileId or ""
			self._saved.anonymousId = t.anonymousId or ""
		end
	end
end

function Wrapper:_save()
	Platform.writeFile(storageName(self.wrapperName), json.encode(self._saved))
end

function Wrapper:_applySaved()
	if self._saved.anonymousId == "" then
		self._saved.anonymousId = self.client.authentication:generateAnonymousId()
		self:_save()
	end
	self.client.authentication:initialize(self._saved.profileId, self._saved.anonymousId)
end

function Wrapper:getStoredProfileId()
	return self._saved.profileId
end

function Wrapper:setStoredProfileId(profileId)
	self._saved.profileId = profileId or ""
	self:_save()
end

function Wrapper:resetStoredProfileId()
	self:setStoredProfileId("")
	self.client.authentication.profileId = ""
end

function Wrapper:getStoredAnonymousId()
	return self._saved.anonymousId
end

function Wrapper:setStoredAnonymousId(anonymousId)
	self._saved.anonymousId = anonymousId or ""
	self:_save()
end

function Wrapper:resetStoredAnonymousId()
	self:setStoredAnonymousId("")
	self.client.authentication.anonymousId = ""
end

--- When false, logging into a different profile than the saved one fails instead of switching.
function Wrapper:setAlwaysAllowProfileSwitch(allow)
	self._alwaysAllowProfileSwitch = allow == true
end

function Wrapper:getAlwaysAllowProfileSwitch()
	return self._alwaysAllowProfileSwitch
end

-- AUTHENTICATION

-- Saves the profile id on success, then forwards to the caller.
function Wrapper:_authCallback(callback)
	return function(success, response)
		if success and response and response.data then
			if response.data.profileId then
				self._saved.profileId = response.data.profileId
			end
			self:_save()
		end
		if callback then
			callback(success, response)
		end
	end
end

-- Profile id to send: the saved one, unless switching is allowed and this login isn't anonymous.
function Wrapper:_prepareAuth(isAnonymous)
	local auth = self.client.authentication
	if self._alwaysAllowProfileSwitch and not isAnonymous then
		auth:initialize("", self._saved.anonymousId)
		auth.profileId = ""
	else
		auth:initialize(self._saved.profileId, self._saved.anonymousId)
	end
	if self._saved.anonymousId == "" then
		self._saved.anonymousId = auth:generateAnonymousId()
		auth.anonymousId = self._saved.anonymousId
		self:_save()
	end
end

local STALE_PROFILE = { [40206] = true, [40208] = true }

function Wrapper:authenticateAnonymous(callback)
	self:_prepareAuth(true)
	local hadProfile = self._saved.profileId ~= ""
	self.client.authentication:authenticateAnonymous(true, function(success, response)
		-- the saved profile is gone (deleted elsewhere): start a fresh anonymous profile once
		if not success and hadProfile and response and STALE_PROFILE[response.reason_code] then
			self:onProfileDeleted()
			self:_prepareAuth(true)
			self.client.authentication:authenticateAnonymous(true, self:_authCallback(callback))
			return
		end
		self:_authCallback(callback)(success, response)
	end)
end

--- Forgets the saved ids after the profile is deleted.
function Wrapper:onProfileDeleted()
	self:resetStoredProfileId()
	self:resetStoredAnonymousId()
	self:_applySaved()
end

function Wrapper:authenticateAdvanced(authenticationType, ids, forceCreate, extraJson, callback)
	self:_prepareAuth(authenticationType == "Anonymous")
	self.client.authentication:authenticateAdvanced(authenticationType, ids, forceCreate, extraJson, self:_authCallback(callback))
end

-- authenticateX(args..., forceCreate, callback) pass-throughs.
local PASS_THROUGH = {
	"authenticateApple",
	"authenticateEmailPassword",
	"authenticateEpicGames",
	"authenticateExternal",
	"authenticateFacebook",
	"authenticateFacebookLimited",
	"authenticateGameCenter",
	"authenticateGoogle",
	"authenticateGoogleOpenId",
	"authenticateNintendo",
	"authenticateOculus",
	"authenticateParse",
	"authenticatePlaystationNetwork",
	"authenticatePlaystation5",
	"authenticateSteam",
	"authenticateTwitter",
	"authenticateUltra",
	"authenticateUniversal",
	"authenticateHandoff",
	"authenticateSettopHandoff",
}

for _, name in ipairs(PASS_THROUGH) do
	Wrapper[name] = function(self, ...)
		local args = { ... }
		local n = select("#", ...)
		local callback = args[n]
		if type(callback) == "function" or callback == nil then
			args[n] = self:_authCallback(callback)
		end
		self:_prepareAuth(false)
		local auth = self.client.authentication
		return auth[name](auth, unpack(args, 1, n))
	end
end

-- SMART SWITCH: deletes an anonymous-only profile (or logs out a signed one), then authenticates.

function Wrapper:_smartSwitch(callback, authenticate)
	local client = self.client
	if not client:isAuthenticated() then
		authenticate()
		return
	end
	client.identity:getIdentities(function(success, response)
		if not success then
			if callback then
				callback(false, response)
			end
			return
		end
		local identities = response.data and response.data.identities
		local function onDone(ok, r)
			if ok then
				authenticate()
			elseif callback then
				callback(false, r)
			end
		end
		if type(identities) == "table" and next(identities) == nil then
			client.playerState:deleteUser(function(ok, r)
				if ok then
					self:resetStoredProfileId()
					self:resetStoredAnonymousId()
					self:_applySaved()
				end
				onDone(ok, r)
			end)
		else
			client.playerState:logout(function(ok, r)
				if ok then
					self:resetStoredProfileId()
				end
				onDone(ok, r)
			end)
		end
	end)
end

function Wrapper:smartSwitchAuthenticateAdvanced(authenticationType, ids, forceCreate, extraJson, callback)
	self:_smartSwitch(callback, function()
		self:authenticateAdvanced(authenticationType, ids, forceCreate, extraJson, callback)
	end)
end

for _, name in ipairs(PASS_THROUGH) do
	local switchName = "smartSwitch" .. name:sub(1, 1):upper() .. name:sub(2)
	Wrapper[switchName] = function(self, ...)
		local args = { ... }
		local n = select("#", ...)
		self:_smartSwitch(args[n], function()
			self[name](self, unpack(args, 1, n))
		end)
	end
end
-- Name parity with the other wrappers.
Wrapper.smartSwitchAuthenticateEmail = Wrapper.smartSwitchAuthenticateEmailPassword

--- Re-authenticates anonymously with the saved ids (used by auto-reconnect).
function Wrapper:reconnect(callback)
	local auth = self.client.authentication
	auth:initialize(self._saved.profileId, self._saved.anonymousId)
	auth:authenticateAnonymous(false, self:_authCallback(callback))
end

--- Logs out. forgetUser clears the saved profile id so the next anonymous login makes a new profile.
function Wrapper:logout(forgetUser, callback)
	if forgetUser then
		self:resetStoredProfileId()
	end
	self.client.playerState:logout(callback)
end

-- PASSWORD RESETS

for _, name in ipairs({
	"resetEmailPassword",
	"resetEmailPasswordAdvanced",
	"resetEmailPasswordWithExpiry",
	"resetEmailPasswordAdvancedWithExpiry",
	"resetUniversalIdPassword",
	"resetUniversalIdPasswordAdvanced",
	"resetUniversalIdPasswordWithExpiry",
	"resetUniversalIdPasswordAdvancedWithExpiry",
}) do
	Wrapper[name] = function(self, ...)
		local auth = self.client.authentication
		return auth[name](auth, ...)
	end
end

return Wrapper
