local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local brainCloudOneWayMatch = {}
brainCloudOneWayMatch.__index = brainCloudOneWayMatch

local SERVICE = "onewayMatch"
local OPS = {
	START_MATCH = "START_MATCH",
	CANCEL_MATCH = "CANCEL_MATCH",
	COMPLETE_MATCH = "COMPLETE_MATCH",
}

function brainCloudOneWayMatch.new(client)
	local self = setmetatable({}, brainCloudOneWayMatch)
	self.client = client
	return self
end

--- Starts a match
-- Service Name - onewayMatch
-- Service Operation - START_MATCH
-- 
-- @param otherPlayerId The player to start a match with
-- @param rangeDelta The range delta used for the initial match search
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudOneWayMatch:startMatch(otherPlayerId, rangeDelta, callback)
	local data = {
		playerId = otherPlayerId,
		rangeDelta = rangeDelta,
	}
	self.client:sendRequest(SERVICE, OPS.START_MATCH, data, callback)
end

--- Cancels a match
-- Service Name - onewayMatch
-- Service Operation - CANCEL_MATCH
-- 
-- @param playbackStreamId The playback stream id returned in the start match
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudOneWayMatch:cancelMatch(playbackStreamId, callback)
	local data = { playbackStreamId = playbackStreamId }
	self.client:sendRequest(SERVICE, OPS.CANCEL_MATCH, data, callback)
end

--- Completes a match
-- Service Name - onewayMatch
-- Service Operation - COMPLETE_MATCH
-- 
-- @param playbackStreamId The playback stream id returned in the initial start match
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudOneWayMatch:completeMatch(playbackStreamId, callback)
	local data = { playbackStreamId = playbackStreamId }
	self.client:sendRequest(SERVICE, OPS.COMPLETE_MATCH, data, callback)
end

return brainCloudOneWayMatch
