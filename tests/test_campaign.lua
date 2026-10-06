--- Test_Campaign.lua
--- Server integration test for Campaign service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Campaign", nil, function(client)
	local campaign = client.campaign
	assert(campaign, "Campaign module missing")

	local tests = {
		{
			name = "GetMyCampaigns",
			fn = function()
				local s, res = TestUtils.await("GetMyCampaigns", function(cb)
					campaign:getMyCampaigns({}, cb)
				end)
				assert(s, "GetMyCampaigns failed")
				assert(res ~= nil, "GetMyCampaigns did not return a response")
				assert(type(res.data) == "table", "Expected data table")
			end,
		},
	}

	return tests
end)
