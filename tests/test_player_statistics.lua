--- Test_PlayerStatistics.lua
--- Comprehensive server integration tests for BrainCloud PlayerStatistics (resilient mode)

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("PlayerStatistics", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")

	local stats = client.playerStatistics
	assert(stats, "[TEST] PlayerStatistics module missing")

	--- Define all tests
	local tests = {

		--- GET PLAYER STATISTICS
		{
			name = "ReadAllUserStats",
			fn = function()
				local s, response = TestUtils.await("ReadAllUserStats", function(r)
					stats:readAllUserStats(r)
				end)
				assert(s, " failed")
				assert(type(response.data.statistics) == "table", "No player statistics returned")
			end,
		},

		{
			name = "ReadUserStatsSubset",
			fn = function()
				local s, response = TestUtils.await("ReadUserStatsSubset", function(r)
					stats:readUserStatsSubset({ "score", "wins" }, r)
				end)
				assert(s, "readUserStatsSubset failed")
				assert(response.data, "No subset returned")
				assert(type(response.data.statistics) == "table", "Subset statistics missing")
			end,
		},

		{
			name = "IncrementUserStats",
			fn = function()
				local s, response = TestUtils.await("IncrementUserStats", function(r)
					stats:incrementUserStats({ score = 10, wins = 1 }, 5, r)
				end)
				assert(s, " failed")
				assert(response.data, "Response missing after increment")
			end,
		},

		{
			name = "SetExperiencePoints",
			fn = function()
				local s, response = TestUtils.await("SetExperiencePoints", function(r)
					stats:setExperiencePoints(1000, r)
				end)
				assert(s, "setExperiencePoints failed")
				assert(response.data, "Response missing after XP update")
			end,
		},

		--- RESET PLAYER STATISTICS
		{
			name = "ResetAllUserStats",
			fn = function()
				local s, response = TestUtils.await("ResetAllUserStats", function(r)
					stats:resetAllUserStats(r)
				end)
				assert(s, " failed")
				assert(response.data, "Response missing after reset")
			end,
		},

		--- XP / EXPERIENCE LEVEL
		{
			name = "ReadNextExperienceLevel",
			fn = function()
				local s, response = TestUtils.await("ReadNextExperienceLevel", function(r)
					stats:getNextExperienceLevel(r)
				end)
				assert(s, " failed")
				assert(response.data, "Response missing for next XP level")
			end,
		},
	}

	return tests
end)
