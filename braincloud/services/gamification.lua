local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local Gamification = {}
Gamification.__index = Gamification

local SERVICE = "gamification"

local OPS = {
	READ = "READ",
	READ_XP_LEVELS = "READ_XP_LEVELS",
	READ_ACHIEVEMENTS = "READ_ACHIEVEMENTS",
	READ_ACHIEVED_ACHIEVEMENTS = "READ_ACHIEVED_ACHIEVEMENTS",
	AWARD_ACHIEVEMENTS = "AWARD_ACHIEVEMENTS",
	READ_MILESTONES = "READ_MILESTONES",
	READ_MILESTONES_BY_CATEGORY = "READ_MILESTONES_BY_CATEGORY",
	READ_COMPLETED_MILESTONES = "READ_COMPLETED_MILESTONES",
	READ_IN_PROGRESS_MILESTONES = "READ_IN_PROGRESS_MILESTONES",
	RESET_MILESTONES = "RESET_MILESTONES",
	READ_QUESTS = "READ_QUESTS",
	READ_QUESTS_BY_CATEGORY = "READ_QUESTS_BY_CATEGORY",
	READ_COMPLETED_QUESTS = "READ_COMPLETED_QUESTS",
	READ_IN_PROGRESS_QUESTS = "READ_IN_PROGRESS_QUESTS",
	READ_NOT_STARTED_QUESTS = "READ_NOT_STARTED_QUESTS",
	READ_QUESTS_WITH_STATUS = "READ_QUESTS_WITH_STATUS",
	READ_QUESTS_WITH_BASIC_PERCENTAGE = "READ_QUESTS_WITH_BASIC_PERCENTAGE",
	READ_QUESTS_WITH_COMPLEX_PERCENTAGE = "READ_QUESTS_WITH_COMPLEX_PERCENTAGE",
}


--- Constructor

--- Creates a new Gamification service instance.
--- @param baseClient The brainCloud client instance.
--- @return Gamification A new Gamification service object.
function Gamification.new(baseClient)
	local self = setmetatable({}, Gamification)
	self.client = baseClient
	return self
end


--- Gamification Methods

--- Method retrieves all gamification data for the player.
-- Service Name - gamification
-- Service Operation - READ
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readAllGamification(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ, data, callback)
end

--- Method will award the achievements specified.
-- Service Name - gamification
-- Service Operation - AWARD_ACHIEVEMENTS
-- 
-- @param achievementIds Collection of achievement ids to award
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:awardAchievements(achievements, callback, includeMetaData)
	local data = { achievements = Utils.array(achievements) }
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.AWARD_ACHIEVEMENTS, data, callback)
end

--- Method retrives the list of achieved achievements.
-- Service Name - gamification
-- Service Operation - READ_ACHIEVED_ACHIEVEMENTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readAchievedAchievements(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_ACHIEVED_ACHIEVEMENTS, data, callback)
end

--- Method returns all defined xp levels and any rewards associated
-- with those xp levels.
-- Service Name - gamification
-- Service Operation - READ_XP_LEVELS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readXPLevelsMetaData(callback)
	self.client:sendRequest(SERVICE, OPS.READ_XP_LEVELS, {}, callback)
end

--- Read all of the achievements defined for the game.
-- Service Name - gamification
-- Service Operation - READ_ACHIEVEMENTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readAchievements(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_ACHIEVEMENTS, data, callback)
end

--- Method retrieves all milestones defined for the game.
-- Service Name - gamification
-- Service Operation - READ_MILESTONES
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readMilestones(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_MILESTONES, data, callback)
end

--- Method retrieves milestones of the given category.
-- Service Name - gamification
-- Service Operation - READ_MILESTONES_BY_CATEGORY
-- 
-- @param category The milestone category
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readMilestonesByCategory(category, callback, includeMetaData)
	local data = { category = category }
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_MILESTONES_BY_CATEGORY, data, callback)
end

--- Method retrieves the list of completed milestones.
-- Service Name - gamification
-- Service Operation - READ_COMPLETED_MILESTONES
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readCompletedMilestones(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_COMPLETED_MILESTONES, data, callback)
end

--- Method retrieves the list of in progress milestones
-- Service Name - gamification
-- Service Operation - READ_IN_PROGRESS_MILESTONES
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readInProgressMilestones(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_IN_PROGRESS_MILESTONES, data, callback)
end

--- Method retrieves all of the quests defined for the game.
-- Service Name - gamification
-- Service Operation - READ_QUESTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readQuests(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_QUESTS, data, callback)
end

--- Method returns quests for the given category.
-- Service Name - gamification
-- Service Operation - READ_QUESTS_BY_CATEGORY
-- 
-- @param category The quest category
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readQuestsByCategory(category, callback, includeMetaData)
	local data = { category = category }
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_QUESTS_BY_CATEGORY, data, callback)
end

--- Method returns all completed quests.
-- Service Name - gamification
-- Service Operation - READ_COMPLETED_QUESTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readCompletedQuests(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_COMPLETED_QUESTS, data, callback)
end

--- Method returns quests that are in progress.
-- Service Name - gamification
-- Service Operation - READ_IN_PROGRESS_QUESTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readInProgressQuests(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_IN_PROGRESS_QUESTS, data, callback)
end

--- Method returns quests that have not been started.
-- Service Name - gamification
-- Service Operation - READ_NOT_STARTED_QUESTS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readNotStartedQuests(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_NOT_STARTED_QUESTS, data, callback)
end

--- Method returns quests with a status.
-- Service Name - gamification
-- Service Operation - READ_QUESTS_WITH_STATUS
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readQuestsWithStatus(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_QUESTS_WITH_STATUS, data, callback)
end

--- Method returns quests with a basic percentage.
-- Service Name - gamification
-- Service Operation - READ_QUESTS_WITH_BASIC_PERCENTAGE
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readQuestsWithBasicPercentage(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_QUESTS_WITH_BASIC_PERCENTAGE, data, callback)
end

--- Method returns quests with a complex percentage.
-- Service Name - gamification
-- Service Operation - READ_QUESTS_WITH_COMPLEX_PERCENTAGE
-- 
-- @param callback Method to be invoked when the server response is received.
-- 
function Gamification:readQuestsWithComplexPercentage(callback, includeMetaData)
	local data = {}
	if includeMetaData then
		data.includeMetaData = includeMetaData
	end
	self.client:sendRequest(SERVICE, OPS.READ_QUESTS_WITH_COMPLEX_PERCENTAGE, data, callback)
end

return Gamification
