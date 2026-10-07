local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local Platform = require(ROOT .. ".platform.core")
local Utils = require(ROOT .. ".util")

local Identity = {}
Identity.__index = Identity

local SERVICE = "identity"

local OPS = {
	ATTACH = "ATTACH",
	ATTACH_BLOCKCHAIN_IDENTITY = "ATTACH_BLOCKCHAIN_IDENTITY",
	DETACH_BLOCKCHAIN_IDENTITY = "DETACH_BLOCKCHAIN_IDENTITY",
	MERGE = "MERGE",
	DETACH = "DETACH",
	SWITCH_TO_CHILD_PROFILE = "SWITCH_TO_CHILD_PROFILE",
	SWITCH_TO_PARENT_PROFILE = "SWITCH_TO_PARENT_PROFILE",
	GET_CHILD_PROFILES = "GET_CHILD_PROFILES",
	GET_IDENTITIES = "GET_IDENTITIES",
	GET_IDENTITY_STATUS = "GET_IDENTITY_STATUS",
	GET_EXPIRED_IDENTITIES = "GET_EXPIRED_IDENTITIES",
	REFRESH_IDENTITY = "REFRESH_IDENTITY",
	CHANGE_EMAIL_IDENTITY = "CHANGE_EMAIL_IDENTITY",
	ATTACH_PARENT_WITH_IDENTITY = "ATTACH_PARENT_WITH_IDENTITY",
	DETACH_PARENT = "DETACH_PARENT",
	ATTACH_PEER_PROFILE = "ATTACH_PEER_PROFILE",
	DETACH_PEER = "DETACH_PEER",
	GET_PEER_PROFILES = "GET_PEER_PROFILES",
	ATTACH_NONLOGIN_UNIVERSAL = "ATTACH_NONLOGIN_UNIVERSAL",
	UPDATE_UNIVERSAL_LOGIN = "UPDATE_UNIVERSAL_LOGIN",
}

--- Creates a new Identity instance.
--- @param baseClient table The brainCloud client instance.
--- @return Identity
function Identity.new(baseClient)
	local self = setmetatable({}, Identity)
	self.client = baseClient
	return self
end

--- Generic attach identity helper
--- Attach a generic external identity to the current profile.
--- @param externalId string External ID to attach (e.g., email, facebook id)
--- @param authenticationToken string Authentication token or password
--- @param authenticationType string Authentication type constant (see `self.client.authentication.AuthType`)
--- @param callback fun(success:boolean, response:table)|nil Optional server callback
function Identity:attachIdentity(externalId, authenticationToken, authenticationType, callback)
	local data = {
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
	}
	self.client:sendRequest(SERVICE, OPS.ATTACH, data, callback)
end

--- Generic merge identity helper
--- Merge an external identity into the current profile.
--- @param externalId string External ID to merge
--- @param authenticationToken string Authentication token or password
--- @param authenticationType string Authentication type constant
--- @param callback fun(success:boolean, response:table)|nil Optional server callback
function Identity:mergeIdentity(externalId, authenticationToken, authenticationType, callback)
	local data = {
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
	}
	self.client:sendRequest(SERVICE, OPS.MERGE, data, callback)
end

--- Generic detach identity helper
--- Detach an external identity from the current profile.
--- @param externalId string External ID to detach
--- @param authenticationType string Authentication type constant
--- @param continueAnon boolean|nil Whether to continue as anonymous if applicable
--- @param callback fun(success:boolean, response:table)|nil Optional server callback
function Identity:detachIdentity(externalId, authenticationType, continueAnon, callback)
	local data = {
		externalId = externalId,
		authenticationType = authenticationType,
		continueAnon = continueAnon,
	}
	self.client:sendRequest(SERVICE, OPS.DETACH, data, callback)
end

--- Attach the user's Facebook credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param facebookId The facebook id of the user
-- @param authenticationToken The validated token from the Facebook SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Facebook identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateFacebook().
-- 
function Identity:attachFacebookIdentity(facebookId, token, callback)
	self:attachIdentity(facebookId, token, self.client.authentication.AuthType.FACEBOOK, callback)
end

--- Merge the profile associated with the provided Facebook credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param facebookId The facebook id of the user
-- @param authenticationToken The validated token from the Facebook SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeFacebookIdentity(facebookId, token, callback)
	self:mergeIdentity(facebookId, token, self.client.authentication.AuthType.FACEBOOK, callback)
end

--- Detach the Facebook identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param facebookId The facebook id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachFacebookIdentity(facebookId, continueAnon, callback)
	self:detachIdentity(facebookId, self.client.authentication.AuthType.FACEBOOK, continueAnon, callback)
end

--- Attach the user's Ultra credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param ultraUsername it's what the user uses to log into the Ultra endpoint initially
-- @param ultraIdToken The "id_token" taken from Ultra's JWT.
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Ultra identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateApple().
-- 
function Identity:attachUltraIdentity(username, idToken, callback)
	self:attachIdentity(username, idToken, self.client.authentication.AuthType.ULTRA, callback)
end

--- Merge the profile associated with the provided Ultra credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param ultraUsername it's what the user uses to log into the Ultra endpoint initially
-- @param ultraIdToken The "id_token" taken from Ultra's JWT.
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeUltraIdentity(username, idToken, callback)
	self:mergeIdentity(username, idToken, self.client.authentication.AuthType.ULTRA, callback)
end

--- Detach the Ultra identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param ultraUsername it's what the user uses to log into the Ultra endpoint initially
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachUltraIdentity(username, continueAnon, callback)
	self:detachIdentity(username, self.client.authentication.AuthType.ULTRA, continueAnon, callback)
end

--- Attach a Email and Password identity to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param email The user's e-mail address
-- @param password The user's password
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the email address you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and then call AuthenticateEmailPassword().
-- 
function Identity:attachEmailIdentity(email, password, callback)
	self:attachIdentity(email, password, self.client.authentication.AuthType.EMAIL, callback)
end

--- Merge the profile associated with the provided e=mail with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param email The user's e-mail address
-- @param password The user's password
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeEmailIdentity(email, password, callback)
	self:mergeIdentity(email, password, self.client.authentication.AuthType.EMAIL, callback)
end

--- Detach the e-mail identity from the current profile
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param email The user's e-mail address
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachEmailIdentity(email, continueAnon, callback)
	self:detachIdentity(email, self.client.authentication.AuthType.EMAIL, continueAnon, callback)
end

--- Attach a Universal (userid + password) identity to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param userId The user's userid
-- @param password The user's password
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the email address you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and then call AuthenticateEmailPassword().
-- 
function Identity:attachUniversalIdentity(userId, password, callback)
	self:attachIdentity(userId, password, self.client.authentication.AuthType.UNIVERSAL, callback)
end

--- Merge the profile associated with the provided userId with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param userId The user's userid
-- @param password The user's password
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeUniversalIdentity(userId, password, callback)
	self:mergeIdentity(userId, password, self.client.authentication.AuthType.UNIVERSAL, callback)
end

--- Detach the universal identity from the current profile
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param userId The user's userid
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachUniversalIdentity(userId, continueAnon, callback)
	self:detachIdentity(userId, self.client.authentication.AuthType.UNIVERSAL, continueAnon, callback)
end

--- Attach a Steam (userid + steamsessionticket) identity to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param steamId String representation of 64 bit steam id
-- @param sessionTicket The user's session ticket (hex encoded)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the email address you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and then call AuthenticateSteam().
-- 
function Identity:attachSteamIdentity(steamId, sessionTicket, callback)
	self:attachIdentity(steamId, sessionTicket, self.client.authentication.AuthType.STEAM, callback)
end

--- Merge the profile associated with the provided steam userid with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param steamId String representation of 64 bit steam id
-- @param sessionTicket The user's session ticket (hex encoded)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeSteamIdentity(steamId, sessionTicket, callback)
	self:mergeIdentity(steamId, sessionTicket, self.client.authentication.AuthType.STEAM, callback)
end

--- Detach the steam identity from the current profile
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param steamId String representation of 64 bit steam id
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachSteamIdentity(steamId, continueAnon, callback)
	self:detachIdentity(steamId, self.client.authentication.AuthType.STEAM, continueAnon, callback)
end

--- Attach the user's Google credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param googleId The Google id of the user
-- @param authenticationToken The validated token from the Google SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Google identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateGoogle().
-- 
function Identity:attachGoogleIdentity(googleId, token, callback)
	self:attachIdentity(googleId, token, self.client.authentication.AuthType.GOOGLE, callback)
end

--- Merge the profile associated with the provided Google credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param googleId The Google id of the user
-- @param authenticationToken The validated token from the Google SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeGoogleIdentity(googleId, token, callback)
	self:mergeIdentity(googleId, token, self.client.authentication.AuthType.GOOGLE, callback)
end

--- Detach the Google identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param googleId The Google id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachGoogleIdentity(googleId, continueAnon, callback)
	self:detachIdentity(googleId, self.client.authentication.AuthType.GOOGLE, continueAnon, callback)
end

--- Attach the user's Google credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param googleId The Google id of the user
-- @param authenticationToken The validated token from the Google SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Google identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateGoogle().
-- 
function Identity:attachGoogleOpenIdIdentity(googleOpenId, token, callback)
	self:attachIdentity(googleOpenId, token, self.client.authentication.AuthType.GOOGLE_OPEN_ID, callback)
end

--- Merge the profile associated with the provided Google credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param googleId The Google id of the user
-- @param authenticationToken The validated token from the Google SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeGoogleOpenIdIdentity(googleOpenId, token, callback)
	self:mergeIdentity(googleOpenId, token, self.client.authentication.AuthType.GOOGLE_OPEN_ID, callback)
end

--- Detach the Google identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param googleId The Google id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachGoogleOpenIdIdentity(googleOpenId, continueAnon, callback)
	self:detachIdentity(googleOpenId, self.client.authentication.AuthType.GOOGLE_OPEN_ID, continueAnon, callback)
end

--- Attach the user's Apple credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param appleId The appleid of the user
-- @param authenticationToken The validated token from the Apple SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Apple identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateApple().
-- 
function Identity:attachAppleIdentity(appleId, token, callback)
	self:attachIdentity(appleId, token, self.client.authentication.AuthType.APPLE, callback)
end

--- Merge the profile associated with the provided Apple credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param appleId The apple id of the user
-- @param authenticationToken The validated token from the Apple SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeAppleIdentity(appleId, token, callback)
	self:mergeIdentity(appleId, token, self.client.authentication.AuthType.APPLE, callback)
end

--- Detach the Apple identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param appleId The apple id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachAppleIdentity(appleId, continueAnon, callback)
	self:detachIdentity(appleId, self.client.authentication.AuthType.APPLE, continueAnon, callback)
end

--- Attach the user's EpicGames credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
--
-- @param epicAccountId LocalUserId retrieved from the EOS AuthInterface's Login method.
-- @param authIdToken IdToken string from the EOS AuthInterface's CopyIdToken method.
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the EpicGames identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateEpicGames().
--
function Identity:attachEpicGamesIdentity(epicAccountId, authIdToken, callback)
	self:attachIdentity(epicAccountId, authIdToken, self.client.authentication.AuthType.EPIC_GAMES, callback)
end

--- Merge the profile associated with the provided EpicGames credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
--
-- @param epicAccountId LocalUserId retrieved from the EOS AuthInterface's Login method.
-- @param authIdToken IdToken string from the EOS AuthInterface's CopyIdToken method.
-- @param callback The method to be invoked when the server response is received
--
function Identity:mergeEpicGamesIdentity(epicAccountId, authIdToken, callback)
	self:mergeIdentity(epicAccountId, authIdToken, self.client.authentication.AuthType.EPIC_GAMES, callback)
end

--- Detach the EpicGames identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
--
-- @param epicAccountId LocalUserId retrieved from the EOS AuthInterface's Login method.
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
--
function Identity:detachEpicGamesIdentity(epicAccountId, continueAnon, callback)
	self:detachIdentity(epicAccountId, self.client.authentication.AuthType.EPIC_GAMES, continueAnon, callback)
end

--- Attach the user's credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param authenticationType Universal, Email, Facebook, etc
-- @param ids Auth IDs structure
-- @param extraJson Additional to piggyback along with the call, to be picked up by pre- or post- hooks. Leave empty string for no extraJson.
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateAdvanced().
-- 
function Identity:attachAdvancedIdentity(authenticationType, ids, extraJson, callback)
	local data = {
		externalId = ids.externalId,
		authenticationType = authenticationType,
		authenticationToken = ids.authenticationToken,
		externalAuthName = ids.authenticationSubType,
		extraJson = extraJson,
	}
	self.client:sendRequest(SERVICE, OPS.ATTACH, data, callback)
end

--- Merge the profile associated with the provided credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param authenticationType Universal, Email, Facebook, etc
-- @param ids Auth IDs structure
-- @param extraJson Additional to piggyback along with the call, to be picked up by pre- or post- hooks. Leave empty string for no extraJson.
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeAdvancedIdentity(authenticationType, ids, extraJson, callback)
	local data = {
		externalId = ids.externalId,
		authenticationType = authenticationType,
		authenticationToken = ids.authenticationToken,
		externalAuthName = ids.authenticationSubType,
		extraJson = extraJson,
	}
	self.client:sendRequest(SERVICE, OPS.MERGE, data, callback)
end

--- Detach the identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param authenticationType Universal, Email, Facebook, etc
-- @param externalId User ID
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param extraJson Additional to piggyback along with the call, to be picked up by pre- or post- hooks. Leave empty string for no extraJson.
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachAdvancedIdentity(authenticationType, externalId, continueAnon, extraJson, callback)
	local data = {
		externalId = externalId,
		authenticationType = authenticationType,
		continueAnon = continueAnon,
		extraJson = extraJson,
	}
	self.client:sendRequest(SERVICE, OPS.DETACH, data, callback)
end

--- Attach the user's Facebook credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param facebookLimitedId The facebook limited id of the user
-- @param authenticationToken The validated token from the Facebook SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Facebook identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateFacebook().
-- 
function Identity:attachFacebookLimitedIdentity(facebookLimitedId, authenticationToken, callback)
	self:attachIdentity(facebookLimitedId, authenticationToken, self.client.authentication.AuthType.FACEBOOK_LIMITED, callback)
end

--- Merge the profile associated with the provided Facebook credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param facebookLimitedId The facebook limited id of the user
-- @param authenticationToken The validated token from the Facebook SDK
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeFacebookLimitedIdentity(facebookLimitedId, authenticationToken, callback)
	self:mergeIdentity(facebookLimitedId, authenticationToken, self.client.authentication.AuthType.FACEBOOK_LIMITED, callback)
end

--- Detach the Facebook identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param facebookLimitedId The facebook limited id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachFacebookLimitedIdentity(facebookLimitedId, continueAnon, callback)
	self:detachIdentity(facebookLimitedId, self.client.authentication.AuthType.FACEBOOK_LIMITED, continueAnon, callback)
end

--- Attach a Game Center identity to the current profile.
-- Note: If the Game Center legacy authentication compatibility flag is enabled,
-- only gameCenterId is required and all verification signature parameters are ignored.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param gameCenterId The user's Game Center Id which can be the playerId, gamePlayerId, or teamPlayerId from the localPlayer object.
-- @param timestamp The timestamp value returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param publicKeyUrl The publicKeyUrl value returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param signature The raw signature bytes returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param signatureLength The length of the returned identity verification signature.
--        Required for modern Game Center verification.
-- @param salt The raw salt bytes returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param saltLength The length of the returned identity verification salt.
--        Required for modern Game Center verification.
-- @param teamPlayerId Optional for Game Center verification; only required when gameCenterId is set to a value other than teamPlayerId (e.g. playerId),
--        so that brainCloud can still associate the user with their team-scoped identity.
-- @param callback The method to be invoked when the server response is received.
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Game Center identity you provided
--        already points to a different profile.  You will likely want to offer the player the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call this method again.
-- 
function Identity:attachGameCenterIdentity(gameCenterId, callback)
	self:attachIdentity(gameCenterId, "", self.client.authentication.AuthType.GAME_CENTER, callback)
end

--- Merge the profile associated with the specified Game Center identity with the current profile.
-- Note: If the Game Center legacy authentication compatibility flag is enabled,
-- only gameCenterId is required and all verification signature parameters are ignored.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param gameCenterId The user's Game Center Id which can be the playerId, gamePlayerId, or teamPlayerId from the localPlayer object.
-- @param timestamp The timestamp value returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param publicKeyUrl The publicKeyUrl value returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param signature The raw signature bytes returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param signatureLength The length of the returned identity verification signature.
--        Required for modern Game Center verification.
-- @param salt The raw salt bytes returned as part of the identity verification signature fetch from Game Center.
--        Required for modern Game Center verification.
-- @param saltLength The length of the returned identity verification salt.
--        Required for modern Game Center verification.
-- @param teamPlayerId Optional for Game Center verification; only required when gameCenterId is set to a value other than
--        teamPlayerId (e.g. playerId), so that brainCloud can still associate the user with their team-scoped identity.
-- @param callback The method to be invoked when the server response is received.
-- 
function Identity:mergeGameCenterIdentity(gameCenterId, callback)
	self:mergeIdentity(gameCenterId, "", self.client.authentication.AuthType.GAME_CENTER, callback)
end

--- Detach the Game Center identity from the current profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param gameCenterId The user's Game Center Id which can be the playerId, gamePlayerId, or teamPlayerId from the localPlayer object.
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received.
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachGameCenterIdentity(gameCenterId, continueAnon, callback)
	self:detachIdentity(gameCenterId, self.client.authentication.AuthType.GAME_CENTER, continueAnon, callback)
end

--- Attach the user's Oculus credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param oculusId The oculus id of the user
-- @param oculusNonce The validated token from the Oculus SDK
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Oculus identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateOculus().
-- 
function Identity:attachOculusIdentity(oculusId, oculusNonce, callback)
	self:attachIdentity(oculusId, oculusNonce, self.client.authentication.AuthType.OCULUS, callback)
end

--- Merge the profile associated with the provided Oculus credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param oculusId The oculus id of the user
-- @param oculusNonce The validated token from the Oculus SDK
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeOculusIdentity(oculusId, oculusNonce, callback)
	self:mergeIdentity(oculusId, oculusNonce, self.client.authentication.AuthType.OCULUS, callback)
end

--- Detach the Oculus identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param oculusId The oculus id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachOculusIdentity(oculusId, continueAnon, callback)
	self:detachIdentity(oculusId, self.client.authentication.AuthType.OCULUS, continueAnon, callback)
end

--- Attach the user's PSN credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
--
-- @param psnAccountId The PSN account id of the user
-- @param authenticationToken The validated token from the PlayStation SDK
-- @param callback The method to be invoked when the server response is received
--
function Identity:attachPlaystationNetworkIdentity(psnAccountId, authenticationToken, callback)
	self:attachIdentity(psnAccountId, authenticationToken, self.client.authentication.AuthType.PLAYSTATION_NETWORK, callback)
end

--- Merge the profile associated with the provided PSN credentials with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
--
-- @param psnAccountId The PSN account id of the user
-- @param authenticationToken The validated token from the PlayStation SDK
-- @param callback The method to be invoked when the server response is received
--
function Identity:mergePlaystationNetworkIdentity(psnAccountId, authenticationToken, callback)
	self:mergeIdentity(psnAccountId, authenticationToken, self.client.authentication.AuthType.PLAYSTATION_NETWORK, callback)
end

--- Detach the PSN identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
--
-- @param psnAccountId The PSN account id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--
function Identity:detachPlaystationNetworkIdentity(psnAccountId, continueAnon, callback)
	self:detachIdentity(psnAccountId, self.client.authentication.AuthType.PLAYSTATION_NETWORK, continueAnon, callback)
end

--- Attach the user's PS5 credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param psnAccountId The PSN account id of the user
-- @param authenticationToken The validated token from the PlayStation SDK
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:attachPlaystation5Identity(psnAccountId, authenticationToken, callback)
	self:attachIdentity(psnAccountId, authenticationToken, self.client.authentication.AuthType.PLAYSTATION_NETWORK5, callback)
end

--- Merge the profile associated with the provided PS5 credentials with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param psnAccountId The PSN account id of the user
-- @param authenticationToken The validated token from the PlayStation SDK
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergePlaystation5Identity(psnAccountId, authenticationToken, callback)
	self:mergeIdentity(psnAccountId, authenticationToken, self.client.authentication.AuthType.PLAYSTATION_NETWORK5, callback)
end

--- Detach the PS5 identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param psnAccountId The PSN account id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:detachPlaystation5Identity(psnAccountId, continueAnon, callback)
	self:detachIdentity(psnAccountId, self.client.authentication.AuthType.PLAYSTATION_NETWORK5, continueAnon, callback)
end

--- Attach the user's Nintendo credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
--
-- @param nintendoAccountId The Nintendo account id of the user
-- @param authenticationToken The validated token from the Nintendo SDK
-- @param callback The method to be invoked when the server response is received
--
function Identity:attachNintendoIdentity(nintendoAccountId, authenticationToken, callback)
	self:attachIdentity(nintendoAccountId, authenticationToken, self.client.authentication.AuthType.NINTENDO, callback)
end

--- Merge the profile associated with the provided Nintendo credentials with the current profile.
-- Service Name - identity
-- Service Operation - MERGE
--
-- @param nintendoAccountId The Nintendo account id of the user
-- @param authenticationToken The validated token from the Nintendo SDK
-- @param callback The method to be invoked when the server response is received
--
function Identity:mergeNintendoIdentity(nintendoAccountId, authenticationToken, callback)
	self:mergeIdentity(nintendoAccountId, authenticationToken, self.client.authentication.AuthType.NINTENDO, callback)
end

--- Detach the Nintendo identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
--
-- @param nintendoAccountId The Nintendo account id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--
function Identity:detachNintendoIdentity(nintendoAccountId, continueAnon, callback)
	self:detachIdentity(nintendoAccountId, self.client.authentication.AuthType.NINTENDO, continueAnon, callback)
end

--- Attach the user's Twitter credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param twitterId The Twitter id of the user
-- @param authenticationToken The authentication token derived from the twitter APIs
-- @param secret The secret given when attempting to link with Twitter
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Twitter identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateTwitter().
-- 
function Identity:attachTwitterIdentity(twitterId, token, secret, callback)
	self:attachIdentity(twitterId, token .. ":" .. secret, self.client.authentication.AuthType.TWITTER, callback)
end

--- Merge the profile associated with the provided Twitter credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param twitterId The Twitter id of the user
-- @param authenticationToken The authentication token derived from the twitter APIs
-- @param secret The secret given when attempting to link with Twitter
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeTwitterIdentity(twitterId, token, secret, callback)
	self:mergeIdentity(twitterId, token .. ":" .. secret, self.client.authentication.AuthType.TWITTER, callback)
end

--- Detach the Twitter identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param twitterId The Twitter id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachTwitterIdentity(twitterId, continueAnon, callback)
	self:detachIdentity(twitterId, self.client.authentication.AuthType.TWITTER, continueAnon, callback)
end

--- Attach the user's Parse credentials to the current profile.
-- Service Name - identity
-- Service Operation - ATTACH
-- 
-- @param parseId The Parse id of the user
-- @param authenticationToken The validated token from Parse
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
--        Errors to watch for:  SWITCHING_PROFILES - this means that the Google identity you provided
--        already points to a different profile.  You will likely want to offer the user the
--        choice to *SWITCH* to that profile, or *MERGE* the profiles.
--        To switch profiles, call ClearSavedProfileID() and call AuthenticateParse().
-- 
function Identity:attachParseIdentity(parseId, token, callback)
	self:attachIdentity(parseId, token, self.client.authentication.AuthType.PARSE, callback)
end

--- Merge the profile associated with the provided Parse credentials with the
-- current profile.
-- Service Name - identity
-- Service Operation - MERGE
-- 
-- @param parseId The Parse id of the user
-- @param authenticationToken The validated token from Parse
--        (that will be further validated when sent to the bC service)
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:mergeParseIdentity(parseId, token, callback)
	self:mergeIdentity(parseId, token, self.client.authentication.AuthType.PARSE, callback)
end

--- Detach the Google identity from this profile.
-- Service Name - identity
-- Service Operation - DETACH
-- 
-- @param parseId The Parse id of the user
-- @param continueAnon Proceed even if the profile will revert to anonymous?
-- @param callback The method to be invoked when the server response is received
--        Watch for DOWNGRADING_TO_ANONYMOUS_ERROR - occurs if you set continueAnon to false, and
--        disconnecting this identity would result in the profile being anonymous (which means that
--        the profile wouldn't be retrievable if the user loses their device)
-- 
function Identity:detachParseIdentity(parseId, continueAnon, callback)
	self:detachIdentity(parseId, self.client.authentication.AuthType.PARSE, continueAnon, callback)
end

--- Switch to a Child Profile
--- Service Name - identity
--- Service Operation - SWITCH_TO_CHILD_PROFILE
--- @param childProfileId The profileId of the child profile to switch to
---        If null and forceCreate is true a new profile will be created
--- @param childAppId The appId of the child app to switch to
--- @param forceCreate Should a new profile be created if it does not exist?
--- @param callback The method to be invoked when the server response is received
function Identity:switchToChildProfile(childProfileId, childAppId, forceCreate, callback)
	self:switchToChildProfileInternal(childProfileId, childAppId, forceCreate, false, callback)
end

--- Switches to a child profile of an app when only one profile exists
--- If multiple profiles exist this returns an error
--- Service Name - identity
--- Service Operation - SWITCH_TO_CHILD_PROFILE
--- @param childAppId The App ID of the child app to switch to
--- @param forceCreate Should a new profile be created if it does not exist?
--- @param callback The method to be invoked when the server response is received
function Identity:switchToSingletonChildProfile(childAppId, forceCreate, callback)
	self:switchToChildProfileInternal(nil, childAppId, forceCreate, true, callback)
end

--- Switch to a Parent Profile
--- Service Name - identity
--- Service Operation - SWITCH_TO_PARENT_PROFILE
--- @param parentLevelName The level of the parent to switch to
---        If null and forceCreate is true a new profile will be created
--- @param callback The method to be invoked when the server response is received
function Identity:switchToParentProfile(parentLevelName, callback)
	self.client:sendRequest(SERVICE, OPS.SWITCH_TO_PARENT_PROFILE, { levelName = parentLevelName }, callback)
end

--- Returns a list of all child profiles in child Apps
--- Service Name - identity
--- Service Operation - GET_CHILD_PROFILES
--- @param includeSummaryData Whether to return the summary friend data along with this call
--- @param callback The method to be invoked when the server response is received
function Identity:getChildProfiles(includeSummaryData, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.GET_CHILD_PROFILES,
		{ includePlayerSummaryData = includeSummaryData },
		callback
	)
end

--- Attaches the given block chain public key identity to the current profile.
--- @param blockchainConfig
--- @param publicKey
--- Service Name - identity
--- Service Operation - ATTACH_BLOCKCHAIDENTITY
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:attachBlockchainIdentity(blockchainConfig, publicKey, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.ATTACH_BLOCKCHAIN_IDENTITY,
		{ blockchainConfig = blockchainConfig, publicKey = publicKey },
		callback
	)
end

--- Detaches the blockchain identity to the current profile.
--- @param blockchainConfig
--- Service Name - identity
--- Service Operation - ATTACH_BLOCKCHAIDENTITY
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:detachBlockchainIdentity(blockchainConfig, callback)
	self.client:sendRequest(SERVICE, OPS.DETACH_BLOCKCHAIN_IDENTITY, { blockchainConfig = blockchainConfig }, callback)
end

--- Updates univeral id of the current profile.
-- Service Name - identity
-- Service Operation - UPDATE_UNIVERSAL_LOGIN
-- 
-- @param externalId the id that's been connected with
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:updateUniversalIdLogin(externalId, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_UNIVERSAL_LOGIN, { externalId = externalId }, callback)
end

--- Attaches a univeral id to the current profile with no login capability.
-- Service Name - identity
-- Service Operation - ATTACH_NONLOGIN_UNIVERSAL
-- 
-- @param externalId the id that's been connected with
-- @param callback The method to be invoked when the server response is received
-- 
function Identity:attachNonLoginUniversalId(externalId, callback)
	self.client:sendRequest(SERVICE, OPS.ATTACH_NONLOGIN_UNIVERSAL, { externalId = externalId }, callback)
end

--- Retrieve list of identities
--- Service Name - identity
--- Service Operation - GET_IDENTITIES
--- @param callback The method to be invoked when the server response is received
function Identity:getIdentities(callback)
	self.client:sendRequest(SERVICE, OPS.GET_IDENTITIES, {}, callback)
end

--- Retrieves identity status for given identity type for this profile.
function Identity:getIdentityStatus(authenticationType, externalAuthName, callback)
	local data = {
		authenticationType = authenticationType,
		externalAuthName = externalAuthName,
	}
	self.client:sendRequest(SERVICE, OPS.GET_IDENTITY_STATUS, data, callback)
end

--- Retrieve list of expired identities
--- Service Name - identity
--- Service Operation - GET_EXPIRED_IDENTITIES
--- @param callback The method to be invoked when the server response is received
function Identity:getExpiredIdentities(callback)
	self.client:sendRequest(SERVICE, OPS.GET_EXPIRED_IDENTITIES, {}, callback)
end

--- Refreshes an identity for this user
--- Service Name - identity
--- Service Operation - REFRESH_IDENTITY
--- @param externalId User ID
--- @param authenticationToken Password or client side token
--- @param authenticationType Type of authentication
--- @param callback The method to be invoked when the server response is received
function Identity:refreshIdentity(externalId, authenticationToken, authenticationType, callback)
	local data = {
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
	}
	self.client:sendRequest(SERVICE, OPS.REFRESH_IDENTITY, data, callback)
end

--- Allows email identity email address to be changed
--- Service Name - identity
--- Service Operation - CHANGE_EMAIL_IDENTITY
--- @param oldEmailAddress Old email address
--- @param password Password for identity
--- @param newEmailAddress New email address
--- @param updateContactEmail Whether to update contact email in profile
--- @param callback The method to be invoked when the server response is received
function Identity:changeEmailIdentity(oldEmailAddress, password, newEmailAddress, updateContactEmail, callback)
	local data = {
		oldEmailAddress = oldEmailAddress,
		authenticationToken = password,
		newEmailAddress = newEmailAddress,
		updateContactEmail = updateContactEmail,
	}
	self.client:sendRequest(SERVICE, OPS.CHANGE_EMAIL_IDENTITY, data, callback)
end

--- Attach a new identity to a parent app
--- Service Name - identity
--- Service Operation - ATTACH_PARENT_WITH_IDENTITY
--- @param externalId The users id for the new credentials
--- @param authenticationToken The password/token
--- @param authenticationType Type of identity
--- @param externalAuthName Optional - if attaching an external identity
--- @param forceCreate Should a new profile be created if it does not exist?
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:attachParentWithIdentity(
	externalId,
	authenticationToken,
	authenticationType,
	externalAuthName,
	forceCreate,
	callback
)
	local data = {
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
		forceCreate = forceCreate,
	}
	if externalAuthName then
		data.externalAuthName = externalAuthName
	end
	self.client:sendRequest(SERVICE, OPS.ATTACH_PARENT_WITH_IDENTITY, data, callback)
end

--- Detaches parent from this user's profile
--- Service Name - identity
--- Service Operation - DETACH_PARENT
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:detachParent(callback)
	self.client:sendRequest(SERVICE, OPS.DETACH_PARENT, nil, callback)
end

--- Attaches a peer identity to this user's profile
--- Service Name - identity
--- Service Operation - ATTACH_PEER_PROFILE
--- @param peer Name of the peer to connect to
--- @param externalId The users id for the new credentials
--- @param authenticationToken The password/token
--- @param authenticationType Type of identity
--- @param externalAuthName Optional - if attaching an external identity
--- @param forceCreate Should a new profile be created if it does not exist?
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:attachPeerProfile(
	peer,
	externalId,
	authenticationToken,
	authenticationType,
	externalAuthName,
	forceCreate,
	callback
)
	local data = {
		peer = peer,
		externalId = externalId,
		authenticationToken = authenticationToken,
		authenticationType = authenticationType,
		forceCreate = forceCreate,
	}
	if externalAuthName then
		data.externalAuthName = externalAuthName
	end
	self.client:sendRequest(SERVICE, OPS.ATTACH_PEER_PROFILE, data, callback)
end

--- Detaches a peer identity from this user's profile
--- Service Name - identity
--- Service Operation - DETACH_PEER
--- @param peer Name of the peer to connect to
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:detachPeer(peer, callback)
	local data = { peer = peer }
	self.client:sendRequest(SERVICE, OPS.DETACH_PEER, data, callback)
end

--- Returns a list of peer profiles attached to this user
--- Service Name - identity
--- Service Operation - GET_PEER_PROFILES
--- @param successCallback The success callback
--- @param errorCallback The failure callback.
--- @param cbObject The user object sent to the callback
function Identity:getPeerProfiles(callback)
	self.client:sendRequest(SERVICE, OPS.GET_PEER_PROFILES, nil, callback)
end

--- Internal switch to child profile helper
--- Internal helper to switch to a child profile.
--- @param childProfileId string|nil Child profile id (nil for singleton child)
--- @param childAppId string App id of the child profile
--- @param forceCreate boolean|nil Whether to force-create the child profile
--- @param forceSingleton boolean|nil Whether the child should be singleton
--- @param callback fun(success:boolean, response:table)|nil Optional server callback
function Identity:switchToChildProfileInternal(childProfileId, childAppId, forceCreate, forceSingleton, callback)
	--- Determine language and country
	local languageCode, countryCode = Platform.locale(self.client)
	local timeZoneOffset = Platform.timeZoneOffset(self.client)

	local data = {
		profileId = childProfileId,
		gameId = childAppId,
		forceCreate = forceCreate,
		forceSingleton = forceSingleton,
		releasePlatform = self.client.releasePlatform,
		timeZoneOffset = timeZoneOffset,
		languageCode = languageCode,
		countryCode = countryCode,
	}

	self.client:sendRequest(SERVICE, OPS.SWITCH_TO_CHILD_PROFILE, data, callback)
end

return Identity
