--- Test_VirtualCurrency.lua
--- Server integration smoke tests for VirtualCurrency service

local TestUtils = require("tests.shared")


return TestUtils.buildRunner("VirtualCurrency", nil, function(client)
	local vc = client.virtualCurrency
	assert(vc, "VirtualCurrency module missing")

	local tests = {
		{
			name = "GetCurrency",
			fn = function()
				local s, res = TestUtils.await("GetCurrency", function(cb)
					vc:getCurrency(nil, cb)
				end)
				assert(res ~= nil, "GetCurrency did not return a response")
				assert(res.data.currencyMap, "Currency data missing in GetCurrency response")
			end,
		},

		{
			name = "GetParentCurrency",
			fn = function()
				local s, res = TestUtils.await("GetParentCurrency", function(cb)
					vc:getParentCurrency(nil, nil, cb)
				end)
				assert(res ~= nil, "GetParentCurrency did not return a response")
			end,
		},

		{
			name = "GetPeerCurrency",
			fn = function()
				--- peerCode is environment-specific; call with nil to ensure API path works
				local s, res = TestUtils.await("GetPeerCurrency", function(cb)
					vc:getPeerCurrency(nil, "", cb)
				end)
				assert(res ~= nil, "GetPeerCurrency did not return a response")
			end,
		},

		--- not recommended from the client,
		--- for sanity of the test suite this is being called
		{
			name = "AwardCurrency",
			fn = function()
				local s, res = TestUtils.await("AwardCurrency", function(cb)
					vc:awardCurrency("credits", 1, cb)
				end)
				assert(res ~= nil, "AwardCurrency did not return a response")
				assert(res.data.currencyMap, "Currency data missing in GetCurrency response")
			end,
		},

		--- not recommended from the client,
		--- for sanity of the test suite this is being called
		{
			name = "ConsumeCurrency",
			fn = function()
				local s, res = TestUtils.await("ConsumeCurrency", function(cb)
					vc:consumeCurrency("credits", 1, cb)
				end)
				assert(res ~= nil, "ConsumeCurrency did not return a response")
				assert(res.data.currencyMap, "Currency data missing in GetCurrency response")
			end,
		},

		{
			name = "ResetCurrency",
			fn = function()
				local s, res = TestUtils.await("ResetCurrency", function(cb)
					vc:resetCurrency(cb)
				end)
				assert(res ~= nil, "ResetCurrency did not return a response")
				assert(res.status == 200, "Expected status 200")
			end,
		},
	}

	return tests
end)
