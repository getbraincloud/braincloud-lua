-- SDK smoke test inside LÖVE (threaded HTTP, native pack, RTT, relay):
--   ./run.sh <path to test_ids file>   (runs it as a folder and as a packed .love)
local BrainCloud = require("braincloud")

local ids = {}
local checks, failed = {}, 0
local bc, steps, step, deadline
local transports = { "ws", "tcp", "udp" }

local function check(name, ok, detail)
	checks[#checks + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and ("  " .. tostring(detail)) or "")
	if not ok then
		failed = failed + 1
	end
end

local function finish()
	for _, line in ipairs(checks) do
		print(line)
	end
	print(failed == 0 and "LOVE SMOKE: all passed" or ("LOVE SMOKE: " .. failed .. " failed"))
	love.event.quit(failed == 0 and 0 or 1)
end

local function nextStep()
	step = step + 1
	deadline = love.timer.getTime() + 180
	if steps[step] then
		steps[step]()
	else
		finish()
	end
end

local function relayFlow(proto)
	return function()
		local server, ready
		bc.rttService:registerRTTLobbyCallback(function(msg)
			if msg.operation == "ROOM_READY" then
				server = msg.data
			elseif msg.operation == "DISBANDED" then
				ready = msg.data.reason and msg.data.reason.code == 80101
				if ready and server then
					local echoed = false
					bc.relay:registerRelayCallback(function(_, data)
						if data == "Hello " .. proto then
							echoed = true
							check("relay " .. proto .. " echo", true)
							bc.relay:disconnect()
							bc.rttService:deregisterRTTLobbyCallback()
							nextStep()
						end
					end)
					bc.relay:connect(proto, {
						host = server.connectData.address,
						port = server.connectData.ports[proto],
						passcode = server.passcode,
						lobbyId = server.lobbyId,
					}, function()
						local me = bc.relay:getNetIdForProfileId(bc.client.profileId)
						bc.relay:send("Hello " .. proto, me, true, true, 0)
					end, function(err)
						if not echoed then
							check("relay " .. proto .. " connect", false, err)
							nextStep()
						end
					end)
				elseif not ready then
					check("relay " .. proto .. " room", false, "disbanded " .. tostring(msg.data.reason and msg.data.reason.code))
					nextStep()
				end
			end
		end)
		bc.lobby:createLobby(ids.relayLobbyType or "READY_START_V2", 0, nil, true, {}, "all", {}, function(ok, r)
			if not ok then
				check("relay " .. proto .. " createLobby", false, r.status_message)
				nextStep()
			end
		end)
	end
end

function love.load(args)
	for line in io.lines(args[1]) do
		local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if k then
			ids[k] = v
		end
	end
	bc = BrainCloud.new("lovetest")
	bc:initialize(ids.appId, ids.secret, ids.version, ids.serverUrl)
	step = 0
	steps = {
		function()
			bc:authenticateAnonymous(function(ok, r)
				check("threaded auth", ok, not ok and r.status_message)
				nextStep()
			end)
		end,
		function()
			local n, before = 0, bc.client.packetId
			for _ = 1, 3 do
				bc.time:readServerTime(function(ok)
					n = n + 1
					if n == 3 then
						check("bundled 3 calls in 1 packet", bc.client.packetId == before + 1, "packets " .. (bc.client.packetId - before))
						nextStep()
					end
				end)
			end
		end,
		function()
			local connected = false
			bc.rttService:enableRTT(function()
				connected = true
				check("RTT over wss (native pack)", true)
				nextStep()
			end, function(err)
				-- after a connect this fires again as the disconnect notice; only a failed connect counts
				if not connected then
					check("RTT over wss (native pack)", false, err)
					nextStep()
				end
			end)
		end,
	}
	for _, p in ipairs(transports) do
		steps[#steps + 1] = relayFlow(p)
	end
	steps[#steps + 1] = function()
		bc.playerState:deleteUser(function()
			nextStep()
		end)
	end
	nextStep()
end

function love.update()
	bc:update()
	if love.timer.getTime() > deadline then
		check("step " .. step, false, "timeout")
		nextStep()
	end
end
