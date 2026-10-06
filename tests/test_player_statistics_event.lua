--- Test_PlayerStatisticsEvent.lua
--- Server integration tests for PlayerStatisticsEvent service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("PlayerStatisticsEvent", nil, function(client)
	local pse = client.playerStatisticsEvent
	assert(pse, "PlayerStatisticsEvent module missing")

	local tests = {
		{
			name = "TriggerStatsEvent",
			fn = function()
				local s, res = TestUtils.await("TriggerStatsEvent", function(cb)
					pse:triggerStatsEvent("testEvent01", 1, cb)
				end)
				TestUtils.assertOk("TriggerStatsEvent", s, res)
			end,
		},

		{
			name = "TriggerStatsEvents",
			fn = function()
				local events = {
					{ eventName = "testEvent01", eventMultiplier = 1 },
					{ eventName = "rewardCredits", eventMultiplier = 1 },
				}
				local s, res = TestUtils.await("TriggerStatsEvents", function(cb)
					pse:triggerStatsEvents(events, cb)
				end)
				TestUtils.assertOk("TriggerStatsEvents", s, res)
			end,
		},
	}

	return tests
end)
