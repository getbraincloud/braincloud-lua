local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local DataStream = {}
DataStream.__index = DataStream

local SERVICE = "dataStream"

local OPS = {
	CUSTOM_PAGE_EVENT = "CUSTOM_PAGE_EVENT",
	CUSTOM_SCREEN_EVENT = "CUSTOM_SCREEN_EVENT",
	CUSTOM_TRACK_EVENT = "CUSTOM_TRACK_EVENT",
	SUBMIT_CRASH_REPORT = "SEND_CRASH_REPORT",
}

--- Constructor

function DataStream.new(baseClient)
	local self = setmetatable({}, DataStream)
	self.client = baseClient
	return self
end

--- Page Event

--- Creates custom data stream page event
-- Service Name - dataStream
-- Service Operation - CUSTOM_PAGE_EVENT
-- 
-- @param eventName Name of event
-- @param eventProperties Properties of event
-- 
function DataStream:customPageEvent(eventName, eventProperties, callback)
	local data = {
		eventName = eventName,
		eventProperties = eventProperties,
	}

	self.client:sendRequest(SERVICE, OPS.CUSTOM_PAGE_EVENT, data, callback)
end

--- Screen Event

--- Creates custom data stream screen event
-- 
-- @param eventName Name of event
-- @param eventProperties Properties of event
-- 
function DataStream:customScreenEvent(eventName, eventProperties, callback)
	local data = {
		eventName = eventName,
		eventProperties = eventProperties,
	}

	self.client:sendRequest(SERVICE, OPS.CUSTOM_SCREEN_EVENT, data, callback)
end

--- Track Event

--- Creates custom data stream track event
-- 
-- @param eventName Name of event
-- @param eventProperties Properties of event
-- 
function DataStream:customTrackEvent(eventName, eventProperties, callback)
	local data = {
		eventName = eventName,
		eventProperties = eventProperties,
	}

	self.client:sendRequest(SERVICE, OPS.CUSTOM_TRACK_EVENT, data, callback)
end

--- Crash Report

--- Send crash report
-- @param crashType
-- @param errorMsg
-- @param crashJson
-- @param crashLog
-- @param userName
-- @param userEmail
-- @param userNotes
-- @param userSubmitted
-- 
-- 
function DataStream:submitCrashReport(
	crashType,
	errorMsg,
	crashJson,
	crashLog,
	userName,
	userEmail,
	userNotes,
	userSubmitted,
	callback
)
	local data = {
		crashType = crashType,
		errorMsg = errorMsg,
		crashJson = crashJson,
		crashLog = crashLog,
		userName = userName,
		userEmail = userEmail,
		userNotes = userNotes,
		userSubmitted = userSubmitted,
	}

	self.client:sendRequest(SERVICE, OPS.SUBMIT_CRASH_REPORT, data, callback)
end

return DataStream
