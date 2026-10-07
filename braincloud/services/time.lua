local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Time = {}
Time.__index = Time

local SERVICE = "time"

local OPS = {
	READ = "READ",
}

--- Creates a new Time service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return Time
function Time.new(brainCloudClient)
	local self = setmetatable({}, Time)
	self.client = brainCloudClient
	return self
end

--- Method returns the server time in UTC. This is in UNIX millis time format.
-- For instance 1396378241893 represents 2014-04-01 2:50:41.893 in GMT-4.
-- Server API reference: ServiceName.Time, ServiceOperation.Read
-- Service Name - time
-- Service Operation - READ
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function Time:readServerTime(callback)
	self.client:sendRequest(SERVICE, OPS.READ, {}, callback)
end

return Time
