local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local PlayerStatistics = {}
PlayerStatistics.__index = PlayerStatistics

local SERVICE = "playerStatistics"

local OPS = {
	READ = "READ",
	READ_SUBSET = "READ_SUBSET",
	READ_SHARED = "READ_SHARED",
	READ_FOR_CATEGORY = "READ_FOR_CATEGORY",
	RESET = "RESET",
	UPDATE = "UPDATE",
	UPDATE_INCREMENT = "UPDATE_INCREMENT",
	UPDATE_SET_MINIMUM = "UPDATE_SET_MINIMUM",
	UPDATE_INCREMENT_TO_MAXIMUM = "UPDATE_INCREMENT_TO_MAXIMUM",
	PROCESS = "PROCESS_STATISTICS",
	READ_NEXT_XPLEVEL = "READ_NEXT_XPLEVEL",
	SET_XPPOINTS = "SET_XPPOINTS",
}


--- Constructor

--- Creates a new PlayerStatistics service instance.
--- @param baseClient table The brainCloud client instance.
--- @return PlayerStatistics
function PlayerStatistics.new(baseClient)
	local self = setmetatable({}, PlayerStatistics)
	self.client = baseClient
	return self
end


--- SERVICE METHODS (1:1 with JS version)

--- Returns JSON representing the next experience level for the user.
-- Service Name - playerStatistics
-- Service Operation - READ_NEXT_XPLEVEL
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:getNextExperienceLevel(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.READ_NEXT_XPLEVEL, data, callback)
end

--- Increments the user's experience. If the user goes up a level,
-- the new level details will be returned along with a list of rewards.
-- Service Name - playerStatistics
-- Service Operation - UPDATE_INCREMENT
-- 
-- @param xpValue The amount to increase the user's experience by
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:incrementExperiencePoints(xp, callback)
	local data = { xp_points = xp }
	self.client:sendRequest(SERVICE, OPS.UPDATE, data, callback)
end

--- Atomically increment (or decrement) user statistics.
-- Any rewards that are triggered from user statistic increments
-- will be considered. User statistics are defined through the brainCloud portal.
-- Note also that the "xpCapped" property is returned (true/false depending on whether
-- the xp cap is turned on and whether the user has hit it).
-- Service Name - playerStatistics
-- Service Operation - UPDATE
-- 
-- @param jsonData The JSON encoded data to be sent to the server as follows:
--        {
--        stat1: 10,
--        stat2: -5.5,
--        }
--        would increment stat1 by 10 and decrement stat2 by 5.5.
--        For the full statistics grammer see the api.braincloudservers.com site.
--        There are many more complex operations supported such as:
--        {
--        stat1:INC_TO_LIMIT#9#30
--        }
--        which increments stat1 by 9 up to a limit of 30.
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:incrementUserStats(stats, xp, callback)
	local data = {
		statistics = Utils.emptyFix(stats),
		xp_points = xp,
	}
	self.client:sendRequest(SERVICE, OPS.UPDATE, data, callback)
end

--- Read all available user statistics.
-- Service Name - playerStatistics
-- Service Operation - READ
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:readAllUserStats(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.READ, data, callback)
end

--- Reads a subset of user statistics as defined by the input collection.
-- Service Name - playerStatistics
-- Service Operation - READ_SUBSET
-- 
-- @param statistics A collection containing the subset of statistics to read:
--        ex. [ "pantaloons", "minions" ]
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:readUserStatsSubset(subset, callback)
	local data = { statistics = Utils.emptyFix(subset) }
	self.client:sendRequest(SERVICE, OPS.READ_SUBSET, data, callback)
end

--- Method retrieves the user statistics for the given category.
-- Service Name - playerStatistics
-- Service Operation - READ_FOR_CATEGORY
-- 
-- @param category The user statistics category
-- @param callback Method to be invoked when the server response is received.
-- 
function PlayerStatistics:readUserStatsForCategory(category, callback)
	local data = { category = category }
	self.client:sendRequest(SERVICE, OPS.READ_FOR_CATEGORY, data, callback)
end

--- Reset all of the statistics for this user back to their initial value.
-- Service Name - playerStatistics
-- Service Operation - RESET
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:resetAllUserStats(callback)
	local data = {}
	self.client:sendRequest(SERVICE, OPS.RESET, data, callback)
end

--- Sets the user's experience to an absolute value. Note that this
-- is simply a set and will not reward the user if their level changes
-- as a result.
-- Service Name - playerStatistics
-- Service Operation - SET_XPPOINTS
-- 
-- @param xpValue The amount to set the the user's experience to
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatistics:setExperiencePoints(xp, callback)
	local data = { xp_points = xp }
	self.client:sendRequest(SERVICE, OPS.SET_XPPOINTS, data, callback)
end

--- Apply statistics grammar to a partial set of statistics.
-- Service Name - playerStatistics
-- Service Operation - PROCESS_STATISTICS
-- 
-- @param jsonData The JSON format is as follows:
--        {
--        "DEAD_CATS": "RESET",
--        "LIVES_LEFT": "SET#9",
--        "MICE_KILLED": "INC#2",
--        "DOG_SCARE_BONUS_POINTS": "INC#10",
--        "TREES_CLIMBED": 1
--        }
-- @param callback Method to be invoked when the server response is received.
-- 
function PlayerStatistics:processStatistics(stats, callback)
	local data = { statistics = Utils.emptyFix(stats) }
	self.client:sendRequest(SERVICE, OPS.PROCESS, data, callback)
end

return PlayerStatistics
