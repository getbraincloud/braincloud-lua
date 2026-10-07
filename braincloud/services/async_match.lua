local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

---@class AsyncMatch
---@field client table brainCloud client instance
local AsyncMatch = {}
AsyncMatch.__index = AsyncMatch

local SERVICE = "asyncMatch"

---@private
---@type table<string, string>
local OPS = {
	SUBMIT_TURN = "SUBMIT_TURN",
	UPDATE_SUMMARY = "UPDATE_SUMMARY",
	ABANDON = "ABANDON",
	COMPLETE = "COMPLETE",
	CREATE = "CREATE",
	READ_MATCH = "READ_MATCH",
	READ_MATCH_HISTORY = "READ_MATCH_HISTORY",
	FIND_MATCHES = "FIND_MATCHES",
	FIND_MATCHES_COMPLETED = "FIND_MATCHES_COMPLETED",
	DELETE_MATCH = "DELETE_MATCH",
	ABANDON_MATCH_WITH_SUMMARY_DATA = "ABANDON_MATCH_WITH_SUMMARY_DATA",
	COMPLETE_MATCH_WITH_SUMMARY_DATA = "COMPLETE_MATCH_WITH_SUMMARY_DATA",
	UPDATE_MATCH_STATE_CURRENT_TURN = "UPDATE_MATCH_STATE_CURRENT_TURN",
}

--- Constructor

---@param baseClient table brainCloud client instance
---@return AsyncMatch
function AsyncMatch.new(baseClient)
	local self = setmetatable({}, AsyncMatch)
	self.client = baseClient
	return self
end

--- CREATE MATCH

--- Creates an instance of an asynchronous match.
-- Service Name - asyncMatch
-- Service Operation - CREATE
-- 
-- @param jsonOpponentIds JSON string identifying the opponent platform and id for this match.
--        Platforms are identified as:
--        BC - a brainCloud profile id
--        FB - a Facebook id
--        An exmaple of this string would be:
--        [
--        {
--        "platform": "BC",
--        "id": "some-braincloud-profile"
--        },
--        {
--        "platform": "FB",
--        "id": "some-facebook-id"
--        }
--        ]
-- @param pushNotificationMessage Optional push notification message to send to the other party.
--        Refer to the Push Notification functions for the syntax required.
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:createMatch(opponentIds, pushNotificationMessage, callback)
	local data = { players = Utils.array(opponentIds) }
	if pushNotificationMessage then
		data.pushContent = pushNotificationMessage
	end

	self.client:sendRequest(SERVICE, OPS.CREATE, data, callback)
end

--- Creates an instance of an asynchronous match with an initial turn.
-- Service Name - asyncMatch
-- Service Operation - CREATE
-- 
-- @param jsonOpponentIds JSON string identifying the opponent platform and id for this match.
--        Platforms are identified as:
--        BC - a brainCloud profile id
--        FB - a Facebook id
--        An exmaple of this string would be:
--        [
--        {
--        "platform": "BC",
--        "id": "some-braincloud-profile"
--        },
--        {
--        "platform": "FB",
--        "id": "some-facebook-id"
--        }
--        ]
-- @param jsonMatchState JSON string blob provided by the caller
-- @param pushNotificationMessage Optional push notification message to send to the other party.
--        Refer to the Push Notification functions for the syntax required.
-- @param nextPlayer Optionally, force the next player player to be a specific player
-- @param jsonSummary Optional JSON string defining what the other player will see as a summary of the game when listing their games
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:createMatchWithInitialTurn(
	opponentIds,
	matchState,
	pushNotificationMessage,
	nextPlayer,
	summary,
	callback
)
	local data = {
		players = Utils.array(opponentIds),
		matchState = Utils.emptyFix(matchState),
	}
	if pushNotificationMessage then
		data.pushContent = pushNotificationMessage
	end
	if nextPlayer then
		data.status = { currentPlayer = nextPlayer }
	end
	if summary then
		data.summary = summary
	end
	self.client:sendRequest(SERVICE, OPS.CREATE, data, callback)
end

--- READ MATCH + HISTORY

--- Returns the current state of the given match.
-- Service Name - asyncMatch
-- Service Operation - READ_MATCH
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:readMatch(ownerId, matchId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_MATCH, { ownerId = ownerId, matchId = matchId }, callback)
end

--- Returns the match history of the given match.
-- Service Name - asyncMatch
-- Service Operation - READ_MATCH_HISTORY
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:readMatchHistory(ownerId, matchId, callback)
	self.client:sendRequest(SERVICE, OPS.READ_MATCH_HISTORY, { ownerId = ownerId, matchId = matchId }, callback)
end

--- SUBMIT TURN

--- Submits a turn for the given match.
-- Service Name - asyncMatch
-- Service Operation - SUBMIT_TURN
-- 
-- @param ownerId Match owner identfier
-- @param matchId Match identifier
-- @param version Game state version to ensure turns are submitted once and in order
-- @param jsonMatchState JSON string provided by the caller
-- @param pushNotificationMessage Optional push notification message to send to the other party.
--        Refer to the Push Notification functions for the syntax required.
-- @param nextPlayer Optionally, force the next player player to be a specific player
-- @param jsonSummary Optional JSON string that other players will see as a summary of the game when listing their games
-- @param jsonStatistics Optional JSON string blob provided by the caller
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:submitTurn(
	ownerId,
	matchId,
	version,
	matchState,
	pushNotificationMessage,
	nextPlayer,
	summary,
	statistics,
	callback
)
	local data = {
		ownerId = ownerId,
		matchId = matchId,
		version = version,
		matchState = Utils.emptyFix(matchState),
	}
	if nextPlayer then
		data.status = { currentPlayer = nextPlayer }
	end
	if summary then
		data.summary = summary
	end
	if statistics then
		data.statistics = statistics
	end
	if pushNotificationMessage then
		data.pushContent = pushNotificationMessage
	end
	self.client:sendRequest(SERVICE, OPS.SUBMIT_TURN, data, callback)
end

--- UPDATE MATCH SUMMARY

--- Allows the current player (only) to update Summary data without having to submit a whole turn.
-- Service Name - asyncMatch
-- Service Operation - UPDATE_SUMMARY
-- 
-- @param ownerId Match owner identfier
-- @param matchId Match identifier
-- @param version Game state version to ensure turns are submitted once and in order
-- @param jsonSummary JSON string that other players will see as a summary of the game when listing their games
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:updateMatchSummaryData(ownerId, matchId, version, summary, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_SUMMARY, {
		ownerId = ownerId,
		matchId = matchId,
		version = version,
		summary = summary,
	}, callback)
end

--- ABANDON / COMPLETE / DELETE

--- Marks the given match as abandoned.
-- Service Name - asyncMatch
-- Service Operation - ABANDON
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:abandonMatch(ownerId, matchId, callback)
	self.client:sendRequest(SERVICE, OPS.ABANDON, { ownerId = ownerId, matchId = matchId }, callback)
end

--- Marks the given match as complete.
-- Service Name - asyncMatch
-- Service Operation - COMPLETE
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:completeMatch(ownerId, matchId, callback)
	self.client:sendRequest(SERVICE, OPS.COMPLETE, { ownerId = ownerId, matchId = matchId }, callback)
end

--- Removes the match and match history from the server. DEBUG ONLY, in production it is recommended
-- the user leave it as completed.
-- Service Name - asyncMatch
-- Service Operation - DELETE
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:deleteMatch(ownerId, matchId, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_MATCH, { ownerId = ownerId, matchId = matchId }, callback)
end

--- ABANDON / COMPLETE WITH SUMMARY DATA

--- Marks the given match as abandoned. This call can send a notification message.
-- Service Name - asyncMatch
-- Service Operation - ABANDON_MATCH_WITH_SUMMARY_DATA
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
--        @param pushContent
--        @param summary
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:abandonMatchWithSummaryData(ownerId, matchId, pushContent, summary, callback)
	self.client:sendRequest(SERVICE, OPS.ABANDON_MATCH_WITH_SUMMARY_DATA, {
		ownerId = ownerId,
		matchId = matchId,
		pushContent = pushContent,
		summary = summary,
	}, callback)
end

--- Marks the given match as complete. This call can send a notification message.
-- Service Name - asyncMatch
-- Service Operation - COMPLETE_MATCH_WITH_SUMMARY_DATA
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
--        @param pushContent
--        @param summary
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:completeMatchWithSummaryData(ownerId, matchId, pushContent, summary, callback)
	self.client:sendRequest(SERVICE, OPS.COMPLETE_MATCH_WITH_SUMMARY_DATA, {
		ownerId = ownerId,
		matchId = matchId,
		pushContent = pushContent,
		summary = summary,
	}, callback)
end

--- UPDATE MATCH STATE CURRENT TURN

--- Allows the current player in the game to overwrite the matchState and
-- statistics without completing their turn or adding to matchHistory.
-- *
-- Service Name - asyncMatch
-- Service Operation - UPDATE_MATCH_STATE_CURRENT_TURN
-- 
-- @param ownerId Match owner identifier
-- @param matchId Match identifier
-- @param version Game state version being updated, to ensure data integrity
-- @param jsonMatchState JSON string provided by the caller Required.
-- @param jsonStatistics Optional JSON string provided by the caller.
--        @param callback
-- 
function AsyncMatch:updateMatchStateCurrentTurn(ownerId, matchId, version, matchState, statistics, callback)
	local data = {
		ownerId = ownerId,
		matchId = matchId,
		version = version,
		matchState = Utils.emptyFix(matchState),
	}
	if statistics then
		data.statistics = statistics
	end
	self.client:sendRequest(SERVICE, OPS.UPDATE_MATCH_STATE_CURRENT_TURN, data, callback)
end

--- FIND MATCHES

--- Returns all matches that are NOT in a COMPLETE state for which the player is involved.
-- Service Name - asyncMatch
-- Service Operation - FIND_MATCHES
-- 
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:findMatches(callback)
	self.client:sendRequest(SERVICE, OPS.FIND_MATCHES, {}, callback)
end

--- Returns all matches that are in a COMPLETE state for which the player is involved.
-- Service Name - asyncMatch
-- Service Operation - FIND_MATCHES_COMPLETED
-- 
-- @param callback Optional instance of IServerCallback to call when the server response is received.
-- 
function AsyncMatch:findCompleteMatches(callback)
	self.client:sendRequest(SERVICE, OPS.FIND_MATCHES_COMPLETED, {}, callback)
end

return AsyncMatch
