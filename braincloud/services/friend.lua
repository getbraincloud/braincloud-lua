local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local Friend = {}
Friend.__index = Friend

local SERVICE = "friend"

local OPS = {
	GET_FRIEND_PROFILE_INFO_FOR_EXTERNAL_ID = "GET_FRIEND_PROFILE_INFO_FOR_EXTERNAL_ID",
	GET_PROFILE_INFO_FOR_CREDENTIAL = "GET_PROFILE_INFO_FOR_CREDENTIAL",
	GET_PROFILE_INFO_FOR_CREDENTIAL_IF_EXISTS = "GET_PROFILE_INFO_FOR_CREDENTIAL_IF_EXISTS",
	GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID = "GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID",
	GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID_IF_EXISTS = "GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID_IF_EXISTS",
	GET_EXTERNAL_ID_FOR_PROFILE_ID = "GET_EXTERNAL_ID_FOR_PROFILE_ID",
	READ_FRIENDS = "READ_FRIENDS",
	READ_FRIEND_ENTITY = "READ_FRIEND_ENTITY",
	READ_FRIENDS_ENTITIES = "READ_FRIENDS_ENTITIES",
	READ_FRIEND_PLAYER_STATE = "READ_FRIEND_PLAYER_STATE",
	READ_FRIENDS_WITH_APPLICATION = "READ_FRIENDS_WITH_APPLICATION",
	FIND_PLAYER_BY_NAME = "FIND_PLAYER_BY_NAME",
	FIND_PLAYER_BY_UNIVERSAL_ID = "FIND_PLAYER_BY_UNIVERSAL_ID",
	LIST_FRIENDS = "LIST_FRIENDS",
	GET_MY_SOCIAL_INFO = "GET_MY_SOCIAL_INFO",
	ADD_FRIENDS = "ADD_FRIENDS",
	ADD_FRIENDS_FROM_PLATFORM = "ADD_FRIENDS_FROM_PLATFORM",
	REMOVE_FRIENDS = "REMOVE_FRIENDS",
	GET_SUMMARY_DATA_FOR_PROFILE_ID = "GET_SUMMARY_DATA_FOR_PROFILE_ID",
	GET_USERS_ONLINE_STATUS = "GET_USERS_ONLINE_STATUS",
	FIND_USERS_BY_EXACT_NAME = "FIND_USERS_BY_EXACT_NAME",
	FIND_USERS_BY_SUBSTR_NAME = "FIND_USERS_BY_SUBSTR_NAME",
	FIND_USERS_BY_NAME_STARTING_WITH = "FIND_USERS_BY_NAME_STARTING_WITH",
	FIND_USERS_BY_UNIVERSAL_ID_STARTING_WITH = "FIND_USERS_BY_UNIVERSAL_ID_STARTING_WITH",
	FIND_USER_BY_EXACT_UNIVERSAL_ID = "FIND_USER_BY_EXACT_UNIVERSAL_ID",
}

--https://docs.braincloudservers.com/api/capi/friend/addfriendsfromplatform
local FRIEND_PLATFORM = {
	All = "All",
	Steam = "Steam",
	Facebook = "Facebook",
	PlaystationNetwork = "PlaystationNetwork",
}


--- Constructor

--- Creates a new Friend service instance.
--- @param client table The brainCloud client instance.
--- @return Friend
function Friend.new(client)
	local self = setmetatable({}, Friend)
	self.client = client
	return self
end


--- Core Methods

--- Retrieves profile information for the specified user.
--- Service Name - friend
--- Service Operation - GET_PROFILE_INFO_FOR_CREDENTIAL
--- @param externalId The users's external ID
--- @param authenticationType The authentication type of the user ID
--- @param callback Method to be invoked when the server response is received.
function Friend:getProfileInfoForCredential(externalId, authenticationType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PROFILE_INFO_FOR_CREDENTIAL, {
		externalId = externalId,
		authenticationType = authenticationType,
	}, callback)
end

--- Retrieves profile information for the specified user.
--- Silently fails, if profile does not exist, just returns null and success, instead of an error.
--- Service Name - friend
--- Service Operation - GET_PROFILE_INFO_FOR_CREDENTIAL_IF_EXISTS
--- @param externalId The users's external ID
--- @param authenticationType The authentication type of the user ID
--- @param callback Method to be invoked when the server response is received.
function Friend:getProfileInfoForCredentialIfExists(externalId, authenticationType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PROFILE_INFO_FOR_CREDENTIAL_IF_EXISTS, {
		externalId = externalId,
		authenticationType = authenticationType,
	}, callback)
end

--- Retrieves profile information for the specified external auth user.
--- Service Name - friend
--- Service Operation - GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID
--- @param externalId External ID of the friend to find
--- @param externalAuthType The external authentication type used for this friend's external ID
--- @param callback Method to be invoked when the server response is received.
function Friend:getProfileInfoForExternalAuthId(externalId, externalAuthType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID, {
		externalId = externalId,
		externalAuthType = externalAuthType,
	}, callback)
end

--- Retrieves profile information for the specified user. Silently fails, if profile does not exist, just returns null and success, instead of an error.
-- Service Name - friend
-- Service Operation - GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID_IF_EXISTS
-- 
-- @param externalId External ID of the friend to find
-- @param externalAuthType The external authentication type used for this friend's external ID
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:getProfileInfoForExternalAuthIdIfExists(externalId, externalAuthType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_PROFILE_INFO_FOR_EXTERNAL_AUTH_ID_IF_EXISTS, {
		externalId = externalId,
		externalAuthType = externalAuthType,
	}, callback)
end

--- Retrieves the external ID for the specified user profile ID on the specified social platform.
-- 
-- @param profileId Profile (user) ID.
-- @param authenticationType Associated authentication type.
-- 
function Friend:getExternalIdForProfileId(profileId, authenticationType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_EXTERNAL_ID_FOR_PROFILE_ID, {
		profileId = profileId,
		authenticationType = authenticationType,
	}, callback)
end

--- Returns a particular entity of a particular friend.
-- Service Name - friend
-- Service Operation - READ_FRIEND_ENTITY
-- 
-- @param entityId Id of entity to retrieve.
-- @param friendId Profile Id of friend who owns entity.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:readFriendEntity(friendId, entityId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_FRIEND_ENTITY, {
		friendId = friendId,
		entityId = entityId,
	}, callback)
end

--- Returns entities of all friends optionally based on type.
-- Service Name - friend
-- Service Operation - READ_FRIENDS_ENTITIES
-- 
-- @param entityType Types of entities to retrieve.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:readFriendsEntities(entityType, callback)
	self.client:sendRequest(SERVICE, OPS.READ_FRIENDS_ENTITIES, {
		entityType = entityType,
	}, callback)
end

--- Read a friend's user state.
-- If you are not friend with this user, you will get an error
-- with NOT_FRIENDS reason code.
-- Service Name - friend
-- Service Operation - READ_FRIEND_PLAYER_STATE
-- 
-- @param friendId Target friend
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:readFriendUserState(friendId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_FRIEND_PLAYER_STATE, {
		friendId = friendId,
	}, callback)
end

--- Finds a list of users matching the search text by performing an exact match search
-- Service Name - friend
-- Service Operation - FIND_USERS_BY_EXACT_NAME
-- 
-- @param searchText The string to search for.
-- @param maxResults Maximum number of results to return.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:findUsersByExactName(searchText, maxResults, callback)
	self.client:sendRequest(SERVICE, OPS.FIND_USERS_BY_EXACT_NAME, {
		searchText = searchText,
		maxResults = maxResults,
	}, callback)
end

--- Finds a list of users matching the search text by performing a substring
-- search of all user names.
-- Service Name - friend
-- Service Operation - FIND_USERS_BY_SUBSTR_NAME
-- 
-- @param searchText The substring to search for. Minimum length of 3 characters.
-- @param maxResults Maximum number of results to return. If there are more the message
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:findUsersBySubstrName(searchText, maxResults, callback)
	self.client:sendRequest(SERVICE, OPS.FIND_USERS_BY_SUBSTR_NAME, {
		searchText = searchText,
		maxResults = maxResults,
	}, callback)
end

--- Retrieves profile information of the specified universal Id.
-- 
-- @param searchText Universal ID text on which to search.
-- 
function Friend:findUserByExactUniversalId(searchText, callback)
	self.client:sendRequest(SERVICE, OPS.FIND_USER_BY_EXACT_UNIVERSAL_ID, {
		searchText = searchText,
	}, callback)
end

--- Retrieves a list of user and friend platform information for all friends of the current user.
-- Service Name - friend
-- Service Operation - LIST_FRIENDS
-- 
-- @param friendPlatform Friend platform to query.
-- @param includeSummaryData True if including summary data; false otherwise.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:listFriends(friendPlatform, includeSummaryData, callback)
	self.client:sendRequest(SERVICE, OPS.LIST_FRIENDS, {
		friendPlatform = friendPlatform,
		includeSummaryData = includeSummaryData,
	}, callback)
end

--- Retrieves your social info for a platform.
--- @param friendPlatform string
--- @param includeSummaryData boolean
--- @param callback fun(response: table)
function Friend:getMySocialInfo(friendPlatform, includeSummaryData, callback)
	self.client:sendRequest(SERVICE, OPS.GET_MY_SOCIAL_INFO, {
		friendPlatform = friendPlatform,
		includeSummaryData = includeSummaryData,
	}, callback)
end

--- Links the current user and the specified users as brainCloud friends.
-- Service Name - friend
-- Service Operation - ADD_FRIENDS
-- 
-- @param profileIds Collection of profile IDs.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:addFriends(profileIds, callback)
	self.client:sendRequest(SERVICE, OPS.ADD_FRIENDS, {
		profileIds = Utils.array(profileIds),
	}, callback)
end

--- Links the profiles for the specified externalIds for the given friend platform as internal friends.
-- Service Name - friend
-- Service Operation - ADD_FRIENDS_FROM_PLATFORM
-- 
-- @param friendPlatform Platform to add from (i.e: FriendPlatform::Facebook)
-- @param mode ADD or SYNC
-- @param externalIds Collection of external IDs from the friend platform.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:addFriendsFromPlatform(friendPlatform, mode, externalIds, callback)
	self.client:sendRequest(SERVICE, OPS.ADD_FRIENDS_FROM_PLATFORM, {
		friendPlatform = friendPlatform,
		mode = mode,
		externalIds = Utils.array(externalIds),
	}, callback)
end

--- Unlinks the current user and the specified users as brainCloud friends.
-- Service Name - friend
-- Service Operation - REMOVE_FRIENDS
-- 
-- @param profileIds Collection of profile IDs.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:removeFriends(profileIds, callback)
	self.client:sendRequest(SERVICE, OPS.REMOVE_FRIENDS, {
		profileIds = Utils.array(profileIds),
	}, callback)
end

--- Returns user state of a particular user.
-- Service Name - friend
-- Service Operation - GET_SUMMARY_DATA_FOR_PROFILE_ID
-- 
-- @param profileId Profile Id of user to retrieve user state for.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:getSummaryDataForProfileId(profileId, callback)
	self.client:sendRequest(SERVICE, OPS.GET_SUMMARY_DATA_FOR_PROFILE_ID, {
		profileId = profileId,
	}, callback)
end

--- Get users online status
-- Service Name - friend
-- Service Operation - GET_USERS_ONLINE_STATUS
-- 
-- @param profileIds Collection of profile IDs.
-- @param callback Method to be invoked when the server response is received.
-- 
function Friend:getUsersOnlineStatus(profileIds, callback)
	self.client:sendRequest(SERVICE, OPS.GET_USERS_ONLINE_STATUS, {
		profileIds = Utils.array(profileIds),
	}, callback)
end

--- Retrieves profile information for the users whos names start with search text.
-- 
-- @param searchText Name text on which to search.
-- @param maxResults Maximum number of results to return.
-- 
function Friend:findUsersByNameStartingWith(searchText, maxResults, callback)
	self.client:sendRequest(SERVICE, OPS.FIND_USERS_BY_NAME_STARTING_WITH, {
		searchText = searchText,
		maxResults = maxResults,
	}, callback)
end

--- Retrieves profile information for the users whos UniversalId start with search text.
-- 
-- @param searchText Universal ID text on which to search.
-- @param maxResults Maximum number of results to return.
-- 
function Friend:findUsersByUniversalIdStartingWith(searchText, maxResults, callback)
	self.client:sendRequest(SERVICE, OPS.FIND_USERS_BY_UNIVERSAL_ID_STARTING_WITH, {
		searchText = searchText,
		maxResults = maxResults,
	}, callback)
end


--- Constants

Friend.FRIEND_PLATFORM = FRIEND_PLATFORM

return Friend
