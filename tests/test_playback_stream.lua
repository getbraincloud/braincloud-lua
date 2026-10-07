--- Test_PlaybackStream.lua
--- Server integration tests for PlaybackStream service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("PlaybackStream", nil, function(client)
	local ps = client.playbackStream
	assert(ps, "PlaybackStream module missing")

	local playbackStreamId = nil

	local tests = {
		{
			name = "StartStream",
			fn = function()
				local target = TestUtils.TEST_USER_OPP_PROFILE_ID or ""
				local s, res = TestUtils.await("StartStream", function(cb)
					ps:startStream(target, true, cb)
				end)
				TestUtils.assertOk("StartStream", s, res)
				if res and res.data and res.data.playbackStreamId then
					playbackStreamId = res.data.playbackStreamId
				end
			end,
		},

		{
			name = "AddEvent",
			fn = function()
				local id = playbackStreamId or ""
				local eventData = { action = "test" }
				local summary = { score = 1 }
				local s, res = TestUtils.await("AddEvent", function(cb)
					ps:addEvent(id, eventData, summary, cb)
				end)
				assert(res ~= nil, "AddEvent did not return a response")
				assert(res.status == 200, "Non 200 Status from AddEvent")
			end,
		},

		{
			name = "ReadStream",
			fn = function()
				local id = playbackStreamId or ""
				local s, res = TestUtils.await("ReadStream", function(cb)
					ps:readStream(id, cb)
				end)
				assert(res ~= nil, "ReadStream did not return a response")
				assert(res.data.initiatingPlayerId, "No InitiatingPlayerId in ReadStream response")
			end,
		},

		{
			name = "GetRecentInitiating",
			fn = function()
				local s, res = TestUtils.await("GetRecentInitiating", function(cb)
					ps:getRecentStreamsForInitiatingPlayer(client.profileId, 10, cb)
				end)
				assert(res ~= nil, "GetRecentStreamsForInitiatingPlayer did not return a response")

				assert(res.data.streams, "No Streams in GetRecentStreamsForInitiatingPlayer response")
			end,
		},

		{
			name = "GetRecentTarget",
			fn = function()
				local s, res = TestUtils.await("GetRecentTarget", function(cb)
					ps:getRecentStreamsForTargetPlayer(client.profileId, 10, cb)
				end)
				assert(res ~= nil, "GetRecentStreamsForTargetPlayer did not return a response")
				assert(res.data.streams, "No Streams in GetRecentTarget response")
			end,
		},

		{
			name = "ProtectStreamUntil",
			fn = function()
				local id = playbackStreamId or ""
				local s, res = TestUtils.await("ProtectStreamUntil", function(cb)
					ps:protectStreamUntil(id, 7, cb)
				end)
				assert(res ~= nil, "ProtectStreamUntil did not return a response")
				assert(res.status == 200, "Non 200 Status from ProtectStreamUntil")
			end,
		},

		{
			name = "EndStream",
			fn = function()
				local id = playbackStreamId or ""
				local s, res = TestUtils.await("EndStream", function(cb)
					ps:endStream(id, cb)
				end)
				assert(res ~= nil, "EndStream did not return a response")
				assert(res.status == 200, "Non 200 Status from EndStream")
			end,
		},

		{
			name = "DeleteStream",
			fn = function()
				local id = playbackStreamId or ""
				local s, res = TestUtils.await("DeleteStream", function(cb)
					ps:deleteStream(id, cb)
				end)
				assert(res ~= nil, "DeleteStream did not return a response")
				assert(res.status == 200, "Non 200 Status from DeleteStream")
			end,
		},
	}

	return tests
end)
