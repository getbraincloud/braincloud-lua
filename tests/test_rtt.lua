--- RTT service + comms: endpoint request, wss connect, an RTT event round trip, disable.
local TestUtils = require("tests.shared")

return TestUtils.buildRunner("RTT", nil, function(client)
	local rtt = client.rttService

	local function enable()
		local s, r = TestUtils.await("EnableRTT", function(cb)
			rtt:enableRTT(function(msg)
				cb(true, msg)
			end, function(err)
				cb(false, err)
			end)
		end)
		assert(s, "EnableRTT failed: " .. tostring(r))
		return r
	end

	return {
		{
			name = "RequestClientConnection",
			fn = function()
				local s, r = TestUtils.await("RequestClientConnection", function(cb)
					rtt:requestClientConnection(cb)
				end)
				TestUtils.assertOk("RequestClientConnection", s, r)
				assert(r.data.endpoints and #r.data.endpoints > 0, "no endpoints")
			end,
		},
		{
			name = "EnableAndDisableRTT",
			fn = function()
				local msg = enable()
				assert(rtt:isRTTEnabled(), "isRTTEnabled false after connect")
				assert(rtt:getRTTConnectionId() == msg.data.cxId, "connection id mismatch")
				rtt:disableRTT()
				assert(not rtt:isRTTEnabled(), "still enabled after disable")
			end,
		},
		{
			name = "RTTEventCallback",
			fn = function()
				enable()
				local got
				rtt:registerRTTEventCallback(function(msg)
					got = msg
				end)
				TestUtils.await("SendEvent", function(cb)
					client.event:sendEvent(client.profileId, "luaRttTest", { value = 7 }, cb)
				end)
				TestUtils.waitFor("RTT event", function()
					return got ~= nil
				end)
				assert(got.service == "event", "expected event service, got " .. tostring(got.service))
				rtt:deregisterRTTEventCallback()
				rtt:disableRTT()
			end,
		},
	}
end)
