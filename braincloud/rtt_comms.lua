-- RTT (real-time tech) connection: requests an endpoint, opens the WebSocket, sends CONNECT,
-- heartbeats at the server's interval and routes messages to per-service callbacks.

local ROOT = (...):match("^(.*)%.[^%.]+$")
local json = require(ROOT .. ".lib.json")
local WebSocket = require(ROOT .. ".net.websocket")

local RTTComms = {}
RTTComms.__index = RTTComms

local Status = {
	CONNECTED = "Connected",
	DISCONNECTED = "Disconnected",
	CONNECTING = "Connecting",
	DISCONNECTING = "Disconnecting",
}
RTTComms.Status = Status

function RTTComms.new(client)
	local self = setmetatable({}, RTTComms)
	self.client = client
	self._status = Status.DISCONNECTED
	self.connectionId = nil
	self.callbacks = {}
	self._debugEnabled = false
	self._heartbeatSeconds = 30
	self._lastHeartbeat = 0
	self._connectCallback = nil
	return self
end

function RTTComms:setDebugEnabled(enabled)
	self._debugEnabled = enabled == true
end

function RTTComms:_log(...)
	if self._debugEnabled then
		self.client.platform.log("[RTT]", ...)
	end
end

function RTTComms:getRTTConnectionId()
	return self.connectionId
end

function RTTComms:getConnectionStatus()
	return self._status
end

function RTTComms:isRTTEnabled()
	return self._status == Status.CONNECTED
end

function RTTComms:registerRTTCallback(serviceName, callback)
	self.callbacks[serviceName] = callback
end

function RTTComms:deregisterRTTCallback(serviceName)
	self.callbacks[serviceName] = nil
end

function RTTComms:deregisterAllRTTCallbacks()
	self.callbacks = {}
end

local function pickEndpoint(endpoints)
	local plain
	for _, ep in ipairs(endpoints or {}) do
		if ep.protocol == "ws" then
			if ep.ssl then
				return ep
			end
			plain = plain or ep
		end
	end
	return plain
end

function RTTComms:_failConnect(message)
	self._status = Status.DISCONNECTED
	local cb = self._connectCallback
	self._connectCallback = nil
	if cb and cb.failure then
		cb.failure(message)
	end
end

--- enableRTT(success(connectMessage), failure(errorMessage))
function RTTComms:enableRTT(success, failure)
	if self._status == Status.CONNECTED then
		local msg = self._connectMessage
		self.client:defer(function()
			if success then
				success(msg)
			end
		end)
		return
	end
	self._connectCallback = { success = success, failure = failure }
	if self._status == Status.CONNECTING then
		return
	end
	self._disconnectReason = nil
	if not self.client:isAuthenticated() then
		self.client:defer(function()
			self:_failConnect("Invalid Session - Must be authenticated before enabling RTT.")
		end)
		return
	end
	self._status = Status.CONNECTING

	self.client.rttService:requestClientConnection(function(ok, result)
		if self._status ~= Status.CONNECTING then
			return
		end
		if not ok then
			self:_failConnect(result and result.status_message or "requestClientConnection failed")
			return
		end
		local ep = pickEndpoint(result.data.endpoints)
		if not ep then
			self:_failConnect("WebSocket endpoint missing")
			return
		end
		if not WebSocket.available(ep.ssl) then
			self:_failConnect("RTT needs TLS: add the brainCloud native pack (ssl module) for this platform")
			return
		end
		self:_connect(ep, result.data.auth or {})
	end)
end

function RTTComms:_connect(ep, auth)
	self._auth = auth
	local query = {}
	for k, v in pairs(auth) do
		query[#query + 1] = k .. "=" .. tostring(v)
	end
	table.sort(query)
	local uri = (ep.ssl and "wss://" or "ws://") .. ep.host .. ":" .. tostring(ep.port)
	if #query > 0 then
		uri = uri .. "/?" .. table.concat(query, "&")
	end
	self:_log("connecting", ep.host, ep.port)

	self.socket = WebSocket.new(uri, {
		onOpen = function()
			self:_onOpen()
		end,
		onMessage = function(data)
			self:_onMessage(data)
		end,
		onClose = function(code, reason)
			self:_onClosed("closed (" .. tostring(code) .. ") " .. tostring(reason or ""))
		end,
		onError = function(err)
			self:_log("socket error", err)
		end,
	})
end

function RTTComms:_send(tbl)
	if self.socket then
		local text = json.encode(tbl)
		self:_log("SEND", text)
		self.socket:send(text)
	end
end

function RTTComms:_onOpen()
	local c = self.client
	self:_send({
		operation = "CONNECT",
		service = "rtt",
		data = {
			appId = c.appId,
			profileId = c.profileId,
			sessionId = c:getSessionId(),
			auth = self._auth,
			system = {
				protocol = "ws",
				platform = c.releasePlatform,
			},
		},
	})
end

function RTTComms:_onMessage(text)
	local ok, msg = pcall(json.decode, text)
	if not ok or type(msg) ~= "table" then
		self:_log("bad message", text)
		return
	end
	self:_log("RECV", text)
	if msg.service == "rtt" then
		if msg.operation == "CONNECT" then
			self.connectionId = msg.data and msg.data.cxId
			self._heartbeatSeconds = (msg.data and msg.data.heartbeatSeconds) or self._heartbeatSeconds
			self._lastHeartbeat = self.client.platform.now()
			self._status = Status.CONNECTED
			self._connectMessage = msg
			local cb = self._connectCallback
			if cb and cb.success then
				cb.success(msg)
			end
		elseif msg.operation == "DISCONNECT" then
			self._disconnectReason = msg.data
		end
		return
	end
	local cb = self.callbacks[msg.service]
	if cb then
		cb(msg)
	else
		self:_log("no callback for service", msg.service)
	end
end

function RTTComms:_onClosed(why)
	if self._status == Status.DISCONNECTED then
		return
	end
	local wasConnected = self._status == Status.CONNECTED
	self.socket = nil
	self.connectionId = nil
	local reason = self._disconnectReason and json.encode(self._disconnectReason) or why
	if self._connectCallback then
		self:_failConnect(reason)
	else
		self._status = Status.DISCONNECTED
	end
	if wasConnected then
		self:_log("disconnected", reason)
	end
end

function RTTComms:disableRTT()
	if self._status == Status.DISCONNECTED then
		return
	end
	self._status = Status.DISCONNECTING
	if self.socket then
		self.socket:close()
		self.socket = nil
	end
	self.connectionId = nil
	self._connectCallback = nil
	self._status = Status.DISCONNECTED
end

function RTTComms:update(now)
	if not self.socket then
		return
	end
	self.socket:update()
	if self._status == Status.CONNECTED and now - self._lastHeartbeat >= self._heartbeatSeconds then
		self._lastHeartbeat = now
		self:_send({ operation = "HEARTBEAT", service = "rtt", data = json.null })
	end
end

return RTTComms
