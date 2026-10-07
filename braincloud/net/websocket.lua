-- Non-blocking WebSocket client (RFC 6455) over LuaSocket, TLS via the bundled LuaSec.
-- Drive it with ws:update() every frame. Handlers: onOpen(), onMessage(data, isBinary),
-- onClose(code, reason), onError(err).

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local Platform = require(ROOT .. ".platform.core")
local Native = require(ROOT .. ".platform.native")
local base64 = require(ROOT .. ".lib.base64")
local bit = require(ROOT .. ".lib.bit")
local Stream = require(ROOT .. ".net.stream")
local Web = require(ROOT .. ".platform.web")

local WebSocket = {}
WebSocket.__index = WebSocket

local OP_CONT, OP_TEXT, OP_BINARY, OP_CLOSE, OP_PING, OP_PONG = 0, 1, 2, 8, 9, 10

local function parseUrl(url)
	local scheme, rest = url:match("^(wss?)://(.+)$")
	if not scheme then
		return nil
	end
	local hostport, path = rest:match("^([^/?]+)(.*)$")
	if path == "" then
		path = "/"
	elseif path:sub(1, 1) == "?" then
		path = "/" .. path
	end
	local host, port = hostport:match("^(.-):(%d+)$")
	if not host then
		host = hostport
		port = scheme == "wss" and 443 or 80
	end
	return scheme == "wss", host, tonumber(port), path
end

-- Browser builds: the page's WebSocket via the web bridge, same interface.
local BrowserSocket = {}
BrowserSocket.__index = BrowserSocket

function BrowserSocket.new(url, handlers)
	local self = setmetatable({ url = url, handlers = handlers or {}, state = "connecting" }, BrowserSocket)
	self.id = Web.open(function(e)
		self:_onEvent(e)
	end)
	Web.send({ op = "ws_open", id = self.id, url = url })
	return self
end

function BrowserSocket:_onEvent(e)
	local h = self.handlers
	if e.op == "ws_open" then
		self.state = "open"
		if h.onOpen then
			h.onOpen()
		end
	elseif e.op == "ws_message" then
		if h.onMessage then
			h.onMessage(Web.decode(e.data or ""), e.binary == true)
		end
	elseif e.op == "ws_error" then
		if h.onError then
			h.onError(e.err)
		end
	elseif e.op == "ws_close" then
		local wasOpen = self.state ~= "closed"
		self.state = "closed"
		Web.close(self.id)
		if wasOpen and h.onClose then
			h.onClose(e.code or 1006, e.reason or "")
		end
	end
end

function BrowserSocket:isOpen()
	return self.state == "open"
end

function BrowserSocket:send(data, isBinary)
	if self.state ~= "open" then
		return false
	end
	Web.send({ op = "ws_send", id = self.id, data = Web.encode(data), binary = isBinary == true })
	return true
end

function BrowserSocket:close(code)
	if self.state ~= "closed" then
		self.state = "closed"
		Web.send({ op = "ws_close", id = self.id, code = code or 1000 })
		Web.close(self.id)
	end
end

function BrowserSocket:update()
	Web.pump()
end

function WebSocket.new(url, handlers)
	if Web.available() then
		return BrowserSocket.new(url, handlers)
	end
	local self = setmetatable({}, WebSocket)
	self.url = url
	self.handlers = handlers or {}
	self.state = "connecting"
	self._recv = ""
	self._fragments = nil
	self._fragmentBinary = false

	local secure, host, port, path = parseUrl(url)
	if not host then
		self:_fail("bad websocket url: " .. tostring(url))
		return self
	end
	self.host, self.port, self.path = host, port, path
	self._stream = Stream.new(host, port, secure)
	return self
end

function WebSocket:isOpen()
	return self.state == "open"
end

function WebSocket:_fail(err)
	if self.state == "closed" then
		return
	end
	self.state = "closed"
	if self._stream then
		self._stream:close()
	end
	if self.handlers.onError then
		self.handlers.onError(err)
	end
	if self.handlers.onClose then
		self.handlers.onClose(1006, err)
	end
end

function WebSocket:_sendHandshake()
	self._key = base64.encode(Platform.randomBytes(16))
	local hostHeader = self.host
	if not ((self.port == 443 and self._stream.secure) or (self.port == 80 and not self._stream.secure)) then
		hostHeader = hostHeader .. ":" .. self.port
	end
	self._stream:send(table.concat({
		"GET " .. self.path .. " HTTP/1.1",
		"Host: " .. hostHeader,
		"Upgrade: websocket",
		"Connection: Upgrade",
		"Sec-WebSocket-Key: " .. self._key,
		"Sec-WebSocket-Version: 13",
		"",
		"",
	}, "\r\n"))
end

local function u16(n)
	return string.char(math.floor(n / 256) % 256, n % 256)
end

local function mask(payload, key)
	local k1, k2, k3, k4 = key:byte(1, 4)
	local keys = { k1, k2, k3, k4 }
	local out = {}
	local bxor = bit.bxor
	for i = 1, #payload do
		out[i] = string.char(bxor(payload:byte(i), keys[(i - 1) % 4 + 1]))
	end
	return table.concat(out)
end

function WebSocket:_sendFrame(opcode, payload)
	payload = payload or ""
	local n = #payload
	local header = string.char(0x80 + opcode)
	if n < 126 then
		header = header .. string.char(0x80 + n)
	elseif n < 65536 then
		header = header .. string.char(0x80 + 126) .. u16(n)
	else
		local hi = math.floor(n / 4294967296)
		local lo = n % 4294967296
		header = header .. string.char(0x80 + 127) .. u16(math.floor(hi / 65536)) .. u16(hi % 65536)
			.. u16(math.floor(lo / 65536)) .. u16(lo % 65536)
	end
	local key = Platform.randomBytes(4)
	self._stream:send(header .. key .. mask(payload, key))
end

--- Sends a text frame (or binary when isBinary).
function WebSocket:send(data, isBinary)
	if self.state ~= "open" then
		return false
	end
	self:_sendFrame(isBinary and OP_BINARY or OP_TEXT, data)
	return true
end

function WebSocket:close(code)
	if self.state == "open" then
		self:_sendFrame(OP_CLOSE, u16(code or 1000))
		self._stream:flush()
	end
	self.state = "closed"
	if self._stream then
		self._stream:close()
	end
end

function WebSocket:_readHandshake()
	local headerEnd = self._recv:find("\r\n\r\n", 1, true)
	if not headerEnd then
		if #self._recv > 16384 then
			self:_fail("websocket handshake too large")
		end
		return
	end
	local head = self._recv:sub(1, headerEnd - 1)
	self._recv = self._recv:sub(headerEnd + 4)
	local status = tonumber(head:match("^HTTP/%d%.%d (%d+)"))
	if status ~= 101 then
		self:_fail("websocket upgrade failed: " .. (head:match("^[^\r\n]*") or "?"))
		return
	end
	self.state = "open"
	if self.handlers.onOpen then
		self.handlers.onOpen()
	end
end

-- Parses complete frames from the receive buffer.
function WebSocket:_readFrames()
	while self.state == "open" do
		local buf = self._recv
		if #buf < 2 then
			return
		end
		local b1, b2 = buf:byte(1, 2)
		local fin = b1 >= 128
		local opcode = b1 % 16
		local masked = b2 >= 128
		local len = b2 % 128
		local pos = 3
		if len == 126 then
			if #buf < 4 then
				return
			end
			local x, y = buf:byte(3, 4)
			len = x * 256 + y
			pos = 5
		elseif len == 127 then
			if #buf < 10 then
				return
			end
			len = 0
			for i = 3, 10 do
				len = len * 256 + buf:byte(i)
			end
			pos = 11
		end
		local maskKey
		if masked then
			if #buf < pos + 3 then
				return
			end
			maskKey = buf:sub(pos, pos + 3)
			pos = pos + 4
		end
		if #buf < pos + len - 1 then
			return
		end
		local payload = buf:sub(pos, pos + len - 1)
		self._recv = buf:sub(pos + len)
		if maskKey then
			payload = mask(payload, maskKey)
		end
		self:_onFrame(fin, opcode, payload)
	end
end

function WebSocket:_onFrame(fin, opcode, payload)
	if opcode == OP_PING then
		self:_sendFrame(OP_PONG, payload)
	elseif opcode == OP_PONG then
		return
	elseif opcode == OP_CLOSE then
		local code = #payload >= 2 and (payload:byte(1) * 256 + payload:byte(2)) or 1005
		local reason = payload:sub(3)
		if self.state == "open" then
			self:_sendFrame(OP_CLOSE, u16(code))
			self._stream:flush()
		end
		self.state = "closed"
		self._stream:close()
		if self.handlers.onClose then
			self.handlers.onClose(code, reason)
		end
	elseif opcode == OP_TEXT or opcode == OP_BINARY then
		if fin then
			if self.handlers.onMessage then
				self.handlers.onMessage(payload, opcode == OP_BINARY)
			end
		else
			self._fragments = { payload }
			self._fragmentBinary = opcode == OP_BINARY
		end
	elseif opcode == OP_CONT and self._fragments then
		self._fragments[#self._fragments + 1] = payload
		if fin then
			local data = table.concat(self._fragments)
			self._fragments = nil
			if self.handlers.onMessage then
				self.handlers.onMessage(data, self._fragmentBinary)
			end
		end
	end
end

function WebSocket:update()
	if self.state == "closed" or not self._stream then
		return
	end
	local ok, err = self._stream:update()
	if not ok then
		self:_fail(err)
		return
	end
	if self.state == "connecting" and self._stream:isConnected() then
		self.state = "handshake"
		self:_sendHandshake()
	end
	local data, rerr = self._stream:receive()
	if data then
		self._recv = self._recv .. data
	end
	if self.state == "handshake" then
		self:_readHandshake()
	end
	if self.state == "open" then
		self:_readFrames()
	end
	if rerr == "closed" and self.state ~= "closed" then
		self.state = "closed"
		self._stream:close()
		if self.handlers.onClose then
			self.handlers.onClose(1006, "connection closed")
		end
	end
end

WebSocket.available = function(secure)
	if Web.available() then
		return true -- the browser does TLS
	end
	if not Platform.socket then
		return false
	end
	return not secure or Native.ssl() ~= nil
end

return WebSocket
