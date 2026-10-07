local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local PlayerState = {}
PlayerState.__index = PlayerState

local SERVICE = "playerState"

local OPS = {
	SEND = "SEND",
	UPDATE_EVENT_DATA = "UPDATE_EVENT_DATA",
	DELETE_INCOMING = "DELETE_INCOMING",
	DELETE_SENT = "DELETE_SENT",
	FULL_PLAYER_RESET = "FULL_PLAYER_RESET",
	GAME_DATA_RESET = "GAME_DATA_RESET",
	UPDATE_SUMMARY = "UPDATE_SUMMARY",
	READ_FRIENDS = "READ_FRIENDS",
	READ_FRIEND_PLAYER_STATE = "READ_FRIEND_PLAYER_STATE",
	UPDATE_ATTRIBUTES = "UPDATE_ATTRIBUTES",
	REMOVE_ATTRIBUTES = "REMOVE_ATTRIBUTES",
	GET_ATTRIBUTES = "GET_ATTRIBUTES",
	UPDATE_PICTURE_URL = "UPDATE_PICTURE_URL",
	UPDATE_CONTACT_EMAIL = "UPDATE_CONTACT_EMAIL",
	READ = "READ",
	UPDATE_NAME = "UPDATE_NAME",
	LOGOUT = "LOGOUT",
	CLEAR_USER_STATUS = "CLEAR_USER_STATUS",
	EXTEND_USER_STATUS = "EXTEND_USER_STATUS",
	GET_USER_STATUS = "GET_USER_STATUS",
	SET_USER_STATUS = "SET_USER_STATUS",
	UPDATE_TIMEZONE_OFFSET = "UPDATE_TIMEZONE_OFFSET",
	UPDATE_LANGUAGE_CODE = "UPDATE_LANGUAGE_CODE",
}

--- Helper debug logger
local function debugLog(client, ...)
	if client and client.debug then
		print("[BrainCloud][PLAYERSTATE]", ...)
	end
end


--- Constructor

--- Creates a new PlayerState service instance.
--- @param baseClient table The brainCloud client instance.
--- @return PlayerState
function PlayerState.new(baseClient)
	local self = setmetatable({}, PlayerState)
	self.client = baseClient
	return self
end


--- PlayerState API

--- Completely deletes the user record and all data fully owned
-- by the user. After calling this method, the user will need
-- to re-authenticate and create a new profile.
-- This is mostly used for debugging/qa.
-- Service Name - playerState
-- Service Operation - FULL_PLAYER_RESET
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:deleteUser(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.FULL_PLAYER_RESET, data, callback)
end

--- This method will delete *most* data for the currently logged in user.
-- Data which is not deleted includes: currency, credentials, and
-- purchase transactions. ResetUser is different from DeleteUser in that
-- the user record will continue to exist after the reset (so the user
-- does not need to re-authenticate).
-- Service Name - playerState
-- Service Operation - GAME_DATA_RESET
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:resetUserState(callback)
	self:resetUser(callback)
end

function PlayerState:resetUser(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.GAME_DATA_RESET, data, callback)
end

--- Retrieve the user's attributes.
-- Service Name - playerState
-- Service Operation - GET_ATTRIBUTES
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:getAttributes(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.GET_ATTRIBUTES, data, callback)
end

--- Update user's attributes.
-- Service Name - playerState
-- Service Operation - UPDATE_ATTRIBUTES
-- 
-- @param jsonAttributes Single layer json string that is a set of key-value pairs
-- @param wipeExisting Whether to wipe existing attributes prior to update.
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:updateAttributes(attributes, wipeExisting, callback)
	local data = { attributes = attributes, wipeExisting = wipeExisting }
	self.client:sendRequest(SERVICE, OPS.UPDATE_ATTRIBUTES, data, callback)
end

--- Remove user's attributes.
-- Service Name - playerState
-- Service Operation - REMOVE_ATTRIBUTES
-- 
-- @param attributeNames Collection of attribute names.
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:removeAttributes(attributes, callback)
	local data = { attributes = attributes }
	self.client:sendRequest(SERVICE, OPS.REMOVE_ATTRIBUTES, data, callback)
end

--- Read the state of the currently logged in user.
-- This method returns a JSON object describing most of the
-- user's data: entities, statistics, level, currency.
-- Apps will typically call this method after authenticating to get an
-- up-to-date view of the user's data.
-- Service Name - playerState
-- Service Operation - READ
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:readUserState(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.READ, data, callback)
end

--- Sets the user's name.
--- Service Name - playerState
--- Service Operation - UPDATE_NAME
--- @param userName The name of the user
--- @param callback The method to be invoked when the server response is received
function PlayerState:updateUserName(name, callback)
	local data = { playerName = name }
	self.client:sendRequest(SERVICE, OPS.UPDATE_NAME, data, callback)
end

--- Updates the "friend summary data" associated with the logged in user.
-- Some operations will return this summary data. For instance the social
-- leaderboards will return the player's score in the leaderboard along
-- with the friend summary data. Generally this data is used to provide
-- a quick overview of the player without requiring a separate API call
-- to read their public stats or entity data.
-- Service Name - playerState
-- Service Operation - UPDATE_SUMMARY
-- 
-- @param jsonSummaryData A JSON string defining the summary data.
--        For example:
--        {
--        "xp":123,
--        "level":12,
--        "highScore":45123
--        }
-- @param callback Method to be invoked when the server response is received.
-- 
function PlayerState:updateSummaryFriendData(summaryFriendData, callback)
	local data = { summaryFriendData = summaryFriendData }
	self.client:sendRequest(SERVICE, OPS.UPDATE_SUMMARY, data, callback)
end

--- Update User picture URL.
-- Service Name - playerState
-- Service Operation - UPDATE_PICTURE_URL
-- 
-- @param pictureUrl URL to apply
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:updateUserPictureUrl(url, callback)
	local data = { playerPictureUrl = url }
	self.client:sendRequest(SERVICE, OPS.UPDATE_PICTURE_URL, data, callback)
end

--- Update the user's contact email.
-- Note this is unrelated to email authentication.
-- Service Name - playerState
-- Service Operation - UPDATE_CONTACT_EMAIL
-- 
-- @param contactEmail Updated email
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:updateContactEmail(email, callback)
	local data = { contactEmail = email }
	self.client:sendRequest(SERVICE, OPS.UPDATE_CONTACT_EMAIL, data, callback)
end

--- Logs out the user.
--- @param callback fun(response: table)
function PlayerState:logout(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.LOGOUT, data, callback)
end

--- Delete's the specified status
-- Service Name - playerState
-- Service Operation - CLEAR_USER_STATUS
-- 
-- @param statusName Updated email
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:clearUserStatus(statusName, callback)
	self.client:sendRequest(SERVICE, OPS.CLEAR_USER_STATUS, { statusName = statusName }, callback)
end

--- Stack user's statuses
-- Service Name - playerState
-- Service Operation - EXTEND_USER_STATUS
-- 
-- @param statusName Updated email
--        @param additionalSecs
--        @param details
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:extendUserStatus(statusName, additionalSecs, details, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.EXTEND_USER_STATUS,
		{ statusName = statusName, additionalSecs = additionalSecs, details = details },
		callback
	)
end

--- Get user status
-- Service Name - playerState
-- Service Operation - GET_USER_STATUS
-- 
-- @param statusName Updated email
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:getUserStatus(statusName, callback)
	self.client:sendRequest(SERVICE, OPS.GET_USER_STATUS, { statusName = statusName }, callback)
end

--- Set timed status for a user
-- Service Name - playerState
-- Service Operation - SET_USER_STATUS
-- 
-- @param statusName Updated email
--        @param durationSecs
--        @param details
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:setUserStatus(statusName, durationSecs, details, callback)
	self.client:sendRequest(
		SERVICE,
		OPS.SET_USER_STATUS,
		{ statusName = statusName, durationSecs = durationSecs, details = details },
		callback
	)
end

--- Remove user's attributes.
-- Service Name - playerState
-- Service Operation - REMOVE_ATTRIBUTES
-- 
-- @param attributeNames Collection of attribute names.
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:updateTimeZoneOffset(offset, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_TIMEZONE_OFFSET, { timeZoneOffset = offset }, callback)
end

--- Remove user's attributes.
-- Service Name - playerState
-- Service Operation - REMOVE_ATTRIBUTES
-- 
-- @param attributeNames Collection of attribute names.
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerState:updateLanguageCode(code, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_LANGUAGE_CODE, { languageCode = code }, callback)
end


return PlayerState
