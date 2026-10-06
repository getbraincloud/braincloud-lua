--- Test_GlobalStatistics.lua
--- Server integration tests for GLOBALSTATISTICS service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("GlobalStatistics", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local globalStats = client.globalStatistics
	assert(globalStats, "GLOBALSTATISTICS module missing")

	local tests = {

		--- 1. IncrementGlobalStats
		{
			name = "IncrementGlobalStats",
			fn = function()
				local s, res = TestUtils.await("IncrementGlobalStats", function(r)
					globalStats:incrementGlobalStats({ TEST_STAT = 1 }, r)
				end)
				assert(s, "IncrementGlobalStats failed")
				assert(type(res.data.statistics) == "table", "Expected statistics table")
			end,
		},

		--- 2. ReadAllGlobalStats
		{
			name = "ReadAllGlobalStats",
			fn = function()
				local s, res = TestUtils.await("ReadAllGlobalStats", function(r)
					globalStats:readAllGlobalStats(r)
				end)
				assert(s, "ReadAllGlobalStats failed")
				assert(type(res.data.statistics) == "table", "Expected statistics table")
			end,
		},

		--- 3. ReadGlobalStatsSubset
		{
			name = "ReadGlobalStatsSubset",
			fn = function()
				local s, res = TestUtils.await("ReadGlobalStatsSubset", function(r)
					globalStats:readGlobalStatsSubset({ "TEST_STAT" }, r)
				end)
				assert(s, "ReadGlobalStatsSubset failed")
				assert(type(res.data.statistics) == "table", "Expected statistics table")
			end,
		},

		--- 4. ReadGlobalStatsForCategory
		{
			name = "ReadGlobalStatsForCategory",
			fn = function()
				local s, res = TestUtils.await("ReadGlobalStatsForCategory", function(r)
					globalStats:readGlobalStatsForCategory("TEST_CATEGORY", r)
				end)
				assert(s, "ReadGlobalStatsForCategory failed")
				assert(type(res.data.statistics) == "table", "Expected statistics table")
			end,
		},

		--- 5. ProcessStatistics
		{
			name = "ProcessStatistics",
			fn = function()
				local s, res = TestUtils.await("ProcessStatistics", function(r)
					globalStats:processStatistics({ TEST_STAT = "INC#5" }, r)
				end)
				assert(s, "ProcessStatistics failed")
				assert(type(res.data.statistics) == "table", "Expected statistics table")
			end,
		},
	}

	return tests
end)
