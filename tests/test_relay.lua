--- Relay over WebSocket, TCP and UDP: RTT → lobby → ROOM_READY → relay connect → echo to self.
--- Mirrors C# TestRelay.FullFlow.
local TestUtils = require("tests.shared")

local LOBBY_TYPE = TestUtils.ids.relayLobbyType or "READY_START_V2"

return TestUtils.buildRunner("Relay", nil, function(client)
	local relay = client.relay
	local rtt = client.rttService
	local ReasonCodes = client.reasonCodes

	local function fullFlow(connectionType, withEndMatch)
		-- fresh user so no lobby membership from earlier tests carries over (C# SetUpNewUser)
		client.authentication:clearSavedSession()
		TestUtils.assertOk("NewUser", TestUtils.await("NewUser", function(cb)
			client.authentication:authenticateAnonymous(true, cb)
		end))
		local server, roomReady
		rtt:registerRTTLobbyCallback(function(msg)
			if msg.operation == "ROOM_READY" then
				server = msg.data
			elseif msg.operation == "DISBANDED" then
				local code = msg.data.reason and msg.data.reason.code
				roomReady = code == ReasonCodes.RTT_ROOM_READY
				if not roomReady then
					error("lobby disbanded: " .. tostring(code))
				end
			end
		end)

		local s, r = TestUtils.await("EnableRTT", function(cb)
			rtt:enableRTT(function(m)
				cb(true, m)
			end, function(e)
				cb(false, e)
			end)
		end)
		assert(s, "EnableRTT failed: " .. tostring(r))

		-- own lobby: matchmaking could join a stale one left by the lobby tests and time out
		s, r = TestUtils.await("CreateLobby", function(cb)
			client.lobby:createLobby(LOBBY_TYPE, 0, nil, true, {}, "all", {}, cb)
		end)
		TestUtils.assertOk("CreateLobby", s, r)

		TestUtils.waitFor("ROOM_READY", function()
			return roomReady and server
		end, 180) -- cold room servers can take minutes to provision

		local cd = server.connectData
		local port = cd.ports[connectionType]
		assert(port, "no " .. connectionType .. " port in connectData")

		local systemConnect, echoed, endMatch = false, false, false
		relay:registerSystemCallback(function(json)
			if json.op == "CONNECT" then
				systemConnect = true
			elseif json.op == "END_MATCH" then
				endMatch = true
			end
		end)
		relay:registerRelayCallback(function(_, data)
			if data == "Hello World!" then
				echoed = true
			end
		end)

		s, r = TestUtils.await("RelayConnect", function(cb)
			relay:connect(connectionType, {
				ssl = false,
				host = cd.address,
				port = port,
				passcode = server.passcode,
				lobbyId = server.lobbyId,
			}, function(m)
				cb(true, m)
			end, function(e)
				cb(false, e)
			end)
		end)
		assert(s, "Relay connect failed: " .. tostring(r))
		assert(relay:isConnected(), "isConnected false")

		local myNetId = relay:getNetIdForProfileId(client.profileId)
		assert(myNetId < 40, "bad netId " .. tostring(myNetId))
		assert(relay:getProfileIdForNetId(myNetId) == client.profileId, "netId→profileId mismatch")
		assert(relay:getOwnerProfileId() ~= "", "owner profile missing")

		relay:send("Hello World!", myNetId, true, true, relay.CHANNEL_HIGH_PRIORITY_1)
		TestUtils.waitFor("echo", function()
			return echoed
		end)
		assert(systemConnect, "no system CONNECT")

		TestUtils.wait(1.2)
		assert(relay:getPing() < 999, "no ping measured")

		if withEndMatch then
			relay:endMatch({ cxId = rtt:getRTTConnectionId(), op = "END_MATCH" })
			TestUtils.waitFor("END_MATCH", function()
				return endMatch
			end)
		else
			relay:disconnect()
		end
		assert(not relay:isConnected(), "still connected")

		relay:deregisterRelayCallback()
		relay:deregisterSystemCallback()
		rtt:deregisterRTTLobbyCallback()
		rtt:disableRTT()
		TestUtils.await("DeleteUser", function(cb)
			client.playerState:deleteUser(cb)
		end)
	end

	return {
		{ name = "FullFlowWebSocket", fn = function() fullFlow("ws", false) end },
		{ name = "FullFlowTCP", fn = function() fullFlow("tcp", false) end },
		{ name = "FullFlowUDP", fn = function() fullFlow("udp", false) end },
		{ name = "FullFlowEndMatch", fn = function() fullFlow("ws", true) end },
	}
end)
