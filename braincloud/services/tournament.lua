local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local Tournament = {}
Tournament.__index = Tournament

local SERVICE = "tournament"

local OPS = {
	CLAIM_TOURNAMENT_REWARD = "CLAIM_TOURNAMENT_REWARD",
	GET_DIVISION_INFO = "GET_DIVISION_INFO",
	GET_MY_DIVISIONS = "GET_MY_DIVISIONS",
	GET_TOURNAMENT_STATUS = "GET_TOURNAMENT_STATUS",
	JOIN_DIVISION = "JOIN_DIVISION",
	JOIN_TOURNAMENT = "JOIN_TOURNAMENT",
	LEAVE_DIVISION_INSTANCE = "LEAVE_DIVISION_INSTANCE",
	LEAVE_TOURNAMENT = "LEAVE_TOURNAMENT",
	POST_TOURNAMENT_SCORE = "POST_TOURNAMENT_SCORE",
	POST_TOURNAMENT_SCORE_WITH_RESULTS = "POST_TOURNAMENT_SCORE_WITH_RESULTS",
	VIEW_CURRENT_REWARD = "VIEW_CURRENT_REWARD",
	VIEW_REWARD = "VIEW_REWARD",
	-- Group tournament operations
	GET_GROUP_TOURNAMENT_STATUS = "GET_GROUP_TOURNAMENT_STATUS",
	GET_GROUP_DIVISION_INFO = "GET_GROUP_DIVISION_INFO",
	GET_GROUP_DIVISIONS = "GET_GROUP_DIVISIONS",
	JOIN_GROUP_DIVISION = "JOIN_GROUP_DIVISION",
	JOIN_GROUP_TOURNAMENT = "JOIN_GROUP_TOURNAMENT",
	LEAVE_GROUP_TOURNAMENT = "LEAVE_GROUP_TOURNAMENT",
	LEAVE_GROUP_DIVISION_INSTANCE = "LEAVE_GROUP_DIVISION_INSTANCE",
	POST_GROUP_TOURNAMENT_SCORE = "POST_GROUP_TOURNAMENT_SCORE",
	POST_GROUP_TOURNAMENT_SCORE_WITH_RESULTS = "POST_GROUP_TOURNAMENT_SCORE_WITH_RESULTS",
}

--- Creates a new Tournament service instance.
--- @param brainCloudClient table
--- @return Tournament
function Tournament.new(brainCloudClient)
	local self = setmetatable({}, Tournament)
	self.client = brainCloudClient
	return self
end

--- Processes any outstanding rewards for the given player
--- Service Name - tournament
--- Service Operation - CLAIM_TOURNAMENT_REWARD
--- @param leaderboardId The leaderboard for the tournament
--- @param versionId Version of the tournament. Use -1 for the latest version.
--- @param callback The method to be invoked when the server response is received
function Tournament:claimTournamentReward(leaderboardId, versionId, callback)
	local data = { leaderboardId = leaderboardId, versionId = versionId }
	self.client:sendRequest(SERVICE, OPS.CLAIM_TOURNAMENT_REWARD, data, callback)
end

--- Get the status of a division
--- Service Name - tournament
--- Service Operation - GET_DIVISION_INFO
--- @param divSetId The id for the division
--- @param callback The method to be invoked when the server response is received
function Tournament:getDivisionInfo(divSetId, callback)
	local data = { divSetId = divSetId }
	self.client:sendRequest(SERVICE, OPS.GET_DIVISION_INFO, data, callback)
end

--- Get the status of a group division
-- Service Name - tournament
-- Service Operation - GET_GROUP_DIVISION_INFO
-- 
-- @param divSetId The id for the division
-- @param groupId The id of the group
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:getGroupDivisionInfo(divSetId, groupId, callback)
	local data = { divSetId = divSetId, groupId = groupId }
	self.client:sendRequest(SERVICE, OPS.GET_GROUP_DIVISION_INFO, data, callback)
end

--- Returns list of player's recently active divisions
--- Service Name - tournament
--- Service Operation - GET_MY_DIVISIONS
--- @param callback The method to be invoked when the server response is received
function Tournament:getMyDivisions(callback)
	self.client:sendRequest(SERVICE, OPS.GET_MY_DIVISIONS, nil, callback)
end

--- Returns list of group's recently active divisions
-- Service Name - tournament
-- Service Operation - GET_GROUP_DIVISIONS
-- 
-- @param groupId The id of the group
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:getGroupDivisions(groupId, callback)
	local data = { groupId = groupId }
	self.client:sendRequest(SERVICE, OPS.GET_GROUP_DIVISIONS, data, callback)
end

--- Get tournament status associated with a leaderboard
--- Service Name - tournament
--- Service Operation - GET_TOURNAMENT_STATUS
--- @param leaderboardId The leaderboard for the tournament
--- @param versionId Version of the tournament. Use -1 for the latest version.
--- @param callback The method to be invoked when the server response is received
function Tournament:getTournamentStatus(leaderboardId, versionId, callback)
	local data = { leaderboardId = leaderboardId, versionId = versionId }
	self.client:sendRequest(SERVICE, OPS.GET_TOURNAMENT_STATUS, data, callback)
end

--- Get tournament status associated with a group leaderboard
-- Service Name - tournament
-- Service Operation - GET_GROUP_TOURNAMENT_STATUS
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param groupId The id of the group
-- @param versionId Version of the tournament. Use -1 for the latest version.
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:getGroupTournamentStatus(leaderboardId, groupId, versionId, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId, versionId = versionId }
	self.client:sendRequest(SERVICE, OPS.GET_GROUP_TOURNAMENT_STATUS, data, callback)
end

--- Join the specified division.
-- If joining requires a fee, it is possible to fail at joining the division
-- Service Name - tournament
-- Service Operation - JODIVISION
-- 
-- @param divSetId The id for the division
-- @param tournamentCode Tournament to join
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:joinDivision(divSetId, tournamentCode, initialScore, callback)
	local data = { divSetId = divSetId, tournamentCode = tournamentCode, initialScore = initialScore }
	self.client:sendRequest(SERVICE, OPS.JOIN_DIVISION, data, callback)
end

--- Join the specified group division.
-- Service Name - tournament
-- Service Operation - JOIN_GROUP_DIVISION
-- 
-- @param divSetId The id for the division
-- @param tournamentCode Tournament to join
-- @param groupId The id of the group
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:joinGroupDivision(divSetId, tournamentCode, groupId, initialScore, callback)
	local data =
		{ divSetId = divSetId, tournamentCode = tournamentCode, groupId = groupId, initialScore = initialScore }
	self.client:sendRequest(SERVICE, OPS.JOIN_GROUP_DIVISION, data, callback)
end

--- Join the specified tournament.
-- Any entry fees will be automatically collected.
-- Service Name - tournament
-- Service Operation - JOTOURNAMENT
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param tournamentCode Tournament to join
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:joinTournament(leaderboardId, tournamentCode, initialScore, callback)
	local data = { leaderboardId = leaderboardId, tournamentCode = tournamentCode, initialScore = initialScore }
	self.client:sendRequest(SERVICE, OPS.JOIN_TOURNAMENT, data, callback)
end

--- Join the specified group tournament.
-- Service Name - tournament
-- Service Operation - JOIN_GROUP_TOURNAMENT
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param tournamentCode Tournament to join
-- @param groupId The id of the group
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:joinGroupTournament(leaderboardId, tournamentCode, groupId, initialScore, callback)
	local data = {
		leaderboardId = leaderboardId,
		tournamentCode = tournamentCode,
		groupId = groupId,
		initialScore = initialScore,
	}
	self.client:sendRequest(SERVICE, OPS.JOIN_GROUP_TOURNAMENT, data, callback)
end

--- Removes player from division instance
--- Also removes division instance from player's division list
--- Service Name - tournament
--- Service Operation - LEAVE_DIVISION_INSTANCE
--- @param leaderboardId The leaderboard for the tournament
--- @param callback The method to be invoked when the server response is received
function Tournament:leaveDivisionInstance(leaderboardId, callback)
	local data = { leaderboardId = leaderboardId }
	self.client:sendRequest(SERVICE, OPS.LEAVE_DIVISION_INSTANCE, data, callback)
end

--- Removes group from division instance
-- Service Name - tournament
-- Service Operation - LEAVE_GROUP_DIVISION_INSTANCE
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param groupId The id of the group
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:leaveGroupDivisionInstance(leaderboardId, groupId, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId }
	self.client:sendRequest(SERVICE, OPS.LEAVE_GROUP_DIVISION_INSTANCE, data, callback)
end

--- Removes player's score from tournament leaderboard
--- Service Name - tournament
--- Service Operation - LEAVE_TOURNAMENT
--- @param leaderboardId The leaderboard for the tournament
--- @param callback The method to be invoked when the server response is received
function Tournament:leaveTournament(leaderboardId, callback)
	local data = { leaderboardId = leaderboardId }
	self.client:sendRequest(SERVICE, OPS.LEAVE_TOURNAMENT, data, callback)
end

--- Removes group from tournament leaderboard
-- Service Name - tournament
-- Service Operation - LEAVE_GROUP_TOURNAMENT
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param groupId The id of the group
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:leaveGroupTournament(leaderboardId, groupId, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId }
	self.client:sendRequest(SERVICE, OPS.LEAVE_GROUP_TOURNAMENT, data, callback)
end

--- Post the users score to the leaderboard - UTC time
-- Service Name - tournament
-- Service Operation - POST_TOURNAMENT_SCORE
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param score The score to post
-- @param jsonData Optional data attached to the leaderboard entry
-- @param roundStartedTimeUTC Time the user started the match resulting in the score being posted in UTC. Use UTC time in milliseconds since epoch
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:postTournamentScoreUTC(leaderboardId, score, data, roundStartedEpoch, callback)
	local payload = { leaderboardId = leaderboardId, score = score, roundStartedEpoch = roundStartedEpoch }
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then
		payload.data = fixedData
	end
	self.client:sendRequest(SERVICE, OPS.POST_TOURNAMENT_SCORE, payload, callback)
end

--- Post the group's score to the tournament leaderboard
-- Service Name - tournament
-- Service Operation - POST_GROUP_TOURNAMENT_SCORE
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param groupId The id of the group
-- @param score The score to post
-- @param jsonData Optional data attached to the leaderboard entry
-- @param roundStartedTimeUTC Time the round started in UTC milliseconds since epoch
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:postGroupTournamentScore(leaderboardId, groupId, score, data, roundStartedEpoch, callback)
	local payload =
		{ leaderboardId = leaderboardId, groupId = groupId, score = score, roundStartedEpoch = roundStartedEpoch }
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then
		payload.data = fixedData
	end
	self.client:sendRequest(SERVICE, OPS.POST_GROUP_TOURNAMENT_SCORE, payload, callback)
end

--- Post the users score to the leaderboard - UTC time
-- Service Name - tournament
-- Service Operation - POST_TOURNAMENT_SCORE_WITH_RESULTS
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param score The score to post
-- @param jsonData Optional data attached to the leaderboard entry
-- @param roundStartedTimeUTC Time the user started the match resulting in the score being posted in UTC. Use UTC time in milliseconds since epoch
-- @param sort Sort key Sort order of page.
-- @param beforeCount The count of number of players before the current player to include.
-- @param afterCount The count of number of players after the current player to include.
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:postTournamentScoreWithResultsUTC(
	leaderboardId,
	score,
	data,
	roundStartedEpoch,
	sort,
	beforeCount,
	afterCount,
	initialScore,
	callback
)
	local payload = {
		leaderboardId = leaderboardId,
		score = score,
		roundStartedEpoch = roundStartedEpoch,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
		initialScore = initialScore,
	}
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then
		payload.data = fixedData
	end
	self.client:sendRequest(SERVICE, OPS.POST_TOURNAMENT_SCORE_WITH_RESULTS, payload, callback)
end

--- Post the group's score to the tournament leaderboard and return results
-- Service Name - tournament
-- Service Operation - POST_GROUP_TOURNAMENT_SCORE_WITH_RESULTS
-- 
-- @param leaderboardId The leaderboard for the tournament
-- @param groupId The id of the group
-- @param score The score to post
-- @param jsonData Optional data attached to the leaderboard entry
-- @param roundStartedTimeUTC Time the round started in UTC milliseconds since epoch
-- @param sort Sort order of page
-- @param beforeCount The count of number of players before the current player to include
-- @param afterCount The count of number of players after the current player to include
-- @param initialScore The initial score for players first joining a tournament
--        Usually 0, unless leaderboard is LOW_VALUE
-- @param callback The method to be invoked when the server response is received
-- 
function Tournament:postGroupTournamentScoreWithResults(
	leaderboardId,
	groupId,
	score,
	data,
	roundStartedEpoch,
	sort,
	beforeCount,
	afterCount,
	initialScore,
	callback
)
	local payload = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		score = score,
		roundStartedEpoch = roundStartedEpoch,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
		initialScore = initialScore,
	}
	local fixedData = Utils.emptyFix(data)
	if next(fixedData) then
		payload.data = fixedData
	end
	self.client:sendRequest(SERVICE, OPS.POST_GROUP_TOURNAMENT_SCORE_WITH_RESULTS, payload, callback)
end

--- Returns the user's expected reward based on the current scores
--- Service Name - tournament
--- Service Operation - VIEW_CURRENT_REWARD
--- @param leaderboardId The leaderboard for the tournament
--- @param callback The method to be invoked when the server response is received
function Tournament:viewCurrentReward(leaderboardId, callback)
	local data = { leaderboardId = leaderboardId }
	self.client:sendRequest(SERVICE, OPS.VIEW_CURRENT_REWARD, data, callback)
end

--- Returns the user's reward from a finished tournament
--- Service Name - tournament
--- Service Operation - VIEW_REWARD
--- @param leaderboardId The leaderboard for the tournament
--- @param versionId Version of the tournament. Use -1 for the latest version.
--- @param callback The method to be invoked when the server response is received
function Tournament:viewReward(leaderboardId, versionId, callback)
	local data = { leaderboardId = leaderboardId, versionId = versionId }
	self.client:sendRequest(SERVICE, OPS.VIEW_REWARD, data, callback)
end

return Tournament
