-- Relay server connection over WebSocket, TCP or UDP. Wire format and reliability rules follow
-- the C++ RelayComms: [size u16][control u8][...], 11-byte relay header, UDP acks/resends and
-- ordered-reliable reassembly.

local ROOT = (...):match("^(.*)%.[^%.]+$")
local json = require(ROOT .. ".lib.json")
local Platform = require(ROOT .. ".platform.core")
local WebSocket = require(ROOT .. ".net.websocket")
local Stream = require(ROOT .. ".net.stream")
local Web = require(ROOT .. ".platform.web")

local RelayComms = {}
RelayComms.__index = RelayComms

local MAX_PLAYERS = 40
local INVALID_NET_ID = MAX_PLAYERS

local CL2RS_CONNECT = 0
local CL2RS_DISCONNECT = 1
local CL2RS_RELAY = 2
local CL2RS_ACK = 3
local CL2RS_PING = 4
local CL2RS_RSMG_ACK = 5
local CL2RS_ENDMATCH = 6

local RS2CL_RSMG = 0
local RS2CL_DISCONNECT = 1
local RS2CL_RELAY = 2
local RS2CL_ACK = 3
local RS2CL_PONG = 4

local RELIABLE_BIT = 0x8000
local ORDERED_BIT = 0x4000

local CONNECT_RESEND_INTERVAL = 2
local MAX_RELIABLE_RESEND_INTERVAL = 0.5
local MAX_PACKET_ID = 0xFFF
local PACKET_LOWER_THRESHOLD = math.floor(MAX_PACKET_ID * 25 / 100)
local PACKET_HIGHER_THRESHOLD = math.floor(MAX_PACKET_ID * 75 / 100)
local MAX_PACKET_SIZE = 1024
local MAX_PACKET_ID_HISTORY = 60 * 10
local MAX_RSMG_HISTORY = 50
local UDP_TIMEOUT = 10
local RELIABLE_RESEND_INTERVALS = { 0.05, 0.05, 0.15, 0.5 }

local function u16(n)
	return string.char(math.floor(n / 256) % 256, n % 256)
end

local function readU16(s, i)
	local a, b = s:byte(i, i + 1)
	return a * 256 + b
end

local function profileIdFromCxId(cxId)
	if type(cxId) ~= "string" then
		return ""
	end
	local first = cxId:find(":", 1, true)
	local last = cxId:match(".*():")
	if not first or first == last or last - first < 2 then
		return ""
	end
	return cxId:sub(first + 1, last - 1)
end

-- a <= b with 12-bit wraparound
local function packetLE(a, b)
	if a > PACKET_HIGHER_THRESHOLD and b <= PACKET_LOWER_THRESHOLD then
		return true
	end
	if b > PACKET_HIGHER_THRESHOLD and a <= PACKET_LOWER_THRESHOLD then
		return false
	end
	return a <= b
end

-- 40-bit player mask → 6 wire bytes: bit order reversed, shifted left 8.
local function encodePlayerMask(playerMask)
	local reversed = 0
	local p = 1
	for i = 0, MAX_PLAYERS - 1 do
		local bitIndex = MAX_PLAYERS - i - 1
		if math.floor(playerMask / 2 ^ bitIndex) % 2 == 1 then
			reversed = reversed + p
		end
		p = p * 2
	end
	local v = reversed * 256
	local out = {}
	for i = 6, 1, -1 do
		out[i] = string.char(v % 256)
		v = math.floor(v / 256)
	end
	return table.concat(out)
end

function RelayComms.new(client)
	local self = setmetatable({}, RelayComms)
	self.client = client
	self._debugEnabled = false
	self._pingInterval = 1
	self:_reset()
	return self
end

function RelayComms:_reset()
	self._isConnected = false
	self._isSocketConnected = false
	self._resendConnectRequest = false
	self._ping = 999
	self._netId = -1
	self._ownerProfileId = ""
	self._ownerCxId = ""
	self._netIdToCxId = {}
	self._cxIdToNetId = {}
	self._netIdToProfileId = {}
	self._profileIdToNetId = {}
	self._sendPacketId = {}
	self._recvPacketId = {}
	self._reliables = {}
	self._orderedReliablePackets = {}
	self._rsmgHistory = {}
	self._trackedPacketIds = { {}, {}, {}, {} }
	self._tcpBuffer = ""
end

function RelayComms:setDebugEnabled(enabled)
	self._debugEnabled = enabled == true
end

function RelayComms:_log(...)
	if self._debugEnabled then
		Platform.log("[Relay]", ...)
	end
end

function RelayComms:isConnected()
	return self._isConnected
end

function RelayComms:getPing()
	return self._ping
end

function RelayComms:getNetId()
	return self._netId
end

function RelayComms:setPingInterval(seconds)
	if seconds > 999 then
		seconds = seconds / 1000
	end
	self._pingInterval = seconds
end

function RelayComms:getOwnerProfileId()
	return self._ownerProfileId
end

function RelayComms:getOwnerCxId()
	return self._ownerCxId
end

function RelayComms:getProfileIdForNetId(netId)
	return self._netIdToProfileId[netId] or ""
end

function RelayComms:getNetIdForProfileId(profileId)
	return self._profileIdToNetId[profileId] or INVALID_NET_ID
end

function RelayComms:getCxIdForNetId(netId)
	return self._netIdToCxId[netId] or ""
end

function RelayComms:getNetIdForCxId(cxId)
	return self._cxIdToNetId[cxId] or INVALID_NET_ID
end

function RelayComms:registerRelayCallback(fn)
	self._relayCallback = fn
end

function RelayComms:deregisterRelayCallback()
	self._relayCallback = nil
end

function RelayComms:registerSystemCallback(fn)
	self._systemCallback = fn
end

function RelayComms:deregisterSystemCallback()
	self._systemCallback = nil
end

-- CONNECTION

function RelayComms:connect(connectionType, options, success, failure)
	local client = self.client
	self._connectSuccess = success
	self._connectFailure = failure
	if not client:isAuthenticated() or client:isKillswitchEngaged() then
		self:_queueError("Relay: Connect called before calling authentication request.")
		return
	end
	if not (options and options.host and options.port and options.passcode and options.lobbyId) then
		self:_queueError("Relay: Invalid connect options (need host, port, passcode, lobbyId)")
		return
	end
	if self._socket or self._isSocketConnected then
		self:_socketCleanup()
	end
	self:_reset()
	self._endMatchRequested = false
	self._connectionType = connectionType
	self._options = options
	self._lastRecvTime = Platform.now()
	self._lastPingTime = Platform.now()
	self._events = self._events or {}

	if Web.available() and connectionType ~= "ws" then
		self:_queueError("Relay: browsers only support WebSocket relay connections (use ws with ssl = true)")
		return
	end

	if connectionType == "ws" then
		if not WebSocket.available(options.ssl) then
			self:_queueError("Relay: secure WebSocket needs the brainCloud native pack (ssl module)")
			return
		end
		local uri = (options.ssl and "wss://" or "ws://") .. options.host .. ":" .. tostring(options.port)
		self._socket = {
			kind = "ws",
			ws = WebSocket.new(uri, {
				onOpen = function()
					self:_onSocketConnected()
				end,
				onMessage = function(data)
					self:_onRecv(data)
				end,
				onClose = function(_, reason)
					self:_onSocketLost("Relay: socket closed " .. tostring(reason or ""))
				end,
			}),
		}
	elseif connectionType == "tcp" then
		self._socket = { kind = "tcp", stream = Stream.new(options.host, options.port, false) }
	elseif connectionType == "udp" then
		local socket = Platform.socket
		local ip = socket and socket.dns.toip(options.host)
		if not ip then
			self:_queueError("Relay: could not resolve " .. tostring(options.host))
			return
		end
		local udp = ip:find(":", 1, true) and socket.udp6 and socket.udp6() or socket.udp()
		udp:settimeout(0)
		local ok, err = udp:setpeername(ip, options.port)
		if not ok then
			self:_queueError("Relay: UDP setup failed: " .. tostring(err))
			return
		end
		self._socket = { kind = "udp", udp = udp }
		self:_onSocketConnected()
	else
		self:_queueError("Relay: Protocol Unimplemented " .. tostring(connectionType))
	end
end

function RelayComms:_buildConnectionRequest()
	self._cxId = self.client.rttService:getRTTConnectionId()
	return {
		lobbyId = self._options.lobbyId,
		cxId = self._cxId,
		passcode = self._options.passcode,
		version = self.client:getBrainCloudClientVersion(),
	}
end

function RelayComms:_onSocketConnected()
	self._isSocketConnected = true
	self:_log("socket connected (" .. self._connectionType .. ")")
	self:_sendText(CL2RS_CONNECT, json.encode(self:_buildConnectionRequest()))
	if self._connectionType == "udp" then
		self._resendConnectRequest = true
		self._lastConnectResendTime = Platform.now()
	end
end

function RelayComms:_onSocketLost(message)
	if self._socket then
		self:_socketCleanup()
		self:_queueError(message)
	end
end

function RelayComms:endMatch(jsonPayload)
	if self._isSocketConnected then
		self:_sendText(CL2RS_ENDMATCH, json.encode(jsonPayload or {}))
	end
end

function RelayComms:disconnect()
	if self._isSocketConnected then
		self:_sendText(CL2RS_DISCONNECT, "")
	end
	self:_socketCleanup()
end

function RelayComms:_socketCleanup()
	local s = self._socket
	self._socket = nil
	if s then
		if s.ws then
			s.ws:close()
		elseif s.stream then
			s.stream:flush()
			s.stream:close()
		elseif s.udp then
			s.udp:close()
		end
	end
	self._isConnected = false
	self._isSocketConnected = false
	self._resendConnectRequest = false
	self._sendPacketId = {}
	self._recvPacketId = {}
	self._rsmgHistory = {}
	self._reliables = {}
	self._orderedReliablePackets = {}
end

-- SENDING

function RelayComms:_sendRaw(packet)
	local s = self._socket
	if not s then
		return
	end
	if s.ws then
		s.ws:send(packet, true)
	elseif s.stream then
		s.stream:send(packet)
	elseif s.udp then
		s.udp:send(packet)
	end
end

-- [size][controlByte][text]
function RelayComms:_sendText(controlByte, text)
	self:_sendRaw(u16(#text + 3) .. string.char(controlByte) .. text)
end

function RelayComms:sendRelay(data, playerMask, reliable, ordered, channel)
	if not self._isConnected or playerMask == 0 then
		return
	end
	data = type(data) == "table" and json.encode(data) or tostring(data)
	channel = channel or 0
	if #data > MAX_PACKET_SIZE then
		self:_socketCleanup()
		self:_queueError("Relay Error: Packet is too big " .. #data .. " > max " .. MAX_PACKET_SIZE)
		return
	end

	local rh = 0
	if reliable then
		rh = rh + RELIABLE_BIT
	end
	if ordered then
		rh = rh + ORDERED_BIT
	end
	rh = rh + (channel % 4) * 4096

	local maskBytes = encodePlayerMask(playerMask)
	local key = u16(rh) .. maskBytes
	local packetId = self._sendPacketId[key] or 0
	self._sendPacketId[key] = (packetId + 1) % (MAX_PACKET_ID + 1)
	rh = rh + packetId

	local header = u16(rh) .. maskBytes
	local packet = u16(#data + 11) .. string.char(CL2RS_RELAY) .. header .. data
	self:_sendRaw(packet)

	if reliable and self._connectionType == "udp" then
		local now = Platform.now()
		self._reliables[header] = {
			data = packet,
			lastResendTime = now,
			firstSendTime = now,
			resendInterval = RELIABLE_RESEND_INTERVALS[channel + 1],
		}
	end
end

function RelayComms:_sendPing()
	self._lastPingTime = Platform.now()
	self:_sendRaw(u16(5) .. string.char(CL2RS_PING) .. u16(math.min(self._ping, 65535)))
end

-- RECEIVING

function RelayComms:_onRecv(packet)
	self._lastRecvTime = Platform.now()
	local size = #packet
	if size < 3 then
		self:_socketCleanup()
		self:_queueError("Relay Recv Error: packet cannot be smaller than 3 bytes")
		return
	end
	local headerSize = readU16(packet, 1)
	local controlByte = packet:byte(3)
	if headerSize < size then
		self:_socketCleanup()
		self:_queueError("Relay Recv Error: Packet is smaller than header's size")
		return
	end

	if controlByte == RS2CL_RSMG then
		if size < 5 then
			self:_socketCleanup()
			self:_queueError("Relay Recv Error: RSMG cannot be smaller than 5 bytes")
			return
		end
		self:_onRSMG(packet:sub(4))
	elseif controlByte == RS2CL_DISCONNECT then
		self:_socketCleanup()
		self:_queueError("Relay: Disconnected by server")
	elseif controlByte == RS2CL_PONG then
		self._ping = math.min(999, math.floor((Platform.now() - self._lastPingTime) * 1000 + 0.5))
	elseif controlByte == RS2CL_ACK then
		if size < 11 then
			self:_socketCleanup()
			self:_queueError("Relay Recv Error: ack packet cannot be smaller than 11 bytes")
			return
		end
		if self._connectionType == "udp" then
			self._reliables[packet:sub(4, 11)] = nil
		end
	elseif controlByte == RS2CL_RELAY then
		if size < 11 then
			self:_socketCleanup()
			self:_queueError("Relay Recv Error: relay packet cannot be smaller than 11 bytes")
			return
		end
		self:_onRelay(packet:sub(4))
	else
		self:_socketCleanup()
		self:_queueError("Relay Recv Error: Unknown control byte: " .. tostring(controlByte))
	end
end

function RelayComms:_onRSMG(data)
	local rsmgPacketId = readU16(data, 1)
	local text = data:sub(3)
	self:_log("system", text)

	if self._connectionType == "udp" then
		self:_sendRaw(u16(5) .. string.char(CL2RS_RSMG_ACK) .. u16(rsmgPacketId))
		for _, id in ipairs(self._rsmgHistory) do
			if id == rsmgPacketId then
				return
			end
		end
		table.insert(self._rsmgHistory, rsmgPacketId)
		while #self._rsmgHistory > MAX_RSMG_HISTORY do
			table.remove(self._rsmgHistory, 1)
		end
	end

	local ok, msg = pcall(json.decode, text)
	if not ok or type(msg) ~= "table" then
		return
	end

	local op = msg.op
	if op == "CONNECT" or op == "NET_ID" then
		local netId, cxId = msg.netId, msg.cxId
		local profileId = profileIdFromCxId(cxId)
		self._netIdToCxId[netId] = cxId
		self._cxIdToNetId[cxId] = netId
		self._netIdToProfileId[netId] = profileId
		self._profileIdToNetId[profileId] = netId
		if op == "NET_ID" and type(msg.orderedPacketIds) == "table" then
			for ch, id in ipairs(msg.orderedPacketIds) do
				if id ~= 0 and self._trackedPacketIds[ch] then
					self._trackedPacketIds[ch][netId] = id
				end
			end
		end
		if op == "CONNECT" and cxId == self._cxId then
			self._netId = netId
			self._ownerCxId = msg.ownerCxId or ""
			self._ownerProfileId = profileIdFromCxId(self._ownerCxId)
			self._lastPingTime = Platform.now()
			self._isConnected = true
			self._resendConnectRequest = false
			self:_queue({ type = "connect", message = msg })
		end
	elseif op == "MIGRATE_OWNER" then
		self._ownerCxId = msg.cxId or ""
		self._ownerProfileId = profileIdFromCxId(self._ownerCxId)
	elseif op == "DISCONNECT" then
		if msg.cxId == self._cxId then
			self:_socketCleanup()
			self:_queueError("Relay: Disconnected by server")
			return
		end
	elseif op == "END_MATCH" then
		self._endMatchRequested = true
		self:_queue({ type = "system", message = msg })
		self:_socketCleanup()
		return
	end

	self:_queue({ type = "system", message = msg })
end

function RelayComms:_onRelay(data)
	local rh = readU16(data, 1)
	local reliable = rh >= RELIABLE_BIT
	local ordered = math.floor(rh / ORDERED_BIT) % 2 == 1
	local channel = math.floor(rh / 4096) % 4
	local packetId = rh % 4096
	local netId = data:byte(8)
	local payload = data:sub(9)

	if self._connectionType == "udp" then
		if reliable then
			self:_sendRaw(u16(11) .. string.char(CL2RS_ACK) .. data:sub(1, 8))
		end
		if ordered then
			-- ack id with the packet id bits cleared
			local hi = math.floor(rh / 4096) * 4096
			local key = u16(hi) .. data:sub(3, 8)
			local prevPacketId = self._recvPacketId[key] or MAX_PACKET_ID
			local tracked = self._trackedPacketIds[channel + 1]
			if tracked and tracked[netId] then
				prevPacketId = tracked[netId]
				tracked[netId] = nil
			end

			if reliable then
				if packetLE(packetId, prevPacketId) then
					return -- duplicate
				end
				local queue = self._orderedReliablePackets[key]
				if not queue then
					queue = {}
					self._orderedReliablePackets[key] = queue
				end
				if packetId ~= (prevPacketId + 1) % (MAX_PACKET_ID + 1) then
					if #queue > MAX_PACKET_ID_HISTORY then
						self:_socketCleanup()
						self:_queueError("Relay disconnected, too many queued out of order packets.")
						return
					end
					local insertIdx = #queue + 1
					for i, p in ipairs(queue) do
						if p.id == packetId then
							return
						end
						if packetLE(packetId, p.id) then
							insertIdx = i
							break
						end
					end
					table.insert(queue, insertIdx, { id = packetId, netId = netId, data = payload })
					return
				end
				self._recvPacketId[key] = packetId
				self:_queue({ type = "relay", netId = netId, data = payload })
				while #queue > 0 and queue[1].id == (packetId + 1) % (MAX_PACKET_ID + 1) do
					local p = table.remove(queue, 1)
					packetId = p.id
					self._recvPacketId[key] = packetId
					self:_queue({ type = "relay", netId = p.netId, data = p.data })
				end
				return
			end
			if packetLE(packetId, prevPacketId) then
				return -- out of order unreliable, drop
			end
			self._recvPacketId[key] = packetId
		end
	end

	self:_queue({ type = "relay", netId = netId, data = payload })
end

-- EVENTS (callbacks fire from update, like the other SDKs' runCallbacks)

function RelayComms:_queue(event)
	self._events = self._events or {}
	self._events[#self._events + 1] = event
end

function RelayComms:_queueError(message)
	self:_log(message)
	self:_queue({ type = "error", message = message })
end

-- Pulls whole packets out of the socket.
function RelayComms:_pump()
	local s = self._socket
	if not s then
		return
	end
	if s.ws then
		s.ws:update()
	elseif s.stream then
		local ok, err = s.stream:update()
		if not ok then
			self:_onSocketLost("Relay Socket Error: " .. tostring(err))
			return
		end
		if not self._isSocketConnected and s.stream:isConnected() then
			self:_onSocketConnected()
		end
		local data, rerr = s.stream:receive()
		if data then
			self._tcpBuffer = self._tcpBuffer .. data
			while #self._tcpBuffer >= 2 do
				local n = readU16(self._tcpBuffer, 1)
				if n < 3 or n > MAX_PACKET_SIZE + 11 then
					self:_onSocketLost("Relay Recv Error: bad packet size " .. n)
					return
				end
				if #self._tcpBuffer < n then
					break
				end
				local packet = self._tcpBuffer:sub(1, n)
				self._tcpBuffer = self._tcpBuffer:sub(n + 1)
				self:_onRecv(packet)
				if not self._socket then
					return
				end
			end
		end
		if rerr == "closed" then
			self:_onSocketLost("Relay: connection closed")
		end
	elseif s.udp then
		while self._socket do
			local datagram = s.udp:receive()
			if not datagram then
				break
			end
			self:_onRecv(datagram)
		end
	end
end

function RelayComms:update(now)
	if self._socket then
		self:_pump()
	end
	if self._socket and self._isSocketConnected then
		local udp = self._connectionType == "udp"
		if udp and self._resendConnectRequest and now - self._lastConnectResendTime > CONNECT_RESEND_INTERVAL then
			self._lastConnectResendTime = now
			self:_sendText(CL2RS_CONNECT, json.encode(self:_buildConnectionRequest()))
		end
		if self._isConnected and now - self._lastPingTime >= self._pingInterval then
			self:_sendPing()
		end
		if udp then
			for _, p in pairs(self._reliables) do
				if now - p.firstSendTime > 10 then
					self:_socketCleanup()
					self:_queueError("Relay disconnected, too many packet lost")
					break
				end
				if now - p.lastResendTime >= p.resendInterval then
					p.lastResendTime = now
					p.resendInterval = math.min(p.resendInterval * 1.25, MAX_RELIABLE_RESEND_INTERVAL)
					self:_sendRaw(p.data)
				end
			end
			if self._socket and now - self._lastRecvTime > UDP_TIMEOUT then
				self:_socketCleanup()
				self:_queueError("Relay Socket Timeout")
			end
		end
	end

	local events = self._events
	if not events or #events == 0 then
		return
	end
	self._events = {}
	for _, e in ipairs(events) do
		local ok, err = true, nil
		if e.type == "connect" then
			if self._connectSuccess then
				ok, err = pcall(self._connectSuccess, e.message)
			end
		elseif e.type == "error" then
			if self._connectFailure and not self._endMatchRequested then
				ok, err = pcall(self._connectFailure, e.message)
			end
		elseif e.type == "system" then
			if self._systemCallback then
				ok, err = pcall(self._systemCallback, e.message)
			end
		elseif e.type == "relay" then
			if self._relayCallback then
				ok, err = pcall(self._relayCallback, e.netId, e.data)
			end
		end
		if not ok then
			Platform.log("relay callback error: " .. tostring(err))
		end
	end
end

return RelayComms
