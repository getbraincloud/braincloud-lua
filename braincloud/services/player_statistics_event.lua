local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local PlayerStatisticsEvent = {}
PlayerStatisticsEvent.__index = PlayerStatisticsEvent

local SERVICE = "playerStatisticsEvent"
local OPS = {
	TRIGGER = "TRIGGER",
	TRIGGER_MULTIPLE = "TRIGGER_MULTIPLE",
}

function PlayerStatisticsEvent.new(client)
	local self = setmetatable({}, PlayerStatisticsEvent)
	self.client = client
	return self
end

--- Trigger an event server side that will increase the user's statistics.
-- This may cause one or more awards to be sent back to the user -
-- could be achievements, experience, etc. Achievements will be sent by this
-- client library to the appropriate awards service (Apple Game Center, etc).
-- This mechanism supercedes the PlayerStatisticsService API methods, since
-- PlayerStatisticsService API method only update the raw statistics without
-- triggering the rewards.
-- @see BrainCloudPlayerStatistics
-- Service Name - playerStatisticsEvent
-- Service Operation - TRIGGER
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function PlayerStatisticsEvent:triggerStatsEvent(eventName, eventMultiplier, callback)
	local data = { eventName = eventName, eventMultiplier = eventMultiplier }
	self.client:sendRequest(SERVICE, OPS.TRIGGER, data, callback)
end

--- See documentation for TriggerStatisticsEvent for more
-- documentation.
-- @param jsonData
-- [
-- {
-- "eventName": "event1",
-- "eventMultiplier": 1
-- },
-- {
-- "eventName": "event2",
-- "eventMultiplier": 1
-- }
-- ]
-- Service Name - playerStatisticsEvent
-- Service Operation - TRIGGER_MULTIPLE
-- 
-- 
function PlayerStatisticsEvent:triggerStatsEvents(events, callback)
	local data = { events = Utils.array(events) }
	self.client:sendRequest(SERVICE, OPS.TRIGGER_MULTIPLE, data, callback)
end

return PlayerStatisticsEvent
