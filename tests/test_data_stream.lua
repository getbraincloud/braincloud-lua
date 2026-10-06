--- Test_DataStream.lua
--- Server integration tests for DataStream service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("DataStream", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local dataStream = client.dataStream
	assert(dataStream, "DataStream module missing")

	local tests = {

		--- 1. CustomPageEvent
		{
			name = "CustomPageEvent",
			fn = function()
				local s, res = TestUtils.await("CustomPageEvent", function(r)
					dataStream:customPageEvent("TestPage", { foo = "bar" }, r)
				end)
				assert(s, "CustomPageEvent failed")
			end,
		},

		--- 2. CustomScreenEvent
		{
			name = "CustomScreenEvent",
			fn = function()
				local s, res = TestUtils.await("CustomScreenEvent", function(r)
					dataStream:customScreenEvent("TestScreen", { screenId = 1 }, r)
				end)
				assert(s, "CustomScreenEvent failed")
			end,
		},

		--- 3. CustomTrackEvent
		{
			name = "CustomTrackEvent",
			fn = function()
				local s, res = TestUtils.await("CustomTrackEvent", function(r)
					dataStream:customTrackEvent("TestTrackEvent", { points = 42 }, r)
				end)
				assert(s, "CustomTrackEvent failed")
			end,
		},

		--- 4. SubmitCrashReport
		{
			name = "SubmitCrashReport",
			fn = function()
				local s, res = TestUtils.await("SubmitCrashReport", function(r)
					dataStream:submitCrashReport(
						"LuaError",
						"Testing crash report",
						{ crashed = true },
						"Stacktrace: none",
						"Tester",
						"test@example.com",
						"No notes",
						true,
						r
					)
				end)
				assert(s, "SubmitCrashReport failed")
			end,
		},
	}
	return tests
end)
