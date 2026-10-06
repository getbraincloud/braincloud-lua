--- Test_RedemptionCode.lua
--- Server integration smoke tests for RedemptionCode service
local TestUtils = require("tests.shared")

local client = nil
local function allowedFailure(res)
	if not res or not res.status then
		return false
	end

	local okCodes = {
		[client.reasonCodes.REDEMPTION_CODE_REDEEMED_BY_SELF] = true,
		[client.reasonCodes.REDEMPTION_CODE_REDEEMED_BY_OTHER] = true,
	}
	return okCodes[res.reason_code] == true
end

return TestUtils.buildRunner("RedemptionCode", nil, function(inClient)
	client = inClient
	local rc = client.redemptionCode
	assert(rc, "RedemptionCode module missing")

	-- same as C#: codes are sequential and lastCodeUsed tracks the next unused one
	local CODE_TYPE = "default"
	local function getValidCode()
		local s, r = TestUtils.await("IncrementGlobalStats", function(cb)
			client.globalStatistics:incrementGlobalStats({ lastCodeUsed = "+1" }, cb)
		end)
		TestUtils.assertOk("IncrementGlobalStats", s, r)
		return tostring(r.data.statistics.lastCodeUsed)
	end
	local tests = {
		{
			name = "GetRedeemedCodes",
			fn = function()
				local s, res = TestUtils.await("GetRedeemedCodes", function(cb)
					rc:getRedeemedCodes(nil, cb)
				end)
				assert(res ~= nil, "GetRedeemedCodes did not return a response")
				assert(res.data.codes, "Missing codes")
			end,
		},

		{
			name = "RedeemCode",
			fn = function()
				--- Attempt to redeem a test code
				--- get the code from the list above
				local s, res = TestUtils.await("RedeemCode", function(cb)
					rc:redeemCode(getValidCode(), CODE_TYPE, { test = 127 }, cb)
				end)
				assert(s or allowedFailure(res), "RedeemCode failed: " .. TestUtils.describe(res))
			end,
		},
	}

	return tests
end)
