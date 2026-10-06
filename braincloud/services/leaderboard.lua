local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local Leaderboard = {}
Leaderboard.__index = Leaderboard

local SERVICE = "leaderboard"

local OPS = {
	GET_SOCIAL_LEADERBOARD = "GET_SOCIAL_LEADERBOARD",
	GET_SOCIAL_LEADERBOARD_IF_EXISTS = "GET_SOCIAL_LEADERBOARD_IF_EXISTS",
	GET_SOCIAL_LEADERBOARD_BY_VERSION = "GET_SOCIAL_LEADERBOARD_BY_VERSION",
	GET_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS = "GET_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS",
	GET_MULTI_SOCIAL_LEADERBOARD = "GET_MULTI_SOCIAL_LEADERBOARD",
	GET_GLOBAL_LEADERBOARD_PAGE = "GET_GLOBAL_LEADERBOARD_PAGE",
	GET_GLOBAL_LEADERBOARD_PAGE_IF_EXISTS = "GET_GLOBAL_LEADERBOARD_PAGE_IF_EXISTS",
	GET_GLOBAL_LEADERBOARD_VIEW = "GET_GLOBAL_LEADERBOARD_VIEW",
	GET_GLOBAL_LEADERBOARD_VIEW_IF_EXISTS = "GET_GLOBAL_LEADERBOARD_VIEW_IF_EXISTS",
	GET_GLOBAL_LEADERBOARD_VERSIONS = "GET_GLOBAL_LEADERBOARD_VERSIONS",
	GET_GLOBAL_LEADERBOARD_ENTRY_COUNT = "GET_GLOBAL_LEADERBOARD_ENTRY_COUNT",
	GET_GROUP_SOCIAL_LEADERBOARD = "GET_GROUP_SOCIAL_LEADERBOARD",
	GET_GROUP_SOCIAL_LEADERBOARD_BY_VERSION = "GET_GROUP_SOCIAL_LEADERBOARD_BY_VERSION",
	GET_GROUP_LEADERBOARD_VIEW = "GET_GROUP_LEADERBOARD_VIEW",
	GET_PLAYERS_SOCIAL_LEADERBOARD = "GET_PLAYERS_SOCIAL_LEADERBOARD",
	GET_PLAYERS_SOCIAL_LEADERBOARD_IF_EXISTS = "GET_PLAYERS_SOCIAL_LEADERBOARD_IF_EXISTS",
	GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION = "GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION",
	GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS = "GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS",
	GET_PLAYER_SCORE = "GET_PLAYER_SCORE",
	GET_PLAYER_SCORES = "GET_PLAYER_SCORES",
	GET_PLAYER_SCORES_FROM_LEADERBOARDS = "GET_PLAYER_SCORES_FROM_LEADERBOARDS",
	LIST_ALL_LEADERBOARDS = "LIST_ALL_LEADERBOARDS",
	POST_SCORE = "POST_SCORE",
	POST_SCORE_DYNAMIC = "POST_SCORE_DYNAMIC",
	POST_SCORE_DYNAMIC_USING_CONFIG = "POST_SCORE_DYNAMIC_USING_CONFIG",
	POST_GROUP_SCORE = "POST_GROUP_SCORE",
	POST_GROUP_SCORE_DYNAMIC = "POST_GROUP_SCORE_DYNAMIC",
	POST_GROUP_SCORE_DYNAMIC_USING_CONFIG = "POST_GROUP_SCORE_DYNAMIC_USING_CONFIG",
	REMOVE_PLAYER_SCORE = "REMOVE_PLAYER_SCORE",
	REMOVE_GROUP_SCORE = "REMOVE_GROUP_SCORE",
}

--- Sort order values for the `sort` params.
Leaderboard.SortOrder = {
	HIGH_TO_LOW = "HIGH_TO_LOW",
	LOW_TO_HIGH = "LOW_TO_HIGH",
}

--- Leaderboard types for dynamic leaderboards.
Leaderboard.LeaderboardType = {
	HIGH_VALUE = "HIGH_VALUE",
	CUMULATIVE = "CUMULATIVE",
	LAST_VALUE = "LAST_VALUE",
	LOW_VALUE = "LOW_VALUE",
}

--- Rotation types for dynamic leaderboards.
Leaderboard.RotationType = {
	NEVER = "NEVER",
	DAILY = "DAILY",
	WEEKLY = "WEEKLY",
	MONTHLY = "MONTHLY",
	YEARLY = "YEARLY",
}

function Leaderboard.new(baseClient)
	local self = setmetatable({}, Leaderboard)
	self.client = baseClient
	return self
end

function Leaderboard:_send(operation, data, callback)
	self.client:sendRequest(SERVICE, operation, data, callback)
end

--- SOCIAL LEADERBOARDS

--- Method returns the social leaderboard. A player's social leaderboard is comprised of players who are
-- recognized as being your friend. The friends are ranked by their scores, including the current player.
-- Service Name - leaderboard
-- Service Operation - GET_SOCIAL_LEADERBOARD
--
-- @param leaderboardId The id of the leaderboard to retrieve
-- @param replaceName If true, the currently logged in player's name will be replaced by the string "You".
-- @param callback The method to be invoked when the server response is received
--
function Leaderboard:getSocialLeaderboard(leaderboardId, replaceName, callback)
	self:_send(OPS.GET_SOCIAL_LEADERBOARD, { leaderboardId = leaderboardId, replaceName = replaceName }, callback)
end

--- Same as getSocialLeaderboard, but returns no error when the leaderboard doesn't exist.
function Leaderboard:getSocialLeaderboardIfExists(leaderboardId, replaceName, callback)
	self:_send(OPS.GET_SOCIAL_LEADERBOARD_IF_EXISTS, { leaderboardId = leaderboardId, replaceName = replaceName }, callback)
end

--- Social leaderboard for a specific version.
-- Service Operation - GET_SOCIAL_LEADERBOARD_BY_VERSION
--
-- @param versionId The version of the leaderboard
function Leaderboard:getSocialLeaderboardByVersion(leaderboardId, replaceName, versionId, callback)
	local data = { leaderboardId = leaderboardId, replaceName = replaceName, versionId = versionId }
	self:_send(OPS.GET_SOCIAL_LEADERBOARD_BY_VERSION, data, callback)
end

--- Same as getSocialLeaderboardByVersion, but returns no error when the leaderboard doesn't exist.
function Leaderboard:getSocialLeaderboardByVersionIfExists(leaderboardId, replaceName, versionId, callback)
	local data = { leaderboardId = leaderboardId, replaceName = replaceName, versionId = versionId }
	self:_send(OPS.GET_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS, data, callback)
end

--- Reads multiple social leaderboards.
-- Service Operation - GET_MULTI_SOCIAL_LEADERBOARD
--
-- @param leaderboardIds Array of leaderboard ids
-- @param leaderboardResultCount Maximum count of entries to return for each leaderboard
-- @param replaceName If true, the currently logged in player's name will be replaced by the string "You".
function Leaderboard:getMultiSocialLeaderboard(leaderboardIds, leaderboardResultCount, replaceName, callback)
	local data = {
		leaderboardIds = Utils.array(leaderboardIds),
		leaderboardResultCount = leaderboardResultCount,
		replaceName = replaceName,
	}
	self:_send(OPS.GET_MULTI_SOCIAL_LEADERBOARD, data, callback)
end

--- Social leaderboard for the given profile ids.
-- Service Operation - GET_PLAYERS_SOCIAL_LEADERBOARD
function Leaderboard:getPlayersSocialLeaderboard(leaderboardId, profileIds, callback)
	self:_send(OPS.GET_PLAYERS_SOCIAL_LEADERBOARD, { leaderboardId = leaderboardId, profileIds = Utils.array(profileIds) }, callback)
end

function Leaderboard:getPlayersSocialLeaderboardIfExists(leaderboardId, profileIds, callback)
	local data = { leaderboardId = leaderboardId, profileIds = Utils.array(profileIds) }
	self:_send(OPS.GET_PLAYERS_SOCIAL_LEADERBOARD_IF_EXISTS, data, callback)
end

function Leaderboard:getPlayersSocialLeaderboardByVersion(leaderboardId, profileIds, versionId, callback)
	local data = { leaderboardId = leaderboardId, profileIds = Utils.array(profileIds), versionId = versionId }
	self:_send(OPS.GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION, data, callback)
end

function Leaderboard:getPlayersSocialLeaderboardByVersionIfExists(leaderboardId, profileIds, versionId, callback)
	local data = { leaderboardId = leaderboardId, profileIds = Utils.array(profileIds), versionId = versionId }
	self:_send(OPS.GET_PLAYERS_SOCIAL_LEADERBOARD_BY_VERSION_IF_EXISTS, data, callback)
end

--- GLOBAL LEADERBOARDS

--- Method returns a page of global leaderboard results.
-- Service Operation - GET_GLOBAL_LEADERBOARD_PAGE
--
-- @param leaderboardId The id of the leaderboard to retrieve.
-- @param sort Leaderboard.SortOrder value
-- @param startIndex The index at which to start the page.
-- @param endIndex The index at which to end the page.
function Leaderboard:getGlobalLeaderboardPage(leaderboardId, sort, startIndex, endIndex, callback)
	local data = { leaderboardId = leaderboardId, sort = sort, startIndex = startIndex, endIndex = endIndex }
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_PAGE, data, callback)
end

function Leaderboard:getGlobalLeaderboardPageIfExists(leaderboardId, sort, startIndex, endIndex, callback)
	local data = { leaderboardId = leaderboardId, sort = sort, startIndex = startIndex, endIndex = endIndex }
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_PAGE_IF_EXISTS, data, callback)
end

--- Page of a specific leaderboard version.
function Leaderboard:getGlobalLeaderboardPageByVersion(leaderboardId, sort, startIndex, endIndex, versionId, callback)
	local data = {
		leaderboardId = leaderboardId,
		sort = sort,
		startIndex = startIndex,
		endIndex = endIndex,
		versionId = versionId,
	}
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_PAGE, data, callback)
end

function Leaderboard:getGlobalLeaderboardPageByVersionIfExists(
	leaderboardId,
	sort,
	startIndex,
	endIndex,
	versionId,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		sort = sort,
		startIndex = startIndex,
		endIndex = endIndex,
		versionId = versionId,
	}
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_PAGE_IF_EXISTS, data, callback)
end

--- Method returns a view of global leaderboard results that centers on the current player.
-- Service Operation - GET_GLOBAL_LEADERBOARD_VIEW
--
-- @param beforeCount The count of number of players before the current player to include.
-- @param afterCount The count of number of players after the current player to include.
function Leaderboard:getGlobalLeaderboardView(leaderboardId, sort, beforeCount, afterCount, callback)
	self:getGlobalLeaderboardViewByVersion(leaderboardId, sort, beforeCount, afterCount, -1, callback)
end

function Leaderboard:getGlobalLeaderboardViewIfExists(leaderboardId, sort, beforeCount, afterCount, callback)
	self:getGlobalLeaderboardViewByVersionIfExists(leaderboardId, sort, beforeCount, afterCount, -1, callback)
end

function Leaderboard:getGlobalLeaderboardViewByVersion(leaderboardId, sort, beforeCount, afterCount, versionId, callback)
	local data = {
		leaderboardId = leaderboardId,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
		versionId = versionId,
	}
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_VIEW, data, callback)
end

function Leaderboard:getGlobalLeaderboardViewByVersionIfExists(
	leaderboardId,
	sort,
	beforeCount,
	afterCount,
	versionId,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
		versionId = versionId,
	}
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_VIEW_IF_EXISTS, data, callback)
end

--- Gets the global leaderboard versions.
-- Service Operation - GET_GLOBAL_LEADERBOARD_VERSIONS
function Leaderboard:getGlobalLeaderboardVersions(leaderboardId, callback)
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_VERSIONS, { leaderboardId = leaderboardId }, callback)
end

--- Gets the number of entries in a global leaderboard.
-- Service Operation - GET_GLOBAL_LEADERBOARD_ENTRY_COUNT
function Leaderboard:getGlobalLeaderboardEntryCount(leaderboardId, callback)
	self:getGlobalLeaderboardEntryCountByVersion(leaderboardId, -1, callback)
end

function Leaderboard:getGlobalLeaderboardEntryCountByVersion(leaderboardId, versionId, callback)
	self:_send(OPS.GET_GLOBAL_LEADERBOARD_ENTRY_COUNT, { leaderboardId = leaderboardId, versionId = versionId }, callback)
end

--- Lists all leaderboards defined for the app.
-- Service Operation - LIST_ALL_LEADERBOARDS
function Leaderboard:listAllLeaderboards(callback)
	self:_send(OPS.LIST_ALL_LEADERBOARDS, {}, callback)
end

--- PLAYER SCORES

--- Gets a player's score from a leaderboard.
-- Service Operation - GET_PLAYER_SCORE
--
-- @param versionId The version of the leaderboard. Use -1 for current.
function Leaderboard:getPlayerScore(leaderboardId, versionId, callback)
	self:_send(OPS.GET_PLAYER_SCORE, { leaderboardId = leaderboardId, versionId = versionId }, callback)
end

--- Gets a player's highest scores from a leaderboard.
-- Service Operation - GET_PLAYER_SCORES
--
-- @param maxResults The number of max results to return
function Leaderboard:getPlayerScores(leaderboardId, versionId, maxResults, callback)
	local data = { leaderboardId = leaderboardId, versionId = versionId, maxResults = maxResults }
	self:_send(OPS.GET_PLAYER_SCORES, data, callback)
end

--- Gets a player's score from multiple leaderboards.
-- Service Operation - GET_PLAYER_SCORES_FROM_LEADERBOARDS
function Leaderboard:getPlayerScoresFromLeaderboards(leaderboardIds, callback)
	self:_send(OPS.GET_PLAYER_SCORES_FROM_LEADERBOARDS, { leaderboardIds = Utils.array(leaderboardIds) }, callback)
end

--- Post the player's score to the given social leaderboard.
-- Service Operation - POST_SCORE
--
-- @param score The score to post
-- @param jsonData Optional table of data attached to the score
function Leaderboard:postScoreToLeaderboard(leaderboardId, score, jsonData, callback)
	self:_send(OPS.POST_SCORE, { leaderboardId = leaderboardId, score = score, data = jsonData or {} }, callback)
end

--- Removes a player's score from the leaderboard.
-- Service Operation - REMOVE_PLAYER_SCORE
function Leaderboard:removePlayerScore(leaderboardId, versionId, callback)
	self:_send(OPS.REMOVE_PLAYER_SCORE, { leaderboardId = leaderboardId, versionId = versionId }, callback)
end

--- Post the player's score to the given dynamic leaderboard, creating it if it doesn't exist.
-- Service Operation - POST_SCORE_DYNAMIC
--
-- @param leaderboardType Leaderboard.LeaderboardType value
-- @param rotationType Leaderboard.RotationType value
-- @param rotationResetUTC Time of the first reset, in UTC milliseconds
-- @param retainedCount How many rotations to keep
function Leaderboard:postScoreToDynamicLeaderboardUTC(
	leaderboardId,
	score,
	jsonData,
	leaderboardType,
	rotationType,
	rotationResetUTC,
	retainedCount,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		score = score,
		data = jsonData or {},
		leaderboardType = leaderboardType,
		rotationType = rotationType,
		rotationResetTime = rotationResetUTC,
		retainedCount = retainedCount,
	}
	self:_send(OPS.POST_SCORE_DYNAMIC, data, callback)
end

--- Post to a dynamic leaderboard that rotates every numDaysToRotate days.
-- Service Operation - POST_SCORE_DYNAMIC
function Leaderboard:postScoreToDynamicLeaderboardDaysUTC(
	leaderboardId,
	score,
	jsonData,
	leaderboardType,
	rotationResetUTC,
	retainedCount,
	numDaysToRotate,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		score = score,
		data = jsonData or {},
		leaderboardType = leaderboardType,
		rotationType = "DAYS",
		rotationResetTime = rotationResetUTC,
		retainedCount = retainedCount,
		numDaysToRotate = numDaysToRotate,
	}
	self:_send(OPS.POST_SCORE_DYNAMIC, data, callback)
end

--- Post to a dynamic leaderboard, creating it from configJson if it doesn't exist.
-- Service Operation - POST_SCORE_DYNAMIC_USING_CONFIG
--
-- @param scoreData Optional table of data attached to the score
-- @param configJson Must specify leaderboardType, rotationType, resetAt and retainedCount at a minimum
function Leaderboard:postScoreToDynamicLeaderboardUsingConfig(leaderboardId, score, scoreData, configJson, callback)
	local data = {
		leaderboardId = leaderboardId,
		score = score,
		scoreData = scoreData or {},
		configJson = configJson,
	}
	self:_send(OPS.POST_SCORE_DYNAMIC_USING_CONFIG, data, callback)
end

--- GROUP LEADERBOARDS

--- Retrieve the social leaderboard for a group.
-- Service Operation - GET_GROUP_SOCIAL_LEADERBOARD
function Leaderboard:getGroupSocialLeaderboard(leaderboardId, groupId, callback)
	self:_send(OPS.GET_GROUP_SOCIAL_LEADERBOARD, { leaderboardId = leaderboardId, groupId = groupId }, callback)
end

function Leaderboard:getGroupSocialLeaderboardByVersion(leaderboardId, groupId, versionId, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId, versionId = versionId }
	self:_send(OPS.GET_GROUP_SOCIAL_LEADERBOARD_BY_VERSION, data, callback)
end

--- Retrieve a view of the group leaderboard surrounding the current group.
-- Service Operation - GET_GROUP_LEADERBOARD_VIEW
function Leaderboard:getGroupLeaderboardView(leaderboardId, groupId, sort, beforeCount, afterCount, callback)
	local data = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
	}
	self:_send(OPS.GET_GROUP_LEADERBOARD_VIEW, data, callback)
end

function Leaderboard:getGroupLeaderboardViewByVersion(
	leaderboardId,
	groupId,
	versionId,
	sort,
	beforeCount,
	afterCount,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		sort = sort,
		beforeCount = beforeCount,
		afterCount = afterCount,
		versionId = versionId,
	}
	self:_send(OPS.GET_GROUP_LEADERBOARD_VIEW, data, callback)
end

--- Post the group's score to the given social leaderboard.
-- Service Operation - POST_GROUP_SCORE
function Leaderboard:postScoreToGroupLeaderboard(leaderboardId, groupId, score, jsonData, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId, score = score, data = jsonData or {} }
	self:_send(OPS.POST_GROUP_SCORE, data, callback)
end

--- Removes a group's score from the leaderboard.
-- Service Operation - REMOVE_GROUP_SCORE
function Leaderboard:removeGroupScore(leaderboardId, groupId, versionId, callback)
	local data = { leaderboardId = leaderboardId, groupId = groupId, versionId = versionId }
	self:_send(OPS.REMOVE_GROUP_SCORE, data, callback)
end

--- Post the group's score to the given dynamic group leaderboard, creating it if it doesn't exist.
-- Service Operation - POST_GROUP_SCORE_DYNAMIC
function Leaderboard:postScoreToDynamicGroupLeaderboardUTC(
	leaderboardId,
	groupId,
	score,
	jsonData,
	leaderboardType,
	rotationType,
	rotationResetUTC,
	retainedCount,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		score = score,
		data = jsonData or {},
		leaderboardType = leaderboardType,
		rotationType = rotationType,
		rotationResetTime = rotationResetUTC,
		retainedCount = retainedCount,
	}
	self:_send(OPS.POST_GROUP_SCORE_DYNAMIC, data, callback)
end

--- Post to a dynamic group leaderboard that rotates every numDaysToRotate days.
-- Service Operation - POST_GROUP_SCORE_DYNAMIC (C# sends POST_SCORE_DYNAMIC here; JS and the server use the group op)
function Leaderboard:postScoreToDynamicGroupLeaderboardDaysUTC(
	leaderboardId,
	groupId,
	score,
	jsonData,
	leaderboardType,
	rotationResetUTC,
	retainedCount,
	numDaysToRotate,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		score = score,
		data = jsonData or {},
		leaderboardType = leaderboardType,
		rotationType = "DAYS",
		rotationResetTime = rotationResetUTC,
		retainedCount = retainedCount,
		numDaysToRotate = numDaysToRotate,
	}
	self:_send(OPS.POST_GROUP_SCORE_DYNAMIC, data, callback)
end

--- Post to a dynamic group leaderboard, creating it from configJson if it doesn't exist.
-- Service Operation - POST_GROUP_SCORE_DYNAMIC_USING_CONFIG
function Leaderboard:postScoreToDynamicGroupLeaderboardUsingConfig(
	leaderboardId,
	groupId,
	score,
	scoreData,
	configJson,
	callback
)
	local data = {
		leaderboardId = leaderboardId,
		groupId = groupId,
		score = score,
		scoreData = scoreData or {},
		configJson = configJson,
	}
	self:_send(OPS.POST_GROUP_SCORE_DYNAMIC_USING_CONFIG, data, callback)
end

return Leaderboard
