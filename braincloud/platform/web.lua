-- Browser bridge for love.js builds (love.system.getOS() == "Web"). Lua can't open sockets in a
-- browser, so HTTP and WebSockets go through braincloud-web.js on the page: commands out via
-- print("@@BCWEB@@" .. json), results back via a file the page writes into the save directory
-- during that same print call.

local ROOT = (...):match("^(.*)%.[^%.]+%.[^%.]+$")
local json = require(ROOT .. ".lib.json")
local base64 = require(ROOT .. ".lib.base64")

local Web = {}

local PREFIX = "@@BCWEB@@"
local INBOX = "bcweb_in.json"

local available = type(love) == "table" and love.system and love.system.getOS() == "Web"
local started = false
local nextId = 0
local handlers = {} -- id → function(event)

function Web.available()
	return available
end

local function send(msg)
	if not started then
		started = true
		-- the save directory must exist for the page to write the inbox into it
		love.filesystem.write(".bcweb", "1")
		print(PREFIX .. json.encode({ op = "hello", dir = love.filesystem.getSaveDirectory() }))
	end
	print(PREFIX .. json.encode(msg))
end

--- Registers handler(event) for events tagged with the returned id.
function Web.open(handler)
	nextId = nextId + 1
	handlers[nextId] = handler
	return nextId
end

function Web.close(id)
	handlers[id] = nil
end

function Web.send(msg)
	send(msg)
end

--- Pulls queued page events and dispatches them. Safe to call more than once per frame.
function Web.pump()
	if not started then
		return
	end
	send({ op = "poll" })
	if not love.filesystem.getInfo(INBOX) then
		return
	end
	local raw = love.filesystem.read(INBOX)
	love.filesystem.remove(INBOX)
	local ok, events = pcall(json.decode, raw or "")
	if not ok or type(events) ~= "table" then
		return
	end
	for _, e in ipairs(events) do
		local h = handlers[e.id]
		if h then
			h(e)
		end
	end
end

Web.encode = base64.encode
Web.decode = base64.decode

return Web
