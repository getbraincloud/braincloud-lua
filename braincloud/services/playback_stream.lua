local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local brainCloudPlaybackStream = {}
brainCloudPlaybackStream.__index = brainCloudPlaybackStream

local SERVICE = "playbackStream"
local OPS = {
	START_STREAM = "START_STREAM",
	READ_STREAM = "READ_STREAM",
	END_STREAM = "END_STREAM",
	DELETE_STREAM = "DELETE_STREAM",
	ADD_EVENT = "ADD_EVENT",
	GET_STREAM_SUMMARIES_FOR_INITIATING_PLAYER = "GET_STREAM_SUMMARIES_FOR_INITIATING_PLAYER",
	GET_STREAM_SUMMARIES_FOR_TARGET_PLAYER = "GET_STREAM_SUMMARIES_FOR_TARGET_PLAYER",
	GET_RECENT_STREAMS_FOR_INITIATING_PLAYER = "GET_RECENT_STREAMS_FOR_INITIATING_PLAYER",
	GET_RECENT_STREAMS_FOR_TARGET_PLAYER = "GET_RECENT_STREAMS_FOR_TARGET_PLAYER",
	PROTECT_STREAM_UNTIL = "PROTECT_STREAM_UNTIL",
}

function brainCloudPlaybackStream.new(client)
	local self = setmetatable({}, brainCloudPlaybackStream)
	self.client = client
	return self
end

--- Starts a stream
-- Service Name - playbackStream
-- Service Operation - START_STREAM
-- 
-- @param targetPlayerId The player to start a stream with
-- @param includeSharedData Whether to include shared data in the stream
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:startStream(targetPlayerId, includeSharedData, callback)
	local data = { targetPlayerId = targetPlayerId, includeSharedData = includeSharedData }
	self.client:sendRequest(SERVICE, OPS.START_STREAM, data, callback)
end

--- Reads a stream
-- Service Name - playbackStream
-- Service Operation - READ_STREAM
-- 
-- @param playbackStreamId Identifies the stream to read
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:readStream(playbackStreamId, callback)
	local data = { playbackStreamId = playbackStreamId }
	self.client:sendRequest(SERVICE, OPS.READ_STREAM, data, callback)
end

--- Ends a stream
-- Service Name - playbackStream
-- Service Operation - END_STREAM
-- 
-- @param playbackStreamId Identifies the stream to read
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:endStream(playbackStreamId, callback)
	local data = { playbackStreamId = playbackStreamId }
	self.client:sendRequest(SERVICE, OPS.END_STREAM, data, callback)
end

--- Deletes a stream
-- Service Name - playbackStream
-- Service Operation - DELETE_STREAM
-- 
-- @param playbackStreamId Identifies the stream to read
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:deleteStream(playbackStreamId, callback)
	local data = { playbackStreamId = playbackStreamId }
	self.client:sendRequest(SERVICE, OPS.DELETE_STREAM, data, callback)
end

--- Adds a stream event
-- Service Name - playbackStream
-- Service Operation - ADD_EVENT
-- 
-- @param playbackStreamId Identifies the stream to read
-- @param jsonEventData Describes the event
-- @param jsonSummary Current summary data as of this event
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:addEvent(playbackStreamId, eventData, summary, callback)
	local data = { playbackStreamId = playbackStreamId, eventData = eventData, summary = summary }
	self.client:sendRequest(SERVICE, OPS.ADD_EVENT, data, callback)
end

--- Gets recent stream summaries for initiating player
-- Service Name - playbackStream
-- Service Operation - GET_RECENT_STREAMS_FOR_INITIATING_PLAYER
-- 
-- @param targetPlayerId The player that started the stream
-- @param maxNumStreams The max number of streams to query
-- @param callback The callback.
-- 
function brainCloudPlaybackStream:getRecentStreamsForInitiatingPlayer(initiatingPlayerId, maxNumStreams, callback)
	local data = { initiatingPlayerId = initiatingPlayerId, maxNumStreams = maxNumStreams }
	self.client:sendRequest(SERVICE, OPS.GET_RECENT_STREAMS_FOR_INITIATING_PLAYER, data, callback)
end

--- Gets recent stream summaries for target player
-- Service Name - playbackStream
-- Service Operation - GET_RECENT_STREAMS_FOR_TARGET_PLAYER
-- 
-- @param targetPlayerId The player that was target of the stream
-- @param maxNumStreams The max number of streams to query
-- @param callback The callback.
-- 
function brainCloudPlaybackStream:getRecentStreamsForTargetPlayer(targetPlayerId, maxNumStreams, callback)
	local data = { targetPlayerId = targetPlayerId, maxNumStreams = maxNumStreams }
	self.client:sendRequest(SERVICE, OPS.GET_RECENT_STREAMS_FOR_TARGET_PLAYER, data, callback)
end

--- Get stream summaries for initiating player.
--- @param initiatingPlayerId string
--- @param maxNumStreams number
--- @param callback function
function brainCloudPlaybackStream:getStreamSummariesForInitiatingPlayer(initiatingPlayerId, maxNumStreams, callback)
	local data = { initiatingPlayerId = initiatingPlayerId, maxNumStreams = maxNumStreams }
	self.client:sendRequest(SERVICE, OPS.GET_STREAM_SUMMARIES_FOR_INITIATING_PLAYER, data, callback)
end

--- Get stream summaries for target player.
--- @param targetPlayerId string
--- @param maxNumStreams number
--- @param callback function
function brainCloudPlaybackStream:getStreamSummariesForTargetPlayer(targetPlayerId, maxNumStreams, callback)
	local data = { targetPlayerId = targetPlayerId, maxNumStreams = maxNumStreams }
	self.client:sendRequest(SERVICE, OPS.GET_STREAM_SUMMARIES_FOR_TARGET_PLAYER, data, callback)
end

--- Protects a playback stream from being purged (but not deleted) for the given number of days (from now).
-- If the number of days given is less than the normal purge interval days (from createdAt), the longer protection date is applied.
-- Can only be called by users involved in the playback stream.
-- Service Name - playbackStream
-- Service Operation - PROTECT_STREAM_UNTIL
-- 
-- @param playbackStreamId Identifies the stream to protect
-- @param numDays The number of days the stream is to be protected (from now)
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudPlaybackStream:protectStreamUntil(playbackStreamId, numDays, callback)
	local data = { playbackStreamId = playbackStreamId, numDays = numDays }
	self.client:sendRequest(SERVICE, OPS.PROTECT_STREAM_UNTIL, data, callback)
end

return brainCloudPlaybackStream
