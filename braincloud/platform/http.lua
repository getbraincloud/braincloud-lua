-- Async HTTP(S). In LÖVE the blocking request runs on love.thread workers so the game loop never
-- stalls; headless it runs inline and the callback fires on the next update().
-- Backend order: love.https (LÖVE 12) → lua-https module → LuaSec → LuaSocket (http:// only).

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local Platform = require(ROOT .. ".platform.core")
local Native = require(ROOT .. ".platform.native")
local Web = require(ROOT .. ".platform.web")

local Http = {}
Http.__index = Http

local MAX_WORKERS = 4

-- Builds perform(req) → code, body, headerString | 0, nil, err. Runs in the main state or a thread.
local BACKEND_SOURCE = [[
local cfg, installSsl = ...

local function packHeaders(h)
	local out = {}
	for k, v in pairs(h or {}) do
		out[#out + 1] = tostring(k):lower() .. "\n" .. tostring(v)
	end
	return table.concat(out, "\n")
end

local function unpackHeaders(s)
	local h = {}
	if s and s ~= "" then
		local key
		for line in (s .. "\n"):gmatch("(.-)\n") do
			if key then
				h[key] = line
				key = nil
			else
				key = line
			end
		end
	end
	return h
end

local loveHttps = type(love) == "table" and pcall(require, "love.https") and love.https or nil
local luaHttps
if not loveHttps and cfg.httpsPath then
	local open = package.loadlib(cfg.httpsPath, "luaopen_https")
	if open then
		luaHttps = open()
	end
end
local ssl = installSsl(cfg)

local function nativeRequest(lib, req)
	local code, body, headers = lib.request(req.url, {
		method = req.method,
		headers = unpackHeaders(req.headers),
		data = req.body,
	})
	if not code or code == 0 then
		return 0, nil, tostring(body or "request failed")
	end
	return code, body, packHeaders(headers)
end

local function socketRequest(req)
	local ltn12 = require("ltn12")
	local isHttps = req.url:sub(1, 6) == "https:"
	local http
	if isHttps then
		if not ssl then
			return 0, nil, "no HTTPS support: add the brainCloud native pack or use LÖVE 12"
		end
		http = require("ssl.https")
	else
		http = require("socket.http")
	end
	http.TIMEOUT = req.timeout or 30
	local chunks = {}
	local params = {
		url = req.url,
		method = req.method,
		headers = unpackHeaders(req.headers),
		sink = ltn12.sink.table(chunks),
	}
	if req.body and req.body ~= "" then
		params.source = ltn12.source.string(req.body)
		params.headers["content-length"] = tostring(#req.body)
	end
	if isHttps then
		params.protocol = "any"
		params.options = { "all", "no_sslv2", "no_sslv3", "no_tlsv1" }
		params.verify = cfg.cafile and "peer" or "none"
		params.cafile = cfg.cafile
	end
	local ok, code, headers = http.request(params)
	if not ok then
		return 0, nil, tostring(code)
	end
	return code, table.concat(chunks), packHeaders(headers)
end

-- Timed TCP connect, measured here so frame time doesn't skew it.
local function ping(req)
	local socket = require("socket")
	local host = req.url:gsub("^%a+://", ""):gsub("/.*$", "")
	local port = 80
	local h, p = host:match("^(.-):(%d+)$")
	if h then
		host, port = h, tonumber(p)
	elseif req.url:sub(1, 6) == "https:" then
		port = 443
	end
	local ip = socket.dns.toip(host)
	if not ip then
		return 0, nil, "dns failed"
	end
	local t = socket.tcp()
	t:settimeout(req.timeout or 2)
	local start = socket.gettime()
	local ok, err = t:connect(ip, port)
	local ms = math.floor((socket.gettime() - start) * 1000 + 0.5)
	t:close()
	if not ok then
		return 0, nil, tostring(err)
	end
	return 200, tostring(ms), ""
end

return function(req)
	if req.method == "PING" then
		return ping(req)
	end
	local isHttps = req.url:sub(1, 6) == "https:"
	if loveHttps then
		return nativeRequest(loveHttps, req)
	end
	if luaHttps and (isHttps or not ssl) then
		return nativeRequest(luaHttps, req)
	end
	return socketRequest(req)
end
]]

local WORKER_SOURCE = [[
local reqChan, respChan, cfg, backendSource, installSource = ...
local installSsl = function(c) return assert(loadstring(installSource, "=installSsl"))(c) end
local perform = assert(loadstring(backendSource, "=httpBackend"))(cfg, installSsl)
while true do
	local r = reqChan:demand()
	if r == "quit" then
		break
	end
	local ok, code, body, extra = pcall(perform, r)
	if ok then
		respChan:push({ id = r.id, code = code, body = body or "", headers = code ~= 0 and extra or "", err = code == 0 and extra or "" })
	else
		respChan:push({ id = r.id, code = 0, body = "", headers = "", err = tostring(code) })
	end
end
]]

local function packHeaders(h)
	local out = {}
	for k, v in pairs(h or {}) do
		out[#out + 1] = tostring(k) .. "\n" .. tostring(v)
	end
	return table.concat(out, "\n")
end

local function unpackHeaders(s)
	local h = {}
	if s and s ~= "" then
		local key
		for line in (s .. "\n"):gmatch("(.-)\n") do
			if key then
				h[key] = line
				key = nil
			else
				key = line
			end
		end
	end
	return h
end

function Http.new()
	local self = setmetatable({}, Http)
	self._nextId = 0
	self._pending = {}
	self._done = {}
	self._web = Web.available()
	self._useThreads = not self._web and Platform.isLove and love.thread ~= nil
	return self
end

local function threadCfg()
	local i = Native.info()
	return {
		sslPath = i.sslPath,
		httpsPath = i.httpsPath,
		cafile = i.cafile,
		sslLua = i.sslLua,
		httpsLua = i.httpsLua,
	}
end

function Http:_startWorkers()
	if self._workers then
		return
	end
	self._reqChan = love.thread.newChannel()
	self._respChan = love.thread.newChannel()
	self._workers = {}
	self._cfg = threadCfg()
end

function Http:_ensureWorker()
	self:_startWorkers()
	local busy = 0
	for _ in pairs(self._pending) do
		busy = busy + 1
	end
	if #self._workers < MAX_WORKERS and busy > #self._workers then
		local t = love.thread.newThread(WORKER_SOURCE)
		t:start(self._reqChan, self._respChan, self._cfg, BACKEND_SOURCE, Native.INSTALL_SSL_SOURCE)
		self._workers[#self._workers + 1] = t
	end
end

function Http:_inlineBackend()
	if not self._perform then
		self._perform = assert(loadstring(BACKEND_SOURCE, "=httpBackend"))(threadCfg(), Native.installSsl)
	end
	return self._perform
end

--- req = { url, method, headers = {k=v}, body, timeout }; callback(code, body, headers, err).
function Http:request(req, callback)
	self._nextId = self._nextId + 1
	local id = self._nextId
	local msg = {
		id = id,
		url = req.url,
		method = req.method or (req.body and "POST" or "GET"),
		headers = packHeaders(req.headers),
		body = req.body or "",
		timeout = req.timeout or 30,
	}
	self._pending[id] = callback
	if self._web then
		-- the page does the fetch; the result comes back through Web.pump()
		local bridgeId
		bridgeId = Web.open(function(e)
			Web.close(bridgeId)
			self._done[#self._done + 1] = {
				id = id,
				code = e.code or 0,
				body = e.body and Web.decode(e.body) or "",
				headers = "",
				err = e.err or "",
			}
		end)
		Web.send({
			op = msg.method == "PING" and "ping" or "http",
			id = bridgeId,
			url = msg.url,
			method = msg.method,
			headers = req.headers or {},
			body = msg.body ~= "" and Web.encode(msg.body) or nil,
			timeout = msg.timeout,
		})
	elseif self._useThreads then
		self:_ensureWorker()
		self._reqChan:push(msg)
	else
		local ok, code, body, extra = pcall(self:_inlineBackend(), msg)
		if not ok then
			code, body, extra = 0, nil, tostring(code)
		end
		self._done[#self._done + 1] = {
			id = id,
			code = code,
			body = body or "",
			headers = code ~= 0 and extra or "",
			err = code == 0 and extra or "",
		}
	end
	return id
end

function Http:update()
	if self._web then
		Web.pump()
	end
	if self._respChan then
		while true do
			local r = self._respChan:pop()
			if not r then
				break
			end
			self._done[#self._done + 1] = r
		end
		for _, t in ipairs(self._workers) do
			local err = t:getError()
			if err then
				Platform.log("http worker error: " .. err)
			end
		end
	end
	if #self._done == 0 then
		return
	end
	local done = self._done
	self._done = {}
	for _, r in ipairs(done) do
		local cb = self._pending[r.id]
		self._pending[r.id] = nil
		if cb then
			local headers = unpackHeaders(r.headers)
			local body = r.body
			if headers["content-encoding"] == "gzip" and body ~= "" then
				body = Platform.gunzip(body) or body
			end
			cb(r.code, body, headers, r.err ~= "" and r.err or nil)
		end
	end
end

--- Blocking request for tools: returns code, body, headers, err.
function Http.requestSync(req)
	local perform = assert(loadstring(BACKEND_SOURCE, "=httpBackend"))(threadCfg(), Native.installSsl)
	local ok, code, body, extra = pcall(perform, {
		url = req.url,
		method = req.method or (req.body and "POST" or "GET"),
		headers = packHeaders(req.headers),
		body = req.body or "",
		timeout = req.timeout or 30,
	})
	if not ok then
		return 0, nil, {}, tostring(code)
	end
	if code == 0 then
		return 0, nil, {}, extra
	end
	return code, body, unpackHeaders(extra)
end

function Http:busy()
	return next(self._pending) ~= nil
end

function Http:shutdown()
	if self._workers then
		for _ = 1, #self._workers do
			self._reqChan:push("quit")
		end
		self._workers = nil
	end
end

return Http
