--- Test_Time.lua
--- Server integration test for Time service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Time", nil, function(client)
	local time = client.time
	assert(time, "Time module missing")

	local tests = {
		{
			name = "ReadServerTime",
			fn = function()
				local s, res = TestUtils.await("ReadServerTime", function(cb)
					time:readServerTime(cb)
				end)
				assert(res ~= nil, "ReadServerTime did not return a response")
				assert(res.data.server_time, "ReadServerTime did not return server_time")
			end,
		},
	}

	return tests
end)
