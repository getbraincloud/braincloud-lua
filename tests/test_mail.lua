--- Test_Mail.lua
--- Server integration tests for Mail service
local TestUtils = require("tests.shared")


return TestUtils.buildRunner("Mail", nil, function(client)
	assert(client, "[TEST] brainCloud client not created")
	local mail = client.mail
	assert(mail, "Mail module missing")

	local tests = {
		{
			name = "SendBasicEmail",
			fn = function()
				local target = client.profileId or ""
				local s, res = TestUtils.await("SendBasicEmail", function(cb)
					mail:sendBasicEmail(target, "Test Subject", "Hello from test", cb)
				end)
				assert(res ~= nil, "SendBasicEmail did not return a response")
			end,
		},

		{
			name = "SendAdvancedEmail",
			fn = function()
				local target = client.profileId or ""
				local params = { template = "default", tokens = { name = "Test" } }
				local s, res = TestUtils.await("SendAdvancedEmail", function(cb)
					mail:sendAdvancedEmail(target, params, cb)
				end)
				assert(res ~= nil, "SendAdvancedEmail did not return a response")
			end,
		},

		{
			name = "SendAdvancedEmailByAddress",
			fn = function()
				local params = { template = "default", tokens = { name = "External" } }
				local s, res = TestUtils.await("SendAdvancedEmailByAddress", function(cb)
					mail:sendAdvancedEmailByAddress("test@example.com", params, cb)
				end)
				assert(res ~= nil, "SendAdvancedEmailByAddress did not return a response")
			end,
		},

		{
			name = "SendAdvancedEmailByAddresses",
			fn = function()
				local params = { template = "default", tokens = { name = "Group" } }
				local s, res = TestUtils.await("SendAdvancedEmailByAddresses", function(cb)
					mail:sendAdvancedEmailByAddresses({ "a@example.com", "b@example.com" }, params, cb)
				end)
				assert(res ~= nil, "SendAdvancedEmailByAddresses did not return a response")
			end,
		},
	}
	return tests
end)
