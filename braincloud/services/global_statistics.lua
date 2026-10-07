local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local GlobalStatistics = {}
GlobalStatistics.__index = GlobalStatistics

local SERVICE = "globalGameStatistics"

local OPS = {
	READ = "READ",
	READ_SUBSET = "READ_SUBSET",
	READ_FOR_CATEGORY = "READ_FOR_CATEGORY",
	UPDATE_INCREMENT = "UPDATE_INCREMENT",
	PROCESS_STATISTICS = "PROCESS_STATISTICS",
}


--- Constructor

--- Creates a new GlobalStatistics instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return GlobalStatistics
function GlobalStatistics.new(brainCloudClient)
	local self = setmetatable({}, GlobalStatistics)
	self.client = brainCloudClient
	return self
end


--- SERVICE METHODS

--- Increment (or decrement) global statistics atomically.
--- @param stats table Table of statistics to increment/decrement.
--- @param callback fun(response: table) Callback to handle server response.
function GlobalStatistics:incrementGlobalStats(stats, callback)
	local data = { statistics = stats }
	self.client:sendRequest(SERVICE, OPS.UPDATE_INCREMENT, data, callback)
end

--- Atomically increment (or decrement) global statistics.
-- Global statistics are defined through the brainCloud portal.
-- Service Name - globalGameStatistics
-- Service Operation - UPDATE_INCREMENT
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
-- @param callback Method to be invoked when the server response is received.
-- 
function GlobalStatistics:incrementGlobalGameStat(jsonData, callback)
	self:incrementGlobalStats(jsonData, callback)
end

function GlobalStatistics:readAllGlobalStats(callback)
	self.client:sendRequest(SERVICE, OPS.READ, nil, callback)
end

--- Reads a subset of global statistics as defined by the input collection.
-- Service Name - globalGameStatistics
-- Service Operation - READ_SUBSET
-- 
-- @param statistics A collection containing the statistics to read:
--        [
--        "Level01_TimesBeaten",
--        "Level02_TimesBeaten"
--        ]
-- @param callback Method to be invoked when the server response is received.
-- 
function GlobalStatistics:readGlobalStatsSubset(stats, callback)
	local data = { statistics = stats }
	self.client:sendRequest(SERVICE, OPS.READ_SUBSET, data, callback)
end

--- Method retrieves the global statistics for the given category.
-- Service Name - globalGameStatistics
-- Service Operation - READ_FOR_CATEGORY
-- 
-- @param category The global statistics category
-- @param callback Method to be invoked when the server response is received.
-- 
function GlobalStatistics:readGlobalStatsForCategory(category, callback)
	local data = { category = category }
	self.client:sendRequest(SERVICE, OPS.READ_FOR_CATEGORY, data, callback)
end

--- Apply statistics grammar to a partial set of statistics.
-- Service Name - globalGameStatistics
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
function GlobalStatistics:processStatistics(stats, callback)
	local data = { statistics = stats }
	self.client:sendRequest(SERVICE, OPS.PROCESS_STATISTICS, data, callback)
end

return GlobalStatistics
