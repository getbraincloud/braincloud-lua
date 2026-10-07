--- Test_OneWayMatch.lua
--- Server integration tests for OneWayMatch service
--- Mirrors C# TestOneWayMatch.cs (UserA plays a one-way match against UserB)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("OneWayMatch", nil, function(client)
	local ow = client.oneWayMatch
	assert(ow, "OneWayMatch module missing")

	local function call(tag, fn)
		local s, r = TestUtils.await(tag, fn)
		return TestUtils.assertOk(tag, s, r)
	end

	local function startMatch()
		local r = call("StartMatch", function(cb)
			ow:startMatch(TestUtils.users.B.profileId, 1000, cb)
		end)
		assert(r.data.playbackStreamId, "Missing playbackStreamId from StartMatch")
		return r.data.playbackStreamId
	end

	local function cancelMatch(streamId)
		call("CancelMatch", function(cb)
			ow:cancelMatch(streamId, cb)
		end)
	end

	return {
		{
			name = "StartMatch",
			fn = function()
				cancelMatch(startMatch())
			end,
		},
		{
			name = "CancelMatch",
			fn = function()
				cancelMatch(startMatch())
			end,
		},
		{
			name = "CompleteMatch",
			fn = function()
				local streamId = startMatch()
				call("CompleteMatch", function(cb)
					ow:completeMatch(streamId, cb)
				end)
			end,
		},
	}
end)
