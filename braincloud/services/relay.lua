
local Relay = {}
Relay.__index = Relay

Relay.ConnectionType = {
	WEBSOCKET = "ws",
	TCP = "tcp",
	UDP = "udp",
}

Relay.TO_ALL_PLAYERS = 0xFFFFFFFFFF
Relay.CHANNEL_HIGH_PRIORITY_1 = 0
Relay.CHANNEL_HIGH_PRIORITY_2 = 1
Relay.CHANNEL_NORMAL_PRIORITY = 2
Relay.CHANNEL_LOW_PRIORITY = 3

function Relay.new(brainCloudClient)
	local self = setmetatable({}, Relay)
	self.client = brainCloudClient
	return self
end

function Relay:_comms()
	return self.client.brainCloudRelayComms
end

--- Start a connection, based on connection type to
-- brainClouds Relay Servers. Connect options come in
-- from ROOM_ASSIGNED lobby callback.
-- @param connectionType
-- @param host
-- @param port
-- @param passcode
-- @param lobbyId
-- 
-- @param callback Callback objects that report Success or Failure|Disconnect.
--        @note SSL option will only work with WEBSOCKET connetion type.
-- 
function Relay:connect(connectionType, options, success, failure)
	if type(connectionType) == "table" then
		connectionType, options, success, failure = Relay.ConnectionType.WEBSOCKET, connectionType, options, success
	end
	self:_comms():connect(connectionType, options, success, failure)
end

--- Disconnects from the relay server
-- 
-- 
function Relay:disconnect()
	self:_comms():disconnect()
end

--- Requests to end the current match on the relay server
-- 
-- 
function Relay:endMatch(json)
	self:_comms():endMatch(json or {})
end

function Relay:isConnected()
	return self:_comms():isConnected()
end

--- Last round-trip time to the relay server, in ms (999 = unknown/timed out).
function Relay:getPing()
	return self:_comms():getPing()
end

--- Set the ping interval. Ping allows to keep the connection
-- alive, but also inform the player of his current ping.
-- The default is 1 second interval.
-- 
-- 
function Relay:setPingInterval(seconds)
	self:_comms():setPingInterval(seconds)
end

function Relay:getOwnerProfileId()
	return self:_comms():getOwnerProfileId()
end

function Relay:getOwnerCxId()
	return self:_comms():getOwnerCxId()
end

function Relay:getProfileIdForNetId(netId)
	return self:_comms():getProfileIdForNetId(netId)
end

function Relay:getNetIdForProfileId(profileId)
	return self:_comms():getNetIdForProfileId(profileId)
end

function Relay:getCxIdForNetId(netId)
	return self:_comms():getCxIdForNetId(netId)
end

function Relay:getNetIdForCxId(cxId)
	return self:_comms():getNetIdForCxId(cxId)
end

--- Register callback for relay messages coming from peers.
-- 
-- @param callback Called whenever a relay message was received.
-- 
function Relay:registerRelayCallback(callback)
	self:_comms():registerRelayCallback(callback)
end

function Relay:deregisterRelayCallback()
	self:_comms():deregisterRelayCallback()
end

--- Register callback for RelayServer system messages.
-- 
-- @param callback Called whenever a system message was received. function(json)
--        # CONNECT
--        Received when a new member connects to the server.
--        {
--        op: "CONNECT",
--        profileId: "...",
--        ownerId: "...",
--        netId: #
--        }
--        # NET_ID
--        Receive the Net Id assossiated with a profile Id. This is
--        sent for each already connected members once you
--        successfully connected.
--        {
--        op: "NET_ID",
--        profileId: "...",
--        netId: #
--        }
--        # DISCONNECT
--        Received when a member disconnects from the server.
--        {
--        op: "DISCONNECT",
--        profileId: "..."
--        }
--        # MIGRATE_OWNER
--        If the owner left or never connected in a timely manner,
--        the relay-server will migrate the role to the next member
--        with the best ping. If no one else is currently connected
--        yet, it will be transferred to the next member in the
--        lobby members' list. This last scenario can only occur if
--        the owner connected first, then quickly disconnected.
--        Leaving only unconnected lobby members.
--        {
--        op: "MIGRATE_OWNER",
--        profileId: "..."
--        }
-- 
function Relay:registerSystemCallback(callback)
	self:_comms():registerSystemCallback(callback)
end

function Relay:deregisterSystemCallback()
	self:_comms():deregisterSystemCallback()
end

--- Send a packet to peer(s)
-- 
-- @param data Byte array for the data to send
-- @param size Size of data in bytes
-- @param toNetId The net id to send to, TO_ALL_PLAYERS to relay to all.
-- @param reliable Send this reliable or not.
-- @param ordered Receive this ordered or not.
-- @param channel One of: (CHANNEL_HIGH_PRIORITY_1, CHANNEL_HIGH_PRIORITY_2, CHANNEL_NORMAL_PRIORITY, CHANNEL_LOW_PRIORITY)
-- 
function Relay:send(data, toNetId, reliable, ordered, channel)
	self:_comms():sendRelay(data, 2 ^ toNetId, reliable, ordered, channel)
end

--- Send a packet to any players by using a mask
-- 
-- @param data Byte array for the data to send
-- @param size Size of data in bytes
-- @param playerMask Mask of the players to send to. 0001 = netId 0, 0010 = netId 1, etc. If you pass ALL_PLAYER_MASK you will be included and you will get an echo for your message. Use sendToAll instead, you will be filtered out. You can manually filter out by : ALL_PLAYER_MASK &= ~(1 << myNetId)
-- @param reliable Send this reliable or not.
-- @param ordered Receive this ordered or not.
-- @param channel One of: (CHANNEL_HIGH_PRIORITY_1, CHANNEL_HIGH_PRIORITY_2, CHANNEL_NORMAL_PRIORITY, CHANNEL_LOW_PRIORITY)
-- 
function Relay:sendToPlayers(data, playerMask, reliable, ordered, channel)
	self:_comms():sendRelay(data, playerMask, reliable, ordered, channel)
end

--- Send a packet to all except yourself
-- 
-- @param data Byte array for the data to send
-- @param size Size of data in bytes
-- @param reliable Send this reliable or not.
-- @param ordered Receive this ordered or not.
-- @param channel One of: (CHANNEL_HIGH_PRIORITY_1, CHANNEL_HIGH_PRIORITY_2, CHANNEL_NORMAL_PRIORITY, CHANNEL_LOW_PRIORITY)
-- 
function Relay:sendToAll(data, reliable, ordered, channel)
	local comms = self:_comms()
	local mask = Relay.TO_ALL_PLAYERS
	local myNetId = comms:getNetId()
	if myNetId and myNetId >= 0 and myNetId < 40 then
		mask = mask - 2 ^ myNetId
	end
	comms:sendRelay(data, mask, reliable, ordered, channel)
end

return Relay
