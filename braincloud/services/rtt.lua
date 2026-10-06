local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")

local RTT = {}
RTT.__index = RTT

local SERVICE = "rttRegistration"

local OPS = {
	REQUEST_CLIENT_CONNECTION = "REQUEST_CLIENT_CONNECTION",
}

--- Create a new RTT service instance.
--- @param brainCloudClient table The brainCloud client instance.
--- @return RTT
function RTT.new(brainCloudClient)
	local self = setmetatable({}, RTT)
	self.client = brainCloudClient
	return self
end

--- Requests the event server address
-- Service Name - rttRegistration
-- Service Operation - REQUEST_CLIENT_CONNECTION
-- 
-- @param callback The callback.
-- 
function RTT:requestClientConnection(callback)
	self.client:sendRequest(SERVICE, OPS.REQUEST_CLIENT_CONNECTION, {}, callback)
end

--- Enables Real Time event for this session.
--- Real Time events are disabled by default. Usually events
--- need to be polled using GET_EVENTS. By enabling this, events will
--- be received instantly when they happen through a TCP connection to an Event Server.
--- This function will first call requestClientConnection, then connect to the address
--- @param callback The callback.
--- @param useWebSocket Use web sockets instead of TCP for the internal connections. Default is true
function RTT:enableRTT(success, failure)
	if not self.client.brainCloudRttComms then
		if failure then
			failure({ status = 0, status_message = "RTT comms not available" })
		end
		return
	end
	self.client.brainCloudRttComms:enableRTT(success, failure)
end

--- Disables Real Time event for this session.
function RTT:disableRTT()
	if self.client.brainCloudRttComms then
		self.client.brainCloudRttComms:disableRTT()
	end
end

--- Returns true if RTT is enabled.
function RTT:isRTTEnabled()
	if self.client.brainCloudRttComms then
		return self.client.brainCloudRttComms:isRTTEnabled()
	end
	return false
end

--- returns true if RTT is enabled
function RTT:getRTTEnabled()
	return self:isRTTEnabled()
end

--- Returns the RTT connection status.
function RTT:getConnectionStatus()
	if self.client.brainCloudRttComms then
		return self.client.brainCloudRttComms:getConnectionStatus()
	end
	return "Disconnected"
end

--- Returns the RTT connection id.
function RTT:getRTTConnectionId()
	if self.client.brainCloudRttComms then
		return self.client.brainCloudRttComms:getRTTConnectionId()
	end
	return nil
end

--- Register/deregister RTT callbacks for service names.
function RTT:registerRTTCallback(serviceName, callback)
	if self.client.brainCloudRttComms then
		self.client.brainCloudRttComms:registerRTTCallback(serviceName, callback)
	end
end

function RTT:deregisterRTTCallback(serviceName)
	if self.client.brainCloudRttComms then
		self.client.brainCloudRttComms:deregisterRTTCallback(serviceName)
	end
end

function RTT:deregisterAllRTTCallbacks()
	if self.client.brainCloudRttComms then
		self.client.brainCloudRttComms:deregisterAllRTTCallbacks()
	end
end

--- Listen to real time events.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one event callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTEventCallback(callback)
	self:registerRTTCallback("event", callback)
end

function RTT:deregisterRTTEventCallback()
	self:deregisterRTTCallback("event")
end

--- Listen to real time chat messages.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one chat callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTChatCallback(callback)
	self:registerRTTCallback("chat", callback)
end

function RTT:deregisterRTTChatCallback()
	self:deregisterRTTCallback("chat")
end

--- Listen to real time messaging.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one messaging callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTMessagingCallback(callback)
	self:registerRTTCallback("messaging", callback)
end

function RTT:deregisterRTTMessagingCallback()
	self:deregisterRTTCallback("messaging")
end

--- Listen to real time lobby events.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one lobby callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTLobbyCallback(callback)
	self:registerRTTCallback("lobby", callback)
end

function RTT:deregisterRTTLobbyCallback()
	self:deregisterRTTCallback("lobby")
end

--- Listen to real time presence events.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one presence callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTPresenceCallback(callback)
	self:registerRTTCallback("presence", callback)
end

function RTT:deregisterRTTPresenceCallback()
	self:deregisterRTTCallback("presence")
end

--- Listen to real time blockchain events.
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one presence callback can be registered at a time. Calling this a second time will override the previous callback.
-- 
-- 
function RTT:registerRTTBlockchainRefresh(callback)
	self:registerRTTCallback("blockchain", callback)
end

function RTT:deregisterRTTBlockchainRefresh()
	self:deregisterRTTCallback("blockchain")
end

--- Listen to real time user item events.
--
-- Notes: RTT must be enabled for this app, and enableRTT must have been successfully called.
-- Only one user items callback can be registered at a time. Calling this a second time will override the previous callback.
--
-- @param callback function(message) with message.service, message.operation and message.data
function RTT:registerRTTUserItemsCallback(callback)
	self:registerRTTCallback("userItems", callback)
end

function RTT:deregisterRTTUserItemsCallback()
	self:deregisterRTTCallback("userItems")
end

-- Same as registerRTTBlockchainRefresh (JS name).
RTT.registerRTTBlockchainCallback = RTT.registerRTTBlockchainRefresh
RTT.deregisterRTTBlockchainCallback = RTT.deregisterRTTBlockchainRefresh

return RTT
