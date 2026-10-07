-- Non-blocking TCP stream with optional TLS (bundled LuaSec). Pump with update().

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local Platform = require(ROOT .. ".platform.core")
local Native = require(ROOT .. ".platform.native")

local Stream = {}
Stream.__index = Stream

local CONNECT_TIMEOUT = 10

function Stream.new(host, port, secure)
	local self = setmetatable({}, Stream)
	self.host = host
	self.port = port
	self.secure = secure == true
	self.state = "init"
	self._out = {}
	self._started = Platform.now()
	return self
end

function Stream:isConnected()
	return self.state == "connected"
end

function Stream:_begin()
	local socket = Platform.socket
	if not socket then
		return false, "LuaSocket not available"
	end
	local ip = socket.dns.toip(self.host)
	if not ip then
		return false, "could not resolve " .. tostring(self.host)
	end
	local isV6 = ip:find(":", 1, true) ~= nil
	local sock = isV6 and socket.tcp6 and socket.tcp6() or socket.tcp()
	sock:settimeout(0)
	sock:setoption("tcp-nodelay", true)
	local ok, err = sock:connect(ip, self.port)
	if not ok and err ~= "timeout" and err ~= "Operation already in progress" then
		sock:close()
		return false, "connect failed: " .. tostring(err)
	end
	self._sock = sock
	self.state = ok and "tcp" or "connecting"
	return true
end

function Stream:_startTls()
	local ssl = Native.ssl()
	if not ssl then
		return false, "TLS needs the brainCloud native pack (ssl module)"
	end
	local cafile = Native.info().cafile
	local conn, err = ssl.wrap(self._sock, {
		mode = "client",
		protocol = "any",
		options = { "all", "no_sslv2", "no_sslv3", "no_tlsv1" },
		verify = cafile and "peer" or "none",
		cafile = cafile,
	})
	if not conn then
		return false, "tls setup failed: " .. tostring(err)
	end
	conn:sni(self.host)
	conn:settimeout(0)
	self._sock = conn
	self.state = "tls"
	return true
end

function Stream:update()
	if self.state == "closed" then
		return false, "closed"
	end
	if self.state == "init" then
		local ok, err = self:_begin()
		if not ok then
			self.state = "closed"
			return false, err
		end
	end
	if self.state == "connecting" then
		local _, writable = Platform.socket.select(nil, { self._sock }, 0)
		if writable and #writable > 0 then
			if self._sock:getpeername() then
				self.state = "tcp"
			else
				self:close()
				return false, "connect refused"
			end
		elseif Platform.now() - self._started > CONNECT_TIMEOUT then
			self:close()
			return false, "connect timeout"
		end
	end
	if self.state == "tcp" then
		if self.secure then
			local ok, err = self:_startTls()
			if not ok then
				self:close()
				return false, err
			end
		else
			self.state = "connected"
		end
	end
	if self.state == "tls" then
		local ok, err = self._sock:dohandshake()
		if ok then
			self.state = "connected"
		elseif err ~= "wantread" and err ~= "wantwrite" and err ~= "timeout" then
			self:close()
			return false, "tls handshake failed: " .. tostring(err)
		elseif Platform.now() - self._started > CONNECT_TIMEOUT then
			self:close()
			return false, "tls handshake timeout"
		end
	end
	if self.state == "connected" then
		return self:flush()
	end
	return true
end

function Stream:send(data)
	self._out[#self._out + 1] = data
	if self.state == "connected" then
		return self:flush()
	end
	return true
end

function Stream:flush()
	if self.state ~= "connected" or #self._out == 0 then
		return true
	end
	local buf = table.concat(self._out)
	self._out = {}
	local i = 1
	while i <= #buf do
		local sent, err, last = self._sock:send(buf, i)
		if sent then
			i = sent + 1
		else
			if err == "timeout" or err == "wantwrite" or err == "wantread" then
				if last and last >= i then
					i = last + 1
				end
				self._out[1] = buf:sub(i)
				return true
			end
			self:close()
			return false, "send failed: " .. tostring(err)
		end
	end
	return true
end

--- Returns whatever arrived since the last call (or nil), plus "closed" once the peer hangs up.
function Stream:receive()
	if self.state ~= "connected" then
		return nil
	end
	local chunks = {}
	while true do
		local data, err, partial = self._sock:receive(8192)
		local chunk = data or partial
		if chunk and #chunk > 0 then
			chunks[#chunks + 1] = chunk
		end
		if not data then
			if err == "closed" then
				self:close()
				return #chunks > 0 and table.concat(chunks) or nil, "closed"
			end
			break
		end
	end
	if #chunks == 0 then
		return nil
	end
	return table.concat(chunks)
end

function Stream:close()
	if self._sock then
		pcall(function()
			self._sock:close()
		end)
		self._sock = nil
	end
	self.state = "closed"
end

return Stream
