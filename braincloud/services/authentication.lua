local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local json = require(ROOT .. ".lib.json")
local Platform = require(ROOT .. ".platform.core")

---@class Authentication
---@field client table brainCloud client instance
---@field compressResponses boolean
---@field profileId string
---@field anonymousId string
---@field previousAuthParams table
local Authentication = {}
Authentication.__index = Authentication


---@private
local SERVICE = "authenticationV2"

---@private
---@type table<string, string>
local OPS = {
	AUTHENTICATE = "AUTHENTICATE",
	RESET_EMAIL_PASSWORD = "RESET_EMAIL_PASSWORD",
	RESET_EMAIL_PASSWORD_ADVANCED = "RESET_EMAIL_PASSWORD_ADVANCED",
	RESET_EMAIL_PASSWORD_WITH_EXPIRY = "RESET_EMAIL_PASSWORD_WITH_EXPIRY",
	RESET_EMAIL_PASSWORD_ADVANCED_WITH_EXPIRY = "RESET_EMAIL_PASSWORD_ADVANCED_WITH_EXPIRY",
	RESET_UNIVERSAL_ID_PASSWORD = "RESET_UNIVERSAL_ID_PASSWORD",
	RESET_UNIVERSAL_ID_PASSWORD_ADVANCED = "RESET_UNIVERSAL_ID_PASSWORD_ADVANCED",
	RESET_UNIVERSAL_ID_PASSWORD_WITH_EXPIRY = "RESET_UNIVERSAL_ID_PASSWORD_WITH_EXPIRY",
	RESET_UNIVERSAL_ID_PASSWORD_ADVANCED_WITH_EXPIRY = "RESET_UNIVERSAL_ID_PASSWORD_ADVANCED_WITH_EXPIRY",
	GET_SERVER_VERSION = "GET_SERVER_VERSION",
}

---@private
---@enum AuthType
local AuthType = {
	ANONYMOUS = "Anonymous",
	EMAIL = "Email",
	EXTERNAL = "External",
	FACEBOOK = "Facebook",
	FACEBOOK_LIMITED = "FacebookLimited",
	OCULUS = "Oculus",
	PLAYSTATION_NETWORK = "PlaystationNetwork",
	PLAYSTATION_NETWORK5 = "PlaystationNetwork5",
	NINTENDO = "Nintendo",
	GOOGLE = "Google",
	GOOGLE_OPEN_ID = "GoogleOpenId",
	APPLE = "Apple",
	EPIC_GAMES = "EpicGames",
	ULTRA = "Ultra",
	UNIVERSAL = "Universal",
	GAME_CENTER = "GameCenter",
	STEAM = "Steam",
	BLOCKCHAIN = "Blockchain",
	TWITTER = "Twitter",
	PARSE = "Parse",
	HANDOFF = "Handoff",
	SETTOP_HANDOFF = "SettopHandoff",
}

---@private
---@param client table
---@vararg any
local function debugLog(client, ...)
	if client and client.debug then
		print("[BrainCloud][AUTH]", ...)
	end
end

--- Constructor

---@param baseClient table brainCloud client instance
---@return Authentication
function Authentication.new(baseClient)
	local self = setmetatable({}, Authentication)
	self.client = baseClient

	self.compressResponses = Platform.canGunzip()
	self.profileId = ""
	self.anonymousId = ""
	self.previousAuthParams = {
		externalId = "",
		authenticationToken = "",
		authenticationType = "",
		externalAuthName = "",
		forceCreate = true,
		extraJson = "",
	}

	return self
end

--- SESSION HANDLING UTILS

---@private
---@param selfRef Authentication
---@param client table
---@param response table
local function saveSessionFromResponse(selfRef, client, response)
	if not response then
		return
	end
	local d = response.data
	if d then
		local sid = d.sessionId or d._sessionId or d._sessionid or d._sessionID
		local pid = d.profileId or d.profileID or d.profileid
		local aid = d.anonymousId or d.anonymousID or d.anonymousid or selfRef.anonymousId
		selfRef:initialize(pid, aid)
		if client and client.setSession then
			client:setSession(sid, pid, aid)
		end
	end
end

---@private
--- Used to create the anonymous installation id for the brainCloud profile.
--- @returns A unique Anonymous ID
local function generateAnonymousId()
	return Platform.uuid()
end

--- Low-level auth request wrapper

---@private
---@param operation string
---@param data table
---@param callback fun(success: boolean, response: table|nil)
function Authentication:_sendAuthRequest(operation, data, callback)
	if operation == OPS.AUTHENTICATE then
		local languageCode, countryCode = Platform.locale(self.client)
		data.languageCode = data.languageCode or languageCode
		data.countryCode = data.countryCode or countryCode
		data.timeZoneOffset = data.timeZoneOffset or Platform.timeZoneOffset(self.client)
	end
	debugLog(self.client, "Sending auth request:", operation, json.encode(data or {}))
	self.client:sendRequest(SERVICE, operation, data, function(success, response)
		if success then
			pcall(function()
				saveSessionFromResponse(self, self.client, response)
			end)
		end
		if callback then
			callback(success, response)
		end
	end)
end

--- Initialization / helpers

--- Initialize - initializes the identity service with a saved
--- anonymous installation id and most recently used profile id
--- @param anonymousId The anonymous installation id that was generated for this device
--- @param profileId The id of the profile id that was most recently used by the app (on this device)
function Authentication:initialize(profileId, anonymousId)
	self.anonymousId = anonymousId or self.anonymousId
	self.profileId = profileId or self.profileId
	debugLog(self.client, "Authentication initialized. profileId:", self.profileId, "anonymousId:", self.anonymousId)
end

--- Used to create the anonymous installation id for the brainCloud profile.
--- @returns A unique Anonymous ID
function Authentication:generateAnonymousId()
	return generateAnonymousId()
end

function Authentication:clearSavedProfileId()
	self.profileId = ""
	debugLog(self.client, "Cleared saved profileId")
end

function Authentication:clearSavedSession()
	if self.client and self.client.setSession then
		self.client:setSession(nil, nil, nil)
	end
	self.profileId = ""
	self.anonymousId = ""
	debugLog(self.client, "Cleared saved session locally")
end

--- AUTHENTICATION: generic + typed helpers

--- A generic Authenticate method that translates to the same as calling a specific one, except it takes an extraJson
-- that will be passed along to pre- or post- hooks.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param authenticationType Universal, Email, Facebook, etc
-- @param ids Auth IDs structure
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param extraJson Additional to piggyback along with the call, to be picked up by pre- or post- hooks. Leave empty string for no extraJson.
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateAdvanced(authenticationType, ids, forceCreate, extraJson, callback)
	local externalId = tostring(ids.externalId or "")
	local authenticationToken = tostring(ids.authenticationToken or "")
	local authenticationSubType = ids.authenticationSubType

	self.previousAuthParams.externalId = externalId
	self.previousAuthParams.authenticationToken = authenticationToken
	self.previousAuthParams.authenticationType = authenticationType
	self.previousAuthParams.externalAuthName = authenticationSubType
	self.previousAuthParams.forceCreate = forceCreate
	self.previousAuthParams.extraJson = extraJson

	local languageCode, countryCode = Platform.locale(self.client)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
		forceCreate = forceCreate == true,
		compressResponses = self.compressResponses,
		anonymousId = self.anonymousId,
		profileId = self.profileId,
		timeZoneOffset = Platform.timeZoneOffset(self.client),
		languageCode = languageCode,
		countryCode = countryCode,
		clientLib = "lua",
		releasePlatform = self.client.releasePlatform,
		clientLibVersion = self.client.clientLibVersion,
		gameVersion = self.client and self.client.appVersion or nil,
	}
	if authenticationSubType then
		data.externalAuthName = tostring(authenticationSubType)
	end
	if extraJson then
		data.extraJson = extraJson
	end

	self:_sendAuthRequest(OPS.AUTHENTICATE, data, callback)
end

---@param callback fun(success: boolean, response: table|nil)
function Authentication:retryPreviousAuthenticate(callback)
	local p = self.previousAuthParams
	self:authenticateAdvanced(p.authenticationType or "", {
		externalId = p.externalId,
		authenticationToken = p.authenticationToken,
		authenticationSubType = p.externalAuthName,
	}, p.forceCreate, p.extraJson, callback)
end

--- Provider-specific authentication methods

--- Authenticate a user anonymously with brainCloud - used for apps that don't want to bother
-- the user to login, or for users who are sensitive to their privacy
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param forceCreate Should a new profile be created if it does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateAnonymous(forceCreate, callback)
	if not self.anonymousId or self.anonymousId == "" then
		self.anonymousId = self:generateAnonymousId()
	end
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(self.anonymousId or ""),
		authenticationToken = self:generateAnonymousId(),
		authenticationType = AuthType.ANONYMOUS,
		forceCreate = forceCreate == true,
		compressResponses = self.compressResponses,
		anonymousId = self.anonymousId,
		profileId = self.profileId,
		clientLib = "lua",
		releasePlatform = self.client.releasePlatform,
		clientLibVersion = self.client.clientLibVersion,
		gameVersion = self.client and self.client.appVersion or nil,
	}
	self.previousAuthParams.externalId = data.externalId
	self.previousAuthParams.authenticationToken = ""
	self.previousAuthParams.authenticationType = AuthType.ANONYMOUS
	self.previousAuthParams.externalAuthName = nil
	self.previousAuthParams.forceCreate = forceCreate == true
	self.previousAuthParams.extraJson = ""
	self:_sendAuthRequest(OPS.AUTHENTICATE, data, callback)
end

--- Authenticate the user using a userid and password (without any validation on the userid).
-- Similar to AuthenticateEmailPassword - except that that method has additional features to
-- allow for e-mail validation, password resets, etc.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param email The e-mail address of the user
-- @param password The password of the user
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateUniversal(username, password, forceCreate, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(username),
		authenticationToken = tostring(password),
		authenticationType = AuthType.UNIVERSAL,
		forceCreate = forceCreate == true,
		compressResponses = self.compressResponses,
		anonymousId = self.anonymousId,
		profileId = self.profileId,
		clientLib = "lua",
		releasePlatform = self.client.releasePlatform,
		clientLibVersion = self.client.clientLibVersion,
		gameVersion = self.client and self.client.appVersion or nil,
	}
	self.previousAuthParams.externalId = data.externalId
	self.previousAuthParams.authenticationToken = data.authenticationToken
	self.previousAuthParams.authenticationType = AuthType.UNIVERSAL
	self.previousAuthParams.forceCreate = forceCreate == true
	self.previousAuthParams.extraJson = ""
	self:_sendAuthRequest(OPS.AUTHENTICATE, data, callback)
end

--- Authenticate the user with a custom Email and Password.  Note that the client app
-- is responsible for collecting (and storing) the e-mail and potentially password
-- (for convenience) in the client data.  For the greatest security,
-- force the user to re-enter their * password at each login.
-- (Or at least give them that option).
-- Note that the password sent from the client to the server is protected via SSL.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param email The e-mail address of the user
-- @param password The password of the user
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateEmailPassword(email, password, forceCreate, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(email),
		authenticationToken = tostring(password),
		authenticationType = AuthType.EMAIL,
		forceCreate = forceCreate == true,
		compressResponses = self.compressResponses,
		anonymousId = self.anonymousId,
		profileId = self.profileId,
		clientLib = "lua",
		releasePlatform = self.client.releasePlatform,
		clientLibVersion = self.client.clientLibVersion,
		gameVersion = self.client and self.client.appVersion or nil,
	}
	--- store previous params
	self.previousAuthParams.externalId = data.externalId
	self.previousAuthParams.authenticationToken = data.authenticationToken
	self.previousAuthParams.authenticationType = AuthType.EMAIL
	self.previousAuthParams.forceCreate = forceCreate == true
	self.previousAuthParams.extraJson = ""

	self:_sendAuthRequest(OPS.AUTHENTICATE, data, callback)
end

--- Authenticate the user via cloud code (which in turn validates the supplied credentials against an external system).
-- This allows the developer to extend brainCloud authentication to support other backend authentication systems.
-- Service Name - authenticationV2
-- Service Operation - Authenticate
-- 
-- @param userId The user id
-- @param token The user token (password etc)
-- @param externalAuthName The name of the cloud script to call for external authentication
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateExternal(externalId, token, externalAuthName, forceCreate, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(externalId),
		authenticationToken = tostring(token),
		externalAuthName = tostring(externalAuthName),
		authenticationType = AuthType.EXTERNAL,
		forceCreate = forceCreate == true,
		compressResponses = self.compressResponses,
		anonymousId = self.anonymousId,
		profileId = self.profileId,
		clientLib = "lua",
		releasePlatform = self.client.releasePlatform,
		clientLibVersion = self.client.clientLibVersion,
		gameVersion = self.client and self.client.appVersion or nil,
	}
	--- store previous params
	self.previousAuthParams.externalId = data.externalId
	self.previousAuthParams.authenticationToken = data.authenticationToken
	self.previousAuthParams.authenticationType = AuthType.EXTERNAL
	self.previousAuthParams.externalAuthName = externalAuthName
	self.previousAuthParams.forceCreate = forceCreate == true
	self.previousAuthParams.extraJson = ""

	self:_sendAuthRequest(OPS.AUTHENTICATE, data, callback)
end

--- Authenticate the user with brainCloud using their Facebook Credentials
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param fbUserId The facebook id of the user
-- @param fbAuthToken The validated token from the Facebook SDK
--        (that will be further validated when sent to the bC service)
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateFacebook(facebookId, facebookToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.FACEBOOK,
		{ externalId = facebookId, authenticationToken = facebookToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateFacebookLimited(facebookLimitedId, facebookToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.FACEBOOK_LIMITED,
		{ externalId = facebookLimitedId, authenticationToken = facebookToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateApple(appleUserId, identityToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.APPLE,
		{ externalId = appleUserId, authenticationToken = identityToken },
		forceCreate,
		nil,
		callback
	)
end

--- Authenticate the user using an epicAccountId and their authIdToken.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
--
-- @param epicAccountId LocalUserId retrieved from the EOS AuthInterface's Login method.
-- @param authIdToken IdToken string from the EOS AuthInterface's CopyIdToken method.
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
--
function Authentication:authenticateEpicGames(epicAccountId, authIdToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.EPIC_GAMES,
		{ externalId = epicAccountId, authenticationToken = authIdToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateGoogle(googleUserId, serverAuthCode, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.GOOGLE,
		{ externalId = googleUserId, authenticationToken = serverAuthCode },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateGoogleOpenId(googleUserAccountEmail, idToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.GOOGLE_OPEN_ID,
		{ externalId = googleUserAccountEmail, authenticationToken = idToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateGameCenter(gameCenterId, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.GAME_CENTER,
		{ externalId = gameCenterId, authenticationToken = "" },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateUltra(ultraUsername, ultraIdToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.ULTRA,
		{ externalId = ultraUsername, authenticationToken = ultraIdToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateSteam(userId, sessionTicket, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.STEAM,
		{ externalId = userId, authenticationToken = sessionTicket },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateTwitter(userId, token, secret, forceCreate, callback)
	local tokenConcat = tostring(token) .. ":" .. tostring(secret)
	self:authenticateAdvanced(
		AuthType.TWITTER,
		{ externalId = userId, authenticationToken = tokenConcat },
		forceCreate,
		nil,
		callback
	)
end

--- Authenticate the user with brainCloud using their Oculus Credentials
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
-- 
-- @param oculusUserId The oculus id of the user
-- @param oculusNonce Oculus token from the Oculus SDK
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:authenticateOculus(oculusId, oculusNonce, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.OCULUS,
		{ externalId = oculusId, authenticationToken = oculusNonce },
		forceCreate,
		nil,
		callback
	)
end

--- Authenticate the user using their PSN account id and an auth token.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
--
-- @param accountId The user's PSN account id
-- @param authToken The user's PSN auth token
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
--
function Authentication:authenticatePlaystationNetwork(accountId, authToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.PLAYSTATION_NETWORK,
		{ externalId = accountId, authenticationToken = authToken },
		forceCreate,
		nil,
		callback
	)
end

--- Authenticate the user using their PS5 account id and an auth token.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
--
-- @param accountId The user's PSN account id
-- @param authToken The user's PSN auth token
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
--
function Authentication:authenticatePlaystation5(accountId, authToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.PLAYSTATION_NETWORK5,
		{ externalId = accountId, authenticationToken = authToken },
		forceCreate,
		nil,
		callback
	)
end

--- Authenticate the user using their Nintendo account id and an auth token.
-- Service Name - authenticationV2
-- Service Operation - AUTHENTICATE
--
-- @param accountId The user's Nintendo account id
-- @param authToken The user's Nintendo auth token
-- @param forceCreate Should a new profile be created for this user if the account does not exist?
-- @param callback The method to be invoked when the server response is received
--
function Authentication:authenticateNintendo(accountId, authToken, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.NINTENDO,
		{ externalId = accountId, authenticationToken = authToken },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateParse(userId, token, forceCreate, callback)
	self:authenticateAdvanced(
		AuthType.PARSE,
		{ externalId = userId, authenticationToken = token },
		forceCreate,
		nil,
		callback
	)
end

function Authentication:authenticateHandoff(handoffId, securityToken, callback)
	self:authenticateAdvanced(
		AuthType.HANDOFF,
		{ externalId = handoffId, authenticationToken = securityToken },
		false,
		nil,
		callback
	)
end

function Authentication:authenticateSettopHandoff(handoffCode, callback)
	self:authenticateAdvanced(
		AuthType.SETTOP_HANDOFF,
		{ externalId = handoffCode, authenticationToken = "" },
		false,
		nil,
		callback
	)
end

--- Reset Email password - Sends a password reset email to the specified address
-- Service Name - authenticationV2
-- Service Operation - ResetEmailPassword
-- 
-- @param externalId The email address to send the reset email to.
-- @param callback The method to be invoked when the server response is received
--        Note the follow error reason codes:
--        SECURITY_ERROR (40209) - If the email address cannot be found.
-- 
function Authentication:resetEmailPassword(email, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(email),
	}
	debugLog(self.client, "ResetEmailPassword payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_EMAIL_PASSWORD, data, function(success, response)
		if callback then
			callback(success, response)
		end
	end)
end

function Authentication:resetEmailPasswordAdvanced(emailAddress, serviceParams, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		emailAddress = emailAddress,
		serviceParams = serviceParams,
	}
	debugLog(self.client, "ResetEmailPasswordAdvanced payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_EMAIL_PASSWORD_ADVANCED, data, callback)
end

function Authentication:resetEmailPasswordWithExpiry(email, tokenTtlInMinutes, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		externalId = tostring(email),
		tokenTtlInMinutes = tokenTtlInMinutes,
	}
	debugLog(self.client, "ResetEmailPasswordWithExpiry payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_EMAIL_PASSWORD_WITH_EXPIRY, data, callback)
end

function Authentication:resetEmailPasswordAdvancedWithExpiry(emailAddress, serviceParams, tokenTtlInMinutes, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		emailAddress = emailAddress,
		serviceParams = serviceParams,
		tokenTtlInMinutes = tokenTtlInMinutes,
	}
	debugLog(self.client, "ResetEmailPasswordAdvancedWithExpiry payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_EMAIL_PASSWORD_ADVANCED_WITH_EXPIRY, data, callback)
end

--- Resets Universal ID password
-- Service Name - authenticationV2
-- Service Operation - ResetUniversalIdPassword
-- 
-- @param universalId The universal Id in question
-- @param callback The method to be invoked when the server response is received
-- 
function Authentication:resetUniversalIdPassword(universalId, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		universalId = universalId,
	}
	debugLog(self.client, "ResetUniversalIdPassword payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_UNIVERSAL_ID_PASSWORD, data, callback)
end

function Authentication:resetUniversalIdPasswordAdvanced(universalId, serviceParams, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		universalId = universalId,
		serviceParams = serviceParams,
	}
	debugLog(self.client, "ResetUniversalIdPasswordAdvanced payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_UNIVERSAL_ID_PASSWORD_ADVANCED, data, callback)
end

function Authentication:resetUniversalIdPasswordWithExpiry(universalId, tokenTtlInMinutes, callback)
	local data = {
		gameId = self.client and self.client.appId or nil,
		universalId = universalId,
		tokenTtlInMinutes = tokenTtlInMinutes,
	}
	debugLog(self.client, "ResetUniversalIdPasswordWithExpiry payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_UNIVERSAL_ID_PASSWORD_WITH_EXPIRY, data, callback)
end

function Authentication:resetUniversalIdPasswordAdvancedWithExpiry(
	universalId,
	serviceParams,
	tokenTtlInMinutes,
	callback
)
	local data = {
		gameId = self.client and self.client.appId or nil,
		universalId = universalId,
		serviceParams = serviceParams,
		tokenTtlInMinutes = tokenTtlInMinutes,
	}
	debugLog(self.client, "ResetUniversalIdPasswordAdvancedWithExpiry payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.RESET_UNIVERSAL_ID_PASSWORD_ADVANCED_WITH_EXPIRY, data, callback)
end

--- Logout
---@param callback fun(success: boolean, response: table|nil)
function Authentication:logout(callback)
	debugLog(self.client, "Logout called")
	self.client:sendRequest("playerState", "LOGOUT", {}, function(success, response)
		--- Clear local session regardless of server result
		if self.client and self.client.setSession then
			self:clearSavedSession(nil, nil)
		end
		if callback then
			callback(success, response)
		end
	end)
end

--- Returns the anonymous id used for anonymous authentication.
function Authentication:getAnonymousId()
	return self.anonymousId
end

--- Returns the profile id of the last authenticated profile.
function Authentication:getProfileId()
	return self.profileId
end

--- Sets the anonymous id used for anonymous authentication.
-- @param anonymousId The anonymous id
function Authentication:setAnonymousId(anonymousId)
	self.anonymousId = anonymousId or ""
end

--- Sets the profile id sent on the next authentication.
-- @param profileId The profile id
function Authentication:setProfileId(profileId)
	self.profileId = profileId or ""
end

--- Get server version.
-- 
-- 
function Authentication:getServerVersion(callback)
	local data = { gameId = self.client and self.client.appId or nil }
	debugLog(self.client, "GetServerVersion payload:", json.encode(data))
	self.client:sendRequest(SERVICE, OPS.GET_SERVER_VERSION, data, callback)
end

--- Export

Authentication.OPS = OPS
Authentication.AuthType = AuthType
return Authentication
