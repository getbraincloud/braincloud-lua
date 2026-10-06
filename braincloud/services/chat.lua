local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

--- @class Chat
--- Chat service wrapper for brainCloud.
local Chat = {}
Chat.__index = Chat

local SERVICE = "chat"

--- Operation Map

--- @enum ChatOps
local OPS = {
	CHANNEL_CONNECT = "CHANNEL_CONNECT",
	CHANNEL_DISCONNECT = "CHANNEL_DISCONNECT",
	DELETE_CHAT_MESSAGE = "DELETE_CHAT_MESSAGE",
	GET_CHANNEL_ID = "GET_CHANNEL_ID",
	GET_CHANNEL_INFO = "GET_CHANNEL_INFO",
	GET_CHAT_MESSAGE = "GET_CHAT_MESSAGE",
	GET_RECENT_CHAT_MESSAGES = "GET_RECENT_CHAT_MESSAGES",
	GET_SUBSCRIBED_CHANNELS = "GET_SUBSCRIBED_CHANNELS",
	POST_CHAT_MESSAGE = "POST_CHAT_MESSAGE",
	UPDATE_CHAT_MESSAGE = "UPDATE_CHAT_MESSAGE",
}

--- Constructor

--- Creates a new Chat service bound to a brainCloud client.
--- @param client any BrainCloud client instance
--- @return Chat
function Chat.new(baseClient)
	return setmetatable({
		client = baseClient,
	}, Chat)
end

--- Channel Connect / Disconnect

--- Registers a listener for incoming events from <channelId>.
-- Also returns a list of <maxReturn> recent messages from history.
-- Service Name - chat
-- Service Operation - CHANNEL_CONNECT
-- 
-- @param channelId The id of the chat channel to return history from.
-- @param maxReturn Maximum number of messages to return.
-- @param callback The method to be invoked when the server response is received
-- 
function Chat:channelConnect(channelId, maxReturn, callback)
	self.client:sendRequest(SERVICE, OPS.CHANNEL_CONNECT, {
		channelId = channelId,
		maxReturn = maxReturn,
	}, callback)
end

--- Unregisters a listener for incoming events from <channelId>.
-- Service Name - chat
-- Service Operation - CHANNEL_DISCONNECT
-- 
-- @param channelId The id of the chat channel to unsubscribed from.
-- @param callback The method to be invoked when the server response is received
-- 
function Chat:channelDisconnect(channelId, callback)
	self.client:sendRequest(SERVICE, OPS.CHANNEL_DISCONNECT, {
		channelId = channelId,
	}, callback)
end

--- Chat Message APIs

--- Send a potentially rich chat message.
-- <content> must contain at least a "text" field for text messaging.
-- Service Name - chat
-- Service Operation - POST_CHAT_MESSAGE
-- 
-- @param channelId Channel id to post message to.
-- @param content Object containing "text" for the text message. Can also has rich content for custom data.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:postChatMessage(channelId, content, recordInHistory, callback)
	self.client:sendRequest(SERVICE, OPS.POST_CHAT_MESSAGE, {
		channelId = channelId,
		content = content,
		recordInHistory = recordInHistory,
	}, callback)
end

--- Send a chat message with text only
-- Service Name - chat
-- Service Operation - POST_CHAT_MESSAGE
-- 
-- @param channelId Channel id to post message to.
-- @param text The text message.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:postChatMessageSimple(channelId, text, recordInHistory, callback)
	self.client:sendRequest(SERVICE, OPS.POST_CHAT_MESSAGE, {
		channelId = channelId,
		content = { text = text },
		recordInHistory = recordInHistory,
	}, callback)
end

--- Channel Information APIs

--- Gets the channelId for the given <channelType> and <channelSubId>. Channel type must be one of "gl" or "gr".
-- Service Name - chat
-- Service Operation - GET_CHANNEL_ID
-- 
-- @param channelType Channel type must be one of "gl" or "gr". For (global) or (group) respectively.
-- @param channelSubId The sub id of the channel.
-- @param callback The method to be invoked when the server response is received
-- 
function Chat:getChannelId(channelType, channelSubId, callback)
	self.client:sendRequest(SERVICE, OPS.GET_CHANNEL_ID, {
		channelType = channelType,
		channelSubId = channelSubId,
	}, callback)
end

--- Gets description info and activity stats for channel <channelId>.
-- Note that numMsgs and listeners only returned for non-global groups.
-- Only callable for channels the user is a member of.
-- Service Name - chat
-- Service Operation - GET_CHANNEL_INFO
-- 
-- @param channelId Id of the channel to receive the info from.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:getChannelInfo(channelId, callback)
	self.client:sendRequest(SERVICE, OPS.GET_CHANNEL_INFO, {
		channelId = channelId,
	}, callback)
end

--- Get a list of <maxReturn> messages from history of channel <channelId>.
-- Service Name - chat
-- Service Operation - GET_RECENT_CHAT_MESSAGES
-- 
-- @param channelId Id of the channel to receive the info from.
-- @param maxReturn Maximum message count to return.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:getRecentChatMessages(channelId, maxReturn, callback)
	self.client:sendRequest(SERVICE, OPS.GET_RECENT_CHAT_MESSAGES, {
		channelId = channelId,
		maxReturn = maxReturn,
	}, callback)
end

--- Gets a populated chat object (normally for editing).
-- Service Name - chat
-- Service Operation - GET_CHAT_MESSAGE
-- 
-- @param channelId Id of the channel to receive the message from.
-- @param msgId Id of the message to read.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:getChatMessage(channelId, msgId, callback)
	self.client:sendRequest(SERVICE, OPS.GET_CHAT_MESSAGE, {
		channelId = channelId,
		msgId = msgId,
	}, callback)
end

--- Gets a list of the channels of type <channelType> that the user has access to.
-- Channel type must be one of "gl", "gr" or "all".
-- Service Name - chat
-- Service Operation - GET_SUBSCRIBED_CHANNELS
-- 
-- @param channelType Type of channels to get back. "gl" for global, "gr" for group or "all" for both.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:getSubscribedChannels(channelType, callback)
	self.client:sendRequest(SERVICE, OPS.GET_SUBSCRIBED_CHANNELS, {
		channelType = channelType,
	}, callback)
end

--- Moderation APIs

--- Delete a chat message. <version> must match the latest or pass -1 to bypass version check.
-- Service Name - chat
-- Service Operation - DELETE_CHAT_MESSAGE
-- 
-- @param channelId The id of the chat channel that contains the message to delete.
-- @param msgId The message id to delete.
-- @param version Version of the message to delete. Must match latest or pass -1 to bypass version check.
-- @param callback The method to be invoked when the server response is received
-- 
function Chat:deleteChatMessage(channelId, msgId, version, callback)
	self.client:sendRequest(SERVICE, OPS.DELETE_CHAT_MESSAGE, {
		channelId = channelId,
		msgId = msgId,
		version = version,
	}, callback)
end

--- Update a chat message.
-- <content> must contain at least a "text" field for text-text messaging.
-- <version> must match the latest or pass -1 to bypass version check.
-- Service Name - chat
-- Service Operation - UPDATE_CHAT_MESSAGE
-- 
-- @param channelId Channel id where the message to update is.
-- @param msgId Message id to update.
-- @param version Version of the message to update. Must match latest or pass -1 to bypass version check.
-- @param content Data to update. Object containing "text" for the text message. Can also has rich content for custom data.
-- @param callback The method to be invoked when the server response is received.
-- 
function Chat:updateChatMessage(channelId, msgId, version, content, callback)
	self.client:sendRequest(SERVICE, OPS.UPDATE_CHAT_MESSAGE, {
		channelId = channelId,
		msgId = msgId,
		version = version,
		content = content,
	}, callback)
end

return Chat
