local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local Utils = require(ROOT .. ".util")
local brainCloudMessaging = {}
brainCloudMessaging.__index = brainCloudMessaging

local SERVICE = "messaging"
local OPS = {
	DELETE_MESSAGES = "DELETE_MESSAGES",
	GET_MESSAGE_BOXES = "GET_MESSAGE_BOXES",
	GET_MESSAGE_COUNTS = "GET_MESSAGE_COUNTS",
	GET_MESSAGES = "GET_MESSAGES",
	GET_MESSAGES_PAGE = "GET_MESSAGES_PAGE",
	GET_MESSAGES_PAGE_OFFSET = "GET_MESSAGES_PAGE_OFFSET",
	MARK_MESSAGES_READ = "MARK_MESSAGES_READ",
	SEND_MESSAGE = "SEND_MESSAGE",
	SEND_MESSAGE_SIMPLE = "SEND_MESSAGE_SIMPLE",
}

function brainCloudMessaging.new(client)
	local self = setmetatable({}, brainCloudMessaging)
	self.client = client
	return self
end

--- Deletes specified user messages on the server.
-- Service Name - messaging
-- Service Operation - DELETE_MESSAGES
-- 
-- @param msgIds Arrays of message ids to delete.
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:deleteMessages(msgbox, msgIds, callback)
	local data = {
		msgbox = msgbox,
		msgIds = Utils.array(msgIds),
	}
	self.client:sendRequest(SERVICE, OPS.DELETE_MESSAGES, data, callback)
end

--- Retrieve user's message boxes, including 'inbox', 'sent', etc.
-- Service Name - messaging
-- Service Operation - GET_MESSAGE_BOXES
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:getMessageboxes(callback)
	self.client:sendRequest(SERVICE, OPS.GET_MESSAGE_BOXES, {}, callback)
end

--- Retrieve user's message boxes, including 'inbox', 'sent', etc.
-- Service Name - messaging
-- Service Operation - GET_MESSAGE_COUNTS
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:getMessageCounts(callback)
	self.client:sendRequest(SERVICE, OPS.GET_MESSAGE_COUNTS, {}, callback)
end

--- Retrieves list of specified messages.
-- Service Name - messaging
-- Service Operation - GET_MESSAGES
-- 
-- @param msgIds Arrays of message ids to get.
-- @param markAsRead mark messages that are read
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:getMessages(msgbox, msgIds, markMessageRead, callback)
	local data = {
		msgbox = msgbox,
		msgIds = Utils.array(msgIds),
		markAsRead = markMessageRead,
	}
	self.client:sendRequest(SERVICE, OPS.GET_MESSAGES, data, callback)
end

--- Retrieves a page of messages.
-- @param context
-- Service Name - messaging
-- Service Operation - GET_MESSAGES_PAGE
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:getMessagesPage(context, callback)
	local data = { context = context }
	self.client:sendRequest(SERVICE, OPS.GET_MESSAGES_PAGE, data, callback)
end

--- Gets the page of messages from the server based on the encoded context and specified page offset.
-- @param context
-- @param pageOffset
-- Service Name - messaging
-- Service Operation - GET_MESSAGES_PAGE_OFFSET
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:getMessagesPageOffset(context, pageOffset, callback)
	local data = { context = context, pageOffset = pageOffset }
	self.client:sendRequest(SERVICE, OPS.GET_MESSAGES_PAGE_OFFSET, data, callback)
end

--- Sends a message with specified 'subject' and 'text' to list of users.
-- @param toProfileIds
-- Service Name - messaging
-- Service Operation - SEND_MESSAGE
-- 
-- @param contentJson the message you are sending
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:sendMessage(toProfileIds, content, callback)
	local data = { toProfileIds = toProfileIds, contentJson = content }
	self.client:sendRequest(SERVICE, OPS.SEND_MESSAGE, data, callback)
end

--- Sends a simple message to specified list of users.
-- @param toProfileIds
-- @param messageText
-- Service Name - messaging
-- Service Operation - SEND_MESSAGE_SIMPLE
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:sendMessageSimple(toProfileIds, messageText, callback)
	local data = { toProfileIds = toProfileIds, text = messageText }
	self.client:sendRequest(SERVICE, OPS.SEND_MESSAGE_SIMPLE, data, callback)
end

--- Marks list of user messages as read on the server.
-- @param msgbox
-- @param msgIds
-- Service Name - messaging
-- Service Operation - MARK_MESSAGES_READ
-- 
-- @param callback The method to be invoked when the server response is received
-- 
function brainCloudMessaging:markMessagesRead(msgbox, msgIds, callback)
	local data = { msgbox = msgbox, msgIds = Utils.array(msgIds) }
	self.client:sendRequest(SERVICE, OPS.MARK_MESSAGES_READ, data, callback)
end

return brainCloudMessaging
