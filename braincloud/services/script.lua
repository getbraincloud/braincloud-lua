local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")

local ScriptService = {}
ScriptService.__index = ScriptService

local SERVICE = "script"

local OPS = {
	RUN = "RUN",
	SCHEDULE_CLOUD_SCRIPT = "SCHEDULE_CLOUD_SCRIPT",
	RUN_PARENT_SCRIPT = "RUN_PARENT_SCRIPT",
	CANCEL_SCHEDULED_SCRIPT = "CANCEL_SCHEDULED_SCRIPT",
	GET_SCHEDULED_CLOUD_SCRIPTS = "GET_SCHEDULED_CLOUD_SCRIPTS",
	GET_RUNNING_OR_QUEUED_CLOUD_SCRIPTS = "GET_RUNNING_OR_QUEUED_CLOUD_SCRIPTS",
	RUN_PEER_SCRIPT = "RUN_PEER_SCRIPT",
	RUN_PEER_SCRIPT_ASYNC = "RUN_PEER_SCRIPT_ASYNC",
}


--- Constructor

--- Creates a new ScriptService instance.
--- @param baseClient table The brainCloud client instance.
--- @return ScriptService
function ScriptService.new(baseClient)
	local self = setmetatable({}, ScriptService)
	self.client = baseClient
	return self
end


--- SERVICE METHODS

--- Executes a script on the server.
-- Service Name - script
-- Service Operation - RUN
-- 
-- @param scriptName The name of the script to be run
-- @param jsonScriptData Data to be sent to the script in json format
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:runScript(scriptName, scriptData, callback)
	local data = {
		scriptName = scriptName,
		scriptData = Utils.emptyFix(scriptData),
	}
	self.client:sendRequest(SERVICE, OPS.RUN, data, callback)
end

--- Allows cloud script executions to be scheduled - UTC time
-- Service Name - script
-- Service Operation - SCHEDULE_CLOUD_SCRIPT
-- 
-- @param scriptName The name of the script to be run
-- @param jsonScriptData Data to be sent to the script in json format
-- @param startDateInUTC The start date in UTC
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:scheduleRunScriptMillisUTC(scriptName, scriptData, startDateInUTC, callback)
	local data = {
		scriptName = scriptName,
		scriptData = Utils.emptyFix(scriptData),
		startDateUTC = startDateInUTC,
	}
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_CLOUD_SCRIPT, data, callback)
end

--- Allows cloud script executions to be scheduled
-- Service Name - script
-- Service Operation - SCHEDULE_CLOUD_SCRIPT
-- 
-- @param scriptName The name of the script to be run
-- @param jsonScriptData Data to be sent to the script in json format
-- @param minutesFromNow Number of minutes from now to run script
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:scheduleRunScriptMinutes(scriptName, scriptData, minutesFromNow, callback)
	local data = {
		scriptName = scriptName,
		scriptData = Utils.emptyFix(scriptData),
		minutesFromNow = minutesFromNow,
	}
	self.client:sendRequest(SERVICE, OPS.SCHEDULE_CLOUD_SCRIPT, data, callback)
end

--- Run a cloud script in a parent app
-- Service Name - script
-- Service Operation - RUN_PARENT_SCRIPT
-- 
-- @param scriptName The name of the script to be run
-- @param scriptData Data to be sent to the script in json format
-- @param parentLevel The level name of the parent to run the script from
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:runParentScript(scriptName, scriptData, parentLevel, callback)
	local data = {
		scriptName = scriptName,
		scriptData = Utils.emptyFix(scriptData),
		parentLevel = parentLevel,
	}
	self.client:sendRequest(SERVICE, OPS.RUN_PARENT_SCRIPT, data, callback)
end

--- Cancels a scheduled cloud code script
-- Service Name - script
-- Service Operation - CANCEL_SCHEDULED_SCRIPT
-- 
-- @param jobId ID of script job to cancel
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:cancelScheduledScript(jobId, callback)
	local data = { jobId = jobId }
	self.client:sendRequest(SERVICE, OPS.CANCEL_SCHEDULED_SCRIPT, data, callback)
end

--- Cancels a scheduled cloud code script
-- Service Name - script
-- Service Operation - CANCEL_SCHEDULED_SCRIPT
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:getRunningOrQueuedCloudScripts(callback)
	self.client:sendRequest(SERVICE, OPS.GET_RUNNING_OR_QUEUED_CLOUD_SCRIPTS, nil, callback)
end

--- Cancels a scheduled cloud code script
-- Service Name - script
-- Service Operation - CANCEL_SCHEDULED_SCRIPT
-- 
-- @param jobId ID of script job to cancel
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:getScheduledCloudScripts(startDateUTC, callback)
	local data = { startDateUTC = startDateUTC }
	self.client:sendRequest(SERVICE, OPS.GET_SCHEDULED_CLOUD_SCRIPTS, data, callback)
end

--- Runs a script from the context of a peer
-- Service Name - script
-- Service Operation - RUN_PEER_SCRIPT
-- 
-- @param scriptName The name of the script to be run
-- @param jsonScriptData Data to be sent to the script in json format
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:runPeerScript(scriptName, scriptData, peer, callback)
	local data = {
		scriptName = scriptName,
		peer = peer,
		scriptData = Utils.emptyFix(scriptData),
	}
	self.client:sendRequest(SERVICE, OPS.RUN_PEER_SCRIPT, data, callback)
end

--- Runs a script asynchronously from the context of a peer
-- This method does not wait for the script to complete before returning
-- Service Name - script
-- Service Operation - RUN_PEER_SCRIPT_ASYNC
-- 
-- @param scriptName The name of the script to be run
-- @param jsonScriptData Data to be sent to the script in json format
-- @param callback The method to be invoked when the server response is received
-- 
function ScriptService:runPeerScriptAsync(scriptName, scriptData, peer, callback)
	local data = {
		scriptName = scriptName,
		peer = peer,
		scriptData = Utils.emptyFix(scriptData),
	}
	self.client:sendRequest(SERVICE, OPS.RUN_PEER_SCRIPT_ASYNC, data, callback)
end

return ScriptService
