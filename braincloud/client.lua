-- brainCloud client core: request bundling, packet ids, X-SIG signing, heartbeat, retries,
-- kill switch, session/auto-reconnect, event and reward callbacks.
-- Nothing blocks: call client:update() every frame (the wrapper does it for you).

local ROOT = (...):match("^(.*)%.[^%.]+$")

local json = require(ROOT .. ".lib.json")
local Profile = require(ROOT .. ".lib.profile")
local Platform = require(ROOT .. ".platform.core")
local Http = require(ROOT .. ".platform.http")
local Utils = require(ROOT .. ".util")
local ReasonCodes = require(ROOT .. ".reasoncodes")
local VERSION = require(ROOT .. ".version")

local Client = {}
Client.__index = Client

Client.VERSION = VERSION

local STATUS_CLIENT_NETWORK_ERROR = 900
local DEFAULT_URL = "https://api.braincloudservers.com/dispatcherv2"

-- field name → module under services/
local SERVICES = {
	{ "authentication", "authentication" },
	{ "asyncMatch", "async_match" },
	{ "blockchain", "blockchain" },
	{ "chat", "chat" },
	{ "customEntity", "custom_entity" },
	{ "dataStream", "data_stream" },
	{ "entity", "entity" },
	{ "event", "event" },
	{ "friend", "friend" },
	{ "gamification", "gamification" },
	{ "globalApp", "global_app" },
	{ "globalStatistics", "global_statistics" },
	{ "globalEntity", "global_entity" },
	{ "group", "group" },
	{ "identity", "identity" },
	{ "itemCatalog", "item_catalog" },
	{ "lobby", "lobby" },
	{ "mail", "mail" },
	{ "matchMaking", "match_making" },
	{ "messaging", "messaging" },
	{ "oneWayMatch", "one_way_match" },
	{ "playbackStream", "playback_stream" },
	{ "playerState", "player_state" },
	{ "playerStatistics", "player_statistics" },
	{ "playerStatisticsEvent", "player_statistics_event" },
	{ "presence", "presence" },
	{ "profanity", "profanity" },
	{ "pushNotification", "push_notification" },
	{ "redemptionCode", "redemption_code" },
	{ "time", "time" },
	{ "campaign", "campaign" },
	{ "script", "script" },
	{ "leaderboard", "leaderboard" },
	{ "tournament", "tournament" },
	{ "userItems", "user_items" },
	{ "virtualCurrency", "virtual_currency" },
	{ "appStore", "app_store" },
	{ "s3Handling", "s3_handling" },
	{ "file", "file" },
	{ "globalFile", "global_file" },
	{ "groupFile", "group_file" },
	{ "raw", "raw" },
	{ "rttService", "rtt" },
	{ "relay", "relay" },
}

local function toProfile(secretOrProfile)
	if type(secretOrProfile) == "function" then
		return secretOrProfile
	end
	return Profile.fromValue(secretOrProfile)
end

--- Client.new(appId, secretKeyOrAppProfile, appVersion, serverUrl, debug, wrapper)
function Client.new(appId, secretOrProfile, appVersion, serverUrl, debug, wrapper)
	local self = setmetatable({}, Client)

	self.clientLibVersion = VERSION
	self.releasePlatform = Platform.releasePlatform()
	self.appId = appId or ""
	self.appVersion = appVersion or ""
	self.serverUrl = DEFAULT_URL
	self:setServerUrl(serverUrl or DEFAULT_URL)
	self.wrapper = wrapper
	self.platform = Platform
	self.json = json

	self._appProfiles = {}
	self:_putProfile(self.appId, toProfile(secretOrProfile))

	self.sessionId = nil
	self.profileId = nil
	self.anonymousId = nil
	self.countryCode = nil
	self.languageCode = nil
	self.timeZoneOffset = nil

	self.debug = debug == true
	self._autoReconnect = false

	self._http = Http.new()

	self._sendQueue = {}
	self._inProgressQueue = {}
	self.packetId = 0
	self._jsonedQueue = nil
	self.MAX_REQUESTS_IN_BUNDLE = 10
	self._compressionThreshold = 51200
	self._lastRequestTime = 0

	self._idleTimeout = 30
	self._heartBeatActive = false

	self._packetTimeouts = { 15, 20, 35, 50 }
	self._authPacketTimeouts = { 15, 30, 60 }
	self._cacheMessagesOnNetworkError = false
	self._retry = 0
	self._retryAt = nil

	self._killSwitchThreshold = 11
	self._killSwitchEngaged = false
	self._killSwitchErrorCount = 0
	self._killSwitchService = ""
	self._killSwitchOperation = ""

	self._eventCallback = nil
	self._rewardCallback = nil
	self._errorCallback = nil
	self._globalErrorCallback = nil
	self._autoReconnectCallback = nil
	self._networkErrorCallback = nil

	self._isInitialized = true
	self._isAuthenticated = false
	self._requestInProgress = false
	self._deferred = {}

	for _, entry in ipairs(SERVICES) do
		local Service = require(ROOT .. ".services." .. entry[2])
		self[entry[1]] = Service.new(self)
	end

	local RTTComms = require(ROOT .. ".rtt_comms")
	local RelayComms = require(ROOT .. ".relay_comms")
	self.brainCloudRttComms = RTTComms.new(self)
	self.brainCloudRelayComms = RelayComms.new(self)

	self.reasonCodes = ReasonCodes

	self:debugLog("Client created", self.appId, self.serverUrl)
	return self
end

-- APP / SESSION CONFIG

function Client:_putProfile(appId, profile)
	if appId and appId ~= "" and profile then
		self._appProfiles[appId] = profile
	end
end

function Client:_profileFor(appId)
	local p = self._appProfiles[appId]
	if not p then
		-- a switched-to app with no value configured still signs, so the server returns a clear error
		p = Profile.fromValue("MISSING")
		self._appProfiles[appId] = p
	end
	return p
end

--- Re-initialize with one app. secretOrProfile = app secret string or appProfile function.
function Client:initialize(serverUrl, appId, secretOrProfile, appVersion)
	self:resetCommunication()
	self._appProfiles = {}
	self.appId = appId or self.appId
	self:_putProfile(self.appId, toProfile(secretOrProfile))
	self.appVersion = appVersion or self.appVersion
	self:setServerUrl(serverUrl or self.serverUrl)
end

--- Multi-app init (child/parent apps). appSecretMap = { [appId] = secretOrProfile }.
function Client:initializeWithApps(serverUrl, defaultAppId, appSecretMap, appVersion)
	self:resetCommunication()
	self._appProfiles = {}
	for id, v in pairs(appSecretMap or {}) do
		self:_putProfile(id, toProfile(v))
	end
	self.appId = defaultAppId
	self.appVersion = appVersion or self.appVersion
	self:setServerUrl(serverUrl or self.serverUrl)
end

function Client:setPlatform(platform)
	self.releasePlatform = platform or self.releasePlatform
end

function Client:enableAutoReconnect(enabled)
	self._autoReconnect = enabled == true
end

function Client:setSession(sessionId, profileId, anonymousId)
	self.sessionId = sessionId
	self.profileId = profileId or self.profileId
	self.anonymousId = anonymousId or self.anonymousId
	if sessionId and sessionId ~= "" then
		self._isAuthenticated = true
		self:startHeartBeat()
	else
		self._isAuthenticated = false
		self:stopHeartBeat()
	end
end

function Client:getSessionId()
	return self.sessionId
end

function Client:getProfileId()
	return self.profileId
end

function Client:getAppId()
	return self.appId
end

function Client:getAppVersion()
	return self.appVersion
end

function Client:getBrainCloudClientVersion()
	return self.clientLibVersion
end

function Client:isAuthenticated()
	return self._isAuthenticated
end

function Client:isInitialized()
	return self._isInitialized
end

function Client:setAppId(id)
	self.appId = id or self.appId
end

function Client:setAppSecret(secretOrProfile)
	self:_putProfile(self.appId, toProfile(secretOrProfile))
end

function Client:setServerUrl(url)
	if not url then
		return
	end
	url = url:gsub("/+$", "")
	if url:sub(-13):lower() == "/dispatcherv2" then
		url = url:sub(1, -14)
	end
	self.serverUrl = url .. "/dispatcherv2"
	self.baseUrl = url
end

function Client:getServerUrl()
	return self.serverUrl
end

function Client:setCountryCode(code)
	self.countryCode = code
end

function Client:setLanguageCode(code)
	self.languageCode = code
end

function Client:setTimeZoneOffset(offset)
	self.timeZoneOffset = offset
end

function Client:setPacketTimeouts(timeouts)
	self._packetTimeouts = timeouts
end

function Client:setAuthenticationPacketTimeouts(timeouts)
	self._authPacketTimeouts = timeouts
end

--- When enabled, calls that exhaust their retries stay queued: networkErrorCallback fires and
--- the app picks retryCachedMessages() or flushCachedMessages().
function Client:enableNetworkErrorMessageCaching(enabled)
	self._cacheMessagesOnNetworkError = enabled == true
end

function Client:setHeartbeatInterval(seconds)
	self._idleTimeout = seconds
end

function Client:isKillswitchEngaged()
	return self._killSwitchEngaged
end

-- CALLBACKS

function Client:registerEventCallback(fn)
	self._eventCallback = fn
end

function Client:deregisterEventCallback()
	self._eventCallback = nil
end

function Client:registerRewardCallback(fn)
	self._rewardCallback = fn
end

function Client:deregisterRewardCallback()
	self._rewardCallback = nil
end

function Client:registerAutoReconnectCallback(fn)
	self._autoReconnectCallback = fn
end

function Client:deregisterAutoReconnectCallback()
	self._autoReconnectCallback = nil
end

function Client:registerNetworkErrorCallback(fn)
	self._networkErrorCallback = fn
end

function Client:deregisterNetworkErrorCallback()
	self._networkErrorCallback = nil
end

function Client:setErrorCallback(fn)
	self._errorCallback = fn
end

--- fn(service, operation, statusCode, reasonCode, response) for every failed call.
function Client:registerGlobalErrorCallback(fn)
	self._globalErrorCallback = fn
end

function Client:deregisterGlobalErrorCallback()
	self._globalErrorCallback = nil
end

function Client:setDebugEnabled(enabled)
	self.debug = enabled == true
	if self.brainCloudRttComms then
		self.brainCloudRttComms:setDebugEnabled(self.debug)
	end
	if self.brainCloudRelayComms then
		self.brainCloudRelayComms:setDebugEnabled(self.debug)
	end
end

function Client:debugLog(...)
	if self.debug then
		Platform.log(...)
	end
end

local function safeCall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then
		Platform.log("callback error: " .. tostring(err))
	end
end

--- Runs fn on the next update(), for callbacks that must not fire synchronously.
function Client:defer(fn)
	self._deferred[#self._deferred + 1] = fn
end

-- KILL SWITCH

function Client:resetKillSwitch()
	self._killSwitchErrorCount = 0
	self._killSwitchService = ""
	self._killSwitchOperation = ""
	self._killSwitchEngaged = false
end

function Client:updateKillSwitch(service, operation, statusCode)
	if statusCode == STATUS_CLIENT_NETWORK_ERROR or not service or not operation then
		return
	end
	if self._killSwitchService == "" then
		self._killSwitchService = service
		self._killSwitchOperation = operation
		self._killSwitchErrorCount = self._killSwitchErrorCount + 1
	elseif self._killSwitchService == service and self._killSwitchOperation == operation then
		self._killSwitchErrorCount = self._killSwitchErrorCount + 1
	end
	if not self._killSwitchEngaged and self._killSwitchErrorCount >= self._killSwitchThreshold then
		self._killSwitchEngaged = true
		self:debugLog("Kill switch engaged for", service, operation)
	end
end

-- RESPONSES

function Client:fakeErrorResponse(statusCode, reasonCode, message)
	local responses = {}
	local n = math.max(1, #self._inProgressQueue)
	for i = 1, n do
		responses[i] = {
			status = statusCode,
			reason_code = reasonCode,
			status_message = message or "Error",
			severity = "ERROR",
		}
	end
	self:handleSuccessResponse({ responses = responses })
end

function Client:_clearSession()
	self._isAuthenticated = false
	self.sessionId = ""
	self:stopHeartBeat()
end

function Client:_handleRewards(queued, data)
	if not self._rewardCallback or not data then
		return
	end
	local rewards
	local s, op = queued.service, queued.operation
	if s == "authenticationV2" and op == "AUTHENTICATE" then
		if data.rewards and data.rewards.rewards then
			rewards = data.rewards
		end
	elseif s == "playerStatistics" and op == "UPDATE" then
		if data.rewards then
			rewards = data
		end
	elseif s == "playerStatisticsEvent" and (op == "TRIGGER" or op == "TRIGGER_MULTIPLE") then
		if data.rewards then
			rewards = data
		end
	end
	if rewards then
		safeCall(self._rewardCallback, rewards)
	end
end

function Client:_tryAutoReconnect(queued)
	if not (self._autoReconnect and self.wrapper and self.wrapper.reconnect) then
		return false
	end
	local expired = {}
	for _, call in ipairs(self._inProgressQueue) do
		if call.operation ~= "AUTHENTICATE" then
			expired[#expired + 1] = call
		end
	end
	self._inProgressQueue = {}
	self:_clearSession()
	self.packetId = 0
	self:debugLog("Session expired, re-authenticating")
	self.wrapper:reconnect(function(success, response)
		if not success then
			self._autoReconnect = false
			for _, call in ipairs(expired) do
				if call.callback then
					safeCall(call.callback, false, response)
				end
			end
			return
		end
		for i = #expired, 1, -1 do
			table.insert(self._sendQueue, 1, expired[i])
		end
		if self._autoReconnectCallback then
			safeCall(self._autoReconnectCallback, response)
		end
	end)
	return true
end

function Client:handleSuccessResponse(response)
	local messages = response.responses or {}
	local queue = self._inProgressQueue

	for i = 1, math.min(#queue, #messages) do
		local queued = queue[i]
		local msg = messages[i]
		local ok = msg ~= nil and msg.status == 200

		if self.debug then
			self:debugLog("Response(" .. tostring(msg and msg.status) .. ") " .. queued.service .. "." .. queued.operation .. ": " .. json.encode(msg or {}))
		end

		if not ok then
			local reason = msg and msg.reason_code
			if self._globalErrorCallback then
				safeCall(self._globalErrorCallback, queued.service, queued.operation, msg and msg.status, reason, msg)
			end
			if reason == ReasonCodes.PLAYER_SESSION_EXPIRED and self._isAuthenticated and self:_tryAutoReconnect(queued) then
				return
			end
			if reason == ReasonCodes.PLAYER_SESSION_EXPIRED
				or reason == ReasonCodes.NO_SESSION
				or reason == ReasonCodes.PLAYER_SESSION_LOGGED_OUT
			then
				self:_clearSession()
			end
			if queued.operation == "LOGOUT" and queued.service == "playerState" then
				self:_clearSession()
			end
			self:updateKillSwitch(queued.service, queued.operation, msg and msg.status)
		else
			local data = msg.data
			if data and (queued.service == "authenticationV2" or queued.service == "identity") then
				if data.sessionId then
					self.sessionId = data.sessionId
				end
				if data.profileId then
					self.profileId = data.profileId
				end
				if data.switchToAppId then
					self.appId = data.switchToAppId
				end
			end

			if queued.operation == "AUTHENTICATE" then
				-- RTT belongs to the previous profile's session
				if self._rttProfileId and data and data.profileId ~= self._rttProfileId then
					self.brainCloudRttComms:disableRTT()
				end
				self._rttProfileId = data and data.profileId
				self._isAuthenticated = true
				if data and data.playerSessionExpiry then
					self._idleTimeout = data.playerSessionExpiry * 0.85
				end
				if data and data.maxKillCount then
					self._killSwitchThreshold = data.maxKillCount
				end
				if data and data.maxBundleMsgs then
					self.MAX_REQUESTS_IN_BUNDLE = data.maxBundleMsgs
				end
				if data and data.compressIfLarger then
					self._compressionThreshold = data.compressIfLarger
				end
				self:resetKillSwitch()
				self:startHeartBeat()
			elseif queued.service == "playerState" and (queued.operation == "LOGOUT" or queued.operation == "FULL_PLAYER_RESET" or queued.operation == "DELETE") then
				self:_clearSession()
				self.packetId = 0
				self.brainCloudRttComms:disableRTT()
				self.brainCloudRelayComms:disconnect()
				-- the deleted profile's saved ids would otherwise resume a profile that no longer exists
				if queued.operation == "FULL_PLAYER_RESET" and self.wrapper and self.wrapper.onProfileDeleted then
					self.wrapper:onProfileDeleted()
				end
			end

			self:_handleRewards(queued, data)
		end

		if queued.callback then
			safeCall(queued.callback, ok, msg)
		end
	end

	local events = response.events
	if events and self._eventCallback then
		safeCall(self._eventCallback, { events = events })
	end
end

-- SENDING

function Client:sendRequest(service, operation, data, callback)
	table.insert(self._sendQueue, {
		service = service,
		operation = operation,
		data = Utils.emptyFix(data),
		callback = callback,
	})
end

--- Forces the queued calls so far into their own bundle.
function Client:insertEndOfMessageBundleMarker()
	table.insert(self._sendQueue, { operation = "END_BUNDLE_MARKER" })
end

local AUTH_OPS = {
	AUTHENTICATE = true,
	RESET_EMAIL_PASSWORD = true,
	RESET_EMAIL_PASSWORD_ADVANCED = true,
	RESET_EMAIL_PASSWORD_WITH_EXPIRY = true,
	RESET_EMAIL_PASSWORD_ADVANCED_WITH_EXPIRY = true,
	RESET_UNIVERSAL_ID_PASSWORD = true,
	RESET_UNIVERSAL_ID_PASSWORD_ADVANCED = true,
	RESET_UNIVERSAL_ID_PASSWORD_WITH_EXPIRY = true,
	RESET_UNIVERSAL_ID_PASSWORD_ADVANCED_WITH_EXPIRY = true,
	GET_SERVER_VERSION = true,
}

function Client:processQueue()
	if self._requestInProgress or self._waitingOnNetworkDecision or #self._sendQueue == 0 then
		return
	end

	-- AUTHENTICATE goes first and alone
	local authIndex
	for i, msg in ipairs(self._sendQueue) do
		if msg.operation == "AUTHENTICATE" then
			authIndex = i
			break
		end
	end
	local maxMessages = self.MAX_REQUESTS_IN_BUNDLE
	if authIndex then
		if authIndex ~= 1 then
			table.insert(self._sendQueue, 1, table.remove(self._sendQueue, authIndex))
		end
		maxMessages = 1
	end

	local bundle = {}
	while #self._sendQueue > 0 and #bundle < maxMessages do
		local msg = table.remove(self._sendQueue, 1)
		if msg.operation == "END_BUNDLE_MARKER" then
			if #bundle > 0 then
				break
			end
		else
			bundle[#bundle + 1] = msg
		end
	end
	if #bundle == 0 then
		return
	end
	self._inProgressQueue = bundle

	if self._killSwitchEngaged then
		self:fakeErrorResponse(STATUS_CLIENT_NETWORK_ERROR, ReasonCodes.CLIENT_DISABLED, "Client disabled due to repeated errors from a single API call")
		self._inProgressQueue = {}
		return
	end

	if not self._isAuthenticated then
		local allowed = false
		for _, q in ipairs(bundle) do
			if AUTH_OPS[q.operation] then
				allowed = true
				break
			end
		end
		if not allowed then
			self:fakeErrorResponse(403, ReasonCodes.NO_SESSION, "No session")
			self._inProgressQueue = {}
			return
		end
	end

	self.packetId = self.packetId + 1
	local messages = {}
	for i, q in ipairs(bundle) do
		messages[i] = { service = q.service, operation = q.operation, data = q.data }
	end
	local ok, body = pcall(json.encode, {
		messages = json.array(messages),
		gameId = self.appId,
		sessionId = self.sessionId or "",
		packetId = self.packetId,
	})
	if not ok then
		self:fakeErrorResponse(STATUS_CLIENT_NETWORK_ERROR, ReasonCodes.JSON_PARSING_ERROR or 0, "Failed to JSON encode request: " .. tostring(body))
		self._inProgressQueue = {}
		return
	end
	self:debugLog("Request: " .. body)

	self._jsonedQueue = body
	self._retry = 0
	self:performQuery()
end

function Client:buildHeaders(body)
	local headers = {
		["Content-Type"] = "application/json",
		["X-APPID"] = self.appId,
	}
	local profile = self:_profileFor(self.appId)
	if profile then
		headers["X-SIG"] = profile(body)
	end
	return headers
end

function Client:performQuery()
	self._requestInProgress = true
	self._lastRequestTime = Platform.now()
	local body = self._jsonedQueue
	local headers = self:buildHeaders(body)

	if self._compressionThreshold >= 0 and #body >= self._compressionThreshold then
		local packed = Platform.gzip(body)
		if packed then
			body = packed
			headers["Content-Encoding"] = "gzip"
		end
	end

	local packetId = self.packetId
	local timeouts = self:_timeoutsForPacket()
	local timeout = timeouts[self._retry + 1] or timeouts[#timeouts]
	self._http:request({
		url = self.serverUrl,
		method = "POST",
		headers = headers,
		body = body,
		timeout = timeout,
	}, function(code, responseBody, _, err)
		if packetId ~= self.packetId or not self._requestInProgress then
			return
		end
		self:_onHttpResponse(code, responseBody, err)
	end)
end

function Client:_timeoutsForPacket()
	local q = self._inProgressQueue
	if #q == 1 and q[1].operation == "AUTHENTICATE" then
		return self._authPacketTimeouts
	end
	return self._packetTimeouts
end

function Client:_onHttpResponse(code, body, err)
	if code == 200 then
		local ok, decoded = pcall(json.decode, body)
		if not ok or type(decoded) ~= "table" then
			self:debugLog("Bad JSON from server: " .. tostring(decoded))
			self:fakeErrorResponse(STATUS_CLIENT_NETWORK_ERROR, ReasonCodes.JSON_PARSING_ERROR or 0, "Invalid JSON response")
			self:_finishPacket()
			return
		end
		if decoded.packetId and decoded.packetId ~= -1 and decoded.packetId ~= self.packetId then
			self:debugLog("Dropping response for stale packet " .. tostring(decoded.packetId))
			return
		end
		self._retry = 0
		self:handleSuccessResponse(decoded)
		self:_finishPacket()
	elseif code == 0 or code == 502 or code == 503 or code == 504 then
		self:debugLog("Request failed (" .. tostring(code) .. "): " .. tostring(err))
		self:_scheduleRetry()
	else
		local reasonCode, message = 0, body
		local ok, decoded = pcall(json.decode, body or "")
		if ok and type(decoded) == "table" then
			reasonCode = decoded.reason_code or 0
			message = decoded.status_message or body
		end
		if self._errorCallback then
			safeCall(self._errorCallback, message)
		end
		self:fakeErrorResponse(code, reasonCode, message)
		self:_finishPacket()
	end
end

function Client:_finishPacket()
	self._requestInProgress = false
	self._inProgressQueue = {}
	self._retryAt = nil
end

function Client:_scheduleRetry()
	self._retry = self._retry + 1
	if self._retry < #self:_timeoutsForPacket() then
		self._retryAt = Platform.now() + 0.5 * self._retry
		return
	end
	if self._errorCallback then
		safeCall(self._errorCallback, "Request timed out after retries")
	end
	if self._cacheMessagesOnNetworkError then
		-- keep the packet; retryCachedMessages()/flushCachedMessages() decide
		self._requestInProgress = false
		self._retryAt = nil
		self._waitingOnNetworkDecision = true
		if self._networkErrorCallback then
			safeCall(self._networkErrorCallback)
		end
		return
	end
	if self._networkErrorCallback then
		safeCall(self._networkErrorCallback)
	end
	self:fakeErrorResponse(STATUS_CLIENT_NETWORK_ERROR, ReasonCodes.CLIENT_NETWORK_ERROR_TIMEOUT, "Request timed out")
	self:_finishPacket()
end

--- Retries an exhausted request once more (after a network error callback).
function Client:retryCachedMessages()
	if self._waitingOnNetworkDecision and #self._inProgressQueue > 0 then
		self._waitingOnNetworkDecision = false
		self._retry = 0
		self:performQuery()
	end
end

--- Drops queued calls after a network error.
function Client:flushCachedMessages(sendApiErrorCallbacks)
	if sendApiErrorCallbacks then
		local all = {}
		for _, q in ipairs(self._inProgressQueue) do
			all[#all + 1] = q
		end
		for _, q in ipairs(self._sendQueue) do
			if q.operation ~= "END_BUNDLE_MARKER" then
				all[#all + 1] = q
			end
		end
		self._inProgressQueue = all
		self:fakeErrorResponse(STATUS_CLIENT_NETWORK_ERROR, ReasonCodes.CLIENT_NETWORK_ERROR_TIMEOUT, "Request timed out")
	end
	self._waitingOnNetworkDecision = false
	self._sendQueue = {}
	self._inProgressQueue = {}
end

-- FILE UPLOADS

--- Multipart POST of an already-prepared upload to the uploader. callback(code, body).
function Client:uploadFile(uploadId, fileName, data, callback, peerCode)
	local boundary = "----braincloud" .. Platform.uuid():gsub("-", "")
	local parts = {}
	local function field(name, value)
		parts[#parts + 1] = "--" .. boundary .. "\r\nContent-Disposition: form-data; name=\"" .. name .. "\"\r\n\r\n" .. tostring(value) .. "\r\n"
	end
	field("sessionId", self.sessionId or "")
	if peerCode then
		field("peerCode", peerCode)
	end
	field("uploadId", uploadId)
	field("fileSize", #data)
	parts[#parts + 1] = "--" .. boundary .. "\r\nContent-Disposition: form-data; name=\"uploadFile\"; filename=\"" .. fileName
		.. "\"\r\nContent-Type: application/octet-stream\r\n\r\n" .. data .. "\r\n--" .. boundary .. "--\r\n"
	self._http:request({
		url = self.baseUrl .. "/uploader",
		method = "POST",
		headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
		body = table.concat(parts),
		timeout = 120,
	}, function(code, body)
		if callback then
			safeCall(callback, code, body)
		end
	end)
end

-- HEARTBEAT

function Client:startHeartBeat()
	self._heartBeatActive = true
end

function Client:stopHeartBeat()
	self._heartBeatActive = false
end

function Client:heartbeat(callback)
	self:sendRequest("heartbeat", "READ", nil, callback)
end

function Client:_updateHeartBeat(now)
	if not (self._heartBeatActive and self._isAuthenticated) then
		return
	end
	if self._requestInProgress or #self._sendQueue > 0 then
		return
	end
	if now - self._lastRequestTime >= self._idleTimeout then
		self._lastRequestTime = now
		self:heartbeat()
	end
end

--- Pumps networking and fires callbacks. Call every frame.
function Client:update()
	local now = Platform.now()

	if #self._deferred > 0 then
		local deferred = self._deferred
		self._deferred = {}
		for _, fn in ipairs(deferred) do
			safeCall(fn)
		end
	end

	self._http:update()

	if self._retryAt and now >= self._retryAt then
		self._retryAt = nil
		self:performQuery()
	end

	self:processQueue()
	self:_updateHeartBeat(now)

	self.brainCloudRttComms:update(now)
	self.brainCloudRelayComms:update(now)
	if self.lobby and self.lobby.update then
		self.lobby:update(now)
	end
end

-- Kept for parity with the C++/C# runCallbacks().
Client.runCallbacks = Client.update

function Client:resetCommunication()
	self:stopHeartBeat()
	self._sendQueue = {}
	self._inProgressQueue = {}
	self.sessionId = ""
	self.packetId = 0
	self._isAuthenticated = false
	self._requestInProgress = false
	self._retryAt = nil
	self:resetKillSwitch()
	if self.brainCloudRttComms then
		self.brainCloudRttComms:disableRTT()
	end
	if self.brainCloudRelayComms then
		self.brainCloudRelayComms:disconnect()
	end
end

function Client:shutdown()
	self:resetCommunication()
	self._http:shutdown()
end

return Client
