local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local MatchMaking = {}
MatchMaking.__index = MatchMaking

local SERVICE = "matchMaking"

local OPS = {
	READ = "READ",
	SET_PLAYER_RATING = "SET_PLAYER_RATING",
	RESET_PLAYER_RATING = "RESET_PLAYER_RATING",
	INCREMENT_PLAYER_RATING = "INCREMENT_PLAYER_RATING",
	DECREMENT_PLAYER_RATING = "DECREMENT_PLAYER_RATING",
	SHIELD_ON = "SHIELD_ON",
	SHIELD_ON_FOR = "SHIELD_ON_FOR",
	SHIELD_OFF = "SHIELD_OFF",
	INCREMENT_SHIELD_ON_FOR = "INCREMENT_SHIELD_ON_FOR",
	GET_SHIELD_EXPIRY = "GET_SHIELD_EXPIRY",
	FIND_PLAYERS = "FIND_PLAYERS",
	FIND_PLAYERS_USING_FILTER = "FIND_PLAYERS_USING_FILTER",
	ENABLE_FOR_MATCH = "ENABLE_FOR_MATCH",
	DISABLE_FOR_MATCH = "DISABLE_FOR_MATCH",
}

--- Creates a new MatchMaking instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return MatchMaking
function MatchMaking.new(brainCloudClient)
	local self = setmetatable({}, MatchMaking)
	self.client = brainCloudClient
	return self
end

--- Read match making record
--- @param callback fun(success:boolean, response:table)|nil
function MatchMaking:read(callback)
	self.client:sendRequest(SERVICE, OPS.READ, {}, callback)
end

--- Sets player rating
-- Service Name - matchMaking
-- Service Operation - SET_PLAYER_RATING
-- 
-- @param playerRating The new player rating.
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:setPlayerRating(playerRating, callback)
	local data = { playerRating = playerRating }
	self.client:sendRequest(SERVICE, OPS.SET_PLAYER_RATING, data, callback)
end

--- Resets player rating
-- Service Name - matchMaking
-- Service Operation - RESET_PLAYER_RATING
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:resetPlayerRating(callback)
	self.client:sendRequest(SERVICE, OPS.RESET_PLAYER_RATING, {}, callback)
end

--- Increments player rating
-- Service Name - matchMaking
-- Service Operation - INCREMENT_PLAYER_RATING
-- 
-- @param increment The increment amount
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:incrementPlayerRating(increment, callback)
	local data = { playerRating = increment }
	self.client:sendRequest(SERVICE, OPS.INCREMENT_PLAYER_RATING, data, callback)
end

--- Decrements player rating
-- Service Name - matchMaking
-- Service Operation - DECREMENT_PLAYER_RATING
-- 
-- @param decrement The decrement amount
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:decrementPlayerRating(decrement, callback)
	local data = { playerRating = decrement }
	self.client:sendRequest(SERVICE, OPS.DECREMENT_PLAYER_RATING, data, callback)
end

--- Turns shield on
-- Service Name - matchMaking
-- Service Operation - SHIELD_ON
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:turnShieldOn(callback)
	self.client:sendRequest(SERVICE, OPS.SHIELD_ON, {}, callback)
end

--- Turns shield on for the specified number of minutes
-- Service Name - matchMaking
-- Service Operation - SHIELD_ON_FOR
-- 
-- @param minutes Number of minutes to turn the shield on for
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:turnShieldOnFor(minutes, callback)
	local data = { minutes = minutes }
	self.client:sendRequest(SERVICE, OPS.SHIELD_ON_FOR, data, callback)
end

--- Turns shield off
-- Service Name - matchMaking
-- Service Operation - SHIELD_OFF
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:turnShieldOff(callback)
	self.client:sendRequest(SERVICE, OPS.SHIELD_OFF, {}, callback)
end

--- Increases the shield on time by specified number of minutes
-- Service Name - matchMaking
-- Service Operation - INCREMENT_SHIELD_ON_FOR
-- 
-- @param minutes Number of minutes to increase the shield time for
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:incrementShieldOnFor(minutes, callback)
	local data = { minutes = minutes }
	self.client:sendRequest(SERVICE, OPS.INCREMENT_SHIELD_ON_FOR, data, callback)
end

--- Gets the shield expiry for the given player id. Passing in a null player id
-- will return the shield expiry for the current player. The value returned is
-- the time in UTC millis when the shield will expire.
-- Service Name - matchMaking
-- Service Operation - GET_SHIELD_EXPIRY
-- 
-- @param playerId The player id or use null to retrieve for the current player
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:getShieldExpiry(playerId, callback)
	local data = {}
	if playerId then
		data.playerId = playerId
	end
	self.client:sendRequest(SERVICE, OPS.GET_SHIELD_EXPIRY, data, callback)
end

--- Finds matchmaking enabled players
-- Service Name - matchMaking
-- Service Operation - FIND_PLAYERS
-- 
-- @param rangeDelta The range delta
-- @param numMatches The maximum number of matches to return
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:findPlayers(rangeDelta, numMatches, callback)
	self:findPlayersWithAttributes(rangeDelta, numMatches, nil, callback)
end

--- Finds matchmaking enabled players with additional attributes
-- Service Name - matchMaking
-- Service Operation - FIND_PLAYERS
-- 
-- @param rangeDelta The range delta
-- @param numMatches The maximum number of matches to return
-- @param jsonAttributes Attributes match criteria
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:findPlayersWithAttributes(rangeDelta, numMatches, jsonAttributes, callback)
	local data = { rangeDelta = rangeDelta, numMatches = numMatches }
	if jsonAttributes then
		data.attributes = jsonAttributes
	end
	self.client:sendRequest(SERVICE, OPS.FIND_PLAYERS, data, callback)
end

--- Finds matchmaking enabled players
-- Service Name - matchMaking
-- Service Operation - FIND_PLAYERS_USING_FILTER
-- 
-- @param rangeDelta The range delta
-- @param numMatches The maximum number of matches to return
-- @param jsonExtraParms Parameters to pass to the CloudCode filter script
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:findPlayersUsingFilter(rangeDelta, numMatches, extraParms, callback)
	self:findPlayersWithAttributesUsingFilter(rangeDelta, numMatches, nil, extraParms, callback)
end

--- Finds matchmaking enabled players using a cloud code filter
-- and additional attributes
-- Service Name - matchMaking
-- Service Operation - FIND_PLAYERS_USING_FILTER
-- 
-- @param rangeDelta The range delta
-- @param numMatches The maximum number of matches to return
-- @param jsonAttributes Attributes match criteria
-- @param jsonExtraParms Parameters to pass to the CloudCode filter script
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:findPlayersWithAttributesUsingFilter(rangeDelta, numMatches, jsonAttributes, extraParms, callback)
	local data = { rangeDelta = rangeDelta, numMatches = numMatches }
	if jsonAttributes then
		data.attributes = jsonAttributes
	end
	if extraParms then
		data.extraParms = extraParms
	end
	self.client:sendRequest(SERVICE, OPS.FIND_PLAYERS_USING_FILTER, data, callback)
end

--- Enables Match Making for the Player
-- Service Name - matchMaking
-- Service Operation - ENABLE_FOR_MATCH
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:enableMatchMaking(callback)
	self.client:sendRequest(SERVICE, OPS.ENABLE_FOR_MATCH, {}, callback)
end

--- Disables Match Making for the Player
-- Service Name - matchMaking
-- Service Operation - ENABLE_FOR_MATCH
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function MatchMaking:disableMatchMaking(callback)
	self.client:sendRequest(SERVICE, OPS.DISABLE_FOR_MATCH, {}, callback)
end

return MatchMaking
